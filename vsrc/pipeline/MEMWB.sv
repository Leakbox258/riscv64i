`include "pipeline_pkg.sv"

module MEMWB
  import pipeline_pkg::*;
(
    input clk_i,
    input rst_i,

    input  MEMWB_Pipe_t data_i,
    output MEMWB_Pipe_t data_o
);

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      data_o <= '0;
    end else begin
      data_o <= data_i;
    end
  end

endmodule
