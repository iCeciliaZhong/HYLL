import serial
import time


def send_test_data(port, baudrate=115200):
    """
    发送测试数据到LED矩阵控制器
    数据格式: 64字节(RGB332格式)
    """
    ser = None  # 预先声明 ser 变量
    try:
        # 打开串口
        ser = serial.Serial(port, baudrate, timeout=1)
        print(f"已连接到 {port}，波特率 {baudrate}")
        print("开始发送测试数据...")

        # 测试模式1: 全亮白色
        print("\n测试模式1: 全白")
        data = bytes([0xFF] * 64)  # 64字节全FF (白色)
        ser.write(data)
        time.sleep(2.5)  # 等待LED显示效果

        # 验证回显
        echo = ser.read(64)
        if echo == data:
            print("✅ 回显验证成功: 全白模式")
        else:
            print(f"❌ 回显验证失败 | 发送: {len(data)}字节 | 接收: {len(echo) if echo else 0}字节")

        # 测试模式2: 棋盘格
        print("\n测试模式2: 棋盘格")
        checkerboard = []
        for i in range(8):  # 8x8网格
            for j in range(8):
                # RGB332: 交替黑白 (0xFF或0x00)
                color = 0xFF if (i + j) % 2 == 0 else 0x00
                checkerboard.append(color)

        data = bytes(checkerboard)
        ser.write(data)
        time.sleep(2.5)  # 等待LED显示效果

        # 验证回显
        echo = ser.read(64)
        if echo == data:
            print("✅ 回显验证成功: 棋盘格模式")
        else:
            print("❌ 回显验证失败")

        # 测试模式3: 渐变
        print("\n测试模式3: 红绿渐变")
        gradient = []
        for i in range(8):  # 8x8网格
            for j in range(8):
                # RGB332: 红绿渐变
                # 红色分量随行增加 (0-7 -> 0xE0)
                r = min(i * 0b11100000 // 7, 0b11100000) if i > 0 else 0
                # 绿色分量随列增加 (0-7 -> 0x1C左移3位)
                g = min(j * 0b00011100 // 7, 0b00011100) << 3 if j > 0 else 0
                color = r | g
                gradient.append(color)

        data = bytes(gradient)
        ser.write(data)
        time.sleep(2.5)  # 等待LED显示效果

        # 验证回显
        echo = ser.read(64)
        if echo == data:
            print("✅ 回显验证成功: 渐变模式")
        else:
            print("❌ 回显验证失败")

        print("\n✅ 所有测试完成")

    except serial.SerialException as e:
        print(f"\n❌ 串口错误: {e}")
    except KeyboardInterrupt:
        print("\n操作已中断")
    finally:
        # 安全关闭串口
        if ser and ser.is_open:
            ser.close()
            print("串口已关闭")


if __name__ == "__main__":
    PORT = 'COM5'
    send_test_data(PORT)