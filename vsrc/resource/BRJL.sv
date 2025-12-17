`include "pipeline_pkg.sv"

module BRJL
  import pipeline_pkg::*;
(
    input [DATA_WIDTH-1:0] pc,
    input [2:0] specinst,
    input [DATA_WIDTH-1:0] rs1,
    input [DATA_WIDTH-1:0] imme,

    output logic [DATA_WIDTH-1:0] taken,
    output logic [DATA_WIDTH-1:0] none_taken
);

  /* Enum Specific Inst */
  parameter S_BR = 0, S_JAL = 1, S_JALR = 2;

  assign none_taken = pc + 4;

  wire [DATA_WIDTH-1:0] imme_dst = pc + imme;
  wire [DATA_WIDTH-1:0] reg_dst = (imme + rs1) & ~64'h1;

  always_comb begin
    case (specinst)
      S_BR: taken = imme_dst;
      S_JAL: taken = imme_dst;
      S_JALR: taken = reg_dst;
      default: taken = 0;
    endcase
  end

endmodule
