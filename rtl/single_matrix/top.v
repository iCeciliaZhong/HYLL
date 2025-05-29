`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : top.v
// Module Name  : top
// ---------------------------------------------------------------------------------
// Description   : 利用状态机和显存实现行扫描。输出为行控制信号和并行的列控制信号。
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-29    Cecilia           0.6                  Original
//  
// *********************************************************************************

module top_led_system(
    input clk_50m,        // 50MHz主时钟
    input btn_rst,        // 复位按钮
    // LED矩阵物理接口
    output [2:0] row_en,  // 行使能信号
    output ser_data,      // 串行数据
    output ser_clk,       // 移位时钟
    output latch,         // 锁存信号
    // 控制接口
    input [7:0] reg_addr,
    input [7:0] reg_data,
    input reg_we
);

// 时钟系统
wire matrix_clk;
pll clock_gen(.inclk0(clk_50m), .c0(matrix_clk));

// 复位系统
wire sys_rst;
reset_controller reset_sys(.clk(clk_50m), .ext_rst(btn_rst), .sys_rst(sys_rst));

// 显存
wire [2:0] scanner_row_addr;
wire [23:0] scanner_row_data;
dual_port_ram frame_buffer(
    .clk_a(matrix_clk),
    .addr_a(scanner_row_addr),
    .q_a(scanner_row_data),
    // 写端口连接到CPU或图形生成器
    .clk_b(cpu_clk),
    .we_b(fb_we),
    .addr_b(fb_wr_addr),
    .data_b(fb_wr_data)
);

//vivado ip bram
// 双端口BRAM实例化
frame_buffer u_frame_buffer (
  // 扫描器端口 (Port A)
  .clka(clk_matrix),       // 扫描器时钟 (通常50-100MHz)
  .ena(1'b1),              // 始终使能
  .wea(8'b0),              // 扫描器只读，写使能全0
  .addra(row_addr),        // 行地址输入 (0-7)
  .dina(192'b0),           // 扫描器不写入数据
  .douta(row_data),        // 行数据输出 (192位)
  
  // 图形生成器端口 (Port B)
  .clkb(clk_cpu),          // CPU时钟 (通常50-100MHz)
  .enb(1'b1),              // 始终使能
  .web(byte_we),           // 字节写使能 (8位)
  .addrb(pixel_addr),      // 像素地址 (0-63)
  .dinb(pixel_data),       // 像素数据输入 (192位)
  .doutb()                 // 可选的读数据端口
);

// 控制寄存器
reg [7:0] refresh_rate = 8'd100; // 默认100Hz
reg [7:0] global_brightness = 8'd200;
always @(posedge cpu_clk) if(reg_we) begin
    case(reg_addr)
        8'h10: refresh_rate <= reg_data;
        8'h11: global_brightness <= reg_data;
    endcase
end

// 亮度控制
wire [7:0] brightness_per_row [0:7];
brightness_controller bright_ctrl(
    .clk(matrix_clk),
    .global(global_brightness),
    .brightness_out(brightness_per_row)
);

// LED矩阵扫描器
wire [2:0] row_sel;
wire [7:0] col_r, col_g, col_b;
led_matrix_scanner scanner(
    .clk(matrix_clk),
    .rst(sys_rst),
    .row_sel(row_sel),
    .col_r(col_r),
    .col_g(col_g),
    .col_b(col_b),
    .frame_buffer(scanner_row_data),
    .row_addr(scanner_row_addr),
    .refresh_rate(refresh_rate),
    .brightness_r(brightness_per_row),
    .brightness_g(brightness_per_row),
    .brightness_b(brightness_per_row)
);

// 行驱动电路
row_driver row_drv(.sel(row_sel), .row_en(row_en));

// 列驱动电路
column_driver col_drv(
    .clk(matrix_clk),
    .data_r(col_r),
    .data_g(col_g),
    .data_b(col_b),
    .ser_out(ser_data),
    .sclk(ser_clk),
    .latch(latch)
);

endmodule