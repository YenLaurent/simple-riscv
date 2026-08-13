`timescale 1ns / 1ps
// Output Stationaty Processing Engine (PE) Module

module pe #(
    parameter DATA_WIDTH = 32,
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 2
)(
    input logic clk,
    input logic rst_n,
    input logic clear,
    input logic [DATA_WIDTH-1:0] a_in,
    input logic [DATA_WIDTH-1:0] b_in,
    output logic [DATA_WIDTH-1:0] a_out,
    output logic [DATA_WIDTH-1:0] b_out,
    output logic [ACC_WIDTH-1:0] psum
);

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            psum <= '0;
            a_out <= '0;
            b_out <= '0;
        end
        else if (clear) begin
            psum <= '0;
            a_out <= a_in;
            b_out <= b_in;
        end
        else begin
            psum <= psum + a_in * b_in;
            a_out <= a_in;
            b_out <= b_in;
        end

endmodule;
