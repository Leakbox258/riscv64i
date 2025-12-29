`include "pipeline_pkg.sv"

module CPU
  import pipeline_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input logic [DATA_WIDTH-1:0] pc_i,

    output logic [DATA_WIDTH-1:0] new_pc_o,
    output logic [DATA_WIDTH-1:0] commit_pc_o,
    output logic [7:0] exceptions_o,
    output logic [INST_WIDTH-1:0] inst_o
);
  parameter FetchError = 0, DecodeError = 1, MemAccessError = 2, ECALL = 3, EBREAK = 4;
  logic [7:0] exception;
  logic [31:0] cycle;

  // =======================================================================
  // 1. IF 1
  // =======================================================================

  logic [INST_WIDTH-1:0] inst_raw;
  logic [INST_WIDTH-1:0] inst_safe;

  logic [DATA_WIDTH-1:0] mem_addr_exmem;

  logic [DATA_WIDTH-1:0] pc_delayed;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc_delayed <= 0;
    end else if (!stall) begin
      pc_delayed <= pc_i;
    end
  end

  logic flush_persistence;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      flush_persistence <= 1'b0;
    end else begin
      if (prediction_failed) begin
        flush_persistence <= 1'b1;
      end else if (!stall) begin
        flush_persistence <= 1'b0;
      end
    end
  end

  logic stall_persistence;
  logic [INST_WIDTH-1:0] inst_delay;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      stall_persistence <= 1'b0;
    end else begin
      stall_persistence <= stall;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      inst_delay <= 0;
    end else if (!stall_persistence) begin
      inst_delay <= inst_safe;
    end
  end

  MemControl ram (
      .clk(clk_i),
      .addr_i(mem_addr_exmem),
      .pc_i(pc_i),
      .enwr_i(exmem_out.Mem_REn ? 1'b1 : 1'b0),
      .En_i(exmem_out.Mem_REn | exmem_out.Mem_WEn),
      .data_i(memwrite_mem1),
      .wid_i(exmem_out.Detail),

      .data_o(memdata_mem),
      .inst_o(inst_raw),
      .illegal_access_o(exception[FetchError]),
      .unalign_access(exception[MemAccessError])
  );

  assign inst_safe = flush_persistence ? 32'h00000000 : inst_raw;

  logic [INST_WIDTH-1:0] inst_final;
  IFU ifu (
      .data_i(inst_safe),
      .inst_o(inst_final)
  );

  // =======================================================================
  // 2. IF 2
  // =======================================================================

  IFID_Pipe_t ifid_in, ifid_out;

  assign ifid_in.PC   = flush_persistence ? 0 : pc_delayed;
  assign ifid_in.Inst = stall_persistence ? inst_delay : inst_final;

  logic fetch_error_safe;
  assign fetch_error_safe = flush_persistence ? 1'b0 : exception[FetchError];

  assign ifid_in.enable = !rst_i & !flush_persistence;

  /// for Debug
  assign inst_o = ifid_in.Inst;

  IFID ifid_reg (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .flush_i(flush_if),
      .stall_i(stall),

      .data_i(ifid_in),
      .data_o(ifid_out)
  );

  // =======================================================================
  // 3. ID
  // =======================================================================

  IDEX_Pipe_t idex_in, idex_out;

  assign idex_in.PC = ifid_out.PC;
  assign idex_in.enable = ifid_out.enable;
  assign idex_in.RegData[IDX_RS1] = GprReadRs1;
  assign idex_in.RegData[IDX_RS2] = GprReadRs2;

  wire [INST_WIDTH-1:0] inst_IDU;
  assign inst_IDU = ifid_out.Inst;

  IDU idu (
      .inst_i(inst_IDU),

      .enable_o  (idex_in.Enable),
      .aluop_o   (idex_in.ALUOp),
      .specinst_o(idex_in.SpecInst),
      .regi_o    (idex_in.RegIdx),
      .detail_o  (idex_in.Detail),

      .decode_error_o (exception[DecodeError]),
      .env_exception_o(exception[EBREAK:ECALL])
  );

  logic [DATA_WIDTH-1:0] GprReadRs1, GprReadRs2;

  IMMGen immgen (
      .inst_i(inst_IDU),
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
  // 4. EX
  // =======================================================================
  logic [DATA_WIDTH-1:0] alu_A, alu_B;
  logic [DATA_WIDTH-1:0] alu_C;
  logic [DATA_WIDTH-1:0] Rs1_BrJl;
  logic [DATA_WIDTH-1:0] pcn_ex;

  wire [DATA_WIDTH-1:0] MEM1_DATA_ALU, MEM2_DATA_ALU, MEM3_DATA_ALU, WB_Data_ALU;

  assign MEM1_DATA_ALU = exmem_out.ALU_Result;
  assign MEM2_DATA_ALU = mem1mem2_out.ALU_Result;
  assign MEM3_DATA_ALU = memwb_in.WB_Data;
  assign WB_Data_ALU   = memwb_out.WB_Data;

  always_comb begin
    case (Forward_A)
      MEM1_TO_ALU: Rs1_BrJl = MEM1_DATA_ALU;
      MEM2_TO_ALU: Rs1_BrJl = MEM2_DATA_ALU;
      MEM3_TO_ALU: Rs1_BrJl = MEM3_DATA_ALU;
      WB_TO_ALU: Rs1_BrJl = WB_Data_ALU;
      default: Rs1_BrJl = Rs1_EXU;
    endcase

  end

  always_comb begin
    case (Forward_A)
      MEM1_TO_ALU: alu_A = MEM1_DATA_ALU;
      MEM2_TO_ALU: alu_A = MEM2_DATA_ALU;
      MEM3_TO_ALU: alu_A = MEM3_DATA_ALU;
      WB_TO_ALU: alu_A = WB_Data_ALU;
      default: alu_A = ExMuxAluA;
    endcase
  end

  always_comb begin
    case (Forward_B)
      MEM1_TO_ALU: begin
        if (Forward_Store != MEM1_TO_ALU) alu_B = MEM1_DATA_ALU;
        else alu_B = ExMuxAluB;
      end
      MEM2_TO_ALU: begin
        if (Forward_Store != MEM2_TO_ALU) alu_B = MEM2_DATA_ALU;
        else alu_B = ExMuxAluB;
      end
      MEM3_TO_ALU: begin
        if (Forward_Store != MEM3_TO_ALU) alu_B = MEM3_DATA_ALU;
        else alu_B = ExMuxAluB;
      end
      WB_TO_ALU: begin
        if (Forward_Store != WB_TO_ALU) alu_B = WB_Data_ALU;
        else alu_B = ExMuxAluB;
      end
      default: alu_B = ExMuxAluB;
    endcase
  end


  always_comb begin
    case (Forward_Store)
      MEM1_TO_ALU: exmem_in.Store_Data = MEM1_DATA_ALU;
      MEM2_TO_ALU: exmem_in.Store_Data = MEM2_DATA_ALU;
      MEM3_TO_ALU: exmem_in.Store_Data = MEM3_DATA_ALU;
      WB_TO_ALU: exmem_in.Store_Data = WB_Data_ALU;
      default: exmem_in.Store_Data = Rs2_EXU;
    endcase
  end


  logic [DATA_WIDTH-1:0] ExMuxAluA, ExMuxAluB;
  wire ers1, ers2;
  wire [DATA_WIDTH-1:0] Rs1_EXU, Rs2_EXU, Imm_EXU;
  wire [DATA_WIDTH-1:0] pc;
  assign ers1 = idex_out.Enable[IDX_RS1];
  assign ers2 = idex_out.Enable[IDX_RS2];
  assign Rs1_EXU = idex_out.RegData[IDX_RS1];
  assign Rs2_EXU = idex_out.RegData[IDX_RS2];
  assign Imm_EXU = idex_out.Imm;
  assign pc = idex_out.PC;

  EXU Exu (
      .ers1_i(ers1),
      .ers2_i(ers2),
      .specinst_i(idex_out.SpecInst),

      .rs1_i (Rs1_EXU),
      .rs2_i (Rs2_EXU),
      .pc_i  (pc),
      .imme_i(Imm_EXU),

      .alu_A_o(ExMuxAluA),
      .alu_B_o(ExMuxAluB)
  );

  wire [4:0] ALUOp = idex_out.ALUOp;
  ALU Alu (
      .A_i(alu_A),
      .B_i(alu_B),
      .opcode_i(ALUOp),
      .C_o(alu_C),
      .cmp_o(cmp)
  );

  wire [DATA_WIDTH-1:0] taken, none_taken;
  BRJL brjl (
      .pc(pc),
      .specinst(idex_out.SpecInst),
      .rs1(Rs1_BrJl),  // may forward
      .imme(Imm_EXU),

      .taken(taken),
      .none_taken(none_taken)
  );

  /// Display
  always_ff @(posedge clk_i) begin
    $strobe(
        "ALU: A: 0x%0h, B: 0x%0h, C: 0x%0h, Rs1: 0x%0h, Rs2: 0x%0h, Imm: 0x%0h, AForwardFromMem1: %s, AForwardFromMem2: %s, AForwardFromMem3: %s, AForwardFromWB: %s, BForwardFromMem1: %s, BForwardFromMem2: %s, BForwardFromMem3: %s, BForwardFromWB: %s",
        alu_A, alu_B, alu_C, idex_out.RegData[IDX_RS1], idex_out.RegData[IDX_RS2], idex_out.Imm,
        Forward_A == MEM1_TO_ALU ? "true" : "false", Forward_A == MEM2_TO_ALU ? "true" : "false",
        Forward_A == MEM3_TO_ALU ? "true" : "false", Forward_A == WB_TO_ALU ? " true" : "false",
        Forward_B == MEM1_TO_ALU ? "true" : "false", Forward_B == MEM2_TO_ALU ? "true" : "false",
        Forward_B == MEM3_TO_ALU ? "true" : "false", Forward_B == WB_TO_ALU ? " true" : "false");

    $strobe("BRJL: pc: 0x%08h, rs1: 0x%0h, Imm: 0x%0h, taken: 0x%08h, nonetaken: 0x%08h", pc,
            Rs1_BrJl, Imm_EXU, taken, none_taken);
  end

  wire cmp;
  PCN Pcn (
      .specinst_i(idex_out.SpecInst),
      .detail_i(idex_out.Detail),
      .take_target(taken),
      .nonetake_target(none_taken),

      .cmp_i(cmp),
      .pcn_o(pcn_ex)
  );

  // =======================================================================
  // EX/MEM
  // =======================================================================
  EXMEM_Pipe_t exmem_in;
  EXMEM_Pipe_t exmem_out;

  assign exmem_in.PC = idex_out.PC;
  assign exmem_in.PC_Next = pcn_ex;
  assign exmem_in.ALU_Result = alu_C;
  assign exmem_in.RegIdx = idex_out.RegIdx;
  assign exmem_in.Reg_WEn = idex_out.Enable[IDX_RD];
  assign exmem_in.Mem_REn = idex_out.Enable[IDX_MREAD];
  assign exmem_in.Mem_WEn = idex_out.Enable[IDX_MWRITE];
  assign exmem_in.Detail = idex_out.Detail;
  assign exmem_in.enable = idex_out.enable;

  EXMEM exmem_reg (
      .clk_i(clk_i),
      .rst_i(rst_i),

      .data_i(exmem_in),
      .data_o(exmem_out)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      commit_pc_o <= 0;
    end else if (exmem_in.enable) begin
      commit_pc_o <= pcn_ex;
    end
  end

  // =======================================================================
  // 5. MEM 1 (accessing ram)
  // =======================================================================
  wire [2:0] Forward_RS2;
  logic [DATA_WIDTH-1:0] memwrite_mem1;
  always_comb begin
    case (Forward_RS2)
      MEM3_TO_MEM1: memwrite_mem1 = memwb_in.WB_Data;
      MEM2_TO_MEM1: memwrite_mem1 = mem1mem2_out.ALU_Result;
      WB_TO_MEM1: memwrite_mem1 = memwb_out.WB_Data;
      default: memwrite_mem1 = exmem_out.Store_Data;
    endcase
  end

  assign mem_addr_exmem = exmem_out.ALU_Result;

  /// display
  always_ff @(posedge clk_i) begin
    $strobe("MEM1: Ram%0s, Addr: 0x%0h, WData: 0x%0h",
            exmem_out.Mem_REn ? " read" : (exmem_out.Mem_WEn ? " write" : " non access"),
            exmem_out.ALU_Result, exmem_out.Store_Data);
  end

  MEM1MEM2_Pipe_t mem1mem2_in, mem1mem2_out;
  assign mem1mem2_in.PC = exmem_out.PC;
  assign mem1mem2_in.PC_Next = exmem_out.PC_Next;
  assign mem1mem2_in.RD_Addr = exmem_out.RegIdx[IDX_RD];
  assign mem1mem2_in.RS2_Addr = exmem_out.RegIdx[IDX_RS2];
  assign mem1mem2_in.Mem_Addr = exmem_out.ALU_Result;
  assign mem1mem2_in.ALU_Result = exmem_out.ALU_Result;
  assign mem1mem2_in.Reg_WEn = exmem_out.Reg_WEn;
  assign mem1mem2_in.Mem_REn = exmem_out.Mem_REn;
  assign mem1mem2_in.wid = exmem_out.Detail;
  assign mem1mem2_in.enable = exmem_out.enable;

  MEM1MEM2 mem1mem2_reg (
      .clk_i(clk_i),
      .rst(rst_i),
      .data_i(mem1mem2_in),
      .data_o(mem1mem2_out)
  );

  // =======================================================================
  // 6. MEM 2 (avoid forward mem_read or may create a long path)
  // =======================================================================

  wire [DATA_WIDTH-1:0] mem_read;
  MEM2MEM3_Pipe_t mem2mem3_out;
  wire [DATA_WIDTH-1:0] memdata_mem;

  LD ld (
      .data_i(memdata_mem),
      .wid_i(mem1mem2_out.wid),
      .byteena_i(mem1mem2_out.Mem_Addr[2:0]),

      .data_o(mem_read)
  );

  MEM2MEM3 mem2mem3_reg (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .data_i(mem1mem2_out),
      .MemRead_i(mem_read),  /* mem_read or memdata_mem */
      .data_o(mem2mem3_out)
  );

  // =======================================================================
  // 7. MEM 3 (break critical edge from ram -> alu -> pcn)
  // =======================================================================

  MEMWB_Pipe_t memwb_in, memwb_out;

  assign memwb_in.PC      = mem2mem3_out.PC;
  assign memwb_in.PC_Next = mem2mem3_out.PC_Next;
  assign memwb_in.RD_Addr = mem2mem3_out.RD_Addr;
  assign memwb_in.Reg_WEn = mem2mem3_out.Reg_WEn;
  assign memwb_in.enable  = mem2mem3_out.enable;
  assign memwb_in.WB_Data = mem2mem3_out.Mem_REn ? mem2mem3_out.MemRead : mem2mem3_out.ALU_Result;

  MEMWB memwb_reg (
      .clk_i (clk_i),
      .rst_i (rst_i),
      .data_i(memwb_in),
      .data_o(memwb_out)
  );

  /// Display
  always_comb begin
    $strobe("MEM3: MemRead: 0x%0h, ALUData: 0x%0h", mem2mem3_out.MemRead, mem2mem3_out.ALU_Result);
  end

  // =======================================================================
  // 8. WB
  // =======================================================================

  /* verilator public_module */
  GPR gpr (
      .clk  (clk_i),
      .rs1_i(idex_in.RegIdx[IDX_RS1]),  // ID
      .rs2_i(idex_in.RegIdx[IDX_RS2]),  // ID

      .rd_i(memwb_out.RD_Addr),  // WB
      .write_enable_i(memwb_out.Reg_WEn),  // WB
      .data_i(memwb_out.WB_Data),

      .rs1_data_o(GprReadRs1),
      .rs2_data_o(GprReadRs2)

  );

  /// Display
  always_ff @(posedge clk_i) begin
    $strobe("GPR: Cycle %0d, GPR read x%0d and x%0d, GPR write x%0d, WB_Data 0x%0h", cycle,
            idex_in.RegIdx[IDX_RS1], idex_in.RegIdx[IDX_RS2], memwb_out.RD_Addr, memwb_out.WB_Data);
  end

  // =======================================================================
  // Exceptions
  // =======================================================================
  always_ff @(posedge clk_i) begin
    if (rst_i) exceptions_o <= 8'b0;
    else begin
      exceptions_o[FetchError] <= exception[FetchError] & ifid_in.enable & !fetch_error_safe;
      exceptions_o[DecodeError] <= exception[DecodeError] & idex_in.enable;
      exceptions_o[MemAccessError] <= exception[MemAccessError] & exmem_out.enable & (exmem_out.Mem_WEn || exmem_out.Mem_REn);
      exceptions_o[EBREAK:ECALL] <= exception[EBREAK:ECALL] & {2{exmem_in.enable}};
    end
  end

  // =======================================================================
  // Forward
  // ======================================================================= 
  logic [2:0] Forward_A, Forward_B, Forward_Store;
  wire EnRs1_ex, EnRs2_ex, EnMemW_ex;
  wire [RF_SIZE-1:0] Rs1Idx_ex, Rs2Idx_ex;

  wire EnRegW_mem1, EnMemW_mem1;
  wire [RF_SIZE-1:0] RdIdx_mem1, Rs2Idx_mem1;
  wire EnRegW_mem2, EnMemR_mem1;
  wire [RF_SIZE-1:0] RdIdx_mem2;
  wire EnMemR_mem2;
  wire EnRegW_mem3;
  wire [RF_SIZE-1:0] RdIdx_mem3;
  wire EnRegW_wb;
  wire [RF_SIZE-1:0] RdIdx_wb;

  assign EnRs1_ex = idex_out.Enable[IDX_RS1];
  assign EnRs2_ex = idex_out.Enable[IDX_RS2];
  assign EnMemW_ex = idex_out.Enable[IDX_MWRITE];
  assign EnRegW_mem1 = exmem_out.Reg_WEn;
  assign EnMemW_mem1 = exmem_out.Mem_WEn;
  assign EnMemR_mem1 = exmem_out.Mem_REn;
  assign RdIdx_mem1 = exmem_out.RegIdx[IDX_RD];
  assign Rs2Idx_mem1 = mem1mem2_in.RS2_Addr;
  assign EnRegW_mem2 = mem1mem2_out.Reg_WEn;
  assign EnMemR_mem2 = mem1mem2_out.Mem_REn;
  assign RdIdx_mem2 = mem1mem2_out.RD_Addr;
  assign EnRegW_mem3 = mem2mem3_out.Reg_WEn;
  assign RdIdx_mem3 = mem2mem3_out.RD_Addr;
  assign EnRegW_wb = memwb_out.Reg_WEn;
  assign RdIdx_wb = memwb_out.RD_Addr;
  assign Rs1Idx_ex = idex_out.RegIdx[IDX_RS1];
  assign Rs2Idx_ex = idex_out.RegIdx[IDX_RS2];

  Forward Forward (

      .EnRs1_ex (EnRs1_ex),
      .EnRs2_ex (EnRs2_ex),
      .EnMemW_ex(EnMemW_ex),
      .Rs1Idx_ex(Rs1Idx_ex),
      .Rs2Idx_ex(Rs2Idx_ex),

      .EnRegW_mem1(EnRegW_mem1),
      .EnMemW_mem1(EnMemW_mem1),
      .EnMemR_mem1(EnMemR_mem1),
      .RdIdx_mem1(RdIdx_mem1),
      .RstoreIdx_mem1(Rs2Idx_mem1),

      .EnRegW_mem2(EnRegW_mem2),
      .EnMemR_mem2(EnMemR_mem2),
      .RdIdx_mem2 (RdIdx_mem2),

      .EnRegW_mem3(EnRegW_mem3),
      .RdIdx_mem3 (RdIdx_mem3),

      .EnRegW_wb(EnRegW_wb),
      .RdIdx_wb (RdIdx_wb),

      .Forward_A_Ex(Forward_A),
      .Forward_B_Ex(Forward_B),
      .Forward_Store_Ex(Forward_Store),
      .Forward_Store_Mem1(Forward_RS2)
  );

  // =======================================================================
  // Stall
  // ======================================================================= 
  wire stall;
  wire EnMemR_ex  /* EnMemR_mem1 */;
  wire [RF_SIZE-1:0] RdIdx_ex, Rs1Idx_id, Rs2Idx_id;  /* RdIdx_mem1 */
  assign EnMemR_ex = idex_out.Enable[IDX_MREAD];
  assign RdIdx_ex  = idex_out.RegIdx[IDX_RD];
  assign Rs1Idx_id = idex_in.RegIdx[IDX_RS1];
  assign Rs2Idx_id = idex_in.RegIdx[IDX_RS2];

  Stall Stall (

      .EnMemR_ex(EnMemR_ex),
      .RdIdx_ex (RdIdx_ex),

      .EnMemR_mem1(EnMemR_mem1),
      .RdIdx_mem1 (RdIdx_mem1),

      .EnMemR_mem2(EnMemR_mem2),
      .RdIdx_mem2 (RdIdx_mem2),

      .Rs1Idx_id(Rs1Idx_id),
      .Rs2Idx_id(Rs2Idx_id),

      .stall(stall)
  );

  // =======================================================================
  // Flush
  // ======================================================================= 
  logic flush_if, flush_id;
  wire [DATA_WIDTH-1:0] PCP_FLUSH, PCN_FLUSH;
  assign PCP_FLUSH = none_taken;
  assign PCN_FLUSH = pcn_ex;

  wire flush1, flush2;

  assign flush_id = flush1 | prediction_failed;
  assign flush_if = flush2 | prediction_failed;

  Flush Flush (
      .exception(exception),
      .pcp(PCP_FLUSH),
      .pcn(PCN_FLUSH),
      .enable(exmem_in.enable),

      .flush_id(flush1),
      .flush_if(flush2),
      .prediction_failed(prediction_failed)
  );

  /// Display
  always_ff @(posedge clk_i) begin
    $strobe("EXU: En: %d Predict Pc 0x%h, real Pc Next 0x%h", exmem_in.enable, exmem_in.PC + 4,
            exmem_in.PC_Next);
  end

  // =======================================================================
  // Update PC
  // ======================================================================= 
  logic prediction_failed;

  always_comb begin
    logic [DATA_WIDTH-1:0] next_pc;

    if (prediction_failed) begin
      next_pc = exmem_in.PC_Next;
      $strobe("EXU: Cycle %0d, Branch Prediction Failed, Next_PC: 0x%x", cycle, next_pc);
    end else if (stall) begin
      next_pc = pc_i;
      $strobe("IDU & EXU: Cycle %0d, Pipeline Stall, Next_PC: 0x%x", cycle, next_pc);
    end else begin
      next_pc = pc_i + 4;
    end

    new_pc_o = next_pc;
  end

  /// Display
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      cycle <= 32'b0;
    end else begin
      cycle <= cycle + 1;
    end

    $strobe("Verilator: Cycle %0d, IFID_EN: %d, IDEX_EN: %d, EXMEM_EN: %d, MEMWB_IN_EN: %d", cycle,
            ifid_in.enable, idex_in.enable, exmem_in.enable, memwb_in.enable,);
  end

endmodule
