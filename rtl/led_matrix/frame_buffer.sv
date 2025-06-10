// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-31
// File Name    : frame_buffer.sv
// Module Name  : frame_buffer
// ---------------------------------------------------------------------------------
// Description   : 包含UART接收器实例，接收数据写入后台缓冲区，通过FIFO存满支持显回，并在适当时切换缓冲区。同时，根据read_addr输出当前像素值。缓冲区为双缓冲结构：前台缓冲区用于显示，后台缓冲区用于接收新数据。对于RGB，采用332编码，故COLOR_DEPTH参数为8bit。并定义了两个状态指示灯：00-空闲或复位，01-更新，11-显示
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-31    Cecilia           0.6                  Original
// 2025-06-04    Cecilia           0.88                 支持显回逻辑 
// 2025-06-05    Cecilia           0.9                  修复回显丢失问题
// *********************************************************************************

`include "defines.vh"

module frame_buffer(
    input wire                     clk,             
    input wire                     rst_n,           
    input wire                     uart_rx,         
    input wire  [`ADDR_WIDTH-1:0]  read_addr,  // from scan 
    
    output wire [`COLOR_DEPTH-1:0] pixel_data, 
    output reg  [1:0]              led_state,   
    output wire uart_tx 
);

//例化transmitter
wire tx_ready;
reg tx_valid;
reg [`COLOR_DEPTH-1:0] tx_data;

uart_transmitter u_uart_transmitter(
    .clk(clk),
    .rst_n(rst_n),
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .tx(uart_tx),
    .tx_ready(tx_ready)
);

// 回显FIFO (深度2)
reg [7:0] fifo [0:1];
reg fifo_wptr = 0;
reg fifo_rptr = 0;
reg [1:0] fifo_count = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_valid <= 1'b0;
        tx_data <= 0;
        fifo_wptr <= 0;
        fifo_rptr <= 0;
        fifo_count <= 0;
    end else begin
        tx_valid <= 1'b0;
        
        // 写入FIFO
        if (uart_rx_valid && fifo_count < 2) begin
            fifo[fifo_wptr] <= uart_rx_data;
            fifo_wptr <= ~fifo_wptr;
            fifo_count <= fifo_count + 1;
        end
        
        // 读取FIFO
        if (tx_ready && fifo_count > 0 && !tx_valid) begin
            tx_valid <= 1'b1;
            tx_data <= fifo[fifo_rptr];
            fifo_rptr <= ~fifo_rptr;
            fifo_count <= fifo_count - 1;
        end
    end
end

parameter FRAME_BUFFER_SIZE = `MATRIX_SIZE * `MATRIX_SIZE; // 64 pixels


// 修正后的爱心图案 (居中设计)
localparam [7:0] HEART_PATTERN [0:63] = '{
    // 行0 (顶部)
    8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
    // 行1
    8'h00, 8'h1C, 8'h00, 8'h00, 8'h1C, 8'h00, 8'h00, 8'h00,
    // 行2
    8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'h00, 8'h00,
    // 行3
    8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'h00, 8'h00,
    // 行4
    8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'h00, 8'h00,
    // 行5
    8'h00, 8'hE0, 8'hE0, 8'hE0, 8'hE0, 8'h00, 8'h00, 8'h00,
    // 行6
    8'h00, 8'h00, 8'h03, 8'h03, 8'h00, 8'h00, 8'h00, 8'h00,
    // 行7 (底部)
    8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00
};

// buffer
reg [`COLOR_DEPTH-1:0] buffer0 [0:FRAME_BUFFER_SIZE-1]; // receive new data (from pc)
reg [`COLOR_DEPTH-1:0] buffer1 [0:FRAME_BUFFER_SIZE-1]; // display (to driver)
reg [`ADDR_WIDTH-1:0]  write_addr;                      // index addr
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
            buffer0[i] <= HEART_PATTERN[i];
            buffer1[i] <= HEART_PATTERN[i];
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
                write_addr <= write_addr + 1;
            end
        end
        
        // pixel data receive finished
        if (write_addr == FRAME_BUFFER_SIZE) begin
            new_data_ready <= 1;
            write_addr <= 0;
        end
        
        /* shift
        if (new_data_ready && current_state == IDLE) begin
            buffer_sel <= ~buffer_sel; 
            new_data_ready <= 0;
        end
        */
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
            if (new_data_ready) next_state = UPDATING;
            else next_state = DISPLAYING;
        end
        UPDATING: begin
            next_state = DISPLAYING;
        end
        DISPLAYING: begin
            if (new_data_ready) next_state = UPDATING;
        end
        default: next_state = IDLE;
    endcase
end

// 在UPDATING状态切换缓冲区
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buffer_sel <= 0;
    end else if (current_state == UPDATING) begin
        buffer_sel <= ~buffer_sel;
        new_data_ready <= 0;
    end
end


assign pixel_data = (buffer_sel == 0) ? buffer0[read_addr] : buffer1[read_addr];

// state detect
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_state <= 2'b11;
    end else begin
        if (|write_addr) begin          
            led_state <= 2'b01;
        end else if (buffer_sel) begin 
            led_state <= 2'b00;
        end else begin                 
            led_state <= 2'b10;
        end
    end
end

// 调试:验证frame buffer中是否有uart传输的数据
always @(posedge clk) begin
    if (uart_rx_valid) begin
        $display("RX Data: %h at Addr: %d", uart_rx_data, write_addr);
    end
    
    if (write_addr == 63) begin
        $display("Full frame received!");
    end
end


endmodule