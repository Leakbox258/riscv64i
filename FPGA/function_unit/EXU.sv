module EXU #(
    DATA_WIDTH = 64
) (

    /* controls */
    input ers1,
    input ers2,
    input [2:0] specinst,

    /* resources */
    input [DATA_WIDTH-1:0] rs1,
    input [DATA_WIDTH-1:0] rs2,
    input [DATA_WIDTH-1:0] pc,
    input [DATA_WIDTH-1:0] imme,

    output reg [DATA_WIDTH-1:0] alu_A,
    output reg [DATA_WIDTH-1:0] alu_B
);

  /* Enum Specific Inst */
  parameter JAL = 1, JALR = 2, AUIPC = 3, LUI = 4, STORE = 5;

  always_comb begin

    /// drive alu_A
    if (ers1) alu_A = rs1;
    else if (specinst == AUIPC) alu_A = pc;  // PC + (imm << 12)
    else if (specinst == JAL) alu_A = pc;
    else if (specinst == JALR) alu_A = pc;
    else alu_A = 0;

    /// drive alu_B
    if (ers2) begin
      if (specinst == STORE) alu_B = imme;  // offset
      else alu_B = rs2;
    end else if (specinst == LUI) alu_B = imme;
    else if (specinst == JAL) alu_B = 4;  // PC + 4
    else if (specinst == JALR) alu_B = 4;  // PC + 4
    else alu_B = imme;
  end

endmodule
