`ifndef PROGRAM_COUNTER_INCLUDED
`define PROGRAM_COUNTER_INCLUDED

`include "Definitions.sv"

typedef enum logic [1:0] {
    NEAR,    // pc = (pc & 0xf0000000) | (x[25:0] << 2)
    FAR,     // pc = x[31:0]
    RELATIVE // pc = pc + (x << 2)
} jump_type_t;

module ProgramCounter(
    input logic reset,
    input logic clock,
    input logic stall,
    input logic jumpEnabled,
    input int_t jumpValue,
    output int_t value,
    output logic valueChangedTimes
);

int_t nextValue;

always_comb begin
    if (jumpEnabled)
        nextValue = jumpValue;
    else
        nextValue = value + 4;
end

// On beginning of a cycle
always_ff @ (posedge clock) begin
    // Initialization
    if (reset) begin
        value <= 32'h00003000 - 4; // It will +4 on first cycle
        valueChangedTimes <= 1;
    end
    else
        // PC update
        if (!stall) begin
            value <= nextValue;
            valueChangedTimes <= !valueChangedTimes;
        end
end

endmodule

`endif // PROGRAM_COUNTER_INCLUDED
