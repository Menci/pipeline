`ifndef COUNTROLLER_UNIT_INCLUDED
`define COUNTROLLER_UNIT_INCLUDED

`include "ProgramCounter.sv"
`include "Instruction.sv"
`include "ArithmeticLogicUnit.sv"
`include "MultiplicationDivisionUnit.sv"
`include "GeneralPurposeRegisters.sv"
`include "DataMemory.sv"

typedef enum logic [2:0] {
    REG_WRITE_FROM_ALU_RESULT,
    REG_WRITE_FROM_MDU_DATA_READ,
    REG_WRITE_FROM_DM_READ,
    REG_WRITE_FROM_PC_ADD_8,
    REG_WRITE_FROM_IMME_LSHIFTED
} reg_write_from_t;

typedef enum logic [2:0] {
    ALU_MDU_OPERAND_FROM_REG_READ1,
    ALU_MDU_OPERAND_FROM_REG_READ2,
    ALU_MDU_OPERAND_FROM_IMME_UNSIGNED,
    ALU_MDU_OPERAND_FROM_IMME_SIGNED,
    ALU_MDU_OPERAND_FROM_SHIFT_AMOUNT
} alu_mdu_operand_from_t;

typedef enum logic [0:0] {
    DM_WRITE_FROM_REG_READ2
} dm_write_from_t;

typedef enum logic [1:0] {
    JUMP_INPUT_FROM_REG_READ1,
    JUMP_INPUT_FROM_IMME_UNSIGNED,
    JUMP_INPUT_FROM_IMME_SIGNED
} jump_input_from_t;

typedef enum logic [2:0] {
    NAME_ZERO,
    RS,
    RT,
    RD,
    NAME_RA    // ra = 31
} register_id_from_t;

