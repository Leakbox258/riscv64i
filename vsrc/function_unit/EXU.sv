module EXU #(
    DATA_WIDTH = 64
) (

    /* controls */
    input ers1_i,
    input ers2_i,
    input [2:0] specinst_i,

    /* resources */
    input [DATA_WIDTH-1:0] rs1_i,
    input [DATA_WIDTH-1:0] rs2_i,
    input [DATA_WIDTH-1:0] pc_i,
    input [DATA_WIDTH-1:0] imme_i,

    output reg [DATA_WIDTH-1:0] alu_A_o,
    output reg [DATA_WIDTH-1:0] alu_B_o
);

  /* Enum Specific Inst */
  parameter JAL = 1, JALR = 2, AUIPC = 3, LUI = 4, STORE = 5;

  always_comb begin

    /// drive alu_A_o
    if (ers1_i) alu_A_o = rs1_i;
    else if (specinst_i == AUIPC) alu_A_o = pc_i;  // PC + (imm << 12)
    else if (specinst_i == JAL) alu_A_o = pc_i;
    else if (specinst_i == JALR) alu_A_o = rs1_i;
    else alu_A_o = 0;

    /// drive alu_B_o
    if (ers2_i) begin
      if (specinst_i == STORE) alu_B_o = imme_i;
      else alu_B_o = rs2_i;
    end else if (specinst_i == LUI) alu_B_o = imme_i;
    else if (specinst_i == JAL) alu_B_o = imme_i;  // PC + 4
    else if (specinst_i == JALR) alu_B_o = imme_i;  // PC + 4
    else alu_B_o = imme_i;
  end

  //   initial begin
  //     $monitor("T=%0t | IsJal: %d | IsJalr: %d | last_imme: %h | cur PC: %h | next PC: %h", $time,
  //              jal_i, jalr_i, imme_i, pc_i, new_pc_o);
  //   end

endmodule
