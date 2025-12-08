module PC (
    input clk_i,
    input rst_i,

    input ewrite_i,

    input  [63:0] data_i,
    output [63:0] pc_o
);

  reg [63:0] _pc;

  always_ff @(posedge clk_i) begin
    if (rst_i) _pc <= 64'h80000000;
    else if (ewrite_i) _pc <= data_i;
  end

  assign pc_o = _pc;

endmodule
