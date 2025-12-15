`include "pipeline_pkg.sv"

module IFID
  import pipeline_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input logic stall_i,
    input logic flush_i,

    input  IFID_Pipe_t data_i,
    output IFID_Pipe_t data_o
);

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      data_o <= 0;
    end else if (flush_i) begin
      data_o <= 0;
    end else if (!stall_i) begin
      data_o <= data_i;
    end
  end

endmodule
