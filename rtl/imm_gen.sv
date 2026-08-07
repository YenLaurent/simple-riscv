`timescale 1ns / 1ps
// Immediate Generator

module imm_gen (
    input logic [31:0] instr,   // 32-bit instruction
    output logic [31:0] imm
);
    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;

    logic [6:0] opcode;

    assign imm_i = 32'(signed'(instr[31:20]));
    assign imm_s = 32'(signed'({instr[31:25], instr[11:7]}));
    assign imm_b = 32'(signed'({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}));
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = 32'(signed'({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}));
    assign opcode = instr[6:0];

    always_comb
        case (opcode)
            7'b0000011, 7'b0010011, 7'b1100111:     imm = imm_i;
            7'b0100011:                             imm = imm_s;
            7'b1100011:                             imm = imm_b;
            7'b0110111, 7'b0010111:                 imm = imm_u;
            7'b1101111:                             imm = imm_j;
            default:                                imm = 32'b0;
        endcase

endmodule
