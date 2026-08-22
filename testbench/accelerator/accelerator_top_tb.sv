`timescale 1ns / 1ps

// 总线激励使用非阻塞赋值（<=）：保证 DUT 的 always_ff 在时钟沿采样到的是本拍值，
// 避免 TB 与 DUT 在 active region 的竞争（verilator 会误报 INITIALDLY，可忽略）

module accelerator_top_tb;

    parameter DATA_WIDTH = 32;
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 6;
    parameter K_MAX = 16;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic mem_write;
    logic mem_read;
    logic [31:0] rdata;

    integer errors = 0;
    integer timeout = 0;

    accelerator_top
    #(
        .DATA_WIDTH (DATA_WIDTH ),
        .ACC_WIDTH  (ACC_WIDTH  ),
        .K_MAX      (K_MAX)
    )
    u_accelerator_top(
        .clk       (clk       ),
        .rst_n     (rst_n     ),
        .addr      (addr      ),
        .wdata     (wdata     ),
        .mem_write (mem_write ),
        .mem_read  (mem_read  ),
        .rdata     (rdata     )
    );


    always #5 clk <= ~clk;

    initial begin
        $dumpfile("build/sim/accelerator_top_tb.vcd");
        $dumpvars(0, accelerator_top_tb);

        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        //* Round 1: K=2（不写K，用复位默认值2）
        mem_write <= 1'b1; mem_read <= 1'b0;
        addr <= 32'h300; wdata <= 32'd1; @(posedge clk);   // a00
        addr <= 32'h304; wdata <= 32'd2; @(posedge clk);   // a01
        addr <= 32'h340; wdata <= 32'd3; @(posedge clk);   // a10
        addr <= 32'h344; wdata <= 32'd4; @(posedge clk);   // a11
        addr <= 32'h380; wdata <= 32'd5; @(posedge clk);   // b00
        addr <= 32'h384; wdata <= 32'd7; @(posedge clk);   // b10
        addr <= 32'h3c0; wdata <= 32'd6; @(posedge clk);   // b01
        addr <= 32'h3c4; wdata <= 32'd8; @(posedge clk);   // b11

        // LW
        mem_write <= 1'b0; mem_read <= 1'b1;
        addr <= 32'h300;
        @(negedge clk);
        if (rdata !== 32'd1) begin
            $display("Error: Reading 0x300, expected 1, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x300, got 1");
        @(posedge clk);

        addr <= 32'h340;
        @(negedge clk);
        if (rdata !== 32'd3) begin
            $display("Error: Reading 0x340, expected 3, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x340, got 3");
        @(posedge clk);

        // Start the accelerator
        mem_write <= 1'b1; mem_read <= 1'b0;
        addr <= 32'h400; wdata <= 32'd1; @(posedge clk);

        // 循环检测done
        mem_write <= 1'b0; mem_read <= 1'b1;
        addr <= 32'h400;
        timeout = 0;

        do begin
            @(posedge clk);
            timeout = timeout + 1;
        end while (rdata[0] !== 1'b1 && timeout < 100);

        // Read the results from the accelerator
        addr <= 32'h408; // C00_LO
        @(negedge clk);
        if (rdata !== 32'd19) begin
            $display("Error: Reading 0x408, expected 19, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x408, got 19");

        addr <= 32'h40c; // C00_HI
        @(negedge clk);
        if (rdata !== 32'd0) begin
            $display("Error: Reading 0x40c, expected 0, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x40c, got 0");

        addr <= 32'h410; // C01_LO
        @(negedge clk);
        if (rdata !== 32'd22) begin
            $display("Error: Reading 0x410, expected 22, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x410, got 22");

        addr <= 32'h418; // C10_LO
        @(negedge clk);
        if (rdata !== 32'd43) begin
            $display("Error: Reading 0x418, expected 43, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x418, got 43");

        addr <= 32'h420; // C11_LO
        @(negedge clk);
        if (rdata !== 32'd50) begin
            $display("Error: Reading 0x420, expected 50, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x420, got 50");

        @(posedge clk);

        //* Round 2: K=3
        mem_write <= 1'b1; mem_read <= 1'b0;
        addr <= 32'h404; wdata <= 32'd3; @(posedge clk);   // K = 3
        addr <= 32'h300; wdata <= 32'd1; @(posedge clk);   // a00
        addr <= 32'h304; wdata <= 32'd2; @(posedge clk);   // a01
        addr <= 32'h308; wdata <= 32'd3; @(posedge clk);   // a02
        addr <= 32'h340; wdata <= 32'd4; @(posedge clk);   // a10
        addr <= 32'h344; wdata <= 32'd5; @(posedge clk);   // a11
        addr <= 32'h348; wdata <= 32'd6; @(posedge clk);   // a12
        addr <= 32'h380; wdata <= 32'd1; @(posedge clk);   // b00
        addr <= 32'h384; wdata <= 32'd3; @(posedge clk);   // b10
        addr <= 32'h388; wdata <= 32'd5; @(posedge clk);   // b20
        addr <= 32'h3c0; wdata <= 32'd2; @(posedge clk);   // b01
        addr <= 32'h3c4; wdata <= 32'd4; @(posedge clk);   // b11
        addr <= 32'h3c8; wdata <= 32'd6; @(posedge clk);   // b21

        // K 回读
        mem_write <= 1'b0; mem_read <= 1'b1;
        addr <= 32'h404;
        @(negedge clk);
        if (rdata !== 32'd3) begin
            $display("Error: Reading 0x404, expected 3, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x404, got 3");

        // Start
        mem_write <= 1'b1; mem_read <= 1'b0;
        addr <= 32'h400; wdata <= 32'd1; @(posedge clk);

        // Feed期间读取快照，理应还是Round 1的结果
        mem_write <= 1'b0; mem_read <= 1'b1;
        addr <= 32'h408;
        @(negedge clk);
        if (rdata !== 32'd19) begin
            $display("Error: Snapshot, expected 19, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Snapshot 19");

        // 循环检测done
        addr <= 32'h400;
        timeout = 0;

        do begin
            @(posedge clk);
            timeout = timeout + 1;
        end while (rdata[0] !== 1'b1 && timeout < 100);

        @(posedge clk);
        // 期望 22/28/49/64
        addr <= 32'h408;
        @(negedge clk);
        if (rdata !== 32'd22) begin
            $display("Error: Reading 0x408, expected 22, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x408, got 22");

        addr <= 32'h410;
        @(negedge clk);
        if (rdata !== 32'd28) begin
            $display("Error: Reading 0x410, expected 28, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x410, got 28");

        addr <= 32'h418;
        @(negedge clk);
        if (rdata !== 32'd49) begin
            $display("Error: Reading 0x418, expected 49, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x418, got 49");

        addr <= 32'h420;
        @(negedge clk);
        if (rdata !== 32'd64) begin
            $display("Error: Reading 0x420, expected 64, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x420, got 64");

        //* Round 3: 64位溢出测试，K=2
        mem_write <= 1'b1; mem_read <= 1'b0;
        addr <= 32'h404; wdata <= 32'd2; @(posedge clk);       // K = 2
        addr <= 32'h300; wdata <= 32'h10000; @(posedge clk);   // a00
        addr <= 32'h304; wdata <= 32'h10000; @(posedge clk);   // a01
        addr <= 32'h340; wdata <= 32'd0; @(posedge clk);       // a10
        addr <= 32'h344; wdata <= 32'd0; @(posedge clk);       // a11
        addr <= 32'h380; wdata <= 32'h10000; @(posedge clk);   // b00
        addr <= 32'h384; wdata <= 32'h10000; @(posedge clk);   // b10
        addr <= 32'h3c0; wdata <= 32'd0; @(posedge clk);       // b01
        addr <= 32'h3c4; wdata <= 32'd0; @(posedge clk);       // b11
        addr <= 32'h400; wdata <= 32'd1; @(posedge clk);       // START

        mem_write <= 1'b0; mem_read <= 1'b1;
        addr <= 32'h400;
        timeout = 0;

        do begin
            @(posedge clk);
            timeout = timeout + 1;
        end while (rdata[0] !== 1'b1 && timeout < 100);

        @(posedge clk);
        // c00 = 2 * 2^32 = 0x2_00000000: LO=0, HI=2
        addr <= 32'h408;
        @(negedge clk);
        if (rdata !== 32'd0) begin
            $display("Error: Reading 0x408, expected 0, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x408, got 0");

        addr <= 32'h40c;
        @(negedge clk);
        if (rdata !== 32'd2) begin
            $display("Error: Reading 0x40c, expected 2, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x40c, got 2");

        // 读地址范围外的数据
        addr <= 32'h500;
        @(negedge clk);
        if (rdata !== 32'd0) begin
            $display("Error: Reading 0x500, expected 0, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x500, got 0");

        //* Summary
        if (errors == 0)
            $display("All tests passed!");
        else
            $display("Total errors: %0d", errors);

        repeat (20) @(posedge clk);
        $finish;
    end
endmodule
