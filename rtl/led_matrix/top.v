`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : top.v
// Module Name  : top
// ---------------------------------------------------------------------------------
// Description   : uart接收器、buffer、驱动和pwm调光模块的顶层互连
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-29    Cecilia           0.6                  Original
// 2025-06-02    Cecilia           0.88                 互连变量统一
// *********************************************************************************

`include "defines.vh"

module top(
    input wire clk,             // 系统时钟 (100 MHz)
    input wire rst_n,           // 复位信号 (低有效)
    input wire uart_rx,         // UART接收数据
    
    // 2088RGB行驱动信号 (低电平有效)
    output wire [`MATRIX_SIZE-1:0] row_sel, 
    
    // 2088RGB列驱动信号 (RGB各16个)
    output wire [`MATRIX_SIZE-1:0] col_r,
    output wire [`MATRIX_SIZE-1:0] col_g,
    output wire [`MATRIX_SIZE-1:0] col_b,
    
    // 状态指示
    output wire [1:0] led_state // LED状态指示
);

// 内部信号
wire [`COLOR_DEPTH-1:0] pixel_data;
wire [`ADDR_WIDTH-1:0] read_addr;
wire pwm_cycle_end;
wire [7:0] pwm_counter;
wire [3:0] row_counter;
wire [3:0] col_counter;

// 模块实例化
frame_buffer u_frame_buffer(
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .read_addr(read_addr),
    .pixel_data(pixel_data),
    .led_state(led_state)
);

led_driver u_led_driver(
    .clk(clk),
    .rst_n(rst_n),
    .pwm_cycle_end(pwm_cycle_end),
    .pixel_data(pixel_data),
    .pwm_counter(pwm_counter),
    .row_sel(row_sel),
    .col_r(col_r),
    .col_g(col_g),
    .col_b(col_b),
    .read_addr(read_addr),
    .row_counter(row_counter),
    .col_counter(col_counter)
);

pwm u_pwm(
    .clk(clk),
    .rst_n(rst_n),
    .pwm_counter(pwm_counter),
    .pwm_cycle_end(pwm_cycle_end)
);

endmodule