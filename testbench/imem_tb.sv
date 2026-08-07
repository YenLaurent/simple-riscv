`timescale 1ns / 1ps

module imem_tb;

    logic [31:0] addr;
    logic [31:0] instr;

    imem imem_inst (
        .addr   (addr),
        .instr  (instr)
    );

    integer errors = 0;

    task check_instr(input logic [31:0] exp_instr);
        #10;
        if (instr !== exp_instr) begin
            errors++;
            $display("FAIL [%0d]: instr=0x%08h | exp=0x%08h",
                     errors, instr, exp_instr);
        end 
        else
            $display("OK: instr=0x%08h | exp=0x%08h",
                     instr, exp_instr);
    endtask

    initial begin
        $dumpfile("build/sim/imem_tb.vcd");
        $dumpvars(0, imem_tb);

        addr = 32'h0000_0000;
        check_instr(32'h02A00093);

        addr = 32'h0000_0004;
        check_instr(32'h401101B3);

        addr = 32'h0000_0008;
        check_instr(32'h00002203);

        addr = 32'h0000_000C;
        check_instr(32'hFE208CE3);

        if (errors == 0)
            $display("All tests passed!");
        else
            $display("%0d tests failed.", errors);
    end

endmodule
