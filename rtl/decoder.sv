`timescale 1ns / 1ps
// Decoder of cpu

module decoder (
    input logic [31:0] instr,           // 完整32位指令字段
    output logic reg_write,             // 是否写入寄存器
    output logic alu_src,               // ALU的第二个操作数，0为寄存器，1为立即数
    output logic [3:0] alu_ctrl,        // ALU控制信号
    output logic mem_write,             // 是否写入内存（sw == 1）
    output logic mem_read,              // 是否读取内存（lw == 1）
    output logic branch,                // 是否为条件分支指令
    output logic jump,                  // 是否为无条件跳转
    output logic [1:0] wb_sel           // 写回寄存器的结果来源：2'b00 = ALU结果；2'b01 = 内存数据；2'b10 = PC + 4
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic funct7_5;

    logic [1:0] alu_op;             // ALU操作类型：2'b00 = ADD；2'b01 = B Type，根据funct3/funct7选择操作; 2'b10 = I Type，根据funct3/funct7选择操作；2'b11 = R Type，根据funct3/funct7选择操作

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7_5 = instr[30];

    always_comb begin: MainDecoder // 根据opcode输出控制信号与alu_op
        case (opcode)
            7'b0000011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b01;
                alu_op = 2'b00;
            end

            7'b0010011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b10;
            end

            7'b0010111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b00;
            end

            7'b0100011: begin
                reg_write = 1'b0;
                alu_src = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b1;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b00;
            end

            7'b0110011: begin
                reg_write = 1'b1;
                alu_src = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b11;
            end

            7'b0110111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b00;
            end

            7'b1100011: begin
                reg_write = 1'b0;
                alu_src = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b1;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b01;
            end

            7'b1100111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b1;
                wb_sel = 2'b10;
                alu_op = 2'b00;
            end

            7'b1101111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b1;
                wb_sel = 2'b10;
                alu_op = 2'b00;
            end

            default: begin
                reg_write = 1'b0;
                alu_src = 1'b0;
                mem_read = 1'b0;
                mem_write = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                wb_sel = 2'b00;
                alu_op = 2'b00;
            end
        endcase
    end

    always_comb begin: ALUDecoder // 根据alu_op与funct3/funct7输出alu_ctrl
        casez ({alu_op, funct3, funct7_5})
            6'b00????: alu_ctrl = 4'b0000;
            6'b01000?: alu_ctrl = 4'b0001;
            6'b01001?: alu_ctrl = 4'b0001;
            6'b01100?: alu_ctrl = 4'b1000;
            6'b01101?: alu_ctrl = 4'b1000;
            6'b01110?: alu_ctrl = 4'b1001;
            6'b01111?: alu_ctrl = 4'b1001;
            6'b10000?: alu_ctrl = 4'b0000;
            6'b100010: alu_ctrl = 4'b0101;
            6'b10010?: alu_ctrl = 4'b1000;
            6'b10011?: alu_ctrl = 4'b1001;
            6'b10100?: alu_ctrl = 4'b0100;
            6'b101010: alu_ctrl = 4'b0110;
            6'b101011: alu_ctrl = 4'b0111;
            6'b10110?: alu_ctrl = 4'b0011;
            6'b10111?: alu_ctrl = 4'b0010;
            6'b110000: alu_ctrl = 4'b0000;
            6'b110001: alu_ctrl = 4'b0001;
            6'b110010: alu_ctrl = 4'b0101;
            6'b110100: alu_ctrl = 4'b1000;
            6'b110110: alu_ctrl = 4'b1001;
            6'b111000: alu_ctrl = 4'b0100;
            6'b111010: alu_ctrl = 4'b0110;
            6'b111011: alu_ctrl = 4'b0111;
            6'b111100: alu_ctrl = 4'b0011;
            6'b111110: alu_ctrl = 4'b0010;
            default: alu_ctrl = 4'b0000;
        endcase
    end

endmodule
