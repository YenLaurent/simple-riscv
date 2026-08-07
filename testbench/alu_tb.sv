`timescale 1ns / 1ps

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0] alu_ctrl;
    logic [31:0] result;
    logic zero;

    alu u_alu(
        .a        (a        ),
        .b        (b        ),
        .alu_ctrl (alu_ctrl ),
        .result   (result   ),
        .zero     (zero     )
    );

    initial begin
        $dumpfile("build/sim/alu_tb.vcd");
        $dumpvars(0, alu_tb);
        #50;

        alu_ctrl = 4'b0000; // Addition
        a = 32'd10;
        b = 32'd5;
        #10;
        $display("Addition: %0d + %0d = %0d", a, b, result);
        #50;

        alu_ctrl = 4'b0001; // Subtraction
        a = 32'd3;
        b = 32'd10;
        #10;
        $display("Subtraction: %0d - %0d = %0d", a, b, result);
        #50;

        alu_ctrl = 4'b0001; // Subtraction
        a = 32'd3;
        b = 32'd3;
        #10;
        $display("Subtraction: %0d - %0d = %0d | Zero: %b", a, b, result, zero);
        #50;

        alu_ctrl = 4'b0010; // Bitwise AND
        a = 32'b1100;
        b = 32'b1010;
        #10;
        $display("Bitwise AND: %b & %b = %b", a, b, result);
        #50;

        alu_ctrl = 4'b0011; // Bitwise OR
        a = 32'b1100;
        b = 32'b1001;
        #10;
        $display("Bitwise OR: %b | %b = %b", a, b, result);
        #50;

        alu_ctrl = 4'b0100; // Bitwise XOR
        a = 32'b1100;
        b = 32'b0010;
        #10;
        $display("Bitwise XOR: %b ^ %b = %b", a, b, result);
        #50;

        alu_ctrl = 4'b0101; // Shift left
        a = 32'b0001;
        b = 32'd2;
        #10;
        $display("Shift left: %b << %0d = %b", a, b, result);
        #50;

        alu_ctrl = 4'b0110; // Shift right
        a = 32'hffff_1000;
        b = 32'd3;
        #10;
        $display("Shift right: %b >> %0d = %b", a, b, result);
        #50;

        alu_ctrl = 4'b0111; // Arithmetic shift right
        a = 32'hffff_fffe;  // -2 in 32-bit signed
        b = 32'd2;
        #10;
        $display("Arithmetic shift right: %b >>> %0d = %b", a, b, result);
        #50;

        alu_ctrl = 4'b1000; // Set on less than (signed)
        a = 32'd5;
        b = 32'hffff_fffa;  // -6 in 32-bit signed
        #10;
        $display("Set on less than (signed): %0d < %0d = %b", a, b, result);
        #50;

        alu_ctrl = 4'b1001; // Set on less than (unsigned)
        a = 32'd5;
        b = 32'd6;
        #10;
        $display("Set on less than (unsigned): %0d < %0d = %b", a, b, result);
        #50;
    end


endmodule
