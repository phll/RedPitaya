/**
 * $Id: red_pitaya_pid.v 961 2014-01-21 11:40:39Z matej.oblak $
 *
 * @brief Red Pitaya MIMO PID controller.
 *
 * @Author Matej Oblak
 *
 * (c) Red Pitaya  http://www.redpitaya.com
 *
 * This part of code is written in Verilog hardware description language (HDL).
 * Please visit http://en.wikipedia.org/wiki/Verilog
 * for more details on the language used herein.
 */


module red_pitaya_pid #(
   parameter	AnalogInterfaceWidth = 14,   //this is the width of the ADC/DAC input/output -- may eventually be wider due to averaging  --these regs are signed!!
   parameter    nDDSfreqs            = 10,    //2!! WE NEED TO MAINTAIN DYNAMIC RANGE SO THAT WE DONT OVERRUN OUR BITS! too many channels will do this!
   parameter    maxevents            = 64*16,
   parameter    OutputWidth          = 14
)
(
   // signals
   input                 clk_i           ,  //!< processing clock
   input                 rstn_i          ,  //!< processing reset - active low
   input      [ AnalogInterfaceWidth-1: 0] dat_a_i         ,  //!< input data CHA
   input      [ AnalogInterfaceWidth-1: 0] dat_b_i         ,  //!< input data CHB
   output     [ AnalogInterfaceWidth-1: 0] dat_a_o         ,  //!< output data CHA
   output     [ AnalogInterfaceWidth-1: 0] dat_b_o         ,  //!< output data CHB
   input      physicaltrigger,                                //the physical trigger from the outside world

   // system bus
   input                 sys_clk_i       ,  //!< bus clock
   input                 sys_rstn_i      ,  //!< bus reset - active low
   input      [ 32-1: 0] sys_addr_i      ,  //!< bus address
   input      [ 32-1: 0] sys_wdata_i     ,  //!< bus write data
   input      [  4-1: 0] sys_sel_i       ,  //!< bus write byte select
   input                 sys_wen_i       ,  //!< bus write enable
   input                 sys_ren_i       ,  //!< bus read enable
   
   output     [ 32-1: 0] sys_rdata_o     ,  //!< bus read data
   output                sys_err_o       ,  //!< bus error indicator
   output                sys_ack_o          //!< bus acknowledge signal
);

wire [ 32-1: 0] addr         ;
wire [ 32-1: 0] wdata        ;
wire            wen          ;
wire            ren          ;
reg  [ 32-1: 0] rdata        ;
reg             err          ;
reg             ack          ;

//RAM addresses (for writing)
localparam DDS_CHANNEL_OFFSET    = 0         ;//offset in WORDS (4 bytes) to the channel that we are currently writing to!

localparam DDSawaittrigger_OFFSET      = 24        ;//offset in WORDS (4 bytes) to address where we write ANYTHING to tell system to reset and await trigger
localparam DDSsoftwaretrigger_OFFSET   = 25        ;//offset in WORDS (4 bytes) to address where we write ANYTHING to give the system a software trigger!
localparam phase_reset_OFFSET          = 26        ;//offset in WORDS (4 bytes) to address where we write 1 or 0 to specify wether to reset phase a sequence start or not

//REGISTERS FOR FSM
reg DDSawaitingtrigger=1;//when we start, we must await a trigger!
reg DDSsoftwaretrigger=0;//the trigger can be hardware (below) or software (here)
reg phase_reset=0;       //reset phase when starting sequence?

assign dat_a_o = $signed(DDSfreqs[nDDSfreqs-1].SumDataA);//<<<(AnalogInterfaceWidth-SineWidth);
assign dat_b_o = $signed(DDSfreqs[nDDSfreqs-1].SumDataB);//<<<(AnalogInterfaceWidth-SineWidth);

reg [7:0] curDDSchannel=0; //we assume that each DAC won't support more than 256 DDS's!
reg DDSreset = 0;

//---------------------------Trigger debouncer and edge detector!

reg [5:0] trig_debouncer;
wire debouncedHWtriggerRisingEdge = trig_debouncer[5]&!trig_debouncer[4];
always @(posedge clk_i) begin
    trig_debouncer[0  ] <= physicaltrigger; //NEW CODE -- MIGHT BE A PROBLEM! USED TO JUST BE ZERO!
    trig_debouncer[5:1] <= trig_debouncer[4:0];
