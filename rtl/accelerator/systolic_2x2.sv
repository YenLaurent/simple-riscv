`timescale 1ns / 1ps
// 2x2 Systolic Array (Output Stationary)

module systolic_2x2 #(
    parameter DATA_WIDTH = 32,
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 2
)(
    input logic clk,
    input logic rst_n,
    input logic clear,
    input logic [DATA_WIDTH-1:0] a_in[1:0],
    input logic [DATA_WIDTH-1:0] b_in[1:0],
    output logic [ACC_WIDTH-1:0] c00, c01, c10, c11
);
    
    logic [DATA_WIDTH-1:0] a_out[1:0];
    logic [DATA_WIDTH-1:0] b_out[1:0];

    // Instantiate 4 PEs
    pe #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ACC_WIDTH          (ACC_WIDTH)
    ) pe00 (
        .clk                (clk),
        .rst_n              (rst_n),
        .clear              (clear),
        .a_in               (a_in[0]),
        .b_in               (b_in[0]),
        .a_out              (a_out[0]),
        .b_out              (b_out[0]),
        .psum               (c00)
    );

    pe #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ACC_WIDTH          (ACC_WIDTH)
    ) pe01 (
        .clk                (clk),
        .rst_n              (rst_n),
        .clear              (clear),
        .a_in               (a_out[0]),
        .b_in               (b_in[1]),
        .a_out              (),
        .b_out              (b_out[1]),
        .psum               (c01)
    );

    pe #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ACC_WIDTH          (ACC_WIDTH)
    ) pe10 (
        .clk                (clk),
        .rst_n              (rst_n),
        .clear              (clear),
        .a_in               (a_in[1]),
        .b_in               (b_out[0]),
        .a_out              (a_out[1]),
        .b_out              (),
        .psum               (c10)
    );

    pe #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ACC_WIDTH          (ACC_WIDTH)
    ) pe11 (
        .clk                (clk),
        .rst_n              (rst_n),
        .clear              (clear),
        .a_in               (a_out[1]),
        .b_in               (b_out[1]),
        .a_out              (),
        .b_out              (),
        .psum               (c11)
    );

endmodule
