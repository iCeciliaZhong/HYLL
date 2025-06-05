`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : top.v
// Module Name  : top
// ---------------------------------------------------------------------------------
// Description   : uart接收器、buffer、驱动和pwm调光模块的顶层互连
//                 修改：添加AXI Lite从接口，连接到frame_buffer
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-29    Cecilia           0.6                  Original
// 2025-06-02    Cecilia           0.88                 互连变量统一
// 2025-06-04    Cecilia           0.9                  支持显回逻辑
// 2025-06-04    Cecilia           1.0                  删除uart，添加AXI Lite接口
// *********************************************************************************

`include "defines.vh"

module top(
    input  wire                     clk,
    input  wire                     rst_n,           // 0 valid
    output wire [`MATRIX_SIZE-1:0]  row_sel, 
    output wire [`MATRIX_SIZE-1:0]  col_r,
    output wire [`MATRIX_SIZE-1:0]  col_g,
    output wire [`MATRIX_SIZE-1:0]  col_b,
    output wire [1:0]               led_state,

    // AXI Lite Interface
    input  wire [31:0]              s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    input  wire [31:0]              s_axi_wdata,
    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    output wire [1:0]               s_axi_bresp,
    output wire                     s_axi_bvalid,
    input  wire                     s_axi_bready
);

wire [`COLOR_DEPTH-1:0] pixel_data;
wire [`ADDR_WIDTH-1:0] read_addr;
wire pwm_cycle_end;
wire [7:0] pwm_counter;
wire [3:0] row_counter;
wire [3:0] col_counter;


frame_buffer u_frame_buffer(
    .clk(clk),
    .rst_n(rst_n),
    .read_addr(read_addr),
    .pixel_data(pixel_data),
    .led_state(led_state),
    // AXI Lite Interface
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready)
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