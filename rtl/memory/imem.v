// Independent instruction RAM: a PC lookup returns in the same cycle.
module imem #(
    parameter integer MEM_BYTES = 65536,
    parameter [63:0] BASE_ADDR = 64'd0
) (
    input  wire [63:0] addr,
    output reg  [31:0] rdata,
    output wire        error
);
    reg [7:0] mem [0:MEM_BYTES-1];
    wire [63:0] offset = addr - BASE_ADDR;
    wire address_ok = (addr >= BASE_ADDR) &&
                      (offset <= MEM_BYTES - 4) &&
                      (addr[1:0] == 2'b00);
    assign error = !address_ok;

    always @* begin
        if (address_ok)
            rdata = {mem[offset+3], mem[offset+2], mem[offset+1], mem[offset]};
        else
            rdata = 32'd0;
    end

`ifndef SYNTHESIS
    reg [8*256-1:0] image_file;
    integer init_i;
    initial begin
        for (init_i = 0; init_i < MEM_BYTES; init_i = init_i + 1)
            mem[init_i] = 8'd0;
        if ($value$plusargs("HEX=%s", image_file)) begin
            $display("Loading %0s into instruction RAM", image_file);
            $readmemh(image_file, mem);
        end
    end
`endif
endmodule
