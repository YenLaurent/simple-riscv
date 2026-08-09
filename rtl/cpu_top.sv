`timescale 1ns / 1ps
// CPU Top Module

module cpu_top (
    input logic clk,
    input logic rst_n,
    output logic [63:0] mcycle,
    output logic [63:0] minstret
);
    logic [31:0] pc;
    logic [31:0] next_pc;

    pc pc_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .next_pc    (next_pc),
        .pc_out     (pc)
    );

    logic [31:0] instr;

    imem #(
        .INSTR_NUM  (1024)
    ) imem_inst (
        .addr       (pc),
        .instr      (instr)
    );

    logic reg_write;
    logic alu_src;
    logic [3:0] alu_ctrl;
    logic mem_write;
    logic mem_read;
    logic branch;
    logic jump;
    logic [1:0] wb_sel;

    decoder decoder_inst (
        .instr     (instr),
        .reg_write (reg_write),
        .alu_src   (alu_src),
        .alu_ctrl  (alu_ctrl),
        .mem_write (mem_write),
        .mem_read  (mem_read),
        .branch    (branch),
        .jump      (jump),
        .wb_sel    (wb_sel)
    );

    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    reg_file reg_file_inst(
        .clk      (clk),
        .we       (reg_write),
        .rs1_addr (instr[19:15]),
        .rs2_addr (instr[24:20]),
        .rd_addr  (instr[11:7]),
        .rd_data  (rd_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    logic [31:0] alu_b;
    logic [31:0] alu_a;
    logic [31:0] imm;
    logic [31:0] alu_result;
    logic alu_zero;
    
    alu alu_inst(
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (alu_zero)
    );
    
    logic [31:0] dmem_rdata;
    logic [31:0] lsu_rdata_out;
    logic [31:0] lsu_wdata_out;
    logic [3:0] lsu_byte_en;

    lsu lsu_inst(
        .addr      (alu_result),
        .wdata     (rs2_data),
        .rdata     (dmem_rdata),
        .lsu_ctrl  (instr[14:12]),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .rdata_out (lsu_rdata_out),
        .wdata_out (lsu_wdata_out),
        .byte_en   (lsu_byte_en)
    );
    
    dmem #(
        .N      (1024)
    ) dmem_inst (
        .clk        (clk),
        .addr       (alu_result),
        .wdata      (lsu_wdata_out),
        .byte_en    (lsu_byte_en),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .rdata      (dmem_rdata)
    );

    imm_gen imm_gen_inst (
        .instr      (instr),
        .imm        (imm)
    );

    // MUX & Branch & Jump
    assign alu_b = (!alu_src) ? rs2_data : imm;             // ALU的第二个源操作数
    assign rd_data = (wb_sel == 2'b00) ? alu_result :       // 写回REG FILE的数据
                     (wb_sel == 2'b01) ? lsu_rdata_out :
                     (wb_sel == 2'b10) ? (pc + 4) : 32'b0;

    logic branch_en;
    logic [6:0] opcode;

    assign opcode = instr[6:0];

    assign branch_en = (instr[14:12] == 3'b000) ? alu_zero :
                       (instr[14:12] == 3'b001) ? !alu_zero :
                       (instr[14:12] == 3'b100) ? alu_result[0] :
                       (instr[14:12] == 3'b101) ? !alu_result[0] :
                       (instr[14:12] == 3'b110) ? alu_result[0] :
                       (instr[14:12] == 3'b111) ? !alu_result[0] : 1'b0;

    always_comb 
        if (jump)
            if (opcode == 7'b1100111) next_pc = alu_result & ~1;
            else next_pc = pc + imm;
        else if (branch)
            if (branch_en)  next_pc = pc + imm;
            else next_pc = pc + 4;
        else
            next_pc = pc + 4;

    assign alu_a = (opcode == 7'b0110111) ? 32'b0 :
                   (opcode == 7'b0010111) ? pc : rs1_data;

    // Cycle Counter
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            mcycle <= 64'b0;
        else
            mcycle <= mcycle + 64'd1;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            minstret <= 64'b0;
        else if (instr !== 32'b0)
            minstret <= minstret + 64'd1;

endmodule
