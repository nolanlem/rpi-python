#!/usr/bin python

# importing libraries
import thread 
import time
import RPi.GPIO as GPIO

# DECLARE variables! 
mypin1 = 21 # GPIO pin 21
mypin2 = 20 # GPIO pin 22

# SETUP!
# set GPIO layout - pin numbering convention (BCM or number)
GPIO.setmode(GPIO.BCM)
GPIO.setup(mypin1, GPIO.OUT)
GPIO.setup(mypin2, GPIO.OUT) 

#define a function for the thread
def toggleLED( threadName, delay, mypin):
    count = 0
    while count < 5:
        time.sleep(delay)
        count+=1
        print "%s: %s" %( threadName, time.ctime(time.time()) )
        GPIO.output(mypin, True) # toggle ON pin
	time.sleep(delay)        # wait some time (s)
        GPIO.output(mypin, False) # toggle OFF pin 
        

# LOOP!
# create 2 threads as follows
try:
    thread.start_new_thread( toggleLED, ("Thread-1",1,mypin1 ) )
    thread.start_new_thread( toggleLED, ("thread-2",1,mypin2 ) )
except:
    print "Error!: unable to start thread..."

while 1:
    pass
