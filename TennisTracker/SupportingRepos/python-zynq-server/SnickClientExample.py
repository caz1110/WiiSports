# Author: Christopher Zamora
# Project: ESDII Lab 4 - Blender Client Commands
# Function: Using pre-defined messages, this client sends
# requests to a blender server to perform object manipulation
# or request information from the blender 3D enviornment

import socket
import struct
import numpy as np
from enum import Enum
from PIL import ImageTk, Image

PCSERVER = socket.gethostbyname(socket.gethostname())
HEADER = 64
PORT = 9999
ADDR = (PCSERVER, PORT)
FORMAT = 'utf-8'

class Msgs(str, Enum):
    KILL_MESSAGE = "!KILL"
    DISCONNECT_MESSAGE = "!DISCONNECT"
    CALIBRATION_REQUEST = "!CALIBRATION"
    RECIEVE_IMAGE_REQUEST = "!RECIEVEIMAGE"
    SEND_FEEDTHROUGH_REQUEST = "!SENDFEEDTHROUGH"
    SEND_PROCESSED_REQUEST = "!SENDPROCESSED"
    COORDINATE_REQUEST = "!COORDINATE"
    ...

leftCamera= "LeftCamera"
rightCamera = "RightCamera"
tennisBall = "tennisBall"

def transform_object(client, obj, x, y, z, pitch, roll, yaw):
    sendString(client, Msgs.TRANSFORM_REQUEST)

    # Send object name
    sendString(client, obj)

    # Send pose data
    # Structure follows: Number of bytes (in this case the # of bytes matches # of arguments)
    # camera width and height, x,y,z transforms, pitch,roll,yaw transforms
    data = struct.pack('6f', x, y, z, pitch, roll, yaw)
    client.sendall(data)

def getCoordinates(client, obj):
    sendString(client, Msgs.COORDINATE_REQUEST)
    sendString(client, obj)
    # We attempt to recieve float values
    try:
        data = client.recv(4)
        depthDouble = struct.unpack('4f', data)
    except (ConnectionError, struct.error) as e:
        print(f"Error receiving data: {e}")
        return
    x, y, z = depthDouble[0], depthDouble[1], depthDouble[2]
    print(f"Received coordinates: x={x}, y={y}, z={z}")
    return x, y, z

def recieveImage(client, width, height):
    sendString(client, Msgs.CAPTURE_REQUEST)

    # Receive image data
    imgs_size = width * height * 4  # Assuming 4 channels per pixel
    data = bytearray()
    while len(data) < imgs_size:
        packet = client.recv(imgs_size - len(data))
        if not packet:
            break
        data.extend(packet)
    # Create numpy image buffer from data buffer
    img_buffer = np.frombuffer(data, dtype=np.uint8)
    # Extract RGB channels
    img_buffer = img_buffer.reshape((height, width, 4))[:, :, :3]
     # Flip image (recall intrinsic properties of camera)
    img_buffer = np.flipud(img_buffer)
    im = Image.fromarray(img_buffer)
    return im

def sendString(client, msg):
    # Our destination server expects a message length to be sent before
    # any other communication, so we derive the length of our desired
    # message which will be the first message sent.
    messageForServer = msg.encode(FORMAT)
    messageLength = len(messageForServer)
    sendLength = str(messageLength).encode(FORMAT)
    sendLength += b' ' * (HEADER - len(sendLength))

    client.send(sendLength)
    client.send(messageForServer)

def connect_and_capture(width, height):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")

        #im1 = sendImageRequest(client, width, height)
        #dist = getCoordinates(client, tennisBall)

        sendString(client, Msgs.DISCONNECT_MESSAGE)

        return
    
def testConnection():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        sendString(client, Msgs.DISCONNECT_MESSAGE)
        print("[CLIENT] Disconnected from server...")

def testImageSend():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        sendString(client, Msgs.DISCONNECT_MESSAGE)
        print("[CLIENT] Disconnected from server...")

def killServer():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        sendString(client, Msgs.KILL_MESSAGE)
        print("[CLIENT] Killed server...")


if __name__ == "__main__":
    #testConnection()
    killServer()
