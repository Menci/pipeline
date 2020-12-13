`ifndef MULTIPLICATION_DIVISION_UNIT_INCLUDED
`define MULTIPLICATION_DIVISION_UNIT_INCLUDED

`include "Definitions.sv"

typedef enum logic [2:0] {
    MDU_READ_HI,
    MDU_READ_LO,
    MDU_WRITE_HI,
    MDU_WRITE_LO,
    MDU_START_SIGNED_MUL,
    MDU_START_UNSIGNED_MUL,
    MDU_START_SIGNED_DIV,
    MDU_START_UNSIGNED_DIV
} mdu_operation_t;

module MultiplicationDivisionUnit(
    input logic reset,
    input logic clock,

    input int_t operand1,
    input int_t operand2,
    input mdu_operation_t operation,

    input logic start,

    output logic busy,
    output int_t dataRead
);

// Results
int_t hi, lo;

// Running status

int_t remainingCycleCount;

int_t savedOperand1, savedOperand2;
mdu_operation_t savedOperation;

// Result values

long_t resultSignedMul;
long_t resultUnsignedMul;
long_t resultSignedDiv;
long_t resultUnsignedDiv;

always_comb begin
    resultSignedMul   = $signed(savedOperand1) * $signed(savedOperand2);
    resultUnsignedMul = savedOperand1 * savedOperand2;
    resultSignedDiv   = {
        $signed(savedOperand1) % $signed(savedOperand2),
        $signed(savedOperand1) / $signed(savedOperand2)
    };
    resultUnsignedDiv = {
        savedOperand1 % savedOperand2,
        savedOperand1 / savedOperand2
    };
end

// Operations

always_ff @ (posedge clock) begin
    if (reset) begin
        hi <= 0;
        lo <= 0;
        remainingCycleCount <= 0;
    end
    else begin
        if (remainingCycleCount != 0)
            remainingCycleCount <= remainingCycleCount - 1;

        // We read the value of remainingCycleCount before the non-blocking assignment
        if (remainingCycleCount == 1)
            // The result is ready to use now, and will ready to read from hi and lo in next cycle
            case (savedOperation)
                MDU_START_SIGNED_MUL:   {hi, lo} <= resultSignedMul;
                MDU_START_UNSIGNED_MUL: {hi, lo} <= resultUnsignedMul;
                // Mars won't modify HI and LO on division by zero
                MDU_START_SIGNED_DIV:   if (savedOperand2 != 0) {hi, lo} <= resultSignedDiv;
                MDU_START_UNSIGNED_DIV: if (savedOperand2 != 0) {hi, lo} <= resultUnsignedDiv;
            endcase
        else if (remainingCycleCount == 0) begin
            // Ready
            case (operation)
                MDU_START_SIGNED_MUL, MDU_START_UNSIGNED_MUL,
                MDU_START_SIGNED_DIV, MDU_START_UNSIGNED_DIV: begin
                    if (start) begin
                        if (remainingCycleCount != 0)
                            // This shouldn't happen
                            $stop;

                        case (operation)
                            MDU_START_SIGNED_MUL, MDU_START_UNSIGNED_MUL: remainingCycleCount <= 5;
                            MDU_START_SIGNED_DIV, MDU_START_UNSIGNED_DIV: remainingCycleCount <= 10;
                        endcase

                        savedOperand1 <= operand1;
                        savedOperand2 <= operand2;
                        savedOperation <= operation;
                    end
                end
                MDU_WRITE_HI: hi <= operand1;
                MDU_WRITE_LO: lo <= operand1;
            endcase
        end
    end
end

// Busy signal
always_comb
    busy = remainingCycleCount != 0;

// Read HI and LO
always_comb begin
    dataRead = 0;

    case (operation)
        MDU_READ_HI: dataRead = hi;
        MDU_READ_LO: dataRead = lo;
    endcase
end

endmodule

`endif // MULTIPLICATION_DIVISION_UNIT_INCLUDED
