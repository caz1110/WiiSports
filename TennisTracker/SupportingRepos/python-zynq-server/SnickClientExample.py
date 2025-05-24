# Author: Christopher Zamora
# Project: Tennis Tracker - WiiSports
# Function: Using pre-defined messages, this client sends
# requests to a "snickerdoodle"" server to perform image
# proecessing and supporting functions.

import socket
import struct
import numpy as np
import cv2
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
    IMAGES_TO_SNICK = "!IMGTOSNICK"
    FEEDTHROUGH_FROM_SNICK = "!GETFEEDTHROUGH"
    PROCESSED_FROM_SNICK = "!GETPROCESSED"
    COORDINATE_CALCULATIONS = "!COORDINATE"
    ...

leftCamera= "LeftCamera"
rightCamera = "RightCamera"
tennisBall = "tennisBall"

def getCoordinates(client, obj):
    sendString(client, Msgs.COORDINATE_REQUEST)
    sendString(client, obj)
    try:
        data = client.recv(12)
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

def sendImages(client):
    left = cv2.imread("./test-images/leftBall.jpg")
    leftBaseline = cv2.imread("./test-images/leftBaseline.jpg")
    right = cv2.imread("./test-images/rightBall.jpg")
    rightBaseline = cv2.imread("./test-images/rightBaseline.jpg")

    height = left.shape[0]
    width = left.shape[1]
    channels = left.shape[2]
    num_images = 4
    data = struct.pack('4i', width, height, channels, num_images)
    client.sendall(data)

    left = np.ascontiguousarray(left, dtype=np.uint8)
    right = np.ascontiguousarray(right, dtype=np.uint8)
    leftBaseline = np.ascontiguousarray(leftBaseline, dtype=np.uint8)
    rightBaseline = np.ascontiguousarray(rightBaseline, dtype=np.uint8)

    client.sendall(left)
    print("Sent left image, size:", left.shape)
    client.sendall(leftBaseline)
    print("Sent left baseline image, size:", leftBaseline.shape)
    client.sendall(right)
    print("Sent right image, size:", right.shape)
    client.sendall(rightBaseline)
    print("Sent right baseline image, size:", rightBaseline.shape)

def testConnection():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        sendString(client, Msgs.DISCONNECT_MESSAGE)
        print("[CLIENT] Disconnected from server...")

def testCalibration():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        sendString(client, Msgs.CALIBRATION_REQUEST)
        print("[CLIENT] Sending calibration request...")
        data = struct.pack('3f', 1000.0, 5.0, 0.006)
        client.sendall(data)
        sendString(client, Msgs.DISCONNECT_MESSAGE)
        print("[CLIENT] Disconnected from server...")

def testImageSend():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")
        sendString(client, Msgs.IMAGES_TO_SNICK)
        print("[CLIENT] Sending image request...")
        sendImages(client)
        sendString(client, Msgs.DISCONNECT_MESSAGE)
        print("[CLIENT] Disconnected from server...")

def testCoordinates():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(ADDR)
        print("[CLIENT] Connected to server...")

        sendString(client, Msgs.COORDINATE_CALCULATIONS)
        print("[CLIENT] Sending coordinate request...")
        # receive floats
        try:
            data = client.recv(12)
            floats = struct.unpack('3f', data)
        except (ConnectionError, struct.error) as e:
            print(f"Error receiving data: {e}")
            return
        x, y, z = floats[0], floats[1], floats[2]
        print(f"Received coordinates: x={x}, y={y}, z={z}")

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
    testCalibration()
    testImageSend()
    testCoordinates()
    killServer()
