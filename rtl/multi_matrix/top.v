`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-28
// File Name    : top.v
// Module Name  : top
// ---------------------------------------------------------------------------------
// Description   : 
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-28    Cecilia           0.6                  Original
//  
// *********************************************************************************

`include "defines.vh"

module top(
    input clk,
    input rst,
    output reg led0, // rst
    output reg led1, // clk

    output [3:0][7:0] led_row,
    output [3:0][7:0] led_col_r,,
    output [3:0][7:0] led_col_g,
    output [3:0][7:0] led_col_b
);

    wire [3:0] LED_DR;
    wire [3:0] LED_DG;
    wire [3:0] LED_DB;
    wire [4:0] LED_ROW;
    wire shift_clk_o;
    wire LED_STB;
    wire LED_OE;



wire [`PWM_DEPTH-1:0] pwm_cnt;
wire frame_end;


pwm_ctrl  u_pwm_ctrl(
    .clk_i(clk),
    .rst_i(~rst), 
    .frame_end_o(frame_end),
    .pwm_cnt_o(pwm_cnt)
);


scan_fsm u_scan_fsm(
    .clk_i(clk),
    .rst_i(rst),
    .color_data_i(/* 连接颜色数据源 */),
    .pwm_cnt_i(pwm_cnt),
    .led_sel(LED_ROW),
    .col_shift_clk_o(shift_clk_o),
    .led_latch_o(LED_STB),
    .led_en_o(LED_OE),
    .frame_end_o(frame_end),
    .led_r_o(LED_DR),
    .led_g_o(LED_DG),
    .led_b_o(LED_DB)
);

//row sel
decoder_3to8 u_d1(
    .data_3bit_i (LED_ROW[2:0]),
    .decoder_en_i(1'b1),
    .data_8bit_o (led_row[(LED_ROW[4:3]):0][7:0])
);

endmodule
/*
module top(
    input clk,
    input rst,
    output reg led0,
    output reg led1,
    
    // 4组RGB数据线（每组对应一个8x8模块）
    output [3:0] LED_DR,
    output [3:0] LED_DG,
    output [3:0] LED_DB,
    
    // 行选择信号扩展
    output [4:0] LED_ROW,  // [4:3]模块选择，[2:0]行选择
    output shift_clk_o,
    output reg LED_STB,
    output LED_OE
);

// 参数重定义
`define MODULE_NUM 4       // 模块数量
`define MODULE_SIZE 8      // 单模块尺寸
`define TOTAL_WIDTH (`MODULE_SIZE * 2) // 总宽度16像素
`define BIT_DEPTH 8        // PWM位深

reg [24:0] counter;        // 主计数器
wire pixel_clock = counter[2]; // 分频时钟

// 状态机参数
`define STATE_IDLE         3'b000
`define STATE_SHIFT        3'b001
`define STATE_LATCH        3'b010
`define STATE_UPDATE       3'b011

// 扫描控制信号
reg [2:0] state;
reg [2:0] row_cnt;         // 行计数器（0-7）
reg [1:0] module_cnt;      // 模块计数器（0-3）
reg [3:0] pwm_cnt;         // PWM位计数器（0-7）
reg [`TOTAL_WIDTH-1:0] shift_cnt; // 移位计数器

// 颜色数据存储（4模块 x 8行 x 16列）
reg [23:0] color_ram [0:3][0:7][0:15]; // [模块][行][列]

// 数据输出缓存
reg [15:0] r_data [0:3];
reg [15:0] g_data [0:3];
reg [15:0] b_data [0:3];

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter <= 0;
        state <= `STATE_IDLE;
        row_cnt <= 0;
        module_cnt <= 0;
        pwm_cnt <= `BIT_DEPTH-1;
        shift_cnt <= 0;
        LED_STB <= 0;
        LED_ROW <= 5'b11111; // 默认关闭所有行
    end else begin
        counter <= counter + 1;
        
        case(state)
            // 空闲状态初始化
            `STATE_IDLE: begin
                LED_OE <= 1;
                if (pixel_clock) begin
                    state <= `STATE_SHIFT;
                    shift_cnt <= 0;
                    // 加载当前行数据
                    for (integer m=0; m<4; m=m+1) begin
                        r_data[m] <= color_ram[m][row_cnt][shift_cnt];
                        g_data[m] <= color_ram[m][row_cnt][shift_cnt];
                        b_data[m] <= color_ram[m][row_cnt][shift_cnt];
                    end
                end
            end
            
            // 数据移位状态
            `STATE_SHIFT: begin
                shift_clk_o <= 0;
                if (shift_cnt < `TOTAL_WIDTH) begin
                    // 输出数据到所有模块
                    for (integer m=0; m<4; m=m+1) begin
                        LED_DR[m] <= r_data[m][shift_cnt];
                        LED_DG[m] <= g_data[m][shift_cnt];
                        LED_DB[m] <= b_data[m][shift_cnt];
                    end
                    shift_cnt <= shift_cnt + 1;
                    shift_clk_o <= 1; // 生成时钟上升沿
                end else begin
                    state <= `STATE_LATCH;
                    LED_STB <= 1; // 锁存数据
                end
            end
            
            // 数据锁存状态
            `STATE_LATCH: begin
                LED_STB <= 0;
                LED_OE <= 0; // 使能显示输出
                state <= `STATE_UPDATE;
                // 设置当前行选择
                LED_ROW <= {module_cnt, row_cnt};
            end
            
            // 更新状态
            `STATE_UPDATE: begin
                if (module_cnt == 3) begin
                    module_cnt <= 0;
                    if (row_cnt == 7) begin
                        row_cnt <= 0;
                        if (pwm_cnt == 0)
                            pwm_cnt <= `BIT_DEPTH-1;
                        else
                            pwm_cnt <= pwm_cnt - 1;
                    end else begin
                        row_cnt <= row_cnt + 1;
                    end
                end else begin
                    module_cnt <= module_cnt + 1;
                end
                state <= `STATE_IDLE;
            end
        endcase
    end
end

// PWM亮度控制（示例）
always @(posedge pixel_clock) begin
    for (integer m=0; m<4; m=m+1) begin
        for (integer r=0; r<8; r=r+1) begin
            for (integer c=0; c<16; c=c+1) begin
                // 亮度比较（实际使用时需要根据颜色值调整）
                color_ram[m][r][c] <= (color_ram[m][r][c] > pwm_cnt) ? 24'hFFFFFF : 24'h000000;
            end
        end
    end
end
*/
