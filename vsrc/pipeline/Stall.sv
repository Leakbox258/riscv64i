`include "pipeline_pkg.sv"

module Stall
  import pipeline_pkg::*;
(
    input EnMemR_ex,
    input EnRd_ex,
    input [RF_SIZE-1:0] RdIdx_ex,

    input [RF_SIZE-1:0] Rs1Idx_id,
    input [RF_SIZE-1:0] Rs2Idx_id,

    output logic stall
);

  always_comb begin
    stall = 1'b0;

    if (EnMemR_ex && EnRd_ex && RdIdx_ex != 0) begin

      if ((RdIdx_ex == Rs1Idx_id && Rs1Idx_id != 0)) begin
        stall = 1'b1;
      end

      if ((RdIdx_ex == Rs2Idx_id && Rs2Idx_id != 0)) begin
        stall = 1'b1;
      end
    end
  end

endmodule
