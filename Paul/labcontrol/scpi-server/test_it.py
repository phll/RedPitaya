#!/usr/bin/python

import sys
import time
import redpitaya_scpi as scpi

rp_s = scpi.scpi(sys.argv[1])


data = [45,     3, 9, 0, 0.01, 1, 0.02, 0, 0.03, 1, 0.04, 0,   1, 7, -1.0, 0.000000016, -0.0, 0.000000816, -0.5, 0.000003, -0.5,   0, 7, -1.0, 0.0000008, 0.6, 0.000000816, -0.5, 0.000003, -0.5,    11, 13, 1, 0.000000016, 0, 0.0000008, 1, 0.000000816, 0, 0.000002350, 1, 0.000002420, 0, 0.001, 1]

send = ""

for i in range(0, len(data) -1):
    send += str(data[i])+", "
send += str(data[-1])

print(send)

print(rp_s.txrx_txt('LC:DATA ' + send))
print(rp_s.err_n())

print(rp_s.tx_txt('LC:TRIG:AWAIT '))
print(rp_s.err_n())

print(rp_s.tx_txt('LC:TRIG:SOFT '))
print(rp_s.err_n())
