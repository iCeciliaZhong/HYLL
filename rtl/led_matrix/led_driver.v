`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : led_driver.v
// Module Name  : led_driver
// ---------------------------------------------------------------------------------
// Description   : 利用移位寄存器实现行扫描，列数据（每行16*3=48个像素点）经pwm比较并行地输出（RGB并行）
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-29    Cecilia           0.6                  Original
//  
// *********************************************************************************

`include "defines.vh"

module led_driver(
    input wire clk,             
    input wire rst_n,           
    input wire pwm_cycle_end,   
    input wire [`COLOR_DEPTH-1:0] pixel_data, 
    input wire [7:0] pwm_counter, 
    
    // to LED matrix
    output reg [`MATRIX_SIZE-1:0] row_sel,  // 1 valid
    output reg [`MATRIX_SIZE-1:0] col_r,    // 0 valid
    output reg [`MATRIX_SIZE-1:0] col_g,    
    output reg [`MATRIX_SIZE-1:0] col_b,    
    
    // to frame buffer
    output reg [`ADDR_WIDTH-1:0]  read_addr, 
    output reg [3:0] row_counter, 
    output reg [3:0] col_counter  
);

// row
reg [3:0] current_row;

// column
reg [`MATRIX_SIZE-1:0] col_r_data;
reg [`MATRIX_SIZE-1:0] col_g_data;
reg [`MATRIX_SIZE-1:0] col_b_data;

// display control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        row_counter <= 0;
        col_counter <= 0;
        current_row <= 0;
        row_sel <= `MATRIX_SIZE'h0000;    
        col_r <= `MATRIX_SIZE'hFFFF;
        col_g <= `MATRIX_SIZE'hFFFF;
        col_b <= `MATRIX_SIZE'hFFFF;
        col_r_data <= `MATRIX_SIZE'hFFFF;
        col_g_data <= `MATRIX_SIZE'hFFFF;
        col_b_data <= `MATRIX_SIZE'hFFFF;
        read_addr <= 0;
    end else begin
        // row
        if (pwm_cycle_end) begin
            if (current_row < MATRIX_SIZE-1) begin
                current_row <= current_row + 1;
            end else begin
                current_row <= 0;
            end
            
            // update row
            row_sel <= (`MATRIX_SIZE'h0001 << current_row);
            
            // next row data
            row_counter <= current_row;
            col_counter <= 0;
        end
        
        // column
        if (col_counter < MATRIX_SIZE) begin
            read_addr <= {row_counter, col_counter};
            // column data
            col_r_data[col_counter] <= (pixel_data[7:5] > pwm_counter[7:5]); 
            col_g_data[col_counter] <= (pixel_data[4:2] > pwm_counter[7:5]); 
            col_b_data[col_counter] <= (pixel_data[1:0] > pwm_counter[7:6]); 
            col_counter <= col_counter + 1;
        end else begin
            // update column
            col_r <= col_r_data;
            col_g <= col_g_data;
            col_b <= col_b_data;
        end
    end
end

endmodule