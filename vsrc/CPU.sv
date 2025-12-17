`include "pipeline_pkg.sv"

module CPU
  import pipeline_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input logic [DATA_WIDTH-1:0] pc_i,

    output logic [DATA_WIDTH-1:0] new_pc_o,
    output logic [7:0] exceptions_o
);
  parameter FetchError = 0, DecodeError = 1, MemAccessError = 2, ECALL = 3, EBREAK = 4;
  logic [7:0] exception;
  logic [31:0] cycle;

  // =======================================================================
  // 1. Instruction Fetch
  // =======================================================================
  logic [INST_WIDTH-1:0] inst_if;
  logic [INST_WIDTH-1:0] data_i;
  /* (* keep = 1 *) */ logic [DATA_WIDTH-1:0] mem_addr_exmem;
  /* (* keep = 1 *) */ wire [DATA_WIDTH-1:0] pc_addr_if = pc_i;

  /* verilator public_module */
  MemControl ram (
      .clk(clk_i),
      .addr_i(mem_addr_exmem),
      .pc_i(pc_addr_if),
      .enwr_i(exmem_out.Mem_REn ? 1'b1 : 1'b0),
      .En_i(exmem_out.Mem_REn | exmem_out.Mem_WEn),
      .data_i(exmem_out.Store_Data),
      .wid_i(exmem_out.Detail),

      .data_o(memdata_mem),
      .inst_o(data_i),
      .illegal_access_o(exception[FetchError]),
      .unalign_access(exception[MemAccessError])
  );

  IFU ifu (
      .data_i(data_i),
      .inst_o(inst_if)
  );

  IFID_Pipe_t ifid_in, ifid_out;
  assign ifid_in.PC = pc_i;
  assign ifid_in.Inst = inst_if;
  assign ifid_in.enable = ifid_in_en;

  logic ifid_in_en;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      ifid_in_en <= 1'b0;
    end else begin
      ifid_in_en <= 1'b1;
    end
  end

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

  assign idex_in.PC = ifid_out.PC;
  assign idex_in.enable = ifid_out.enable;
  assign idex_in.RegData[IDX_RS1] = GprReadRs1;
  assign idex_in.RegData[IDX_RS2] = GprReadRs2;

  /* (* keep = 1 *) */ wire [INST_WIDTH-1:0] inst_IDU;
  assign inst_IDU = inst_if;

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

  /* verilator public_module */
  GPR gpr (
      .clk  (clk_i),
      .rs1_i(idex_in.RegIdx[IDX_RS1]),  // ID
      .rs2_i(idex_in.RegIdx[IDX_RS2]),  // ID

      .rd_i(memwb_out.RD_Addr),  // WB
      .write_enable_i(memwb_out.Reg_WEn),  // WB
      .data_i(WB_Data),  // WB (critical path)

      .rs1_data_o(GprReadRs1),
      .rs2_data_o(GprReadRs2)
  );

  /// Display
  always_ff @(posedge clk_i) begin
    $strobe(
        "GPR: Cycle %0d, GPR read x%0d and x%0d, GPR write x%0d, ALUData 0x%h, RegEn %0d, MemREn %0d, Memdata 0x%h",
        cycle, idex_in.RegIdx[IDX_RS1], idex_in.RegIdx[IDX_RS2], memwb_out.RD_Addr,
        memwb_out.WB_Data, memwb_out.Reg_WEn, memwb_out.Mem_REn, memdata_mem);
  end

  /* (* keep = 1 *) */ wire [INST_WIDTH-1:0] inst_IMMGen;
  assign inst_IMMGen = inst_if;

  IMMGen immgen (
      .inst_i(inst_IMMGen),
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
  logic [DATA_WIDTH-1:0] Rs1_BrJl;
  logic [DATA_WIDTH-1:0] pcn_ex;
  /* (* keep = 1 *) */wire  [DATA_WIDTH-1:0] ALU_Result;  // result from last cycle
  /* (* keep = 1 *) */wire  [DATA_WIDTH-1:0] WB_Data_ALU;
  assign ALU_Result  = exmem_out.ALU_Result;
  assign WB_Data_ALU = WB_Data;

  always_comb begin
    case (Forward_A)
      MEM_TO_ALU: Rs1_BrJl = ALU_Result;
      WB_TO_ALU: Rs1_BrJl = WB_Data_ALU;
      default: Rs1_BrJl = Rs1_EXU;
    endcase

  end

  always_comb begin
    case (Forward_A)
      MEM_TO_ALU: alu_A = ALU_Result;
      WB_TO_ALU: alu_A = WB_Data_ALU;
      default: alu_A = ExMuxAluA;
    endcase
  end

  always_comb begin
    case (Forward_B)
      MEM_TO_ALU: begin
        if (Forward_Store != MEM_TO_ALU) alu_B = ALU_Result;
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
      MEM_TO_ALU: exmem_in.Store_Data = ALU_Result;
      WB_TO_ALU: exmem_in.Store_Data = WB_Data_ALU;
      default: exmem_in.Store_Data = Rs2_EXU;
    endcase
  end


  logic [DATA_WIDTH-1:0] ExMuxAluA, ExMuxAluB;
  /* (* keep = 1 *) */ wire ers1, ers2;
  /* (* keep = 1 *) */ wire [DATA_WIDTH-1:0] Rs1_EXU, Rs2_EXU, Imm_EXU;
  /* (* keep = 1 *) */ wire [DATA_WIDTH-1:0] pc;
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

  /* (* keep = 1 *) */ wire [4:0] ALUOp = idex_out.ALUOp;
  ALU Alu (
      .A_i(alu_A),
      .B_i(alu_B),
      .opcode_i(ALUOp),
      .C_o(alu_C)
  );

  /* (* keep = 1 *) */ wire [DATA_WIDTH-1:0] taken, none_taken;
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
        "ALU: A: 0x%0h, B: 0x%0h, C: 0x%0h, Rs1: 0x%0h, Rs2: 0x%0h, Imm: 0x%0h, ForwardFromMem: %s, ForwardFromWB: %s",
        alu_A, alu_B, alu_C, idex_out.RegData[IDX_RS1], idex_out.RegData[IDX_RS2], idex_out.Imm,
        Forward_B == MEM_TO_ALU ? "true" : "false", Forward_B == WB_TO_ALU ? " true" : "false");
  end

  PCN Pcn (
      .specinst_i(idex_out.SpecInst),
      .detail_i(idex_out.Detail),
      .take_target(taken),
      .nonetake_target(none_taken),

      .cmp_i(alu_C[0]),
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

  // =======================================================================
  // 4. MEM
  // =======================================================================
  assign mem_addr_exmem = exmem_out.ALU_Result;
  wire [DATA_WIDTH-1:0] memdata_mem;

  /// display
  always_ff @(posedge clk_i) begin
    $strobe("RAM: Cycle %0d, Ram%0s, Addr: 0x%0h, WData: 0x%0h", cycle,
            exmem_out.Mem_REn ? " read" : (exmem_out.Mem_WEn ? " write" : " non access"),
            exmem_out.ALU_Result, exmem_out.Store_Data);
  end

  // =======================================================================
  // MEM/WB
  // =======================================================================
  MEMWB_Pipe_In_t  memwb_in;
  MEMWB_Pipe_Out_t memwb_out;

  assign memwb_in.PC      = exmem_out.PC;
  assign memwb_in.PC_Next = exmem_out.PC_Next;
  assign memwb_in.RD_Addr = exmem_out.RegIdx[IDX_RD];
  assign memwb_in.Reg_WEn = exmem_out.Reg_WEn;
  assign memwb_in.enable  = exmem_out.enable;

  MEMWB memwb_reg (
      .clk_i  (clk_i),
      .rst_i  (rst_i),
      .WB_Data(exmem_out.ALU_Result),  // read data from syn RAM will be ready next cycle
      .Mem_REn(exmem_out.Mem_REn),
      .data_i (memwb_in),
      .data_o (memwb_out)
  );

  // =======================================================================
  // WB
  // =======================================================================

  wire [DATA_WIDTH-1:0] WB_Data;
  assign WB_Data = memwb_out.Mem_REn ? memdata_mem : memwb_out.WB_Data;

  // =======================================================================
  // Exceptions
  // =======================================================================
  always_ff @(posedge clk_i) begin
    if (rst_i) exceptions_o <= 8'b0;
    else begin
      exceptions_o[FetchError] <= exception[FetchError] & ifid_in.enable;
      exceptions_o[DecodeError] <= exception[DecodeError] & idex_in.enable;
      exceptions_o[MemAccessError] <= exception[MemAccessError] & exmem_out.enable & (exmem_out.Mem_WEn || exmem_out.Mem_REn);
      exceptions_o[EBREAK:ECALL] <= exception[EBREAK:ECALL] & {2{exmem_in.enable}};
    end
  end

  // =======================================================================
  // Forward
  // ======================================================================= 
  logic [1:0] Forward_A, Forward_B, Forward_Store;
  /* (* keep = 1 *) */ wire EnRs1_ex;
  /* (* keep = 1 *) */ wire EnRs2_ex;
  /* (* keep = 1 *) */ wire EnMemW_ex;

  /* (* keep = 1 *) */ wire EnRegW_mem;
  /* (* keep = 1 *) */ wire [RF_SIZE-1:0] RdIdx_mem;
  /* (* keep = 1 *) */ wire EnRegW_wb;
  /* (* keep = 1 *) */ wire [RF_SIZE-1:0] RdIdx_wb;
  /* (* keep = 1 *) */ wire [RF_SIZE-1:0] Rs1Idx_ex;
  /* (* keep = 1 *) */ wire [RF_SIZE-1:0] Rs2Idx_ex;

  assign EnRs1_ex   = idex_out.Enable[IDX_RS1];
  assign EnRs2_ex   = idex_out.Enable[IDX_RS2];
  assign EnMemW_ex  = idex_out.Enable[IDX_MWRITE];
  assign EnRegW_mem = exmem_out.Reg_WEn;
  assign RdIdx_mem  = exmem_out.RegIdx[IDX_RD];
  assign EnRegW_wb  = memwb_out.Reg_WEn;
  assign RdIdx_wb   = memwb_out.RD_Addr;
  assign Rs1Idx_ex  = idex_out.RegIdx[IDX_RS1];
  assign Rs2Idx_ex  = idex_out.RegIdx[IDX_RS2];

  Forward Forward (

      .EnRs1_ex (EnRs1_ex),
      .EnRs2_ex (EnRs2_ex),
      .EnMemW_ex(EnMemW_ex),

      .EnRegW_mem(EnRegW_mem),
      .RdIdx_mem (RdIdx_mem),
      .EnRegW_wb (EnRegW_wb),
      .RdIdx_wb  (RdIdx_wb),
      .Rs1Idx_ex (Rs1Idx_ex),
      .Rs2Idx_ex (Rs2Idx_ex),

      .Forward_A(Forward_A),
      .Forward_B(Forward_B),
      .Forward_Store(Forward_Store)
  );


  // =======================================================================
  // Stall
  // ======================================================================= 
  logic stall;
  /* (* keep = 1 *) */ wire EnMemR_ex, EnRd_ex;
  /* (* keep = 1 *) */ wire [RF_SIZE-1:0] RdIdx_ex, Rs1Idx_id, Rs2Idx_id;
  assign EnMemR_ex = idex_out.Enable[IDX_MREAD];
  assign EnRd_ex   = idex_out.Enable[IDX_RD];
  assign RdIdx_ex  = idex_out.RegIdx[IDX_RD];
  assign Rs1Idx_id = idex_in.RegIdx[IDX_RS1];
  assign Rs2Idx_id = idex_in.RegIdx[IDX_RS2];


  Stall Stall (
      .EnMemR_ex(EnMemR_ex),
      .EnRd_ex(EnRd_ex),
      .RdIdx_ex(RdIdx_ex),
      .Rs1Idx_id(Rs1Idx_id),
      .Rs2Idx_id(Rs2Idx_id),
      .stall(stall)
  );

  // =======================================================================
  // Flush
  // ======================================================================= 
  logic flush_if, flush_id;
  /* (* keep = 1 *) */ wire [DATA_WIDTH-1:0] PC_FLUSH, PCN_FLUSH;
  assign PC_FLUSH  = exmem_in.PC;
  assign PCN_FLUSH = exmem_in.PC_Next;
  wire flush1, flush2;

  assign flush_id = flush1 | prediction_failed;
  assign flush_if = flush2 | prediction_failed;

  Flush Flush (
      .exception(exception),
      .pc(PC_FLUSH),
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