end

//---------------------------ADD UP PARTIAL SUMS!
genvar tDDS;
generate
	for ( tDDS = 0; tDDS < nDDSfreqs; tDDS = tDDS+1 )
	begin: DDSfreqs

        wire [OutputWidth-1:0]    SigOutA;
        wire [OutputWidth-1:0]    SigOutB;
        reg  [OutputWidth+10-1:0] SumDataA;
        reg  [OutputWidth+10-1:0] SumDataB;

	    DDS_machine #(.maxevents(maxevents), .OutputWidth(OutputWidth) ) DDS_machs
        (
           // signals
           .clk_i           (   clk_i                                             ),
           .rstn_i          (   rstn_i                                            ),
           .trigger_edge    (   debouncedHWtriggerRisingEdge | DDSsoftwaretrigger ),
           .phase_reset     (   phase_reset                                       ),
           .DDSreset        (   DDSreset                                          ),

           .wen             (   wen & (curDDSchannel==tDDS)                       ),
           .addr            (   addr                                              ),
           .wdata           (   wdata                                             ),

           .DDSout_I        (   SigOutA                                           ),//DDS output I data
           .DDSout_Q        (   SigOutB                                           ) //DDS output Q data

        );
	end
endgenerate

always @(posedge clk_i) begin
    DDSfreqs[0].SumDataA        <= $signed(DDSfreqs[0].SigOutA);
    DDSfreqs[0].SumDataB        <= $signed(DDSfreqs[0].SigOutB);
end

genvar tIND;
generate
    for ( tIND = 1; tIND < nDDSfreqs; tIND = tIND+1 )
    begin
        always @(posedge clk_i) begin
            DDSfreqs[tIND].SumDataA <= $signed(DDSfreqs[tIND-1].SumDataA)+$signed(DDSfreqs[tIND].SigOutA);
            DDSfreqs[tIND].SumDataB <= $signed(DDSfreqs[tIND-1].SumDataB)+$signed(DDSfreqs[tIND].SigOutB);
        end
    end
endgenerate

//---------------------------------------------------------------------------------
//
//  System bus connection

always @(posedge clk_i) begin
   //each of these should only be high for a single cycle!
   DDSsoftwaretrigger <= 0;
   DDSreset           <= 0;
   
   if (rstn_i == 1'b0) begin
      ;//do nothing
   end
   else begin
      if (wen) begin
        //memory addresses for DDS
         if (addr[19:2]     ==           DDSawaittrigger_OFFSET) begin
            DDSreset <= 1;
         end
          
         if (addr[19:2]     ==           DDSsoftwaretrigger_OFFSET) begin
            DDSsoftwaretrigger <= 1;
         end
         
         if (addr[19:2]     ==           phase_reset_OFFSET) begin
            if(wdata[1:0]==1) begin
              phase_reset = 1;
            end
            else begin
              phase_reset = 0;
            end
         end
         
         if (addr[19:2]     ==           DDS_CHANNEL_OFFSET) begin
            curDDSchannel <= wdata[7:0];
         end
      end     
   end
end


always @(posedge clk_i) begin
   err <= 1'b0 ;
   casez (addr[19:2])
     default      : begin ack <= 1'b1;          rdata <=  32'h0                              ; end
   endcase
end

// bridge between processing and sys clock
bus_clk_bridge i_bridge
(
   .sys_clk_i     (  sys_clk_i      ),
   .sys_rstn_i    (  sys_rstn_i     ),
   .sys_addr_i    (  sys_addr_i     ),
   .sys_wdata_i   (  sys_wdata_i    ),
   .sys_sel_i     (  sys_sel_i      ),
   .sys_wen_i     (  sys_wen_i      ),
   .sys_ren_i     (  sys_ren_i      ),
   .sys_rdata_o   (  sys_rdata_o    ),
   .sys_err_o     (  sys_err_o      ),
   .sys_ack_o     (  sys_ack_o      ),

   .clk_i         (  clk_i          ),
   .rstn_i        (  rstn_i         ),
   .addr_o        (  addr           ),
   .wdata_o       (  wdata          ),
   .wen_o         (  wen            ),
   .ren_o         (  ren            ),
   .rdata_i       (  rdata          ),
   .err_i         (  err            ),
   .ack_i         (  ack            )
);

function integer clog2j;
input integer value;
begin 
value = value-1;
for (clog2j=0; value>0; clog2j=clog2j+1)
value = value>>1;
end 
endfunction

endmodule

//---------------------------------------------------------------------------------
// A parameterized, inferable, true dual-port, dual-clock block RAM in Verilog.
 
module bram_tdp #(
    parameter DATA = 72,
    parameter ADDR = 10
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
     
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);
 
