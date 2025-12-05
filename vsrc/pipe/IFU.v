module IFU #(
    DATA_WIDTH = 32
) (
    input  [DATA_WIDTH-1:0] data_i,
    output [DATA_WIDTH-1:0] inst_o
);

  assign inst_o = data_i;

endmodule
