// ALU operation encoding shared by decoder and alu.
`ifndef RV64_ALU_OPS_VH
`define RV64_ALU_OPS_VH
`define RV64_ALU_ADD   5'd0
`define RV64_ALU_SUB   5'd1
`define RV64_ALU_SLL   5'd2
`define RV64_ALU_SLT   5'd3
`define RV64_ALU_SLTU  5'd4
`define RV64_ALU_XOR   5'd5
`define RV64_ALU_SRL   5'd6
`define RV64_ALU_SRA   5'd7
`define RV64_ALU_OR    5'd8
`define RV64_ALU_AND   5'd9
`define RV64_ALU_ADDW  5'd10
`define RV64_ALU_SUBW  5'd11
`define RV64_ALU_SLLW  5'd12
`define RV64_ALU_SRLW  5'd13
`define RV64_ALU_SRAW  5'd14
`endif
