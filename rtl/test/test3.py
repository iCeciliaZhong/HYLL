import serial
import time


# 心形图案定义 (RGB332格式)
HEART_PATTERN = [
    # 行0 (顶部)
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    # 行1
    0x00, 0x1C, 0x00, 0x00, 0x1C, 0x00, 0x00, 0x00,
    # 行2
    0xE0, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0x00, 0x00,
    # 行3
    0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0x00, 0x00,
    # 行4
    0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0x00, 0x00,
    # 行5
    0x00, 0xE0, 0xE0, 0xE0, 0xE0, 0x00, 0x00, 0x00,
    # 行6
    0x00, 0x00, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00,
    # 行7 (底部)
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
]


# 串口发送函数
def send_heart_pattern(port='COM3', baudrate=115200):
    try:
        # 打开串口
        ser = serial.Serial(port, baudrate)

        # 发送数据
        ser.write(bytes(HEART_PATTERN))
        print(f"成功发送心形图案数据 ({len(HEART_PATTERN)}字节)")

        # 关闭串口
        ser.close()
        return True

    except serial.SerialException as e:
        print(f"串口错误: {e}")
        return False


# 主程序
if __name__ == "__main__":
    PORT_NAME = "COM5"
    send_heart_pattern(PORT_NAME)

# 添加串口连接测试代码
import serial


def test_serial_connection(port='COM3', baudrate=115200):
    try:
        # 尝试打开串口
        with serial.Serial(port, baudrate, timeout=1) as ser:
            print(f"成功打开串口: {ser.name}")

            # 发送测试数据
            test_data = b"\x55\xAA"  # 简单的测试模式
            ser.write(test_data)
            print("已发送测试数据: [55 AA]")

            # 尝试读取回显
            echo = ser.read(2)
            if echo == test_data:
                print("成功接收到回显数据")
            else:
                print(f"未收到回显数据，接收到: {echo.hex()}")

        return True
    except serial.SerialException as e:
        print(f"串口错误: {e}")
        return False


# 在主程序中调用
if __name__ == "__main__":
    PORT_NAME = "COM5"
    if test_serial_connection(PORT_NAME):
        send_heart_pattern(PORT_NAME)