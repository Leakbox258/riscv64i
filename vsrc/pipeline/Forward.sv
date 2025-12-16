`include "pipeline_pkg.sv"

module Forward
  import pipeline_pkg::*;
(
    input EnRs1_ex,
    input EnRs2_ex,
    input EnMemW_ex,

    input EnRegW_mem,
    input [RF_SIZE-1:0] RdIdx_mem,
    input EnRegW_wb,
    input [RF_SIZE-1:0] RdIdx_wb,
    input [RF_SIZE-1:0] Rs1Idx_ex,
    input [RF_SIZE-1:0] Rs2Idx_ex,

    output logic [1:0] Forward_A,
    output logic [1:0] Forward_B,
    output logic [1:0] Forward_Store
);

  always_comb begin

    if (EnRs1_ex) begin
      if (EnRegW_mem && RdIdx_mem == Rs1Idx_ex) begin
        Forward_A = MEM_TO_ALU;
      end else if (EnRegW_wb && RdIdx_wb == Rs1Idx_ex) begin
        Forward_A = WB_TO_ALU;
      end else Forward_A = NO_FWD;
    end else Forward_A = NO_FWD;

  end

  always_comb begin

    if (EnRs2_ex) begin
      if (EnRegW_mem && RdIdx_mem == Rs2Idx_ex) begin
        Forward_B = MEM_TO_ALU;
      end else if (EnRegW_wb && RdIdx_wb == Rs2Idx_ex) begin
        Forward_B = WB_TO_ALU;
      end else Forward_B = NO_FWD;
    end else Forward_B = NO_FWD;

  end


  always_comb begin
    if (EnMemW_ex) begin
      if (EnRegW_mem && RdIdx_mem == Rs2Idx_ex) begin
        Forward_Store = MEM_TO_ALU;
      end else if (EnRegW_wb && RdIdx_wb == Rs2Idx_ex) begin
        Forward_Store = WB_TO_ALU;
      end else Forward_Store = NO_FWD;
    end else Forward_Store = NO_FWD;

  end
endmodule
