`include "pipeline_pkg.sv"

module MEMWB
  import pipeline_pkg::*;
(
    input clk_i,
    input rst_i,

    input [DATA_WIDTH-1:0] WB_Data,
    input Mem_REn,

    input  MEMWB_Pipe_In_t  data_i,
    output MEMWB_Pipe_Out_t data_o
);

  MEMWB_Pipe_Out_t next_data;

  always_comb begin
    if (rst_i) begin
      next_data = 0;
    end else begin
      next_data.PC = data_i.PC;
      next_data.PC_Next = data_i.PC_Next;
      next_data.RD_Addr = data_i.RD_Addr;
      next_data.Reg_WEn = data_i.Reg_WEn;
      next_data.enable = data_i.enable;

      next_data.WB_Data = WB_Data;
      next_data.Mem_REn = Mem_REn;
      next_data.wid = data_i.wid;
      next_data.Mem_Addr = data_i.Mem_Addr;
    end
  end

  always_ff @(posedge clk_i) begin
    data_o <= next_data;
  end

endmodule
