// Resolves conditional branches and jumps. No prediction is used.
module branch (
    input  wire [63:0] pc,
    input  wire [63:0] rs1_data,
    input  wire [63:0] rs2_data,
    input  wire [63:0] immediate,
    input  wire        is_branch,
    input  wire [2:0]  branch_funct3,
    input  wire [1:0]  jump_kind, // 0 none, 1 JAL, 2 JALR
    output wire        redirect,
    output wire [63:0] target,
    output wire        target_misaligned
);
    reg branch_taken;
    always @* begin
        branch_taken = 1'b0;
        case (branch_funct3)
            3'b000: branch_taken = (rs1_data == rs2_data); // BEQ
            3'b001: branch_taken = (rs1_data != rs2_data); // BNE
            3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));
            3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
            3'b110: branch_taken = (rs1_data < rs2_data);
            3'b111: branch_taken = (rs1_data >= rs2_data);
            default: branch_taken = 1'b0;
        endcase
    end
    assign redirect = (jump_kind != 2'd0) || (is_branch && branch_taken);
    assign target = (jump_kind == 2'd2) ? ((rs1_data + immediate) & ~64'd1)
                                         : (pc + immediate);
    assign target_misaligned = redirect && (|target[1:0]);
endmodule
