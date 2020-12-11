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
    output int_t value
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
    if (reset)
        value <= 32'h00003000 - 4; // It will +4 on first cycle
    else begin
        // PC update
        if (!stall)
            value <= nextValue;
    end
end

// Debugging output
always @ (posedge clock)
    if (stall)
        $display("PC Stall : @0x%h -> @0x%h", value, nextValue);
    else
        $display("PC Change: @0x%h -> @0x%h", value, nextValue);

endmodule

`endif // PROGRAM_COUNTER_INCLUDED
