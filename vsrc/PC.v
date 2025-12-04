module PC (
    input i_we,
    input i_clk,
    input i_rst,
    input [63:0] i_data,
    output [63:0] o_pc
);

  reg [63:0] pc;

  always @(posedge i_clk) begin
    if (i_rst) pc <= 64'h80000000;
    else if (i_we) pc <= i_data;
  end

  assign o_pc = pc;

endmodule
