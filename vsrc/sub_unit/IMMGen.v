module IMMGen #(
    DATA_WIDTH = 64
) (
    input [31:0] inst_i,
    output reg [DATA_WIDTH-1:0] imme_o
);

  /* Instruction Type */
  parameter
  // Rty = 7'h33, 
  Ity = 7'h13, 
				Load = 7'h03,
				Store = 7'h23, 
				Branch = 7'h63, 
				Jalr = 7'h67, 
				Jal = 7'h6f, 
				Auipc = 7'h17, 
				Lui = 7'h37;
  // Fence = 7'h0f,
  // System = 7'h73,

  wire [6:0] opcode;
  assign opcode = inst_i[6:0];

  always @(*) begin
    case (opcode)
      Ity: begin
        imme_o = {{(DATA_WIDTH - 12) {1'b0}}, inst_i[31:20]};
      end
      Load: begin
        if (inst_i[31]) imme_o = {{(DATA_WIDTH - 12) {1'b1}}, inst_i[31:20]};
        else imme_o = {{(DATA_WIDTH - 12) {1'b0}}, inst_i[31:20]};
      end
      Store: begin
        if (inst_i[31]) imme_o = {{(DATA_WIDTH - 12) {1'b1}}, inst_i[31:25], inst_i[11:7]};
        else imme_o = {{(DATA_WIDTH - 12) {1'b0}}, inst_i[31:25], inst_i[11:7]};
      end
      Branch: begin
        if (inst_i[31])
          imme_o = {
            {(DATA_WIDTH - 12) {1'b1}}, inst_i[31], inst_i[11], inst_i[30:25], inst_i[11:8]
          };
        else
          imme_o = {
            {(DATA_WIDTH - 12) {1'b0}}, inst_i[31], inst_i[11], inst_i[30:25], inst_i[11:8]
          };
      end
      Jalr: begin
        if (inst_i[31]) imme_o = {{(DATA_WIDTH - 12) {1'b1}}, inst_i[31:20]};
        else imme_o = {{(DATA_WIDTH - 12) {1'b0}}, inst_i[31:20]};
      end
      Jal: begin
        if (inst_i[31])
          imme_o = {
            {(DATA_WIDTH - 21) {1'b1}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0
          };
        else
          imme_o = {
            {(DATA_WIDTH - 21) {1'b0}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0
          };
      end
      Auipc: begin
        imme_o = {{(DATA_WIDTH - 32) {1'b0}}, inst_i[31:12], 12'b0};
      end
      Lui: begin
        imme_o = {{(DATA_WIDTH - 32) {1'b0}}, inst_i[31:12], 12'b0};
      end
      default: imme_o = 0;
    endcase
  end

endmodule
