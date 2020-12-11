`ifndef ARITHMETIC_LOGIC_UNIT_INCLUDED
`define ARITHMETIC_LOGIC_UNIT_INCLUDED

`include "Definitions.sv"

typedef enum logic [2:0] {
    ADD,
    SUB,
    OR
} alu_operator_t;

module ArithmeticLogicUnit(
    input int_t operand1,
    input int_t operand2,
    input alu_operator_t operator,
    output int_t result
);

always_comb begin
    result = 0;

    case (operator)
        ADD:
            result = operand1 + operand2;
        SUB:
            result = operand1 - operand2;
        OR:
            result = operand1 | operand2;
    endcase
end
endmodule

`endif // ARITHMETIC_LOGIC_UNIT_INCLUDED
