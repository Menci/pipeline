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

typedef enum logic [2:0] {
    ALU_OPERAND_FROM_REG_READ1,
    ALU_OPERAND_FROM_REG_READ2,
    ALU_OPERAND_FROM_IMME_UNSIGNED,
    ALU_OPERAND_FROM_IMME_SIGNED,
    ALU_OPERAND_FROM_SHIFT_AMOUNT
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

typedef enum logic [2:0] {
    FALSE                                        = 0,
    TRUE                                         = 1,
    REG_READ_DATA_EQUAL                          = 2,
    REG_READ_DATA_NOT_EQUAL                      = 3,
    REG_READ_DATA1_LESS_THAN_ZERO                = 4,
    REG_READ_DATA1_LESS_THAN_OR_EQUAL_TO_ZERO    = 5,
    REG_READ_DATA1_GREATER_THAN_ZERO             = 6,
    REG_READ_DATA1_GREATER_THAN_OR_EQUAL_TO_ZERO = 7
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
    signals.aluOperator = ALU_ADD;
    signals.dmWriteEnabled = 0;
    signals.dmDataWriteFrom = DM_WRITE_FROM_REG_READ2;
    signals.pcJumpCondition = FALSE;
    signals.pcJumpType = NEAR;
    signals.pcJumpInputFrom = JUMP_INPUT_FROM_REG_READ1;

    casex (instruction.instructionCode)
        // syscall
        SYSCALL: begin
            // Do nothing
        end
        // rd = rs ?? rt
        // rd = rs ?? sa
        ADD, ADDU, SUB, SUBU,
        SLL, SRL, SRA, SLLV,
        SRLV, SRAV, AND, OR,
        XOR, NOR, SLT, SLTU: begin
            casex (instruction.instructionCode)
                SLL:     signals.regReadId1From = NAME_ZERO;
                SRL:     signals.regReadId1From = NAME_ZERO;
                SRA:     signals.regReadId1From = NAME_ZERO;
                default: signals.regReadId1From = RS;
            endcase
            signals.regReadId2From = RT;
            signals.regDataRequiredStage = EXECUATION;
            casex (instruction.instructionCode)
                SLL:     signals.aluOperand1From = ALU_OPERAND_FROM_SHIFT_AMOUNT;
                SRL:     signals.aluOperand1From = ALU_OPERAND_FROM_SHIFT_AMOUNT;
                SRA:     signals.aluOperand1From = ALU_OPERAND_FROM_SHIFT_AMOUNT;
                default: signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            endcase
            signals.aluOperand2From = ALU_OPERAND_FROM_REG_READ2;
            casex (instruction.instructionCode)
                ADD:  signals.aluOperator = ALU_ADD;
                ADDU: signals.aluOperator = ALU_ADD;
                SUB:  signals.aluOperator = ALU_SUB;
                SUBU: signals.aluOperator = ALU_SUB;
                SLL:  signals.aluOperator = ALU_SHIFT_L;
                SRL:  signals.aluOperator = ALU_SHIFT_R_LOGICAL;
                SRA:  signals.aluOperator = ALU_SHIFT_R_ARITHMETIC;
                SLLV: signals.aluOperator = ALU_SHIFT_L;
                SRLV: signals.aluOperator = ALU_SHIFT_R_LOGICAL;
                SRAV: signals.aluOperator = ALU_SHIFT_R_ARITHMETIC;
                AND:  signals.aluOperator = ALU_AND;
                OR:   signals.aluOperator = ALU_OR;
                XOR:  signals.aluOperator = ALU_XOR;
                NOR:  signals.aluOperator = ALU_NOR;
                SLT:  signals.aluOperator = ALU_LESS_THAN_SIGNED;
                SLTU: signals.aluOperator = ALU_LESS_THAN_UNSIGNED;
            endcase
            signals.regWriteEnabled = 1;
            signals.regWriteIdFrom = RD;
            signals.regDataWriteFrom = REG_WRITE_FROM_ALU_RESULT;
        end
        // rt = rs ?? imme
        ADDI, ADDIU, ANDI, ORI,
        XORI, SLTI, SLTIU: begin
            signals.regReadId1From = RS;
            signals.regDataRequiredStage = EXECUATION;
            signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            casex (instruction.instructionCode)
                ADDI:  signals.aluOperand2From = ALU_OPERAND_FROM_IMME_SIGNED;
                ADDIU: signals.aluOperand2From = ALU_OPERAND_FROM_IMME_SIGNED;
                ANDI:  signals.aluOperand2From = ALU_OPERAND_FROM_IMME_UNSIGNED;
                ORI:   signals.aluOperand2From = ALU_OPERAND_FROM_IMME_UNSIGNED;
                XORI:  signals.aluOperand2From = ALU_OPERAND_FROM_IMME_UNSIGNED;
                SLTI:  signals.aluOperand2From = ALU_OPERAND_FROM_IMME_SIGNED;
                SLTIU: signals.aluOperand2From = ALU_OPERAND_FROM_IMME_SIGNED;
            endcase
            casex (instruction.instructionCode)
                ADDI:  signals.aluOperator = ALU_ADD;
                ADDIU: signals.aluOperator = ALU_ADD;
                ANDI:  signals.aluOperator = ALU_AND;
                ORI:   signals.aluOperator = ALU_OR;
                XORI:  signals.aluOperator = ALU_XOR;
                SLTI:  signals.aluOperator = ALU_LESS_THAN_SIGNED;
                SLTIU: signals.aluOperator = ALU_LESS_THAN_UNSIGNED;
            endcase
            signals.regWriteEnabled = 1;
            signals.regWriteIdFrom = RT;
            signals.regDataWriteFrom = REG_WRITE_FROM_ALU_RESULT;
        end
        // if Compare(rs, rt) then pc += SignedExtend(imme)
        BEQ, BNE, BLEZ, BGTZ, BGEZ, BLTZ: begin
            signals.regReadId1From = RS;
            casex (instruction.instructionCode)
                BEQ:  signals.regReadId2From = RT;
                BNE:  signals.regReadId2From = RT;
                BLEZ: signals.regReadId2From = NAME_ZERO;
                BGTZ: signals.regReadId2From = NAME_ZERO;
                BGEZ: signals.regReadId2From = NAME_ZERO;
                BLTZ: signals.regReadId2From = NAME_ZERO;
            endcase
            signals.regDataRequiredStage = DECODE;
            casex (instruction.instructionCode)
                BEQ:  signals.pcJumpCondition = REG_READ_DATA_EQUAL;
                BNE:  signals.pcJumpCondition = REG_READ_DATA_NOT_EQUAL;
                BLEZ: signals.pcJumpCondition = REG_READ_DATA1_LESS_THAN_OR_EQUAL_TO_ZERO;
                BGTZ: signals.pcJumpCondition = REG_READ_DATA1_GREATER_THAN_ZERO;
                BGEZ: signals.pcJumpCondition = REG_READ_DATA1_GREATER_THAN_OR_EQUAL_TO_ZERO;
                BLTZ: signals.pcJumpCondition = REG_READ_DATA1_LESS_THAN_ZERO;
            endcase
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
        J, JAL: begin
            if (instruction.instructionCode inside {JAL}) begin
                signals.regWriteEnabled = 1;
                signals.regWriteIdFrom = NAME_RA;
                signals.regDataWriteFrom = REG_WRITE_FROM_PC_ADD_8;
            end
            signals.pcJumpCondition = TRUE;
            signals.pcJumpType = NEAR;
            signals.pcJumpInputFrom = JUMP_INPUT_FROM_IMME_UNSIGNED;
        end
        // pc = rs
        JR, JALR: begin
            if (instruction.instructionCode inside {JALR}) begin
                signals.regWriteEnabled = 1;
                signals.regWriteIdFrom = RD;
                signals.regDataWriteFrom = REG_WRITE_FROM_PC_ADD_8;
            end

            signals.regReadId1From = RS;
            signals.regDataRequiredStage = DECODE;
            signals.pcJumpCondition = TRUE;
            signals.pcJumpType = FAR;
            signals.pcJumpInputFrom = JUMP_INPUT_FROM_REG_READ1;
        end
        LW, SW: begin
            signals.regReadId1From = RS;
            signals.aluOperand1From = ALU_OPERAND_FROM_REG_READ1;
            signals.aluOperand2From = ALU_OPERAND_FROM_IMME_SIGNED;
            signals.aluOperator = ALU_ADD;
            casex (instruction.instructionCode)
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
    endcase
end

endmodule

`endif // COUNTROLLER_UNIT_INCLUDED
