// pipeline_pkg.sv
package pipeline_pkg;

  parameter DATA_WIDTH = 64;
  parameter INST_WIDTH = 32;
  parameter RF_SIZE = 5;

  // Enables
  parameter IDX_RS1 = 0;
  parameter IDX_RS2 = 1;
  parameter IDX_RD = 2;
  parameter IDX_MREAD = 3;
  parameter IDX_MWRITE = 4;

  // 1. IF -> ID
  typedef struct packed {
    logic [DATA_WIDTH-1:0] PC;
    logic [INST_WIDTH-1:0] Inst;
  } IFID_Pipe_t;

  // 2. ID -> EX
  typedef struct packed {
    logic [DATA_WIDTH-1:0]      PC;
    logic [DATA_WIDTH-1:0]      Imm;
    logic [RF_SIZE-1:0]         Rd_Addr;
    logic [1:0][DATA_WIDTH-1:0] RegData;
    logic [4:0]                 Enable;
    logic [3:0]                 ALUOp;
    logic [2:0]                 SpecInst;
    logic [2:0]                 Detail;
  } IDEX_Pipe_t;

  // 3. EX -> MEM
  parameter EXMEM_SLICE_BEGIN = 266;
  typedef struct packed {
    logic [DATA_WIDTH-1:0] PC;
    logic [DATA_WIDTH-1:0] PC_Next;
    logic [DATA_WIDTH-1:0] ALU_Result;
    logic [DATA_WIDTH-1:0] Store_Data;
    logic [RF_SIZE-1:0]    RD_Addr;
    logic                  Reg_WEn;
    logic                  Mem_REn;
    logic                  Mem_WEn;
    logic [2:0]            Detail;

    logic [1:0][DATA_WIDTH-1:0] RegData;
  } EXMEM_Pipe_In_t;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] PC;
    logic [DATA_WIDTH-1:0] PC_Next;
    logic [DATA_WIDTH-1:0] ALU_Result;
    logic [DATA_WIDTH-1:0] Store_Data;
    logic [RF_SIZE-1:0]    RD_Addr;
    logic                  Reg_WEn;
    logic                  Mem_REn;
    logic                  Mem_WEn;
    logic [2:0]            Detail;
  } EXMEM_Pipe_Out_t;


  // 4. MEM -> WB
  typedef struct packed {
    logic [DATA_WIDTH-1:0] PC;
    logic [DATA_WIDTH-1:0] PC_Next;
    logic [DATA_WIDTH-1:0] WB_Data;
    logic [RF_SIZE-1:0]    RD_Addr;
    logic                  Reg_WEn;
  } MEMWB_Pipe_t;

endpackage
