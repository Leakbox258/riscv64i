`include "pipeline_pkg.sv"

module Forward
  import pipeline_pkg::*;
(
    input EnRs1_ex,
    input EnRs2_ex,
    input EnMemW_ex,
    input [RF_SIZE-1:0] Rs1Idx_ex,
    input [RF_SIZE-1:0] Rs2Idx_ex,

    input EnRegW_mem1,
    input EnMemW_mem1,
    input EnMemR_mem1,
    input [RF_SIZE-1:0] RdIdx_mem1,
    input [RF_SIZE-1:0] RstoreIdx_mem1,

    input EnRegW_mem2,
    input EnMemR_mem2,
    input [RF_SIZE-1:0] RdIdx_mem2,

    input EnRegW_mem3,
    input [RF_SIZE-1:0] RdIdx_mem3,

    input EnRegW_wb,
    input [RF_SIZE-1:0] RdIdx_wb,

    output logic [2:0] Forward_A_Ex,
    output logic [2:0] Forward_B_Ex,
    output logic [2:0] Forward_Store_Ex,

    output logic [2:0] Forward_Store_Mem1
);

  always_comb begin

    if (EnRs1_ex) begin
      if (EnRegW_mem1 && !EnMemR_mem1 && RdIdx_mem1 == Rs1Idx_ex) begin
        Forward_A_Ex = MEM1_TO_ALU;
      end else if (EnRegW_mem2 && !EnMemR_mem2 && RdIdx_mem2 == Rs1Idx_ex) begin
        Forward_A_Ex = MEM2_TO_ALU;
      end else if (EnRegW_mem3 && RdIdx_mem3 == Rs1Idx_ex) begin
        Forward_A_Ex = MEM3_TO_ALU;
      end else if (EnRegW_wb && RdIdx_wb == Rs1Idx_ex) begin
        Forward_A_Ex = WB_TO_ALU;
      end else Forward_A_Ex = NO_FWD;
    end else Forward_A_Ex = NO_FWD;

  end

  always_comb begin

    if (EnRs2_ex) begin
      if (EnRegW_mem1 && !EnMemR_mem1 && RdIdx_mem1 == Rs2Idx_ex) begin
        Forward_B_Ex = MEM1_TO_ALU;
      end else if (EnRegW_mem2 && !EnMemR_mem2 && RdIdx_mem2 == Rs2Idx_ex) begin
        Forward_B_Ex = MEM2_TO_ALU;
      end else if (EnRegW_mem3 && RdIdx_mem3 == Rs2Idx_ex) begin
        Forward_B_Ex = MEM3_TO_ALU;
      end else if (EnRegW_wb && RdIdx_wb == Rs2Idx_ex) begin
        Forward_B_Ex = WB_TO_ALU;
      end else Forward_B_Ex = NO_FWD;
    end else Forward_B_Ex = NO_FWD;

  end

  always_comb begin

    if (EnMemW_ex) begin
      if (EnRegW_mem1 && !EnMemR_mem1 && RdIdx_mem1 == Rs2Idx_ex) begin
        Forward_Store_Ex = MEM1_TO_ALU;
      end else if (EnRegW_mem2 && !EnMemR_mem2 && RdIdx_mem2 == Rs2Idx_ex) begin
        Forward_Store_Ex = MEM2_TO_ALU;
      end else if (EnRegW_mem3 && RdIdx_mem3 == Rs2Idx_ex) begin
        Forward_Store_Ex = MEM3_TO_ALU;
      end else if (EnRegW_wb && RdIdx_wb == Rs2Idx_ex) begin
        Forward_Store_Ex = WB_TO_ALU;
      end else Forward_Store_Ex = NO_FWD;
    end else Forward_Store_Ex = NO_FWD;

  end

  always_comb begin
    if (EnMemW_mem1) begin

      if (EnRegW_mem2 && !EnMemR_mem2 && RdIdx_mem2 == RstoreIdx_mem1) begin
        Forward_Store_Mem1 = MEM2_TO_MEM1;
      end else if (EnRegW_mem3 && RdIdx_mem3 == RstoreIdx_mem1) begin
        Forward_Store_Mem1 = MEM3_TO_MEM1;
      end else if (EnRegW_wb && RdIdx_wb == RstoreIdx_mem1) begin
        Forward_Store_Mem1 = WB_TO_MEM1;
      end else Forward_Store_Mem1 = NO_FWD;
    end else Forward_Store_Mem1 = NO_FWD;
  end

endmodule
