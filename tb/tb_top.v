`timescale 1ns/1ps

// Testbench only supplies clock/reset and checks the observable test protocol.
// The core and the two external RAMs are instantiated in soc.
module tb_top;
    localparam [63:0] TOHOST = 64'h0000_0000_0000_f000;
    reg clk;
    reg rst_n;
    wire halted;
    wire [3:0] halt_reason;
    wire [63:0] halt_pc;
    wire store_valid;
    wire [63:0] store_addr;
    wire [63:0] store_data;
    wire [7:0] store_strb;
    reg [8*256-1:0] testcase;
    reg [8*256-1:0] wave_file;
    integer max_cycles;
    integer cycles;
    reg saw_overlap;
    reg saw_exmem_forward;
    reg saw_memwb_forward;
    reg saw_load_use_stall;
    reg saw_redirect;

    soc #(.RESET_PC(64'd0), .MEM_BYTES(65536)) dut (
        .clk(clk), .rst_n(rst_n),
        .halted(halted), .halt_reason(halt_reason), .halt_pc(halt_pc),
        .store_valid(store_valid), .store_addr(store_addr),
        .store_data(store_data), .store_strb(store_strb)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        cycles = 0;
        saw_overlap = 1'b0;
        saw_exmem_forward = 1'b0;
        saw_memwb_forward = 1'b0;
        saw_load_use_stall = 1'b0;
        saw_redirect = 1'b0;
        if (!$value$plusargs("TESTCASE=%s", testcase)) testcase = "unknown";
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 10000;
        if ($test$plusargs("WAVE")) begin
            if (!$value$plusargs("WAVE_FILE=%s", wave_file))
                wave_file = "wave.vcd";
            $dumpfile(wave_file);
            // Omit the large RAM array from the waveform.
            $dumpvars(0, tb_top.dut.u_core);
        end
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycles <= cycles + 1;
            // With combinational instruction RAM, reset PC reaches IF/ID at
            // the first active edge rather than after a response-register beat.
            if ($test$plusargs("CHECK_PIPELINE") && cycles == 1 &&
                (!dut.u_core.u_ifu.ifid_valid ||
                 dut.u_core.u_ifu.ifid_pc != 64'd0)) begin
                $display("TEST_FAIL testcase=%0s reason=IF_STAGE_LATENCY", testcase);
                $fatal(1, "IF/ID did not capture reset PC in one cycle");
            end
            if (dut.u_core.u_ifu.ifid_valid && dut.u_core.u_exu.idex_valid &&
                dut.u_core.u_exu.exmem_valid && dut.u_core.u_exu.memwb_valid)
                saw_overlap <= 1'b1;
            if (dut.u_core.u_exu.ex_active &&
                (dut.u_core.u_exu.forward_rs1 == 2'd1 ||
                 dut.u_core.u_exu.forward_rs2 == 2'd1))
                saw_exmem_forward <= 1'b1;
            if (dut.u_core.u_exu.ex_active &&
                (dut.u_core.u_exu.forward_rs1 == 2'd2 ||
                 dut.u_core.u_exu.forward_rs2 == 2'd2))
                saw_memwb_forward <= 1'b1;
            if (dut.u_core.u_exu.load_use_stall)
                saw_load_use_stall <= 1'b1;
            if (dut.u_core.u_exu.redirect_valid)
                saw_redirect <= 1'b1;
            if (cycles >= max_cycles) begin
                $display("TEST_FAIL testcase=%0s reason=TIMEOUT cycles=%0d", testcase, cycles);
                $fatal(1, "TIMEOUT after %0d cycles", cycles);
            end
            if (halted) begin
                $display("TEST_FAIL testcase=%0s reason=CORE_HALT code=%0d pc=%016h",
                         testcase, halt_reason, halt_pc);
                $fatal(1, "CORE HALT: reason=%0d PC=%016h", halt_reason, halt_pc);
            end
            if ($test$plusargs("TRACE") && dut.u_core.u_exu.ex_active)
                $display("TRACE cycle=%0d EX pc=%016h insn=%08h", cycles,
                         dut.u_core.u_exu.idex_pc,
                         dut.u_core.u_exu.idex_instruction);
            if (store_valid && store_addr == TOHOST && store_strb == 8'hff) begin
                if (store_data == 64'd1) begin
                    if ($test$plusargs("CHECK_PIPELINE") &&
                        !(saw_overlap && saw_exmem_forward &&
                          saw_memwb_forward && saw_load_use_stall &&
                          saw_redirect)) begin
                        $display("TEST_FAIL testcase=%0s reason=PIPELINE_COVERAGE overlap=%b exmem=%b memwb=%b load_stall=%b redirect=%b",
                                 testcase, saw_overlap, saw_exmem_forward,
                                 saw_memwb_forward, saw_load_use_stall,
                                 saw_redirect);
                        $fatal(1, "Pipeline coverage check failed");
                    end
                    $display("TEST_PASS testcase=%0s cycles=%0d", testcase, cycles);
                    $finish;
                end else begin
                    $display("TEST_FAIL testcase=%0s reason=TOHOST value=%016h",
                             testcase, store_data);
                    $fatal(1, "TEST FAIL: tohost=%016h", store_data);
                end
            end
        end
    end
endmodule
