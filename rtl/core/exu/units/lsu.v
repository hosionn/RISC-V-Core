// MEM-stage load/store unit. The EX/MEM register supplies the effective
// address and store operand; data RAM is read combinationally in this stage.
module lsu (
    input  wire [63:0] effective_address,
    input  wire [63:0] store_data,
    input  wire [2:0]  funct3,
    input  wire [63:0] response_data,
    output wire [63:0] request_address,
    output wire [63:0] request_write_data,
    output reg  [7:0]  request_write_strobe,
    output wire        request_misaligned,
    output reg  [63:0] load_result
);
    wire [2:0] lane = effective_address[2:0];
    wire [3:0] size_bytes = 4'd1 << funct3[1:0];
    wire [63:0] selected_data = response_data >> {lane, 3'b000};
    assign request_address = {effective_address[63:3], 3'b000};
    assign request_write_data = store_data << {lane, 3'b000};
    assign request_misaligned = ((size_bytes == 4'd2) && effective_address[0]) ||
                                ((size_bytes == 4'd4) && (|effective_address[1:0])) ||
                                ((size_bytes == 4'd8) && (|effective_address[2:0]));

    always @* begin
        case (size_bytes)
            4'd1: request_write_strobe = 8'h01 << lane;
            4'd2: request_write_strobe = 8'h03 << lane;
            4'd4: request_write_strobe = 8'h0f << lane;
            4'd8: request_write_strobe = 8'hff;
            default: request_write_strobe = 8'd0;
        endcase
        case (funct3)
            3'b000: load_result = {{56{selected_data[7]}}, selected_data[7:0]};
            3'b001: load_result = {{48{selected_data[15]}}, selected_data[15:0]};
            3'b010: load_result = {{32{selected_data[31]}}, selected_data[31:0]};
            3'b011: load_result = selected_data;
            3'b100: load_result = {56'd0, selected_data[7:0]};
            3'b101: load_result = {48'd0, selected_data[15:0]};
            3'b110: load_result = {32'd0, selected_data[31:0]};
            default: load_result = 64'd0;
        endcase
    end
endmodule
