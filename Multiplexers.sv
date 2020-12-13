`ifndef MULTIPLEXERS_INCLUDED
`define MULTIPLEXERS_INCLUDED

`include "Instruction.sv"
`include "ControllerUnit.sv"
`include "GeneralPurposeRegisters.sv"

function int_t selectAluMduOperandData(
    alu_mdu_operand_from_t from,
    register_data_read_t regRead,
    instruction_t instruction
);
    casez (from)
        ALU_MDU_OPERAND_FROM_REG_READ1:
            return regRead.data1;
        ALU_MDU_OPERAND_FROM_REG_READ2:
            return regRead.data2;
        ALU_MDU_OPERAND_FROM_IMME_UNSIGNED:
            return {16'b0, instruction.immediate};
        ALU_MDU_OPERAND_FROM_IMME_SIGNED:
            return {{16{instruction.immediate[15]}}, instruction.immediate};
        ALU_MDU_OPERAND_FROM_SHIFT_AMOUNT:
            return {27'b0, instruction.shiftAmount};
        default:
            return 'bx;
    endcase
endfunction

function int_t selectDataMemoryWriteData(
    dm_write_from_t from,
    register_data_read_t regRead
);
    casez (from)
        DM_WRITE_FROM_REG_READ2:
            return regRead.data2;
        default:
            return 'bx;
    endcase
endfunction

function int_t selectJumpInput(
    jump_input_from_t from,
    register_data_read_t regRead,
    instruction_t instruction
);
    casez (from)
        JUMP_INPUT_FROM_REG_READ1:
            return regRead.data1;
        JUMP_INPUT_FROM_IMME_UNSIGNED:
            return {16'b0, instruction.immediate};
        JUMP_INPUT_FROM_IMME_SIGNED:
            return {{16{instruction.immediate[15]}}, instruction.immediate};
        default:
            return 'bx;
    endcase
endfunction

function register_id_t selectRegisterId(
    register_id_from_t from,
    instruction_t instruction
);
    casez (from)
        NAME_ZERO:
            return ZERO;
        RS:
            return instruction.registerS;
        RT:
            return instruction.registerT;
        RD:
            return instruction.registerD;
        NAME_RA:
            return RA;
    endcase
endfunction

`endif // MULTIPLEXERS_INCLUDED
