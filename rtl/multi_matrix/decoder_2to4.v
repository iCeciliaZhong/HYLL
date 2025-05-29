// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-28
// File Name    : decoder_2to4.v
// Module Name  : decoder_2to4
// ---------------------------------------------------------------------------------
// Description   : 2线-4线译码器，本项目中用于对LED驱动模块输出的矩阵选择信号进行2-4译码。1使能对应模块。
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-28    Cecilia           0.6                  Original
//  
// *********************************************************************************

module decoder_2to4(
    input  [1:0] data_2bit_i,
    input        decoder_en_i,
    output [3:0] data_4bit_o
);

wire sel0 = (data_2bit_i == 2'b00);
wire sel1 = (data_2bit_i == 2'b01);
wire sel2 = (data_2bit_i == 2'b10);
wire sel3 = (data_2bit_i == 2'b11);


assign data_4bit_o = ({4{sel0}} & 4'b0001) |
                     ({4{sel1}} & 4'b0010) |
                     ({4{sel2}} & 4'b0100) |
                     ({4{sel3}} & 4'b1000) |;


endmodule