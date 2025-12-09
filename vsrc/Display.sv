module Display #(
    DATA_WIDTH = 64
) (
    input clk_i,
    input rst_i,
    input [DATA_WIDTH-1:0] pc_i,
    input [2:0] nstate_i,
    input [3:0] interrupts_i,

    output reg [7:0] segs_reg[7:0]
);
  reg [7:0] segs_combine[8];

  parameter FetchError = 0, DecodeError = 1;
  // ECALL = 2,
  // EBREAK = 3;
  parameter  /* RST = 0, */ NORMAL = 1, HALT = 2  /*, ERROR = 3 */;
  parameter Anormaly = 1;
  parameter   
            SEGNONE = ~(8'b00000000),
            SEGERROR = ~(8'b10010010),
            SEG0 = ~(8'b11111100),
            SEG1 = ~(8'b01100000),
            SEG2 = ~(8'b11011010),
            SEG3 = ~(8'b11110010),
            SEG4 = ~(8'b01100110),
            SEG5 = ~(8'b10110110),
            SEG6 = ~(8'b10111110),
            SEG7 = ~(8'b11100000),
            SEG8 = ~(8'b11111110),
			SEG9 = ~(8'b11110110),
			SEGA = ~(8'b11101110),
			SEGb = ~(8'b00111110),
			SEGC = ~(8'b10011100),
			SEGd = ~(8'b01111010),
			SEGE = ~(8'b10011110),
			SEGF = ~(8'b10001110);

  function logic [7:0] get_hex_seg(input logic [3:0] val);
    case (val)
      4'h0: return SEG0;
      4'h1: return SEG1;
      4'h2: return SEG2;
      4'h3: return SEG3;
      4'h4: return SEG4;
      4'h5: return SEG5;
      4'h6: return SEG6;
      4'h7: return SEG7;
      4'h8: return SEG8;
      4'h9: return SEG9;
      4'ha: return SEGA;
      4'hb: return SEGb;
      4'hc: return SEGC;
      4'hd: return SEGd;
      4'he: return SEGE;
      4'hf: return SEGF;
    endcase
  endfunction

  always_comb begin
    for (int k = 0; k < 8; k++) segs_combine[k] = SEGNONE;

    if (nstate_i == NORMAL | nstate_i == HALT) begin
      /// Display PC
      for (int k = 0; k < 8; k++) begin
        segs_combine[k] = get_hex_seg(pc_i[k*4+:4]);
      end
    end else begin
      /// Display Error
      segs_combine[FetchError]  = interrupts_i[FetchError] ? SEGERROR : SEGNONE;
      segs_combine[DecodeError] = interrupts_i[DecodeError] ? SEGERROR : SEGNONE;

      for (int i = Anormaly + 1; i < 8; i = i + 1) begin
        segs_combine[i] = SEGNONE;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      for (int k = 0; k < 8; k++) segs_reg[k] <= SEGNONE;
    end else begin
      for (int k = 0; k < 8; k++) segs_reg[k] <= segs_combine[k];
    end
  end

endmodule
