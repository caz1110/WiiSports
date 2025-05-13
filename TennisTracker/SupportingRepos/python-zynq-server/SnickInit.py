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
from ImageProc import detectContors, calculateCoordinates

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

serverBool = False
server = []
server_thread = None

left = None
leftProcessed = None
leftBaseline = None
right = None
rightProcessed = None
rightBaseline = None

# Create a queue to handle Blender operations in the
# main thread, blender operations are not thread safe.
snick_operations_queue = queue.Queue()
def process_blender_operations():
    """Process queued snick operations in the main thread."""
    while not snick_operations_queue.empty():
        operation = snick_operations_queue.get()
        operation()
    return 0.1  # Re-run this function every 0.1 seconds

# sterocameraCalibration() function
# Function intakes calibration parameters for
# baseline and focal length before saving them
# into a configuration file to be used for
# coordinate calculations.
def steroCalibration():
    pass

# recieveImages() function
# Function intakes stero image files 
def receiveImages(conn, num_images=4, width=752, height=480):
    """Receive `num_images` RGBA images of given dimensions from the connection."""
    image_size = width * height * 4  # RGBA = 4 bytes per pixel
    total_size = num_images * image_size
    buffer = bytearray()

    while len(buffer) < total_size:
        packet = conn.recv(total_size - len(buffer))
        if not packet:
            raise ConnectionError("Connection lost during image reception.")
        buffer.extend(packet)

    # Convert buffer to a list of NumPy RGBA images
    frame = np.frombuffer(buffer, dtype=np.uint8)
    images = [
        frame[i*image_size:(i+1)*image_size].reshape((height, width, 4))
        for i in range(num_images)
    ]
    return images

def pack_frame(frame):
    f = BytesIO()
    np.savez(f, frame=frame)
    
    packet_size = len(f.getvalue())
    header = '{0}:'.format(packet_size)
    header = bytes(header.encode())  # prepend length of array

    out = bytearray()
    #out += header

    f.seek(0)
    out += f.read()
    return out

def sendStereoFrames(conn, frame1, frame2):
    if not isinstance(frame1, np.ndarray):
        raise TypeError("input frame is not a valid numpy array")
    
    if not isinstance(frame2, np.ndarray):
        raise TypeError("input frame is not a valid numpy array")

    out1 = pack_frame(frame1)
    out2 = pack_frame(frame2)

    socket = conn.socket
    if(conn.client_connection):
        socket = conn.client_connection
    try:
        socket.sendall(frame1)
        socket.sendall(frame2)
    except BrokenPipeError:
        print("pipe error")
        #logging.error("connection broken")
        #raise

def sendCoordinates(conn):
    if left is None or right is None:
        print("[ERROR] Images not received yet!")
        x = 0
        y = 0
        z = 0
    elif leftProcessed is None or rightProcessed is None:
        print("[WARNING] Images not processed. Performing image processing!")
        leftProcessed, rightProcessed = detectContors(left, right)
        x, y, z = calculateCoordinates(leftProcessed, rightProcessed, leftBaseline, rightBaseline)
    else:
        x, y, z = calculateCoordinates(leftProcessed, rightProcessed, leftBaseline, rightBaseline)
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
                    # Kill the server
                    serverBool = False
                    break
                case Msgs.DISCONNECT_MESSAGE:
                    print(f"[CONNECTION TERMINATED] {addr}")
                    break
                case Msgs.CALIBRATION_REQUEST:
                    print(f"[CALIBRATION REQUEST] {addr}")
                    # Calibrate "Snickerdoodle"
                case Msgs.RECIEVE_IMAGE_REQUEST:
                    print(f"[RECEIVE FRAMES REQUEST] {addr}")
                    try:
                        imgs = receiveImages(conn)
                        left, leftBaseline, right, rightBaseline = imgs
                        print(f"[IMAGES RECEIVED] Left and right images stored.")
                    except Exception as e:
                        print(f"[ERROR RECEIVING IMAGES] {e}")
                case Msgs.SEND_FEEDTHROUGH_REQUEST:
                    print(f"[FEEDTHROUGH FRAMES REQUEST]] {addr}")
                    # Send unprocessed images
                case Msgs.SEND_PROCESSED_REQUEST:
                    print(f"[PROCESSED FRAMES REQUEST] {addr}")  
                case Msgs.COORDINATE_REQUEST:
                    print(f"[COORDINATE REQUEST] {addr}")
                    sendCoordinates(conn)
                case _:
                    print(f"[INVALID COMMAND] {addr} {message}")

    conn.close()

def startQueueProcessor():
    def run():
        while serverBool:
            process_blender_operations()
            time.sleep(0.1)
    thread = threading.Thread(target=run, daemon=True)
    thread.start()

def startServer():
    global server, serverBool, renderRequest, renderFinished
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(ADDR)
    serverBool = True
    server.listen()
    print(f"[LISTEN] server is listening on {PCSERVER}")


    # Start the queue processor thread
    startQueueProcessor()

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

#####################
# GUI GENERATION
#####################

if __name__ == "__main__":
    startServer()