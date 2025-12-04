module IFU #(
    DATA_WIDTH = 32,
    PC_WIDTH   = 64
) (
    input clk,
    input [PC_WIDTH-1:0] pc_i,
    output [DATA_WIDTH-1:0] inst_o,
    output fecth_error_o
);

  CodeROM #(64, 32, 12) codeROM (
      .clk(clk),
      .addr_i(pc_i),
      .data_o(inst_o),
      .illegal_access_o(fecth_error_o)
  );

endmodule
