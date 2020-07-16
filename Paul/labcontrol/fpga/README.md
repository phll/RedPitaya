This fpga image is based on the RedPitaya v0.94 fpga image.

## Files
| paths                         | changes
|-------------------------------|---------
| `red_pitaya_top.sv`           | integrated controller module, output 125MHz clock on fpga_clk (-> schematics), output 20MHz clock on SATA connector S1(changed)
| `red_pitaya_pll.sv`           | changed ser_clk clock frequency from 250MHz to 20MHz(changed)
| `controller`                  | module to control analog channels and digital pins (LED & expansion connector 1)(new)
| `red_pitaya.xdc`              | changed IOStandard for daisy_* pins to differential hstl class I 1.8V 


## controller
description:
Multiple analog and digital ramp machines to drive the fast analog and digital outputs (referred to as channels)  of the RedPitaya.

Analog ramp: 
is specified by a 14bit inital value, the amount of events (32bit) and such many delta_cycles(32bit), delta_voltage(46bit) pairs (the voltage is increased by delta_voltage per cycle for delta_cycles cycle)

Digital ramp: 
is specified by a 1bit enable value, a 1bit inital value, the amount of events (32bit) and such many delta_cycles(32bit), new_state(1bit) pairs (if enabled the pin direction is set to 1 and the pin state is set to new_state after delta_cycles cycles) 


data comes over AXI (one channel at once)
can be armed (reset) to wait on a hardware or software trigger over AXI
AXI registers (each 32bit) (memory map):
| addr (+base address)        | name                          | description
|-----------------------------|-------------------------------|------------------------------------------------
| 0                           | curLCchannel                  | current channel for which data is in AXI
| 24                          | LC_reset (await_trigger)      | write anything to this address to reset ramp machines (wait for trigger)
| 25                          | sw_trigger                    | write anything to this address to generate a software trigger
| channel specific
| 1                           | enable (digital)              | set digital pin direction to 'out' (=1)
| 2                           | samples                       | number of 'actual' events specified (32bit)
| 3                           | ampl_IF, state_IF             | initial dc value (analog, 14bit) or pin state (digital, 1bit) 
| 40 - 40+maxevents-1         | amount cycles for each event  | needs to be stored in block ram (maxevents differ for analog and digital channels) (32bit per value)
| 40+maxevents - 40+maxev. +(2or1)*maxev.-1 | delta voltages per cycle or state for each event  | needs to be stored in block ram (analog, 46bit; digital, 1bit per value), analog values are stored in 64bit, therefore 2*maxev. in this case |

channel-pin map:
| channel |   pin
|---------|-------------------------
| 0       | analog CH 1
| 1       | analog CH 2
| 2 - 9   | LED 0 - 7
| 10 - 17 | EXP_P 0 - 7 (EXP_P 0 is used as trigger!)
| 18 - 25 | EXP_N 0 - 7

Look at the ../scpi-server/src/controller.c file on more information how to write data to AXI

## Install
Copy redpitaya.runs/impl_1/red_pitaya_top.bit to RedPitaya and load it via 'cat red_pitaya_top.bit > /dev/xdevcfg'
