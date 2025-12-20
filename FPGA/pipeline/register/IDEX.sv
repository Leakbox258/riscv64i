`include "pipeline_pkg.sv"

module IDEX
  import pipeline_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input logic stall_i,
    input logic flush_i,

    input  IDEX_Pipe_t data_i,
    output IDEX_Pipe_t data_o
);

  IDEX_Pipe_t next_data;

  always_comb begin
    if (rst_i) begin
      next_data = 0;
    end else if (flush_i || stall_i) begin
      next_data = 0;
    end else begin
      next_data = data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    data_o <= next_data;
  end

endmodule