// Shared memory
reg [DATA-1:0] mem [(2**ADDR)-1:0];
 
// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        a_dout      <= a_din;
        mem[a_addr] <= a_din;
    end
end
 
// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end
 
endmodule


module DDS_machine #(

parameter maxevents=64*16                 ,     //maximum number of linear ramps the DDS channel can handle!
parameter EVENTRAMwidth=clog2j(maxevents) ,     //width of the ram address
parameter OutputWidth = 14                      //number of bits in the DDS output, allowing for amplitude control

) (
   // signals
   input                      clk_i           ,  //!< processing clock
   input                      rstn_i          ,  //!< processing reset - active low

   input                      trigger_edge    ,  //trigger from the outside world--rising edge -- software and hardware!!
   input                      phase_reset     ,   //reset phase when starting sequence
   input                      DDSreset        ,  //reset the DDS and await trigger!

   input                      wen             ,  //there is data to write!
   input [32-1:0]             addr            ,  //address that we are currently writing to
   input [32-1:0]             wdata           ,  //data coming in

   output [OutputWidth-1:0]   DDSout_I,             //DDS output I data
   output [OutputWidth-1:0]   DDSout_Q              //DDS output Q data
);

//==== VARIABLE DEFINITIONS ==== //
reg [32-1:0] DDSftw_IF=0;  //Initial/Final FTW: high 32 bits only
reg [14-1:0] DDSamp_IF=0;  //Initial/Final amp: high 14 bits only

reg DDSrampdone = 1; //is the ramp done?

//RAM ADDRESSES
localparam DDSftw_IF_OFFSET      = 1         ;//offset in WORDS (4 bytes) to the initial/final FTW for the current channel
localparam DDSsamples_OFFSET     = 2         ;//offset in WORDS (4 bytes) to # of samples for the current channel
localparam DDSamp_IF_OFFSET      = 3         ;//offset in WORDS (4 bytes) to the initial/final amp for the current channel

//EXPECT LOW WORD AT LOWER MEMORY ADDRESS FOR FREQS (FTW) RAMS!
localparam DDSfreqs_OFFSET            = 40                                ; //offset in WORDS to the first  element of the current freq list
localparam DDScycles_OFFSET           = DDSfreqs_OFFSET  + maxevents*2    ; //offset in WORDS to the first  element of the current cyc. list
localparam DDSamps_OFFSET             = DDScycles_OFFSET + maxevents*1    ; //offset in WORDS to the first  element of the current amp list
localparam DDSamps_last_OFFSET        = DDSamps_OFFSET   + maxevents*2 - 1; //offset in WORDS to the last   element of the current amp list
//localparam DDScycles_last_OFFSET    = DDScycles_OFFSET + maxevents*1 ;//offset in WORDS to the last  element of the current cyc. list

//DDS INDEXER
localparam DDSindbits=32;
localparam DDSfracbits=DDSindbits-SineTableAddrBits;
reg [DDSindbits-1:0] DDSind;
reg [DDSindbits-1-DDSfracbits:0] DDSind_red;  //temporary register which holds DDSind 'devided' by 2^DDSfracbits

//DDS connection controller
localparam  DDSDataWidth = OutputWidth;      //assuming this is bigger than SineWidth!
reg signed [DDSDataWidth-1:0] DDS_unscaled_I;  //unscaled DDS output for I-data
reg signed [DDSDataWidth-1:0] DDS_unscaled_Q;  //unscaled DDS output for Q-data


