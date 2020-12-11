`ifndef PIPELINE_MEMORY_INCLUDED
`define PIPELINE_MEMORY_INCLUDED

`include "Definitions.sv"
`include "HazardUnit.sv"
`include "Multiplexers.sv"

`include "3-Execuation.sv"

typedef struct packed {
    int_t programCounter;
    instruction_t instruction;
    control_signals_t signals;
    register_read_id_t regReadId;
    register_data_read_t regData;
    register_id_t regWriteId;
    logic regDataWriteReady;
    int_t regDataWrite;
    logic forwardStall;
} pipeline_result_memory_t;

module PipelineStageMemory(
    input logic reset,
    input logic clock,

    // From execuation stage
    input pipeline_result_execuation_t pipelineResultExecuation,

    output pipeline_result_memory_t pipelineResultMemory,
    output stage_register_data_t resultOfInstructionAfterMemory
);

register_data_read_t regData;
logic hazardStall [2];

stages_register_data_t registerDataFromStages;
assign registerDataFromStages = '{
    resultOfInstructionAfterMemory,
    `NO_SUCH_STAGE,
    `NO_SUCH_STAGE
};

HazardUnit hu0(
    .reset(reset),
    .clock(clock),
    .programCounter(pipelineResultExecuation.programCounter),
    .registerId(pipelineResultExecuation.regReadId.id1),
    .originalData(pipelineResultExecuation.regData.data1),
    .stallCount(2'b00),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data1),
    .stall(hazardStall[0])
);

HazardUnit hu1(
    .reset(reset),
    .clock(clock),
    .programCounter(pipelineResultExecuation.programCounter),
    .registerId(pipelineResultExecuation.regReadId.id2),
    .originalData(pipelineResultExecuation.regData.data2),
    .stallCount(2'b00),
    .dataFromNextStages(registerDataFromStages),
    .forwardedData(regData.data2),
    .stall(hazardStall[1])
);

// Here won't stall
always_comb 
    assert ((hazardStall[0] || hazardStall[1]) == 0);

assign stall = pipelineResultExecuation.forwardStall;

// Data Memory

int_t dmDataRead;
int_t dmDataWrite;
assign dmDataWrite = selectDataMemoryWriteData(
    pipelineResultExecuation.signals.dmDataWriteFrom,
    regData
);

DataMemory dm(
    .clock(clock),
    .address(pipelineResultExecuation.aluResult),
    .dataRead(dmDataRead),
    .writeEnabled(!stall && pipelineResultExecuation.signals.dmWriteEnabled),
    .dataWrite(dmDataWrite),
    .programCounter(pipelineResultExecuation.programCounter)
);

// Pipeline logic

always_ff @ (posedge clock) begin
    if (reset)
        pipelineResultMemory.forwardStall = 0;
    else begin
        $display("Stage 4 (memory)    : %s %s", inspect(pipelineResultExecuation.instruction), stall ? "[stalled]" : "");
        
        if (!stall) begin
            pipelineResultMemory.programCounter <= pipelineResultExecuation.programCounter;
            pipelineResultMemory.instruction <= pipelineResultExecuation.instruction;
            pipelineResultMemory.signals <= pipelineResultExecuation.signals;
            pipelineResultMemory.regReadId <= pipelineResultExecuation.regReadId;
            pipelineResultMemory.regData <= pipelineResultExecuation.regData;
            pipelineResultMemory.regWriteId <= pipelineResultExecuation.regWriteId;

            // Register write data - for passing and forwarding

            if (pipelineResultExecuation.signals.regWriteEnabled) begin
                if (pipelineResultExecuation.regDataWriteReady) begin
                    pipelineResultMemory.regDataWriteReady <= 1;
                    pipelineResultMemory.regDataWrite <= pipelineResultExecuation.regDataWrite;
                end
                else if (pipelineResultExecuation.signals.regDataWriteFrom == REG_WRITE_FROM_DM_READ) begin
                    pipelineResultMemory.regDataWriteReady <= 1;
                    pipelineResultMemory.regDataWrite <= dmDataRead;
                end
                else begin
                    pipelineResultMemory.regDataWriteReady <= 0;
                    pipelineResultMemory.regDataWrite <= 'bx;
                end
            end
            else begin
                pipelineResultMemory.regDataWriteReady <= 1;
                pipelineResultMemory.regDataWrite <= 0;
            end
        end

        pipelineResultMemory.forwardStall <= pipelineResultExecuation.forwardStall;
    end
end

// Provide hazard data info

always_comb begin
    resultOfInstructionAfterMemory.registerId = pipelineResultMemory.regWriteId;
    resultOfInstructionAfterMemory.dataReady = pipelineResultMemory.regDataWriteReady;
    resultOfInstructionAfterMemory.data = pipelineResultMemory.regDataWrite;     
end

`ifndef SYNTHESIS
// Debug
string instructionInfo;
assign instructionInfo = inspect(pipelineResultExecuation.instruction);
`endif

endmodule

`endif // PIPELINE_MEMORY_INCLUDED
