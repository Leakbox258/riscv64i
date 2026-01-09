`include "pipeline_pkg.sv"

module IDEX
  import pipeline_pkg::*;
(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,

    input  IDEX_Pipe_t wdata,
    output IDEX_Pipe_t rdata
);

  IDEX_Pipe_t next_data;

  always_comb begin
    if (rst) begin
      next_data = 0;
    end else if (flush || stall) begin
      next_data = 0;
    end else begin
      next_data = wdata;
    end
  end

  always_ff @(posedge clk) begin
    rdata <= next_data;
  end

endmodule
