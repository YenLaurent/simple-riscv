`timescale 1ns / 1ps
// Program Counter

module pc (
    input logic clk,
    input logic rst_n,
    input logic [31:0] next_pc,
    output logic [31:0] pc_out
);

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            pc_out <= 32'b0;
        else
            pc_out <= next_pc;

endmodule
