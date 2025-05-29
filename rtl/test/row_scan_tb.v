`timescale 1ns / 1ps

module row_scan_tb();

// Inputs
reg clk_i;
reg rst_i;

// Outputs
wire [7:0] led_row_o;
wire [7:0] led_col_r_o;
wire [7:0] led_col_g_o;
wire [7:0] led_col_b_o;

// Instantiate the Unit Under Test (UUT)
row_scan u_rs (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .led_row_o(led_row_o),
    .led_col_r_o(led_col_r_o),
    .led_col_g_o(led_col_g_o),
    .led_col_b_o(led_col_b_o)
);

// Clock generation
parameter CLK_PERIOD = 20; // 50MHz clock (20ns period)
always begin
    clk_i = 1'b0;
    #(CLK_PERIOD/2);
    clk_i = 1'b1;
    #(CLK_PERIOD/2);
end

// Test pattern generator
task load_test_pattern;
    integer r, c;
    begin
        // Fill frame buffer with a test pattern
        for (r = 0; r < 8; r = r + 1) begin
            for (c = 0; c < 8; c = c + 1) begin
                // Diagonal pattern
                if (r == c) begin
                    u_rs.frame_buffer[r][c][0] = 1'b1; // Red
                    u_rs.frame_buffer[r][c][1] = 1'b1; // Green
                    u_rs.frame_buffer[r][c][2] = 1'b0; // Blue off
                end
                // Cross pattern
                else if ((r + c) == 7) begin
                    u_rs.frame_buffer[r][c][0] = 1'b1; // Red
                    u_rs.frame_buffer[r][c][1] = 1'b0; // Green off
                    u_rs.frame_buffer[r][c][2] = 1'b1; // Blue
                end
                else begin
                    u_rs.frame_buffer[r][c][0] = 1'b0; // Red off
                    u_rs.frame_buffer[r][c][1] = 1'b0; // Green off
                    u_rs.frame_buffer[r][c][2] = 1'b0; // Blue off
                end
            end
        end
    end
endtask

// Monitor output
always @(posedge clk_i) begin
    if (!rst_i) begin
        $display("Time=%0t: Row=%b, Col_R=%b, Col_G=%b, Col_B=%b", 
                 $time, led_row_o, led_col_r_o, led_col_g_o, led_col_b_o);
    end
end

// Main test sequence
initial begin
    // Initialize Inputs
    rst_i = 1'b1;
    
    // Wait for global reset
    #100;
    rst_i = 1'b0;
    
    // Load test pattern into frame buffer
    load_test_pattern();
    
    // Let it run for several refresh cycles
    #1000000; // 1ms simulation time
    
    // Check if all rows are being scanned properly
    $display("Simulation complete");
    $stop;
end

endmodule

