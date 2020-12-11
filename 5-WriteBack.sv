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
assign stall = pipelineResultMemory.forwardStall;

always_ff @ (posedge clock)
    if (reset) begin
        // Do nothing
    end else begin
        $display("Stage 5 (write back): %s %s", inspect(pipelineResultMemory.instruction), stall ? "[stalled]" : "");
    end

always_comb begin
    regWriteId = pipelineResultMemory.regWriteId;
    regWriteEnabled = !stall && pipelineResultMemory.signals.regWriteEnabled;
    regDataWrite = pipelineResultMemory.regDataWrite;
end

// syscall instruction
always_comb
    if (pipelineResultMemory.instruction.operationCode == R && pipelineResultMemory.instruction.functionCode == R_SYSCALL)
        $stop;

// Debug
string instructionInfo;
assign instructionInfo = inspect(pipelineResultMemory.instruction);

endmodule

`endif // PIPELINE_WRITE_BACK_INCLUDED
