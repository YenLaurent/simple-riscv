`timescale 1ns / 1ps

module imm_gen_tb;

    logic [31:0] instr;
    logic [31:0] imm;

    imm_gen u_imm_gen(
        .instr (instr ),
        .imm   (imm   )
    );
    
    initial begin
        $dumpfile("build/sim/imm_gen_tb.vcd");
        $dumpvars(0, imm_gen_tb);

        instr[6:0] = 7'b0010011;
        instr[31:20] = 12'd42;
        #10
        $display("I type instruction: %b, Immediate: %0d", instr, imm);

        instr[6:0] = 7'b0010011;
        instr[31:20] = -12'd1;
        #10
        $display("I type instruction: %b, Immediate: %h", instr, imm);

        instr[6:0] = 7'b0100011;
        instr[31:25] = 7'b000_1111;
        instr[11:7] = 5'b10101;
        #10
        $display("S type instruction: %b, Immediate: %h", instr, imm);

        instr[6:0] = 7'b1100011;
        instr[31:25] = 7'b1111111;
        instr[11:7] = 5'b11001;
        #10
        $display("B type instruction: %b, Immediate: %h (expected imm is -8)", instr, imm);

        instr[6:0] = 7'b0110111;
        instr[31:12] = 20'h12345;
        #10
        $display("U type instruction: %b, Immediate: %h", instr, imm);

        instr[6:0] = 7'b1101111;
        instr[31:12] = 20'h00c00;
        #10
        $display("J type instruction: %b, Immediate: %0d (expected imm is 12)", instr, imm);

        #50
        $finish;
    end

endmodule
