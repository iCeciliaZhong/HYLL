# HYLL

这是一个基于zynq AXZ7020开发板的LED矩阵驱动项目。

## 文件目录说明

- rtl：代码
- - led_matrix：led矩阵驱动的硬件描述代码（verilog/systemverilog）
  - test：测试代码
  - - marquee：跑马灯代码，用于确定矩阵的行列是否连接正确
    - test1/test2/test3：上位机python代码，分别是回显检查、随机棋盘灰度控制和串口发送检验代码
- Vivado_project：Vivado工程文件，版本为2018.3。管脚约束文件为io.xdc
- FPGA课设报告.pdf：Cecilia个人课设报告
