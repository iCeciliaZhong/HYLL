`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : row_scan.v
// Module Name  : row_scan
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

`include "defines.vh"

module top (
    input            clk_i,          // 50MHz
    input            rst_i,                        
    output reg [7:0] led_row_o,      // 行控制信号（高电平有效）
    output reg [7:0] led_col_r_o,    // 列控制信号（低电平有效）
    output reg [7:0] led_col_g_o,    // 列控制信号（低电平有效）
    output reg [7:0] led_col_b_o     // 列控制信号（低电平有效）
);

wire [2:0] row_sel;
// row display time
localparam ROW_TIME = (`CLK_FREQ / (`REFRESH_RATE * `ROW_NUM)) - 1;

// display mem def (8 rows x 8 cols x 3 colors)
reg [7:0] frame_buffer [0:7][0:7][0:2]; 

reg [2:0] row_cnt;
reg [15:0] timer;

// scan fsm : 
reg [1:0] current_state, next_state;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        current_state <= `IDLE;
        row_cnt <= 0;
        timer <= 0;
        row_sel <= 3'b000;  // shut off all rows
        {led_col_r_o, led_col_g_o, led_col_b_o} <= 24'b0; 
    end else begin
        current_state <= next_state;
        
        case (current_state)
            `IDLE: begin
                next_state <= `BLANKING;
            end
            
            `BLANKING: begin
                row_sel <= 3'b000;
                next_state <= `LOAD_DATA;
            end
            
            `LOAD_DATA: begin
                {led_col_r_o, led_col_g_o, led_col_b_o} <= get_row_data(row_cnt);
                next_state <= `ACTIVATE;
            end
            
            `ACTIVATE: begin
                row_sel <= row_cnt;
                if (timer >= ROW_TIME) begin
                    timer <= 0;
                    // shift row
                    if (row_cnt == `ROW_NUM-1)
                        row_cnt <= 0;
                    else
                        row_cnt <= row_cnt + 1;

                    next_state <= `BLANKING;
                end 
                else begin
                    timer <= timer + 1; // row display until timer end
                    next_state <= `ACTIVATE; 
                end
            end
            
            default: next_state <= `IDLE;
        endcase
    end
end

function [23:0] get_row_data;
    input [2:0] row;
    integer col;
    begin
        get_row_data = 0;
        for (col = 0; col < 8; col = col + 1) begin
            get_row_data[col*3 + 0] = frame_buffer[row][col][0]; 
            get_row_data[col*3 + 1] = frame_buffer[row][col][1]; 
            get_row_data[col*3 + 2] = frame_buffer[row][col][2]; 
        end
    end
endfunction

decoder_3to8 u_d1(
    .data_3bit_i (row_sel),
    .decoder_en_i(1'b1),
    .data_8bit_o (led_row_o)
);

// display mem initialize
initial begin
    integer r, c;
    for (r = 0; r < 8; r = r + 1)
        for (c = 0; c < 8; c = c + 1) begin
            frame_buffer[r][c][0] = 1'b0; 
            frame_buffer[r][c][1] = 1'b0; 
            frame_buffer[r][c][2] = 1'b0; 
        end
end

endmodule