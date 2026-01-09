`include "pipeline_pkg.sv"

module MEM1MEM2
  import pipeline_pkg::*;
(
    input clk,
    input rst,
    input MEM1MEM2_Pipe_t wdata,
    output MEM1MEM2_Pipe_t rdata
);

  MEM1MEM2_Pipe_t next_data;

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
