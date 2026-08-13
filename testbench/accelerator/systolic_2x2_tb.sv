`timescale 1ns / 1ps

module systolic_2x2_tb;

    parameter DATA_WIDTH = 32;
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 2;

    logic clk = 1'b0;
    logic rst_n;
    logic clear;
    logic [DATA_WIDTH-1:0] a_in[1:0];
    logic [DATA_WIDTH-1:0] b_in[1:0];
    logic [ACC_WIDTH-1:0] c00, c01, c10, c11;

    integer errors = 0;

    systolic_2x2 
    #(
        .DATA_WIDTH (DATA_WIDTH ),
        .ACC_WIDTH  (ACC_WIDTH  )
    )
    u_systolic_2x2(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .clear (clear ),
        .a_in  (a_in  ),
        .b_in  (b_in  ),
        .c00   (c00   ),
        .c01   (c01   ),
        .c10   (c10   ),
        .c11   (c11   )
    );
    
    always #5 clk <= ~clk;

    initial begin
        $dumpfile("build/sim/systolic_2x2_tb.vcd");
        $dumpvars(0, systolic_2x2_tb);

        a_in[0] = 32'd0;
        b_in[0] = 32'd0;
        a_in[1] = 32'd0;
        b_in[1] = 32'd0;

        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        clear = 1'b1;
        repeat (5) @(posedge clk);
        clear = 1'b0;

        // Test a simple matrix multiplication: A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]]
        // A矩阵横着按行送到a_in，B矩阵竖着按列送到b_in，注意Skew
        // T0
        a_in[0] = 32'd1;
        b_in[0] = 32'd5;
        a_in[1] = 32'd0;
        b_in[1] = 32'd0;
        @(posedge clk);
        if (c00 !== 66'd5 || c01 !== 66'd0 || c10 !== 66'd0 || c11 !== 66'd0) begin
            $display("Error: expected c00 = 5, c01 = 0, c10 = 0, c11 = 0, got c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d", c00, c01, c10, c11);
            errors = errors + 1;
        end
        else $display("Correct: T0: c00: %0d, c01: %0d, c10: %0d, c11: %0d", c00, c01, c10, c11);

        // T1
        a_in[0] = 32'd2;
        b_in[0] = 32'd7;
        a_in[1] = 32'd3;
        b_in[1] = 32'd6;
        @(posedge clk);
        if (c00 !== 66'd19 || c01 !== 66'd6 || c10 !== 66'd15 || c11 !== 66'd0) begin
            $display("Error: expected c00 = 19, c01 = 6, c10 = 15, c11 = 0, got c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d", c00, c01, c10, c11);
            errors = errors + 1;
        end
        else $display("Correct: T1: c00: %0d, c01: %0d, c10: %0d, c11: %0d", c00, c01, c10, c11);

        // T2
        a_in[0] = 32'd0;
        b_in[0] = 32'd0;
        a_in[1] = 32'd4;
        b_in[1] = 32'd8;
        @(posedge clk);
        if (c00 !== 66'd19 || c01 !== 66'd22 || c10 !== 66'd43 || c11 !== 66'd18) begin
            $display("Error: expected c00 = 19, c01 = 22, c10 = 43, c11 = 18, got c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d", c00, c01, c10, c11);
            errors = errors + 1;
        end
        else $display("Correct: T2: c00: %0d, c01: %0d, c10: %0d, c11: %0d", c00, c01, c10, c11);

        // T3
        a_in[0] = 32'd0;
        b_in[0] = 32'd0;
        a_in[1] = 32'd0;
        b_in[1] = 32'd0;
        @(posedge clk);
        if (c00 !== 66'd19 || c01 !== 66'd22 || c10 !== 66'd43 || c11 !== 66'd50) begin
            $display("Error: expected c00 = 19, c01 = 22, c10 = 43, c11 = 50, got c00 = %0d, c01 = %0d, c10 = %0d, c11 = %0d", c00, c01, c10, c11);
            errors = errors + 1;
        end
        else $display("Correct: T3: c00: %0d, c01: %0d, c10: %0d, c11: %0d", c00, c01, c10, c11);

        if (errors == 0)
            $display("All tests passed!");
        else
            $display("Total errors: %0d", errors);
        
        $finish;
    end
endmodule
