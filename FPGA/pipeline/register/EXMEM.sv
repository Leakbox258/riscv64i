`include "pipeline_pkg.sv"

module EXMEM
  import pipeline_pkg::*;
(
    input clk_i,
    input rst_i,

    input  EXMEM_Pipe_t data_i,
    output EXMEM_Pipe_t data_o
);

  EXMEM_Pipe_t next_data;

  always_comb begin
    if (rst_i) begin
      next_data = 0;
    end else begin
      next_data = data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    data_o <= next_data;
  end

endmodule

