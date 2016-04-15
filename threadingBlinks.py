#!/usr/bin python
import thread
import time
import RPi.GPIO as GPIO

mypin1 = 21
mypin2 = 20


GPIO.setmode(GPIO.BCM)
GPIO.setup(mypin1, GPIO.OUT)
GPIO.setup(mypin2, GPIO.OUT) 

#define a function for the thread
def print_time( threadName, delay, mypin):
    count = 0
    while count < 5:
        time.sleep(delay)
        count+=1
        print "%s: %s" %( threadName, time.ctime(time.time()) )
        GPIO.output(mypin, True)
        time.sleep(delay)
        GPIO.output(mypin, False)
        

# create 2 threads as follows
try:
    thread.start_new_thread( print_time, ("Thread-1",1,mypin1 ) )
    thread.start_new_thread( print_time, ("thread-2",2,mypin2 ) )
except:
    print "Error!: unable to start thread..."

while 1:
    pass
