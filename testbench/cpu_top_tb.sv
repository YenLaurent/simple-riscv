`timescale 1ns / 1ps

module cpu_top_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b1;

    cpu_top u_cpu_top(
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    always #10 clk <= ~clk;     // 50MHz

    initial begin
        $dumpfile("build/sim/cpu_top_tb.vcd");
        $dumpvars(0, cpu_top_tb);
        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (100) @(posedge clk);
        $finish;
    end
    
endmodule
