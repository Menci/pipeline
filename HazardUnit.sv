`ifndef HAZARD_UNIT_INCLUDED
`define HAZARD_UNIT_INCLUDED

`include "GeneralPurposeRegisters.sv"

typedef struct packed {
    register_id_t registerId;
    logic dataReady;
    int_t data;
} stage_register_data_t;

typedef logic [1:0] stall_count_t;

`define MAX_STALL_STAGES    3
`define NO_SUCH_STAGE       '{ registerId: ZERO, dataReady: 1, data: 0 }

typedef stage_register_data_t stages_register_data_t [`MAX_STALL_STAGES];

module HazardUnit(
    input logic reset,
    input logic clock,
    input int_t programCounter,
    input register_id_t registerId,
    input int_t originalData,
    input stages_register_data_t dataFromNextStages,
    output int_t forwardedData,
    output logic stall
);

// According to current pipeline state, can we got data forwarded?
int_t currentForwardedData;
logic currentStall;


always_comb begin
    currentStall = 0;
    currentForwardedData = originalData;

    if (registerId != ZERO)
        for (integer i = 0; i < `MAX_STALL_STAGES; i++)
            if (registerId == dataFromNextStages[i].registerId) begin
                if (dataFromNextStages[i].dataReady)
                    currentForwardedData = dataFromNextStages[i].data;
                else
                    currentStall = 1;

                break;
            end
end

// If we stalled for too long, the instruction (computed after current instruction's decode (aka. read general registers) stage)
// will compulete execuation and its result will only available in general registers.
// In this situation the data we request won't be available in any stage.
// This happens on a lw -> lw/div -> add sequence.

// We need to save the forwarded data ONCE it finishs stalling. This makes sure that we always have the correct data to forward.

int_t savedProgramCounter;

// The forwarded data is required on POSEDGE, all input we read to calculate the forwarded data is unstable on POSEDGE.
// So we calculate the forwarded data on NEGEDGE -- between to POSEDGEs.

always_ff @ (negedge clock) begin
    if (reset) begin
        forwardedData <= 0;
        stall <= 0;
        savedProgramCounter <= 32'hffffffff;
    end
    else begin
        if (
            // When instruction changes
            programCounter != savedProgramCounter ||
            // When enter stalling or leave stalling
            currentStall != stall
        ) begin
            savedProgramCounter <= programCounter;
            forwardedData <= currentForwardedData;
            stall <= currentStall;
        end
    end
end

endmodule

`endif // HAZARD_UNIT_INCLUDED
