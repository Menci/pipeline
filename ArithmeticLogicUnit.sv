`ifndef ARITHMETIC_LOGIC_UNIT_INCLUDED
`define ARITHMETIC_LOGIC_UNIT_INCLUDED

`include "Definitions.sv"

typedef enum logic [3:0] {
    ALU_ADD,
    ALU_SUB,

    ALU_SHIFT_R_ARITHMETIC,
    ALU_SHIFT_R_LOGICAL,
    ALU_SHIFT_L,

    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_NOR,
    ALU_LESS_THAN_SIGNED,
    ALU_LESS_THAN_UNSIGNED
} alu_operator_t;

module ArithmeticLogicUnit(
    input int_t operand1,
    input int_t operand2,
    input alu_operator_t operator,
    output int_t result
);

logic [4:0] shiftAmount;
assign shiftAmount = operand1[4:0];

always_comb begin
    result = 0;

    case (operator)
        ALU_ADD:
            result = operand1 + operand2;
        ALU_SUB:
            result = operand1 - operand2;
        ALU_SHIFT_R_ARITHMETIC:
            result = $signed(operand2) >>> shiftAmount;
        ALU_SHIFT_R_LOGICAL:
            result = operand2 >> shiftAmount;
        ALU_SHIFT_L:
            result = operand2 << shiftAmount;
        ALU_AND:
            result = operand1 & operand2;
        ALU_OR:
            result = operand1 | operand2;
        ALU_XOR:
            result = operand1 ^ operand2;
        ALU_NOR:
            result = ~(operand1 | operand2);
        ALU_LESS_THAN_SIGNED:
            result = {31'b0, $signed(operand1) < $signed(operand2)};
        ALU_LESS_THAN_UNSIGNED:
            result = {31'b0, operand1 < operand2};
    endcase
end
endmodule

`endif // ARITHMETIC_LOGIC_UNIT_INCLUDED