//DDS control parameters
reg [64-1:0]     DDSftwfull;                   //this is the full FTWs, with even more extra bits so the ramp will be smooth!
wire [32-1:0]    DDSftw=DDSftwfull[64-1:32];   //current FTW for outputting
reg  [14+32-1:0] DDSampfull;                   //this is the full DDS amp, with even more extra bits to smooth the ramp
wire [14-1:0]    DDSamp=DDSampfull[14+32-1:32];//current amp for multiplying-- right now amplitude jumps but frequency sweeps!

//DDS ramp controller
reg [16-1:0] DDSnextlistind;                  //current index in the DDS ramp ram
reg [16-1:0] DDSlistlen;                      //total number of ramps in the ram
reg [32-1:0] DDSrampcyclesremaining;          //number of cycles remaining in current ramp
reg signed [64-1:0]    DDS_dftw=0;            //how much to step the FTW in each clock cycle
reg signed [14+32-1:0] DDS_damp=0;            //how much to step the amp in each clock cycle
reg DDSchannelawaitingtrigger=0;              //awaiting trigger?!

//RAM control registers
wire [64+32+14+32-1:0] memout;//RAM output register
reg  [64+32+14+32-1:0] inf;   //input register for the RAM -- where data is accumulated over AXI bus before writing! (maybe a mask would be more efficient?!)
reg  [19:0] memaddr;
reg wrmem=1'b0;

//Sine/Cosine Lookup Tables
localparam SineWidth=14;                             //bit width of each element of the sine table
localparam SineDepth=256;                            //number of elements in the sine table -- it seems if we go above 256 the lut ram doesn't work?! weird...
localparam SineTableAddrBits = clog2j(SineDepth);    //log of the number of elements in the sine table

wire [18-1:0] DDS_Addr_df= addr[19:2]-DDSfreqs_OFFSET;
wire [18-1:0] DDS_Addr_da= addr[19:2]-DDSamps_OFFSET;
wire [18-1:0] DDS_Addr_dc= addr[19:2]-DDScycles_OFFSET;

reg signed [SineWidth-1:0] SineLookup[0:SineDepth-1];
initial 
    $readmemh("sinetable256x14bit.txt", SineLookup, 0, SineDepth-1);

//bram_tdp #(.DATA(14+64+32),.ADDR(EVENTRAMwidth)) DDS_mem(.a_clk(clk_i),.a_wr(wrmem),.a_addr(addr[19:2]-DDScycles_OFFSET),.a_din({wdata[14-1:0],inf[64+32-1:0]}),.b_clk(clk_i),.b_wr(1'b0),.b_addr(DDSnextlistind),.b_dout(memout));
bram_tdp #(.DATA(32+14+64+32),.ADDR(EVENTRAMwidth)) DDS_mem(.a_clk(clk_i),.a_wr(wrmem),.a_addr(memaddr),.a_din(inf),.b_clk(clk_i),.b_wr(1'b0),.b_addr(DDSnextlistind),.b_dout(memout));

localparam DDSamp_fracbits = 14;                      //all 14 of the DDS bits are fractional (of course-- cant go bigger than max)!

