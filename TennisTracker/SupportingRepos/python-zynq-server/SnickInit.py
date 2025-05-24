# Author: Chris Zamora
# SnickInit.py
# blenderInit creates a socket that replicates the
# functionality of the Zynq server, but is used
# on a host PC to allow for testing without HW

from enum import Enum
from io import BytesIO
import numpy as np
import threading
import queue
import socket
import struct
import time
from ImageProc import detectContors, calculateCoordinates, updateStereoConfig

PCSERVER = socket.gethostbyname(socket.gethostname())
HEADER = 64
PORT = 9999
ADDR = (PCSERVER, PORT)
FORMAT = 'utf-8'

class Msgs(str, Enum):
    KILL_MESSAGE = "!KILL"
    DISCONNECT_MESSAGE = "!DISCONNECT"
    CALIBRATION_REQUEST = "!CALIBRATION"
    IMAGES_TO_SNICK = "!IMGTOSNICK"
    FEEDTHROUGH_FROM_SNICK = "!GETFEEDTHROUGH"
    PROCESSED_FROM_SNICK = "!GETPROCESSED"
    COORDINATE_CALCULATIONS = "!COORDINATE"
    ...

serverBool = False
server = []
server_thread = None

left = None
leftProcessed = None
leftBaseline = None
right = None
rightProcessed = None
rightBaseline = None

# sterocameraCalibration() function
# Function intakes calibration parameters for
# baseline and focal length before saving them
# into a configuration file to be used for
# coordinate calculations.
def steroCalibration(conn):
    try:
        data = conn.recv(12)
        calibrationFloats = struct.unpack('3f', data)
    except (ConnectionError, struct.error) as e:
        print(f"Error receiving data: {e}")
        return
    
    baseline, focal_length, pixel_size = calibrationFloats[0], calibrationFloats[1], calibrationFloats[2]
    print(f"[ALERT] Received calibration data: {baseline}, {focal_length}, {pixel_size}")

    updateStereoConfig(baseline=baseline, focal_length=focal_length, pixel_size=pixel_size)
    print(f"[ALERT] Calibration data saved to configuration file.")

# recieveImages() function
# Function intakes stero image files 
def receiveImages(conn):
    global left, leftProcessed, leftBaseline, right, rightProcessed, rightBaseline
    # receive floats
    try:
        data = conn.recv(16)
        floats = struct.unpack('4i', data)
    except (ConnectionError, struct.error) as e:
        print(f"Error receiving data: {e}")
        return
    # Receive a number of images of a provided size from socket client
    # The images are expected to be in RGBA format
    image_size = floats[0] * floats[1] * floats[2]
    total_size = floats[3] * image_size
    buffer = bytearray()

    while len(buffer) < total_size:
        packet = conn.recv(total_size - len(buffer))
        if not packet:
            raise ConnectionError("Connection lost during image reception.")
        buffer.extend(packet)

    # Convert buffer to a list of NumPy RGBA images
    frame = np.frombuffer(buffer, dtype=np.uint8)
    images = [
        frame[i*image_size:(i+1)*image_size].reshape((floats[1], floats[0], floats[2]))
        for i in range(floats[3])
    ]
    return images

def sendStereoFrames(conn, frame1, frame2):
    if not isinstance(frame1, np.ndarray):
        raise TypeError("input frame is not a valid numpy array")
    
    if not isinstance(frame2, np.ndarray):
        raise TypeError("input frame is not a valid numpy array")

    socket = conn.socket
    if(conn.client_connection):
        socket = conn.client_connection
    try:
        socket.sendall(frame1)
        socket.sendall(frame2)
    except BrokenPipeError:
        print("pipe error")
        return

def sendCoordinates(conn):
    global left, leftProcessed, leftBaseline, right, rightProcessed, rightBaseline
    if left is None or right is None:
        print("[ERROR] Images not received yet!")
        x = 0
        y = 0
        z = 0
    else:
        print("[ALERT] Performing image processing!")
        leftProcessed, leftCenter = detectContors(left, leftBaseline)
        rightProcessed, rightCenter = detectContors(right, rightBaseline)
        x, y, z = calculateCoordinates(leftCenter, rightCenter, left.shape[1], left.shape[0])
    data = struct.pack('3f', x, y, z)
    conn.sendall(data)

# handle_client(conn, addr) function
# function listens along the socket for a valid Msgs class command.
# If a valid command is found, then the corresponding function is
# executed. Best practice is to always send Msgs.DISCONNECTPMESSAGE
# when a client wishes to terminate, otherwise a thread will remain
# in use which waits for additional communication with the client.
def handle_client(conn, addr):
    global serverBool
    global left, leftBaseline, right, rightBaseline
    print(f"[NEW CONNECTION] {addr} connected.")
    connected = True
    while connected:
        # We need to recieve the header to understand which
        # operation we want to perform: either camera capture,
        # position change, or a depth measurement
        message_length = conn.recv(HEADER).decode(FORMAT)

        if message_length:
            message_length = int(message_length)
            message = conn.recv(message_length).decode(FORMAT)
            match message:
                case Msgs.KILL_MESSAGE:
                    print(f"[KILL REQUEST] {addr}")
                    serverBool = False
                    break
                case Msgs.DISCONNECT_MESSAGE:
                    print(f"[CONNECTION TERMINATED] {addr}")
                    break
                case Msgs.CALIBRATION_REQUEST:
                    print(f"[CALIBRATION REQUEST] {addr}")
                    steroCalibration(conn)
                case Msgs.IMAGES_TO_SNICK:
                    print(f"[RECEIVE FRAMES REQUEST] {addr}")
                    try:
                        imgs = receiveImages(conn)
                        left, leftBaseline, right, rightBaseline = imgs
                        print(f"[IMAGES RECEIVED] Left and right images stored.")
                    except Exception as e:
                        print(f"[ERROR RECEIVING IMAGES] {e}")
                        break
                case Msgs.FEEDTHROUGH_FROM_SNICK:
                    print(f"[FEEDTHROUGH FRAMES REQUEST]] {addr}")
                case Msgs.SEND_PROCESSED_REQUEST:
                    print(f"[PROCESSED FRAMES REQUEST] {addr}")  
                case Msgs.COORDINATE_REQUEST:
                    print(f"[COORDINATE REQUEST] {addr}")
                    sendCoordinates(conn)
                case _:
                    print(f"[INVALID COMMAND] {addr} {message}")

    conn.close()

def startServer():
    global server, serverBool, renderRequest, renderFinished
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(ADDR)
    serverBool = True
    server.listen()
    print(f"[LISTEN] server is listening on {PCSERVER}")

    # A timeout is employed in order to allow for serverBool to be checked, otherwise,
    # it will only check following the handling of a new client being connected.
    while serverBool:
        try:
            server.settimeout(1)
            conn, addr = server.accept()
            thread = threading.Thread(target=handle_client, args=(conn, addr))
            thread.start()
            print(f"[ACTIVE CONNECTIONS] {threading.active_count() - 2}")
        except socket.timeout:
            continue
    endServer()

def endServer():
    global server
    print("[END] server is shutting down...")
    try:
        server.close()
    except OSError as e:
        print(f"[ERROR] Error closing server: {e}")
        print("[WARNING] Killing python process...")
        exit(1)
    print("[END] server closed.")

#####################
# GUI GENERATION
#####################

if __name__ == "__main__":
    startServer()