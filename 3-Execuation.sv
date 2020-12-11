`ifndef PIPELINE_EXECUATION_INCLUDED
`define PIPELINE_EXECUATION_INCLUDED

`include "Definitions.sv"
`include "HazardUnit.sv"
`include "Multiplexers.sv"

`include "2-Decode.sv"

typedef struct packed {
    int_t programCounter;
    instruction_t instruction;
    control_signals_t signals;
    register_read_id_t regReadId;
    register_data_read_t regData;
    register_id_t regWriteId;
    int_t aluResult;
    logic regDataWriteReady;
    int_t regDataWrite;
    logic bubbled;
} pipeline_result_execuation_t;

module PipelineStageExecuation(
    input logic reset,
    input logic clock,

    // From decode stage
    input pipeline_result_decode_t pipelineResultDecode,

    // From memory stage
    input stage_register_data_t resultOfInstructionAfterMemory,

    output pipeline_result_execuation_t pipelineResultExecuation,
    output logic stallOnExecuation,
    output logic stallFromExecuation,
    output stage_register_data_t resultOfInstructionAfterExecuation
);

register_data_read_t regData;
logic hazardStall [2];

stages_register_data_t registerDataFromStages;
assign registerDataFromStages = '{
    resultOfInstructionAfterExecuation,
    resultOfInstructionAfterMemory,
    `NO_SUCH_STAGE
};

HazardUnit hu0(
    .reset(reset),
    .clock(clock),
    .programCounter(pipelineResultDecode.programCounter),
    .registerId(pipelineResultDecode.regReadId.id1),
    .originalData(pipelineResultDecode.regData.data1),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data1),
    .stall(hazardStall[0])
);

HazardUnit hu1(
    .reset(reset),
    .clock(clock),
    .programCounter(pipelineResultDecode.programCounter),
    .registerId(pipelineResultDecode.regReadId.id2),
    .originalData(pipelineResultDecode.regData.data2),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data2),
    .stall(hazardStall[1])
);

// Execuation Stage: Stall
logic regDataRequired;
assign regDataRequired = pipelineResultDecode.signals.regDataRequiredStage <= EXECUATION;
assign stallFromExecuation = regDataRequired && (hazardStall[0] || hazardStall[1]);
assign stallOnExecuation = stallFromExecuation;
logic stall;
assign stall = stallOnExecuation || pipelineResultDecode.bubbled;

int_t aluOperand1;
assign aluOperand1 = selectAluOperandData(
    pipelineResultDecode.signals.aluOperand1From,
    regData,
    pipelineResultDecode.instruction
);

int_t aluOperand2;
assign aluOperand2 = selectAluOperandData(
    pipelineResultDecode.signals.aluOperand2From,
    regData,
    pipelineResultDecode.instruction
);

int_t aluResult;

ArithmeticLogicUnit alu(
    .operand1(aluOperand1),
    .operand2(aluOperand2),
    .operator(pipelineResultDecode.signals.aluOperator),
    .result(aluResult)
);

// Pipeline logic

logic passBubble;
assign passBubble = stallFromExecuation || pipelineResultDecode.bubbled;

always_ff @ (posedge clock) begin
    if (reset) begin
        pipelineResultExecuation.bubbled <= 0;
    end
    else begin
        $display("Stage 3 (execuation): %s %s", inspect(pipelineResultDecode.instruction), stall ? "[stalled]" : "");

        if (!stall) begin
            pipelineResultExecuation.programCounter <= pipelineResultDecode.programCounter;
            pipelineResultExecuation.instruction <= pipelineResultDecode.instruction;
            pipelineResultExecuation.signals <= pipelineResultDecode.signals;
            pipelineResultExecuation.regReadId <= pipelineResultDecode.regReadId;
            pipelineResultExecuation.regData <= regData;
            pipelineResultExecuation.regWriteId <= pipelineResultDecode.regWriteId;
            pipelineResultExecuation.aluResult <= aluResult;

            // Register write data - for passing and forwarding

            if (pipelineResultDecode.signals.regWriteEnabled) begin
                if (pipelineResultDecode.regDataWriteReady) begin
                    pipelineResultExecuation.regDataWriteReady <= 1;
                    pipelineResultExecuation.regDataWrite <= pipelineResultDecode.regDataWrite;
                end
                else if (pipelineResultDecode.signals.regDataWriteFrom == REG_WRITE_FROM_ALU_RESULT) begin
                    pipelineResultExecuation.regDataWriteReady <= 1;
                    pipelineResultExecuation.regDataWrite <= aluResult;
                end
                else begin
                    pipelineResultExecuation.regDataWriteReady <= 0;
                    pipelineResultExecuation.regDataWrite <= 'bx;
                end
            end
            else begin
                pipelineResultExecuation.regDataWriteReady <= 1;
                pipelineResultExecuation.regDataWrite <= 0;
            end
        end

        pipelineResultExecuation.bubbled <= passBubble;
    end
end

// Provide hazard data info

always_comb begin
    if (pipelineResultExecuation.bubbled) begin
        resultOfInstructionAfterExecuation.registerId = ZERO;
        resultOfInstructionAfterExecuation.dataReady = 1;
        resultOfInstructionAfterExecuation.data = 0;
    end
    else begin
        resultOfInstructionAfterExecuation.registerId = pipelineResultExecuation.regWriteId;
        resultOfInstructionAfterExecuation.dataReady = pipelineResultExecuation.regDataWriteReady;
        resultOfInstructionAfterExecuation.data = pipelineResultExecuation.regDataWrite;
    end
end

`ifndef SYNTHESIS
// Debug
string instructionInfo;
assign instructionInfo = inspect(pipelineResultDecode.instruction);
`endif

endmodule

`endif // PIPELINE_EXECUATION_INCLUDED
