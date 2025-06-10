import serial
import numpy as np
import matplotlib.pyplot as plt
import time


def create_test_image():
    return np.random.randint(0, 256, (8, 8), dtype=np.uint8)


def send_test_image(ser, img):
    # 添加帧头
    ser.write(b'START')

    # 发送数据并计算校验和
    total_sum = 0
    flat_img = img.flatten()
    for pixel in flat_img:
        ser.write(bytes([pixel]))
        total_sum = (total_sum + pixel) % 256

    # 添加帧尾和校验和
    ser.write(b'END')
    ser.write(bytes([total_sum]))
    return total_sum


# 打开串口
try:
    ser = serial.Serial('COM5', 115200, timeout=1)
except Exception as e:
    print(f"Error opening serial port: {e}")
    exit(1)

try:
    while True:
        test_img = create_test_image()
        checksum = send_test_image(ser, test_img)

        # 显示图像
        plt.imshow(test_img, cmap='gray', vmin=0, vmax=255)
        plt.title(f"LED Test Pattern (Checksum: 0x{checksum:02X})")
        plt.pause(0.5)  # 显示0.5秒

        # 打印像素值
        print("Sent image (first row):", test_img[0])
        time.sleep(1)  # 每秒更新一次


except KeyboardInterrupt:
    print("\nProgram terminated")
finally:
    ser.close()