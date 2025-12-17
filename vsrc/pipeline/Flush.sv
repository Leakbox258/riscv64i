`include "pipeline_pkg.sv"

module Flush
  import pipeline_pkg::*;
#(
    FetchError  = 0,
    DecodeError = 1
) (
    input [7:0] exception,
    input [DATA_WIDTH-1:0] pc,
    input [DATA_WIDTH-1:0] pcn,
    input enable,

    output logic prediction_failed,
    output logic flush_id,
    output logic flush_if
);

  assign flush_id = exception[DecodeError] & enable;
  assign flush_if = (exception[FetchError] | exception[DecodeError]) & enable;
  assign prediction_failed = (pc + 4 != pcn) & enable;

endmodule
