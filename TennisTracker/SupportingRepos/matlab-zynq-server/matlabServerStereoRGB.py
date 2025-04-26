# Dr. Kaputa
# Matlab Server
from numpysocket import NumpySocket
import cv2
import numpy as np
import time
import mmap
import struct
import sys, random
import ctypes
import copy
from frameGrabber import ImageProcessing
from frameGrabber import ImageFeedthrough
from frameGrabber import ImageWriter
from matlabServerImageProcCPU import detectContors, calculateCoordinates

camProcessed = ImageProcessing()
camFeedthrough = ImageFeedthrough()
camWriter = ImageWriter()

npSocket = NumpySocket()
npSocket.startServer(9999)

# only set this flag to true if you have generated your bit file with a 
# Vivado reference design for Simulink
simulink = True    
if simulink == True:
    f1 = open("/dev/mem", "r+b")
    simulinkMem = mmap.mmap(f1.fileno(), 1000, offset=0x43c60000)
    simulinkMem.seek(0) 
    simulinkMem.write(struct.pack('l', 1))       # reset IP core
    simulinkMem.seek(8)                         
    simulinkMem.write(struct.pack('l', 1920))    # image width
    simulinkMem.seek(12)                        
    simulinkMem.write(struct.pack('l', 1080))    # image height
    simulinkMem.seek(16)                        
    simulinkMem.write(struct.pack('l', 94))      #  horizontal porch
    simulinkMem.seek(20)                        
    simulinkMem.write(struct.pack('l', 1000))    #  vertical porch when reading from debug
    simulinkMem.seek(256) 
    simulinkMem.write(struct.pack('l', 1))       # filter select
    simulinkMem.seek(4) 
    simulinkMem.write(struct.pack('l', 1))       # enable IP core

print "entering main loop"

# feel free to modify this command structue as you wish.  It might match the 
# command structure that is setup in the Matlab side of things on the host PC.
while(1):
    cmd = npSocket.receiveCmd()
    print("Received command: {}".format(cmd))

    # Command 0: Recieve frame from Matlab
    if cmd == '0':
        print("Attempting to recieve data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Sent response for command '0'")

    # Command 1: Send RGB frame from camera feedthrough
    elif cmd == '1':
        frame, frameBaseline = camFeedthrough.getStereoRGB()
        tempImageLeft = np.ascontiguousarray(frame, dtype=np.uint8)
        tempImageRight = np.ascontiguousarray(frameBaseline, dtype=np.uint8)
        npSocket.send(tempImageLeft)
        npSocket.send(tempImageRight)
        print("Sent response for command '1'")

    # Command 9: Process RGB frame from camera and send back (For Debugging)
    elif cmd == '2':
        currentTime = time.time()
        differenceFrame, emptyFrame = camProcessed.getStereoRGB()
        center1 = detectContors(np.ascontiguousarray(differenceFrame, dtype=np.uint8))
        center2 = detectContors(np.ascontiguousarray(emptyFrame, dtype=np.uint8))

        npSocket.send(np.ascontiguousarray(differenceFrame, dtype=np.uint8))
        npSocket.send(np.ascontiguousarray(emptyFrame, dtype=np.uint8))

        cv2.imwrite("differenceProcessed.jpg", differenceFrame)
        cv2.imwrite("emptyProcessed.jpg", emptyFrame)

        print("Sent response for command '2'")

    elif cmd == '3':
        # Grab current time for CoR Calculations
        currentTime = time.time()
        print(currentTime)

        # Left Frame Processing
        print("Attempting to get left frame data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Sent response for command '0'")
        leftFrame, emptyFrame = camProcessed.getStereoRGB()
        leftFrame = np.ascontiguousarray(leftFrame, dtype=np.uint8)

        # Right Frame Processing
        print("Attempting to get right frame data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Sent response for command '0'")
        rightFrame, emptyFrame = camProcessed.getStereoRGB()
        rightFrame = np.ascontiguousarray(rightFrame, dtype=np.uint8)

        # Send the frames
        npSocket.send(leftFrame)
        print("Sent data of size: {}".format(leftFrame.shape))
        npSocket.send(rightFrame)
        print("Sent data of size: {}".format(rightFrame.shape))

        print("Processed stereo frames and sent data.")
    elif cmd == '4':
        center1 = detectContors(leftFrame)
        center2 = detectContors(rightFrame)
        
        # Example coordinate calculation (uncomment when ready)
        x, y, z = calculateCoordinates(center1, center2, leftFrame.shape[1], rightFrame.shape[0])

        # Send the time stamp & coordinates
        npSocket.send(np.array(currentTime, dtype=np.float64))
        npSocket.send(np.array(x,           dtype=np.float64))
        npSocket.send(np.array(y,           dtype=np.float64))
        npSocket.send(np.array(z,           dtype=np.float64))

        print("Calculated coordinates and sent data.")

    elif cmd == 'e':
        print("Exit command! Closing socket...")
        break
    else:
        print("Unknown command: {}".format(cmd))
        time.sleep(5) # Sleep for a bit to avoid busy waiting

npSocket.close()
print("Socket server closed.")