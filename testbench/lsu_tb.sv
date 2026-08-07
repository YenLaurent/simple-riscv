`timescale 1ns / 1ps

module lsu_tb;

    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic [2:0]  lsu_ctrl;
    logic        mem_read;
    logic        mem_write;
    logic [31:0] rdata_out;
    logic [31:0] wdata_out;
    logic [3:0]  byte_en;

    lsu u_lsu (
        .addr      (addr),
        .wdata     (wdata),
        .rdata     (rdata),
        .lsu_ctrl  (lsu_ctrl),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .rdata_out (rdata_out),
        .wdata_out (wdata_out),
        .byte_en   (byte_en)
    );

    integer errors = 0;
    integer test_num = 0;

    task set_inputs(
        input logic        mr, mw,
        input logic [2:0]  ctrl,
        input logic [31:0] rd,
        input logic [31:0] wd,
        input logic [1:0]  a
    );
        mem_read  = mr;
        mem_write = mw;
        lsu_ctrl  = ctrl;
        rdata     = rd;
        wdata     = wd;
        addr      = {30'b0, a};
    endtask

    task check_load(
        input string       name,
        input logic [31:0] exp_rdata
    );
        #10; test_num++;
        if (rdata_out !== exp_rdata) begin
            $display("FAIL[%0d] %s: rdata_out=0x%08h exp=0x%08h",
                     test_num, name, rdata_out, exp_rdata);
            errors++;
        end else
            $display("OK  [%0d] %s", test_num, name);
    endtask

    task check_store(
        input string       name,
        input logic [31:0] exp_wdata,
        input logic [3:0]  exp_be
    );
        #10; test_num++;
        if (wdata_out !== exp_wdata || byte_en !== exp_be) begin
            $display("FAIL[%0d] %s: wdata_out=0x%08h exp=0x%08h  byte_en=%04b exp=%04b",
                     test_num, name, wdata_out, exp_wdata, byte_en, exp_be);
            errors++;
        end else
            $display("OK  [%0d] %s", test_num, name);
    endtask

    initial begin
        $dumpfile("build/sim/lsu_tb.vcd");
        $dumpvars(0, lsu_tb);

        // rdata = 0xAABBCCDD for load tests (4 distinct bytes)

        // lw
        set_inputs(1,0, 3'b010, 32'hAABBCCDD, 32'h0, 2'b00);
        check_load("lw",         32'hAABBCCDD);

        // lh — signed extend
        set_inputs(1,0, 3'b001, 32'hAABBCCDD, 32'h0, 2'b00);
        check_load("lh_00",      32'hFFFFCCDD);
        set_inputs(1,0, 3'b001, 32'hAABBCCDD, 32'h0, 2'b10);
        check_load("lh_10",      32'hFFFFAABB);

        // lhu — zero extend
        set_inputs(1,0, 3'b101, 32'hAABBCCDD, 32'h0, 2'b00);
        check_load("lhu_00",     32'h0000CCDD);
        set_inputs(1,0, 3'b101, 32'hAABBCCDD, 32'h0, 2'b10);
        check_load("lhu_10",     32'h0000AABB);

        // lb — signed extend
        set_inputs(1,0, 3'b000, 32'hAABBCCDD, 32'h0, 2'b00);
        check_load("lb_00",      32'hFFFFFFDD);
        set_inputs(1,0, 3'b000, 32'hAABBCCDD, 32'h0, 2'b01);
        check_load("lb_01",      32'hFFFFFFCC);
        set_inputs(1,0, 3'b000, 32'hAABBCCDD, 32'h0, 2'b10);
        check_load("lb_10",      32'hFFFFFFBB);
        set_inputs(1,0, 3'b000, 32'hAABBCCDD, 32'h0, 2'b11);
        check_load("lb_11",      32'hFFFFFFAA);

        // lbu — zero extend
        set_inputs(1,0, 3'b100, 32'hAABBCCDD, 32'h0, 2'b00);
        check_load("lbu_00",     32'h000000DD);
        set_inputs(1,0, 3'b100, 32'hAABBCCDD, 32'h0, 2'b01);
        check_load("lbu_01",     32'h000000CC);
        set_inputs(1,0, 3'b100, 32'hAABBCCDD, 32'h0, 2'b10);
        check_load("lbu_10",     32'h000000BB);
        set_inputs(1,0, 3'b100, 32'hAABBCCDD, 32'h0, 2'b11);
        check_load("lbu_11",     32'h000000AA);

        // lh misaligned (addr=01) — falls to default
        set_inputs(1,0, 3'b001, 32'hAABBCCDD, 32'h0, 2'b01);
        check_load("lh_misaligned", 32'hFFFFBBCC);

        // wdata = 0x12345678 for store tests
        // wdata_out = wdata << (8 * addr[1:0])

        // sw
        set_inputs(0,1, 3'b010, 32'h0, 32'h12345678, 2'b00);
        check_store("sw",        32'h12345678, 4'b1111);

        // sh
        set_inputs(0,1, 3'b001, 32'h0, 32'h12345678, 2'b00);
        check_store("sh_00",     32'h12345678, 4'b0011);
        set_inputs(0,1, 3'b001, 32'h0, 32'h12345678, 2'b10);
        check_store("sh_10",     32'h56780000, 4'b1100);

        // sb
        set_inputs(0,1, 3'b000, 32'h0, 32'h12345678, 2'b00);
        check_store("sb_00",     32'h12345678, 4'b0001);
        set_inputs(0,1, 3'b000, 32'h0, 32'h12345678, 2'b01);
        check_store("sb_01",     32'h34567800, 4'b0010);
        set_inputs(0,1, 3'b000, 32'h0, 32'h12345678, 2'b10);
        check_store("sb_10",     32'h56780000, 4'b0100);
        set_inputs(0,1, 3'b000, 32'h0, 32'h12345678, 2'b11);
        check_store("sb_11",     32'h78000000, 4'b1000);

        // sh misaligned (addr=01) — should not write
        set_inputs(0,1, 3'b001, 32'h0, 32'h12345678, 2'b01);
        check_store("sh_misaligned", 32'h34567800, 4'b0000);

        // no operation: mem_read=0, mem_write=0
        set_inputs(0,0, 3'b010, 32'hAABBCCDD, 32'h12345678, 2'b00);
        check_load("no_op",      32'h0);

        $display("==================================");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", test_num);
        else
            $display("%0d/%0d FAILED", errors, test_num);
        $display("==================================");
        $finish;
    end

endmodule
