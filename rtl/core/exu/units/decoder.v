`include "alu_ops.vh"

// RV64I instruction classification and immediate generation.
// This module does not read registers or perform arithmetic.
module decoder (
    input  wire [31:0] instruction,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output reg  [63:0] immediate,
    output reg  [4:0]  alu_op,
    output reg  [1:0]  alu_a_sel, // 0 rs1, 1 PC, 2 zero
    output reg         alu_b_imm,
    output reg         write_rd,
    output reg         write_pc4,
    output reg         is_branch,
    output reg  [1:0]  jump_kind, // 0 none, 1 JAL, 2 JALR
    output reg         mem_read,
    output reg         mem_write,
    output reg         uses_rs1,
    output reg         uses_rs2,
    output reg         illegal,
    output reg  [3:0]  illegal_reason
);
    wire [6:0] opcode = instruction[6:0];
    wire [6:0] funct7 = instruction[31:25];
    wire [63:0] imm_i = {{52{instruction[31]}}, instruction[31:20]};
    wire [63:0] imm_s = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [63:0] imm_b = {{51{instruction[31]}}, instruction[31], instruction[7],
                         instruction[30:25], instruction[11:8], 1'b0};
    wire [63:0] imm_u = {{32{instruction[31]}}, instruction[31:12], 12'b0};
    wire [63:0] imm_j = {{43{instruction[31]}}, instruction[31], instruction[19:12],
                         instruction[20], instruction[30:21], 1'b0};
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];

    always @* begin
        immediate = 64'd0;
        alu_op = `RV64_ALU_ADD;
        alu_a_sel = 2'd0;
        alu_b_imm = 1'b0;
        write_rd = 1'b0;
        write_pc4 = 1'b0;
        is_branch = 1'b0;
        jump_kind = 2'd0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        illegal = 1'b0;
        illegal_reason = 4'd1;
        case (opcode)
            7'b0110111: begin // LUI
                immediate = imm_u;
                alu_a_sel = 2'd2;
                alu_b_imm = 1'b1;
                write_rd = 1'b1;
            end
            7'b0010111: begin // AUIPC
                immediate = imm_u;
                alu_a_sel = 2'd1;
                alu_b_imm = 1'b1;
                write_rd = 1'b1;
            end
            7'b1101111: begin // JAL
                immediate = imm_j;
                jump_kind = 2'd1;
                write_rd = 1'b1;
                write_pc4 = 1'b1;
            end
            7'b1100111: begin // JALR
                immediate = imm_i;
                jump_kind = 2'd2;
                uses_rs1 = 1'b1;
                write_rd = 1'b1;
                write_pc4 = 1'b1;
                if (funct3 != 3'b000) illegal = 1'b1;
            end
            7'b1100011: begin // Branch
                immediate = imm_b;
                is_branch = 1'b1;
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: ;
                    default: illegal = 1'b1;
                endcase
            end
            7'b0000011: begin // Load
                immediate = imm_i;
                alu_b_imm = 1'b1;
                mem_read = 1'b1;
                write_rd = 1'b1;
                uses_rs1 = 1'b1;
                case (funct3)
                    3'b000, 3'b001, 3'b010, 3'b011,
                    3'b100, 3'b101, 3'b110: ;
                    default: illegal = 1'b1;
                endcase
            end
            7'b0100011: begin // Store
                immediate = imm_s;
                alu_b_imm = 1'b1;
                mem_write = 1'b1;
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000, 3'b001, 3'b010, 3'b011: ;
                    default: illegal = 1'b1;
                endcase
            end
            7'b0010011: begin // OP-IMM
                immediate = imm_i;
                alu_b_imm = 1'b1;
                write_rd = 1'b1;
                uses_rs1 = 1'b1;
                case (funct3)
                    3'b000: alu_op = `RV64_ALU_ADD;
                    3'b010: alu_op = `RV64_ALU_SLT;
                    3'b011: alu_op = `RV64_ALU_SLTU;
                    3'b100: alu_op = `RV64_ALU_XOR;
                    3'b110: alu_op = `RV64_ALU_OR;
                    3'b111: alu_op = `RV64_ALU_AND;
                    3'b001: begin
                        alu_op = `RV64_ALU_SLL;
                        if (instruction[31:26] != 6'b000000) illegal = 1'b1;
                    end
                    3'b101: begin
                        if (instruction[31:26] == 6'b000000) alu_op = `RV64_ALU_SRL;
                        else if (instruction[31:26] == 6'b010000) alu_op = `RV64_ALU_SRA;
                        else illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
            7'b0011011: begin // OP-IMM-32
                immediate = imm_i;
                alu_b_imm = 1'b1;
                write_rd = 1'b1;
                uses_rs1 = 1'b1;
                case (funct3)
                    3'b000: alu_op = `RV64_ALU_ADDW;
                    3'b001: begin
                        alu_op = `RV64_ALU_SLLW;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) alu_op = `RV64_ALU_SRLW;
                        else if (funct7 == 7'b0100000) alu_op = `RV64_ALU_SRAW;
                        else illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
            7'b0110011: begin // OP
                write_rd = 1'b1;
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000) alu_op = `RV64_ALU_ADD;
                        else if (funct7 == 7'b0100000) alu_op = `RV64_ALU_SUB;
                        else illegal = 1'b1;
                    end
                    3'b001: begin
                        alu_op = `RV64_ALU_SLL;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b010: begin
                        alu_op = `RV64_ALU_SLT;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b011: begin
                        alu_op = `RV64_ALU_SLTU;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b100: begin
                        alu_op = `RV64_ALU_XOR;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) alu_op = `RV64_ALU_SRL;
                        else if (funct7 == 7'b0100000) alu_op = `RV64_ALU_SRA;
                        else illegal = 1'b1;
                    end
                    3'b110: begin
                        alu_op = `RV64_ALU_OR;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b111: begin
                        alu_op = `RV64_ALU_AND;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                endcase
            end
            7'b0111011: begin // OP-32
                write_rd = 1'b1;
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000) alu_op = `RV64_ALU_ADDW;
                        else if (funct7 == 7'b0100000) alu_op = `RV64_ALU_SUBW;
                        else illegal = 1'b1;
                    end
                    3'b001: begin
                        alu_op = `RV64_ALU_SLLW;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) alu_op = `RV64_ALU_SRLW;
                        else if (funct7 == 7'b0100000) alu_op = `RV64_ALU_SRAW;
                        else illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
            7'b0001111: begin // FENCE; FENCE.I is not RV64I
                if (funct3 != 3'b000) illegal = 1'b1;
            end
            7'b1110011: begin // No privileged trap handler
                illegal = 1'b1;
                if (instruction == 32'h0000_0073) illegal_reason = 4'd6;
                else if (instruction == 32'h0010_0073) illegal_reason = 4'd7;
            end
            default: illegal = 1'b1;
        endcase
    end
endmodule
