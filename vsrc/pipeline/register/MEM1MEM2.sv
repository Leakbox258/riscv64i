`include "pipeline_pkg.sv"

module MEM1MEM2
  import pipeline_pkg::*;
(
    input clk_i,
    input rst,
    input MEM1MEM2_Pipe_t data_i,
    output MEM1MEM2_Pipe_t data_o
);

  MEM1MEM2_Pipe_t next_data;

  always_comb begin
    if (rst) begin
      next_data = 0;
    end else begin
      next_data = data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    data_o <= next_data;
  end

endmodule
