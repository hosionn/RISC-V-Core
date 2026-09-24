// IF combinational logic followed by its single IF/ID register boundary.
// The registered PC directly addresses the combinational instruction RAM.
module ifu #(
    parameter [63:0] RESET_PC = 64'd0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    input  wire        halted,
    input  wire        redirect_valid,
    input  wire [63:0] redirect_pc,
    output wire        ifid_valid,
    output wire [63:0] ifid_pc,
    output wire [31:0] ifid_instruction,
    output wire        ifid_error,
    output wire [63:0] imem_addr,
    input  wire [31:0] imem_rdata,
    input  wire        imem_error
);
    // ----------------------- IF combinational logic ----------------------
    wire [63:0] pc;
    wire [63:0] next_pc = redirect_valid ? redirect_pc : pc + 64'd4;
    wire pc_enable = redirect_valid || (!stall && !flush && !halted);
    wire ifid_capture = !stall && !flush && !halted && !redirect_valid;
    wire ifid_valid_enable = !stall || flush || halted || redirect_valid;
    wire ifid_valid_next = ifid_capture;
    assign imem_addr = pc;

    // ------------------------- IF stage registers -----------------------
    gnrl_dfflrs #(.DW(64), .RST(RESET_PC)) u_pc_dff (
        .lden(pc_enable), .dnxt(next_pc), .qout(pc), .clk(clk), .rst_n(rst_n)
    );
    gnrl_dfflr #(.DW(1)) u_ifid_valid_dff (
        .lden(ifid_valid_enable), .dnxt(ifid_valid_next),
        .qout(ifid_valid), .clk(clk), .rst_n(rst_n)
    );
    gnrl_dfflr #(.DW(97)) u_ifid_data_dff (
        .lden(ifid_capture), .dnxt({pc, imem_rdata, imem_error}),
        .qout({ifid_pc, ifid_instruction, ifid_error}),
        .clk(clk), .rst_n(rst_n)
    );
endmodule
