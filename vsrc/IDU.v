module IDU #(
    DATA_LEN = 64,
    RF_SIZE  = 5
) (
    input [31:0] inst_i,

    /* controls */
    output reg rd_enable_o,
    output reg rs1_enable_o,
    output reg rs2_enable_o,
    output reg memread_o,
    output reg memwrite_o,
    output reg [1:0] writeback_to_o,
    output reg [3:0] alu_op_o,
    output reg alu_2nd_src_o,
    output reg branch_o,
    output reg jal_o,
    output reg jalr_o,
    output reg auipc_o,
    output reg lui_o,
    output reg inst_illegal_o,

    /* resources */
    output [RF_SIZE-1:0] rd_o,
    output [RF_SIZE-1:0] rs1_o,
    output [RF_SIZE-1:0] rs2_o,
    output [2:0] memwid_o,
    output [2:0] brty_o,

    output [DATA_LEN-1:0] imme_o
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
				Fence = 7'h0f,
				System = 7'h73,
				R64ty = 7'h3b,
				I64ty = 7'h1b; // 13

  /* Write Back to Target from Where */
  parameter WB_ALU = 0, WB_MEM = 1, WB_Next_PC = 2, WB_None = 3;

  /* ALU opcode */
  parameter 	
  			ALU_ADD = 0, ALU_SUB = 1,
            ALU_OR = 2, ALU_AND = 3, ALU_XOR = 4, 
			ALU_SLL = 5, ALU_SRL = 6, ALU_SRA = 7,
            ALU_SLT = 8, ALU_SLTU = 9,
            ALU_COPY_B = 10,
			ALU_ADDW = 11, ALU_SUBW = 12,
			ALU_SLLW = 13, ALU_SRLW = 14, ALU_SRAW = 15;

  /// extract the elems from encode or set default
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [5:0] funct6;
  wire [6:0] funct7;

  assign opcode = inst_i[6:0];
  assign funct3 = inst_i[14:12];
  assign funct6 = inst_i[31:26];
  assign funct7 = inst_i[31:25];

  assign rd_o = inst_i[11:7];
  assign rs1_o = inst_i[19:15];
  assign rs2_o = inst_i[24:20];
  assign memwid_o = funct3;
  assign brty_o = funct3;

  IMMGen immeGen (
      .inst_i(inst_i),
      .imme_o(imme_o)
  );

  /// get alu control signals 
  always @(*) begin
    /// set default value
    rd_enable_o = 0;
    rs1_enable_o = 0;
    rs2_enable_o = 0;

    alu_2nd_src_o = 0;

    memread_o = 0;
    memwrite_o = 0;
    writeback_to_o = WB_None;
    branch_o = 0;
    jal_o = 0;
    jalr_o = 0;
    auipc_o = 0;
    lui_o = 0;

    inst_illegal_o = 0;

    case (opcode)
      Rty: begin
        rd_enable_o = 1;
        rs1_enable_o = 1;
        rs2_enable_o = 1;
        writeback_to_o = WB_ALU;
      end
      Ity: begin
        rd_enable_o = 1;
        rs1_enable_o = 1;
        alu_2nd_src_o = 1;
        writeback_to_o = WB_ALU;
      end
      R64ty: begin
        rd_enable_o = 1;
        rs1_enable_o = 1;
        rs2_enable_o = 1;
        writeback_to_o = WB_ALU;
      end
      I64ty: begin
        rd_enable_o = 1;
        rs1_enable_o = 1;
        alu_2nd_src_o = 1;
        writeback_to_o = WB_ALU;
      end
      Load: begin
        rd_enable_o = 1;
        rs1_enable_o = 1;
        alu_2nd_src_o = 1;  // calculate address
        memread_o = 1;
        writeback_to_o = WB_MEM;
      end
      Store: begin
        rs2_enable_o = 1;
        rs1_enable_o = 1;
        alu_2nd_src_o = 1;  // calculate addresss
        memwrite_o = 1;
      end
      Branch: begin
        rs1_enable_o = 1;
        rs2_enable_o = 1;
        branch_o = 1;
      end
      Jal: begin
        rd_enable_o = 1;
        writeback_to_o = WB_Next_PC;
        jal_o = 1;
      end
      Jalr: begin
        rd_enable_o = 1;
        rs1_enable_o = 1;
        alu_2nd_src_o = 1;  // calculate address
        jalr_o = 1;
      end
      Auipc: begin
        rd_enable_o = 1;
        alu_2nd_src_o = 1;
        auipc_o = 1;
        writeback_to_o = WB_ALU;  // pc + (imm << 12)
      end
      Lui: begin
        rd_enable_o = 1;
        alu_2nd_src_o = 1;
        lui_o = 1;
        writeback_to_o = WB_ALU;  // imm << 12
      end
      Fence:   inst_illegal_o = 1;  // not supported yet
      System:  inst_illegal_o = 1;  // not supported yet
      default: inst_illegal_o = 1;
    endcase
  end

  /// get alu opcode
  always @(*) begin
    case (opcode)

      Rty: begin  // R-type
        case (funct3)
          3'b000: alu_op_o = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
          3'b111: alu_op_o = ALU_AND;
          3'b110: alu_op_o = ALU_OR;
          3'b100: alu_op_o = ALU_XOR;
          3'b010: alu_op_o = ALU_SLT;
          3'b011: alu_op_o = ALU_SLTU;
          3'b001: alu_op_o = ALU_SLL;
          3'b101: alu_op_o = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
        endcase
      end

      Ity: begin  // I-type immediate ALU
        case (funct3)
          3'b000: alu_op_o = ALU_ADD;  // ADDI
          3'b111: alu_op_o = ALU_AND;
          3'b110: alu_op_o = ALU_OR;
          3'b100: alu_op_o = ALU_XOR;
          3'b010: alu_op_o = ALU_SLT;
          3'b011: alu_op_o = ALU_SLTU;
          3'b001: alu_op_o = ALU_SLL;  // SLLI
          3'b101: alu_op_o = (funct6 == 6'b010000) ? ALU_SRA : ALU_SRL;  // SRAI / SRLI
        endcase
      end

      R64ty: begin
        case (funct3)
          3'b000:  alu_op_o = (funct7 == 7'b0000000) ? ALU_ADDW : ALU_SUBW;
          3'b001:  alu_op_o = ALU_SLLW;
          3'b101:  alu_op_o = (funct7 == 7'b0000000) ? ALU_SRLW : ALU_SRAW;
          default: alu_op_o = ALU_ADD;
        endcase
      end

      I64ty: begin
        case (funct3)
          3'b000:  alu_op_o = ALU_ADDW;
          3'b001:  alu_op_o = ALU_SLLW;
          3'b101:  alu_op_o = (funct7 == 7'b0000000) ? ALU_SRLW : ALU_SRAW;
          default: alu_op_o = ALU_ADD;
        endcase
      end

      Lui:    alu_op_o = ALU_COPY_B;  // LUI
      Auipc:  alu_op_o = ALU_ADD;     // AUIPC (PC + imm)
      Jal:    alu_op_o = ALU_ADD;     // JAL (PC + 4)
      Jalr:   alu_op_o = ALU_ADD;     // JALR (PC + 4)
      Load:   alu_op_o = ALU_ADD;     // Load (base + offset)
      Store:  alu_op_o = ALU_ADD;     // Store (base + offset)
      Branch: alu_op_o = ALU_SUB;     // Branch (comparison)
      default: alu_op_o = ALU_ADD;
    endcase
  end

endmodule
