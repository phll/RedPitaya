#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "controller.h"
#include "scpi/parser.h"
#include "common.h"


#define LC_ERR(msg) do{*out = msg; return 0;}while(0)
#define LC_ERR_i(msg, i) do{*out = msg; *err_ev = i; return 0;}while(0)
#define LC_RES_ERR(...) {char buf[200]; snprintf(buf, 200, __VA_ARGS__); SCPI_ResultText(context, buf); RP_LOG(LOG_ERR, __VA_ARGS__);}
#define LC_RES_OK( ...) {char buf[100*N_CHANNELS+100]; snprintf(buf, 100*N_CHANNELS+100, __VA_ARGS__); SCPI_ResultText(context, buf); RP_LOG(LOG_INFO, __VA_ARGS__);}

#define N_CHANNELS 26  //total amount of channels
#define N_A_CHANNELS 2 //analog channels

#define FCLK_HZ 125000000
#define DAC_BITS 14

#define MAX_DCYC 4294967296 //2^32 -> maximum timestep is ~34s

#define MAX_EVENTS_A 4*1024 //analog
#define MAX_EVENTS_D 128    //digital

#define LC_BASE_ADDR        0x40600000
#define LC_BASE_SIZE        0x10000

#define CHANNEL_OFFSET      4*0
#define AWAIT_TRIGGER       4*24
#define SOFTWARE_TRIGGER    4*25

#define ENABLE_OFFSET       4*1
#define SAMPLES_OFFSET      4*2
#define INITIAL_OFFSET      4*3

#define CYCLES_OFFSET       4*40
#define VALUES_OFFSET_A     CYCLES_OFFSET+4*MAX_EVENTS_A
#define VALUES_OFFSET_D     CYCLES_OFFSET+4*MAX_EVENTS_D


int fd = -1; //file descriptor for fpga
void *lc_reg = NULL; //register on fpga

#define LC_DEBUG
FILE *log_file = NULL;

double max(double x, double y){
  if(x > y)
    return x;
  else
    return y;
}

double clip(double x, double lower, double upper){
  if(x>upper)
    return upper;
  if(x<lower)
    return lower;
  return x;
}


void fpga_write(unsigned int addr, uint32_t value){
  *((uint32_t*)(lc_reg+addr)) = value;
  #ifdef LC_DEBUG
  fprintf(log_file, "[%x]: %u [%d]\n", addr+LC_BASE_ADDR, value, value);
  #endif
}

void fpga_write_l(unsigned int addr, uint64_t value){
  *((uint32_t*)(lc_reg+addr)) = value&0xffffffff;
  *((uint32_t*)(lc_reg+addr+4)) = value>>32;
  #ifdef LC_DEBUG
  fprintf(log_file, "[%x]: %u\n", addr+LC_BASE_ADDR, (int)(value&0xffffffff));
  fprintf(log_file, "[%x]: %u [%lld]\n", addr+LC_BASE_ADDR+4, (int)(value>>32), (int64_t)value);
  #endif
}

//bits must be smaller than 53! Otherwise, double will be to small
double toSignedDAC(double volts, int bits, double range){
  double v = clip(volts, -range/2.0, range/2.0);
  return round(v*(pow(2,bits)-1)/range -0.5);
}

//bits must be at most 31
double toSignedVoltage(int dac, int bits, double range){
  int v = clip(dac, -pow(2,bits-1), pow(2, bits-1)-1);
  return ((v+pow(2,bits-1))/(pow(2,bits)-1)-0.5)*range;
}

scpi_result_t LC_Init(){
  // Page variables used to calculate correct mapping addresses
  void *page_ptr;
  long page_addr, page_off, page_size = sysconf(_SC_PAGESIZE);

  if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1){
    RP_LOG(LOG_ERR, "*LC#:INIT Failed to "
        "open /dev/mem.\n");
    return SCPI_RES_ERR;
  }

  // Calculate correct page address and offset from LC_BASE_ADDR and
  // LC_BASE_SIZE
  page_addr = LC_BASE_ADDR & (~(page_size-1));
  page_off  = LC_BASE_ADDR - page_addr;

  // Map FPGA memory space to page_ptr.
  page_ptr = mmap(NULL, LC_BASE_SIZE, PROT_READ | PROT_WRITE,
                          MAP_SHARED, fd, page_addr);

  if((void *)page_ptr == MAP_FAILED){
    RP_LOG(LOG_ERR, "*LC#:INIT Failed to "
        "map memory.\n");
    return SCPI_RES_ERR;
  }

  // Set FPGA LC module pointers to correct values.
  lc_reg = page_ptr + page_off;

  #ifdef LC_DEBUG
  log_file = fopen("/var/log/lc.log", "w");
  #endif


  return SCPI_RES_OK;
}

