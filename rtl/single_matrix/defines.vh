`define CLK_FREQ      50_000_000
`define REFRESH_RATE  100
`define ROW_NUM       8
`define COL_NUM       8

//-------------------scan state------------------
`define IDLE        2'b00
`define BLANKING    2'b01
`define LOAD_DATA   2'b10
`define ACTIVATE    2'b11