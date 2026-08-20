`timescale 1ns / 1ps

module accelerator_top_tb;

    parameter DATA_WIDTH = 32;
    parameter ACC_WIDTH = 2 * DATA_WIDTH + 2;
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
        .ACC_WIDTH  (ACC_WIDTH  )
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

        //* Round 1
        // Write matrix A and B to the accelerator
        mem_write = 1'b1; mem_read = 1'b0;
        addr = 32'h300; wdata = 32'd1; @(posedge clk);
        addr = 32'h304; wdata = 32'd2; @(posedge clk);
        addr = 32'h308; wdata = 32'd3; @(posedge clk);
        addr = 32'h30c; wdata = 32'd4; @(posedge clk);
        addr = 32'h310; wdata = 32'd5; @(posedge clk);
        addr = 32'h314; wdata = 32'd6; @(posedge clk);
        addr = 32'h318; wdata = 32'd7; @(posedge clk);
        addr = 32'h31c; wdata = 32'd8; @(posedge clk);

        // LW
        mem_write = 1'b0; mem_read = 1'b1;
        addr = 32'h300;
        @(negedge clk);
        if (rdata !== 32'd1) begin
            $display("Error: Reading 0x300, expected 1, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x300, got 1");
        @(posedge clk);

        addr = 32'h314;
        @(negedge clk);
        if (rdata !== 32'd6) begin
            $display("Error: Reading 0x314, expected 6, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x314, got 6");
        @(posedge clk);

        // Start the accelerator
        mem_write = 1'b1; mem_read = 1'b0;
        addr = 32'h320; wdata = 32'd1; @(posedge clk);
        
        // 循环检测done
        mem_write = 1'b0; mem_read = 1'b1;
        addr = 32'h320;
        timeout = 0;
        
        do begin
            @(posedge clk);
            timeout = timeout + 1;
        end while (rdata[0] !== 1'b1 && timeout < 100);

        if (timeout >= 100) begin
            $display("ERROR: done 超时！");
            errors = errors + 1;
        end

        @(posedge clk);
        if (rdata[0] === 1'b1) begin
            $display("Error: done signal not reset, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: done signal reset, got %0d", rdata);

        // Read the results from the accelerator
        addr = 32'h324; // C00
        @(negedge clk);
        if (rdata !== 32'd19) begin
            $display("Error: Reading 0x324, expected 19, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x324, got 19");

        addr = 32'h328; // C01
        @(negedge clk);
        if (rdata !== 32'd22) begin
            $display("Error: Reading 0x328, expected 22, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x328, got 22");

        addr = 32'h32c; // C10
        @(negedge clk);
        if (rdata !== 32'd43) begin
            $display("Error: Reading 0x32c, expected 43, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x32c, got 43");

        addr = 32'h330; // C11
        @(negedge clk);
        if (rdata !== 32'd50) begin
            $display("Error: Reading 0x330, expected 50, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x330, got 50");

        @(posedge clk);

        //* Round 2
        // Write matrix A and B to the accelerator
        mem_write = 1'b1; mem_read = 1'b0;
        addr = 32'h300; wdata = 32'd2; @(posedge clk);
        addr = 32'h304; wdata = 32'd2; @(posedge clk);
        addr = 32'h308; wdata = 32'd3; @(posedge clk);
        addr = 32'h30c; wdata = 32'd3; @(posedge clk);
        addr = 32'h310; wdata = 32'd1; @(posedge clk);
        addr = 32'h314; wdata = 32'd1; @(posedge clk);
        addr = 32'h318; wdata = 32'd1; @(posedge clk);
        addr = 32'h31c; wdata = 32'd1; @(posedge clk);

        // LW
        mem_write = 1'b0; mem_read = 1'b1;
        addr = 32'h300;
        @(negedge clk);
        if (rdata !== 32'd2) begin
            $display("Error: Reading 0x300, expected 2, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x300, got 2");
        @(posedge clk);

        addr = 32'h314;
        @(negedge clk);
        if (rdata !== 32'd1) begin
            $display("Error: Reading 0x314, expected 1, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x314, got 1");
        @(posedge clk);

        // Start the accelerator
        mem_write = 1'b1; mem_read = 1'b0;
        addr = 32'h320; wdata = 32'd1; @(posedge clk);
        
        // Feed期间读取输出，理应寄存旧输出值
        mem_write = 1'b0; mem_read = 1'b1;
        addr = 32'h324; // C00
        @(negedge clk);
        if (rdata !== 32'd19) begin
            $display("Error: Reading 0x324, expected 19, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x324, got 19");

        // 循环检测done
        mem_write = 1'b0; mem_read = 1'b1;
        addr = 32'h320;
        timeout = 0;

        do begin
            @(posedge clk);
            timeout = timeout + 1;
        end while (rdata[0] !== 1'b1 && timeout < 100);

        if (timeout >= 100) begin
            $display("ERROR: done 超时！");
            errors = errors + 1;
        end

        @(posedge clk);
        if (rdata[0] === 1'b1) begin
            $display("Error: done signal not reset, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: done signal reset, got %0d", rdata);

        @(posedge clk);
        // Read the results from the accelerator
        addr = 32'h324; // C00
        @(negedge clk);
        if (rdata !== 32'd4) begin
            $display("Error: Reading 0x324, expected 4, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x324, got 4");

        addr = 32'h328; // C01
        @(negedge clk);
        if (rdata !== 32'd4) begin
            $display("Error: Reading 0x328, expected 4, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x328, got 4");

        addr = 32'h32c; // C10
        @(negedge clk);
        if (rdata !== 32'd6) begin
            $display("Error: Reading 0x32c, expected 6, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x32c, got 6");

        addr = 32'h330; // C11
        @(negedge clk);
        if (rdata !== 32'd6) begin
            $display("Error: Reading 0x330, expected 6, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x330, got 6");

        // 读地址范围外的数据
        addr = 32'h400;
        @(negedge clk);
        if (rdata !== 32'd0) begin
            $display("Error: Reading 0x400, expected 0, got %0d", rdata);
            errors = errors + 1;
        end
        else
            $display("Success: Reading 0x400, got 0");

        //* Summary
        if (errors == 0)
            $display("All tests passed!");
        else
            $display("Total errors: %0d", errors);

        repeat (20) @(posedge clk);
        $finish;
    end
endmodule
