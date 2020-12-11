`ifndef TOPLEVEL_INCLUDED
`define TOPLEVEL_INCLUDED

`include "1-Fetch.sv"
`include "2-Decode.sv"
`include "3-Execuation.sv"
`include "4-Memory.sv"
`include "5-WriteBack.sv"

`include "Decoder.sv"
`include "ControllerUnit.sv"
`include "GeneralPurposeRegisters.sv"
`include "ProgramCounter.sv"
`include "InstructionMemory.sv"
`include "DataMemory.sv"
`include "ArithmeticLogicUnit.sv"
`include "Multiplexers.sv"
`include "HazardUnit.sv"

module TopLevel(
    input logic reset,
    input logic clock
);

pipeline_result_fetch_t pipelineResultFetch;
pipeline_result_decode_t pipelineResultDecode;
pipeline_result_execuation_t pipelineResultExecuation;
pipeline_result_memory_t pipelineResultMemory;

stage_register_data_t resultOfInstructionAfterDecode;
stage_register_data_t resultOfInstructionAfterExecuation;
stage_register_data_t resultOfInstructionAfterMemory;

logic stallOnDecode;
logic stallOnExecuation;

logic jumpEnabled;
int_t jumpValue;

// Registers

register_read_id_t regReadId;
register_data_read_t regDataRead;
register_id_t regWriteId;
logic regWriteEnabled;
int_t regDataWrite;

GeneralPurposeRegisters gpr(
    .reset(reset),
    .clock(clock),
    .readId(regReadId),
    .dataRead(regDataRead),
    .writeId(regWriteId),
    .writeEnabled(regWriteEnabled),
    .dataWrite(regDataWrite),

    .programCounterRead(pipelineResultFetch.programCounter),
    .programCounterWrite(pipelineResultMemory.programCounter)
);

// Fetch

PipelineStageFetch fetch(
    .reset(reset),
    .clock(clock),

    // From decode stage
    .stallOnDecode(stallOnDecode),

    // From execuation stage
    .jumpEnabled(jumpEnabled),
    .jumpValue(jumpValue),

    .pipelineResultFetch(pipelineResultFetch)
);

// Decode

PipelineStageDecode decode(
    .reset(reset),
    .clock(clock),

    // From fetch stage
    .pipelineResultFetch(pipelineResultFetch),

    // From execuation stage
    .stallOnExecuation(stallOnExecuation),
    .resultOfInstructionAfterExecuation(resultOfInstructionAfterExecuation),

    // From memory stage
    .resultOfInstructionAfterMemory(resultOfInstructionAfterMemory),

    // Registers
    .regReadId(regReadId),
    .regDataRead(regDataRead),

    .pipelineResultDecode(pipelineResultDecode),
    .stallOnDecode(stallOnDecode),
    .resultOfInstructionAfterDecode(resultOfInstructionAfterDecode),
    .jumpEnabled(jumpEnabled),
    .jumpValue(jumpValue)
);

// Execuation

PipelineStageExecuation execuation(
    .reset(reset),
    .clock(clock),

    // From decode stage
    .pipelineResultDecode(pipelineResultDecode),

    // From memory stage
    .resultOfInstructionAfterMemory(resultOfInstructionAfterMemory),

    .pipelineResultExecuation(pipelineResultExecuation),
    .stallOnExecuation(stallOnExecuation),
    .resultOfInstructionAfterExecuation(resultOfInstructionAfterExecuation)
);

// Memory

PipelineStageMemory memory(
    .reset(reset),
    .clock(clock),

    // From execuation stage
    .pipelineResultExecuation(pipelineResultExecuation),

    .pipelineResultMemory(pipelineResultMemory),
    .resultOfInstructionAfterMemory(resultOfInstructionAfterMemory)
);

// Write Back

PipelineStageWriteBack writeBack(
    .reset(reset),
    .clock(clock),

    // From memory stage
    .pipelineResultMemory(pipelineResultMemory),

    // Registers
    .regWriteId(regWriteId),
    .regWriteEnabled(regWriteEnabled),
    .regDataWrite(regDataWrite)
);

endmodule

`endif // TOPLEVEL_INCLUDED
