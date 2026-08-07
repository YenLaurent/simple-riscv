`timescale 1ns / 1ps
// Data Memory

module dmem #(
    parameter N = 1024
)(
    input logic clk,
    input logic [31:0] addr,            // 字节地址
    input logic [31:0] wdata,           // 写数据，来自LSU
    input logic [3:0] byte_en,          // 字节使能，来自LSU
    input logic mem_read,               // 读使能
    input logic mem_write,              // 写使能
    output logic [31:0] rdata           // 读取数据，输出给LSU
);

    logic [31:0] mem [0:N-1];
    logic [31:0] write_data_masked;
    logic [31:0] addr_word;             // 字地址
    logic [31:0] mask;

    assign mask = {{8{byte_en[3]}}, {8{byte_en[2]}}, {8{byte_en[1]}}, {8{byte_en[0]}}};

    assign write_data_masked = (mask & wdata) | (~mask & mem[addr_word]);
    assign addr_word = addr >> 2;
    
    assign rdata = mem_read ? mem[addr_word] : 32'b0;

    always_ff @(posedge clk)
        if (mem_write)
            mem[addr_word] <= write_data_masked;

    initial     // 用于仿真初始化
        for (int i = 0; i < N; i++)
        mem[i] = 32'b0;

endmodule
