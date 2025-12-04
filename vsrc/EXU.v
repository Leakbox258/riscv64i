module EXU #(
    DATA_LEN = 64,
    RF_SIZE  = 5,
    RAM_SIZE = 12
) (
    input clk,

    /* controls */
    input rd_enable_i,
    input rs1_enable_i,
    input rs2_enable_i,
    input memread_i,
    input memwrite_i,
    input [1:0] writeback_data_to_i,
    input [3:0] alu_op_i,
    input alu_2nd_src_i,
    input branch_i,
    input jal_i,
    input jalr_i,
    // input auipc_i,
    // input lui_i,
    // input inst_illegal_i,

    /* resources */
    input [RF_SIZE-1:0] rd_i,
    input [RF_SIZE-1:0] rs1_i,
    input [RF_SIZE-1:0] rs2_i,

    input [DATA_LEN-1:0] pc_i,

    input [DATA_LEN-1:0] imme_i,

    input [2:0] memwid_i,
    input [2:0] brty_i,

    output new_pc_o,
    output illegal_mem_access_o
);


  /// Read & Write Register
  reg [DATA_LEN-1:0] rs1_data, rs2_data;
  reg reg_write_enable;
  GPR #(DATA_LEN, RF_SIZE) RvGpr (
      .clk(clk),
      .rs1_i(rs1_i),
      .rs2_i(rs2_i),
      .rd_i(rd_i),
      .write_enable_i(reg_write_enable),
      .data_i(writeback_data),  // from ALU

      .rs1_data_o(rs1_data),
      .rs2_data_o(rs2_data)
  );

  /// Memory Read || Write
  parameter RAM_NONE = 0, RAM_READ = 1, RAM_WRITE = 2;

  reg [RAM_SIZE-1:0] mem_addr;
  reg [DATA_LEN-1:0] mem_writein;
  reg [DATA_LEN-1:0] mem_readout;
  RAM #(DATA_LEN, RAM_SIZE) RvRam (
      .clk(clk),
      .addr_i(mem_addr),
      .access_mode_i(memread_i ? RAM_READ : (memwrite_i ? RAM_WRITE : RAM_NONE)),
      .data_i(mem_writein),
      .memwid_i(memwid_i),

      .data_o(mem_readout),
      .illegal_access_o(illegal_mem_access_o)
  );

  /// ALU 
  reg [DATA_LEN -1:0] alu_A, alu_B;
  reg [DATA_LEN -1:0] writeback_data;

  ALU #(DATA_LEN) RvAlu (
      .A_i(alu_A),
      .B_i(alu_B),
      .opcode_i(alu_op_i),
      .C_o(writeback_data)
  );

  /* Write Back to Target from Where */
  parameter WB_ALU = 0, WB_MEM = 1, WB_Next_PC = 2, WB_None = 3;


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
    else if (jalr_i) alu_A = pc_i;
    else alu_A = 64'h0;

    /// drive alu_B
    if (rs2_enable_i) alu_B = rs2_data;
    else if (alu_2nd_src_i) alu_B = imme_i;
    else if (jalr_i) alu_B = 64'h4;  // PC + 4
    else if (memread_i) alu_B = mem_readout;
    else alu_B = 64'h0;

    /// update pc

  end

endmodule
