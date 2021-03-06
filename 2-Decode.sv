`ifndef PIPELINE_DECODE_INCLUDED
`define PIPELINE_DECODE_INCLUDED

`include "Definitions.sv"
`include "Instruction.sv"
`include "ControllerUnit.sv"
`include "ForwardingUnit.sv"
`include "Multiplexers.sv"

`include "1-Fetch.sv"

typedef struct packed {
    int_t programCounter;
    logic programCounterChangedTimes;
    instruction_t instruction;
    control_signals_t signals;
    register_read_id_t regReadId;
    register_data_read_t regData;
    register_id_t regWriteId;
    logic regDataWriteReady;
    int_t regDataWrite;
    logic bubbled;
} pipeline_result_decode_t;

module PipelineStageDecode(
    input logic reset,
    input logic clock,

    // From fetch stage
    input pipeline_result_fetch_t pipelineResultFetch,

    // From execuation stage
    input logic stallOnExecuation,
    input logic stallFromExecuation,
    input stage_register_data_t resultOfInstructionAfterExecuation,

    // From memory stage
    input stage_register_data_t resultOfInstructionAfterMemory,

    // Registers
    output register_read_id_t regReadId,
    input register_data_read_t regDataRead,

    output pipeline_result_decode_t pipelineResultDecode,
    output logic stallOnDecode,
    output stage_register_data_t resultOfInstructionAfterDecode,
    output logic jumpEnabled,
    output int_t jumpValue
);

control_signals_t signals;

ControllerUnit cu(
    .instruction(pipelineResultFetch.instruction),
    .signals(signals)
);

assign regReadId.id1 = selectRegisterId(signals.regReadId1From, pipelineResultFetch.instruction);
assign regReadId.id2 = selectRegisterId(signals.regReadId2From, pipelineResultFetch.instruction);

register_id_t regWriteId;
assign regWriteId = selectRegisterId(signals.regWriteIdFrom, pipelineResultFetch.instruction);

register_data_read_t regData;
logic hazardStall [2];

stages_register_data_t registerDataFromStages;
assign registerDataFromStages = '{
    resultOfInstructionAfterDecode,
    resultOfInstructionAfterExecuation,
    resultOfInstructionAfterMemory
};

ForwardingUnit fu0(
    .reset(reset),
    .clock(clock),
    .programCounterChangedTimes(pipelineResultFetch.programCounterChangedTimes),
    .registerId(regReadId.id1),
    .originalData(regDataRead.data1),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data1),
    .stall(hazardStall[0])
);

ForwardingUnit fu1(
    .reset(reset),
    .clock(clock),
    .programCounterChangedTimes(pipelineResultFetch.programCounterChangedTimes),
    .registerId(regReadId.id2),
    .originalData(regDataRead.data2),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data2),
    .stall(hazardStall[1])
);

// Stall
logic regDataRequired [2];
assign regDataRequired[0] = signals.regData1RequiredStage <= DECODE;
assign regDataRequired[1] = signals.regData2RequiredStage <= DECODE;
logic stallFromDecode;
assign stallFromDecode = (
    (hazardStall[0] && regDataRequired[0]) ||
    (hazardStall[1] && regDataRequired[1])
);
assign stallOnDecode = stallFromDecode || stallOnExecuation;
logic stall;
assign stall = stallOnDecode;

// Jump
int_t jumpInput;
always_comb begin
    jumpEnabled = 0;
    if (!stall)
        case (signals.pcJumpCondition)
            TRUE:
                jumpEnabled = 1;
            FALSE:
                jumpEnabled = 0;
            REG_READ_DATA_EQUAL:
                jumpEnabled = regData.data1 == regData.data2;
            REG_READ_DATA_NOT_EQUAL:
                jumpEnabled = regData.data1 != regData.data2;
            REG_READ_DATA1_LESS_THAN_ZERO:
                jumpEnabled = $signed(regData.data1) < $signed(0);
            REG_READ_DATA1_LESS_THAN_OR_EQUAL_TO_ZERO:
                jumpEnabled = $signed(regData.data1) <= $signed(0);
            REG_READ_DATA1_GREATER_THAN_ZERO:
                jumpEnabled = $signed(regData.data1) > $signed(0);
            REG_READ_DATA1_GREATER_THAN_OR_EQUAL_TO_ZERO:
                jumpEnabled = $signed(regData.data1) >= $signed(0);
        endcase

    // This won't be from alu and dm
    jumpInput = selectJumpInput(
        signals.pcJumpInputFrom,
        regData,
        pipelineResultFetch.instruction
    );

    // Calculate jump value
    jumpValue = 0;
    case (signals.pcJumpType)
        NEAR:
            jumpValue = (pipelineResultFetch.programCounter & 32'hf0000000) | {4'b0, jumpInput[25:0], 2'b0};
        FAR:
            jumpValue = jumpInput;
        RELATIVE:
            jumpValue = pipelineResultFetch.programCounter + 4 + {jumpInput[29:0], 2'b0};
    endcase
end

// Pipeline logic

logic passBubble;
assign passBubble = stallFromDecode;

always_ff @ (posedge clock) begin
    if (reset) begin
        pipelineResultDecode.bubbled <= 0;
    end
    else begin
        if (!stall) begin
            pipelineResultDecode.programCounter <= pipelineResultFetch.programCounter;
            pipelineResultDecode.programCounterChangedTimes <= pipelineResultFetch.programCounterChangedTimes;
            pipelineResultDecode.instruction <= pipelineResultFetch.instruction;
            pipelineResultDecode.signals <= signals;
            pipelineResultDecode.regReadId <= regReadId;
            pipelineResultDecode.regData <= regData;
            pipelineResultDecode.regWriteId <= regWriteId;

            // Register write data - for passing and forwarding

            if (signals.regWriteEnabled) begin
                if (signals.regDataWriteFrom == REG_WRITE_FROM_PC_ADD_8) begin
                    pipelineResultDecode.regDataWriteReady <= 1;
                    pipelineResultDecode.regDataWrite <= pipelineResultFetch.programCounter + 8;
                end
                else if (signals.regDataWriteFrom == REG_WRITE_FROM_IMME_LSHIFTED) begin
                    pipelineResultDecode.regDataWriteReady <= 1;
                    pipelineResultDecode.regDataWrite <= {pipelineResultFetch.instruction.immediate, 16'b0};
                end
                else begin
                    pipelineResultDecode.regDataWriteReady <= 0;
                    pipelineResultDecode.regDataWrite <= 'bx;
                end
            end
            else begin
                pipelineResultDecode.regDataWriteReady <= 1;
                pipelineResultDecode.regDataWrite <= 0;
            end
        end

        if (!stallFromExecuation)
            pipelineResultDecode.bubbled <= passBubble;
    end
end

// Provide hazard data info

always_comb begin
    if (pipelineResultDecode.bubbled) begin
        resultOfInstructionAfterDecode.registerId = ZERO;
        resultOfInstructionAfterDecode.dataReady = 1;
        resultOfInstructionAfterDecode.data = 0;
    end
    else begin
        resultOfInstructionAfterDecode.registerId = pipelineResultDecode.regWriteId;
        resultOfInstructionAfterDecode.dataReady = pipelineResultDecode.regDataWriteReady;
        resultOfInstructionAfterDecode.data = pipelineResultDecode.regDataWrite;
    end
end

endmodule

`endif // PIPELINE_DECODE_INCLUDED
