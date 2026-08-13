`timescale 1ns / 1ps

module pe_tb;

    parameter DATA_WIDTH = 32;
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 2;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic clear = 1'b0;
    logic [DATA_WIDTH-1:0] a_in;
    logic [DATA_WIDTH-1:0] b_in;
    logic [DATA_WIDTH-1:0] a_out;
    logic [DATA_WIDTH-1:0] b_out;
    logic [ACC_WIDTH-1:0] psum;

    integer errors = 0;

    pe 
    #(
        .DATA_WIDTH (DATA_WIDTH ),
        .ACC_WIDTH  (ACC_WIDTH  )
    )
    u_pe(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .clear (clear ),
        .a_in  (a_in  ),
        .b_in  (b_in  ),
        .a_out (a_out ),
        .b_out (b_out ),
        .psum  (psum  )
    );

    always #5 clk <= ~clk;
        
    initial begin
        $dumpfile("build/sim/pe_tb.vcd");
        $dumpvars(0, pe_tb);

        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        clear = 1'b1;
        repeat (5) @(posedge clk);
        clear = 1'b0;

        a_in = 32'd3;           // a00 = 3
        b_in = 32'd5;           // b00 = 5
        @(posedge clk);
        if ((psum !== 66'd15) || (a_out !== 32'd3) || (b_out !== 32'd5)) begin
            $display("Error: expected psum = 15, a_out = 3, b_out = 5, got psum = %0d, a_out = %0d, b_out = %0d", psum, a_out, b_out);
            errors++;
        end
        else $display("Correct: a_in: %0d, b_in: %0d, psum: %0d", a_in, b_in, psum);

        a_in = 32'd4;           // a01 = 4
        b_in = 32'd6;           // b10 = 6
        @(posedge clk);
        if ((psum !== 66'd39) || (a_out !== 32'd4) || (b_out !== 32'd6)) begin
            $display("Error: expected psum = 39, a_out = 4, b_out = 6, got psum = %0d, a_out = %0d, b_out = %0d", psum, a_out, b_out);
            errors++;
        end
        else $display("Correct: a_in: %0d, b_in: %0d, psum: %0d", a_in, b_in, psum);

        clear = 1'b1;
        @(posedge clk);
        clear = 1'b0;
        if ((psum !== 66'd0) || (a_out !== 32'd4) || (b_out !== 32'd6)) begin
            $display("Error: After clear, expected psum = 0, a_out = 4, b_out = 6, got psum = %0d, a_out = %0d, b_out = %0d", psum, a_out, b_out);
            errors++;
        end
        else $display("Correct after clear: psum: %0d, a_out: %0d, b_out: %0d", psum, a_out, b_out);

        a_in = 32'd1234;
        b_in = 32'd0;
        @(posedge clk);
        if ((psum !== 66'd0) || (a_out !== 32'd1234) || (b_out !== 32'd0)) begin
            $display("Error: expected psum = 0, a_out = 1234, b_out = 0, got psum = %0d, a_out = %0d, b_out = %0d", psum, a_out, b_out);
            errors++;
        end
        else $display("Correct: psum: %0d, a_out: %0d, b_out: %0d", psum, a_out, b_out);

        a_in = 32'hffffffff;
        b_in = 32'hffffffff;
        @(posedge clk);
        if ((psum !== 66'hFFFFFFFE00000001) || (a_out !== 32'hffffffff) || (b_out !== 32'hffffffff)) begin
            $display("Error: expected psum = hFFFFFFFE00000001, a_out = hffffffff, b_out = hffffffff, got psum = %0h, a_out = %0h, b_out = %0h", psum, a_out, b_out);
            errors++;
        end
        else $display("Correct: a_in: %0h, b_in: %0h, psum: %0h", a_in, b_in, psum);

        if (errors == 0)
            $display("All tests passed!");
        else
            $display("%0d errors found.", errors);

        $finish;
    end

endmodule
