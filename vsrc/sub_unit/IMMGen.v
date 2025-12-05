module IMMGen #(
    DATA_WIDTH = 64
) (
    input [31:0] inst_i,
    output logic [DATA_WIDTH-1:0] imme_o
);

  /* Instruction Type */
  // Rty = 7'h33, 
  // R64ty = 7'h3b,
  parameter
			Ity = 7'h13, 
			Load = 7'h03,
			Store = 7'h23, 
			Branch = 7'h63, 
			Jalr = 7'h67, 
			Jal = 7'h6f, 
			Auipc = 7'h17, 
			Lui = 7'h37, 
			I64ty = 7'h1b;

  // Env = 7'h73, // TODO: trap code

  wire [6:0] opcode;
  assign opcode = inst_i[6:0];

  function automatic logic [DATA_WIDTH-1:0] sext_imme_12(input logic [11:0] value);
    logic [DATA_WIDTH-1:0] sexted;
    sexted = {{(DATA_WIDTH - 12) {value[11]}}, value};
    return sexted;
  endfunction

  function automatic logic [DATA_WIDTH-1:0] sext_imme_32(input logic [31:0] value);
    logic [DATA_WIDTH-1:0] sexted;
    sexted = {{(DATA_WIDTH - 32) {value[31]}}, value};
    return sexted;
  endfunction

  always @(*) begin
    case (opcode)
      Ity: begin
        imme_o = sext_imme_12(inst_i[31:20]);
      end
      I64ty: begin
        imme_o = sext_imme_12(inst_i[31:20]);
      end
      Load: begin
        imme_o = sext_imme_12(inst_i[31:20]);
      end
      Store: begin
        imme_o = sext_imme_12({inst_i[31:25], inst_i[11:7]});
      end
      Branch: begin
        imme_o = sext_imme_12({inst_i[31], inst_i[11], inst_i[30:25], inst_i[11:8]});
      end
      Jalr: begin
        imme_o = sext_imme_12(inst_i[31:20]);
      end
      Jal: begin  // 21
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
        imme_o = sext_imme_32({inst_i[31:12], 12'b0});
      end
      Lui: begin
        imme_o = sext_imme_32({inst_i[31:12], 12'b0});
      end
      default: imme_o = 0;
    endcase
  end

  //   initial begin
  //     $monitor("IMMGen imme: %h", imme_o);
  //   end

endmodule
