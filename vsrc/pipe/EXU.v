module EXU #(
    DATA_WIDTH = 64,
    RF_SIZE = 5,
    RAM_SIZE = 12
) (
    input clk,

    /* controls */
    input rd_enable_i,
    input rs1_enable_i,
    input rs2_enable_i,
    input memread_i,
    input memwrite_i,
    input [3:0] alu_op_i,
    input alu_2nd_src_i,
    input br_i,
    input jal_i,
    input jalr_i,
    input auipc_i,
    // input lui_i,

    /* resources */
    input [RF_SIZE-1:0] rd_i,
    input [RF_SIZE-1:0] rs1_i,
    input [RF_SIZE-1:0] rs2_i,

    input [DATA_WIDTH-1:0] pc_i,

    input [DATA_WIDTH-1:0] imme_i,

    input [2:0] memwid_i,
    input [2:0] brty_i,

    output reg [DATA_WIDTH-1:0] new_pc_o,
    output [1:0] execute_error_o  // one-hot
);

  /* Enum illegal instruction type */
  parameter MEM_ACCESS_ERROR = 0, UNKNOWN_BRTY = 1;

  /// Read & Write Register
  reg [DATA_WIDTH-1:0] rs1_data, rs2_data;
  reg reg_write_enable;
  GPR #(DATA_WIDTH, RF_SIZE) RvGpr (
      .clk(clk),
      .rs1_i(rs1_i),
      .rs2_i(rs2_i),
      .rd_i(rd_i),
      .write_enable_i(reg_write_enable),
      .data_i(alu_C),  // from ALU

      .rs1_data_o(rs1_data),
      .rs2_data_o(rs2_data)
  );

  /// Memory Read || Write
  parameter RAM_NONE = 0, RAM_READ = 1, RAM_WRITE = 2;

  reg [RAM_SIZE-1:0] mem_addr;
  reg [DATA_WIDTH-1:0] mem_writein;
  reg [DATA_WIDTH-1:0] mem_readout;
  wire mem_access_error;

  RAM #(DATA_WIDTH, RAM_SIZE) RegisterFile (
      .clk(clk),
      .addr_i(mem_addr),
      .access_mode_i(memread_i ? RAM_READ : (memwrite_i ? RAM_WRITE : RAM_NONE)),
      .data_i(mem_writein),
      .memwid_i(memwid_i),

      .data_o(mem_readout),
      .illegal_access_o(mem_access_error)
  );

  assign execute_error_o[MEM_ACCESS_ERROR] = mem_access_error && (memread_i || memwrite_i);

  /// ALU 
  reg [DATA_WIDTH -1:0] alu_A, alu_B;
  reg [DATA_WIDTH -1:0] alu_C;

  ALU #(DATA_WIDTH) Alu (
      .A_i(alu_A),
      .B_i(alu_B),
      .opcode_i(alu_op_i),
      .C_o(alu_C)
  );

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  always @(*) begin
    /// drive reg_write_enable
    reg_write_enable = rd_enable_i;

    /// drive mem_addr
    /// TODO: convertion virtual -> physical
    mem_addr = rs1_data[RAM_SIZE-1:0] + imme_i[RAM_SIZE-1:0];

    /// drive mem_writein
    mem_writein = rs2_data;

    /// drive alu_A
    if (rs1_enable_i) alu_A = rs1_data;
    else if (jal_i) alu_A = pc_i;
    else if (jalr_i) alu_A = pc_i;
    else if (auipc_i) alu_A = pc_i;  // PC + (imm << 12)
    else alu_A = 0;

    /// drive alu_B`
    if (rs2_enable_i) alu_B = rs2_data;
    else if (alu_2nd_src_i) alu_B = imme_i;
    else if (jal_i) alu_B = 4;  // PC + 4
    else if (jalr_i) alu_B = 4;  // PC + 4
    else if (memread_i) alu_B = mem_readout;
    else alu_B = 0;
  end

  always @(*) begin
    /// update pc
    new_pc_o = pc_i + 4;

    execute_error_o[UNKNOWN_BRTY] = 0;

    if (br_i) begin
      case (brty_i)
        B_EQ: begin
          /// ALU_SUB
          if (alu_C == 0) new_pc_o = pc_i + imme_i;
        end
        B_NE: begin
          /// ALU_SUB
          if (alu_C != 0) new_pc_o = pc_i + imme_i;
        end
        B_LT: begin
          /// ALU_SLT
          if (alu_C == 1) new_pc_o = pc_i + imme_i;
        end
        B_GE: begin
          /// ALU_SLT
          if (alu_C == 0) new_pc_o = pc_i + imme_i;
        end
        B_LTU: begin
          /// ALU_SLTU
          if (alu_C == 1) new_pc_o = pc_i + imme_i;
        end
        B_GEU: begin
          /// ALU_SLTU
          if (alu_C == 0) new_pc_o = pc_i + imme_i;
        end
        default: execute_error_o[UNKNOWN_BRTY] = 1;
      endcase
    end else if (jal_i) begin
      new_pc_o = imme_i + pc_i;
    end else if (jalr_i) begin
      new_pc_o = rs1_data;
    end
  end

  //   initial begin
  //     $monitor("T=%0t | IsJal: %d | IsJalr: %d | last_imme: %h | cur PC: %h | next PC: %h", $time,
  //              jal_i, jalr_i, imme_i, pc_i, new_pc_o);
  //   end

endmodule
