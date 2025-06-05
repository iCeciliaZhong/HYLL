`timescale 1ns / 1ps

module top_tb();

// 输入信号
reg clk;               // 系统时钟
reg rst_n;             // 复位信号 (低有效)
reg uart_rx;           // UART接收数据

// 输出信号
wire [15:0] row_sel;   // 行选择信号 (低电平有效)
wire [15:0] col_r;     // 红色列驱动
wire [15:0] col_g;     // 绿色列驱动
wire [15:0] col_b;     // 蓝色列驱动
wire [1:0] led_state;  // LED状态指示

// 内部参数
parameter CLK_PERIOD = 20;      // 10ns = 100MHz
parameter BAUD_PERIOD = 8680;   // 115200 baud (100e6 / 115200 ≈ 868.055ns)
parameter TEST_BYTE = 8'hAA;    // 测试数据

// 实例化被测设计(DUT)
top dut (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .row_sel(row_sel),
    .col_r(col_r),
    .col_g(col_g),
    .col_b(col_b),
    .led_state(led_state)
);

// 时钟生成
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// 测试序列
initial begin
    // 初始化
    rst_n = 1'b0;
    uart_rx = 1'b1;  // UART空闲状态为高电平
    #100;
    
    // 释放复位
    rst_n = 1'b1;
    #100;
    
    // 测试1: 发送UART数据
    $display("[TEST 1] Sending UART data...");
    send_uart_byte(TEST_BYTE);
    
    // 等待状态机进入显示状态
    wait(led_state == 2'b10);
    $display("[TEST 1] Display state reached");
    
    // 测试2: 观察PWM和扫描行为
    $display("[TEST 2] Observing PWM and scanning behavior...");
    #100000;  // 观察100us
    
    // 测试3: 发送完整帧数据
    $display("[TEST 3] Sending full frame data...");
    for (int i = 0; i < 256; i = i + 1) begin
        send_uart_byte(i[7:0]);  // 发送0-255的数据
    end
    
    // 等待状态机再次进入显示状态
    wait(led_state == 2'b10);
    $display("[TEST 3] Display state reached with new frame");
    
    // 测试4: 观察完整帧的显示
    $display("[TEST 4] Observing full frame display...");
    #500000;  // 观察500us
    
    $display("All tests completed successfully!");
    $finish;
end

// UART发送任务
task send_uart_byte(input [7:0] data);
    // 发送起始位 (0)
    uart_rx = 1'b0;
    #BAUD_PERIOD;
    
    // 发送8位数据 (LSB first)
    for (int i = 0; i < 8; i = i + 1) begin
        uart_rx = data[i];
        #BAUD_PERIOD;
    end
    
    // 发送停止位 (1)
    uart_rx = 1'b1;
    #BAUD_PERIOD;
endtask

/*
// 监控信号变化
always @(posedge clk) begin
    // 监控状态变化
    static reg [1:0] last_led_state = 2'b00;
    if (led_state !== last_led_state) begin
        $display("LED State changed: %b -> %b at %t", last_led_state, led_state, $time);
        last_led_state = led_state;
    end
    
    // 监控行选择变化
    static reg [15:0] last_row_sel = 16'h0000;
    if (row_sel !== last_row_sel) begin
        $display("Row Select changed: %h -> %h at %t", last_row_sel, row_sel, $time);
        last_row_sel = row_sel;
    end
end

// 波形保存
initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
end
*/
endmodule