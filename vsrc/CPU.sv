`include "pipeline/pipeline_pkg.sv"  // 引入包文件

module CPU
  import pipeline_pkg::*;
#(
    RAM_SIZE = 16
) (
    input logic clk_i,
    input logic rst_i,
    input logic [DATA_WIDTH-1:0] pc_i,

    output logic [DATA_WIDTH-1:0] new_pc_o,
    output logic [3:0] exceptions_o
);
  parameter FetchError = 0, DecodeError = 1, ECALL = 2, EBREAK = 3;
  logic [3:0] exception;
  logic flush_if, flush_id;
  logic stall;

  // =======================================================================
  // 1. Instruction Fetch
  // =======================================================================
  logic [INST_WIDTH-1:0] inst_if;
  logic [INST_WIDTH-1:0] data_i;

  CodeROM code (
      .addr_i(pc_i),
      .data_o(data_i),
      .illegal_access_o(exception[FetchError])
  );

  IFU ifu (
      .data_i(data_i),
      .inst_o(inst_if)
  );

  IFID_Pipe_t ifid_in, ifid_out;
  assign ifid_in.PC   = pc_i;
  assign ifid_in.Inst = inst_if;

  IFID ifid_reg (
      .clk_i  (clk_i),
      .rst_i  (rst_i),
      .flush_i(flush_if),
      .stall_i(stall),

      .data_i(ifid_in),  // [Change] 传入结构体
      .data_o(ifid_out)  // [Change] 输出结构体
  );

  // =======================================================================
  // 2. ID
  // =======================================================================
  IDEX_Pipe_t idex_in, idex_out;
  logic [2:0][RF_SIZE-1:0] regi_id;
  assign idex_in.PC = ifid_out.PC;
  assign idex_in.Rd_Addr = regi_id[IDX_RD];

  IDU idu (
      .inst_i(ifid_out.Inst),

      .enable_o  (idex_in.Enable),
      .aluop_o   (idex_in.ALUOp),
      .specinst_o(idex_in.SpecInst),
      .regi_o    (regi_id),
      .detail_o  (idex_in.Detail),

      .decode_error_o (exception[DecodeError]),
      .env_exception_o(exception[EBREAK:ECALL])
  );

  GPR gpr (
      .clk  (clk_i),
      .rs1_i(regi_id[IDX_RS1]),  // ID
      .rs2_i(regi_id[IDX_RS2]),  // ID

      .rd_i(memwb_out.RD_Addr),  // WB
      .write_enable_i(memwb_out.Reg_WEn),  // WB
      .data_i(memwb_out.WB_Data),  // WB

      .rs1_data_o(idex_in.RegData[IDX_RS1]),
      .rs2_data_o(idex_in.RegData[IDX_RS2])
  );

  IMMGen immgen (
      .inst_i(ifid_out.Inst),
      .imme_o(idex_in.Imm)
  );

  // =======================================================================
  // ID/EX
  // =======================================================================
  IDEX idex_reg (
      .clk_i  (clk_i),
      .rst_i  (rst_i),
      .stall_i(stall),
      .flush_i(flush_id),

      .data_i(idex_in),
      .data_o(idex_out)
  );

  // =======================================================================
  // 3. EX
  // =======================================================================
  logic [DATA_WIDTH-1:0] alu_A, alu_B, alu_C;
  logic [DATA_WIDTH-1:0] pcn_ex;

  EXU Exu (
      .ers1_i(idex_out.Enable[IDX_RS1]),
      .ers2_i(idex_out.Enable[IDX_RS2]),
      .specinst_i(idex_out.SpecInst),

      .rs1_i (idex_out.RegData[IDX_RS1]),
      .rs2_i (idex_out.RegData[IDX_RS2]),
      .pc_i  (idex_out.PC),
      .imme_i(idex_out.Imm),

      .alu_A_o(alu_A),
      .alu_B_o(alu_B)
  );

  ALU Alu (
      .A_i(alu_A),
      .B_i(alu_B),
      .opcode_i(idex_out.ALUOp),
      .C_o(alu_C)
  );

  PCN Pcn (
      .specinst_i(idex_out.SpecInst),
      .detail_i(idex_out.Detail),
      .pc_i(idex_out.PC),
      .rs1_i(idex_out.RegData[IDX_RS1]),
      .imme_i(idex_out.Imm),
      .aluout_i(alu_C),
      .pcn_o(pcn_ex)
  );

  // =======================================================================
  // EX/MEM
  // =======================================================================
  EXMEM_Pipe_In_t  exmem_in;
  EXMEM_Pipe_Out_t exmem_out;

  assign exmem_in.PC = idex_out.PC;
  assign exmem_in.PC_Next = pcn_ex;
  assign exmem_in.ALU_Result = alu_C;
  assign exmem_in.Store_Data = idex_out.RegData[IDX_RS2];
  assign exmem_in.RegData = idex_out.RegData[IDX_RS2:IDX_RS1];
  assign exmem_in.RD_Addr = idex_out.Rd_Addr;
  assign exmem_in.Reg_WEn = idex_out.Enable[IDX_RD];
  assign exmem_in.Mem_REn = idex_out.Enable[IDX_MREAD];
  assign exmem_in.Mem_WEn = idex_out.Enable[IDX_MWRITE];
  assign exmem_in.Detail = idex_out.Detail;
  logic [DATA_WIDTH-1:0] memdata_mem;

  EXMEM exmem_reg (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .data_i(exmem_in),
      .data_o(exmem_out)
  );

  // =======================================================================
  // 4. MEM
  // =======================================================================

  RAM Ram (
      .clk(clk_i),
      .addr_i(exmem_out.ALU_Result[RAM_SIZE-1:0]),
      .ewr_i(exmem_out.Mem_REn ? 1'b0 : (exmem_out.Mem_WEn ? 1'b1 : 1'bz)),
      .data_i(exmem_out.Store_Data),
      .wid_i(exmem_out.Detail),

      .data_o(memdata_mem)
  );

  // =======================================================================
  // MEM/WB
  // =======================================================================
  MEMWB_Pipe_t memwb_in, memwb_out;

  assign memwb_in.PC      = exmem_out.PC;
  assign memwb_in.PC_Next = exmem_out.PC_Next;
  assign memwb_in.RD_Addr = exmem_out.RD_Addr;
  assign memwb_in.Reg_WEn = exmem_out.Reg_WEn;
  assign memwb_in.WB_Data = memdata_mem;

  MEMWB memwb_reg (
      .clk_i (clk_i),
      .rst_i (rst_i),
      .data_i(memwb_in),
      .data_o(memwb_out)
  );

  // =======================================================================
  // controls, bypass
  // =======================================================================
  always_ff @(posedge clk_i) begin
    if (rst_i) exceptions_o <= 4'b0;
    else exceptions_o <= exception;
  end

  always_comb begin
    flush_if = 1'b0;
    flush_id = 1'b0;
    stall    = 1'b0;
    new_pc_o = pcn_ex;

    if (exception[FetchError]) flush_if = 1'b1;
    if (exception[DecodeError]) begin
      flush_if = 1'b1;
      flush_id = 1'b1;
    end

    if (ifid_out.PC + 4 != pcn_ex) begin
      flush_if = 1'b1;
      flush_id = 1'b1;
    end

    if (exmem_out.Mem_REn && exmem_out.Reg_WEn && 
           (exmem_out.RD_Addr == regi_id[IDX_RS1] || 
            exmem_out.RD_Addr == regi_id[IDX_RS2])) begin
      stall = 1'b1;
    end

    if (stall) begin
      new_pc_o = ifid_out.PC;
    end else if (ifid_out.PC + 4 == pcn_ex) begin
      new_pc_o = ifid_out.PC + 4;
    end else begin
      new_pc_o = pcn_ex;
    end
  end

endmodule
