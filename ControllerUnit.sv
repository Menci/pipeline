`ifndef COUNTROLLER_UNIT_INCLUDED
`define COUNTROLLER_UNIT_INCLUDED

`include "ProgramCounter.sv"
`include "Decoder.sv"
`include "ArithmeticLogicUnit.sv"
`include "GeneralPurposeRegisters.sv"

typedef enum logic [1:0] {
    REG_WRITE_FROM_ALU_RESULT,
    REG_WRITE_FROM_DM_READ,
    REG_WRITE_FROM_PC_ADD_8,
    REG_WRITE_FROM_IMME_LSHIFTED
} reg_write_from_t;

typedef enum logic [1:0] {
    ALU_OPERAND_FROM_REG_READ1,
    ALU_OPERAND_FROM_REG_READ2,
    ALU_OPERAND_FROM_IMME_UNSIGNED,
    ALU_OPERAND_FROM_IMME_SIGNED
} alu_operand_from_t;

typedef enum logic [0:0] {
    DM_WRITE_FROM_REG_READ2
} dm_write_from_t;

typedef enum logic [1:0] {
    JUMP_INPUT_FROM_REG_READ1,
    JUMP_INPUT_FROM_IMME_UNSIGNED,
    JUMP_INPUT_FROM_IMME_SIGNED
} jump_input_from_t;

typedef enum logic [2:0] {
    NAME_ZERO = 0,
    RS        = 1,
    RT        = 2,
    RD        = 3,
    NAME_RA   = 4  // ra = 31
} register_id_from_t;

typedef enum logic [1:0] {
    FALSE                   = 0,
    TRUE                    = 1,
    REG_READ_DATA_EQUAL     = 2,
    REG_READ_DATA_NOT_EQUAL = 3
} jump_condition_t;

typedef enum logic [1:0] {
    DECODE,
    EXECUATION,
    MEMORY,
    NONE
} register_data_required_stage_t;

typedef struct packed {
    register_id_from_t regReadId1From;
    register_id_from_t regReadId2From;
    register_data_required_stage_t regDataRequiredStage;
    register_id_from_t regWriteIdFrom;
    logic regWriteEnabled;
    reg_write_from_t regDataWriteFrom;
    alu_operand_from_t aluOperand1From;
    alu_operand_from_t aluOperand2From;
    alu_operator_t aluOperator;
    logic dmWriteEnabled;
    dm_write_from_t dmDataWriteFrom;
    jump_condition_t pcJumpCondition;
    jump_type_t pcJumpType;
    jump_input_from_t pcJumpInputFrom;
} control_signals_t;

module ControllerUnit(
    input instruction_t instruction,
    output control_signals_t signals
);