scpi_result_t LC_Release(){
  if (lc_reg) {
		if(munmap(lc_reg, LC_BASE_SIZE) == -1){
      RP_LOG(LOG_ERR, "*LC#:RELEASE Failed to "
          "close /dev/mem.\n");
      return SCPI_RES_ERR;
    }
		lc_reg = NULL;
	}

	if (fd != -1) {
		close(fd);
	}

  #ifdef LC_DEBUG
  if(log_file!=NULL)
    fclose(log_file);
  #endif

  return SCPI_RES_OK;
}

//first value must be total array length; data must be freed externally
scpi_bool_t SCPI_ParamBufferDouble(scpi_t * context, double **data, uint32_t *size, scpi_bool_t mandatory) {
    *size = 0;
    double value;
    size_t len = 0;
    double* dat = NULL;
    while (true) {
        if (!SCPI_ParamDouble(context, &value, mandatory)) {
            break;
        }
        if(*size==0){
          len = (int)value;
          if(len<1)
            return false;
          dat = (double*) malloc(sizeof(double)*len);
          if(dat==NULL)
            return false;
        }
        else if(*size>=len)
          return false;
        dat[*size] = value;
        *size = *size + 1;
        mandatory = false;          // only first is mandatory
    }
    *data = dat;
    return true;
}

//data = [total_len, ch, ch_len, initia, time, value, ..., ch,...], total_len is length of total array; ch_len is twice the number of events for this channel +1
scpi_result_t LC_ControllerData(scpi_t *context) {
    double *buffer = NULL;
    uint32_t size;
    double* chs_data[N_CHANNELS];  //2 analog + 24 digital channels
    size_t chs_len[N_CHANNELS];
    int i;

    for(i=0;i<N_CHANNELS;++i){
      chs_data[i] = NULL;
      chs_len[i] = 0;
    }

		//parse incoming data
    if(!SCPI_ParamBufferDouble(context, &buffer, &size, true)){ //allocates memory!
        LC_RES_ERR("*LC#:DATA Failed to "
            "parse controller data.\n");
        return SCPI_RES_ERR;
    }

		//do some validation

    if(size<4 || size!=buffer[0]){ //there should be at least total_len, ch, ch_len, initial
      LC_RES_ERR("*LC#:DATA Failed to "
          "read controller data. To less data or size mismatch [size:%d, total_len:%d].\n", (int)size, (int)buffer[0]);
      free(buffer);
      return SCPI_RES_ERR;
    }

    for(i=1;i<size;){
      int ch = buffer[i];
			//check if valid channel number
      if(ch<0 || ch>(N_CHANNELS-1)){
        LC_RES_ERR("*LC#:DATA Failed to "
            "read controller data. Channel out of bounds.\n");
        free(buffer);
        return SCPI_RES_ERR;
      }
      if(i+2>size-1){ //there should be at least ch, ch_len, inital per channel entry
        LC_RES_ERR("*LC#:DATA Failed to "
            "read controller data. To less data in last channel.\n");
        free(buffer);
        return SCPI_RES_ERR;
      }
      int ch_len = buffer[i+1];
      if(ch_len<1 || size-1<(ch_len+i+1) || ((ch_len-1)/2.0 != (int)(((ch_len-1)/2.0)))){ //check for size mismatch or missing data, ch_len must be odd
        LC_RES_ERR("*LC#:DATA Failed to "
            "read controller data. To less data in a channel [%d].\n", ch);
        free(buffer);
        return SCPI_RES_ERR;
      }
      chs_data[ch] = &buffer[i+2];
      chs_len[ch] = ch_len;
      i = i+ch_len+2;
    }


    double def_seq[3] = {0.0, 0.0001, 0.0};
    bool enable = false;
    bool has_user_events = false;
    char stats[N_CHANNELS*100];
    int stats_len = 0;
    for(i=0;i<N_CHANNELS;++i){
      enable = true;
      has_user_events = true;
			//add dummy sequences for 'empty' channels
      if(chs_len[i]<2){
        has_user_events = false;
        double *d = (double*) malloc(sizeof(double)*3);
        if(d == NULL){
          LC_RES_ERR("*LC#:DATA Failed to "
            "read controller data due to memory allocation error.\n");
          return SCPI_RES_ERR;
        }
        if(chs_len[i]==1){
          d[0] = chs_data[i][0];
          d[1] = def_seq[1];
          d[2] = chs_data[i][0];
        }else{
          d[0] = def_seq[0];
          d[1] = def_seq[1];
          d[2] = def_seq[2];
          enable = false;
        }
        chs_data[i] = d;
        chs_len[i] = 3;
      }
      char * err;
      int err_ev = -1;
      double worst_timing_dev, total_timing_dev, worst_dac_dev;
      int worst_timing_ev, worst_dac_ev;
			//process sequence for this channel; collect errors and deviation informations
      if(!writeChannelSequence(i, chs_data[i], chs_len[i], enable, &err, &err_ev, &worst_timing_dev, &worst_timing_ev, &total_timing_dev, &worst_dac_dev, &worst_dac_ev)){
        if(err_ev==-1){
          LC_RES_ERR("*LC#:DATA Failed to "
              "write controller data at channel [%d] with error: %s\n", i, err);
        }else{
          LC_RES_ERR("*LC#:DATA Failed to "
              "write controller data at channel [%d] with error: %s %d.\n", i, err, err_ev);
        }
        free(buffer);
        return SCPI_RES_ERR;
      }
      if(has_user_events){
        if(i<N_A_CHANNELS)
          stats_len += sprintf(&stats[stats_len], "\tch %d:\ttotal timing dev: %.0fns, worst timing dev: %.2f%% at ev[%d], worst dac dev: %.3fmV at ev[%d]\n", i, total_timing_dev, worst_timing_dev *100.0, worst_timing_ev, worst_dac_dev*1000.0, worst_dac_ev);
        else
          stats_len += sprintf(&stats[stats_len], "\tch %d:\ttotal timing dev: %.0fns, worst timing dev: %.2f%% at ev[%d]\n", i, total_timing_dev, worst_timing_dev*100.0, worst_timing_ev);
      }

      usleep(10000);  //10ms, not sure how long we should wait until all channel data is stored on the fpga..
    }

    free(buffer);
    if(stats_len==0)
      stats[0] = '\0';
    LC_RES_OK("*LC#:DATA Successfully set controller data.\nStats:\n%s", stats);
    return SCPI_RES_OK;
}

