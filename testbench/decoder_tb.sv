`timescale 1ns / 1ps

module decoder_tb;
    logic [31:0] instr;
    logic reg_write;
    logic alu_src;
    logic [3:0] alu_ctrl;
    logic mem_write;
    logic mem_read;
    logic branch;
    logic jump;
    logic [1:0] wb_sel;

    decoder u_decoder(
        .instr     (instr     ),
        .reg_write (reg_write ),
        .alu_src   (alu_src   ),
        .alu_ctrl  (alu_ctrl  ),
        .mem_write (mem_write ),
        .mem_read  (mem_read  ),
        .branch    (branch    ),
        .jump      (jump      ),
        .wb_sel    (wb_sel    )
    );

    localparam OP_LOAD  = 7'b0000011;
    localparam OP_IALU  = 7'b0010011;
    localparam OP_AUIPC = 7'b0010111;
    localparam OP_STORE = 7'b0100011;
    localparam OP_RTYPE = 7'b0110011;
    localparam OP_LUI   = 7'b0110111;
    localparam OP_BRANCH= 7'b1100011;
    localparam OP_JALR  = 7'b1100111;
    localparam OP_JAL   = 7'b1101111;

    // {19'b0, funct7[6:0], rs2, rs1, funct3, rd, opcode}
    // instr[30] = funct7[5]

    function void set_instr(input [6:0] op, input [2:0] f3, input f7_5);
        instr = 32'b0;
        instr[6:0]   = op;
        instr[14:12] = f3;
        instr[30]    = f7_5;
    endfunction

    integer errors = 0;
    integer test_num = 0;

    task check(
        input string name,
        input logic exp_reg_w, exp_alu_s, exp_mem_r, exp_mem_w,
        input logic exp_branch, exp_jump,
        input logic [1:0] exp_wb_sel, input logic [3:0] exp_alu_c
    );
        #10;
        test_num++;
        if (reg_write !== exp_reg_w) begin
            $display("FAIL[%0d] %s: reg_write=%b exp=%b", test_num, name, reg_write, exp_reg_w); errors++;
        end
        if (alu_src !== exp_alu_s) begin
            $display("FAIL[%0d] %s: alu_src=%b exp=%b", test_num, name, alu_src, exp_alu_s); errors++;
        end
        if (mem_read !== exp_mem_r) begin
            $display("FAIL[%0d] %s: mem_read=%b exp=%b", test_num, name, mem_read, exp_mem_r); errors++;
        end
        if (mem_write !== exp_mem_w) begin
            $display("FAIL[%0d] %s: mem_write=%b exp=%b", test_num, name, mem_write, exp_mem_w); errors++;
        end
        if (branch !== exp_branch) begin
            $display("FAIL[%0d] %s: branch=%b exp=%b", test_num, name, branch, exp_branch); errors++;
        end
        if (jump !== exp_jump) begin
            $display("FAIL[%0d] %s: jump=%b exp=%b", test_num, name, jump, exp_jump); errors++;
        end
        if (wb_sel !== exp_wb_sel) begin
            $display("FAIL[%0d] %s: wb_sel=%b exp=%b", test_num, name, wb_sel, exp_wb_sel); errors++;
        end
        if (alu_ctrl !== exp_alu_c) begin
            $display("FAIL[%0d] %s: alu_ctrl=%b exp=%b", test_num, name, alu_ctrl, exp_alu_c); errors++;
        end
        if (errors == 0 || test_num == 1)
            $display("OK  [%0d] %s", test_num, name);
    endtask

    initial begin
        $dumpfile("build/sim/decoder_tb.vcd");
        $dumpvars(0, decoder_tb);

        // ===== Main Decoder: 9 opcodes =====
        set_instr(OP_LOAD,  3'b010, 0); check("lw",     1,1,1,0, 0,0, 2'b01, 4'b0000);
        set_instr(OP_IALU,  3'b000, 0); check("addi",   1,1,0,0, 0,0, 2'b00, 4'b0000);
        set_instr(OP_AUIPC, 3'b000, 0); check("auipc",  1,1,0,0, 0,0, 2'b00, 4'b0000);
        set_instr(OP_STORE, 3'b010, 0); check("sw",     0,1,0,1, 0,0, 2'b00, 4'b0000);
        set_instr(OP_RTYPE, 3'b000, 0); check("add",    1,0,0,0, 0,0, 2'b00, 4'b0000);
        set_instr(OP_LUI,   3'b000, 0); check("lui",    1,1,0,0, 0,0, 2'b00, 4'b0000);
        set_instr(OP_BRANCH,3'b000, 0); check("beq",    0,0,0,0, 1,0, 2'b00, 4'b0001);
        set_instr(OP_JALR,  3'b000, 0); check("jalr",   1,1,0,0, 0,1, 2'b10, 4'b0000);
        set_instr(OP_JAL,   3'b000, 0); check("jal",    1,1,0,0, 0,1, 2'b10, 4'b0000);

        // ===== Critical: addi vs sub (funct7[5]=1, funct3=000) =====
        set_instr(OP_IALU,  3'b000, 1); check("addi(f7=1)", 1,1,0,0, 0,0, 2'b00, 4'b0000);
        set_instr(OP_RTYPE, 3'b000, 1); check("sub",        1,0,0,0, 0,0, 2'b00, 4'b0001);

        // ===== B-type: all 6 funct3 =====
        set_instr(OP_BRANCH,3'b000, 0); check("beq",  0,0,0,0, 1,0, 2'b00, 4'b0001);
        set_instr(OP_BRANCH,3'b001, 0); check("bne",  0,0,0,0, 1,0, 2'b00, 4'b0001);
        set_instr(OP_BRANCH,3'b100, 0); check("blt",  0,0,0,0, 1,0, 2'b00, 4'b1000);
        set_instr(OP_BRANCH,3'b101, 0); check("bge",  0,0,0,0, 1,0, 2'b00, 4'b1000);
        set_instr(OP_BRANCH,3'b110, 0); check("bltu", 0,0,0,0, 1,0, 2'b00, 4'b1001);
        set_instr(OP_BRANCH,3'b111, 0); check("bgeu", 0,0,0,0, 1,0, 2'b00, 4'b1001);

        // ===== SRL vs SRA: both R-type and I-type =====
        set_instr(OP_IALU,  3'b101, 0); check("srli", 1,1,0,0, 0,0, 2'b00, 4'b0110);
        set_instr(OP_IALU,  3'b101, 1); check("srai", 1,1,0,0, 0,0, 2'b00, 4'b0111);
        set_instr(OP_RTYPE, 3'b101, 0); check("srl",  1,0,0,0, 0,0, 2'b00, 4'b0110);
        set_instr(OP_RTYPE, 3'b101, 1); check("sra",  1,0,0,0, 0,0, 2'b00, 4'b0111);

        // ===== All I-type ALU funct3 =====
        set_instr(OP_IALU, 3'b001, 0); check("slli",  1,1,0,0, 0,0, 2'b00, 4'b0101);
        set_instr(OP_IALU, 3'b010, 0); check("slti",  1,1,0,0, 0,0, 2'b00, 4'b1000);
        set_instr(OP_IALU, 3'b011, 0); check("sltiu", 1,1,0,0, 0,0, 2'b00, 4'b1001);
        set_instr(OP_IALU, 3'b100, 0); check("xori",  1,1,0,0, 0,0, 2'b00, 4'b0100);
        set_instr(OP_IALU, 3'b110, 0); check("ori",   1,1,0,0, 0,0, 2'b00, 4'b0011);
        set_instr(OP_IALU, 3'b111, 0); check("andi",  1,1,0,0, 0,0, 2'b00, 4'b0010);

        // ===== All R-type funct3 =====
        set_instr(OP_RTYPE, 3'b001, 0); check("sll",  1,0,0,0, 0,0, 2'b00, 4'b0101);
        set_instr(OP_RTYPE, 3'b010, 0); check("slt",  1,0,0,0, 0,0, 2'b00, 4'b1000);
        set_instr(OP_RTYPE, 3'b011, 0); check("sltu", 1,0,0,0, 0,0, 2'b00, 4'b1001);
        set_instr(OP_RTYPE, 3'b100, 0); check("xor",  1,0,0,0, 0,0, 2'b00, 4'b0100);
        set_instr(OP_RTYPE, 3'b110, 0); check("or",   1,0,0,0, 0,0, 2'b00, 4'b0011);
        set_instr(OP_RTYPE, 3'b111, 0); check("and",  1,0,0,0, 0,0, 2'b00, 4'b0010);

        // ===== Illegal =====
        set_instr(7'b1111111, 3'b000, 0); check("illegal", 0,0,0,0, 0,0, 2'b00, 4'b0000);

        // ===== Summary =====
        $display("==================================");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", test_num);
        else
            $display("%0d/%0d FAILED", errors, test_num);
        $display("==================================");
        $finish;
    end
    
endmodule
