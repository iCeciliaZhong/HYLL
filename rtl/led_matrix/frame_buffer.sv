// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-31
// File Name    : frame_buffer.sv
// Module Name  : frame_buffer
// ---------------------------------------------------------------------------------
// Description   : 包含UART接收器实例，接收数据写入后台缓冲区，并在适当时候切换缓冲区。同时，根据read_addr输出当前像素值。缓冲区为双缓冲结构：前台缓冲区变为后台用于接收新数据，后台缓冲区变为前台用于显示。其中，对于RGB，我们采用332编码，故COLOR_DEPTH参数为8bit。并定义了两个状态指示灯，00-空闲或复位，01-更新，11-显示
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-31    Cecilia           0.6                  Original
//  
// *********************************************************************************

`include "defines.vh"

module frame_buffer(
    input wire                     clk,             
    input wire                     rst_n,           
    input wire                     uart_rx,         
    input wire  [`ADDR_WIDTH-1:0]  read_addr,  // from scan 
    
    output wire [`COLOR_DEPTH-1:0] pixel_data, 
    output reg  [1:0]              led_state   
);

parameter FRAME_BUFFER_SIZE = `MATRIX_SIZE * `MATRIX_SIZE; // 256 pixel

// buffer
reg [`COLOR_DEPTH-1:0] buffer0 [0:FRAME_BUFFER_SIZE-1]; // receive new data (from pc)
reg [`COLOR_DEPTH-1:0] buffer1 [0:FRAME_BUFFER_SIZE-1]; // display (to driver)
reg [`ADDR_WIDTH-1:0]  write_addr;                      // index addr，[7:4]row / [3:0]column
reg buffer_sel;       
reg new_data_ready;   

// uart
wire [`COLOR_DEPTH-1:0] uart_rx_data;        
wire uart_rx_valid;    

uart_receiver u_uart_receiver(
    .clk(clk),
    .rst_n(rst_n),
    .rx(uart_rx),
    .rx_data(uart_rx_data),
    .rx_valid(uart_rx_valid)
);


typedef enum logic [1:0] {
    IDLE,         
    UPDATING,     
    DISPLAYING    
} state_t;

state_t current_state, next_state;


// buffer management
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_addr <= 0;
        buffer_sel <= 0;
        new_data_ready <= 0;
        
        // initialize
        for (int i = 0; i < FRAME_BUFFER_SIZE; i = i + 1) begin
            buffer0[i] <= 0;
            buffer1[i] <= 0;
        end
    end else begin
        // uart
        if (uart_rx_valid) begin
            if (write_addr < FRAME_BUFFER_SIZE) begin
                if (buffer_sel == 0) begin
                    buffer1[write_addr] <= uart_rx_data;
                end else begin
                    buffer0[write_addr] <= uart_rx_data;
                end
                write_addr <= write_addr + 8'd1;
            end
        end
        
        // pixel data receive finished
        if (write_addr == FRAME_BUFFER_SIZE) begin
            new_data_ready <= 1;
            write_addr <= 0;
        end
        
        // shift
        if (new_data_ready && current_state == IDLE) begin
            buffer_sel <= ~buffer_sel; 
            new_data_ready <= 0;
        end
    end
end

//receive fsm
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (new_data_ready) begin
                next_state = UPDATING;
            end else begin
                next_state = DISPLAYING;
            end
        end
        
        UPDATING: begin
            next_state = DISPLAYING;
        end
        
        DISPLAYING: begin
            if (new_data_ready) begin
                next_state = UPDATING;
            end
        end
        
        default: next_state = IDLE;
    endcase
end


assign pixel_data = (buffer_sel == 0) ? buffer0[read_addr] : buffer1[read_addr];

// state detect
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_state <= 2'b00;
    end else begin
        led_state <= current_state;
    end
end

endmodule