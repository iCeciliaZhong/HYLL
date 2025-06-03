`timescale 1ns / 1ps

module marquee_tb();

// �����ź�
reg clk;      // 50MHzʱ��
reg rst;      // ��λ�źţ��͵�ƽ��Ч��

// ����ź�
wire [1:0] led;
wire [7:0] led_row;
wire [7:0] led_col_r;
wire [7:0] led_col_g;
wire [7:0] led_col_b;

// ʵ��������ģ��
Marquee uut (
    .clk(clk),
    .rst(rst),
    .led(led),
    .led_row(led_row),
    .led_col_r(led_col_r),
    .led_col_g(led_col_g),
    .led_col_b(led_col_b)
);

// ����50MHzʱ��
initial begin
    clk = 0;
    forever #10 clk = ~clk; // 20ns���� = 50MHz
end

// ��������
initial begin
    // ��ʼ��
    rst = 1;  // ��λ��Ч
    #100;
    
    // ������λ������Ч��
    rst = 0;
    #1000000; // 20ms����ʱ�䣨ʵ�ʷ�������̣�
    rst = 1;
    
    // �۲�״̬�л�
    #20000000; // �ȴ�״̬�仯
    
    // �ٴδ�����λ
    rst = 0;
    #1000000;
    rst = 1;
    
    // ��������
    #10000000;
    $finish;
end

// ��عؼ��ź�
initial begin
    $monitor("Time=%t | State=%b | R=%b G=%b B=%b | LED=%b", 
             $time, uut.led_state, 
             led_col_r, led_col_g, led_col_b, led);
end

endmodule