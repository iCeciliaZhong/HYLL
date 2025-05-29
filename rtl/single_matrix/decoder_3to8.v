// *********************************************************************************
// Project Name : HYLL
// Author       : Cecilia
// Create Time  : 2025-05-28
// File Name    : decoder_3to8.v
// Module Name  : decoder_3to8
// ---------------------------------------------------------------------------------
// Description   : 3�?-8线译码器，本项目中用于对LED驱动模块输出的行选择信号进行3-8译码。未考虑极�?�匹配，默认LED高电平有效，若需要低有效在使用时取反即可�?
// 
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2025-05-28    Cecilia           0.6                  Original
//  
// *********************************************************************************
`include "defines.vh"

module decoder_3to8(
    input  [2:0] data_3bit_i,
    input        decoder_en_i,
    output [`ROW_NUM-1:0] data_8bit_o
);

wire sel0 = (data_3bit_i == 3'b000);
wire sel1 = (data_3bit_i == 3'b001);
wire sel2 = (data_3bit_i == 3'b010);
wire sel3 = (data_3bit_i == 3'b011);
wire sel4 = (data_3bit_i == 3'b100);
wire sel5 = (data_3bit_i == 3'b101);
wire sel6 = (data_3bit_i == 3'b110);
wire sel7 = (data_3bit_i == 3'b111);

assign data_8bit_o = {`ROW_NUM{decoder_en_i}} & 
                    (({`ROW_NUM{sel0}} & 8'b0000_0001) |
                     ({`ROW_NUM{sel1}} & 8'b0000_0010) |
                     ({`ROW_NUM{sel2}} & 8'b0000_0100) |
                     ({`ROW_NUM{sel3}} & 8'b0000_1000) |
                     ({`ROW_NUM{sel4}} & 8'b0001_0000) |
                     ({`ROW_NUM{sel5}} & 8'b0010_0000) |
                     ({`ROW_NUM{sel6}} & 8'b0100_0000) |
                     ({`ROW_NUM{sel7}} & 8'b1000_0000));


endmodule