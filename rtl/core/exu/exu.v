// In-order RV64I pipeline: ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB.
// Each stage's register bank appears immediately after its combinational work.
module exu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ifid_valid,
    input  wire [63:0] ifid_pc,
    input  wire [31:0] ifid_instruction,
    input  wire        ifid_error,
    output wire        stall_fetch,
    output wire        flush_fetch,
    output wire        redirect_valid,
    output wire [63:0] redirect_pc,
    output wire        dmem_req_valid,
    output wire        dmem_req_write,
    output wire [63:0] dmem_req_addr,
    output wire [63:0] dmem_req_wdata,
    output wire [ 7:0] dmem_req_wstrb,
    input  wire [63:0] dmem_rdata,
    input  wire        dmem_error,
    output wire        halted,
    output wire [ 3:0] halt_reason,
    output wire [63:0] halt_pc
);
    localparam [3:0] IFETCH_ERROR = 4'd2, DATA_ERROR = 4'd3, BAD_TARGET = 4'd4, BAD_DATA_ALIGN = 4'd5;

    // ----------------------------- ID -----------------------------------
    wire [4:0] id_rs1, id_rs2, id_rd;
    wire [ 2:0] id_funct3;
    wire [63:0] id_immediate;
    wire [ 4:0] id_alu_op;
    wire [1:0] id_alu_a_sel, id_jump_kind;
    wire id_alu_b_imm, id_write_rd, id_write_pc4;
    wire id_is_branch, id_mem_read, id_mem_write;
    wire id_uses_rs1, id_uses_rs2, id_illegal;
    wire [3:0] id_illegal_reason;
    decoder u_decoder (
        .instruction(ifid_instruction),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),
        .funct3(id_funct3),
        .immediate(id_immediate),
        .alu_op(id_alu_op),
        .alu_a_sel(id_alu_a_sel),
        .alu_b_imm(id_alu_b_imm),
        .write_rd(id_write_rd),
        .write_pc4(id_write_pc4),
        .is_branch(id_is_branch),
        .jump_kind(id_jump_kind),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .uses_rs1(id_uses_rs1),
        .uses_rs2(id_uses_rs2),
        .illegal(id_illegal),
        .illegal_reason(id_illegal_reason)
    );

    wire [63:0] rf_rs1_data, rf_rs2_data;
    wire wb_write_enable;
    wire [4:0] memwb_rd;
    wire [63:0] memwb_result;
    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rs1_data(rf_rs1_data),
        .rs2_data(rf_rs2_data),
        .write_enable(wb_write_enable),
        .write_rd(memwb_rd),
        .write_data(memwb_result)
    );
    // WB and ID can refer to the same register at one clock edge.
    wire [63:0] id_rs1_data = (wb_write_enable && id_uses_rs1 && id_rs1 == memwb_rd) ? memwb_result : rf_rs1_data;
    wire [63:0] id_rs2_data = (wb_write_enable && id_uses_rs2 && id_rs2 == memwb_rd) ? memwb_result : rf_rs2_data;

    wire idex_valid, idex_error, idex_alu_b_imm, idex_write_rd;
    wire idex_write_pc4, idex_is_branch, idex_mem_read, idex_mem_write;
    wire idex_illegal;
    wire [63:0] idex_pc, idex_rs1_data, idex_rs2_data, idex_immediate;
    wire [31:0] idex_instruction;
    wire [4:0] idex_rs1, idex_rs2, idex_rd, idex_alu_op;
    wire [2:0] idex_funct3;
    wire [1:0] idex_alu_a_sel, idex_jump_kind;
    wire [3:0] idex_illegal_reason;
    wire load_use_stall;
    hazard_unit u_hazard (
        .id_valid(ifid_valid),
        .id_uses_rs1(id_uses_rs1),
        .id_uses_rs2(id_uses_rs2),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .ex_valid(idex_valid),
        .ex_load(idex_mem_read),
        .ex_rd(idex_rd),
        .load_use_stall(load_use_stall)
    );
    wire mem_fault, ex_fault_active;
    wire idex_valid_next = ifid_valid && !load_use_stall && !redirect_valid && !mem_fault && !ex_fault_active && !halted;
    assign stall_fetch = load_use_stall;
    assign flush_fetch = mem_fault || ex_fault_active;

    // -------------------------- ID/EX registers -------------------------
    gnrl_dffr #(
        .DW(1)
    ) u_idex_valid_dff (
        .dnxt (idex_valid_next),
        .qout (idex_valid),
        .clk  (clk),
        .rst_n(rst_n)
    );
    gnrl_dfflr #(
        .DW(327)
    ) u_idex_data_dff (
        .lden(idex_valid_next),
        .dnxt({
            ifid_pc,
            ifid_instruction,
            ifid_error,
            id_rs1,
            id_rs2,
            id_rd,
            id_rs1_data,
            id_rs2_data,
            id_immediate,
            id_funct3,
            id_alu_op,
            id_alu_a_sel,
            id_jump_kind,
            id_alu_b_imm,
            id_write_rd,
            id_write_pc4,
            id_is_branch,
            id_mem_read,
            id_mem_write,
            id_illegal,
            id_illegal_reason
        }),
        .qout({
            idex_pc,
            idex_instruction,
            idex_error,
            idex_rs1,
            idex_rs2,
            idex_rd,
            idex_rs1_data,
            idex_rs2_data,
            idex_immediate,
            idex_funct3,
            idex_alu_op,
            idex_alu_a_sel,
            idex_jump_kind,
            idex_alu_b_imm,
            idex_write_rd,
            idex_write_pc4,
            idex_is_branch,
            idex_mem_read,
            idex_mem_write,
            idex_illegal,
            idex_illegal_reason
        }),
        .clk(clk),
        .rst_n(rst_n)
    );

    // ----------------------------- EX -----------------------------------
    wire exmem_valid, exmem_write_rd, exmem_mem_read, exmem_mem_write;
    wire [63:0] exmem_pc, exmem_result, exmem_store_data;
    wire [4:0] exmem_rd;
    wire [2:0] exmem_funct3;
    wire memwb_valid, memwb_write_rd;
    wire [1:0] forward_rs1, forward_rs2;
    forward_unit u_forward (
        .ex_rs1(idex_rs1),
        .ex_rs2(idex_rs2),
        .exmem_valid(exmem_valid),
        .exmem_write_rd(exmem_write_rd),
        .exmem_load(exmem_mem_read),
        .exmem_rd(exmem_rd),
        .memwb_valid(memwb_valid),
        .memwb_write_rd(memwb_write_rd),
        .memwb_rd(memwb_rd),
        .select_rs1(forward_rs1),
        .select_rs2(forward_rs2)
    );
    wire [63:0] ex_rs1_data = (forward_rs1 == 2'd1) ? exmem_result : (forward_rs1 == 2'd2) ? memwb_result : idex_rs1_data;
    wire [63:0] ex_rs2_data = (forward_rs2 == 2'd1) ? exmem_result : (forward_rs2 == 2'd2) ? memwb_result : idex_rs2_data;
    wire [63:0] alu_a = (idex_alu_a_sel == 2'd1) ? idex_pc : (idex_alu_a_sel == 2'd2) ? 64'd0 : ex_rs1_data;
    wire [63:0] alu_b = idex_alu_b_imm ? idex_immediate : ex_rs2_data;
    wire [63:0] alu_result;
    alu u_alu (
        .a(alu_a),
        .b(alu_b),
        .op(idex_alu_op),
        .result(alu_result)
    );
    wire [63:0] ex_result = idex_write_pc4 ? idex_pc + 64'd4 : alu_result;

    wire branch_redirect, branch_misaligned;
    wire [63:0] branch_target;
    branch u_branch (
        .pc(idex_pc),
        .rs1_data(ex_rs1_data),
        .rs2_data(ex_rs2_data),
        .immediate(idex_immediate),
        .is_branch(idex_is_branch),
        .branch_funct3(idex_funct3),
        .jump_kind(idex_jump_kind),
        .redirect(branch_redirect),
        .target(branch_target),
        .target_misaligned(branch_misaligned)
    );
    wire ex_fault = idex_error || idex_illegal || branch_misaligned;
    wire ex_active = idex_valid && !halted && !mem_fault;
    assign ex_fault_active = ex_active && ex_fault;
    assign redirect_valid = ex_active && !ex_fault && branch_redirect;
    assign redirect_pc = branch_target;
    wire exmem_valid_next = ex_active && !ex_fault;

    // -------------------------- EX/MEM registers ------------------------
    gnrl_dffr #(
        .DW(1)
    ) u_exmem_valid_dff (
        .dnxt (exmem_valid_next),
        .qout (exmem_valid),
        .clk  (clk),
        .rst_n(rst_n)
    );
    gnrl_dfflr #(
        .DW(203)
    ) u_exmem_data_dff (
        .lden (exmem_valid_next),
        .dnxt ({idex_pc, ex_result, idex_rd, idex_write_rd, idex_mem_read, idex_mem_write, idex_funct3, ex_rs2_data}),
        .qout ({exmem_pc, exmem_result, exmem_rd, exmem_write_rd, exmem_mem_read, exmem_mem_write, exmem_funct3, exmem_store_data}),
        .clk  (clk),
        .rst_n(rst_n)
    );

    // ----------------------------- MEM ----------------------------------
    wire [63:0] mem_request_addr, mem_request_wdata, mem_load_result;
    wire [7:0] mem_request_wstrb;
    wire mem_request_misaligned;
    lsu u_lsu (
        .effective_address(exmem_result),
        .store_data(exmem_store_data),
        .funct3(exmem_funct3),
        .response_data(dmem_rdata),
        .request_address(mem_request_addr),
        .request_write_data(mem_request_wdata),
        .request_write_strobe(mem_request_wstrb),
        .request_misaligned(mem_request_misaligned),
        .load_result(mem_load_result)
    );
    wire exmem_memory = exmem_mem_read || exmem_mem_write;
    assign dmem_req_valid = rst_n && !halted && exmem_valid && exmem_memory && !mem_request_misaligned;
    assign dmem_req_write = exmem_mem_write;
    assign dmem_req_addr = mem_request_addr;
    assign dmem_req_wdata = mem_request_wdata;
    assign dmem_req_wstrb = exmem_mem_write ? mem_request_wstrb : 8'd0;
    assign mem_fault = exmem_valid && exmem_memory && (mem_request_misaligned || dmem_error);
    wire memwb_valid_next = exmem_valid && !mem_fault && !halted;

    // -------------------------- MEM/WB registers ------------------------
    gnrl_dffr #(
        .DW(1)
    ) u_memwb_valid_dff (
        .dnxt (memwb_valid_next),
        .qout (memwb_valid),
        .clk  (clk),
        .rst_n(rst_n)
    );
    gnrl_dfflr #(
        .DW(70)
    ) u_memwb_data_dff (
        .lden (memwb_valid_next),
        .dnxt ({exmem_rd, exmem_write_rd, exmem_mem_read ? mem_load_result : exmem_result}),
        .qout ({memwb_rd, memwb_write_rd, memwb_result}),
        .clk  (clk),
        .rst_n(rst_n)
    );

    // ----------------------------- WB -----------------------------------
    assign wb_write_enable = memwb_valid && memwb_write_rd && (memwb_rd != 5'd0);

    // Debug-only terminal fault status; no privileged trap handling yet.
    wire halt_event = mem_fault || ex_fault_active;
    wire [3:0] halt_reason_next = mem_fault ? (mem_request_misaligned ? BAD_DATA_ALIGN : DATA_ERROR) : (idex_error ? IFETCH_ERROR : idex_illegal ? idex_illegal_reason : BAD_TARGET);
    gnrl_dffr #(
        .DW(1)
    ) u_halted_dff (
        .dnxt (halted || halt_event),
        .qout (halted),
        .clk  (clk),
        .rst_n(rst_n)
    );
    gnrl_dfflr #(
        .DW(68)
    ) u_halt_info_dff (
        .lden (halt_event),
        .dnxt ({halt_reason_next, mem_fault ? exmem_pc : idex_pc}),
        .qout ({halt_reason, halt_pc}),
        .clk  (clk),
        .rst_n(rst_n)
    );
endmodule
