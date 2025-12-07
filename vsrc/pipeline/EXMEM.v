module EXMEM #(
    DATA_WIDTH = 64,
    RF_SIZE = 5
) (
    input clk_i,
    input rst_i,

    input [DATA_WIDTH-1:0] pc_i,

    input stall_i,

    input isbr_i,
    input isjal_i,
    input isjalr_i,
    input [2:0] brty_i,

    input [DATA_WIDTH-1:0] rs1_i,
    input [DATA_WIDTH-1:0] imme_i,
    input [DATA_WIDTH-1:0] alures_i,

    input erd_i,
    input [RF_SIZE-1:0] rd_i,

    input ememr_i,
    input ememw_i,

    input [2:0] memwid_i,
    input [DATA_WIDTH-1:0] memdata_i,

    /*-------------------------------------*/

    output reg [DATA_WIDTH-1:0] pc_o,
    output reg [DATA_WIDTH-1:0] pcn_o,

    output reg [DATA_WIDTH-1:0] alures_o,

    output reg erd_o,
    output reg [RF_SIZE-1:0] rd_o,

    output reg ememr_o,
    output reg ememw_o,

    output reg [2:0] memwid_o,
    output reg [DATA_WIDTH-1:0] memdata_o
);

  /* Enum Branch type */
  parameter B_EQ = 3'b000, B_NE = 3'b001, B_LT = 3'b100, B_GE = 3'b101, B_LTU = 3'b110, B_GEU = 3'b111;

  always @(posedge clk_i) begin
    if (rst_i) begin

      pc_o <= {DATA_WIDTH{1'b0}};
      pcn_o <= {DATA_WIDTH{1'b0}};
      alures_o <= {DATA_WIDTH{1'b0}};
      erd_o <= 1'b0;
      rd_o <= {RF_SIZE{1'b0}};
      ememr_o <= 1'b0;
      ememw_o <= 1'b0;
      memdata_o <= {DATA_WIDTH{1'b0}};
      memwid_o <= 3'b0;
    end else if (!stall_i) begin

      pc_o <= pc_i;

      if (isbr_i) begin
        case (brty_i)
          B_EQ: begin
            /// ALU_SUB
            if (alures_i == 0) pcn_o <= pc_i + imme_i;
          end
          B_NE: begin
            /// ALU_SUB
            if (alures_i != 0) pcn_o <= pc_i + imme_i;
          end
          B_LT: begin
            /// ALU_SLT
            if (alures_i == 1) pcn_o <= pc_i + imme_i;
          end
          B_GE: begin
            /// ALU_SLT
            if (alures_i == 0) pcn_o <= pc_i + imme_i;
          end
          B_LTU: begin
            /// ALU_SLTU
            if (alures_i == 1) pcn_o <= pc_i + imme_i;
          end
          B_GEU: begin
            /// ALU_SLTU
            if (alures_i == 0) pcn_o <= pc_i + imme_i;
          end
          default:  /**/;
        endcase
      end else if (isjal_i) begin
        pcn_o <= imme_i + pc_i;
      end else if (isjalr_i) begin
        pcn_o <= (imme_i + rs1_i) & ~64'h1;
      end

      alures_o <= alures_i;
      erd_o <= erd_i;
      rd_o <= rd_i;
      ememr_o <= ememr_i;
      ememw_o <= ememw_i;
      memdata_o <= memdata_i;
      memwid_o <= memwid_i;
    end
  end

endmodule
