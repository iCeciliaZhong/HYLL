// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-31
// File Name    : frame_buffer.sv
// Module Name  : frame_buffer
// ---------------------------------------------------------------------------------
// Description   : 包含UART接收器实例，接收数据写入后台缓冲区，并在适当时切换缓冲区。同时，根据read_addr输出当前像素值。缓冲区为双缓冲结构：前台缓冲区用于显示，后台缓冲区用于接收新数据。对于RGB，采用332编码，故COLOR_DEPTH参数为8bit。并定义了两个状态指示灯：00-空闲或复位，01-更新，11-显示
// 
// ​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-31    Cecilia           0.6                  Original
// 2025-06-04    Cecilia           0.88                 支持显回逻辑 
// ​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*​**​*

`include "defines.vh"

module frame_buffer(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [`ADDR_WIDTH-1:0]   read_addr,
    output wire [`COLOR_DEPTH-1:0]  pixel_data,
    output reg  [1:0]               led_state,
    // 新增AXI Lite接口
    // 寄存器映射:
    // 0x00: 数据寄存器 (写入像素数据)
    // 0x04: 地址寄存器 (设置写地址)
    // 0x08: 控制寄存器 [0]: 切换缓冲区 [1]: 复位写地址 [2]: 地址自动递增
    input  wire [31:0]              s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    input  wire [31:0]              s_axi_wdata,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    output wire [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready
);

// 参数定义
parameter FRAME_SIZE = `MATRIX_SIZE * `MATRIX_SIZE;

// AXI Lite接口逻辑
reg [31:0] axi_awaddr;
reg        aw_en;
reg [31:0] axi_wdata;
reg        w_en;
reg        auto_inc;  // 地址自动递增标志

// 双缓冲逻辑
reg [`COLOR_DEPTH-1:0] buffer0 [0:FRAME_SIZE-1];
reg [`COLOR_DEPTH-1:0] buffer1 [0:FRAME_SIZE-1];
reg buffer_sel;  // 0: buffer0显示，buffer1写入; 1: buffer1显示，buffer0写入
reg [`ADDR_WIDTH-1:0] write_addr;

// AXI响应
assign s_axi_bresp = 2'b00; // OKAY

// AXI握手信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        aw_en <= 1'b1;  // 初始可接收地址
        w_en  <= 1'b0;
    end else begin
        // AWREADY生成
        if (~s_axi_awready && s_axi_awvalid && aw_en) begin
            s_axi_awready <= 1'b1;
            aw_en <= 1'b0;
        end else if (s_axi_bready && s_axi_bvalid) begin
            aw_en <= 1'b1;
            s_axi_awready <= 1'b0;
        end else begin
            s_axi_awready <= 1'b0;
        end

        // WREADY生成
        if (~s_axi_wready && s_axi_wvalid && ~w_en) begin
            s_axi_wready <= 1'b1;
            w_en <= 1'b1;
        end else begin
            s_axi_wready <= 1'b0;
        end

        // BVALID生成
        if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
            s_axi_bvalid <= 1'b1;
        end else if (s_axi_bready && s_axi_bvalid) begin
            s_axi_bvalid <= 1'b0;
        end
    end
end

// AXI地址和数据锁存
always @(posedge clk) begin
    if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid) begin
        axi_awaddr <= s_axi_awaddr;
    end
    if (s_axi_wready && s_axi_wvalid) begin
        axi_wdata <= s_axi_wdata;
    end
end

// AXI写入处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buffer_sel <= 1'b0;
        write_addr <= 0;
        auto_inc   <= 1'b0;
    end else if (s_axi_bvalid && s_axi_bready) begin
        case (axi_awaddr[7:0])
            // 数据寄存器
            8'h00: begin
                // 写入非显示缓冲区
                if (buffer_sel) begin
                    buffer0[write_addr] <= axi_wdata[`COLOR_DEPTH-1:0];
                end else begin
                    buffer1[write_addr] <= axi_wdata[`COLOR_DEPTH-1:0];
                end
                // 地址自动递增
                if (auto_inc && (write_addr < FRAME_SIZE-1)) begin
                    write_addr <= write_addr + 1;
                end
            end
            // 地址寄存器
            8'h04: write_addr <= axi_wdata[`ADDR_WIDTH-1:0];
            // 控制寄存器
            8'h08: begin
                if (axi_wdata[0]) buffer_sel <= ~buffer_sel;  // 切换缓冲区
                if (axi_wdata[1]) write_addr <= 0;            // 复位写地址
                auto_inc <= axi_wdata[2];                     // 地址自动递增
            end
        endcase
    end
end

// LED状态指示
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_state <= 2'b00;  // 复位状态
    end else begin
        // 00: 空闲/复位 01: 更新 11: 显示
        case ({buffer_sel, |write_addr})
            2'b00: led_state <= 2'b11;  // 显示buffer0，无更新
            2'b01: led_state <= 2'b01;  // 显示buffer0，buffer1更新中
            2'b10: led_state <= 2'b11;  // 显示buffer1，无更新
            2'b11: led_state <= 2'b01;  // 显示buffer1，buffer0更新中
        endcase
    end
end

// 显示逻辑
assign pixel_data = buffer_sel ? buffer1[read_addr] : buffer0[read_addr];

endmodule