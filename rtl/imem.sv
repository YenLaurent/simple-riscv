`timescale 1ns / 1ps
// Instruction Memory

module imem #(
    parameter INSTR_NUM = 1024
)(
    input logic [31:0] addr,    // 字节地址
    output logic [31:0] instr   // 指令
);

    logic [31:0] mem [0:INSTR_NUM-1];

    assign instr = mem[addr>>2];

    initial $readmemh ("build/sw/full_test.mem", mem);      // 用于仿真初始化

endmodule