always_comb begin
    // Reset control signals
    signals.regReadId1From = NAME_ZERO;
    signals.regReadId2From = NAME_ZERO;
    signals.regDataRequiredStage = NONE;
    signals.regWriteIdFrom = NAME_ZERO;
    signals.regWriteEnabled = 0;
    signals.regDataWriteFrom = REG_WRITE_FROM_ALU_RESULT;
    signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
    signals.aluOperand2From = ALU_OPERAND_FROM_REG_READ1;
    signals.aluOperator = ADD;
    signals.dmWriteEnabled = 0;
    signals.dmDataWriteFrom = DM_WRITE_FROM_REG_READ2;
    signals.pcJumpCondition = FALSE;
    signals.pcJumpType = NEAR;
    signals.pcJumpInputFrom = JUMP_INPUT_FROM_REG_READ1;

    casez (instruction.operationCode)
        R: begin
            casez (instruction.functionCode)
                // rd = rs + rt
                R_ADDU, R_SUBU: begin
                    signals.regReadId1From = RS;
                    signals.regReadId2From = RT;
                    signals.regDataRequiredStage = EXECUATION;
                    signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
                    signals.aluOperand2From = ALU_OPERAND_FROM_REG_READ2;
                    casez (instruction.functionCode)
                        R_ADDU:
                            signals.aluOperator = ADD;
                        R_SUBU:
                            signals.aluOperator = SUB;
                    endcase
                    signals.regWriteEnabled = 1;
                    signals.regWriteIdFrom = RD;
                    signals.regDataWriteFrom = REG_WRITE_FROM_ALU_RESULT;
                end
                // pc = rs
                R_JR: begin
                    signals.regReadId1From = RS;
                    signals.regDataRequiredStage = DECODE;
                    signals.pcJumpCondition = TRUE;
                    signals.pcJumpType = FAR;
                    signals.pcJumpInputFrom = JUMP_INPUT_FROM_REG_READ1;
                end
                // syscall
                R_SYSCALL: begin
                    // Do nothing
                end
            endcase
        end
        // rt = rs | imme
        ORI: begin
            signals.regReadId1From = RS;
            signals.regDataRequiredStage = EXECUATION;
            signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            signals.aluOperand2From = ALU_OPERAND_FROM_IMME_UNSIGNED;
            signals.aluOperator = OR;
            signals.regWriteEnabled = 1;
            signals.regWriteIdFrom = RT;
            signals.regDataWriteFrom = REG_WRITE_FROM_ALU_RESULT;
        end
        LW, SW: begin
            signals.regReadId1From = RS;
            signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            signals.aluOperand2From = ALU_OPERAND_FROM_IMME_SIGNED;
            signals.aluOperator = ADD;
            casez (instruction.operationCode)
                // rt = *(rs + imme)
                LW: begin
                    signals.regDataRequiredStage = EXECUATION;
                    signals.regWriteEnabled = 1;
                    signals.regWriteIdFrom = RT;
                    signals.regDataWriteFrom = REG_WRITE_FROM_DM_READ;
                end
                // *(rs + imme) = rt
                SW: begin
                    signals.regDataRequiredStage = MEMORY;
                    signals.regReadId2From = RT;
                    signals.dmWriteEnabled = 1;
                    signals.dmDataWriteFrom = DM_WRITE_FROM_REG_READ2;
                end
            endcase
        end
        // if rs - rt == 0 then pc += SignedExtend(imme)
        BEQ: begin
            signals.regReadId1From = RS;
            signals.regReadId2From = RT;
            signals.regDataRequiredStage = DECODE;
            signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            signals.aluOperand2From = ALU_OPERAND_FROM_REG_READ2;
            signals.aluOperator = SUB;
            signals.pcJumpCondition = REG_READ_DATA_EQUAL;
            signals.pcJumpType = RELATIVE;
            signals.pcJumpInputFrom = JUMP_INPUT_FROM_IMME_SIGNED;
        end
        // if rs - rt != 0 then pc += SignedExtend(imme)
        BNE: begin
            signals.regReadId1From = RS;
            signals.regReadId2From = RT;
            signals.regDataRequiredStage = DECODE;
            signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            signals.aluOperand2From = ALU_OPERAND_FROM_REG_READ2;
            signals.aluOperator = SUB;
            signals.pcJumpCondition = REG_READ_DATA_NOT_EQUAL;
            signals.pcJumpType = RELATIVE;
            signals.pcJumpInputFrom = JUMP_INPUT_FROM_IMME_SIGNED;
        end
        // rt = imm << 16
        LUI: begin
            signals.regWriteEnabled = 1;
            signals.regWriteIdFrom = RT;
            signals.regDataWriteFrom = REG_WRITE_FROM_IMME_LSHIFTED;
        end
        // pc = NearJump(pc, imme)
        JAL: begin
            signals.regWriteEnabled = 1;
            signals.regWriteIdFrom = NAME_RA;
            signals.regDataWriteFrom = REG_WRITE_FROM_PC_ADD_8;
            signals.pcJumpCondition = TRUE;
            signals.pcJumpType = NEAR;
            signals.pcJumpInputFrom = JUMP_INPUT_FROM_IMME_UNSIGNED;
        end
    endcase
end

endmodule

`endif // COUNTROLLER_UNIT_INCLUDED
