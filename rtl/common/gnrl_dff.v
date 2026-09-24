// E603-style reusable flops. Reset is active low and asynchronous.
module gnrl_dffr #(
    parameter integer DW = 1
) (
    input  wire [DW-1:0] dnxt,
    output reg  [DW-1:0] qout,
    input  wire          clk,
    input  wire          rst_n
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) qout <= {DW{1'b0}};
        else        qout <= dnxt;
endmodule

module gnrl_dfflr #(
    parameter integer DW = 1
) (
    input  wire          lden,
    input  wire [DW-1:0] dnxt,
    output reg  [DW-1:0] qout,
    input  wire          clk,
    input  wire          rst_n
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n)      qout <= {DW{1'b0}};
        else if (lden)   qout <= dnxt;
endmodule

module gnrl_dfflrs #(
    parameter integer DW = 1,
    parameter [DW-1:0] RST = {DW{1'b1}}
) (
    input  wire          lden,
    input  wire [DW-1:0] dnxt,
    output reg  [DW-1:0] qout,
    input  wire          clk,
    input  wire          rst_n
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n)      qout <= RST;
        else if (lden)   qout <= dnxt;
endmodule
