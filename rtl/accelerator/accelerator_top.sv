`timescale 1ns / 1ps
// 脉动阵列与CPU之间的接口模块，封装成内存
// 脉动阵列数据地址范围: 0x300 - 0x330
// 通过对0x320的位置写入1'b1来触发start信号，该地址在阵列计算完成后会被置位为done信号

module accelerator_top #(
    parameter DATA_WIDTH = 32,
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 2
)(
    input logic clk,
    input logic rst_n,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic mem_write,
    input logic mem_read,
    output logic [31:0] rdata
);
    //* Write data (sequential)
    // Two 2x2 matrix: A & B
    logic [DATA_WIDTH-1:0] A00;
    logic [DATA_WIDTH-1:0] A01;
    logic [DATA_WIDTH-1:0] A10;
    logic [DATA_WIDTH-1:0] A11;
    logic [DATA_WIDTH-1:0] B00;
    logic [DATA_WIDTH-1:0] B01;
    logic [DATA_WIDTH-1:0] B10;
    logic [DATA_WIDTH-1:0] B11;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            A00 <= 'b0;
            A01 <= 'b0;
            A10 <= 'b0;
            A11 <= 'b0;
            B00 <= 'b0;
            B01 <= 'b0;
            B10 <= 'b0;
            B11 <= 'b0;
        end
        else if (mem_write)
            case (addr)                 // 0x300 - 0x320 for systolic array
                32'h300: A00 <= wdata;
                32'h304: A01 <= wdata;
                32'h308: A10 <= wdata;
                32'h30c: A11 <= wdata;
                32'h310: B00 <= wdata;
                32'h314: B01 <= wdata;
                32'h318: B10 <= wdata;
                32'h31c: B11 <= wdata;
            endcase

    //* FSM for systolic array data & control signals
    localparam logic [2:0] IDLE = 3'd0, FEED0 = 3'd1, FEED1 = 3'd2,
                        FEED2 = 3'd3, FEED3 = 3'd4, DONE  = 3'd5;
    logic [2:0] current_state, next_state;

    logic start;
    assign start = mem_write && (addr == 32'h320) && wdata[0];
    //! 通过对0x320的位置写入1'b1来触发start信号

    // Outputs of FSM
    logic clear;
    logic done;
    logic [DATA_WIDTH-1:0] a_feed[1:0];
    logic [DATA_WIDTH-1:0] b_feed[1:0];

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;

    always_comb
        case (current_state)
            IDLE: next_state = start ? FEED0 : IDLE;
            FEED0: next_state = FEED1;
            FEED1: next_state = FEED2;
            FEED2: next_state = FEED3;
            FEED3: next_state = DONE;
            DONE: next_state = start ? FEED0 : IDLE;
            default: next_state = IDLE;
        endcase

    always_comb
        case (current_state)
            IDLE: begin
                clear = 1'b1;
                done = 1'b0;
                a_feed[0] = 'b0;
                a_feed[1] = 'b0;
                b_feed[0] = 'b0;
                b_feed[1] = 'b0;
            end

            FEED0: begin
                clear = 1'b0;
                done = 1'b0;
                a_feed[0] = A00;
                a_feed[1] = 'b0;
                b_feed[0] = B00;
                b_feed[1] = 'b0;
            end

            FEED1: begin
                clear = 1'b0;
                done = 1'b0;
                a_feed[0] = A01;
                a_feed[1] = A10;
                b_feed[0] = B10;
                b_feed[1] = B01;
            end

            FEED2: begin
                clear = 1'b0;
                done = 1'b0;
                a_feed[0] = 'b0;
                a_feed[1] = A11;
                b_feed[0] = 'b0;
                b_feed[1] = B11;
            end

            FEED3: begin
                clear = 1'b0;
                done = 1'b0;
                a_feed[0] = 'b0;
                a_feed[1] = 'b0;
                b_feed[0] = 'b0;
                b_feed[1] = 'b0;
            end

            DONE: begin
                clear = 1'b1;
                done = 1'b1;
                a_feed[0] = 'b0;
                a_feed[1] = 'b0;
                b_feed[0] = 'b0;
                b_feed[1] = 'b0;
            end

            default: begin
                clear = 1'b1;
                done = 1'b0;
                a_feed[0] = 'b0;
                a_feed[1] = 'b0;
                b_feed[0] = 'b0;
                b_feed[1] = 'b0;
            end
        endcase
    
    //* Read data (combinational)
    logic [ACC_WIDTH-1:0] c00_live, c00_snap;
    logic [ACC_WIDTH-1:0] c01_live, c01_snap;
    logic [ACC_WIDTH-1:0] c10_live, c10_snap;
    logic [ACC_WIDTH-1:0] c11_live, c11_snap;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            c00_snap <= 'b0;
            c01_snap <= 'b0;
            c10_snap <= 'b0;
            c11_snap <= 'b0;
        end
        else if (done) begin        // 单独将输出数据寄存，方便读取
            c00_snap <= c00_live;
            c01_snap <= c01_live;
            c10_snap <= c10_live;
            c11_snap <= c11_live;
        end

    logic [31:0] c00_lo, c01_lo, c10_lo, c11_lo;
    assign c00_lo = c00_snap[31:0];   // 预提取，绕开 iverilog 限制
    assign c01_lo = c01_snap[31:0];
    assign c10_lo = c10_snap[31:0];
    assign c11_lo = c11_snap[31:0];

    always_comb
        if (mem_read)
            case (addr)
                32'h300: rdata = A00;
                32'h304: rdata = A01;
                32'h308: rdata = A10;
                32'h30c: rdata = A11;
                32'h310: rdata = B00;
                32'h314: rdata = B01;
                32'h318: rdata = B10;
                32'h31c: rdata = B11;               // 输入的矩阵可回读
                32'h320: rdata = {31'b0, done};     // 计算完成标志，与写入触发start状态的地址相同
                32'h324: rdata = c00_lo;      // 输出截断至32位(仅供测试)
                32'h328: rdata = c01_lo;
                32'h32c: rdata = c10_lo;
                32'h330: rdata = c11_lo;
                default: rdata = 32'b0;
            endcase
        else 
            rdata = 32'b0;

    //* Instantiate systolic array
    systolic_2x2 
    #(
        .DATA_WIDTH (DATA_WIDTH ),
        .ACC_WIDTH  (ACC_WIDTH  )
    )
    u_systolic_2x2(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .clear (clear ),
        .a_in  (a_feed  ),
        .b_in  (b_feed  ),
        .c00   (c00_live   ),
        .c01   (c01_live   ),
        .c10   (c10_live   ),
        .c11   (c11_live   )
    );
    
endmodule
