# Author: Chris Zamora
# blenderInit.py
# blenderInit creates a GUI for which a socket server
# can be started or stopped. This server and client
# connections run on seperate threads.

import bpy # type: ignore
from enum import Enum
import math
from mathutils import Euler # type: ignore
import numpy as np
import threading
import queue
import struct
import socket

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

serverBool = False
server = []
server_thread = None

# Create a queue to handle Blender operations in the
# main thread, blender operations are not thread safe.
blender_operations_queue = queue.Queue()
def process_blender_operations():
    """Process queued Blender operations in the main thread."""
    while not blender_operations_queue.empty():
        operation = blender_operations_queue.get()
        operation()
    return 0.1  # Re-run this function every 0.1 seconds
bpy.app.timers.register(process_blender_operations)

# switch on nodes
bpy.context.scene.use_nodes = True
tree = bpy.context.scene.node_tree
links = tree.links
# clear default nodes
for n in tree.nodes:
    tree.nodes.remove(n)
# create input render layer node
rl = tree.nodes.new('CompositorNodeRLayers')      
rl.location = 185,285
# create output node
v = tree.nodes.new('CompositorNodeViewer')   
v.location = 750,210
v.use_alpha = False
# Links
links.new(rl.outputs[0], v.inputs[0])  # link Image output to Viewer input

# xform_object_by_name(conn) function
# This function receives an object name and transformation  
# data over the socket and applies the transformation to 
# the corresponding object in Blender if it exists.
def safe_xform_object_by_name(name, floats):
    if name in bpy.data.objects:
        obj = bpy.data.objects.get(name)
        obj.location = (floats[0], floats[1], floats[2])
        pitchRad = math.radians(floats[3])
        rollRad = math.radians(floats[4])
        yawRad = math.radians(floats[5])
        obj.rotation_euler = Euler((pitchRad, rollRad, yawRad), 'XYZ')
    else:
        print(f"Object '{name}' not found.")

def xform_object_by_name(conn):
    try:
        message_length = conn.recv(HEADER).decode(FORMAT)
        if message_length:
            message_length = int(message_length)
            name = conn.recv(message_length).decode(FORMAT)
        else:
            print(f"Error receiving obj name")
            return
        # receive floats
        try:
            data = conn.recv(24)
            floats = struct.unpack('6f', data)
        except (ConnectionError, struct.error) as e:
            print(f"Error receiving data: {e}")
            return
        
        blender_operations_queue.put(lambda: safe_xform_object_by_name(name, floats))
    except (ConnectionError, struct.error) as e:
        print(f"Error receiving transformation data: {e}")

# from_linear(conn) function
# This function is used to transform Blender’s linear color space
# space into the standard sRGB color space, which is necessary
# for displaying images correctly on typical monitors.
def from_linear(linear):
    srgb = linear.copy()
    less = linear <= 0.0031308
    srgb[less] = linear[less] * 12.92
    srgb[~less] = 1.055 * np.power(linear[~less], 1.0 / 2.4) - 0.055
    return srgb * 255.0

# get_viewport(conn) function
# This function listens along the socket for connection for the desired image
# width and height, before rendering and converting a blender image from
# the scene's active camera. This image is than sent back via the socket
def safe_get_viewport(conn, width, height):
    bpy.context.scene.render.resolution_x = width
    bpy.context.scene.render.resolution_y = height
    print("[DEBUG]: Resolution Set")
    bpy.ops.render.render()
    print("[DEBUG]: Image rendered")

    # copy pixel buffer to numpy array for faster manipulation
    # before sending via socket connection
    pixels = bpy.data.images['Viewer Node'].pixels
    arr = np.array(pixels[:])
    pixels = np.uint8(from_linear(arr))
    print("[DEBUG]: Pixel buffer converted to array")
    conn.sendall(pixels)
    print("[DEBUG]: Image Sent")

def get_viewport(conn):
    # We attempt to recieve viewport resoultion 
    try:
        data = conn.recv(8)
        unpackedData = struct.unpack('2f', data)
        blender_operations_queue.put(lambda: safe_get_viewport(conn, int(unpackedData[0]), int(unpackedData[1])))
    except (ConnectionError, struct.error) as e:
        print(f"Error receiving viewport data: {e}")