//assign DDSout = (($signed({1'b0,DDSamp})*$signed(DDS_unscaled))<<<(OutputWidth-SineWidth))>>>DDSamp_fracbits;
//assign DDSout = ($signed({1'b0,DDSamp})*$signed(DDS_unscaled))<<<(OutputWidth-SineWidth);
wire [31:0] DDSintermediate_I=($signed({1'b0,DDSamp})*$signed(DDS_unscaled_I));//need this to make sure multiplication uses enough bits!
wire [31:0] DDSintermediate_Q=($signed({1'b0,DDSamp})*$signed(DDS_unscaled_Q));//need this to make sure multiplication uses enough bits!
assign DDSout_I = ((DDSintermediate_I<<<(OutputWidth-SineWidth))>>>DDSamp_fracbits);
assign DDSout_Q = ((DDSintermediate_Q<<<(OutputWidth-SineWidth))>>>DDSamp_fracbits);

//MEMORY MAP CONTROL LOOP
always @(posedge clk_i) begin
    wrmem <= 1'b0;
    if (rstn_i == 1'b0) begin
      ;//do nothing
    end
    else begin
        if (wen) begin
        //memory addresses for DDS         
            if (addr[19:2]==                DDSftw_IF_OFFSET) begin
                DDSftw_IF         <= wdata[32-1:0];
            end
            else if (addr[19:2]==           DDSsamples_OFFSET) begin
                DDSlistlen        <= wdata[16-1:0];
            end
            else if (addr[19:2]==           DDSamp_IF_OFFSET) begin
                DDSamp_IF         <= wdata[14-1:0];
            end
            
            else if ((addr[19:2]>=DDSfreqs_OFFSET)&&(addr[19:2]<DDScycles_OFFSET)) begin
                if(DDS_Addr_df[0]==1'b0) begin
                    inf[32-1:0]          <= wdata[32-1:0];
                end
                else begin
                    inf[64-1:32]         <= wdata[32-1:0];
                end
            end
            else if ((addr[19:2]>=DDScycles_OFFSET)&&(addr[19:2]<DDSamps_OFFSET)) begin
                    inf[64+32-1:64]          <= wdata[32-1:0];
                    
                    memaddr                  <= DDS_Addr_dc; //write to the memory at the correct address
                    wrmem                    <= 1'b1;
            end
            else if ((addr[19:2]>=DDSamps_OFFSET)&&(addr[19:2]<=DDSamps_last_OFFSET)) begin
                if(DDS_Addr_da[0]==1'b0) begin
                    inf[64+32+32-1:64+32]          <= wdata[32-1:0]; //low word
                end
                else begin
                    inf[64+32+14+32-1:64+32+32]    <= wdata[14-1:0]; //high word
                end
            end
        end
    end
end

//DDS CONTROL LOOP
always @(posedge clk_i) begin
//THIS IS WHERE WE DEFINE THE DDS SIGNAL
    DDSind       <= DDSind + DDSftw;
    DDSind_red   <= DDSind>>DDSfracbits;
    DDS_unscaled_I <= $signed(  SineLookup[DDSind_red%SineDepth]);
    DDS_unscaled_Q <= $signed(  SineLookup[(DDSind_red+64)%SineDepth]);   //64 corresponds to a phase shift of 90° (64*2*Pi/256 = Pi/2)
//DDS FSM
    if ((DDSrampdone==1)||(DDSreset==1)) begin //if both DDS's are done, then go back to waiting for a trigger!
            DDSchannelawaitingtrigger <= 1;
    end
    if(DDSchannelawaitingtrigger==1) begin //if we are waiting to be triggered
        DDSftwfull  <= {DDSftw_IF,32'b0};
        DDSampfull  <= {DDSamp_IF,32'b0};
        DDSnextlistind <= 0;
        if (trigger_edge==1) begin //if we just got trigger rising edge
            DDSchannelawaitingtrigger <= 0;
            DDSrampcyclesremaining <=0;
            
            DDS_dftw <= 0;
            DDS_damp <= 0;
            
            if(phase_reset==1) begin
              DDSind <= 32'b0; //(leads to unsmooth behaviour at start)
            end
            
            DDSrampdone <=0;
        end
    end 
    else begin //otherwise the FSM should be running!
//        DDSftwfull <= $signed({1'b0,DDSftwfull}) + $signed(DDS_dftw);
//        DDSampfull <= $signed({1'b0,DDSampfull}) + $signed(DDS_damp);
        if (DDSrampdone==1) begin
            ;
        end
        else if (DDSrampcyclesremaining == 0) begin
            if(DDSnextlistind<DDSlistlen) begin
                DDS_dftw <= memout[64-1:0];
                DDSrampcyclesremaining <= memout[64+32-1:64];
                DDS_damp <= memout[64+32+14+32-1:64+32];
                DDSnextlistind <= DDSnextlistind + 1;
            end
            else begin
                DDSrampdone <= 1;
                DDS_dftw    <= 0;
                DDS_damp    <= 0;
            end
        end
        else begin
            DDSftwfull <= $signed({1'b0,DDSftwfull}) + $signed(DDS_dftw);
            DDSampfull <= $signed({1'b0,DDSampfull}) + $signed(DDS_damp);
            DDSrampcyclesremaining <= DDSrampcyclesremaining - 1;
        end
    end
end

function integer clog2j;
    input integer value;
    begin
        value = value-1;
        for (clog2j=0; value>0; clog2j=clog2j+1)
            value = value>>1;
    end
endfunction

endmodule