module PCN #(
    DATA_WIDTH = 64
) (
    input [2:0] specinst_i,
    input [2:0] detail_i,

    input [DATA_WIDTH-1:0] take_target,
    input [DATA_WIDTH-1:0] nonetake_target,

    input cmp_i,

    output reg [DATA_WIDTH-1:0] pcn_o
);

  parameter S_BR = 0, S_JAL = 1, S_JALR = 2;

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  logic take_branch;

  always_comb begin
    take_branch = 1'b0;
    case (detail_i)
      B_EQ: take_branch = (cmp_i == 1);  // ALU_EQ
      B_NE: take_branch = (cmp_i == 0);
      B_LT: take_branch = (cmp_i == 1);  // ALU_SLT
      B_GE: take_branch = (cmp_i == 0);
      B_LTU: take_branch = (cmp_i == 1);  // ALU_SLTU
      B_GEU: take_branch = (cmp_i == 0);
      default: take_branch = 1'b0;
    endcase
  end

  always_comb begin
    case (specinst_i)
      S_BR: pcn_o = take_branch ? take_target : nonetake_target;
      S_JAL: pcn_o = take_target;
      S_JALR: pcn_o = take_target;
      default: pcn_o = nonetake_target;
    endcase
  end

endmodule
