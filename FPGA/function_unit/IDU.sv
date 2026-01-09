module IDU #(
    INST_WIDTH = 32,
    RF_SIZE = 5
) (
    input [INST_WIDTH-1:0] rinst,

    /* controls */
    output reg [4:0] enables,

    output reg [4:0] aluop,
    output reg [2:0] specinst,

    /* resources */
    output [2:0][RF_SIZE-1:0] registers,
    output [2:0] details,

    output reg decode_error,
    output reg [1:0] env_exception  // ebreak, ecall 
);

  /* Instruction Type */
  parameter 	Rty = 7'h33, 
				Ity = 7'h13, 
				Load = 7'h03,
				Store = 7'h23, 
				Branch = 7'h63, 
				Jalr = 7'h67, 
				Jal = 7'h6f, 
				Auipc = 7'h17, 
				Lui = 7'h37, 
				Env = 7'h73,
  // R64/I64 means R/I-type inst involved by  rv64I, eg: addw/addiw
  R64ty = 7'h3b, I64ty = 7'h1b;

  /* ALU opcode */
  parameter 	
  			ALU_ADD = 0, ALU_SUB = 1,
            ALU_OR = 2, ALU_AND = 3, ALU_XOR = 4, 
			ALU_SLL = 5, ALU_SRL = 6, ALU_SRA = 7,
			ALU_EQ = 8, ALU_SLT = 9, ALU_SLTU = 10,
            ALU_COPY_B = 11,
			ALU_ADDW = 12, ALU_SUBW = 13,
			ALU_SLLW = 14, ALU_SRLW = 15, ALU_SRAW = 16;

  /* Enable params */
  parameter RS1 = 0, RS2 = 1, RD = 2, MREAD = 3, MWRITE = 4;

  /* Enum Specific Inst */
  parameter S_BR = 0, S_JAL = 1, S_JALR = 2, S_AUIPC = 3, S_LUI = 4, S_STORE = 5, S_LOAD = 6, NO_SPEC = 7;

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  /// extract the elems from encode or set default
  wire [ 6:0] opcode;
  wire [ 2:0] funct3;
  wire [ 5:0] funct6;
  wire [ 6:0] funct7;
  wire [11:0] funct12;
  reg  [ 2:0] decodeError;

  assign opcode = rinst[6:0];
  assign funct3 = rinst[14:12];
  assign funct6 = rinst[31:26];
  assign funct7 = rinst[31:25];
  assign funct12 = rinst[31:20];

  assign registers[RD] = rinst[11:7];
  assign registers[RS1] = rinst[19:15];
  assign registers[RS2] = rinst[24:20];
  assign details = funct3;

  assign decode_error = |decodeError;

  /// get alu control signals 
  always_comb begin
    /// set default value
    enables = 5'b0;

    specinst = NO_SPEC;

    decodeError[1:0] = 2'b0;
    env_exception = 2'b00;

    case (opcode)
      Rty: begin
        enables[RD]  = 1;
        enables[RS1] = 1;
        enables[RS2] = 1;
      end
      Ity: begin
        enables[RD]  = 1;
        enables[RS1] = 1;
      end
      R64ty: begin
        enables[RD]  = 1;
        enables[RS1] = 1;
        enables[RS2] = 1;
      end
      I64ty: begin
        enables[RD]  = 1;
        enables[RS1] = 1;
      end
      Load: begin
        enables[RD] = 1;
        enables[RS1] = 1;
        // calculate address
        enables[MREAD] = 1;

        if (funct3 == 3'b111) decodeError[1] = 1;

        specinst = S_LOAD;
      end
      Store: begin
        enables[RS1] = 1;
        enables[RS2] = 1;
        // calculate addresss
        enables[MWRITE] = 1;

        if (funct3 == 3'b111) decodeError[1] = 1;

        specinst = S_STORE;
      end
      Branch: begin
        enables[RS1] = 1;
        enables[RS2] = 1;
        specinst = S_BR;
      end
      Jal: begin
        enables[RD] = 1;
        specinst = S_JAL;
      end
      Jalr: begin
        enables[RD] = 1;
        enables[RS1] = 1;
        // calculate address
        specinst = S_JALR;
      end
      Auipc: begin
        enables[RD] = 1;

        specinst = S_AUIPC;
      end
      Lui: begin
        enables[RD] = 1;

        specinst = S_LUI;
      end
      Env: begin
        env_exception[0] = funct12 == 12'b0;
        env_exception[1] = funct12 == 12'b1;
      end
      default: decodeError[0] = 1;
    endcase
  end

  /// get alu opcode
  always_comb begin
    decodeError[2] = 0;
    aluop = ALU_ADD;

    case (opcode)

      Rty: begin  // R-type
        case (funct3)
          3'b000: aluop = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
          3'b111: aluop = ALU_AND;
          3'b110: aluop = ALU_OR;
          3'b100: aluop = ALU_XOR;
          3'b010: aluop = ALU_SLT;
          3'b011: aluop = ALU_SLTU;
          3'b001: aluop = ALU_SLL;
          3'b101: aluop = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
        endcase
      end

      Ity: begin  // I-type immediate ALU
        case (funct3)
          3'b000: aluop = ALU_ADD;  // ADDI
          3'b111: aluop = ALU_AND;
          3'b110: aluop = ALU_OR;
          3'b100: aluop = ALU_XOR;
          3'b010: aluop = ALU_SLT;
          3'b011: aluop = ALU_SLTU;
          3'b001: aluop = ALU_SLL;  // SLLI
          3'b101: aluop = (funct6 == 6'b010000) ? ALU_SRA : ALU_SRL;  // SRAI / SRLI
        endcase
      end

      R64ty: begin
        case (funct3)
          3'b000:  aluop = (funct7 == 7'b0) ? ALU_ADDW : ALU_SUBW;
          3'b001:  aluop = ALU_SLLW;
          3'b101:  aluop = (funct7 == 7'b0) ? ALU_SRLW : ALU_SRAW;
          default: aluop = ALU_ADD;
        endcase
      end

      I64ty: begin
        case (funct3)
          3'b000:  aluop = ALU_ADDW;
          3'b001:  aluop = ALU_SLLW;
          3'b101:  aluop = (funct7 == 7'b0) ? ALU_SRLW : ALU_SRAW;
          default: aluop = ALU_ADD;
        endcase
      end

      Lui: aluop = ALU_COPY_B;  // S_LUI
      Auipc: aluop = ALU_ADD;  // S_AUIPC (PC + imm)
      Jal: aluop = ALU_ADD;  // S_JAL (PC + 4)
      Jalr: aluop = ALU_ADD;  // S_JALR (PC + 4)
      Load: aluop = ALU_ADD;  // Load (base + offset)
      Store: aluop = ALU_ADD;  // Store (base + offset)
      Branch: begin  // Branch (comparison)
        case (funct3)
          B_EQ: aluop = ALU_EQ;
          B_NE: aluop = ALU_EQ;
          B_LT: aluop = ALU_SLT;
          B_GE: aluop = ALU_SLT;
          B_LTU: aluop = ALU_SLTU;
          B_GEU: aluop = ALU_SLTU;
          default: decodeError[2] = 1;
        endcase
      end
      default: ;
    endcase
  end

endmodule
