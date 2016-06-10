
""" receiving OSC with pyOSC
https://trac.v2.nl/wiki/pyOSC
example by www.ixi-audio.net based on pyOSC documentation

this is a very basic example, for detailed info on pyOSC functionality check the OSC.py file 
or run pydoc pyOSC.py. you can also get the docs by opening a python shell and doing
>>> import OSC
>>> help(OSC)
"""


import OSC
import time, threading
import thread
import RPi.GPIO as GPIO
import atexit 
import Adafruit_PCA9685 

delaytime = 0.125 # 0.3 sec triggered-on time 


# initialize the PCA9685 using the default address (0x40)
pwm = Adafruit_PCA9685.PCA9685()

enA = 21
enB = 20


mypin = []
myGpioPins = [21,20,19,16,13, 12, 6 , 5, 25, 24, 23, 22, 27, 18, 17]; 
enA_0 = 21 
enB_0 = 20 
enA_1 = 16 
enB_1 = 26 
enA_2 = 6 
enB_2 = 5 
enA_3 = 22 
enB_3= 27

GPIO.setmode(GPIO.BCM)

mylogic = True
for pin in myGpioPins:
	mypin.append(pin)
	GPIO.setup(pin, GPIO.OUT)
	GPIO.output(pin, mylogic)
	
	print "GPIO.output(%r , %r)" %(pin, mylogic)
	if mylogic == True:
		mylogic = False 
	elif mylogic == False: 
		mylogic = True
	
GPIO.output(19, False); 
GPIO.output(16, True);
	
mydir = 0
servo_min = 0 
servo_max = 4095

pwm.set_pwm_freq(120) # 60 Hz pwm freq

# tupple with ip, port. i dont use the () but maybe you want -> send_address = ('127.0.0.1', 9000)
receive_address = '127.0.0.1', 8888


# OSC Server. there are three different types of server. 
s = OSC.OSCServer(receive_address) # basic
##s = OSC.ThreadingOSCServer(receive_address) # threading
##s = OSC.ForkingOSCServer(receive_address) # forking

# this registers a 'default' handler (for unmatched messages), 
# an /'error' handler, an '/info' handler.
# And, if the client supports it, a '/subscribe' & '/unsubscribe' handler
s.addDefaultHandlers()


# define a message-handler function for the server to call.
def printing_handler(addr, tags, stuff, source):
   
# print "---"
   # print "received new osc msg from %s" % OSC.getUrlStr(source)
   # print "with addr : %s" % addr
   # print "typetags %s" % tags
   # print "data %s" % stuff
    for x,num in enumerate(stuff):
        if num == 0.0: 
		print 'oscillator %r bang' %(x)
		#pwm.set_pwm(x, 0, servo_max) 
		#time.sleep(0.1) 
		#pwm.set_pwm(x, 0, 0)
		thread.start_new_thread( triggerMotor, ("thread-"+str(x), delaytime, x) )
#		if mydir == 0: 
#			GPIO.output(enA, False)
#			GPIO.output(enB, True)
#			mydir = 1
#		elif mydir == 1: 
#			GPIO.output(enA, True) 
#			GPIO.output(enB, False) 
#			mydir = 0       


def triggerMotor(threadName, delay, mypin):
	pwm.set_pwm(mypin, 0, servo_max) # turn on (@ duty cycle)
	time.sleep(delay) 		 # hold for some delay 

	pwm.set_pwm(mypin, 0, servo_min) # off
	#switchPolarity(mypin, mydir)

def switchPolarity(mypin, mypolarity):
	print "mypin polarity: ", mypolarity

	if mypolarity == 0: 
		GPIO.output(enA, False)
		GPIO.output(enB, True) 
		mydir = 1 
	if mypolarity == 1: 
		GPIO.output(enA, True) 
		GPIO.output(enB, False) 
		mydir = 0 	

s.addMsgHandler("/msgs", printing_handler) # adding our function


# just checking which handlers we have added
print "Registered Callback-functions are :"
for addr in s.getOSCAddressSpace():
    print addr


# Start OSCServer
print "\nStarting OSCServer. Use ctrl-C to quit."
st = threading.Thread( target = s.serve_forever )
st.start()

@atexit.register 
def set2zero():
	print "setting enables to 0 0"
	for pin in myGpioPins:
		GPIO.output(pin, False)

try :
    while 1 :
        time.sleep(5)

except KeyboardInterrupt :
	GPIO.output(enA, False) 
	GPIO.output(enB, False) 	
    	print "\nClosing OSCServer."
    	s.close()
    	print "Waiting for Server-thread to finish"
    	st.join() ##!!!
    	print "Done"
        
