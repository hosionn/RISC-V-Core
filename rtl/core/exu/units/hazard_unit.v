// A load in EX has no value to forward to the next instruction's EX cycle.
// Hold IF/ID and insert one ID/EX bubble; the result then comes from MEM/WB.
module hazard_unit (
    input  wire       id_valid,
    input  wire       id_uses_rs1,
    input  wire       id_uses_rs2,
    input  wire [4:0] id_rs1,
    input  wire [4:0] id_rs2,
    input  wire       ex_valid,
    input  wire       ex_load,
    input  wire [4:0] ex_rd,
    output wire       load_use_stall
);
    assign load_use_stall = id_valid && ex_valid && ex_load && (ex_rd != 5'd0) &&
                            ((id_uses_rs1 && id_rs1 == ex_rd) ||
                             (id_uses_rs2 && id_rs2 == ex_rd));
endmodule
