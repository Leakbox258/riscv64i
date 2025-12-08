`include "pipeline_pkg.sv"

module EXMEM
  import pipeline_pkg::*;
(
    input clk_i,
    input rst_i,

    input  EXMEM_Pipe_In_t  data_i,
    output EXMEM_Pipe_Out_t data_o
);

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      data_o <= '0;
    end else begin
      data_o <= data_i[EXMEM_SLICE_BEGIN:0];
    end
  end

endmodule

