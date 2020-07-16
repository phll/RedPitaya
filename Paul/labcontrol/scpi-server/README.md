# SCPI SERVER

## Contents

| paths                         | changes
|-------------------------------|---------
| `scpi-server/src/`            | added controller.h and controller.c and integrated them in scpi_commands.c
| `scpi-server/scpi-parser`     |
| `scpi-server/Makefile`        |

## Required
Requires the labcontrol fpga-image for all scpi-commands (LC#:*) to work. -> ../fpga/README.md

## How to build Red Pitaya `scpi-server`
Before proceeding follow the [instructions](https://github.com/RedPitaya/RedPitaya/blob/master/doc/developer.rst) on how to set up working environment.
Then proceed by simply running the following command.
```bash
make clean all
``` 

## Load 'scpi-server' to RedPitaya
Copy the executable to /opt/redpitaya/bin
```bash
scp scpi-server root@red_pitaya_ip:/opt/redpitaya/bin/
```
To use the LC-features one has to change /etc/system.d/system/redpitaya_scpi.service in order to load the right fpga-image when starting scpi-server.

## SCPI commands
Load sequences data to RedPitaya: 
'LC:DATA total_len,   ch, ch_len, initial, time, value, time, value,...,   ch, chlen, inital, time, value, time, value,...,   ...' returns informations about time and voltage deviations 

    example: flash LED0 for 1 second 'LC:DATA 8,3,5,0,1,1,2,0'
    
Reset/arm trigger:
'LC:TRIG:AWAIT'

Generate software trigger:
'LC:TRIG:SOFT'

### Sequence data & restrictions
| param                         | notes
|-------------------------------|---------
| `total_len`                   | total amount of transferred 'array' elements
| `ch_len`                      | (twice the number of events) +1 
| `ch`                          | channel number
| `inital`                      | start value of sequence (is also the output value when sequence is finished); double between -1V and 1V (analog channel), 0 or 1 (digital channel) 
| `time`                        | absolute event time in seconds; double
| `value`                       | voltage in V (between -1 and 1; double) for analog channel (linearly sweeps between last value and new value) or logical state (0 or 1) for digital channel (set to new state at event time)

specifications:
| specs                 | value
|-----------------------|---------
| max analog events     | 4096
| max digital events    | 128
| min time step         | 16ns
| time resolution       | 16ns
| max sequence duration | 34s

channel map:
| channel |   pin
|---------|-------------------------
| 0       | analog CH 1
| 1       | analog CH 2
| 2 - 9   | LED 0 - 7
| 10 - 17 | EXP_P 0 - 7 (EXP_P 0 is used as trigger!)
| 18 - 25 | EXP_N 0 - 7

## Starting Red Pitaya SCPI server

Before starting SCPI service, make sure Nginx service is not running.
Running them at the same time will cause conflicts, since they access the same hardware.
```bash
systemctl stop redpitaya_nginx
```
Now we can try and start Red Pitaya SCPI server.
```bash
systemctl start redpitaya_scpi
```

## Starting Red Pitaya SCPI server at boot time

The next commands will enable running SCPI service at boot time and disable Nginx service.
```bash
systemctl disable redpitaya_nginx
systemctl enable  redpitaya_scpi
```
