`timescale 1ns / 1ps
// 32x32 Register File

module reg_file (
    input logic clk,
    input logic we,                 // Write enable
    input logic [4:0] rs1_addr,     // Source register 1 for reading
    input logic [4:0] rs2_addr,     // Source register 2 for reading
    input logic [4:0] rd_addr,      // Destination register
    input logic [31:0] rd_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] x [31:0];          // 前一个[31:0]定义位宽，后一个[31:0]定义元素个数

    // assign x[0] = 32'd0;

    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : x[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : x[rs2_addr];

    always_ff @(posedge clk)
        if (we && rd_addr != 5'b0)
            x[rd_addr] <= rd_data;

    initial     // 用于仿真初始化
        for (int i = 0; i < 32; i++)
            x[i] = 32'b0;

endmodule
