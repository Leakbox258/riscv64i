`include "pipeline_pkg.sv"

module MEMWB
  import pipeline_pkg::*;
(
    input clk,
    input rst,

    input  MEMWB_Pipe_t wdata,
    output MEMWB_Pipe_t rdata
);

  MEMWB_Pipe_t next_data;

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
