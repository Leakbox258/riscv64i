`include "pipeline_pkg.sv"

module Forward
  import pipeline_pkg::*;
(
    input IDEX_Pipe_t idex_in,
    input IDEX_Pipe_t idex_out,
    input EXMEM_Pipe_Out_t exmem_out,
    input MEMWB_Pipe_t memwb_out,

    output logic [1:0] Forward_RD1,
    output logic [1:0] Forward_RD2,
    output logic [1:0] Forward_A,
    output logic [1:0] Forward_B
);

  always_comb begin

    if (idex_in.Enable[IDX_RS1]) begin

      if (idex_out.Enable[IDX_RD] && idex_in.RegIdx[IDX_RS1] == idex_out.RegIdx[IDX_RD]) begin
        Forward_RD1 = ALUC_TO_RD;
      end else if (exmem_out.Reg_WEn && idex_in.RegIdx[IDX_RS1] == exmem_out.RegIdx[IDX_RD]) begin
        Forward_RD1 = MEM_TO_RD;
      end else begin
        Forward_RD1 = NO_FWD;
      end

    end else Forward_RD1 = NO_FWD;
  end

  always_comb begin

    if (idex_in.Enable[IDX_RS2]) begin

      if (idex_out.Enable[IDX_RD] && idex_in.RegIdx[IDX_RS2] == idex_out.RegIdx[IDX_RD]) begin
        Forward_RD2 = ALUC_TO_RD;
      end else if (exmem_out.Reg_WEn && idex_in.RegIdx[IDX_RS2] == exmem_out.RegIdx[IDX_RD]) begin
        Forward_RD2 = MEM_TO_RD;
      end else begin
        Forward_RD2 = NO_FWD;
      end

    end else Forward_RD2 = NO_FWD;

  end

  always_comb begin

    if (idex_out.Enable[IDX_RS1]) begin
      if (exmem_out.Reg_WEn && exmem_out.RegIdx[IDX_RD] == idex_out.RegIdx[IDX_RS1]) begin
        Forward_A = MEM_TO_ALU;
      end else if (memwb_out.Reg_WEn && memwb_out.RD_Addr == idex_out.RegIdx[IDX_RS1]) begin
        Forward_A = WB_TO_ALU;
      end else Forward_A = NO_FWD;
    end else Forward_A = NO_FWD;

  end

  always_comb begin

    if (idex_out.Enable[IDX_RS2]) begin
      if (exmem_out.Reg_WEn && exmem_out.RegIdx[IDX_RD] == idex_out.RegIdx[IDX_RS2]) begin
        Forward_B = MEM_TO_ALU;
      end else if (memwb_out.Reg_WEn && memwb_out.RD_Addr == idex_out.RegIdx[IDX_RS2]) begin
        Forward_B = WB_TO_ALU;
      end else Forward_B = NO_FWD;
    end else Forward_B = NO_FWD;

  end

endmodule
