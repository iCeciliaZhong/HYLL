// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-31
// File Name    : pwm.v
// Module Name  : pwm
// ---------------------------------------------------------------------------------
// Description   : 生成PWM周期调制信号
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-31    Cecilia           0.6                  Original
//  
// *********************************************************************************

module pwm(
    input wire clk,             
    input wire rst_n,           
    
    output reg [7:0] pwm_counter, 
    output reg pwm_cycle_end    
);


parameter PWM_MAX = 255;        


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pwm_counter <= 0;
        pwm_cycle_end <= 0;
    end else begin
        pwm_cycle_end <= 0;
        
        if (pwm_counter < PWM_MAX) begin
            pwm_counter <= pwm_counter + 1;
        end else begin
            pwm_counter <= 0;
            pwm_cycle_end <= 1; 
        end
    end
end

endmodule