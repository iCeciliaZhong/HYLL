// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-28
// File Name    : pwm_ctrl.v
// Module Name  : pwm_ctrl
// ---------------------------------------------------------------------------------
// Description   : PWM控制模块，PWM计数器在每帧结束时准确递减，与扫描序列分离，通过frame_end信号触发PWM更新，该模块输出pwm_cnt并在扫描模块进行亮度比较。
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-28    Cecilia           0.6                  Original
//  
// *********************************************************************************

module pwm_ctrl(
    input clk_i,
    input rst_i,
    input frame_end_i,          
    output reg [PWM_DEPTH-1:0] pwm_cnt_o 
);

// PWM cnt decrease
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        pwm_cnt_o <= {PWM_DEPTH{1'b1}}; // when rst, the lightest
    end else if (frame_end_i) begin // update
        pwm_cnt_o <= (pwm_cnt_o == 0) ? {PWM_DEPTH{1'b1}} : pwm_cnt_o - 1;
    end
end

endmodule