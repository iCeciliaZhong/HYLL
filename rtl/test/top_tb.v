module top_tb();

reg clk;
reg rst;
reg rx;
reg [1:0] mode;
wire [7:0] row;
wire [7:0] col_r, col_g, col_b;

top uut (
    .clk_i(clk),
    .rst_i(rst),
    .rx_i(rx),
    .mode_i(mode),
    .led_row_o(row),
    .led_col_r_o(col_r),
    .led_col_g_o(col_g),
    .led_col_b_o(col_b)
);

// 时钟生成
always #10 clk = ~clk; // 50MHz

// UART发送任务
task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        rx = 0; // 起始位
        #8680;  // 115200波特率周期
        
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #8680;
        end
        
        rx = 1; // 停止位
        #8680;
    end
endtask

// 发送一帧数据
task send_frame;
    integer i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            uart_send_byte({5'b0, i[2:0]}); // 行地址
            uart_send_byte(8'hFF);           // 红色数据
            uart_send_byte(8'h00);           // 绿色数据
            uart_send_byte(8'hFF);           // 蓝色数据
        end
    end
endtask

initial begin
    // 初始化
    clk = 0;
    rst = 1;
    rx = 1;
    mode = 2'b00; // 静态模式
    
    // 复位
    #100 rst = 0;
    #100;
    
    // 测试1: 静态显示
    send_frame();
    #1000000; // 等待显示
    
    // 测试2: 滚动显示
    mode = 2'b01; // 左滚动
    #5000000;
    
    mode = 2'b10; // 右滚动
    #5000000;
    
    $finish;
end

endmodule