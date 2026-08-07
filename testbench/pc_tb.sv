`timescale 1ns / 1ps

module pc_tb;

    logic clk = 1'b0;
    logic rst_n = 1'b1;
    logic [31:0] pc_out;                // 输出端不赋初值
    logic [31:0] next_pc = 32'd0;

    pc u_pc(
        .clk     (clk),
        .rst_n   (rst_n),
        .next_pc (next_pc),
        .pc_out  (pc_out)
    );


    always #10 clk <= !clk;

    initial begin
        $dumpfile("build/sim/pc_tb.vcd");
        $dumpvars(0, pc_tb);

        rst_n = 1'b0;
        repeat (20) @(posedge clk);
        rst_n = 1'b1;
        repeat (20) @(posedge clk);
        
        next_pc = next_pc + 'd4;
        repeat(5) @(posedge clk);
        next_pc = next_pc + 'd4;
        repeat(5) @(posedge clk);
        next_pc = next_pc + 'd4;
        repeat(5) @(posedge clk);
        next_pc = next_pc + 'd4;
        repeat(5) @(posedge clk);
        next_pc = next_pc + 'd4;
        repeat(30) @(posedge clk);

        $finish;
    end

endmodule
