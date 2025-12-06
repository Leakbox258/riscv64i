module CPU #(
    DATA_WIDTH = 64,
    INST_WIDTH = 32,
    RF_SIZE = 5,
    RAM_SIZE = 12
) (
    input clk_i,
    input [DATA_WIDTH-1:0] pc_i,

    output [DATA_WIDTH-1:0] new_pc_o,
    output [5:0] interrupts_o
);
  parameter FetchError = 0, 
            DecodeError = 1,
            MemAccessError = 2,
            UnknownBrtyError = 3,
            ECALL = 4,
            EBREAK = 5;

  /// Internal wire
  wire [DATA_WIDTH-1:0] imme, mem_write, mem_read, alu_A, alu_B, alu_C, rs1_data, rs2_data;
  reg [DATA_WIDTH-1:0] comited_data;
  wire [INST_WIDTH-1:0] data, inst;
  wire [RF_SIZE-1:0] rd, rs1, rs2;
  wire [RAM_SIZE-1:0] memaddr = rs1_data[RAM_SIZE-1:0] + imme[RAM_SIZE-1:0]; // TODO: convertion virtual -> physical
  wire [2:0] memwid, brty;
  wire [3:0] alu_op;
  wire rd_enable, rs1_enable, rs2_enable, memread, memwrite, alu_2nd_src, branch, jal, jalr, auipc;

  wire mem_access_error;

  assign interrupts_o[MemAccessError] = mem_access_error && (memread || memwrite);
  assign mem_write = rs2_data;

  /// Temporal Logic

  CodeROM #(64, 32, 12) codeROM (
      .addr_i(pc_i),
      .data_o(data),
      .illegal_access_o(interrupts_o[FetchError])
  );

  RAM #(DATA_WIDTH, RAM_SIZE) RegisterFile (
      .clk(clk_i),
      .addr_i(memaddr),
      .read_i(memread),
      .write_i(memwrite),
      .data_i(mem_write),
      .wid_i(memwid),

      .data_o(mem_read),
      .illegal_access_o(mem_access_error)
  );

  GPR #(DATA_WIDTH, RF_SIZE) RvGpr (
      .clk(clk_i),
      .rs1_i(rs1),
      .rs2_i(rs2),
      .rd_i(rd),
      .write_enable_i(rd_enable),
      .data_i(comited_data),  // need commit unit (temporal logic)

      .rs1_data_o(rs1_data),
      .rs2_data_o(rs2_data)
  );

  /// Combination Logic
  IMMGen immeGen (
      .inst_i(inst),
      .imme_o(imme)
  );

  ALU #(DATA_WIDTH) Alu (
      .A_i(alu_A),
      .B_i(alu_B),
      .opcode_i(alu_op),
      .C_o(alu_C)
  );

  /// Pipeline

  IFU Ifu (
      .data_i(data),
      .inst_o(inst)
  );

  IDU Idu (
      .inst_i(inst),

      .rd_enable_o(rd_enable),
      .rs1_enable_o(rs1_enable),
      .rs2_enable_o(rs2_enable),
      .memread_o(memread),
      .memwrite_o(memwrite),
      .alu_op_o(alu_op),
      .alu_2nd_src_o(alu_2nd_src),
      .branch_o(branch),
      .jal_o(jal),
      .jalr_o(jalr),
      .auipc_o(auipc),

      .rd_o(rd),
      .rs1_o(rs1),
      .rs2_o(rs2),
      .memwid_o(memwid),
      .brty_o(brty),

      .decode_error_o(interrupts_o[DecodeError]),

      .env_interrupt_o(interrupts_o[EBREAK:ECALL])
  );

  EXU Exu (
      .rs1_enable_i(rs1_enable),
      .rs2_enable_i(rs2_enable),
      .alu_2nd_src_i(alu_2nd_src),
      .jal_i(jal),
      .jalr_i(jalr),
      .auipc_i(auipc),

      .rs1_i (rs1_data),
      .rs2_i (rs2_data),
      .pc_i  (pc_i),
      .imme_i(imme),

      .alu_A_o(alu_A),
      .alu_B_o(alu_B)
  );

  WB Wb (
      .alu_C_i(alu_C),
      .pc_i(pc_i),

      .br_i  (branch),
      .brty_i(brty),
      .jal_i (jal),
      .jalr_i(jalr),

      .imme_i(imme),
      .rs1_i (rs1_data),

      .new_pc_o(new_pc_o),
      .execute_error_o(interrupts_o[UnknownBrtyError])
  );

  initial begin
    $monitor("Inst: %h | imme: %h | cur PC: %h | next PC: %h", inst, imme, pc_i, new_pc_o);
  end

endmodule