typedef enum logic [2:0] {
    FALSE,
    TRUE,
    REG_READ_DATA_EQUAL,
    REG_READ_DATA_NOT_EQUAL,
    REG_READ_DATA1_LESS_THAN_ZERO,
    REG_READ_DATA1_LESS_THAN_OR_EQUAL_TO_ZERO,
    REG_READ_DATA1_GREATER_THAN_ZERO,
    REG_READ_DATA1_GREATER_THAN_OR_EQUAL_TO_ZERO
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
    register_data_required_stage_t regData1RequiredStage;
    register_data_required_stage_t regData2RequiredStage;
    register_id_from_t regWriteIdFrom;
    logic regWriteEnabled;
    reg_write_from_t regDataWriteFrom;
    dm_read_extract_extend_type_t dmReadExtractExtendType;
    alu_mdu_operand_from_t aluMduOperand1From;
    alu_mdu_operand_from_t aluMduOperand2From;
    alu_operator_t aluOperator;
    mdu_operation_t mduOperation;
    logic mduUse;
    logic mduStart;
    dm_write_type_t dmWriteType;
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
    signals.regData1RequiredStage = NONE;
    signals.regData2RequiredStage = NONE;
    signals.regWriteIdFrom = NAME_ZERO;
    signals.regWriteEnabled = 0;
    signals.regDataWriteFrom = REG_WRITE_FROM_ALU_RESULT;
    signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_REG_READ1;
    signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_REG_READ1;
    signals.aluOperator = ALU_ADD;
    signals.mduOperation = MDU_READ_HI;
    signals.mduUse = 0;
    signals.mduStart = 0;
    signals.dmWriteType = WRITE_DISABLED;
    signals.dmDataWriteFrom = DM_WRITE_FROM_REG_READ2;
    signals.dmReadExtractExtendType = ORIGINAL;
    signals.pcJumpCondition = FALSE;
    signals.pcJumpType = NEAR;
    signals.pcJumpInputFrom = JUMP_INPUT_FROM_REG_READ1;

    casez (instruction.instructionCode)
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
            casez (instruction.instructionCode)
                SLL:     signals.regReadId1From = NAME_ZERO;
                SRL:     signals.regReadId1From = NAME_ZERO;
                SRA:     signals.regReadId1From = NAME_ZERO;
                default: signals.regReadId1From = RS;
            endcase
            signals.regReadId2From = RT;
            signals.regData1RequiredStage = EXECUATION;
            signals.regData2RequiredStage = EXECUATION;
            casez (instruction.instructionCode)
                SLL:     signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_SHIFT_AMOUNT;
                SRL:     signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_SHIFT_AMOUNT;
                SRA:     signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_SHIFT_AMOUNT;
                default: signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_REG_READ1;
            endcase
            signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_REG_READ2;
            casez (instruction.instructionCode)
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
            signals.regData1RequiredStage = EXECUATION;
            signals.regData2RequiredStage = EXECUATION;
            signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_REG_READ1;
            casez (instruction.instructionCode)
                ADDI:  signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_SIGNED;
                ADDIU: signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_SIGNED;
                ANDI:  signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_UNSIGNED;
                ORI:   signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_UNSIGNED;
                XORI:  signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_UNSIGNED;
                SLTI:  signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_SIGNED;
                SLTIU: signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_SIGNED;
            endcase
            casez (instruction.instructionCode)
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
            casez (instruction.instructionCode)
                BEQ:  signals.regReadId2From = RT;
                BNE:  signals.regReadId2From = RT;
                BLEZ: signals.regReadId2From = NAME_ZERO;
                BGTZ: signals.regReadId2From = NAME_ZERO;
                BGEZ: signals.regReadId2From = NAME_ZERO;
                BLTZ: signals.regReadId2From = NAME_ZERO;
            endcase
            signals.regData1RequiredStage = DECODE;
            signals.regData2RequiredStage = DECODE;
            casez (instruction.instructionCode)
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
            signals.regData1RequiredStage = DECODE;
            signals.pcJumpCondition = TRUE;
            signals.pcJumpType = FAR;
            signals.pcJumpInputFrom = JUMP_INPUT_FROM_REG_READ1;
        end
        LB, LBU, LH, LHU, LW, SB, SH, SW: begin
            signals.regReadId1From = RS;
            signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_REG_READ1;
            signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_IMME_SIGNED;
            signals.aluOperator = ALU_ADD;
            casez (instruction.instructionCode)
                // rt = *(rs + imme)
                LB, LBU, LH, LHU, LW: begin
                    signals.regData1RequiredStage = EXECUATION; // Address
                    signals.regWriteEnabled = 1;
                    signals.regWriteIdFrom = RT;
                    signals.regDataWriteFrom = REG_WRITE_FROM_DM_READ;
                    casez (instruction.instructionCode)
                        LB:  signals.dmReadExtractExtendType = BYTE_SIGNED;
                        LBU: signals.dmReadExtractExtendType = BYTE_UNSIGNED;
                        LH:  signals.dmReadExtractExtendType = HALF_WORD_SIGNED;
                        LHU: signals.dmReadExtractExtendType = HALF_WORD_UNSIGNED;
                        LW:  signals.dmReadExtractExtendType = ORIGINAL;
                    endcase
                end
                // *(rs + imme) = rt
                SB, SH, SW: begin
                    signals.regData1RequiredStage = EXECUATION; // Address
                    signals.regData2RequiredStage = MEMORY;     // Data
                    signals.regReadId2From = RT;
                    casez (instruction.instructionCode)
                        SB: signals.dmWriteType = WRITE_BYTE;
                        SH: signals.dmWriteType = WRITE_HALF_WORD;
                        SW: signals.dmWriteType = WRITE_WORD;
                    endcase
                    signals.dmDataWriteFrom = DM_WRITE_FROM_REG_READ2;
                end
            endcase
        end
        MULT, MULTU, DIV, DIVU: begin
            signals.regReadId1From = RS;
            signals.regReadId2From = RT;
            signals.regData1RequiredStage = EXECUATION;
            signals.regData2RequiredStage = EXECUATION;
            signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_REG_READ1;
            signals.aluMduOperand2From = ALU_MDU_OPERAND_FROM_REG_READ2;
            signals.mduUse = 1;
            signals.mduStart = 1;
            casez (instruction.instructionCode)
                MULT:  signals.mduOperation = MDU_START_SIGNED_MUL;
                MULTU: signals.mduOperation = MDU_START_UNSIGNED_MUL;
                DIV:   signals.mduOperation = MDU_START_SIGNED_DIV;
                DIVU:  signals.mduOperation = MDU_START_UNSIGNED_DIV;
            endcase
        end
        MFHI, MFLO: begin
            signals.mduUse = 1;
            casez (instruction.instructionCode)
                MFHI: signals.mduOperation = MDU_READ_HI;
                MFLO: signals.mduOperation = MDU_READ_LO;
            endcase
            signals.regWriteIdFrom = RD;
            signals.regWriteEnabled = 1;
            signals.regDataWriteFrom = REG_WRITE_FROM_MDU_DATA_READ;
        end
        MTHI, MTLO: begin
            signals.regReadId1From = RS;
            signals.regData1RequiredStage = EXECUATION;
            signals.aluMduOperand1From = ALU_MDU_OPERAND_FROM_REG_READ1;
            signals.mduUse = 1;
            casez (instruction.instructionCode)
                MTHI: signals.mduOperation = MDU_WRITE_HI;
                MTLO: signals.mduOperation = MDU_WRITE_LO;
            endcase
        end
    endcase
end

endmodule

`endif // COUNTROLLER_UNIT_INCLUDED
