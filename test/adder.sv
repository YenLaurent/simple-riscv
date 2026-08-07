`timescale 1ns / 1ps
// 简单的4-bit加法器，验证环境是否正常

module adder (
    input logic [3:0] a,
    input logic [3:0] b,
    output logic [4:0] sum
);

    assign sum = a + b;

endmodule
