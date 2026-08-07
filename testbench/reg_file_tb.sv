`timescale 1ns / 1ps

module reg_file_tb;

    logic clk = 1'b0;
    logic we = 1'b0;
    logic [4:0] rs1_addr = 5'b0;
    logic [4:0] rs2_addr = 5'b0;
    logic [4:0] rd_addr = 5'b0;
    logic [31:0] rd_data = 32'b0;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    reg_file uut (
        .clk            (clk),
        .we             (we),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .rd_addr        (rd_addr),
        .rd_data        (rd_data),
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data)
    );

    always #5 clk <= ~clk;

    initial begin
        $dumpfile("build/sim/reg_file_tb.vcd");
        $dumpvars(0, reg_file_tb);
        // 测试读取
        rs1_addr = 5'b0;
        rs2_addr = 5'd4;
        #50;
        // 测试写入
        we = 1'b1;
        rd_addr = 5'b0;
        rd_data = 32'hffff_ffff;
        #50;
        rd_addr = 5'd4;
        rd_data = 32'hffff_eeee;
        #50;
        rs1_addr = 5'd4;
        rs2_addr = 5'd10;
        #50;
        $finish;
    end

endmodule
