// Integration top: core plus separate external instruction/data RAMs.
// Store-monitor outputs are optional observation points for a testbench/device.
module soc #(
    parameter [63:0] RESET_PC = 64'd0,
    parameter integer MEM_BYTES = 65536
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire        halted,
    output wire [3:0]  halt_reason,
    output wire [63:0] halt_pc,
    output wire        store_valid,
    output wire [63:0] store_addr,
    output wire [63:0] store_data,
    output wire [7:0]  store_strb
);
    wire [63:0] imem_addr;
    wire [31:0] imem_rdata;
    wire imem_error;
    wire dmem_req_valid;
    wire dmem_req_write;
    wire [63:0] dmem_req_addr;
    wire [63:0] dmem_req_wdata;
    wire [7:0] dmem_req_wstrb;
    wire [63:0] dmem_rdata;
    wire dmem_error;

    core #(.RESET_PC(RESET_PC)) u_core (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .imem_error(imem_error),
        .dmem_req_valid(dmem_req_valid), .dmem_req_write(dmem_req_write),
        .dmem_req_addr(dmem_req_addr), .dmem_req_wdata(dmem_req_wdata),
        .dmem_req_wstrb(dmem_req_wstrb),
        .dmem_rdata(dmem_rdata), .dmem_error(dmem_error),
        .halted(halted), .halt_reason(halt_reason), .halt_pc(halt_pc)
    );

    imem #(.MEM_BYTES(MEM_BYTES)) u_imem (
        .addr(imem_addr), .rdata(imem_rdata), .error(imem_error)
    );
    dmem #(.MEM_BYTES(MEM_BYTES)) u_dmem (
        .clk(clk), .ce(dmem_req_valid), .we(dmem_req_write),
        .addr(dmem_req_addr), .wdata(dmem_req_wdata),
        .wstrb(dmem_req_wstrb), .rdata(dmem_rdata), .error(dmem_error)
    );

    assign store_valid = dmem_req_valid && dmem_req_write;
    assign store_addr = dmem_req_addr;
    assign store_data = dmem_req_wdata;
    assign store_strb = dmem_req_wstrb;
endmodule
