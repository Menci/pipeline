`ifndef PIPELINE_EXECUATION_INCLUDED
`define PIPELINE_EXECUATION_INCLUDED

`include "Definitions.sv"
`include "HazardUnit.sv"
`include "Multiplexers.sv"

`include "2-Decode.sv"

typedef struct packed {
    int_t programCounter;
    logic programCounterChangedTimes;
    instruction_t instruction;
    control_signals_t signals;
    register_read_id_t regReadId;
    register_data_read_t regData;
    register_id_t regWriteId;
    int_t aluResult;
    int_t dmAddress;
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
    .programCounterChangedTimes(pipelineResultDecode.programCounterChangedTimes),
    .registerId(pipelineResultDecode.regReadId.id1),
    .originalData(pipelineResultDecode.regData.data1),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data1),
    .stall(hazardStall[0])
);

HazardUnit hu1(
    .reset(reset),
    .clock(clock),
    .programCounterChangedTimes(pipelineResultDecode.programCounterChangedTimes),
    .registerId(pipelineResultDecode.regReadId.id2),
    .originalData(pipelineResultDecode.regData.data2),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data2),
    .stall(hazardStall[1])
);

// Execuation Stage: Stall
logic regDataRequired [2];
assign regDataRequired[0] = pipelineResultDecode.signals.regData1RequiredStage <= EXECUATION;
assign regDataRequired[1] = pipelineResultDecode.signals.regData2RequiredStage <= EXECUATION;
logic mduBusy;
logic stallFromExecuation;
assign stallFromExecuation = (
    (hazardStall[0] && regDataRequired[0]) ||
    (hazardStall[1] && regDataRequired[1])
) || mduBusy;
assign stallOnExecuation = stallFromExecuation;
logic stall;
assign stall = stallOnExecuation || pipelineResultDecode.bubbled;

int_t aluMduOperand1;
assign aluMduOperand1 = selectAluMduOperandData(
    pipelineResultDecode.signals.aluMduOperand1From,
    regData,
    pipelineResultDecode.instruction
);

int_t aluMduOperand2;
assign aluMduOperand2 = selectAluMduOperandData(
    pipelineResultDecode.signals.aluMduOperand2From,
    regData,
    pipelineResultDecode.instruction
);

int_t aluResult;

ArithmeticLogicUnit alu(
    .operand1(aluMduOperand1),
    .operand2(aluMduOperand2),
    .operator(pipelineResultDecode.signals.aluOperator),
    .result(aluResult)
);

int_t mduDataRead;

MultiplicationDivisionUnit mdu(
    .reset(reset),
    .clock(clock),

    .operand1(aluMduOperand1),
    .operand2(aluMduOperand2),
    .operation(pipelineResultDecode.signals.mduOperation),

    .start(pipelineResultDecode.signals.mduStart && !stall),

    .busy(mduBusy),
    .dataRead(mduDataRead)
);

// Pipeline logic

logic passBubble;
assign passBubble = stallFromExecuation || pipelineResultDecode.bubbled;

always_ff @ (posedge clock) begin
    if (reset) begin
        pipelineResultExecuation.bubbled <= 0;
    end
    else begin
        if (!stall) begin
            pipelineResultExecuation.programCounter <= pipelineResultDecode.programCounter;
            pipelineResultExecuation.programCounterChangedTimes <= pipelineResultDecode.programCounterChangedTimes;
            pipelineResultExecuation.instruction <= pipelineResultDecode.instruction;
            pipelineResultExecuation.signals <= pipelineResultDecode.signals;
            pipelineResultExecuation.regReadId <= pipelineResultDecode.regReadId;
            pipelineResultExecuation.regData <= regData;
            pipelineResultExecuation.aluResult <= aluResult;
            pipelineResultExecuation.dmAddress <= aluResult;
            pipelineResultExecuation.regWriteId <= pipelineResultDecode.regWriteId;

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
                else if (pipelineResultDecode.signals.regDataWriteFrom == REG_WRITE_FROM_MDU_DATA_READ) begin
                    pipelineResultExecuation.regDataWriteReady <= 1;
                    pipelineResultExecuation.regDataWrite <= mduDataRead;
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

endmodule

`endif // PIPELINE_EXECUATION_INCLUDED
