// Two asynchronous read ports, one synchronous write port. x0 is always zero.
module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    output wire [63:0] rs1_data,
    output wire [63:0] rs2_data,
    input  wire        write_enable,
    input  wire [4:0]  write_rd,
    input  wire [63:0] write_data
);
    wire [63:0] regs [0:31];
    assign regs[0] = 64'd0;
    assign rs1_data = (rs1 == 5'd0) ? 64'd0 : regs[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 64'd0 : regs[rs2];

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : gen_register
            localparam [4:0] REG_INDEX = i;
            gnrl_dfflr #(.DW(64)) u_reg (
                .lden(write_enable && write_rd == REG_INDEX),
                .dnxt(write_data), .qout(regs[i]), .clk(clk), .rst_n(rst_n)
            );
        end
    endgenerate
endmodule
