`include "pipeline_pkg.sv"

module Stall
  import pipeline_pkg::*;
(
    input EXMEM_Pipe_Out_t exmem_out,
    input IDEX_Pipe_t idex_out,

    output stall
);

  always_comb begin
    stall = '0;

    if (exmem_out.Mem_REn && exmem_out.Reg_WEn && (exmem_out.RegIdx[IDX_RD] != 0)) begin

      if ((exmem_out.RegIdx[IDX_RD] == idex_out.RegIdx[IDX_RS1] && idex_out.RegIdx[IDX_RS1] != 0) )begin
        stall = '1;
      end

      if((exmem_out.RegIdx[IDX_RD] == idex_out.RegIdx[IDX_RS2] && idex_out.RegIdx[IDX_RS2] != 0)) begin
        stall = '1;
      end
    end
  end

endmodule
