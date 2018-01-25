#!/bin/bash -f
xv_path="/opt/Xilinx/Vivado/2015.4"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto c9c1f93b86354794b019aa668f1bbe03 -m64 --debug typical --relax --mt 8 -L generic_baseblocks_v2_1_0 -L fifo_generator_v13_0_1 -L axi_data_fifo_v2_1_6 -L axi_infrastructure_v1_1_0 -L axi_register_slice_v2_1_7 -L axi_protocol_converter_v2_1_7 -L xil_defaultlib -L lib_cdc_v1_0_2 -L proc_sys_reset_v5_0_8 -L unisims_ver -L unimacro_ver -L secureip --snapshot red_pitaya_top_behav xil_defaultlib.red_pitaya_top xil_defaultlib.glbl -log elaborate.log
