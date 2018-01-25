#!/bin/bash -f
xv_path="/opt/Xilinx/Vivado/2017.1"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
echo "xvlog -m64 --relax -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_13 -L xil_common_vip_v1_0_0 -L axi_vip_v1_0_1 -L xil_defaultlib -prj top_tb_vlog.prj"
ExecStep $xv_path/bin/xvlog -m64 --relax -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_13 -L xil_common_vip_v1_0_0 -L axi_vip_v1_0_1 -L xil_defaultlib -prj top_tb_vlog.prj 2>&1 | tee compile.log
echo "xvhdl -m64 --relax -prj top_tb_vhdl.prj"
ExecStep $xv_path/bin/xvhdl -m64 --relax -prj top_tb_vhdl.prj 2>&1 | tee -a compile.log
