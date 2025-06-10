`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-29
// File Name    : top.v
// Module Name  : top
// ---------------------------------------------------------------------------------
// Description   : 顶层互连，包含uart收发、按键控制逻辑、分级调光逻辑、pwm模块、frame_buffer模块、led_driver驱动模块
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-29    Cecilia           0.6                  Original
// 2025-06-02    Cecilia           0.88                 互连变量统一
// 2025-06-04    Cecilia           0.9                  支持显回逻辑
// 2025-06-05    Cecilia           0.95                 支持滚动
// 2025-06-08    Cecilia           0.98                 支持四级亮度控制
// *********************************************************************************

// 修改后的 top.v 文件
`timescale 1ns / 1ps
`include "defines.vh"

module top(
    input wire clk,             
    input wire rst_n,           // 0 valid
    input wire uart_rx,  
    input wire [1:0] roll_ctrl, // 00-static, 01-right, 10-left, 11-reset
    input wire bright_ctrl,
    input wire uart_rx_command,
    
    output wire [`MATRIX_SIZE-1:0] row_sel, 
    output wire                    uart_tx, 
    output wire [`MATRIX_SIZE-1:0] col_r,
    output wire [`MATRIX_SIZE-1:0] col_g,
    output wire [`MATRIX_SIZE-1:0] col_b,
    
    output wire [1:0] bright_state,
    output wire [1:0] led_state 
);

/*ILA DEBUG: 不需要直接在defines.vh注释掉ILA即可*/
`ifdef ILA
// ILA 实例化
wire clk_bufg;
BUFG bufg_inst (.I(clk), .O(clk_bufg));

(* DONT_TOUCH = "TRUE" *) 
wire debug_uart_rx_valid;        // 串口接收有效信号
wire debug_write_addr_overflow;   // 写地址溢出指示
wire [7:0] debug_write_addr;     // 写地址（扩展为8位）
wire [7:0] debug_pixel_data;     // 像素数据
wire [7:0] debug_read_addr;      // 读地址（扩展为8位）
wire debug_pwm_cycle_end;        // PWM周期结束信号

// 信号连接到ILA探针
assign debug_uart_rx_valid = u_frame_buffer.uart_rx_valid;
assign debug_write_addr = {4'b0, u_frame_buffer.write_addr};
assign debug_write_addr_overflow = (u_frame_buffer.write_addr >= `MATRIX_SIZE*`MATRIX_SIZE);
assign debug_pixel_data = pixel_data;
assign debug_read_addr = {4'b0, read_addr};
assign debug_pwm_cycle_end = pwm_cycle_end;

// ILA核心
ila_0 debug_ila (
    .clk(clk_bufg), // 注意：使用BUFG后的时钟
    .probe0(debug_uart_rx_valid), 
    .probe1(debug_write_addr),
    .probe2(debug_write_addr_overflow),
    .probe3(debug_pixel_data),
    .probe4(debug_read_addr),
    .probe5(debug_pwm_cycle_end)
);

`endif 
/* ILA end*/

wire [`COLOR_DEPTH-1:0] pixel_data;
wire [`ADDR_WIDTH-1:0] read_addr;
wire pwm_cycle_end;
wire [7:0] pwm_counter;
wire [3:0] row_counter;
wire [3:0] col_counter;


reg [1:0] bright_level;    
reg bright_ctrl_dly; 

/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bright_level <= 2'b00;  
        bright_ctrl_dly <= 1'b1;
    end else begin
        bright_ctrl_dly <= bright_ctrl;  
        if (bright_ctrl && !bright_ctrl_dly) begin
            bright_level <= bright_level + 1;
        end
    end
end
*/

/*PWM 分级调光*/
// 消抖参数设置 (50MHz时钟对应20ms)
parameter DEBOUNCE_MS = 20;          // 消抖时间(ms)
parameter CLK_FREQ = 50_000_000;    // 时钟频率(Hz)
localparam DEBOUNCE_CYCLES = (DEBOUNCE_MS * CLK_FREQ) / 1000;

// 按钮同步逻辑
reg [1:0] btn_sync;
always @(posedge clk) btn_sync <= {btn_sync[0], ~bright_ctrl}; // 注意这里取反

// 消抖
reg [19:0] debounce_cnt;
reg btn_debounced;

always @(posedge clk) begin
    if(btn_sync[1] != btn_debounced) begin
        if(debounce_cnt == DEBOUNCE_CYCLES) begin
            btn_debounced <= btn_sync[1]; 
            debounce_cnt <= 0;
        end else begin
            debounce_cnt <= debounce_cnt + 1;
        end
    end else begin
        debounce_cnt <= 0; 
    end
end


reg [1:0] edge_detect;
always @(posedge clk) edge_detect <= {edge_detect[0], btn_debounced};
wire btn_pressed = (edge_detect == 2'b10); 

always @(posedge clk) begin // 优先级：复位>按键>uart命令
    if (!rst_n) begin
        bright_level <= 2'b00;  
    end
    if(btn_pressed) begin  // 有效按键
        bright_level <= (bright_level == 2'b11) ? 2'b00 : bright_level + 2'd1;
    end
    else begin
        case(uart_rx_command_data) 
            8'd3: bright_level <= 2'b00;
            8'd4: bright_level <= 2'b01;
            8'd5: bright_level <= 2'b10;
            8'd6: bright_level <= 2'b11;
            default: bright_level <= bright_level;
        endcase
    end
end

assign bright_state = ~(bright_level);

// 模块例化

wire [7:0] uart_rx_command_data;  // 1-左移；2-右移；
                                  // 3-bright_level = 2'b00; 4-bright_level = 2'b01;  
                                  // 5-bright_level = 2'b10; 4-bright_level = 2'b11;      
wire uart_rx_valid_command;    

uart_receiver u_uart_command(
    .clk(clk),
    .rst_n(rst_n),
    .rx(uart_rx_command),
    .rx_data(uart_rx_command_data),
    .rx_valid(uart_rx_valid_command)
);

frame_buffer u_frame_buffer(
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .read_addr(read_addr),
    .pixel_data(pixel_data),
    .led_state(led_state),
    .uart_tx(uart_tx)  
);

// 滚动控制优先级：uart命令>按键
wire [1:0] roll_ctrl_b;
assign roll_ctrl_b =    (uart_rx_command_data == 8'd1)? 2'b00 :
                        (uart_rx_command_data == 8'd2)? 2'b01 :
                        (uart_rx_command_data == 8'd3)? 2'b10 : roll_ctrl;
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
    .col_counter(col_counter),
    .roll_ctrl(roll_ctrl_b),
    .bright_level(bright_level)
);

pwm u_pwm(
    .clk(clk),
    .rst_n(rst_n),
    .pwm_counter(pwm_counter),
    .pwm_cycle_end(pwm_cycle_end)
);

endmodule