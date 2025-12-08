module IFU #(
    INST_WIDTH = 32
) (
    input  [INST_WIDTH-1:0] data_i,
    output [INST_WIDTH-1:0] inst_o
);

  assign inst_o = data_i;

endmodule
