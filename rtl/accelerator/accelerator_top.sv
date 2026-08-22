`timescale 1ns / 1ps
// 脉动阵列与CPU之间的接口模块，封装成内存
// 脉动阵列数据地址范围: 0x300 -（32'h324 + 16 * K_MAX）
// 通过对32'h300 + 16 * K_MAX的位置写入1'b1来触发start信号，该地址在阵列计算完成后会被置位为done信号
// 当前硬件已支持任意2xk * kx2维度的矩阵乘法，最大内积维度为K_MAX，输出数据被截断至64位

module accelerator_top #(
    parameter DATA_WIDTH = 32,
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 6,
    parameter K_MAX = 16                        // 支持2xK * Kx2矩阵乘法，K最大值为16
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
    logic [DATA_WIDTH-1:0] a_buf[0:2*K_MAX-1];  // 2xK matrix A, stored in row-major order, [0:K_MAX-1] for row 0, [K_MAX:2*K_MAX-1] for row 1
    logic [DATA_WIDTH-1:0] b_buf[0:2*K_MAX-1];  // Kx2 matrix B, stored in column-major order, [0:K_MAX-1] for column 0, [K_MAX:2*K_MAX-1] for column 1

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            for (int i = 0; i < 2*K_MAX; i++) begin
                a_buf[i] <= 'b0;
                b_buf[i] <= 'b0;
            end
            k <= 5'd2;
        end
        else if (mem_write)
            if ((addr >= 32'h300) && (addr < 32'h300 + 8 * K_MAX))
                a_buf[(addr - 32'h300) >> 2] <= wdata;                  // 写入A矩阵
            else if ((addr >= 32'h300 + 8 * K_MAX) && (addr < 32'h300 + 16 * K_MAX))
                b_buf[(addr - (32'h300 + 8 * K_MAX)) >> 2] <= wdata;    // 写入B矩阵
            else if (addr == 32'h304 + 16 * K_MAX)
                k <= (wdata[4:0] > K_MAX) ? K_MAX : wdata[4:0];    
                // K内积维度的写入：CPU需要在start之前写入K值，范围为1 - K_MAX

    //* FSM for systolic array data & control signals
    localparam logic [2:0] IDLE = 3'b100;
    localparam logic [2:0] FEED = 3'b010;
    localparam logic [2:0] DONE = 3'b001;
    logic [2:0] current_state, next_state;
    logic [7:0] t;                          // FEED状态计数器，0 - (K+1)
    logic [7:0] next_t;
    logic [4:0] k;                          // 实际的内积维度K值，1 - K_MAX，CPU需要在start之前写入

    logic start;
    assign start = mem_write && (addr == (32'h300 + 16 * K_MAX)) && wdata[0];
    //! 通过对32'h300 + 16 * K_MAX的位置写入1'b1来触发start信号

    // Outputs of FSM
    logic clear;
    logic done;
    logic [DATA_WIDTH-1:0] a_feed[1:0];
    logic [DATA_WIDTH-1:0] b_feed[1:0];

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            current_state <= IDLE;
            t <= 8'b0;
        end
        else begin
            current_state <= next_state;
            t <= next_t;
        end

    always_comb
        case (current_state)
            IDLE: begin
                next_t = 8'b0;
                next_state = start ? FEED : IDLE;
            end

            FEED: begin
                next_t = t + 8'd1;
                next_state = (t == (k + 'd1)) ? DONE : FEED;      // 喂数据要喂到k次，第k+1次时等待PE11计算结束
            end
            
            DONE: begin
                next_t = 8'd0;
                next_state = start ? FEED : IDLE;
            end

            default: begin
                next_state = IDLE;
                next_t = 8'd0;
            end
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

            FEED: begin
                clear = 1'b0;
                done = 1'b0;
                a_feed[0] = (t < k) ? a_buf[t] : 'b0;
                b_feed[0] = (t < k) ? b_buf[t] : 'b0;
                a_feed[1] = ((t >= 1) && (t < k+1)) ? a_buf[K_MAX + t - 1] : 'b0;
                b_feed[1] = ((t >= 1) && (t < k+1)) ? b_buf[K_MAX + t - 1] : 'b0;
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

    logic done_flag;   // 粘性完成标志：置位后保持，直到下一次 start

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            done_flag <= 1'b0;
        else if (start)
            done_flag <= 1'b0;              // 新一轮计算开始，标志复位
        else if (current_state == DONE)
            done_flag <= 1'b1;              // 计算完成，标志置位

    
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
        else if (done) begin                // 单独将输出数据寄存，方便读取
            c00_snap <= c00_live;
            c01_snap <= c01_live;
            c10_snap <= c10_live;
            c11_snap <= c11_live;
        end

    logic [31:0] c00_lo, c01_lo, c10_lo, c11_lo;
    assign c00_lo = c00_snap[31:0];             // 预提取，绕开 iverilog 限制
    assign c01_lo = c01_snap[31:0];
    assign c10_lo = c10_snap[31:0];
    assign c11_lo = c11_snap[31:0];

    logic [31:0] c00_hi, c01_hi, c10_hi, c11_hi;
    assign c00_hi = c00_snap[63:32];            // 预提取，绕开 iverilog 限制
    assign c01_hi = c01_snap[63:32];
    assign c10_hi = c10_snap[63:32];
    assign c11_hi = c11_snap[63:32];
    // 高于64位的部分舍弃

    always_comb
        if (mem_read)
            if ((addr >= 32'h300) && (addr < 32'h300 + 8 * K_MAX))
                rdata = a_buf[(addr - 32'h300) >> 2];
            else if ((addr >= 32'h300 + 8 * K_MAX) && (addr < 32'h300 + 16 * K_MAX))
                rdata = b_buf[(addr - (32'h300 + 8 * K_MAX)) >> 2];
            else if (addr == (32'h300 + 16 * K_MAX))
                rdata = {31'b0, done_flag};
            else if (addr == (32'h304 + 16 * K_MAX))
                rdata = {27'b0, k};                     // 设计内积维度可回读
            else if (addr == (32'h308 + 16 * K_MAX))
                rdata = c00_lo;
            else if (addr == (32'h30c + 16 * K_MAX))
                rdata = c00_hi;
            else if (addr == (32'h310 + 16 * K_MAX))
                rdata = c01_lo;
            else if (addr == (32'h314 + 16 * K_MAX))
                rdata = c01_hi;
            else if (addr == (32'h318 + 16 * K_MAX))
                rdata = c10_lo;
            else if (addr == (32'h31c + 16 * K_MAX))
                rdata = c10_hi;
            else if (addr == (32'h320 + 16 * K_MAX))
                rdata = c11_lo;
            else if (addr == (32'h324 + 16 * K_MAX))
                rdata = c11_hi;
            else
                rdata = 32'b0;
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
