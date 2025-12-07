module ALU #(
    DATA_WIDTH = 64
) (
    input [DATA_WIDTH-1:0] A_i,
    input [DATA_WIDTH-1:0] B_i,
    input [3:0] opcode_i,
    output reg [DATA_WIDTH-1:0] C_o
);

  /* ALU opcode */
  parameter 	
  			ALU_ADD = 0, ALU_SUB = 1,
            ALU_OR = 2, ALU_AND = 3, ALU_XOR = 4, 
			ALU_SLL = 5, ALU_SRL = 6, ALU_SRA = 7,
            ALU_SLT = 8, ALU_SLTU = 9,
            ALU_COPY_B = 10,
			ALU_ADDW = 11, ALU_SUBW = 12,
			ALU_SLLW = 13, ALU_SRLW = 14, ALU_SRAW = 15;

  reg [DATA_WIDTH/2-1 : 0] intermedia;

  always @(*) begin
    intermedia = 0;

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
        C_o = $signed(A_i) >>> B_i[5:0];
      end
      ALU_SLT: begin
        C_o = {{DATA_WIDTH - 1{1'b0}}, $signed(A_i) < $signed(B_i)};
      end
      ALU_SLTU: begin
        C_o = {{DATA_WIDTH - 1{1'b0}}, A_i < B_i};
      end
      ALU_COPY_B: begin
        C_o = B_i;
      end
      ALU_ADDW: begin
        intermedia = A_i[DATA_WIDTH/2-1:0] + B_i[DATA_WIDTH/2-1:0];
        C_o = {{DATA_WIDTH / 2{intermedia[DATA_WIDTH/2-1]}}, intermedia};
      end
      ALU_SUBW: begin
        intermedia = A_i[DATA_WIDTH/2-1:0] + B_i[DATA_WIDTH/2-1:0];
        C_o = {{DATA_WIDTH / 2{intermedia[DATA_WIDTH/2-1]}}, intermedia};
      end
      ALU_SLLW: begin
        intermedia = A_i[DATA_WIDTH/2-1:0] << B_i[4:0];
        C_o = {{DATA_WIDTH / 2{intermedia[DATA_WIDTH/2-1]}}, intermedia};
      end
      ALU_SRLW: begin
        intermedia = A_i[DATA_WIDTH/2-1:0] >> B_i[4:0];
        C_o = {{DATA_WIDTH / 2{intermedia[DATA_WIDTH/2-1]}}, intermedia};
      end
      ALU_SRAW: begin
        intermedia = $signed(A_i[DATA_WIDTH/2-1:0]) >> B_i[4:0];
        C_o = {{DATA_WIDTH / 2{intermedia[DATA_WIDTH/2-1]}}, intermedia};
      end
    endcase
  end

endmodule

