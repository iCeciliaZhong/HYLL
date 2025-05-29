// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-28
// File Name    : scan_fsm.v
// Module Name  : scan_fsm
// ---------------------------------------------------------------------------------
// Description   : 行扫描模块,主体为四个状态（IDLE->SHIFT->LATCH->UPDATE）的状态转换机，
//                SHIFT对某行从左到右进行列移位扫描，LATCH锁存并使能显示，UPDATE依据模块顺序进行行的更新。
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-28    Cecilia           0.6                  Original
//  
// *********************************************************************************

`include "defines.vh"
module scan_fsm(
    input             clk_i, 
    input             rst_i,
    input wire [23:0] color_data_i [0:`MATRIX_NUM-1][0:`MATRIX_SIZE-1][0:2*`MATRIX_SIZE-1],
    input wire [`PWM_DEPTH-1:0] pwm_cnt_i,
    output reg [4:0]  led_sel,       // [4:3]matrix sel，[2:0]row sel
    output            col_shift_clk_o,
    output reg        led_latch_o,
    output reg        led_en_o,      
    output reg [`MATRIX_NUM-1:0] led_r_o,
    output reg [`MATRIX_NUM-1:0] led_g_o,
    output reg [`MATRIX_NUM-1:0] led_b_o,
    output reg        frame_end_o
);


reg [1:0] state;                   
reg [2:0] row_cnt;                   // row counter(0-7)
reg [1:0] matrix_cnt;                // matrix counter(0-3)
reg [`TOTAL_WIDTH-1:0] shift_cnt;    // shift counter
reg [24:0] counter;                  // main counter

always @(posedge clk_i) begin
    frame_end_o <= (matrix_cnt == (`MATRIX_NUM-1)) && 
                  (row_cnt == (`MATRIX_SIZE-1)) &&
                  (state == `SCAN_UPDATE);
end

// color data (/matrix)
reg [2*`MATRIX_SIZE-1:0] r_data [0:`MATRIX_NUM-1];
reg [2*`MATRIX_SIZE-1:0] g_data [0:`MATRIX_NUM-1];
reg [2*`MATRIX_SIZE-1:0] b_data [0:`MATRIX_NUM-1];


reg col_shift_clk;
wire div_clk = counter[2];  

always @(posedge clk_i) begin
    if ((state == `SCAN_SHIFT) && (shift_cnt < `TOTAL_WIDTH)) begin
        col_shift_clk <= ~col_shift_clk;  // 50%
    end else begin
        col_shift_clk <= 0;               
    end
end
assign col_shift_clk_o = col_shift_clk;  


always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        counter     <= 25'b0;
        state       <= `SCAN_IDLE;
        row_cnt     <= 3'd0;
        matrix_cnt  <= 2'b00;
        pwm_cnt     <= `PWM_DEPTH-1;  
        shift_cnt   <= 0;
        led_latch_o <= 1'b0;
        led_en_o    <= 1'b1;          
        led_sel     <= 5'b11111;      
        
        for (int m=0; m<`MATRIX_NUM; m=m+1) begin
            r_data[m] <= 0;
            g_data[m] <= 0;
            b_data[m] <= 0;
        end
    end else begin
        counter <= counter + 1;  
        //fsm begin
        case(state)
            `SCAN_IDLE: begin
                led_en_o <= 1'b1;  
                if (div_clk) begin
                    state <= `SCAN_SHIFT;
                    shift_cnt <= 0;
                    for (int m=0; m<`MATRIX_NUM; m=m+1) begin
                        r_data[m] <= color_data_i[m][row_cnt];  
                        g_data[m] <= color_data_i[m][row_cnt];
                        b_data[m] <= color_data_i[m][row_cnt];
                    end
                end
            end
            

            `SCAN_SHIFT: begin
                if (shift_cnt < `TOTAL_WIDTH) begin
                    for (int m=0; m<`MATRIX_NUM; m=m+1) begin
                        led_r_o[m] <= r_data[m][shift_cnt];
                        led_g_o[m] <= g_data[m][shift_cnt];
                        led_b_o[m] <= b_data[m][shift_cnt];
                    end
                    shift_cnt <= shift_cnt + 1;
                end else begin
                    state <= `SCAN_LATCH;
                    led_latch_o <= 1'b1;  // latch
                end
            end
            
            
            `SCAN_LATCH: begin
                led_latch_o <= 1'b0;   // negedge
                led_en_o    <= 1'b0;   // enable led
                state       <= `SCAN_UPDATE;
                led_sel     <= {matrix_cnt, row_cnt}; 
            end
            
           
            `SCAN_UPDATE: begin
                if (matrix_cnt == (`MATRIX_NUM-1)) begin 
                    matrix_cnt <= 0;
                    if (row_cnt == (`MATRIX_SIZE-1)) begin  
                        row_cnt <= 0;
                    end else begin
                        row_cnt <= row_cnt + 1;
                    end
                end else begin
                    matrix_cnt <= matrix_cnt + 1;
                end
                state <= `SCAN_IDLE;  
            end
        endcase
    end
end
//fsm end

always @(*) begin
    for (int m=0; m<`MATRIX_NUM; m=m+1) begin
        led_r_o[m] = (r_data[m] > pwm_cnt_i);
        led_g_o[m] = (g_data[m] > pwm_cnt_i);
        led_b_o[m] = (b_data[m] > pwm_cnt_i);
    end
end
endmodule