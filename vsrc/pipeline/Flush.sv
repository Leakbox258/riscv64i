`include "pipeline_pkg.sv"

module Flush
  import pipeline_pkg::*;
#(
    FetchError  = 0,
    DecodeError = 1
) (
    input [3:0] exception,
    input [DATA_WIDTH-1:0] pc,
    input [DATA_WIDTH-1:0] pcn,
    input enable,

    output logic prediction_failed,
    output logic flush_id,
    output logic flush_if
);
  always_comb begin
    flush_if = '0;
    flush_id = '0;
    prediction_failed = '0;

    if (enable) begin
      /// Exceptions
      if (exception[FetchError]) begin
        flush_if = '1;
      end

      if (exception[DecodeError]) begin
        flush_if = '1;
        flush_id = '1;
      end

      /// Wrong control flow prediction
      if (pc + 4 != pcn) begin
        prediction_failed = '1;
        flush_if = '1;
        flush_id = '1;
      end
    end
  end

endmodule
