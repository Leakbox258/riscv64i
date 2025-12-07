module IDEX #(
    DATA_WIDTH = 64,
    RF_SIZE = 5
) (
    input clk_i,
    input rst_i,

    input stall_i,
    input flush_i,

    input [DATA_WIDTH-1:0] pc_i,

    input [RF_SIZE-1:0] rd_i,
    input [RF_SIZE-1:0] rs1_i,
    input [RF_SIZE-1:0] rs2_i,
    input [2:0] memwid_i,
    input [2:0] brty_i,
    input [DATA_WIDTH-1:0] imme_i,

    input alusel2_i,

    input [3:0] aluop_i,
    input isbr_i,
    input isjal_i,
    input isjalr_i,
    input isauipc_i,

    input erd_i,
    input ers1_i,
    input ers2_i,
    input ememread_i,
    input ememwrite_i,

    /* ----------------------------- */
    output reg [DATA_WIDTH-1:0] pc_o,

    output reg [RF_SIZE-1:0] rd_o,
    output reg [RF_SIZE-1:0] rs1_o,
    output reg [RF_SIZE-1:0] rs2_o,
    output reg [2:0] memwid_o,
    output reg [2:0] brty_o,
    output reg [DATA_WIDTH-1:0] imme_o,

    output reg alusel2_o,

    output reg [3:0] aluop_o,
    output reg isbr_o,
    output reg isjal_o,
    output reg isjalr_o,
    output reg isauipc_o,

    output reg erd_o,
    output reg ers1_o,
    output reg ers2_o,
    output reg ememread_o,
    output reg ememwrite_o  // 20

);

  always @(posedge clk_i) begin
    if (rst_i) begin

      pc_o        <= {DATA_WIDTH{1'b0}};
      rd_o        <= {RF_SIZE{1'b0}};
      rs1_o       <= {RF_SIZE{1'b0}};
      rs2_o       <= {RF_SIZE{1'b0}};
      memwid_o    <= 3'b0;
      brty_o      <= 3'b0;
      imme_o      <= {DATA_WIDTH{1'b0}};

      erd_o       <= 1'b0;
      ers1_o      <= 1'b0;
      ers2_o      <= 1'b0;
      ememread_o  <= 1'b0;
      ememwrite_o <= 1'b0;

      alusel2_o   <= 1'b0;
      aluop_o     <= 4'b0;

      isbr_o      <= 1'b0;
      isjal_o     <= 1'b0;
      isjalr_o    <= 1'b0;
      isauipc_o   <= 1'b0;
    end else begin

      if (flush_i) begin
        // clear control signals
        erd_o       <= 1'b0;
        ers1_o      <= 1'b0;
        ers2_o      <= 1'b0;
        ememread_o  <= 1'b0;
        ememwrite_o <= 1'b0;

      end else if (!stall_i) begin
        pc_o        <= pc_i;


        rd_o        <= rd_i;
        rs1_o       <= rs1_i;
        rs2_o       <= rs2_i;
        memwid_o    <= memwid_i;
        brty_o      <= brty_i;
        imme_o      <= imme_i;

        erd_o       <= erd_i;
        ers1_o      <= ers1_i;
        ers2_o      <= ers2_i;
        ememread_o  <= ememread_i;
        ememwrite_o <= ememwrite_i;

        alusel2_o   <= alusel2_i;
        aluop_o     <= aluop_i;

        isbr_o      <= isbr_i;
        isjal_o     <= isjal_i;
        isjalr_o    <= isjalr_i;
        isauipc_o   <= isauipc_i;
      end
    end

  end

endmodule
