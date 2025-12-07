module EXU #(
    DATA_WIDTH = 64
) (

    /* controls */
    input ers1_i,
    input ers2_i,
    input alusel2_i,
    input jal_i,
    input jalr_i,
    input auipc_i,

    /* resources */
    input [DATA_WIDTH-1:0] rs1_i,
    input [DATA_WIDTH-1:0] rs2_i,
    input [DATA_WIDTH-1:0] pc_i,
    input [DATA_WIDTH-1:0] imme_i,

    output reg [DATA_WIDTH-1:0] alu_A_o,
    output reg [DATA_WIDTH-1:0] alu_B_o
);

  always @(*) begin

    /// drive alu_A_o
    if (ers1_i) alu_A_o = rs1_i;
    else if (jal_i) alu_A_o = pc_i;
    else if (jalr_i) alu_A_o = pc_i;
    else if (auipc_i) alu_A_o = pc_i;  // PC + (imm << 12)
    else alu_A_o = 0;

    /// drive alu_B_o`
    if (ers2_i) alu_B_o = rs2_i;
    else if (alusel2_i) alu_B_o = imme_i;
    else if (jal_i) alu_B_o = 4;  // PC + 4
    else if (jalr_i) alu_B_o = 4;  // PC + 4
    else alu_B_o = 0;
  end

  //   initial begin
  //     $monitor("T=%0t | IsJal: %d | IsJalr: %d | last_imme: %h | cur PC: %h | next PC: %h", $time,
  //              jal_i, jalr_i, imme_i, pc_i, new_pc_o);
  //   end

endmodule
