`include "pipeline_pkg.sv"

module Stall
  import pipeline_pkg::*;
(
    input IDEX_Pipe_t idex_out,  // ex
    input IDEX_Pipe_t idex_in,   // id

    output stall
);

  always_comb begin
    stall = 1'b0;

    if (idex_out.Enable[IDX_MREAD] && idex_out.Enable[IDX_RD] && (idex_out.RegIdx[IDX_RD] != 0)) begin

      if ((idex_out.RegIdx[IDX_RD] == idex_in.RegIdx[IDX_RS1] && idex_in.RegIdx[IDX_RS1] != 0)) begin
        stall = 1'b1;
      end

      if ((idex_out.RegIdx[IDX_RD] == idex_in.RegIdx[IDX_RS2] && idex_in.RegIdx[IDX_RS2] != 0)) begin
        stall = 1'b1;
      end
    end
  end

endmodule
