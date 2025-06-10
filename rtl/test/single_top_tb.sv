`include "defines.vh"
`timescale 1ns / 1ps
module single_top_tb();

// 时钟和复位
reg clk;
reg rst_n;

// 输入接口
reg uart_rx;
reg [1:0] roll_ctrl;
reg bright_ctrl;

// 输出接口
wire [`MATRIX_SIZE-1:0] row_sel; 
wire uart_tx; 
wire [`MATRIX_SIZE-1:0] col_r;
wire [`MATRIX_SIZE-1:0] col_g;
wire [`MATRIX_SIZE-1:0] col_b;
wire [1:0] bright_state;
wire [1:0] led_state;

// 实例化设计
top dut (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .roll_ctrl(roll_ctrl),
    .bright_ctrl(bright_ctrl),
    .row_sel(row_sel),
    .uart_tx(uart_tx),
    .col_r(col_r),
    .col_g(col_g),
    .col_b(col_b),
    .bright_state(bright_state),
    .led_state(led_state)
);

// 时钟生成 (100MHz)
always #5 clk = ~clk;

// 主测试流程
initial begin
    // 初始化所有信号
    clk = 0;
    rst_n = 0;
    uart_rx = 1; // UART空闲状态
    roll_ctrl = 2'b00;
    bright_ctrl = 1;
    
    // 创建VCD波形文件用于调试
    $dumpfile("waveforms.vcd");
    $dumpvars(0, tb_top);
    
    // 复位系统
    $display("[%0t] Applying reset", $time);
    #100;
    rst_n = 1;
    #100;
    $display("[%0t] Reset released", $time);
    
    // 测试1: 发送心形图案
    test_send_heart_pattern();
    
    // 等待显示稳定
    #2000000; // 2ms
    
    // 测试2: 亮度控制
    test_brightness_control();
    
    // 测试3: 滚动控制
    test_scroll_control();
    
    // 完成测试
    #1000000; // 1ms
    $display("[%0t] Simulation completed successfully", $time);
    $finish;
end

