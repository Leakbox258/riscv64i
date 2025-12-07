module MEMWB #(
    DATA_WIDTH = 64,
    RF_SIZE = 5
) (
    input clk_i,
    input rst_i,

    input [DATA_WIDTH-1:0] pc_i,
    input [DATA_WIDTH-1:0] pcn_i,

    input erd_i,
    input [DATA_WIDTH-1:0] wbrd_i,
    input [RF_SIZE-1:0] rd_i,

    input ememw_i,
    input [DATA_WIDTH-1:0] wbmem_i,
    input [DATA_WIDTH-1:0] memaddr_i,

    /*----------------------------------*/

    output reg [DATA_WIDTH-1:0] pc_o,
    output reg [DATA_WIDTH-1:0] pcn_o,

    output reg erd_o,
    output reg [DATA_WIDTH-1:0] wbrd_o,
    output reg [RF_SIZE-1:0] rd_o,


    output reg ememw_o,
    output reg [DATA_WIDTH-1:0] wbmem_o,
    output reg [DATA_WIDTH-1:0] memaddr_o
);

  always @(posedge clk_i) begin
    if (rst_i) begin

      pc_o <= {DATA_WIDTH{1'b0}};
      pcn_o <= {DATA_WIDTH{1'b0}};
      erd_o <= 1'b0;
      rd_o <= {RF_SIZE{1'b0}};
      wbmem_o <= {DATA_WIDTH{1'b0}};
      wbrd_o <= {DATA_WIDTH{1'b0}};
      ememw_o <= 1'b0;
      memaddr_o <= {DATA_WIDTH{1'b0}};

    end else begin

      pc_o <= pc_i;
      pcn_o <= pcn_i;
      erd_o <= erd_i;
      rd_o <= rd_i;
      wbmem_o <= wbmem_i;
      wbrd_o <= wbrd_i;
      ememw_o <= ememw_i;
      memaddr_o <= memaddr_i;
    end
  end

endmodule
