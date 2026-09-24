// Five-stage RV64I core: IF (ifu), ID/EX/MEM/WB (exu).
// Instruction and data memory remain external to this module.
module core #(
    parameter [63:0] RESET_PC = 64'd0
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire [63:0] imem_addr,
    input  wire [31:0] imem_rdata,
    input  wire        imem_error,
    output wire        dmem_req_valid,
    output wire        dmem_req_write,
    output wire [63:0] dmem_req_addr,
    output wire [63:0] dmem_req_wdata,
    output wire [7:0]  dmem_req_wstrb,
    input  wire [63:0] dmem_rdata,
    input  wire        dmem_error,
    output wire        halted,
    output wire [3:0]  halt_reason,
    output wire [63:0] halt_pc
);
    wire ifid_valid, ifid_error;
    wire [63:0] ifid_pc;
    wire [31:0] ifid_instruction;
    wire stall_fetch, flush_fetch, redirect_valid;
    wire [63:0] redirect_pc;

    ifu #(.RESET_PC(RESET_PC)) u_ifu (
        .clk(clk), .rst_n(rst_n),
        .stall(stall_fetch), .flush(flush_fetch), .halted(halted),
        .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .ifid_valid(ifid_valid), .ifid_pc(ifid_pc),
        .ifid_instruction(ifid_instruction), .ifid_error(ifid_error),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .imem_error(imem_error)
    );

    exu u_exu (
        .clk(clk), .rst_n(rst_n),
        .ifid_valid(ifid_valid), .ifid_pc(ifid_pc),
        .ifid_instruction(ifid_instruction), .ifid_error(ifid_error),
        .stall_fetch(stall_fetch), .flush_fetch(flush_fetch),
        .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .dmem_req_valid(dmem_req_valid), .dmem_req_write(dmem_req_write),
        .dmem_req_addr(dmem_req_addr), .dmem_req_wdata(dmem_req_wdata),
        .dmem_req_wstrb(dmem_req_wstrb),
        .dmem_rdata(dmem_rdata), .dmem_error(dmem_error),
        .halted(halted), .halt_reason(halt_reason), .halt_pc(halt_pc)
    );
endmodule
