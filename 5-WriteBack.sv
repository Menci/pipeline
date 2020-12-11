`ifndef PIPELINE_WRITE_BACK_INCLUDED
`define PIPELINE_WRITE_BACK_INCLUDED

`include "Definitions.sv"
`include "Multiplexers.sv"

`include "4-Memory.sv"

module PipelineStageWriteBack(
    input logic reset,
    input logic clock,

    // From memory stage
    input pipeline_result_memory_t pipelineResultMemory,

    // Registers
    output register_id_t regWriteId,
    output logic regWriteEnabled,
    output int_t regDataWrite
);

logic stall;
assign stall = pipelineResultMemory.bubbled;

always_comb begin
    regWriteId = pipelineResultMemory.regWriteId;
    regWriteEnabled = !stall && pipelineResultMemory.signals.regWriteEnabled;
    regDataWrite = pipelineResultMemory.regDataWrite;
end

// // syscall instruction
always_comb
    if (pipelineResultMemory.instruction.instructionCode inside {SYSCALL})
        $stop;

endmodule

`endif // PIPELINE_WRITE_BACK_INCLUDED
