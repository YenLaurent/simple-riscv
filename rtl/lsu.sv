`timescale 1ns / 1ps
// Load Store Unit

module lsu (
    input logic [31:0] addr,        // Address for load/store operation
    input logic [31:0] wdata,       // Data to be written to memory
    input logic [31:0] rdata,       // Data read from memory
    input logic [2:0] lsu_ctrl,     // Control signals for load/store operations, equal to funct3
    input logic mem_read,           
    input logic mem_write,
    output logic [31:0] rdata_out,  // To Regfile
    output logic [31:0] wdata_out,  // To Data Memory
    output logic [3:0] byte_en      // 写入字节使能
);

    logic [4:0] ctrl;
    assign ctrl = {lsu_ctrl, addr[1:0]};

    logic [7:0]  b0;
    logic [7:0]  b1;
    logic [7:0]  b2;
    logic [7:0]  b3;
    logic [15:0] h0;
    logic [15:0] h1;
    logic [15:0] h2;
    assign b0 = rdata[7:0];
    assign b1 = rdata[15:8];
    assign b2 = rdata[23:16];
    assign b3 = rdata[31:24];
    assign h0 = rdata[15:0];
    assign h1 = rdata[23:8];
    assign h2 = rdata[31:16];

    always_comb
        if (mem_read)               // load情况
            casez (ctrl)
                5'b00000: rdata_out = 32'(signed'(b0));
                5'b00001: rdata_out = 32'(signed'(b1));
                5'b00010: rdata_out = 32'(signed'(b2));
                5'b00011: rdata_out = 32'(signed'(b3));   // lb
                5'b00100: rdata_out = 32'(signed'(h0));
                5'b00101: rdata_out = 32'(signed'(h1));
                5'b00110: rdata_out = 32'(signed'(h2));   // lh
                5'b010??: rdata_out = rdata;              // lw
                5'b10000: rdata_out = {24'b0, b0};
                5'b10001: rdata_out = {24'b0, b1};
                5'b10010: rdata_out = {24'b0, b2};
                5'b10011: rdata_out = {24'b0, b3};        // lbu
                5'b10100: rdata_out = {16'b0, h0};
                5'b10101: rdata_out = {16'b0, h1};
                5'b10110: rdata_out = {16'b0, h2};        // lhu
                default: rdata_out = 32'b0;
            endcase
        else
            rdata_out = 32'b0;


    always_comb
        if (mem_write)              // store情况
            casez (ctrl)
                5'b00000: byte_en = 4'b0001;
                5'b00001: byte_en = 4'b0010;
                5'b00010: byte_en = 4'b0100;
                5'b00011: byte_en = 4'b1000;                        // sb
                5'b00100: byte_en = 4'b0011;
                5'b00110: byte_en = 4'b1100;                        // sh
                5'b010??: byte_en = 4'b1111;                        // sw
                default: byte_en = 4'b0000;
            endcase
        else
            byte_en = 4'b0000;

    assign wdata_out = wdata << (8 * addr[1:0]);

endmodule
