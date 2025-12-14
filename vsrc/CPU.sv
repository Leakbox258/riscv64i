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
  assign ifid_in.PC = pc_i;
  assign ifid_in.Inst = inst_if;
  assign ifid_in.enable = ifid_in_en;

  logic ifid_in_en;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      ifid_in_en <= '0;
    end else begin
      ifid_in_en <= '1;
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

  IDU idu (
      .inst_i(ifid_out.Inst),

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
      .data_i(WB_Data),  // WB

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
      WB_TO_ALU: alu_A = WB_Data;
      default: alu_A = ExMuxAluA;
    endcase
  end

  always_comb begin
    case (Forward_B)
      MEM_TO_ALU: begin
        if (Forward_Store != MEM_TO_ALU) alu_B = exmem_out.ALU_Result;
        else alu_B = ExMuxAluB;
      end
      WB_TO_ALU: begin
        if (Forward_Store != WB_TO_ALU) alu_B = WB_Data;
        else alu_B = ExMuxAluB;
      end
      default: alu_B = ExMuxAluB;
    endcase
  end


  always_comb begin
    case (Forward_Store)
      MEM_TO_ALU: exmem_in.Store_Data = exmem_out.ALU_Result;
      WB_TO_ALU: exmem_in.Store_Data = WB_Data;
      default: exmem_in.Store_Data = idex_out.RegData[IDX_RS2];
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
      .pc_i(idex_out.PC),
      .rs1_i(idex_out.RegData[IDX_RS1]),
      .imme_i(idex_out.Imm),
      .aluout_i(alu_C),
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
  logic [RAM_SIZE-1:0] mem_addr_exmem;
  assign mem_addr_exmem = exmem_out.ALU_Result[RAM_SIZE-1:0];
  wire [DATA_WIDTH-1:0] memdata_mem;

  /* verilator public_module */
  RAM ram (
      .clk(clk_i),
      .addr_i(mem_addr_exmem),
      .enwr_i(exmem_out.Mem_REn ? 1'b1 : 1'b0),
      .En_i(exmem_out.Mem_REn | exmem_out.Mem_WEn),
      .data_i(exmem_out.Store_Data),
      .wid_i(exmem_out.Detail),

      .data_o(memdata_mem),
      .unalign_access(exception[MemAccessError])
  );

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

  logic [DATA_WIDTH-1:0] WB_Data;
  assign WB_Data = memwb_out.Mem_REn ? memdata_mem : memwb_out.WB_Data;

  // =======================================================================
  // Exceptions
  // =======================================================================
  always_ff @(posedge clk_i) begin
    if (rst_i) exceptions_o <= '0;
    else begin
      exceptions_o[FetchError] <= exception[FetchError] & ifid_in.enable;
      exceptions_o[DecodeError] <= exception[DecodeError] & idex_in.enable;
      exceptions_o[MemAccessError] <= exception[MemAccessError] & memwb_in.enable & (exmem_out.Mem_WEn || exmem_out.Mem_REn);
      exceptions_o[EBREAK:ECALL] <= exception[EBREAK:ECALL] & {2{exmem_in.enable}};
    end
  end

  // =======================================================================
  // Forward
  // ======================================================================= 
  logic [1:0] Forward_A, Forward_B, Forward_Store;

  Forward Forward (
      .idex_out (idex_out),   // EX
      .exmem_out(exmem_out),  // MEM
      .memwb_out(memwb_out),  // WB

      .Forward_A(Forward_A),
      .Forward_B(Forward_B),
      .Forward_Store(Forward_Store)
  );


  // =======================================================================
  // Stall
  // ======================================================================= 
  logic stall;

  Stall Stall (
      .idex_in (idex_in),  // ID
      .idex_out(idex_out), // EX

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
      .enable(exmem_in.enable),

      .flush_id(flush_id),
      .flush_if(flush_if),
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
      cycle <= '0;
    end else begin
      cycle <= cycle + 1;
    end

    $strobe("Verilator: Cycle %0d, IFID_EN: %d, IDEX_EN: %d, EXMEM_EN: %d, MEMWB_IN_EN: %d", cycle,
            ifid_in.enable, idex_in.enable, exmem_in.enable, memwb_in.enable,);
  end

endmodule
