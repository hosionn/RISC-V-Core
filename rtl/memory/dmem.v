// Independent data RAM: combinational read, synchronous byte-masked we.
module dmem #(
    parameter integer MEM_BYTES = 65536,
    parameter [63:0] BASE_ADDR = 64'd0
) (
    input  wire        clk,
    input  wire        ce,
    input  wire        we,
    input  wire [63:0] addr,
    input  wire [63:0] wdata,
    input  wire [7:0]  wstrb,
    output reg  [63:0] rdata,
    output wire        error
);
    reg [7:0] mem [0:MEM_BYTES-1];
    wire [63:0] offset = addr - BASE_ADDR;
    wire address_ok = (addr >= BASE_ADDR) &&
                      (offset <= MEM_BYTES - 8) &&
                      (addr[2:0] == 3'b000);
    assign error = ce && !address_ok;

    always @* begin
        if (ce && !we && address_ok)
            rdata = {mem[offset+7], mem[offset+6], mem[offset+5],
                     mem[offset+4], mem[offset+3], mem[offset+2],
                     mem[offset+1], mem[offset]};
        else
            rdata = 64'd0;
    end

    integer lane;
    always @(posedge clk)
        if (ce && we && address_ok)
            for (lane = 0; lane < 8; lane = lane + 1)
                if (wstrb[lane])
                    mem[offset+lane] <= wdata[8*lane +: 8];

`ifndef SYNTHESIS
    integer init_i;
    initial begin
        for (init_i = 0; init_i < MEM_BYTES; init_i = init_i + 1)
            mem[init_i] = 8'd0;
    end
`endif
endmodule
