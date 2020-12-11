`ifndef INSTRUCTION_MEMORY_INCLUDED
`define INSTRUCTION_MEMORY_INCLUDED

`include "Definitions.sv"

module InstructionMemory(
    input logic clock,
    input int_t programCounter,
    output int_t instructionData
);

logic [11:2] memoryAddress;
assign memoryAddress = programCounter[11:2];

int_t memory [1023:0];

initial
    $readmemh("/tmp/code.txt", memory);

assign instructionData = memory[memoryAddress];

endmodule

`endif // INSTRUCTION_MEMORY_INCLUDED
