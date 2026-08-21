`timescale 1ns / 1ps

module cpu_top_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b1;
    logic [63:0] mcycle;
    logic [63:0] minstret;

    cpu_top u_cpu_top(
        .clk        (clk   ),
        .rst_n      (rst_n ),
        .mcycle     (mcycle),
        .minstret   (minstret)
    );

    always #10 clk <= ~clk;     // 50MHz

    initial begin
        $dumpfile("build/sim/cpu_top_tb.vcd");
        $dumpvars(0, cpu_top_tb);
        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10000) @(posedge clk);
        $display("=== FINAL (window timeout) ===");
        $display("x1=%0h x3=%0h x20=%0h x30=%0h",
                u_cpu_top.reg_file_inst.x[1],
                u_cpu_top.reg_file_inst.x[3],
                u_cpu_top.reg_file_inst.x[20],
                u_cpu_top.reg_file_inst.x[30]);
        $display("Total mcycle: %0d | Total minstret: %0d",
                 mcycle,
                 minstret);
        $finish;
    end

    // 程序结束标记监测：程序向 0x2FC 写 0xC0DE 后立即结束仿真并打印测量结果
    always @(posedge clk)
        if (u_cpu_top.dmem_inst.mem_write && u_cpu_top.dmem_inst.addr == 32'h2fc) begin
            #1;   // 等 NBA 生效：mcycle/minstret/dmem 均为本拍最终值
            $display("=== DONE MARKER ===");
            $display("check 0x200 = 0x%0h  (0x600 = all pass)",
                     u_cpu_top.dmem_inst.mem[32'h200>>2]);
            $display("C = [%0d, %0d, %0d, %0d]  (expect 19, 22, 43, 50)",
                     u_cpu_top.dmem_inst.mem[32'h20c>>2],
                     u_cpu_top.dmem_inst.mem[32'h210>>2],
                     u_cpu_top.dmem_inst.mem[32'h214>>2],
                     u_cpu_top.dmem_inst.mem[32'h218>>2]);
            $display("Total mcycle: %0d | Total minstret: %0d", mcycle, minstret);
            $finish;
        end

    // always @(posedge clk)
    //     if (u_cpu_top.dmem_inst.mem_write)
    //         $display("t=%0t DMEM_WRITE addr=0x%0h wdata=0x%0h byte_en=%0b mask=%0h",
    //                 $time,
    //                 u_cpu_top.dmem_inst.addr,
    //                 u_cpu_top.dmem_inst.wdata,
    //                 u_cpu_top.dmem_inst.byte_en,
    //                 u_cpu_top.dmem_inst.mask);
    
endmodule
