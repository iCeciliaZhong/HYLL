// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-28
// File Name    : uart_receiver.v
// Module Name  : uart_receiver
// ---------------------------------------------------------------------------------
// Description   : 通过状态机实现uart接收模块
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-28    Cecilia           0.6                  Original
//  
// *********************************************************************************

`include "defines.vh"

module uart_receiver #(
    parameter CLK_FREQ = 50_000_000,  // 50MHz
    parameter BAUD_RATE = 115200      
)(
    input wire  clk,
    input wire  rst_n,
    input wire  rx,
    output reg  [`COLOR_DEPTH-1:0] rx_data,
    output reg  rx_valid
);
    
// 内部参数
localparam SAMPLE_RATE = CLK_FREQ / BAUD_RATE;
localparam SAMPLE_HALF = SAMPLE_RATE / 2;

// 内部寄存器
reg [3:0] state;
reg [15:0] sample_counter;
reg [2:0] bit_counter;
reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 0;
        sample_counter <= 0;
        bit_counter <= 0;
        shift_reg <= 0;
        rx_data <= 0;
        rx_valid <= 0;
    end else begin
        rx_valid <= 0;
        
        case (state)
            // 空闲状态，等待起始位
            0: begin
                if (!rx) begin // 检测到起始位
                    state <= 1;
                    sample_counter <= SAMPLE_HALF;
                end
            end
            
            // 采样起始位
            1: begin
                if (sample_counter > 0) begin
                    sample_counter <= sample_counter - 1;
                end else begin
                    if (!rx) begin // 确认起始位有效
                        state <= 2;
                        sample_counter <= SAMPLE_RATE - 1;
                        bit_counter <= 0;
                    end else begin
                        state <= 0; // 无效起始位
                    end
                end
            end
            
            // 采样数据位
            2: begin
                if (sample_counter > 0) begin
                    sample_counter <= sample_counter - 1;
                end else begin
                    shift_reg <= {rx, shift_reg[7:1]}; // 右移
                    sample_counter <= SAMPLE_RATE - 1;
                    
                    if (bit_counter < 7) begin
                        bit_counter <= bit_counter + 1;
                    end else begin
                        state <= 3; // 数据位接收完成
                    end
                end
            end
            
            // 采样停止位
            3: begin
                if (sample_counter > 0) begin
                    sample_counter <= sample_counter - 1;
                end else begin
                    // 收到停止位，数据有效
                    rx_data <= shift_reg;
                    rx_valid <= 1;
                    state <= 0; // 返回空闲状态
                end
            end
            
            default: begin
                state <= 0;
                rx_data <= rx_data;
            end
        endcase
    end
end

endmodule