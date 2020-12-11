`ifndef GENERAL_PURPOSE_REGISTERS_INCLUDED
`define GENERAL_PURPOSE_REGISTERS_INCLUDED

`include "Definitions.sv"

typedef enum logic [4:0] {
    ZERO = 0,
    AT   = 1,
    V0   = 2,
    V1   = 3,
    A0   = 4,
    A1   = 5,
    A2   = 6,
    A3   = 7,
    T0   = 8,
    T1   = 9,
    T2   = 10,
    T3   = 11,
    T4   = 12,
    T5   = 13,
    T6   = 14,
    T7   = 15,
    S0   = 16,
    S1   = 17,
    S2   = 18,
    S3   = 19,
    S4   = 20,
    S5   = 21,
    S6   = 22,
    S7   = 23,
    T8   = 24,
    T9   = 25,
    K0   = 26,
    K1   = 27,
    GP   = 28,
    SP   = 29,
    FP   = 30,
    RA   = 31
} register_id_t;

typedef struct packed {
    register_id_t id1, id2;
} register_read_id_t;

typedef struct packed {
    int_t data1, data2;
} register_data_read_t;

module GeneralPurposeRegisters(
    input logic reset,
    input logic clock,
    input register_read_id_t readId,
    output register_data_read_t dataRead,
    input register_id_t writeId,
    input logic writeEnabled,
    input int_t dataWrite,

    input int_t programCounterRead,
    input int_t programCounterWrite
);

int_t registers [31:0];

assign dataRead.data1 = registers[readId.id1];
assign dataRead.data2 = registers[readId.id2];

always_ff @ (negedge clock) begin
    // Initialization
    if (reset)
        for (integer i = 0; i < 32; i++)
            registers[i] <= 0;

    // Write
    if (writeEnabled && writeId != ZERO)
        registers[writeId] <= dataWrite;
end

// Debugging output
always @ (negedge clock) begin
    $display("GR: Read1 @0x%h: r%02d => 0x%h", programCounterRead, readId.id1, dataRead.data1);
    $display("GR: Read2 @0x%h: r%02d => 0x%h", programCounterRead, readId.id2, dataRead.data2);

    if (writeEnabled)
        $display("GR: Write @0x%h: r%02d <= 0x%h", programCounterWrite, writeId, dataWrite);
end

// Validation output
always @ (posedge clock)
    if (writeEnabled)
        $display("@%h: $%2d <= %h", programCounterWrite, writeId, dataWrite);

endmodule

`endif // GENERAL_PURPOSE_REGISTERS_INCLUDED
