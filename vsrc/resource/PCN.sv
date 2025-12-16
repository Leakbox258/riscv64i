module PCN #(
    DATA_WIDTH = 64
) (
    input [2:0] specinst_i,
    input [2:0] detail_i,

    input [DATA_WIDTH-1:0] pc_i,
    input [DATA_WIDTH-1:0] rs1_i,
    input [DATA_WIDTH-1:0] imme_i,
    input [DATA_WIDTH-1:0] aluout_i,


    output reg [DATA_WIDTH-1:0] pcn_o
);

  parameter S_BR = 0, S_JAL = 1, S_JALR = 2;

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  always_comb begin
    pcn_o = pc_i + 4;
    if (specinst_i == S_BR) begin
      case (detail_i)
        B_EQ: begin
          /// ALU_SUB
          if (aluout_i == 0) pcn_o = pc_i + imme_i;
        end
        B_NE: begin
          /// ALU_SUB
          if (aluout_i != 0) pcn_o = pc_i + imme_i;
        end
        B_LT: begin
          /// ALU_SLT
          if (aluout_i == 1) pcn_o = pc_i + imme_i;
        end
        B_GE: begin
          /// ALU_SLT
          if (aluout_i == 0) pcn_o = pc_i + imme_i;
        end
        B_LTU: begin
          /// ALU_SLTU
          if (aluout_i == 1) pcn_o = pc_i + imme_i;
        end
        B_GEU: begin
          /// ALU_SLTU
          if (aluout_i == 0) pcn_o = pc_i + imme_i;
        end
        default:  /**/;
      endcase
    end else if (specinst_i == S_JAL) begin
      pcn_o = imme_i + pc_i;
    end else if (specinst_i == S_JALR) begin
      pcn_o = (imme_i + rs1_i) & ~64'h1;
    end
  end

endmodule
