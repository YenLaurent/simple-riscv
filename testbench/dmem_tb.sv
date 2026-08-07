`timescale 1ns / 1ps

module dmem_tb;

    logic clk = 1'b0;
    logic [31:0] addr;            // 字节地址
    logic [31:0] wdata;           // 写数据，来自LSU
    logic [3:0] byte_en;          // 字节使能，来自LSU
    logic mem_read;               // 读使能
    logic mem_write;              // 写使能
    logic [31:0] rdata;           // 读取数据，输出给LSU

    integer errors = 0;

    dmem u_dmem(
        .clk       (clk       ),
        .addr      (addr      ),
        .wdata     (wdata     ),
        .byte_en   (byte_en   ),
        .mem_read  (mem_read  ),
        .mem_write (mem_write ),
        .rdata     (rdata     )
    );

    task check (input logic [31:0] exp_rdata);
        @(negedge clk);
        if (rdata !== exp_rdata) begin
            errors++;
            $display("FAIL [%0d]: rdata=0x%08h | exp=0x%08h",
                     errors, rdata, exp_rdata);
        end 
        else
            $display("OK: rdata=0x%08h | exp=0x%08h",
                     rdata, exp_rdata);
    endtask

    always #5 clk <= ~clk;

    initial begin
        $dumpfile("build/sim/dmem_tb.vcd");
        $dumpvars(0, dmem_tb);

        // Read from address 0x0000_0000
        addr = 32'h0000_0004;
        mem_read = 1'b1;
        mem_write = 1'b0;
        check(32'h0000_0000);

        // SW
        addr = 32'h0000_0100;
        wdata = 32'hDEADBEEF;
        byte_en = 4'b1111;
        mem_read = 1'b0;
        mem_write = 1'b1;
        repeat(2) @(posedge clk);
        mem_read = 1'b1;
        mem_write = 1'b0;
        check(32'hDEADBEEF);

        // SB
        addr = 32'h0000_0200;
        wdata = 32'h00000000;
        byte_en = 4'b1111;
        mem_read = 1'b0;
        mem_write = 1'b1;
        repeat(2) @(posedge clk);
        wdata = 32'hCCDDAAFF;
        byte_en = 4'b0001;
        repeat(2) @(posedge clk);
        mem_read = 1'b1;
        mem_write = 1'b0;
        check(32'h000000FF);
        mem_read = 1'b0;
        mem_write = 1'b1;
        wdata = 32'hCCDDAAFF;
        byte_en = 4'b0010;
        repeat(2) @(posedge clk);
        mem_read = 1'b1;
        mem_write = 1'b0;
        check(32'h0000AAFF);
        
        // mem_read = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b1;
        check(32'h00000000);

        // 
        addr = 32'h0000_0100;
        mem_read = 1'b1;
        mem_write = 1'b0;
        check(32'hDEADBEEF);
        addr = 32'h0000_0200;
        mem_read = 1'b1;
        mem_write = 1'b0;
        check(32'h0000AAFF);

        if (errors == 0)
            $display("All tests passed!");
        else
            $display("%0d tests failed.", errors);

        $finish;
    end
    

endmodule
