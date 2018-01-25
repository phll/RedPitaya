`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2017 16:19:33
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: mutiple analog and digital ramp machines to drive the fast analog and digital outputs (referred to as channels) of the RedPitaya
//              data comes over AXI (one channel at once)
//              can be armed (reset) to wait on a hardware or software trigger over AXI
//              AXI registers (each 32bit) (+base address):
//              addr                | name                          | description
//              -------------------------------------------------------------------------------
//              0                   | curLCchannel                  | current channel for which data is in AXI
//              24                  | LC_reset (await_trigger)      | reset ramp machines (wait for trigger)
//              25                  | sw_trigger                    | software trigger
//              channel specific
//              1                   | enable (digital)              | set digital pin direction to 'out' (1)
//              2                   | samples                       | number of 'actual' events specified
//              3                   | ampl_IF, state_IF             | initial dc value (analog) or pin state (digital)
//              40 - 40+maxevents-1 | amount cycles for each event  | needs to be stored in block ram (maxevents differ for analog and digital channels)
//              40+maxevents -      | delta voltages per cycle or   | needs to be stored in block ram
//              "+"+(2or1)*maxev.-1 | state for each event          | analog values are stored in 64bit, therefore 2*maxev. in this case
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller #(
    parameter nChannels = 26 //2 analog, 24 digital (8 led, 8 exp_p, 8 exp_n)
)(
   // signals
   input  logic                clk_i           ,  //!< processing clock
   input  logic                rstn_i          ,  //!< processing reset - active low
   output logic     [ 14-1: 0] dat_a_o         ,  //!< output data CHA
   output logic     [ 14-1: 0] dat_b_o         ,  //!< output data CHB
   // LED(0-7) & EXP_p(8-15) , EXP_n(16-23), one could add XADC as well
   output logic     [24-1: 0]  ex_io_out       ,  //pin value
   output logic     [24-1: 0]  ex_io_dir       ,  //pin direction, 1 is 'out'
   //external trigger
   input  logic                ext_trigger     ,  //triggers on falling edge!                               

   // system bus
   input  logic      [ 32-1: 0] sys_addr        ,  //!< bus address
   input  logic      [ 32-1: 0] sys_wdata       ,  //!< bus write data
   input  logic                 sys_wen         ,  //!< bus write enable
   input  logic                 sys_ren         ,  //!< bus read enable
   output reg        [ 32-1: 0] sys_rdata       ,  //!< bus read data
   output reg                   sys_err         ,  //!< bus error indicator
   output reg                   sys_ack            //!< bus acknowledge signal
);

//RAM addresses (for writing)
localparam LC_CHANNEL_OFFSET        = 0         ;//offset in WORDS (4 bytes) to the channel that we are currently writing to!

localparam LC_awaittrigger_OFFSET   = 24        ;//offset in WORDS (4 bytes) to address where we write ANYTHING to tell system to reset and await trigger
localparam LC_swtrigger_OFFSET      = 25        ;//offset in WORDS (4 bytes) to address where we write ANYTHING to give the system a software trigger!

logic sw_trigger=0;//the trigger can be hardware (below) or software (here)


logic[7:0] curLCchannel=0;  //current channel for which data is in axi
logic LC_reset = 0;         //reset sequences

//---------------------------Trigger debouncer and edge detector!

logic [5:0] trig_debouncer;
logic debouncedHWtriggerRisingEdge = trig_debouncer[5]&!trig_debouncer[4]; //triggers on falling edge of physical signal!
always @(posedge clk_i) begin
    trig_debouncer[0  ] <= ext_trigger; //NEW CODE -- MIGHT BE A PROBLEM! USED TO JUST BE ZERO!
    trig_debouncer[5:1] <= trig_debouncer[4:0];
end


//create two analog ramp machines (for DAC A & B)
Analog_ramp_machine analog_A
        (
           // signals
           .clk_i           (   clk_i                                             ),
           .rstn_i          (   rstn_i                                            ),
           .trigger_edge    (   debouncedHWtriggerRisingEdge | sw_trigger         ),
           .reset           (   LC_reset                                          ),

           .wen             (   sys_wen & (curLCchannel==0)                       ),//notice the machine when there is data for this channel
           .addr            (   sys_addr                                          ),
           .wdata           (   sys_wdata                                         ),

           .d_out           (   dat_a_o                                           )
        );
        
Analog_ramp_machine analog_B
        (
            // signals
            .clk_i           (   clk_i                                             ),
            .rstn_i          (   rstn_i                                            ),
            .trigger_edge    (   debouncedHWtriggerRisingEdge | sw_trigger ),
            .reset           (   LC_reset                                          ),
        
            .wen             (   sys_wen & (curLCchannel==1)                       ),
            .addr            (   sys_addr                                          ),
            .wdata           (   sys_wdata                                         ),
        
            .d_out           (   dat_b_o                                           )
          );

//create digital ramp machines for the 24 digital I/O-pins (and leds)
genvar t;
generate
	for ( t = 2; t < nChannels; t = t+1 )
	begin: DigMachs

	    Digital_ramp_machine dig_machs
                (
                   // signals
                   .clk_i           (   clk_i                                             ),
                   .rstn_i          (   rstn_i                                            ),
                   .trigger_edge    (   debouncedHWtriggerRisingEdge | sw_trigger ),
                   .reset           (   LC_reset                                          ),
        
                   .wen             (   sys_wen & (curLCchannel==t)                       ),
                   .addr            (   sys_addr                                          ),
                   .wdata           (   sys_wdata                                         ),
                           
                   .d_out           (   ex_io_out[t-2]                                    ),
                   .d_dir           (   ex_io_dir[t-2]                                    )
                );
	end
endgenerate



//---------------------------------------------------------------------------------
//
//  System bus connection (channel specific data is retrieved in the ramp modules)

always @(posedge clk_i) begin
   //each of these should only be high for a single cycle!
   sw_trigger <= 0;
   LC_reset   <= 0;
   if (rstn_i == 1'b0) begin
    ;
   end
   else begin
      if (sys_wen) begin
          if (sys_addr[19:2]==LC_awaittrigger_OFFSET)  LC_reset <= 1;
          if (sys_addr[19:2]==LC_swtrigger_OFFSET) sw_trigger <= 1;
          if (sys_addr[19:2]==LC_CHANNEL_OFFSET) curLCchannel <= sys_wdata[7:0]; 
      end
   end
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i)
if (rstn_i == 1'b0) begin
   sys_err <= 1'b0 ;
   sys_ack <= 1'b0 ;
end else begin
   sys_err <= 1'b0 ;

   casez (sys_addr[19:0])

     default : begin sys_ack <= sys_en;          sys_rdata <=  32'h0                              ; end
   endcase
end

endmodule

//---------------------------------------------------------------------------------
// A parameterized, inferable, true dual-port, dual-clock block RAM in Verilog.
// here we store all the event data (each machine has its own bram)!
 
module bram_tdp #(
    //size per sample
    parameter DATA = 72,
    //amount of samples
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
    a_dout      <= mem[a_addr];         //a_dout is delayed by one cycle in relation to a change in a_addr!! Therefore, the min time step is 16ns (2 cycles)
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


//---------------------------------------------------------------------------------
// RAMP-Machines

//start with intitial dc value, the sweep to next dc value by adding damp for given amount of cycles
module Analog_ramp_machine #(

parameter maxevents=1024*4                ,     
parameter EVENTRAMwidth=clog2j(maxevents) ,     //width of the ram address
parameter OutputWidth = 14                      //number of bits in the DAC output, allowing for amplitude control

) (
   // signals
   input                      clk_i           ,  //!< processing clock
   input                      rstn_i          ,  //!< processing reset - active low

   input                      trigger_edge    ,  //trigger from the outside world--rising edge -- software and hardware!!
   input                      reset           ,  //reset the ramp machine and await trigger!

   input                      wen             ,  //there is data to write!
   input [32-1:0]             addr            ,  //address that we are currently writing to
   input [32-1:0]             wdata           ,  //data coming in

   output [OutputWidth-1:0]   d_out              //output voltage
);
//==== VARIABLE DEFINITIONS ==== //

reg  [14-1:0] amp_IF;     //initial amplitude              

reg rampdone = 1; //is the ramp done?

//RAM ADDRESSES
localparam samples_OFFSET     = 2         ;//offset in WORDS (4 bytes) to # of samples for the current channel
localparam amp_IF_OFFSET      = 3         ;//offset in WORDS (4 bytes) to the initial/final amp for the current channel

//EXPECT LOW WORD AT LOWER MEMORY ADDRESS FOR FREQS (FTW) RAMS!
localparam cycles_OFFSET           = 40    ; //offset in WORDS to the first  element of the current cyc. list
localparam amps_OFFSET             = cycles_OFFSET + maxevents*1    ; //offset in WORDS to the first  element of the current amp list
localparam amps_last_OFFSET        = amps_OFFSET   + maxevents*2 - 1; //offset in WORDS to the last   element of the current amp list, *2 since we need 2 floats per amp value
//localparam cycles_last_OFFSET    = cycles_OFFSET + maxevents*1 ;//offset in WORDS to the last  element of the current cyc. list


reg  [14+32+1-1:0] ampfull;                   //this is the full amp, with even more extra bits to smooth the ramp, + 1bit to detect overflow
assign d_out = ampfull[14+32-1:32];

reg [16-1:0] nextlistind;                  //current index in the ramp ram
reg [16-1:0] listlen;                      //total number of ramps in the ram
reg [32-1:0] rampcyclesremaining;          //number of cycles remaining in current ramp
reg signed [14+32-1:0] damp=0;            //how much to step the amp in each clock cycle
reg channelawaitingtrigger=0;              //awaiting trigger?!

//RAM control registers
wire [32+14+32-1:0] memout;//RAM output register
reg  [32+14+32-1:0] inf;   //input register for the RAM (32+14 for damp, 32 for #cycles) -- where data is accumulated over AXI bus before writing! (maybe a mask would be more efficient?!)
reg  [19:0] memaddr;
reg wrmem=1'b0;

wire [18-1:0] Addr_da= addr[19:2]-amps_OFFSET;
wire [18-1:0] Addr_dc= addr[19:2]-cycles_OFFSET;

//save data from axi 
bram_tdp #(.DATA(32+14+32),.ADDR(EVENTRAMwidth)) mem(.a_clk(clk_i),.a_wr(wrmem),.a_addr(memaddr),.a_din(inf),.b_clk(clk_i),.b_wr(1'b0),.b_addr(nextlistind),.b_dout(memout));

//MEMORY MAP CONTROL LOOP
always @(posedge clk_i) begin
    wrmem <= 1'b0;
    if (rstn_i == 1'b0) begin
      ;//do nothing
    end
    else begin
        if (wen) begin
            if (addr[19:2]==samples_OFFSET) listlen <= wdata[16-1:0];
            else if (addr[19:2]==amp_IF_OFFSET) amp_IF <= wdata[14-1:0];
            
            //read and save event-data; has to happen before starting the sequence
            else if ((addr[19:2]>=cycles_OFFSET)&&(addr[19:2]<amps_OFFSET)) begin
                    inf[32-1:0]          <= wdata[32-1:0];          
                    memaddr                  <= Addr_dc; //write to the memory at the correct address
                    wrmem                    <= 1'b1;
            end
            else if ((addr[19:2]>=amps_OFFSET)&&(addr[19:2]<=amps_last_OFFSET)) begin
                if(Addr_da[0]==1'b0) begin
                    inf[32+32-1:32]          <= wdata[32-1:0]; //low word
                end
                else begin
                    inf[32+14+32-1:32+32]    <= wdata[14-1:0]; //high word
                end
            end
        end
    end
end

//RAMP CONTROL LOOP
always @(posedge clk_i) begin
//FSM
    if ((rampdone==1)||(reset==1)) begin //if both DDS's are done, then go back to waiting for a trigger!
            channelawaitingtrigger <= 1;
    end
    if(channelawaitingtrigger==1) begin //if we are waiting to be triggered
        nextlistind <= 0;
        ampfull  <= {amp_IF[14-1], amp_IF, 32'b0};
        if (trigger_edge==1) begin //if we just got trigger rising edge
            channelawaitingtrigger <= 0;
            rampcyclesremaining <=0;
            damp <= 0;
            rampdone <=0;
        end
    end 
    else begin //otherwise the FSM should be running!
        if (rampdone==1) begin
            ;
        end
        else if (rampcyclesremaining == 0) begin
            if(nextlistind<listlen) begin
                rampcyclesremaining <= memout[32-1:0]-1; //this pulse already contributes!
                damp <= memout[32+14+32-1:32];
                ampfull = $signed(ampfull) + $signed(memout[32+14+32-1:32]); //this pulse already contributes!
                
                //check for overflow
                if (ampfull[33+14-1:33+14-2] == 2'b01) // positive saturation
                    ampfull <= {1'b0,14'd8191, 32'b0}; // max positive
                else if (ampfull[33+14-1:33+14-2] == 2'b10) // negative saturation
                    ampfull <= {1'b1,14'h2000, 32'b0}; // max negative
                    
                nextlistind <= nextlistind + 1;  //memout is updated (can be used) in the cycle after the next one -> min timestep is 2 cycles
            end
            else begin
                rampdone <= 1;
                damp    <= 0;
            end
        end
        else begin
            ampfull = $signed(ampfull) + $signed(damp); 
            
            //check for overflow
            if (ampfull[33+14-1:33+14-2] == 2'b01) // positive saturation
                ampfull <= {1'b0,14'd8191, 32'b0}; // max positive
            else if (ampfull[33+14-1:33+14-2] == 2'b10) // negative saturation
                ampfull <= {1'b1,14'h2000, 32'b0}; // max negative
                
            rampcyclesremaining <= rampcyclesremaining - 1;
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

//start with initial state, then change to the next state after a given amount of cycles
module Digital_ramp_machine #(

parameter maxevents=128                 ,     
parameter EVENTRAMwidth=clog2j(maxevents)      //width of the ram address
) (
   // signals
   input                      clk_i           ,  //!< processing clock
   input                      rstn_i          ,  //!< processing reset - active low

   input                      trigger_edge    ,  //trigger from the outside world--rising edge -- software and hardware!!
   input                      reset           ,  //reset the ramp machine and await trigger!

   input                      wen             ,  //there is data to write!
   input [32-1:0]             addr            ,  //address that we are currently writing to
   input [32-1:0]             wdata           ,  //data coming in
   
   output logic               d_out           ,  //pin value
   output logic               d_dir              //pin direction (if pin is enabled/driven this is set to 1/'out')
);
//==== VARIABLE DEFINITIONS ==== //

logic state_IF, state_next;

logic enable;

reg rampdone = 1; //is the ramp done?

//RAM ADDRESSES
localparam enable_OFFSET      = 1         ;//offset in WORDS (4 bytes) to the pin number
localparam samples_OFFSET     = 2         ;//offset in WORDS (4 bytes) to # of samples for the current channel
localparam state_IF_OFFSET    = 3         ;//offset in WORDS (4 bytes) to the initial/final state for the current channel

//EXPECT LOW WORD AT LOWER MEMORY ADDRESS FOR FREQS (FTW) RAMS!
localparam cycles_OFFSET           = 40    ; //offset in WORDS to the first  element of the current cyc. list
localparam states_OFFSET             = cycles_OFFSET + maxevents    ; //offset in WORDS to the first  element of the current states list
localparam states_last_OFFSET        = states_OFFSET   + maxevents - 1; //offset in WORDS to the last   element of the current states list
//localparam cycles_last_OFFSET    = cycles_OFFSET + maxevents*1 ;//offset in WORDS to the last  element of the current cyc. list


reg [16-1:0] nextlistind;                  //current index in the DDS ramp ram
reg [16-1:0] listlen;                      //total number of ramps in the ram
reg [32-1:0] rampcyclesremaining;          //number of cycles remaining in current ramp
reg channelawaitingtrigger=0;              //awaiting trigger?!

//RAM control registers
wire [1+32-1:0] memout;//RAM output register
reg  [1+32-1:0] inf;   //input register for the RAM (32 for #cycles, 1 for the state) -- where data is accumulated over AXI bus before writing! (maybe a mask would be more efficient?!)
reg  [19:0] memaddr;
reg wrmem=1'b0;

wire [18-1:0] Addr_dc= addr[19:2]-cycles_OFFSET;

//save data from axi 
bram_tdp #(.DATA(1+32),.ADDR(EVENTRAMwidth)) mem(.a_clk(clk_i),.a_wr(wrmem),.a_addr(memaddr),.a_din(inf),.b_clk(clk_i),.b_wr(1'b0),.b_addr(nextlistind),.b_dout(memout));


//MEMORY MAP CONTROL LOOP
always @(posedge clk_i) begin
    wrmem <= 1'b0;
    if (rstn_i == 1'b0) begin
      ;//do nothing
    end
    else begin
        if (wen) begin
            if (addr[19:2]==enable_OFFSET) enable <= wdata[0];
            else if (addr[19:2]==samples_OFFSET) listlen <= wdata[16-1:0];
            else if (addr[19:2]==state_IF_OFFSET) state_IF <= wdata[14-1:0];
            
            //read and save event-data; has to happen before starting the ramp
            else if ((addr[19:2]>=cycles_OFFSET)&&(addr[19:2]<states_OFFSET)) begin
                    inf[32-1:0]          <= wdata[32-1:0];          
                    memaddr                  <= Addr_dc; //write to the memory at the correct address
                    wrmem                    <= 1'b1;
            end
            else if ((addr[19:2]>=states_OFFSET)&&(addr[19:2]<=states_last_OFFSET)) begin
                inf[32+1-1:32]          <= wdata[0];
            end
        end
    end
end


//RAMP CONTROL LOOP
always @(posedge clk_i) begin
    d_dir = enable;
    if(enable) begin
        //FSM
        if ((rampdone==1)||(reset==1)) begin //if both DDS's are done, then go back to waiting for a trigger!
                channelawaitingtrigger <= 1;
        end
        if(channelawaitingtrigger==1) begin //if we are waiting to be triggered
            d_out <= state_IF;
            state_next <= state_IF;
            nextlistind <= 0;
            if (trigger_edge==1) begin //if we just got trigger rising edge
                channelawaitingtrigger <= 0;
                rampcyclesremaining <=4; //wait 4 cycles until starting the ramp, because Analog output is somehow delayed 
                
                rampdone <=0;
            end
        end 
        else begin //otherwise the FSM should be running!
            if (rampdone==1) begin
                ;
            end
            else if (rampcyclesremaining == 0) begin
                if(nextlistind<listlen) begin
                    rampcyclesremaining <= memout[32-1:0] - 1;//this pulse already contributes!
                    d_out <= state_next;
                    state_next <= memout[32+1-1:32];
                    nextlistind <= nextlistind + 1; //memout is updated (can be used) in the cycle after the next one -> min timestep is 2 cycles
                end
                else begin
                    rampdone <= 1;
                end
            end
            else begin
                rampcyclesremaining <= rampcyclesremaining - 1;
            end
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