# set_camera(conn) function
# This function receives a camera name over the socket
# and sets it as Blender's active camera if it exists.
def safe_set_camera(cam_name):
    if cam_name in bpy.data.objects:
        CameraObj = bpy.data.objects.get(cam_name)
        bpy.context.scene.camera = CameraObj
    else:
        print("Error setting active camera: camera not found!")

def set_camera(conn):
    message_length = conn.recv(HEADER).decode(FORMAT)

    if message_length:
        message_length = int(message_length)
        message = conn.recv(message_length).decode(FORMAT)
        blender_operations_queue.put(lambda: safe_set_camera(message))

# get_distance(conn) function
# This function receives the name of an object over a network connection 
# and calculates its depth value based on the depth from the active 
# scene camera. The computed depth is then sent back over the connection.
def get_distance(conn):
    # Receive string containing the object name
    message_length = conn.recv(HEADER).decode(FORMAT)

    if message_length:
        message_length = int(message_length)
        message = conn.recv(message_length).decode(FORMAT)

        if message in bpy.data.objects:
            obj = bpy.data.objects.get(message)
        else:
            print("Error: Object not found!")
            return

    # Get the active scene camera
    CameraObj = bpy.context.scene.camera

    if obj and CameraObj:
        # Calculate the Euclidean depth between the camera and the object
        cam_location = CameraObj.location
        obj_location = obj.location
        depth = math.sqrt(
            (cam_location.x - obj_location.x) ** 2 +
            (cam_location.y - obj_location.y) ** 2 +
            (cam_location.z - obj_location.z) ** 2
        )
    else:
        print("Error: No active camera found or object is missing!")
        depth = 0.0

    # Send the calculated depth value back over the network
    data = struct.pack('f', depth)
    conn.sendall(data)

# handle_client(conn, addr) function
# function listens along the socket for a valid Msgs class command.
# If a valid command is found, then the corresponding function is
# executed. Best practice is to always send Msgs.DISCONNECTPMESSAGE
# when a client wishes to terminate, otherwise a thread will remain
# in use which waits for additional communication with the client.
def handle_client(conn, addr):
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
                case Msgs.DISCONNECT_MESSAGE:
                    print(f"[CONNECTION TERMINATED] {addr}")
                    break
                case Msgs.CAPTURE_REQUEST:
                    print(f"[CAM REQUEST] {addr}")
                    get_viewport(conn)
                case Msgs.SET_CAMERA:
                    print(f"[SET CAMERA] {addr}")
                    set_camera(conn)
                case Msgs.DEPTH_REQUEST:
                    print(f"[DEPTH REQUEST] {addr}")
                    get_distance(conn)
                case Msgs.TRANSFORM_REQUEST:
                    print(f"[TRANSFORM REQUEST] {addr}")
                    xform_object_by_name(conn)
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

#####################
# GUI GENERATION
#####################

class TEST_OT_startServer(bpy.types.Operator):
    bl_idname = "scene.start_server"
    bl_label = "Start Server"

    def execute(self, context):
        global server_thread
        if server_thread is None or not server_thread.is_alive():
            print("[STARTING] server is starting...")
            server_thread = threading.Thread(target=startServer, daemon=True)
            server_thread.start()
        return {'FINISHED'}

class TEST_OT_stopServer(bpy.types.Operator):
    bl_idname = "scene.stop_server"
    bl_label = "Stop Server"

    def execute(self, context):
        global serverBool
        print(f"[SERVER TERMINATION REQUEST RECIEVED] (Blender)")
        serverBool = False
        return {'FINISHED'}

class IOServerPanel(bpy.types.Panel):
    bl_label = "IO Server"
    bl_idname = "IOSERVER_PT_Panel"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "IO Server"
    
    def draw(self,context):
        layout = self.layout
        row1 = layout.row()
        row1.operator("scene.start_server", text="Start Server")
        row2 = layout.row()
        row2.operator("scene.stop_server", text="Stop Server")

def register():
    bpy.utils.register_class(IOServerPanel)
    bpy.utils.register_class(TEST_OT_stopServer)
    bpy.utils.register_class(TEST_OT_startServer)

def unregister():
    bpy.utils.unregister_class(IOServerPanel)
    bpy.utils.unregister_class(TEST_OT_stopServer)
    bpy.utils.unregister_class(TEST_OT_startServer)

if __name__ == "__main__":
    register()