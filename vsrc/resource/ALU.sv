`include "utils_pkg.sv"
module ALU
  import utils_pkg::*;
(
    input [DATA_WIDTH-1:0] A_i,
    input [DATA_WIDTH-1:0] B_i,
    input [4:0] opcode_i,
    output logic [DATA_WIDTH-1:0] C_o,
    output logic cmp_o
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

  /// Adder
  logic [DATA_WIDTH-1:0] Lhs, Rhs;
  assign Lhs = A_i;
  assign Rhs = (opcode_i == ALU_ADD || opcode_i == ALU_ADDW) ? B_i : ~B_i + 1;

  logic [DATA_WIDTH/2-1:0] add32;
  logic carry;
  assign {carry, add32} = {1'b0, Lhs[DATA_WIDTH/2-1:0]} + {1'b0, Rhs[DATA_WIDTH/2-1:0]};

  logic [DATA_WIDTH-1:0] add64;
  assign add64 = {
    Lhs[DATA_WIDTH-1:DATA_WIDTH/2] + Rhs[DATA_WIDTH-1:DATA_WIDTH/2] + {31'b0, carry}, add32
  };

  /// Shifter
  logic fillbit;
  always_comb begin
    case (opcode_i)
      ALU_SRA:  fillbit = A_i[DATA_WIDTH-1];
      ALU_SRAW: fillbit = A_i[DATA_WIDTH/2-1];
      default:  fillbit = 1'b0;
    endcase
  end

  logic [5:0] shamt;
  assign shamt = (opcode_i == ALU_SLL || opcode_i == ALU_SRL || opcode_i == ALU_SRA) ? B_i[5:0]: {1'b0, B_i[4:0]};

  logic [DATA_WIDTH-1:0] shed;
  always_comb begin
    case (opcode_i)
      ALU_SLL: begin
        for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
          shed[i] = A_i[DATA_WIDTH-1-i];
        end
      end
      ALU_SLLW: begin
        for (int i = 0; i < DATA_WIDTH / 2; i = i + 1) begin
          shed[i] = A_i[DATA_WIDTH/2-1-i];
        end
        shed[DATA_WIDTH-1:DATA_WIDTH/2] = 32'b0;
      end
      ALU_SRLW: begin
        shed = zext_32(A_i[DATA_WIDTH/2-1:0]);
      end
      ALU_SRAW: begin
        shed = sext_32(A_i[DATA_WIDTH/2-1:0]);
      end
      default: begin
        shed = A_i;
      end
    endcase
  end

  logic [DATA_WIDTH:0] shift;
  assign shift = $signed({fillbit, shed}) >>> shamt;
  logic [DATA_WIDTH-1:0] shift64;
  always_comb begin
    case (opcode_i)
      ALU_SLL: begin
        for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
          shift64[i] = shift[DATA_WIDTH-1-i];  // skip shift[DATA_WIDTH]
        end
      end
      ALU_SLLW: begin
        for (int i = 0; i < DATA_WIDTH / 2; i = i + 1) begin
          shift64[i] = A_i[DATA_WIDTH/2-1-i];
        end
        shift64[DATA_WIDTH-1:DATA_WIDTH/2] = 32'b0;
      end
      default: begin
        shift64 = shift[DATA_WIDTH-1:0];
      end
    endcase
  end
  logic [DATA_WIDTH/2-1:0] shift32;
  assign shift32 = shift64[DATA_WIDTH/2-1:0];

  /// XOR
  logic [DATA_WIDTH-1:0] xor64;
  assign xor64 = A_i ^ B_i;

  /// Mux
  always_comb begin

    case (opcode_i)
      ALU_ADD: begin
        C_o = add64;
      end
      ALU_SUB: begin
        C_o = add64;
      end
      ALU_OR: begin
        C_o = A_i | B_i;
      end
      ALU_AND: begin
        C_o = A_i & B_i;
      end
      ALU_XOR: begin
        C_o = xor64;
      end
      ALU_SLL: begin
        /// RV64I
        C_o = shift64;
      end
      ALU_SRL: begin
        /// RV64I
        C_o = shift64;  /// TODO: need extra testcase
      end
      ALU_SRA: begin
        /// RV64I
        C_o = shift64;  /// TODO: need extra testcase
      end
      ALU_EQ: begin
        C_o = {{DATA_WIDTH - 1{1'b0}}, xor64 == 0};
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
        C_o = sext_32(add32);
      end
      ALU_SUBW: begin
        C_o = sext_32(add32);
      end
      ALU_SLLW: begin
        C_o = sext_32(shift32);  /// TODO: need extra testcase
      end
      ALU_SRLW: begin
        C_o = sext_32(shift32);
      end
      ALU_SRAW: begin
        C_o = sext_32(shift32);
      end
      default: begin
        C_o = 0;
      end
    endcase
  end

  always_comb begin
    case (opcode_i)
      ALU_EQ: begin
        cmp_o = xor64 == 0;
      end
      ALU_SLT: begin
        cmp_o = signed_slt(A_i, B_i);
      end
      ALU_SLTU: begin
        cmp_o = A_i < B_i;
      end
      default: cmp_o = 1'b0;
    endcase
  end

endmodule
