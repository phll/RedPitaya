vlib work
vlib msim

vlib msim/generic_baseblocks_v2_1_0
vlib msim/fifo_generator_v13_1_4
vlib msim/axi_data_fifo_v2_1_11
vlib msim/axi_infrastructure_v1_1_0
vlib msim/axi_register_slice_v2_1_12
vlib msim/axi_protocol_converter_v2_1_12
vlib msim/xil_defaultlib
vlib msim/lib_cdc_v1_0_2
vlib msim/proc_sys_reset_v5_0_11
vlib msim/xil_common_vip_v1_0_0
vlib msim/smartconnect_v1_0
vlib msim/axi_protocol_checker_v1_1_13
vlib msim/axi_vip_v1_0_1
vlib msim/xlconstant_v1_1_3

vmap generic_baseblocks_v2_1_0 msim/generic_baseblocks_v2_1_0
vmap fifo_generator_v13_1_4 msim/fifo_generator_v13_1_4
vmap axi_data_fifo_v2_1_11 msim/axi_data_fifo_v2_1_11
vmap axi_infrastructure_v1_1_0 msim/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_12 msim/axi_register_slice_v2_1_12
vmap axi_protocol_converter_v2_1_12 msim/axi_protocol_converter_v2_1_12
vmap xil_defaultlib msim/xil_defaultlib
vmap lib_cdc_v1_0_2 msim/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_11 msim/proc_sys_reset_v5_0_11
vmap xil_common_vip_v1_0_0 msim/xil_common_vip_v1_0_0
vmap smartconnect_v1_0 msim/smartconnect_v1_0
vmap axi_protocol_checker_v1_1_13 msim/axi_protocol_checker_v1_1_13
vmap axi_vip_v1_0_1 msim/axi_vip_v1_0_1
vmap xlconstant_v1_1_3 msim/xlconstant_v1_1_3

vlog -work generic_baseblocks_v2_1_0 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/f9c1/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_1_4 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/ebc2/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_1_4 -64 -93 \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/ebc2/hdl/fifo_generator_v13_1_rfs.vhd" \

vlog -work fifo_generator_v13_1_4 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/ebc2/hdl/fifo_generator_v13_1_rfs.v" \

vlog -work axi_data_fifo_v2_1_11 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/5235/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_12 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/0e33/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work axi_protocol_converter_v2_1_12 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/138d/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../bd/system/ip/system_axi_protocol_converter_0_0/sim/system_axi_protocol_converter_0_0.v" \

vcom -work lib_cdc_v1_0_2 -64 -93 \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/52cb/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_11 -64 -93 \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/5db7/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../bd/system/ip/system_proc_sys_reset_0/sim/system_proc_sys_reset_0.vhd" \

vlog -work xil_common_vip_v1_0_0 -64 -sv -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_13 -L xil_common_vip_v1_0_0 -L axi_vip_v1_0_1 -L xil_defaultlib "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl/xil_common_vip_v1_0_vl_rfs.sv" \

vlog -work smartconnect_v1_0 -64 -sv -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_13 -L xil_common_vip_v1_0_0 -L axi_vip_v1_0_1 -L xil_defaultlib "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/sc_util_v1_0_vl_rfs.sv" \

vlog -work axi_protocol_checker_v1_1_13 -64 -sv -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_13 -L xil_common_vip_v1_0_0 -L axi_vip_v1_0_1 -L xil_defaultlib "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/8017/hdl/axi_protocol_checker_v1_1_vl_rfs.sv" \

vlog -work axi_vip_v1_0_1 -64 -sv -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_13 -L xil_common_vip_v1_0_0 -L axi_vip_v1_0_1 -L xil_defaultlib "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl/axi_vip_v1_0_vl_rfs.sv" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../bd/system/ip/system_processing_system7_0/sim/system_processing_system7_0.v" \

vcom -work xil_defaultlib -64 -93 \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_conv_funs_pkg.vhd" \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_proc_common_pkg.vhd" \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_ipif_pkg.vhd" \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_family_support.vhd" \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_family.vhd" \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_soft_reset.vhd" \
"../../../bd/system/ip/system_xadc_0/proc_common_v3_30_a/hdl/src/vhdl/system_xadc_0_pselect_f.vhd" \
"../../../bd/system/ip/system_xadc_0/axi_lite_ipif_v1_01_a/hdl/src/vhdl/system_xadc_0_address_decoder.vhd" \
"../../../bd/system/ip/system_xadc_0/axi_lite_ipif_v1_01_a/hdl/src/vhdl/system_xadc_0_slave_attachment.vhd" \
"../../../bd/system/ip/system_xadc_0/interrupt_control_v2_01_a/hdl/src/vhdl/system_xadc_0_interrupt_control.vhd" \
"../../../bd/system/ip/system_xadc_0/axi_lite_ipif_v1_01_a/hdl/src/vhdl/system_xadc_0_axi_lite_ipif.vhd" \
"../../../bd/system/ip/system_xadc_0/system_xadc_0_xadc_core_drp.vhd" \
"../../../bd/system/ip/system_xadc_0/system_xadc_0_axi_xadc.vhd" \

vlog -work xil_defaultlib -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../bd/system/ip/system_xadc_0/system_xadc_0.v" \

vlog -work xlconstant_v1_1_3 -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../../redpitaya.srcs/sources_1/bd/system/ipshared/45df/hdl/xlconstant_v1_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/7e3a/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/2ad9/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/16a2/hdl/verilog" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/d5eb/hdl" "+incdir+../../../../redpitaya.srcs/sources_1/bd/system/ipshared/856d/hdl" \
"../../../bd/system/ip/system_xlconstant_0/sim/system_xlconstant_0.v" \
"../../../bd/system/hdl/system.v" \

vlog -work xil_defaultlib \
"glbl.v"
