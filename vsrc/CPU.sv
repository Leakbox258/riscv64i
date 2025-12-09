`include "pipeline_pkg.sv"

module CPU
  import pipeline_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input logic [DATA_WIDTH-1:0] pc_i,

    output logic [DATA_WIDTH-1:0] new_pc_o,
    output logic [3:0] exceptions_o
);
  parameter FetchError = 0, DecodeError = 1, ECALL = 2, EBREAK = 3;
  logic [3:0] exception;


  // =======================================================================
  // 1. Instruction Fetch
  // =======================================================================
  logic [INST_WIDTH-1:0] inst_if;
  logic [INST_WIDTH-1:0] data_i;

  /* verilator public_module */
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

      .data_i(ifid_in),
      .data_o(ifid_out)
  );

  // =======================================================================
  // 2. ID
  // =======================================================================
  IDEX_Pipe_t idex_in, idex_out;
  logic [2:0][RF_SIZE-1:0] id_regi;

  assign idex_in.PC = ifid_out.PC;
  assign idex_in.RegIdx = id_regi;

  always_comb begin
    case (Forward_RD1)
      MEM_TO_RD: idex_in.RegData[IDX_RS1] = exmem_out.ALU_Result;
      ALUC_TO_RD: idex_in.RegData[IDX_RS1] = alu_C;
      default: idex_in.RegData[IDX_RS1] = GprReadRs1;
    endcase
  end

  always_comb begin
    case (Forward_RD2)
      MEM_TO_RD: idex_in.RegData[IDX_RS2] = exmem_out.ALU_Result;
      ALUC_TO_RD: idex_in.RegData[IDX_RS2] = alu_C;
      default: idex_in.RegData[IDX_RS2] = GprReadRs2;
    endcase
  end

  IDU idu (
      .inst_i(ifid_out.Inst),

      .enable_o  (idex_in.Enable),
      .aluop_o   (idex_in.ALUOp),
      .specinst_o(idex_in.SpecInst),
      .regi_o    (id_regi),
      .detail_o  (idex_in.Detail),

      .decode_error_o (exception[DecodeError]),
      .env_exception_o(exception[EBREAK:ECALL])
  );

  logic [DATA_WIDTH-1:0] GprReadRs1, GprReadRs2;

  /* verilator public_module */
  GPR gpr (
      .clk  (clk_i),
      .rs1_i(id_regi[IDX_RS1]),  // ID
      .rs2_i(id_regi[IDX_RS2]),  // ID

      .rd_i(memwb_out.RD_Addr),  // WB
      .write_enable_i(memwb_out.Reg_WEn),  // WB
      .data_i(memwb_out.WB_Data),  // WB

      .rs1_data_o(GprReadRs1),
      .rs2_data_o(GprReadRs2)
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
  logic [DATA_WIDTH-1:0] alu_A, alu_B;
  logic [DATA_WIDTH-1:0] alu_C;
  logic [DATA_WIDTH-1:0] pcn_ex;

  always_comb begin
    case (Forward_A)
      MEM_TO_ALU: alu_A = exmem_out.ALU_Result;
      WB_TO_ALU: alu_A = memwb_in.WB_Data;
      default: alu_A = ExMuxAluA;
    endcase
  end

  always_comb begin
    case (Forward_B)
      MEM_TO_ALU: alu_B = exmem_out.ALU_Result;
      WB_TO_ALU: alu_B = memwb_in.WB_Data;
      default: alu_B = ExMuxAluB;
    endcase
  end


  logic [DATA_WIDTH-1:0] ExMuxAluA, ExMuxAluB;
  EXU Exu (
      .ers1_i(idex_out.Enable[IDX_RS1]),
      .ers2_i(idex_out.Enable[IDX_RS2]),
      .specinst_i(idex_out.SpecInst),

      .rs1_i (idex_out.RegData[IDX_RS1]),
      .rs2_i (idex_out.RegData[IDX_RS2]),
      .pc_i  (idex_out.PC),
      .imme_i(idex_out.Imm),

      .alu_A_o(ExMuxAluA),
      .alu_B_o(ExMuxAluB)
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
  assign exmem_in.RegIdx = idex_out.RegIdx;
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
  logic [RAM_SIZE-1:0] mem_addr_exmem;
  assign mem_addr_exmem = exmem_out.ALU_Result[RAM_SIZE-1:0];

  /* verilator public_module */
  RAM ram (
      .clk(clk_i),
      .addr_i(mem_addr_exmem),
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
  assign memwb_in.RD_Addr = exmem_out.RegIdx[IDX_RD];
  assign memwb_in.Reg_WEn = exmem_out.Reg_WEn;
  assign memwb_in.WB_Data = memdata_mem;

  MEMWB memwb_reg (
      .clk_i (clk_i),
      .rst_i (rst_i),
      .data_i(memwb_in),
      .data_o(memwb_out)
  );

  // =======================================================================
  // Exceptions
  // =======================================================================
  always_ff @(posedge clk_i) begin
    if (rst_i) exceptions_o <= 4'b0;
    else exceptions_o <= exception;
  end

  // =======================================================================
  // Forward
  // ======================================================================= 

  logic [1:0] Forward_RD1, Forward_RD2;
  logic [1:0] Forward_A, Forward_B;

  Forward Forward (
      .idex_in  (idex_in),    // ID
      .idex_out (idex_out),   // EX
      .exmem_out(exmem_out),  // MEM
      .memwb_out(memwb_out),  // WB

      .Forward_RD1(Forward_RD1),
      .Forward_RD2(Forward_RD2),
      .Forward_A  (Forward_A),
      .Forward_B  (Forward_B)
  );


  // =======================================================================
  // Stall
  // ======================================================================= 
  logic stall;

  Stall Stall (
      .exmem_out(exmem_out),
      .idex_out (idex_out),

      .stall(stall)
  );

  // =======================================================================
  // Flush
  // ======================================================================= 
  logic flush_if, flush_id;

  Flush Flush (
      .exception(exception),
      .pc(exmem_in.PC),
      .pcn(exmem_in.PC_Next),

      .flush_id(flush_id),
      .flush_if(flush_if),
      .prediction_failed(prediction_failed)
  );

  // =======================================================================
  // Update PC
  // ======================================================================= 
  logic prediction_failed;

  always_comb begin
    if (stall) begin
      new_pc_o = pc_i;
    end else if (prediction_failed) begin
      new_pc_o = exmem_in.PC_Next;
    end else begin
      new_pc_o = pc_i + 4;
    end

  end

endmodule
