// Forward EX/MEM results before MEM/WB results; never forward a load before
// its data response has been captured into MEM/WB.
module forward_unit (
    input  wire [4:0] ex_rs1,
    input  wire [4:0] ex_rs2,
    input  wire       exmem_valid,
    input  wire       exmem_write_rd,
    input  wire       exmem_load,
    input  wire [4:0] exmem_rd,
    input  wire       memwb_valid,
    input  wire       memwb_write_rd,
    input  wire [4:0] memwb_rd,
    output reg  [1:0] select_rs1,
    output reg  [1:0] select_rs2
);
    always @* begin
        select_rs1 = 2'd0;
        select_rs2 = 2'd0;
        if (ex_rs1 != 5'd0) begin
            if (exmem_valid && exmem_write_rd && !exmem_load && exmem_rd == ex_rs1)
                select_rs1 = 2'd1;
            else if (memwb_valid && memwb_write_rd && memwb_rd == ex_rs1)
                select_rs1 = 2'd2;
        end
        if (ex_rs2 != 5'd0) begin
            if (exmem_valid && exmem_write_rd && !exmem_load && exmem_rd == ex_rs2)
                select_rs2 = 2'd1;
            else if (memwb_valid && memwb_write_rd && memwb_rd == ex_rs2)
                select_rs2 = 2'd2;
        end
    end
endmodule
