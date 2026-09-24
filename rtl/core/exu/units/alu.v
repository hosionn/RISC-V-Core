`include "alu_ops.vh"

// Purely combinational RV64I integer ALU. The decoder selects operands/op.
module alu (
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [4:0]  op,
    output reg  [63:0] result
);
    function [63:0] sign32;
        input [31:0] value;
        begin sign32 = {{32{value[31]}}, value}; end
    endfunction

    always @* begin
        case (op)
            `RV64_ALU_ADD:  result = a + b;
            `RV64_ALU_SUB:  result = a - b;
            `RV64_ALU_SLL:  result = a << b[5:0];
            `RV64_ALU_SLT:  result = ($signed(a) < $signed(b)) ? 64'd1 : 64'd0;
            `RV64_ALU_SLTU: result = (a < b) ? 64'd1 : 64'd0;
            `RV64_ALU_XOR:  result = a ^ b;
            `RV64_ALU_SRL:  result = a >> b[5:0];
            `RV64_ALU_SRA:  result = $signed(a) >>> b[5:0];
            `RV64_ALU_OR:   result = a | b;
            `RV64_ALU_AND:  result = a & b;
            `RV64_ALU_ADDW: result = sign32(a[31:0] + b[31:0]);
            `RV64_ALU_SUBW: result = sign32(a[31:0] - b[31:0]);
            `RV64_ALU_SLLW: result = sign32(a[31:0] << b[4:0]);
            `RV64_ALU_SRLW: result = sign32(a[31:0] >> b[4:0]);
            `RV64_ALU_SRAW: result = sign32($signed(a[31:0]) >>> b[4:0]);
            default:        result = 64'd0;
        endcase
    end
endmodule
