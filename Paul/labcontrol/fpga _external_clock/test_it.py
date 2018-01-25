"""
Last modified 3/23/2016
Written by Jon
Send to RP
"""
from rpyc import connect
from PyRedPitaya.pc import RedPitaya
from struct import pack, unpack
import math
from math import *

import parser
import sys
import re
import os
import numpy as np
import time
print "Starting up"
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
def convert_2c(val, bits): #take a signed integer and return it in 2c form
    if (val>=0):
        return val
    return ((1 << bits)+val)
numbits=32
def convertsimple(val):
    return convert_2c(val,numbits)
def sendpitaya (addr, val):
    redpitaya.write(addr,convert_2c(val,numbits))
def sendpitaya_long(addr, val): #addr is the address low word. addr+4*4 is where the high word goes!
                                #val is a float, that should be sent in 2c form!
    vali=int(val)
    val2c=convert_2c(val,64)
    val2cH=val2c>>32
    val2cL=val&(0xffffffff)
    redpitaya.write(addr,val2cL)
    redpitaya.write(addr+4,val2cH)
    print "addr: "+str(hex(addr))+"; value: "+str(val2cL)
    print "addr: "+str(hex(addr+4))+"; value: "+str(val2cH)
def sendpitaya_long_u(addr, val): #addr is the address low word. addr+4*4 is where the high word goes!
                                  #val is a unsigned
    vali=int(val)
    val2c=val
    val2cH=val2c>>32
    val2cL=val&(0xffffffff)
    redpitaya.write(addr,val2cL)
    redpitaya.write(addr+4,val2cH)
#    print val2cL
#    print val2cH
##########################################
def get_CSV_data(fileDirectory, columns):
    data = np.loadtxt(fileDirectory, delimiter=',', usecols=columns, unpack=True)
    return data
def getparmval(strIn,parmname,defaultval):
    strlist=re.findall(parmname+"=([\w\a\.-]*)",strIn)
    if(len(strlist)>0):
        outval=strlist[0]
    else:
        outval=defaultval
    print parmname+": "+outval
    return outval
def getparmval_int(strIn,parmname,defaultval):
    strlist=re.findall(parmname+"=([\w\a\.-]*)",strIn)
    if(len(strlist)>0):
        outval=int(strlist[0])
    else:
        outval=int(defaultval)
    print parmname+": "+str(outval)
    return outval

def clip(x, lower, upper):
    if(x<lower):
        return lower
    if(x>upper):
        return upper
    return x

def sub1IfPos(x):
    if(x>0):
        return x-1
    return x

##########################################################################################################!!!!!
#ADDRESSES IN THE MEMORY MAPPED ADDRESS SPACE

LEDADDRESS              =0x40000030    #address in FPGA memory map to control RP LEDS

maxevents_a                  =   64*16*4

maxevents_d                  =   128


DDS_CHANNEL_OFFSET          = 1080033280+4*0                  #offset in WORDS (4 bytes) to the channel that we are currently writing to!
DDSawaittrigger_OFFSET      = 1080033280+4*24                 #offset in WORDS (4 bytes) to address where we write ANYTHING to tell system to reset and await trigger
DDSsoftwaretrigger_OFFSET   = 1080033280+4*25                 #offset in WORDS (4 bytes) to address where we write ANYTHING to give the system a software trigger!
DDSenable_OFFSET            = 1080033280+4*1                  #offset in WORDS (4 bytes) to the initial/final FTW for the current channel
DDSamp_IF_OFFSET            = 1080033280+4*3                  #offset in WORDS (4 bytes) to the initial/final amp for the current channel
DDSsamples_OFFSET           = 1080033280+4*2                  #offset in WORDS (4 bytes) to # of samples for the current channel

####EXPECT LOW WORD AT LOWER MEMORY ADDRESS FOR FREQS (FTW) RAMS! ###
DDScycles_OFFSET           = 1080033280+4*40     #offset in WORDS to the first element of the current cyc. list
DDSamps_OFFSET_A             = DDScycles_OFFSET + 4*maxevents_a*1     #offset in WORDS to the first element of the current cyc. list
DDSamps_OFFSET_D             = DDScycles_OFFSET + 4*maxevents_d*1     #offset in WORDS to the first element of the current cyc. list

