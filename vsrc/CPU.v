module CPU #(
    DATA_WIDTH = 64,
    INST_WIDTH = 32,
    RF_SIZE = 5,
    RAM_SIZE = 16
) (
    input clk_i,
    input rst_i,
    input [DATA_WIDTH-1:0] pc_i,
    input [INST_WIDTH-1:0] data_i,

    output reg [DATA_WIDTH-1:0] new_pc_o,
    output reg [3:0] exceptions_o
);
  parameter FetchError = 0, DecodeError = 1, ECALL = 2, EBREAK = 3;

  /// resources
  IMMGen immgen (
      .inst_i(inst_ifid),
      .imme_o(imme_id)
  );

  GPR gpr (
      .clk(clk_i),
      .rs1_i(rs1_idex),  // Ex
      .rs2_i(rs2_idex),  // Ex
      .rd_i(rd_memwb),  // Wb
      .write_enable_i(erd_memwb),  // Wb
      .data_i(wbrd_memwb),  // Wb

      .rs1_data_o(rs1_ex),  // Ex
      .rs2_data_o(rs2_ex)   // Ex
  );

  ALU Alu (
      .A_i(alu_A_ex),  // Ex
      .B_i(alu_B_ex),  // Ex
      .opcode_i(aluop_idex),  // Ex
      .C_o(alu_C_ex)  // Ex
  );

  RAM Ram (
      .clk(clk_i),
      .raddr_i(alures_exmem[RAM_SIZE-1:0]),  // Mem
      .waddr_i(memaddr_memwb[RAM_SIZE-1:0]),  // Wb
      .read_i(ememr_exmem),  // Mem
      .write_i(ememw_memwb),  // Wb
      .data_i(wbmem_memwb),  // Wb
      .wid_i(memwid_exmem),  // Mem

      .data_o(wbmem_memwb)  // Wb
  );

  /// Pipeline
  wire [INST_WIDTH-1:0] inst_if;
  IFU ifu (
      .pc_i(pc_i),
      .data_i(data_i),
      .inst_o(inst_if),
      .fetch_error_o(exception[FetchError])
  );

  wire [DATA_WIDTH-1:0] pc_ifid;
  wire [INST_WIDTH-1:0] inst_ifid;
  IFID ifid (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .flush_i(flush_if),
      .stall_i(stall),

      .inst_i(inst_if),
      .pc_i  (pc_i),

      .inst_o(inst_ifid),
      .pc_o  (pc_ifid)
  );

  wire erd_id, ers1_id, ers2_id, ememread_id, ememwrite_id;
  wire [3:0] aluop_id;
  wire alusel2_id;
  wire [2:0] brty_id;
  wire isbr_id, isjal_id, isjalr_id, isauipc_id;
  wire [RF_SIZE-1:0] rd_id, rs1_id, rs2_id;
  wire [2:0] memwid_id;


  IDU idu (
      .inst_i(inst_ifid),
      .erd_o(erd_id),
      .ers1_o(ers1_id),
      .ers2_o(ers2_id),
      .ememread_o(ememread_id),
      .ememwrite_o(ememwrite_id),
      .aluop_o(aluop_id),
      .alusel2_o(alusel2_id),

      .branch_o(isbr_id),
      .jal_o(isjal_id),
      .jalr_o(isjalr_id),
      .auipc_o(isauipc_id),

      .rd_o (rd_id),
      .rs1_o(rs1_id),
      .rs2_o(rs2_id),

      .memwid_o(memwid_id),
      .brty_o  (brty_id),

      .decode_error_o (exception[DecodeError]),
      .env_exception_o(exception[EBREAK:ECALL])
  );

  wire [DATA_WIDTH-1:0] imme_id;

  wire [DATA_WIDTH-1:0] pc_idex;
  wire [RF_SIZE-1:0] rd_idex, rs1_idex, rs2_idex;
  wire [2:0] memwid_idex, brty_idex;
  wire [DATA_WIDTH-1:0] imme_idex;
  wire alusel2_idex;
  wire [3:0] aluop_idex;
  wire isbr_idex, isjal_idex, isjalr_idex, isauipc_idex;
  wire erd_idex, ers1_idex, ers2_idex, ememread_idex, ememwrite_idex;

  IDEX idex (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .stall_i(stall),
      .flush_i(flush_id),

      .pc_i(pc_ifid),

      .rd_i(rd_id),
      .rs1_i(rs1_id),
      .rs2_i(rs2_id),
      .memwid_i(memwid_id),
      .brty_i(brty_id),
      .imme_i(imme_id),
      .alusel2_i(alusel2_id),

      .aluop_i(aluop_id),
      .isbr_i(isbr_id),
      .isjal_i(isjal_id),
      .isjalr_i(isjalr_id),
      .isauipc_i(isauipc_id),

      .erd_i(erd_id),
      .ers1_i(ers1_id),
      .ers2_i(ers2_id),
      .ememread_i(ememread_id),
      .ememwrite_i(ememwrite_id),

      .pc_o(pc_idex),

      .rd_o(rd_idex),
      .rs1_o(rs1_idex),
      .rs2_o(rs2_idex),
      .memwid_o(memwid_idex),
      .brty_o(brty_idex),
      .imme_o(imme_idex),

      .alusel2_o(alusel2_idex),

      .aluop_o(aluop_idex),
      .isbr_o(isbr_idex),
      .isjal_o(isjal_idex),
      .isjalr_o(isjalr_idex),
      .isauipc_o(isauipc_idex),

      .erd_o(erd_idex),
      .ers1_o(ers1_idex),
      .ers2_o(ers2_idex),
      .ememread_o(ememread_idex),
      .ememwrite_o(ememwrite_idex)
  );

  wire [DATA_WIDTH-1:0] rs1_ex, rs2_ex;
  wire [DATA_WIDTH-1:0] alu_A_ex, alu_B_ex, alu_C_ex;
  EXU Exu (
      .ers1_i(ers1_idex),
      .ers2_i(ers2_idex),
      .alusel2_i(alusel2_idex),
      .jal_i(isjal_idex),
      .jalr_i(isjalr_idex),
      .auipc_i(isauipc_idex),

      .rs1_i (rs1_ex),
      .rs2_i (rs2_ex),
      .pc_i  (pc_idex),
      .imme_i(imme_idex),

      .alu_A_o(alu_A_ex),
      .alu_B_o(alu_B_ex)
  );

  wire [DATA_WIDTH-1:0] pc_exmem, pcn_exmem, alures_exmem, memdata_exmem;
  wire [2:0] memwid_exmem;
  wire [RF_SIZE-1:0] rd_exmem;
  wire erd_exmem, ememr_exmem, ememw_exmem;

  EXMEM exmem (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .stall_i(stall),

      .pc_i(pc_idex),
      .isbr_i(isbr_idex),
      .isjal_i(isjal_idex),
      .isjalr_i(isjalr_idex),
      .brty_i(brty_idex),

      .rs1_i(rs1_ex),
      .imme_i(imme_idex),
      .alures_i(alu_C_ex),

      .erd_i(erd_idex),
      .rd_i (rd_idex),

      .ememr_i(ememread_idex),
      .ememw_i(ememwrite_idex),

      .memwid_i (memwid_idex),
      .memdata_i(alu_C_ex),

      .pc_o(pc_exmem),
      .pcn_o(pcn_exmem),
      .alures_o(alures_exmem),

      .erd_o  (erd_exmem),
      .rd_o   (rd_exmem),
      .ememw_o(ememw_exmem),
      .ememr_o(ememr_exmem),

      .memwid_o (memwid_exmem),
      .memdata_o(memdata_exmem)
  );

  /// MEM...
  wire [DATA_WIDTH-1:0] pc_memwb, pcn_memwb, wbmem_memwb, memaddr_memwb, wbrd_memwb;
  wire [RF_SIZE-1:0] rd_memwb;
  wire erd_memwb, ememw_memwb;

  MEMWB memwb (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .pc_i (pc_exmem),
      .pcn_i(pcn_exmem),

      .erd_i (erd_exmem),
      .wbrd_i(alures_exmem),
      .rd_i  (rd_exmem),

      .ememw_i  (ememw_exmem),
      .wbmem_i  (memdata_exmem),
      .memaddr_i(alures_exmem),

      .pc_o (pc_memwb),
      .pcn_o(pcn_memwb),

      .erd_o (erd_memwb),
      .rd_o  (rd_memwb),
      .wbrd_o(wbrd_memwb),

      .ememw_o  (ememw_memwb),
      .wbmem_o  (wbmem_memwb),
      .memaddr_o(memaddr_memwb)
  );

  /// WB...

  /// interaction with monitor
  wire [3:0] exception;
  reg flush_if, flush_id;
  reg stall;

  always @(posedge clk_i) begin
    if (rst_i) begin
      exceptions_o <= 4'b0;
    end else begin
      exceptions_o <= exception;
    end
  end

  always @(*) begin
    flush_if = 1'b0;
    flush_id = 1'b0;

    /// ?Handle Exceptions
    if (exception[FetchError]) begin
      flush_if = 1'b1;
    end
    if (exception[DecodeError]) begin
      flush_if = 1'b1;
      flush_id = 1'b1;
    end
    // TODO: ECALL & EBREAK

    if (pc_ifid + 4 != pcn_exmem) begin
      /// Br/Jr Prediction Failed
      flush_if = 1'b1;
      flush_id = 1'b1;
    end
  end

  always @(*) begin

    if (ememr_exmem && erd_exmem && rd_exmem == rd_id) begin
      stall = 1'b1;
    end else begin
      stall = 1'b0;
    end

    if (stall) begin
      new_pc_o = pc_ifid;
    end else if (pc_ifid + 4 == pcn_exmem) begin
      new_pc_o = pc_ifid + 4;
    end else begin
      new_pc_o = pcn_exmem;
    end
  end

endmodule
