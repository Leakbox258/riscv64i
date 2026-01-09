module IFU #(
    INST_WIDTH = 32
) (
    input  [INST_WIDTH-1:0] data,
    output [INST_WIDTH-1:0] inst
);

  assign inst = data;

endmodule