maxsendlen=31*512  #most FIR coefficients we can send at a time
fclk_Hz=125*(10**6) #redpitaya clock frequency
DDSamp_fracbits = 14 #number of DDS bits to the right of the decimal point (all of them, of course!)
DDSchannels = 26 #number of DDS freqs we can simultaneously output!

def sendpitayaarray (addr, dats): #WRITE THE FIR COEFFICIENTS IN THE LARGEST BLOCKS POSSIBLE, TO SPEED THE WRITING
    thelen=len(dats)
    startind=0
    endind=min(thelen,startind+maxsendlen-1)
    while(startind<thelen):
        redpitaya.write (FIRCOEFFSADDRESSOFFSET,startind*4) #since we don't have enough address bits, this is an offset
        redpitaya.writes(addr,dats[startind:endind])
        startind=endind+1
        endind=min(thelen-1,startind+maxsendlen)
def SecToCycles ( t_sec ): #take a time in seconds and convert it to RP timesteps in cycles, without rounding, so we can do it later when we compute deltas!
    return t_sec*fclk_Hz

#pin<0: analog channel, else digital channel
def SendSeqToChannel (channel, enable, IFamp_frac,times_sec, amps_frac ):
    if (channel<2 and len(times_sec)>maxevents_a):
        print bcolors.FAIL + "TOO MANY EDGES ON CHANNEL-- EXCEEDS RED PITAYA RAM SPACE OF " + str(maxevents_a) + bcolors.ENDC
        exit()
    elif (channel>1 and len(times_sec)>maxevents_d):
        print bcolors.FAIL + "TOO MANY EDGES ON CHANNEL-- EXCEEDS RED PITAYA RAM SPACE OF " + str(maxevents_d) + bcolors.ENDC
        exit()

    times_cyc=map(SecToCycles,times_sec)

    dt_cyc=[max(2,int(round(times_cyc[i+1]-times_cyc[i]))) for i in range(len(times_sec)-1)] #we use two cycles min, as the RAM might not be fast enough or da_ATW is overflowed otherwise :(
    dt_cyc.insert(0,max(2,int(round(times_cyc[0]))))

    IF_ATW = IFamp_frac
    da_ATW = amps_frac

    if(channel<2):
        IFamp_frac_c=clip(IFamp_frac,-1.0, 1.0) #make sure we don't overflow the amplitude!
        IF_ATW = sub1IfPos(int(IFamp_frac_c*(2.0**(DDSamp_fracbits-1))))
        amps_frac_c=[clip(amps_frac[i],-1.0,1.0) for i in range(len(amps_frac))] #make sure we don't overflow the amplitude!
        deltas_amp_frac=[(amps_frac_c[i+1]-amps_frac_c[i]) for i in range(len(times_sec)-1)]
        deltas_amp_frac.insert(0,amps_frac_c[0]-IFamp_frac_c)

        da_ATW=[sub1IfPos(int(round((2.0**(32+DDSamp_fracbits-1))*deltas_amp_frac[i]/dt_cyc[i]))) for i in range(len(dt_cyc))] #dont overflow 46bit signed !

    if(DEBUGMODE==False):
        #print "Length of dt_cyc: " + str(len(dt_cyc))
        #print "Length of df_FTW: " + str(len(df_FTW))
        #print "IFamp: " +str(IFamp_frac)

        #set the channel that we are writing to!
        redpitaya.write(DDS_CHANNEL_OFFSET,channel)
        print "addr: "+str(hex(DDS_CHANNEL_OFFSET))+"; value: "+str(channel)

        #send the number of samples on each channel
        redpitaya.write(DDSsamples_OFFSET,len(times_sec))
        print "addr: "+str(hex(DDSsamples_OFFSET))+"; value: "+str(len(times_sec))
        #print "listlen: " + str(len(times_sec))

        #send step sizes for each ramp!
        print "[cycles,da]:"
        for i in range(len(dt_cyc)): #data must be sent as dFTW,dAMP, and corresponding cycles, as the last is when all are written into the memory!
            if(channel<2):
                sendpitaya_long(DDSamps_OFFSET_A   + 8*i,da_ATW[i]  ) #these must be sent as 2's complement 64 bit numbers
            else:
                redpitaya.write(DDSamps_OFFSET_D   + 4*i,da_ATW[i]  ) #these must be sent as unsigned 32 bit numbers
                print "addr: "+str(hex(DDSamps_OFFSET_D + 4*i))+"; value: "+str(da_ATW[i])
            redpitaya.write(DDScycles_OFFSET + 4*i,dt_cyc[i] )  #these must be sent as unsigned 32 bit numbers
            print "addr: "+str(hex(DDScycles_OFFSET + 4*i))+"; value: "+str(dt_cyc[i])
            print "["+str(dt_cyc[i])+","+str(da_ATW[i])+"]"
        #send the I/F values of the  channel
        redpitaya.write(DDSenable_OFFSET, int(enable)) #these must be sent as unsigned 32 bit numbers
        print "addr: "+str(hex(DDSenable_OFFSET))+"; value: "+str(int(enable))
        redpitaya.write(DDSamp_IF_OFFSET, int(IF_ATW))     #these must be sent as unsigned 32 bit numbers
        print "addr: "+str(hex(DDSamp_IF_OFFSET))+"; value: "+str(int(IF_ATW))
        #print "IF_ATW: " +str(IF_ATW)

