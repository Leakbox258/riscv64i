`include "pipeline_pkg.sv"

module IFID
  import pipeline_pkg::*;
(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic flush,

    input  IFID_Pipe_t wdata,
    output IFID_Pipe_t rdata
);

  IFID_Pipe_t next_data;

  always_comb begin
    if (rst) begin
      next_data = 0;
    end else if (flush) begin
      next_data = 0;
    end else if (!stall) begin
      next_data = wdata;
    end else begin
      next_data = rdata;  // keep
    end
  end

  always_ff @(posedge clk) begin
    rdata <= next_data;
  end

endmodule
