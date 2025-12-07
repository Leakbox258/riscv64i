module IFU #(
    DATA_WIDTH = 64,
    INST_WIDTH = 32
) (
    input [DATA_WIDTH-1:0] pc_i,
    input [INST_WIDTH-1:0] data_i,
    output [INST_WIDTH-1:0] inst_o,
    output fetch_error_o
);

  assign inst_o = data_i;
  assign fetch_error_o = pc_i[1:0] != 2'b00;

endmodule
