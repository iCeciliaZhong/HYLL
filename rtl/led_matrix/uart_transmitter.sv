// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-06-04
// File Name    : uart_transmitter.v
// Module Name  : uart_transmitter
// ---------------------------------------------------------------------------------
// Description   : UART发送模块，支持回显功能
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-06-04    Cecilia           1.0                  Original
// 2025-06-05    Cecilia           1.1                  Fix ready signal
// *********************************************************************************

`include "defines.vh"

module uart_transmitter #(
    parameter CLK_FREQ = 50_000_000,  // 50MHz
    parameter BAUD_RATE = 115200      
)(
    input wire clk,
    input wire rst_n,
    input wire tx_valid,          
    input wire [`COLOR_DEPTH-1:0] tx_data, 
    output reg tx,                
    output reg tx_ready          
);

localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
localparam BIT_COUNTER_WIDTH = $clog2(BIT_PERIOD);


typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT
} state_t;

state_t current_state;


reg [BIT_COUNTER_WIDTH-1:0] bit_counter;
reg [2:0] bit_index;
reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        tx <= 1'b1;
        tx_ready <= 1'b1;
        bit_counter <= 0;
        bit_index <= 0;
        shift_reg <= 0;
    end else begin
        case (current_state)
            IDLE: begin
                tx <= 1'b1;  
                tx_ready <= 1'b1;
                
                if (tx_valid && tx_ready) begin
                    shift_reg <= tx_data;
                    current_state <= START_BIT;
                    bit_counter <= 0;
                    tx_ready <= 1'b0;
                end
            end
            

            START_BIT: begin
                tx <= 1'b0;
                
                if (bit_counter < BIT_PERIOD - 1) begin
                    bit_counter <= bit_counter + 1;
                end else begin
                    bit_counter <= 0;
                    current_state <= DATA_BITS;
                    bit_index <= 0;
                end
            end
            
            DATA_BITS: begin
                tx <= shift_reg[bit_index];
                
                if (bit_counter < BIT_PERIOD - 1) begin
                    bit_counter <= bit_counter + 1;
                end else begin
                    bit_counter <= 0;
                    
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        current_state <= STOP_BIT;
                    end
                end
            end
            
            STOP_BIT: begin
                tx <= 1'b1;
                
                if (bit_counter < BIT_PERIOD - 1) begin
                    bit_counter <= bit_counter + 1;
                end else begin
                    bit_counter <= 0;
                    current_state <= IDLE;
                    tx_ready <= 1'b1; 
                end
            end
            
            default: current_state <= IDLE;
        endcase
    end
end

endmodule