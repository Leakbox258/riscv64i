module IDU #(
    INST_WIDTH = 32,
    RF_SIZE = 5
) (
    input [INST_WIDTH-1:0] inst_i,

    /* controls */
    output reg [4:0] enable_o,

    output reg [3:0] aluop_o,
    output reg [2:0] specinst_o,

    /* resources */
    output [2:0][RF_SIZE-1:0] regi_o,
    output [2:0] detail_o,

    output reg decode_error_o,
    output reg [1:0] env_exception_o  // ebreak, ecall 
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
            ALU_SLT = 8, ALU_SLTU = 9,
            ALU_COPY_B = 10,
			ALU_ADDW = 11, ALU_SUBW = 12,
			ALU_SLLW = 13, ALU_SRLW = 14, ALU_SRAW = 15;

  /* Enable params */
  parameter RS1 = 0, RS2 = 1, RD = 2, MREAD = 3, MWRITE = 4;

  /* Enum Specific Inst */
  parameter BR = 0, JAL = 1, JALR = 2, AUIPC = 3, LUI = 4, STORE = 5, LOAD = 6, NO_SPEC = 7;

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  /// extract the elems from encode or set default
  wire [ 6:0] opcode;
  wire [ 2:0] funct3;
  wire [ 5:0] funct6;
  wire [ 6:0] funct7;
  wire [11:0] funct12;
  reg  [ 2:0] decode_error;

  assign opcode = inst_i[6:0];
  assign funct3 = inst_i[14:12];
  assign funct6 = inst_i[31:26];
  assign funct7 = inst_i[31:25];
  assign funct12 = inst_i[31:20];

  assign regi_o[RD] = inst_i[11:7];
  assign regi_o[RS1] = inst_i[19:15];
  assign regi_o[RS2] = inst_i[24:20];
  assign detail_o = funct3;

  assign decode_error_o = |decode_error;

  /// get alu control signals 
  always_comb begin
    /// set default value
    enable_o = 5'b0;

    specinst_o = NO_SPEC;

    decode_error[1:0] = 2'b0;
    env_exception_o = 2'b00;

    case (opcode)
      Rty: begin
        enable_o[RD]  = 1;
        enable_o[RS1] = 1;
        enable_o[RS2] = 1;
      end
      Ity: begin
        enable_o[RD]  = 1;
        enable_o[RS1] = 1;
      end
      R64ty: begin
        enable_o[RD]  = 1;
        enable_o[RS1] = 1;
        enable_o[RS2] = 1;
      end
      I64ty: begin
        enable_o[RD]  = 1;
        enable_o[RS1] = 1;
      end
      Load: begin
        enable_o[RD] = 1;
        enable_o[RS1] = 1;
        // calculate address
        enable_o[MREAD] = 1;

        if (funct3 == 3'b111) decode_error[1] = 1;

        specinst_o = LOAD;
      end
      Store: begin
        enable_o[RS1] = 1;
        enable_o[RS2] = 1;
        // calculate addresss
        enable_o[MWRITE] = 1;

        if (funct3 == 3'b111) decode_error[1] = 1;

        specinst_o = STORE;
      end
      Branch: begin
        enable_o[RS1] = 1;
        enable_o[RS2] = 1;
        specinst_o = BR;
      end
      Jal: begin
        enable_o[RD] = 1;
        specinst_o   = JAL;
      end
      Jalr: begin
        enable_o[RD] = 1;
        enable_o[RS1] = 1;
        // calculate address
        specinst_o = JALR;
      end
      Auipc: begin
        enable_o[RD] = 1;

        specinst_o   = AUIPC;
      end
      Lui: begin
        enable_o[RD] = 1;

        specinst_o   = LUI;
      end
      Env: begin
        env_exception_o[0] = funct12 == 12'b0;
        env_exception_o[1] = funct12 == 12'b1;
      end
      default: decode_error[0] = 1;
    endcase
  end

  /// get alu opcode
  always_comb begin
    decode_error[2] = 0;

    case (opcode)

      Rty: begin  // R-type
        case (funct3)
          3'b000: aluop_o = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
          3'b111: aluop_o = ALU_AND;
          3'b110: aluop_o = ALU_OR;
          3'b100: aluop_o = ALU_XOR;
          3'b010: aluop_o = ALU_SLT;
          3'b011: aluop_o = ALU_SLTU;
          3'b001: aluop_o = ALU_SLL;
          3'b101: aluop_o = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
        endcase
      end

      Ity: begin  // I-type immediate ALU
        case (funct3)
          3'b000: aluop_o = ALU_ADD;  // ADDI
          3'b111: aluop_o = ALU_AND;
          3'b110: aluop_o = ALU_OR;
          3'b100: aluop_o = ALU_XOR;
          3'b010: aluop_o = ALU_SLT;
          3'b011: aluop_o = ALU_SLTU;
          3'b001: aluop_o = ALU_SLL;  // SLLI
          3'b101: aluop_o = (funct6 == 6'b010000) ? ALU_SRA : ALU_SRL;  // SRAI / SRLI
        endcase
      end

      R64ty: begin
        case (funct3)
          3'b000:  aluop_o = (funct7 == 7'b0) ? ALU_ADDW : ALU_SUBW;
          3'b001:  aluop_o = ALU_SLLW;
          3'b101:  aluop_o = (funct7 == 7'b0) ? ALU_SRLW : ALU_SRAW;
          default: aluop_o = ALU_ADD;
        endcase
      end

      I64ty: begin
        case (funct3)
          3'b000:  aluop_o = ALU_ADDW;
          3'b001:  aluop_o = ALU_SLLW;
          3'b101:  aluop_o = (funct7 == 7'b0) ? ALU_SRLW : ALU_SRAW;
          default: aluop_o = ALU_ADD;
        endcase
      end

      Lui: aluop_o = ALU_COPY_B;  // LUI
      Auipc: aluop_o = ALU_ADD;  // AUIPC (PC + imm)
      Jal: aluop_o = ALU_ADD;  // JAL (PC + 4)
      Jalr: aluop_o = ALU_ADD;  // JALR (PC + 4)
      Load: aluop_o = ALU_ADD;  // Load (base + offset)
      Store: aluop_o = ALU_ADD;  // Store (base + offset)
      Branch: begin  // Branch (comparison)
        case (funct3)
          B_EQ: aluop_o = ALU_SUB;
          B_NE: aluop_o = ALU_SUB;
          B_LT: aluop_o = ALU_SLT;
          B_GE: aluop_o = ALU_SLT;
          B_LTU: aluop_o = ALU_SLTU;
          B_GEU: aluop_o = ALU_SLTU;
          default: decode_error[2] = 1;
        endcase
      end
      default: aluop_o = ALU_ADD;
    endcase
  end

endmodule
