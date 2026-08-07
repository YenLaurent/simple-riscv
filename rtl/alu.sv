`timescale 1ns / 1ps
// Arithmetic Logic Unit

module alu (
    input logic [31:0] a,           // First operand
    input logic [31:0] b,           // Second operand
    input logic [3:0] alu_ctrl,
    output logic [31:0] result,
    output logic zero
);

    logic [4:0] shift_amt;
    assign shift_amt = b[4:0];

    always_comb
        priority case (alu_ctrl)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << shift_amt;
            4'b0110: result = a >> shift_amt;
            4'b0111: result = signed'(a) >>> shift_amt;
            4'b1000: result = {31'b0, signed'(a) < signed'(b)};
            4'b1001: result = {31'b0, a < b};
            default: result = 32'b0; 
        endcase

    assign zero = (result == 32'b0);

endmodule
