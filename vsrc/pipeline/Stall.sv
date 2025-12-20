module Stall
  import pipeline_pkg::*;
(

    input logic EnMemR_ex,
    input logic [RF_SIZE-1:0] RdIdx_ex,

    input logic EnMemR_mem1,
    input logic [RF_SIZE-1:0] RdIdx_mem1,

    input logic EnMemR_mem2,
    input logic [RF_SIZE-1:0] RdIdx_mem2,

    input logic [RF_SIZE-1:0] Rs1Idx_id,
    input logic [RF_SIZE-1:0] Rs2Idx_id,

    output logic stall
);

  logic hazard_ex, hazard_mem1, hazard_mem2;

  assign hazard_ex   = EnMemR_ex   && (RdIdx_ex != 0)   && (RdIdx_ex == Rs1Idx_id || RdIdx_ex == Rs2Idx_id);
  assign hazard_mem1 = EnMemR_mem1 && (RdIdx_mem1 != 0) && (RdIdx_mem1 == Rs1Idx_id || RdIdx_mem1 == Rs2Idx_id);
  assign hazard_mem2 = EnMemR_mem2 && (RdIdx_mem2 != 0) && (RdIdx_mem2 == Rs1Idx_id || RdIdx_mem2 == Rs2Idx_id);

  assign stall = hazard_ex | hazard_mem1 | hazard_mem2;

endmodule
