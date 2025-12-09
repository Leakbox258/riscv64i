// pipeline_pkg.sv
`ifndef PIPELINE_PKG
`define PIPELINE_PKG

package pipeline_pkg;

  parameter DATA_WIDTH = 64;
  parameter INST_WIDTH = 32;
  parameter RF_SIZE = 5;
  parameter RAM_SIZE = 16;

  // Enables
  parameter IDX_RS1 = 0;
  parameter IDX_RS2 = 1;
  parameter IDX_RD = 2;
  parameter IDX_MREAD = 3;
  parameter IDX_MWRITE = 4;

  // Forwarding
  parameter NO_FWD = 0;
  parameter MEM_TO_RD = 1;
  parameter ALUC_TO_RD = 2;
  parameter MEM_TO_ALU = 1;
  parameter WB_TO_ALU = 2;


  // 1. IF -> ID
  typedef struct packed {
    logic [DATA_WIDTH-1:0] PC;
    logic [INST_WIDTH-1:0] Inst;
    logic enable;
  } IFID_Pipe_t;

  // 2. ID -> EX
  typedef struct packed {
    logic [DATA_WIDTH-1:0]      PC;
    logic [DATA_WIDTH-1:0]      Imm;
    logic [2:0][RF_SIZE-1:0]    RegIdx;
    logic [1:0][DATA_WIDTH-1:0] RegData;
    logic [4:0]                 Enable;
    logic [3:0]                 ALUOp;
    logic [2:0]                 SpecInst;
    logic [2:0]                 Detail;
    logic                       enable;
  } IDEX_Pipe_t;

  // 3. EX -> MEM
  parameter EXMEM_SLICE_BEGIN = 277;
  typedef struct packed {
    logic [DATA_WIDTH-1:0]   PC;
    logic [DATA_WIDTH-1:0]   PC_Next;
    logic [DATA_WIDTH-1:0]   ALU_Result;
    logic [DATA_WIDTH-1:0]   Store_Data;
    logic [2:0][RF_SIZE-1:0] RegIdx;
    logic                    Reg_WEn;
    logic                    Mem_REn;
    logic                    Mem_WEn;
    logic [2:0]              Detail;

    logic [1:0][DATA_WIDTH-1:0] RegData;
    logic enable;
  } EXMEM_Pipe_In_t;

  typedef struct packed {
    logic [DATA_WIDTH-1:0]   PC;
    logic [DATA_WIDTH-1:0]   PC_Next;
    logic [DATA_WIDTH-1:0]   ALU_Result;
    logic [DATA_WIDTH-1:0]   Store_Data;
    logic [2:0][RF_SIZE-1:0] RegIdx;
    logic                    Reg_WEn;
    logic                    Mem_REn;
    logic                    Mem_WEn;
    logic [2:0]              Detail;

    logic enable;
  } EXMEM_Pipe_Out_t;


  // 4. MEM -> WB
  typedef struct packed {
    logic [DATA_WIDTH-1:0] PC;
    logic [DATA_WIDTH-1:0] PC_Next;
    logic [DATA_WIDTH-1:0] WB_Data;
    logic [RF_SIZE-1:0]    RD_Addr;
    logic                  Reg_WEn;
    logic                  enable;
  } MEMWB_Pipe_t;

endpackage

`endif
