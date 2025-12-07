module IFID #(
    INST_WIDTH = 32,
    DATA_WIDTH = 64
) (
    input clk_i,
    input rst_i,

    input flush_i,
    input stall_i,

    input [INST_WIDTH-1:0] inst_i,
    input [DATA_WIDTH-1:0] pc_i,

    output reg [INST_WIDTH-1:0] inst_o,
    output reg [DATA_WIDTH-1:0] pc_o
);

  always @(posedge clk_i) begin

    if (rst_i) begin
      pc_o   <= 64'h80000000;
      inst_o <= 32'h0;
    end else begin

      if (flush_i) begin
        pc_o   <= 64'h80000000;
        inst_o <= 32'h0;
      end else if (!stall_i) begin
        pc_o   <= pc_i;
        inst_o <= inst_i;
      end
    end
  end

endmodule
