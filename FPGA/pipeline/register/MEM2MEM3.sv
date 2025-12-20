`include "pipeline_pkg.sv"

module MEM2MEM3
  import pipeline_pkg::*;
(
    input clk_i,
    input rst_i,

    input MEM1MEM2_Pipe_t data_i,
    input [DATA_WIDTH-1:0] MemRead_i,

    output MEM2MEM3_Pipe_t data_o
);


  MEM2MEM3_Pipe_t next_data;

  always_comb begin
    if (rst_i) begin
      next_data = 0;
    end else begin
      next_data.PC = data_i.PC;
      next_data.PC_Next = data_i.PC_Next;
      next_data.RD_Addr = data_i.RD_Addr;
      next_data.ALU_Result = data_i.ALU_Result;
      next_data.Reg_WEn = data_i.Reg_WEn;
      next_data.Mem_REn = data_i.Mem_REn;
      next_data.enable = data_i.enable;
      next_data.MemRead = MemRead_i;
    end
  end

  always_ff @(posedge clk_i) begin
    data_o <= next_data;
  end

endmodule
