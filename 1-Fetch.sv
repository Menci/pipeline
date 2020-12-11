`ifndef PIPELINE_FETCH_INCLUDED
`define PIPELINE_FETCH_INCLUDED

`include "Definitions.sv"
`include "ProgramCounter.sv"
`include "InstructionMemory.sv"
`include "Debug.sv"

typedef struct packed {
    int_t programCounter;
    logic programCounterChangedTimes;
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

logic stall;
assign stall = stallOnDecode;

int_t programCounter;
logic programCounterChangedTimes;
int_t instructionData;

ProgramCounter pc(
    .reset(reset),
    .clock(clock),
    .stall(stall),
    .jumpEnabled(jumpEnabled),
    .jumpValue(jumpValue),
    .value(programCounter),
    .valueChangedTimes(programCounterChangedTimes)
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
            pipelineResultFetch.programCounterChangedTimes <= programCounterChangedTimes;
            pipelineResultFetch.instruction <= instruction;
        end
    end
end

`ifndef SYNTHESIS
// Debug
string instructionInfo;
assign instructionInfo = inspect(instruction);
`endif

endmodule

`endif // PIPELINE_FETCH_INCLUDED
