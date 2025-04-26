# Chris Zamora
# Matlab Server support file

import cv2
import numpy as np
import time

import cv2
import numpy as np

def detectContors(imageRGB):
    start = time.time()

    # Grab red channel only, assumed to already contain a binary mask (0 or 255)
    #mask = imageRGB[:, :, 2]

    # Dynamically determine the channel with the most information
    channels = [imageRGB[:, :, i] for i in range(3)]
    channel_variances = [np.var(channel) for channel in channels]
    selected_channel = np.argmax(channel_variances)
    mask = channels[selected_channel]

    print("Using channel {} for contour detection".format(selected_channel))

    # Ensure it's uint8 and contiguous in memory
    mask = np.ascontiguousarray(mask, dtype=np.uint8)

    # Apply erosion and dilation to remove noise and small objects
    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.erode(mask, kernel, iterations=2)
    mask = cv2.dilate(mask, kernel, iterations=1)
    
    #contours, hierarchy = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    _, contours, hierarchy = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    center = ()
    if contours:
        print("Contors found: {}".format(len(contours)))
        c = max(contours, key=cv2.contourArea)
        (x, y), r = cv2.minEnclosingCircle(c)
        center = (int(x), int(y))
        #print("Radius value: {}".format(r))
        #print("Center value: {}".format(center))
    else:
        print("No contours found!")
        center = (-1, -1)

    # Return untouched RGB frame & show time taken for operation
    print("detectContors took {:.2f} ms".format((time.time() - start) * 1000))
    return center

def calculateCoordinates(leftPixel, rightPixel, width, height, baseLine, focalLength):

    # Constant values based on image size and provided camera parameters
    start = time.time()
    pixelSize = 0.006       # mm
    cx = width / 2.0        # Pixels
    cy = height / 2.0       # Pixels

    # Error handling for no coordinates
    if not leftPixel or not rightPixel:
        print("No coordinates available for calculations!")
        return -1, -1, -1 # Error case

    leftPixel = np.array(leftPixel, dtype=np.float64)
    rightPixel = np.array(rightPixel, dtype=np.float64)

    disparity_pixels = np.abs((leftPixel[0] - cx) - (rightPixel[0] - cx))

    if disparity_pixels < 1e-3:  # Prevent near-zero disparity issues
        print("Disparity is too small for accurate z_position calculation!")
        return -1, -1, -1 # Error case

    disparity = disparity_pixels * pixelSize

    z = (baseLine * focalLength) / disparity  # mm
    z_position = z / 1000.0  # Convert to meters

    x_position = ((leftPixel[0] - cx) * z * pixelSize) / focalLength / 1000.0  # m
    y_position = ((leftPixel[1] - cy) * z * pixelSize) / focalLength / 1000.0  # m

    ''' Debugging output for pixel position of ball
    print(
        "XLeft: {:.3f}, " \
        "XRight: {:.3f}, " \
        "YLeft: {:.3f}, " \
        "YRight: {:.3f}".format(
    leftPixel[0], rightPixel[0], leftPixel[1], rightPixel[1]))
    '''

    print(
        "X Position: {:.3f}m, " \
        "Y Position: {:.3f}m, " \
        "Z Position: {:.3f}m".format(
    x_position, y_position, z_position, ))
    
    print("calculateCoordinates took {:.2f} ms".format((time.time() - start) * 1000))
    return x_position, y_position, z_position

if __name__ == "__main__":
    leftImg = cv2.imread("leftProcessed.jpg")
    rightImg = cv2.imread("differenceProcessed.jpg")

    center1 = detectContors(leftImg)
    center2 = detectContors(rightImg)

    #calculateCoordinates(center1, center2, leftImg.shape[1], leftImg.shape[0])

    print("width: {}".format(leftImg.shape[1]))
    print("height: {}".format(leftImg.shape[0]))

    print("Center 1 value: {}".format(center1))
    print("Center 2 value: {}".format(center2))