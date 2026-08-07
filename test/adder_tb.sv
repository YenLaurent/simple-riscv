`timescale 1ns / 1ps
// Testbench for adder.sv

module adder_tb;

    logic [3:0] a = 4'b0;
    logic [3:0] b = 4'b0;
    logic [4:0] sum;
    int count = 0;

    adder dut(
        .a  (a),
        .b  (b),
        .sum(sum)
    );

    initial begin
        $dumpfile("build/sim/adder_tb.vcd");
        $dumpvars(0, adder_tb);

        for (int i=0; i<16; i++)
            for (int j=0; j<16; j++) begin
                a = i[3:0];
                b = j[3:0];
                #10;
                if (sum !== ({1'b0, a} + {1'b0, b})) begin
                    $display("Test failed for a=%0d, b=%0d: expected sum=%0d, got sum=%0d", a, b, (a + b), sum);
                    count = count + 1;
                end
                else
                    $display("Test passed for a=%0d, b=%0d: sum=%0d", a, b, sum);
            end

        $display("Total test failures: %0d", count);

        $finish;
    end

endmodule
