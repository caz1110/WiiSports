# Chris Zamora
# Matlab Server
from numpysocket import NumpySocket
import socket
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

def flushSocket(sock):
    try:
        sock.setblocking(0)
        flushed_bytes = b''
        while True:
            try:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                flushed_bytes += chunk
            except socket.error:
                break
        sock.setblocking(1)
        print("Flushed leftover data of size: {}".format(len(flushed_bytes)))
    except Exception as e:
        print("Error while flushing socket: {}".format(e))

print "entering main loop"

# Main loop to handle incoming commands from Matlab
# This loop will run until the user sends a kill command to close the socket
while(1):

    # Initialize variables
    init = True
    if init:
        baseLine = 1000.0 # mm
        focalLength = 6   # mm
        init = False
    
    cmd = npSocket.receiveCmd()
    print("Received command: {}".format(cmd))
    if cmd is None:
        print("Client disconnected.")
        #break

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

    # Command 2: Process RGB frame from camera and send back (For Debugging)
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

    # Command 3: Receive 4 images - Left, Right, & corresponding baseline images
    # and send back the processed images.
    elif cmd == '3':
        # Grab current time for CoR Calculations
        currentTime = time.time()
        print(currentTime)

        # Left Frame Processing
        print("Attempting to get left frame data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Left Acknowledged")

        leftOriginal, frameBaseline = camFeedthrough.getStereoRGB()
        leftFrame, emptyFrame = camProcessed.getStereoRGB()

        leftOriginal = np.ascontiguousarray(leftOriginal, dtype=np.uint8)
        leftFrame = np.ascontiguousarray(leftFrame, dtype=np.uint8)
        cv2.imwrite("leftProcessed.jpg", leftFrame)

        # Right Frame Processing
        print("Attempting to get right frame data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Right Acknowledged")

        rightOriginal, frameBaseline = camFeedthrough.getStereoRGB()
        rightFrame, emptyFrame = camProcessed.getStereoRGB()

        rightOriginal = np.ascontiguousarray(rightOriginal, dtype=np.uint8)
        rightFrame = np.ascontiguousarray(rightFrame, dtype=np.uint8)
        cv2.imwrite("rightProcessed.jpg", rightFrame)

        # Send the frames
        npSocket.send(leftOriginal)
        print("Sent data of size: {}".format(leftOriginal.shape))
        npSocket.send(rightOriginal)
        print("Sent data of size: {}".format(rightOriginal.shape))

        print("Processed stereo frames and sent data.")

    # Command 4: Calculate coordinates based on contours detected in the frames
    # and send the coordinates back to Matlab.
    elif cmd == '4':
        center1 = detectContors(leftFrame)
        center2 = detectContors(rightFrame)
        
        # Example coordinate calculation (uncomment when ready)
        x, y, z = calculateCoordinates(center1, center2, leftFrame.shape[1], rightFrame.shape[0], baseLine, focalLength)

        # Send the time stamp & coordinates
        npSocket.send(np.array(currentTime, dtype=np.float64))
        npSocket.send(np.array(x,           dtype=np.float64))
        npSocket.send(np.array(y,           dtype=np.float64))
        npSocket.send(np.array(z,           dtype=np.float64))

        print("Calculated coordinates and sent data.")

    elif cmd == '5':
        print("Attempting to get calibration data...")

        sock = npSocket.client_connection  # <-- IMPORTANT

        # Step 1: Read until ':'
        size_buffer = b''
        while True:
            byte = sock.recv(1)
            if byte == b':':
                break
            size_buffer += byte

        expected_size = int(size_buffer.decode('utf-8'))

        # Step 2: Read exactly expected_size bytes
        message_buffer = b''
        while len(message_buffer) < expected_size:
            chunk = sock.recv(expected_size - len(message_buffer))
            if not chunk:
                raise RuntimeError("Socket connection broken during calibration data receive.")
            message_buffer += chunk

        # Step 3: Decode and parse
        decoded_str = message_buffer.decode('utf-8').strip()
        baseline_str, focal_str = decoded_str.split(',')

        baseLine = float(baseline_str)
        focalLength = float(focal_str)

        print("BaseLine: {:.4f} mm, FocalLength: {:.4f} mm".format(baseLine, focalLength))

        # Step 4: Send simple ack
        sock.send(b'2')


    # Command 3: Receive 4 images - Left, Right, & corresponding baseline images
    # and send back the processed images.
    elif cmd == '6':
        # Grab current time for CoR Calculations
        currentTime = time.time()
        print(currentTime)

        # Left Frame Processing
        print("Attempting to get left frame data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Left Acknowledged")

        leftOriginal, frameBaseline = camFeedthrough.getStereoRGB()
        leftFrame, emptyFrame = camProcessed.getStereoRGB()

        leftOriginal = np.ascontiguousarray(leftOriginal, dtype=np.uint8)
        leftFrame = np.ascontiguousarray(leftFrame, dtype=np.uint8)
        cv2.imwrite("leftProcessed.jpg", leftFrame)

        # Right Frame Processing
        print("Attempting to get right frame data...")
        data = npSocket.receive()
        print("Received data of size: {}".format(data.shape))
        camWriter.setFrame(data)
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
        print("Right Acknowledged")

        rightOriginal, frameBaseline = camFeedthrough.getStereoRGB()
        rightFrame, emptyFrame = camProcessed.getStereoRGB()

        rightOriginal = np.ascontiguousarray(rightOriginal, dtype=np.uint8)
        rightFrame = np.ascontiguousarray(rightFrame, dtype=np.uint8)
        cv2.imwrite("rightProcessed.jpg", rightFrame)

        # Send the frames
        npSocket.send(leftFrame)
        print("Sent data of size: {}".format(leftFrame.shape))
        npSocket.send(rightFrame)
        print("Sent data of size: {}".format(rightFrame.shape))

        print("Processed stereo frames and sent data.")

    # Kill command: Close the socket and exit
    elif cmd == 'e':
        print("Exit command! Client requested to close the socket.")
        break

    # Unknown command: Handle gracefully
    else:
        print("Unknown command: {}".format(cmd))
        flushSocket(npSocket.client_connection)
        time.sleep(5)

    print("\n")

npSocket.close()
print("Socket server closed.")
        