//chs_data = [initial, time, value, time, value,...]. So voltages are at 2*i, while times are at 2*i+1
int writeChannelSequence(int ch, double *chs_data, size_t ch_len, bool enable, char** out, int* err_ev, double* worst_timing_dev, int* worst_timing_ev, double* total_timing_dev, double* worst_dac_dev, int* worst_dac_ev){
  int i = 0;
  int events = (ch_len-1)/2;

  if(ch<N_A_CHANNELS && events>MAX_EVENTS_A)
    LC_ERR("to many events.");
  else if(events>MAX_EVENTS_D)
    LC_ERR("to many events.");

  //allocate arrays for delta cycles
  uint32_t* dcyc = (uint32_t*) malloc(sizeof(uint32_t)*events); //32bit -> maximum timestep is ~34s
  if(dcyc==NULL)
    LC_ERR("memory allocation error.");

	//allocate arrays for dac and delta dac values if analog channel
  int64_t* ddc = NULL;
  int* dac_values = NULL;
  if(ch<N_A_CHANNELS){
    ddc = (int64_t*) malloc(sizeof(int64_t)*events);//long is just 32bit on RedPitaya!
    dac_values = (int*) malloc(sizeof(int)*(events+1));
    if(ddc==NULL || dac_values==NULL){
      free(dcyc);
      LC_ERR("memory allocation error.");
    }
  }

  //time[s] -> clock cycles
  for(i=0;i<events;++i){
    chs_data[2*i+1] = chs_data[2*i+1]*FCLK_HZ; //time[s] * clock frequency[Hz]
  }

  //calculate delta cycles and worst timing deviation
  dcyc[0] = round(chs_data[1]); //we use two cycles min, as the RAM might not be fast enough otherwise :(
  if(chs_data[1]<2 || chs_data[1]>MAX_DCYC){
    free(dcyc);
    if(ch<N_A_CHANNELS){
      free(ddc);
      free(dac_values);
    }
    LC_ERR("timing error at event 0. Minimal/Maximal timestep is 16ns/~34s!");
  }

  *worst_timing_dev = (dcyc[0]-chs_data[1])/chs_data[1];
  *worst_timing_ev = 0;
  *total_timing_dev = dcyc[0];

  for(i=1;i<events;++i){
    dcyc[i] = round(chs_data[2*i+1]-chs_data[2*(i-1)+1]); //32bit unsigned int should be sufficient. All integers up to 2^53 can be stored in a double without loss of precision
    if(chs_data[2*i+1]<0 || dcyc[i]<2 || (chs_data[2*i+1]-chs_data[2*(i-1)+1])>MAX_DCYC){
      free(dcyc);
      if(ch<N_A_CHANNELS){
        free(ddc);
        free(dac_values);
      }
      LC_ERR_i("timing error. Minimal/Maximal timestep is 16ns/~34s! At event ", i);
    }else{
      double t = (dcyc[i]-(chs_data[2*i+1]-chs_data[2*(i-1)+1]))/(chs_data[2*i+1]-chs_data[2*(i-1)+1]);
      if(fabs(t)>fabs(*worst_timing_dev)){
        *worst_timing_dev = t;
        *worst_timing_ev = i;
      }
    }
    *total_timing_dev += dcyc[i];
  }
  *total_timing_dev = (*total_timing_dev-chs_data[2*(events-1)+1])*8; //ns

  //check states or clip voltages & calculate delta dac values
  if(ch<N_A_CHANNELS){
    for(i=0;i<events+1;++i){
      dac_values[i] = toSignedDAC(chs_data[2*i], DAC_BITS, 2.0);//calculate DAC value (clips original value)
    }
    //calculate delta dac values, needs to be within -2^(32+DAC_BITS-1) and 2^(32+DAC_BITS-1)-1 (-> signed 32+DAC_BITS bits integer)
    for(i=0;i<events;++i){
      ddc[i] = round(pow(2, 32)*(dac_values[i+1]-dac_values[i])/dcyc[i]); // divisor is min 2; max/min vaue is 2^32*(+/-2^14 -/+1)/2 which fits in 46bit-signed; min (positive) dV/dt is ~2^(-44)*125e6 ~= 7µV/s
    }

    //calculate worst dac deviation
    int64_t dac = ((int64_t)dac_values[0])<<32;
    *worst_dac_dev = toSignedVoltage(dac>>32, DAC_BITS, 2.0)-chs_data[0]; //deviation of initial value
    *worst_dac_ev = -1; //-1 indicates inital value
    for(i=0;i<events;++i){
      dac += ddc[i]*dcyc[i];
      double d = toSignedVoltage(dac>>32, DAC_BITS, 2.0)-chs_data[2*(i+1)];
      if(fabs(d)>fabs(*worst_dac_dev)){
        *worst_dac_dev = d;
        *worst_dac_ev = i;
      }
    }
  }else{
    for(i=0;i<events+1;++i){
      if(!(chs_data[i*2]==1 || chs_data[2*i]==0)){
        free(dcyc);
        LC_ERR("invalid pin states.");
      }
    }
  }
  fpga_write(CHANNEL_OFFSET, ch);
  fpga_write(SAMPLES_OFFSET, events);
  for(i=0;i<events;++i){
    if(ch<N_A_CHANNELS)
      fpga_write_l(VALUES_OFFSET_A + 8*i, ddc[i]);
    else
      fpga_write(VALUES_OFFSET_D + 4*i, chs_data[2*(i+1)]);
    fpga_write(CYCLES_OFFSET +4*i, dcyc[i]);
  }
  fpga_write(ENABLE_OFFSET, enable);
  if(ch<N_A_CHANNELS)
    fpga_write(INITIAL_OFFSET, dac_values[0]);
  else
    fpga_write(INITIAL_OFFSET, (int)chs_data[0]);

  if(ch<N_A_CHANNELS){
    free(ddc);
    free(dac_values);
  }
  return 1;
}

scpi_result_t LC_AwaitTrigger(scpi_t * context){
  fpga_write(AWAIT_TRIGGER, 1);
  return SCPI_RES_OK;
}

scpi_result_t LC_SoftwareTrigger(scpi_t * context){
  fpga_write(SOFTWARE_TRIGGER, 1);
  return SCPI_RES_OK;
}
