`define LED_ROWS     16
`define LED_COLUMNS  16
`define MATRIX_NUM   4       
`define MATRIX_SIZE  8 
`define TOTAL_WIDTH  (2*`MATRIX_SIZE)      
`define PWM_DEPTH    8

//-------------------scan state------------------

`define SCAN_IDLE    2'b00
`define SCAN_SHIFT   2'b01
`define SCAN_LATCH   2'b10
`define SCAN_UPDATE  2'b11