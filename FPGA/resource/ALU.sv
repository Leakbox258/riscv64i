`include "utils_pkg.sv"
module ALU
  import utils_pkg::*;
(
    input [DATA_WIDTH-1:0] A_i,
    input [DATA_WIDTH-1:0] B_i,
    input [4:0] opcode_i,
    output reg [DATA_WIDTH-1:0] C_o
);

  /* ALU opcode */
  parameter 	
  			ALU_ADD = 0, ALU_SUB = 1,
            ALU_OR = 2, ALU_AND = 3, ALU_XOR = 4, 
			ALU_SLL = 5, ALU_SRL = 6, ALU_SRA = 7,
			ALU_EQ = 8, ALU_SLT = 9, ALU_SLTU = 10,
            ALU_COPY_B = 11,
			ALU_ADDW = 12, ALU_SUBW = 13,
			ALU_SLLW = 14, ALU_SRLW = 15, ALU_SRAW = 16;

  always_comb begin

    case (opcode_i)
      ALU_ADD: begin
        C_o = A_i + B_i;
      end
      ALU_SUB: begin
        C_o = A_i - B_i;
      end
      ALU_OR: begin
        C_o = A_i | B_i;
      end
      ALU_AND: begin
        C_o = A_i & B_i;
      end
      ALU_XOR: begin
        C_o = A_i ^ B_i;
      end
      ALU_SLL: begin
        /// RV64I
        C_o = A_i << B_i[5:0];
      end
      ALU_SRL: begin
        /// RV64I
        C_o = A_i >> B_i[5:0];
      end
      ALU_SRA: begin
        /// RV64I
        C_o = sra_64(A_i, B_i[5:0]);
      end
      ALU_EQ: begin
        C_o = {{DATA_WIDTH - 1{1'b0}}, A_i == B_i};
      end
      ALU_SLT: begin
        C_o = {{DATA_WIDTH - 1{1'b0}}, signed_slt(A_i, B_i)};
      end
      ALU_SLTU: begin
        C_o = {{DATA_WIDTH - 1{1'b0}}, A_i < B_i};
      end
      ALU_COPY_B: begin
        C_o = B_i;
      end
      ALU_ADDW: begin
        C_o = sext_32(A_i[DATA_WIDTH/2-1:0] + B_i[DATA_WIDTH/2-1:0]);
      end
      ALU_SUBW: begin
        C_o = sext_32(A_i[DATA_WIDTH/2-1:0] - B_i[DATA_WIDTH/2-1:0]);
      end
      ALU_SLLW: begin
        C_o = sext_32(A_i[DATA_WIDTH/2-1:0] << B_i[4:0]);
      end
      ALU_SRLW: begin
        C_o = sext_32(A_i[DATA_WIDTH/2-1:0] >> B_i[4:0]);
      end
      ALU_SRAW: begin
        C_o = sext_32(sra_32(A_i[DATA_WIDTH/2-1:0], B_i[4:0]));
      end
      default: begin
        C_o = 0;
      end
    endcase
  end

endmodule

