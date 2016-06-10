
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

mypin = []
myGpioPins = [21,20,16,26,6,5,22,27,17,4,18,23,24,25,12,19,13]; 


for pin in myGpioPins:
	mypin.append(pin)


GPIO.setmode(GPIO.BCM)
for i in range(0, len(mypin)): 
	GPIO.setup(mypin[i],GPIO.OUT) 


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
		thread.start_new_thread( toggleLED, ("thread-"+str(x), 0.1, mypin[x]) )			       
		print "thread-"+str(x) + ": bang"   
# print "---"

def toggleLED(threadName, delay, mypin):
	GPIO.output(mypin, True)
	time.sleep(delay) 
	GPIO.output(mypin, False)


s.addMsgHandler("/msgs", printing_handler) # adding our function


# just checking which handlers we have added
print "Registered Callback-functions are :"
for addr in s.getOSCAddressSpace():
    print addr


# Start OSCServer
print "\nStarting OSCServer. Use ctrl-C to quit."
st = threading.Thread( target = s.serve_forever )
st.start()


try :
    while 1 :
        time.sleep(5)

except KeyboardInterrupt :
    print "\nClosing OSCServer."
    s.close()
    print "Waiting for Server-thread to finish"
    st.join() ##!!!
    print "Done"
        
