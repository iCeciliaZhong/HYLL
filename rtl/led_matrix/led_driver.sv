`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : led_driver.v
// Module Name  : led_driver
// ---------------------------------------------------------------------------------
// Description   : 利用移位寄存器实现行扫描，列数据移位并行输出。增加滚动功能，[key2,key3]为滚动方向，10左滚（电平为01），01为右滚。默认2^12帧滚动一次。通过调整pwm占空比（像素数据移位后与pwm计数器比较实现）支持四级整体亮度调整（100\%、50\%、25\%、12.5\%）
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-29    Cecilia           0.6                  Original
// 2025-06-05    Cecilia           0.88                 debug 
// 2025-06-05    Cecilia           0.95                 支持滚动
// 2025-06-08    Cecilia           0.98                 支持四级亮度控制
// *********************************************************************************

`timescale 1ns / 1ps
`include "defines.vh"

module led_driver(
    input wire clk,             
    input wire rst_n,           
    input wire pwm_cycle_end,   
    input wire [`COLOR_DEPTH-1:0] pixel_data, 
    input wire [7:0] pwm_counter,    
    input wire [1:0] roll_ctrl,     // 滚动控制：00-静态，01-右滚，10-左滚
    input wire [1:0] bright_level, 

    output reg [`MATRIX_SIZE-1:0] row_sel,
    output reg [`MATRIX_SIZE-1:0] col_r,
    output reg [`MATRIX_SIZE-1:0] col_g,
    output reg [`MATRIX_SIZE-1:0] col_b,
    
    output reg [`ADDR_WIDTH-1:0] read_addr,
    output reg [3:0] row_counter,
    output reg [3:0] col_counter
);

reg [3:0] current_row;
reg [`COLOR_DEPTH-1:0] pixel_data_dly;

/*
// PWM比较值缩放
wire [2:0] red_threshold   = pixel_data_dly[7:5] >> bright_level;
wire [2:0] green_threshold = pixel_data_dly[4:2] >> bright_level;
wire [2:0] blue_threshold  = {pixel_data_dly[1:0], 1'b0} >> bright_level; 
*/

// PWM比较值缩放
reg [2:0] red_threshold;
reg [2:0] green_threshold;
reg [2:0] blue_threshold;

// 亮度缩放逻辑
always @(*) begin
    case (bright_level)
        2'b00: begin // 100%亮度
            red_threshold = pixel_data_dly[7:5];
            green_threshold = pixel_data_dly[4:2];
            blue_threshold = {pixel_data_dly[1:0], 1'b0};
        end
        2'b01: begin // 50%亮度
            red_threshold = {1'b0, pixel_data_dly[7:6]};
            green_threshold = {1'b0, pixel_data_dly[4:3]};
            blue_threshold = {1'b0, pixel_data_dly[1:0]}; 
        end
        2'b10: begin // 25%亮度
            red_threshold = {2'b00, pixel_data_dly[7]};
            green_threshold = {2'b00, pixel_data_dly[4]};
            blue_threshold = {2'b00, pixel_data_dly[1]};
        end
        2'b11: begin // 12.5%亮度
            red_threshold = 3'b000;
            green_threshold = 3'b000;
            blue_threshold = 3'b000;
        end
    endcase
end

// 滚动控制相关寄存器
reg [3:0] scroll_offset = 0;         // 当前滚动偏移(0-7)
reg [11:0] frame_counter = 0;        

function [3:0] calc_scrolled_col;
    input [3:0] orig_col;
    input [3:0] offset;
    input [1:0] direction;
    begin
        if (direction == 2'b01) begin          // 右滚 (图案向左移动)
            calc_scrolled_col = (orig_col + offset) % `MATRIX_SIZE;
        end
        else if (direction == 2'b10) begin     // 左滚 (图案向右移动)
            calc_scrolled_col = (orig_col + `MATRIX_SIZE - offset) % `MATRIX_SIZE;
        end
        else begin                             // 静态显示
            calc_scrolled_col = orig_col;
        end
    end
endfunction

// 列数据实时生�?
reg [`MATRIX_SIZE-1:0] col_r_data;
reg [`MATRIX_SIZE-1:0] col_g_data;
reg [`MATRIX_SIZE-1:0] col_b_data;

reg [3:0] scrolled_col;  // 存储滚动列计算

always @(*) begin
    // 应用滚动偏移计算实际读取的列
    scrolled_col = calc_scrolled_col(col_counter, scroll_offset, roll_ctrl);
    
    // 实时生成列数
    col_r_data = {`MATRIX_SIZE{1'b1}};  // 默认全灭
    col_g_data = {`MATRIX_SIZE{1'b1}};
    col_b_data = {`MATRIX_SIZE{1'b1}};
    
    if (col_counter < `MATRIX_SIZE) begin
        col_r_data[col_counter] = ~(red_threshold > pwm_counter[7:5]);
        col_g_data[col_counter] = ~(green_threshold > pwm_counter[7:5]);
        col_b_data[col_counter] = ~(blue_threshold > pwm_counter[7:5]); 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_row <= 0;
        row_sel <= 0;
        col_r <= {`MATRIX_SIZE{1'b1}};  // 列低有效，初始全灭
        col_g <= {`MATRIX_SIZE{1'b1}};
        col_b <= {`MATRIX_SIZE{1'b1}};
        read_addr <= 0;
        row_counter <= 0;
        col_counter <= 0;
        pixel_data_dly <= 0;
        scroll_offset <= 0;
        frame_counter <= 0;
    end else begin
        pixel_data_dly <= pixel_data;
        
        // 时序输出列数
        col_r <= col_r_data;
        col_g <= col_g_data;
        col_b <= col_b_data;
        
        // 行扫描
        if (pwm_cycle_end) begin
            row_sel <= (1 << current_row);  // 行高有效
            row_counter <= current_row;
            col_counter <= 0;
            
            if (current_row == `MATRIX_SIZE - 1) begin
                current_row <= 0;
                
                // 帧结束时更新滚动偏移
                if (roll_ctrl != 2'b00) begin
                    if (frame_counter == 12'b111111111111) begin
                        frame_counter <= 0;
                        
                        if (roll_ctrl == 2'b01) begin      // 右滚 (图案向左移动)
                            scroll_offset <= (scroll_offset + 1) % `MATRIX_SIZE;
                        end
                        else if (roll_ctrl == 2'b10) begin // 左滚 (图案向右移动)
                            scroll_offset <= (scroll_offset + 1) % `MATRIX_SIZE;
                        end
                    end else begin
                        frame_counter <= frame_counter + 1;
                    end
                end
            end else begin
                current_row <= current_row + 1;
            end
        end
        
        // 列处理
        if (col_counter < `MATRIX_SIZE) begin
            // 计算读取地址
            read_addr <= row_counter * `MATRIX_SIZE + scrolled_col;
            col_counter <= col_counter + 1;
        end
    end
end
endmodule