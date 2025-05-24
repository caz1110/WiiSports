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
PORT = 5050
ADDR = (PCSERVER, PORT)
FORMAT = 'utf-8'

class Msgs(str, Enum):
    DISCONNECT_MESSAGE = "!DISCONNECT"
    CAPTURE_REQUEST = "!CAPTURE"
    SET_CAMERA = "!SETCAM"
    DEPTH_REQUEST = "!DEPTH"
    TRANSFORM_REQUEST = "!TRANSFORM"
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

def getDepth(client, obj):
    sendString(client, Msgs.DEPTH_REQUEST)
    sendString(client, obj)
    # We attempt to recieve float values
    try:
        data = client.recv(4)
        depthDouble = struct.unpack('f', data)
    except (ConnectionError, struct.error) as e:
        print(f"Error receiving data: {e}")
        return
    return depthDouble[0]

def changeCamera(client, cameraName):
    sendString(client, Msgs.SET_CAMERA)
    sendString(client, cameraName)

def sendCameraRequest(client, width, height):
    sendString(client, Msgs.CAPTURE_REQUEST)
    # Send float values for camera properties
    data = struct.pack('2f', width, height)
    client.sendall(data)

    # Receive image data
    img_size = width * height * 4  # Assuming 4 channels per pixel
    data = bytearray()
    while len(data) < img_size:
        packet = client.recv(img_size - len(data))
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

        changeCamera(client, leftCamera)
        im1 = sendCameraRequest(client, width, height)
        
        changeCamera(client, rightCamera)
        im2 = sendCameraRequest(client, width, height)

        dist = getDepth(client, tennisBall)

        sendString(client, Msgs.DISCONNECT_MESSAGE)

        return (im1, im2, dist)

def change_obj_position(obj, x, y, z, pitch, roll, yaw):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        transform_object(client, obj, x, y, z, pitch, roll, yaw)
        sendString(client, Msgs.DISCONNECT_MESSAGE)

def change_cam_positions(baseline, x, y, z, pitch, roll, yaw):
    leftCamY = y + (-baseline/2)
    rightCamY = y + (baseline/2)
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")

        #Original Values: 15, -0.03, 15, 45, 0, 90
        transform_object(client, leftCamera, x, leftCamY, z, pitch, roll, yaw)
        transform_object(client, rightCamera, x, rightCamY, z, pitch, roll, yaw)
        sendString(client, Msgs.DISCONNECT_MESSAGE)

if __name__ == "__main__":
    change_obj_position("tennisBall", 0, 0, 35 , 0, 0, 0)
    im1, im2, dist = connect_and_capture(752, 480)
    im1.save("./test-images/leftBaseline.jpg")
    im2.save("./test-images/rightBaseline.jpg")

    change_obj_position("tennisBall", 0, 0, 20, 0, 0, 0)
    im1, im2, dist = connect_and_capture(752, 480)
    im1.save("./test-images/leftBall.jpg")
    im2.save("./test-images/rightBall.jpg")

    print(dist)
    #change_cam_positions(752,)
    #im.save("test.png")
