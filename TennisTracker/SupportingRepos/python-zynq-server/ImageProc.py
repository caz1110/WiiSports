import cv2
import numpy as np
import json
import os

# Author : Christopher Zamora
# ImageProc.py
# Function:
# File contains functions to get an image via local file or blender server
# in addition to image processing functionality to find circular objects.

######################################
# Stereo Camera Calibration Parameters
######################################
CONFIG_PATH = "stereo_config.json"

def generateDefaultStereoConfig():
    default_config = {
        "baseline_mm": 1000.0,
        "focal_length_mm": 5.0,
        "pixel_size_mm": 0.006
    }
    with open(CONFIG_PATH, "w") as f:
        json.dump(default_config, f, indent=4)
    print(f"Default stereo config saved to {CONFIG_PATH}")

def updateStereoConfig(baseline: float, focal_length: float, pixel_size: float):
    config = {
        "baseline_mm": baseline,
        "focal_length_mm": focal_length,
        "pixel_size_mm": pixel_size
    }
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=4)
    print(f"Stereo config updated: {config}")

def loadStereoConfig():
    if not os.path.exists(CONFIG_PATH):
        print(f"{CONFIG_PATH} not found. Generating default config.")
        generateDefaultStereoConfig()

    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)
    return config

######################################
# Image Processing "Core"
######################################
def detectContors(image: cv2.typing.MatLike, baseline: cv2.typing.MatLike):
    # Image differencing
    mod_img = cv2.absdiff(image, baseline)
    print(cv2.imwrite("./test-images/diff.png", mod_img))
    
    # Grayscale
    mod_img = cv2.cvtColor(mod_img,cv2.COLOR_BGR2GRAY)
    print(cv2.imwrite("./test-images/gray.png", mod_img))

    # Binary thresholding
    lower_bound = np.array(40, dtype=np.uint8)
    upper_bound = np.array(130, dtype=np.uint8)
    mask = cv2.inRange(mod_img, lower_bound, upper_bound)
    print(cv2.imwrite("./test-images/binary.png", mask))

    # Morphological operations to reduce false positives
    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.erode(mask, kernel, iterations=2)
    mask = cv2.dilate(mask, kernel, iterations=2)


    contours, _ = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours = sorted(contours, key=cv2.contourArea, reverse=True)

    center = ()
    array = []
    print(f"Contors found: {len(contours)}")
    for c in contours:
        # Coordinates & Radius of circle!
        (x,y),r = cv2.minEnclosingCircle(c)
        center = (int(x),int(y))
        r = int(r)
        if r >= 1 and r <= 500:
            print(f"Radius value: {r}")
            print(f"Center value: {center}")
            mask = cv2.circle(mask,center,r,(0,255,0),2)
            array.append(center)
    
    return mask, center

######################################
# Coordinate Calculation Logic
######################################
def calculateCoordinates(leftPixel: tuple, rightPixel: tuple, width: int, height: int):
    config = loadStereoConfig()

    baseLine = config["baseline_mm"]
    focalLength = config["focal_length_mm"]
    pixelSize = config["pixel_size_mm"]
    cx = width / 2.0        # Pixels
    cy = height / 2.0       # Pixels

    if not leftPixel or not rightPixel:
        print("No coordinates available for calculations!")
        return None

    leftPixel = np.array(leftPixel, dtype=np.float64)
    rightPixel = np.array(rightPixel, dtype=np.float64)

    disparity_pixels = np.abs((leftPixel[0] - cx) - (rightPixel[0] - cx))
    disparity = disparity_pixels * pixelSize
    
    if disparity_pixels < 1e-3:  # Prevent near-zero disparity issues
        print("Disparity is too small for accurate depth calculation!")
        return None

    z = (baseLine * focalLength) / disparity  # mm
    z_position = z / 1000.0  # Convert to meters

    x_position = ((leftPixel[0] - cx) * z * pixelSize) / focalLength / 1000.0  # m
    y_position = ((leftPixel[1] - cy) * z * pixelSize) / focalLength / 1000.0  # m

    print(f"XLeft: {leftPixel[0]:.3f}, XRight: {rightPixel[0]:.3f}, "
          f"YLeft: {leftPixel[1]:.3f}, YRight: {rightPixel[1]:.3f}")
    print(f"Disparity: {disparity:.6f} mm, Depth: {z_position:.3f} m, "
          f"X Position: {x_position:.3f} m, Y Position: {y_position:.3f} m")

    return x_position, y_position, z_position

if __name__ == "__main__":
    pass