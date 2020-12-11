`ifndef DATA_MEMORY_INCLUDED
`define DATA_MEMORY_INCLUDED

`include "Definitions.sv"

module DataMemory(
    input logic clock,
    input int_t address,
    input logic writeEnabled,
    input int_t dataWrite,

    output int_t dataRead,

    input int_t programCounter
);

logic [11:2] memoryAddress;
assign memoryAddress = address[11:2];

int_t memory [1023:0];

// Initialization
initial begin
    for (integer i = 0; i < 1024; i++)
        memory[i] = 0;
end

// Read
assign dataRead = memory[memoryAddress];

// Write
always_ff @ (posedge clock)
    if (writeEnabled)
        memory[memoryAddress] <= dataWrite;

// Debugging output
always @ (posedge clock) begin
    $display("DM: Read  @0x%h: *0x%h => 0x%h", programCounter, address, dataRead);
    if (writeEnabled)
        $display("DM: Write @0x%h: *0x%h <= 0x%h", programCounter, address, dataWrite);
end

// Validation output
always @ (posedge clock)
    if (writeEnabled)
        $display("@%h: *%h <= %h", programCounter, address, dataWrite);

endmodule

`endif // DATA_MEMORY_INCLUDED
