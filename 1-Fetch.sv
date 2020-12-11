`ifndef PIPELINE_FETCH_INCLUDED
`define PIPELINE_FETCH_INCLUDED

`include "Definitions.sv"
`include "ProgramCounter.sv"
`include "InstructionMemory.sv"
`include "Debug.sv"

typedef struct packed {
    int_t programCounter;
    instruction_t instruction;
} pipeline_result_fetch_t;

module PipelineStageFetch(
    input logic reset,
    input logic clock,

    // From decode stage
    input logic stallOnDecode,

    // From execuation stage
    input logic jumpEnabled,
    input int_t jumpValue,

    output pipeline_result_fetch_t pipelineResultFetch
);

assign stall = stallOnDecode;

int_t programCounter, instructionData;

ProgramCounter pc(
    .reset(reset),
    .clock(clock),
    .stall(stall),
    .jumpEnabled(jumpEnabled),
    .jumpValue(jumpValue),
    .value(programCounter)
);

InstructionMemory im(
    .clock(clock),
    .programCounter(programCounter),
    .instructionData(instructionData)
);

instruction_t instruction;

Decoder decoder(
    .instructionData(instructionData),
    .instruction(instruction)
);

always_ff @ (posedge clock) begin
    if (reset) begin
        // Do nothing
    end
    else begin
        if (!stall) begin
            pipelineResultFetch.programCounter <= programCounter;
            pipelineResultFetch.instruction <= instruction;
        end
    end
end

// Debug
string instructionInfo;
assign instructionInfo = inspect(instruction);

endmodule

`endif // PIPELINE_FETCH_INCLUDED
