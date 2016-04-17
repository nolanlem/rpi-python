#!/usr/bin python

# importing libraries
import time
import RPi.GPIO as GPIO

# DECLARE variables! 
mypin1 = 21 # GPIO pin 21

# SETUP!
# set GPIO layout - pin numbering convention (BCM or number)
GPIO.setmode(GPIO.BCM)
GPIO.setup(mypin1, GPIO.OUT)

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
delay_time = 1 # 1 second pause
while True:
    GPIO.output(mypin, True)
    time.sleep(delay_time)
    GPIO.outpu(mypin, False)
    time.sleep(delay_time)


