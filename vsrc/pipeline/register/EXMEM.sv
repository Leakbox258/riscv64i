`include "pipeline_pkg.sv"

module EXMEM
  import pipeline_pkg::*;
(
    input clk,
    input rst,

    input  EXMEM_Pipe_t wdata,
    output EXMEM_Pipe_t rdata
);

  EXMEM_Pipe_t next_data;

  always_comb begin
    if (rst) begin
      next_data = 0;
    end else begin
      next_data = wdata;
    end
  end

  always_ff @(posedge clk) begin
    rdata <= next_data;
  end

endmodule

