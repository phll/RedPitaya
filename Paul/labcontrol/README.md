##controller
This app allows the user to drive analog ramps (on the fast adcs OUT1 and OUT2) and digital ramps (leds and expansion connector 1) on the RedPitaya in an event based approach.

Analog ramp: 
is specified by an inital voltage value and (time, voltage)-pairs (up to 4096 such events per analog channel). The output voltage is sweeped linearly between the specified voltage values.
Digital ramp: 
is specified by an inital value and (time, state)-pairs (up to 128 such events per digital channel), where the state of the driven pin is changed at time 'time'.

This functionality is implemented in the standard fpga image and scipy-server and thus can be used along the other standard features. Take a look at the RedPitaya-Wiki for more informations on how to use the scipy interface. Furthermore, there is a LabView program also making use of the scipy interface. 

Take a closer look at the subfolders for more informations.

This program hasn't been used in the lab so far, so there still might be some issues!!