def SendFullSeqs( AllSeqs ):
    #the data for each channel is an element of AllSeqs, sent as follows:
        #[[enable, IFamp_frac],[[time_sec,amp_frac]]]
    if (len(AllSeqs)>DDSchannels):
        print "TOO MANY CHANNELS FOR FPGA! FAIL!"
        exit()
    for chan in range(DDSchannels):
        if (chan<len(AllSeqs)):
            curdat=AllSeqs[chan]
        elif (chan<2):
            curdat = [[0, 0.0],[[.0001,0.0]]]
        else:
            curdat = [[0,0],[[.0001,0]]]

        enable = curdat[0][0]
        IFamp_frac = curdat[0][1]
        times_sec  = [curdat[1][k][0] for k in range(len(curdat[1]))]
        amps_frac  = [curdat[1][k][1] for k in range(len(curdat[1]))]

        SendSeqToChannel (chan, enable, IFamp_frac,times_sec,amps_frac)

    #reset the RP FSM and prepare it for a trigger!
    redpitaya.write(DDSawaittrigger_OFFSET,0) #value sent doesn't affect anything

    #for now, give it a software trigger, for testing!
    #input()
    redpitaya.write(DDSsoftwaretrigger_OFFSET,0) #value sent doesn't affect anything

#todo
#need a routine to send the full sequence (times and frequencies-- convert from seconds and frequencies to steps and stepsizes! quantize, send to board!)
#need to write a server for this bad boy, with pickle and everything! potentially don't want to ever close the connection to the RP, to keep it FAST!
#hopefully the connection doesn't randomly close on its own?
#DOCUMENT THE CODE!!
#test both channels running concurrently!
#have server code complain if sequence is more than 64 edges/channel!
#make sure that the ramp time is correct
#make sure that the stepsize calculator and so forth properly work with floats, so things don't get quantized wrong!
#test hardware triggers!

##############################################################################################
##############################################################################################
#####################################END OF SETUP CODE########################################

cmdstr=""
for tARG in sys.argv:
    cmdstr=cmdstr+" "+tARG
REDPITAYA_IP = getparmval(cmdstr, "RP_IP","147.142.18.242") #IF THE CALL TO DDS_SEQUENCER CONTAINS CMD LINE ARGUMENT "RP_IP=XXX.XXX.XXX.XXX" THAT IS USED INSTEAD OF THE DEFAULT AT LEFT

DEBUGMODE=False #IF TRUE, THE DATA DOESN'T GET SENT TO THE RED PITAYA!

if(DEBUGMODE==False):
    conn = connect(REDPITAYA_IP, port=18861)     #connect to the rpyc process on the red pitaya
    redpitaya = RedPitaya(conn)

CHs_DATA=[[[0, -1.0],[[5.0,1.0],[10.0,-1.0],[14.0,-0.4]]],[[0, 0.0],[[.0001,0.0]]], [[0,0],[[.0001,0]]], [[1, 0],[[5,1],[6,0],[7,1],[8,0]]]]
SendFullSeqs(CHs_DATA)
##############################################################################################
##############################################################################################
###########################END OF SEQUENCE GENERATE/SEND CODE#################################