// 测试1: 发送心形图案
task test_send_heart_pattern;
    integer i;
    integer bit_time_ns = 1000000000 / 115200; // 波特率时间间隔(纳秒)
    reg [7:0] heart_data [0:63];
    begin
        // 初始化心形图案数据 (使用独立赋值确保兼容性)
        heart_data[0] = 8'h00; heart_data[1] = 8'h00; heart_data[2] = 8'h00; heart_data[3] = 8'h00;
        heart_data[4] = 8'h00; heart_data[5] = 8'h00; heart_data[6] = 8'h00; heart_data[7] = 8'h00;
        
        heart_data[8] = 8'h00; heart_data[9] = 8'h1C; heart_data[10] = 8'h00; heart_data[11] = 8'h00;
        heart_data[12] = 8'h1C; heart_data[13] = 8'h00; heart_data[14] = 8'h00; heart_data[15] = 8'h00;
        
        heart_data[16] = 8'hE0; heart_data[17] = 8'hE0; heart_data[18] = 8'hE0; heart_data[19] = 8'hE0;
        heart_data[20] = 8'hE0; heart_data[21] = 8'hE0; heart_data[22] = 8'h00; heart_data[23] = 8'h00;
        
        heart_data[24] = 8'hE0; heart_data[25] = 8'hE0; heart_data[26] = 8'hE0; heart_data[27] = 8'hE0;
        heart_data[28] = 8'hE0; heart_data[29] = 8'hE0; heart_data[30] = 8'h00; heart_data[31] = 8'h00;
        
        heart_data[32] = 8'hE0; heart_data[33] = 8'hE0; heart_data[34] = 8'hE0; heart_data[35] = 8'hE0;
        heart_data[36] = 8'hE0; heart_data[37] = 8'hE0; heart_data[38] = 8'h00; heart_data[39] = 8'h00;
        
        heart_data[40] = 8'h00; heart_data[41] = 8'hE0; heart_data[42] = 8'hE0; heart_data[43] = 8'hE0;
        heart_data[44] = 8'hE0; heart_data[45] = 8'h00; heart_data[46] = 8'h00; heart_data[47] = 8'h00;
        
        heart_data[48] = 8'h00; heart_data[49] = 8'h00; heart_data[50] = 8'h03; heart_data[51] = 8'h03;
        heart_data[52] = 8'h00; heart_data[53] = 8'h00; heart_data[54] = 8'h00; heart_data[55] = 8'h00;
        
        heart_data[56] = 8'h00; heart_data[57] = 8'h00; heart_data[58] = 8'h00; heart_data[59] = 8'h00;
        heart_data[60] = 8'h00; heart_data[61] = 8'h00; heart_data[62] = 8'h00; heart_data[63] = 8'h00;
        
        $display("[%0t] Sending heart pattern data...", $time);
        
        for (i = 0; i < 64; i = i + 1) begin
            // 发送起始位
            uart_rx = 0;
            #(bit_time_ns);
            
            // 发送数据位 (LSB first)
            uart_rx = heart_data[i][0]; #(bit_time_ns);
            uart_rx = heart_data[i][1]; #(bit_time_ns);
            uart_rx = heart_data[i][2]; #(bit_time_ns);
            uart_rx = heart_data[i][3]; #(bit_time_ns);
            uart_rx = heart_data[i][4]; #(bit_time_ns);
            uart_rx = heart_data[i][5]; #(bit_time_ns);
            uart_rx = heart_data[i][6]; #(bit_time_ns);
            uart_rx = heart_data[i][7]; #(bit_time_ns);
            
            // 发送停止位
            uart_rx = 1;
            #(bit_time_ns);
        end
        
        $display("[%0t] Heart pattern data sent", $time);
        #(bit_time_ns * 10); // 额外等待
    end
endtask

// 测试2: 亮度控制
task test_brightness_control;
    integer i;
    begin
        $display("[%0t] Testing brightness control...", $time);
        
        // 测试所有亮度级别
        for (i = 0; i < 4; i = i + 1) begin
            // 模拟按键按下
            bright_ctrl = 0;
            #(100000); // 100us按下
            
            // 模拟按键释放
            bright_ctrl = 1;
            #(2000000); // 2ms保持亮度
            
            $display("[%0t] Brightness level %0d tested", $time, i);
        end
    end
endtask

// 测试3: 滚动控制
task test_scroll_control;
    begin
        $display("[%0t] Testing scroll control...", $time);
        
        // 测试右滚动
        roll_ctrl = 2'b01; // 右滚
        #5000000; // 5ms
        $display("[%0t] Right scroll tested", $time);
        
        // 测试左滚动
        roll_ctrl = 2'b10; // 左滚
        #5000000; // 5ms
        $display("[%0t] Left scroll tested", $time);
        
        // 返回静态模式
        roll_ctrl = 2'b00; // 静态
    end
endtask

// 监视UART回显活动
initial begin
    forever begin
        @(negedge uart_tx) begin
            // 检测到TX下降沿 (UART开始)
            $display("[%0t] UART TX activity detected", $time);
        end
    end
end

// 错误检查：确保没有未知状态
always @(posedge clk) begin
    if (row_sel === 'bx || col_r === 'bx || col_g === 'bx || col_b === 'bx) begin
        $display("[%0t] ERROR: Undefined output detected!", $time);
        $display("row_sel: %b", row_sel);
        $display("col_r: %b", col_r);
        $display("col_g: %b", col_g);
        $display("col_b: %b", col_b);
        $finish;
    end
    
    // 确保地址在有效范围内
    if (dut.read_addr >= `MATRIX_SIZE*`MATRIX_SIZE) begin
        $display("[%0t] ERROR: Invalid read address %0d", $time, dut.read_addr);
        $finish;
    end
end

endmodule