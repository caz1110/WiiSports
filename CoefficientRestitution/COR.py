import bpy
import os
import sys
import glob
import time
import cv2
import numpy as np

leftBaseline = cv2.imread("/path/to/leftBaseline.png")
rightBaseline = cv2.imread("/path/to/rightBaseline.png")

if leftBaseline is None or rightBaseline is None:
    raise RuntimeError("Error loading baseline images.")

def detectContors(image: np.ndarray, sideVar: bool):
    global leftBaseline, rightBaseline
    
    if sideVar:
        mod_img = cv2.absdiff(image, leftBaseline)
    else:
        mod_img = cv2.absdiff(image, rightBaseline)
    
    mod_img = cv2.cvtColor(mod_img, cv2.COLOR_BGR2GRAY)

    lower_bound = 40
    upper_bound = 130
    mask = cv2.inRange(mod_img, lower_bound, upper_bound)

    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.erode(mask, kernel, iterations=3)
    mask = cv2.dilate(mask, kernel, iterations=3)

    contours, _ = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours = sorted(contours, key=cv2.contourArea, reverse=True)

    center = None
    for c in contours:
        (x, y), r = cv2.minEnclosingCircle(c)
        center = (int(x), int(y))
        r = int(r)

        if 1 <= r <= 500:
            cv2.circle(mask, center, r, (255, 255, 255), 2)
            break
    
    return mask, center

def computeCOR(positions, times):
    y_array = np.array(positions)
    t_array = np.array(times)

    bounce_idx = np.argmax(y_array)
    bounce_t = t_array[bounce_idx]

    def finite_diff(vals, tvals):
        return (vals[-1] - vals[0]) / (tvals[-1] - tvals[0])
    
    window_size = 2
    pre_start = max(bounce_idx - window_size, 0)
    post_end = min(bounce_idx + window_size, len(y_array) - 1)

    pre_bounce_v = finite_diff(y_array[pre_start:bounce_idx+1], t_array[pre_start:bounce_idx+1])
    post_bounce_v = finite_diff(y_array[bounce_idx:post_end+1], t_array[bounce_idx:post_end+1])

    cor = post_bounce_v / abs(pre_bounce_v)
    return cor, bounce_t

def main():
    image_folder = "renders"
    image_files = sorted(glob.glob(os.path.join(image_folder, "frame_*.png")))

    y_positions = []
    t_stamps = []

    fps = 30.0
    start_time = time.time()

    for i, img_path in enumerate(image_files):
        frame = cv2.imread(img_path)
        if frame is None:
            continue
        
        mask, center = detectContors(frame, sideVar=True)
        
        if center is not None:
            (cx, cy) = center
            y_positions.append(cy)
            t_stamps.append(i / fps)

    if len(y_positions) < 10:
        print("Not enough data to compute COR.")
        return

    cor, bounce_time = computeCOR(y_positions, t_stamps)
    print(f"Estimated COR: {cor:.3f} at bounce time ~ {bounce_time:.3f}s")

if __name__ == "__main__":
    main()
