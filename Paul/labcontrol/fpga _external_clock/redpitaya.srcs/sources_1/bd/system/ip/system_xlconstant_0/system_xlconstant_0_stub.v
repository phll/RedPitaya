// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.1 (lin64) Build 1846317 Fri Apr 14 18:54:47 MDT 2017
// Date        : Thu Aug 10 12:37:34 2017
// Host        : AE5UPH16 running 64-bit Ubuntu 16.04.3 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/paul/developing/workspace/RedPitaya/Paul/labcontrol/src/fpga/redpitaya.srcs/sources_1/bd/system/ip/system_xlconstant_0/system_xlconstant_0_stub.v
// Design      : system_xlconstant_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "xlconstant_v1_1_3_xlconstant,Vivado 2017.1" *)
module system_xlconstant_0(dout)
/* synthesis syn_black_box black_box_pad_pin="dout[0:0]" */;
  output [0:0]dout;
endmodule