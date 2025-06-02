`timescale 1ns / 1ps

module marquee_tb();

// 输入信号
reg clk;      // 50MHz时钟
reg rst;      // 复位信号（低电平有效）

// 输出信号
wire [1:0] led;
wire [7:0] led_row;
wire [7:0] led_col_r;
wire [7:0] led_col_g;
wire [7:0] led_col_b;

// 实例化被测模块
Marquee uut (
    .clk(clk),
    .rst(rst),
    .led(led),
    .led_row(led_row),
    .led_col_r(led_col_r),
    .led_col_g(led_col_g),
    .led_col_b(led_col_b)
);

// 生成50MHz时钟
initial begin
    clk = 0;
    forever #10 clk = ~clk; // 20ns周期 = 50MHz
end

// 测试序列
initial begin
    // 初始化
    rst = 1;  // 复位无效
    #100;
    
    // 触发复位（低有效）
    rst = 0;
    #1000000; // 20ms消抖时间（实际仿真可缩短）
    rst = 1;
    
    // 观察状态切换
    #20000000; // 等待状态变化
    
    // 再次触发复位
    rst = 0;
    #1000000;
    rst = 1;
    
    // 结束仿真
    #10000000;
    $finish;
end

// 监控关键信号
initial begin
    $monitor("Time=%t | State=%b | R=%b G=%b B=%b | LED=%b", 
             $time, uut.led_state, 
             led_col_r, led_col_g, led_col_b, led);
end

endmodule