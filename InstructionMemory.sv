`ifndef INSTRUCTION_MEMORY_INCLUDED
`define INSTRUCTION_MEMORY_INCLUDED

`include "Definitions.sv"
`include "Instruction.sv"

module InstructionMemory(
    input logic clock,
    input int_t programCounter,
    output instruction_t instruction
);

logic [11:2] memoryAddress;
assign memoryAddress = programCounter[11:2];

int_t memory [1023:0];

initial
    $readmemh("/tmp/code.txt", memory);

assign instruction = parseInstruction(memory[memoryAddress]);

endmodule

`endif // INSTRUCTION_MEMORY_INCLUDED
