`ifndef INSTRUCTION_MEMORY_INCLUDED
`define INSTRUCTION_MEMORY_INCLUDED

`include "Definitions.sv"
`include "Instruction.sv"

module InstructionMemory(
    input logic clock,
    input int_t programCounter,
    output instruction_t instruction
);

logic [`IM_SIZE_BIT - 1:2] memoryAddress;
assign memoryAddress = programCounter[`IM_SIZE_BIT - 1:2];

int_t memory [`IM_WORDS - 1:0];

initial
    $readmemh("/tmp/code.txt", memory);

assign instruction = parseInstruction(memory[memoryAddress]);

endmodule

`endif // INSTRUCTION_MEMORY_INCLUDED
