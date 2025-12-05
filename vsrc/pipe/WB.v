module WB #(
    DATA_WIDTH = 64
) (
    input [DATA_WIDTH-1:0] alu_C_i,
    input [DATA_WIDTH-1:0] pc_i,

    input br_i,
    input [2:0] brty_i,
    input jal_i,
    input jalr_i,

    input [DATA_WIDTH-1:0] imme_i,
    input [DATA_WIDTH-1:0] rs1_i,

    output reg [DATA_WIDTH-1:0] new_pc_o,
    output execute_error_o
);

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  always @(*) begin
    /// update pc
    new_pc_o = pc_i + 4;

    execute_error_o = 0;

    if (br_i) begin
      case (brty_i)
        B_EQ: begin
          /// ALU_SUB
          if (alu_C_i == 0) new_pc_o = pc_i + imme_i;
        end
        B_NE: begin
          /// ALU_SUB
          if (alu_C_i != 0) new_pc_o = pc_i + imme_i;
        end
        B_LT: begin
          /// ALU_SLT
          if (alu_C_i == 1) new_pc_o = pc_i + imme_i;
        end
        B_GE: begin
          /// ALU_SLT
          if (alu_C_i == 0) new_pc_o = pc_i + imme_i;
        end
        B_LTU: begin
          /// ALU_SLTU
          if (alu_C_i == 1) new_pc_o = pc_i + imme_i;
        end
        B_GEU: begin
          /// ALU_SLTU
          if (alu_C_i == 0) new_pc_o = pc_i + imme_i;
        end
        default: execute_error_o = 1;
      endcase
    end else if (jal_i) begin
      new_pc_o = imme_i + pc_i;
    end else if (jalr_i) begin
      new_pc_o = rs1_i;
    end
  end

endmodule
