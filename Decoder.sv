`ifndef DECODER_INCLUDED
`define DECODER_INCLUDED

`include "Definitions.sv"
`include "GeneralPurposeRegisters.sv"

`define INST_OP_HIGH        31
`define INST_OP_LOW         26

`define INST_RS_HIGH        25
`define INST_RS_LOW         21
`define INST_RT_HIGH        20
`define INST_RT_LOW         16
`define INST_RD_HIGH        15
`define INST_RD_LOW         11

// R only
`define INST_SH_HIGH      10
`define INST_SH_LOW       6
`define INST_FUNC_HIGH    5
`define INST_FUNC_LOW     0

// I only
`define INST_IMME_HIGH    15
`define INST_IMME_LOW     0

// J only
`define INST_ADDR_HIGH    25
`define INST_ADDR_LOW     0

typedef enum logic [31:0] {
    ADD     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100000,
    ADDU    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100001,
    SUB     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100010,
    SUBU    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100011,
    SLL     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_000000,
    SRL     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_000010,
    SRA     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_000011,
    SLLV    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_000100,
    SRLV    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_000110,
    SRAV    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_000111,
    AND     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100100,
    OR      = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100101,
    XOR     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100110,
    NOR     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_100111,
    SLT     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_101010,
    SLTU    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_101011,

    MULT    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_011000,
    MULTU   = 32'b000000_XXXXXXXXXXXXXXXXXXXX_011001,
    DIV     = 32'b000000_XXXXXXXXXXXXXXXXXXXX_011010,
    DIVU    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_011011,
    MFHI    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_010000,
    MTHI    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_010001,
    MFLO    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_010010,
    MTLO    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_010011,

    JR      = 32'b000000_XXXXXXXXXXXXXXXXXXXX_001000,
    JALR    = 32'b000000_XXXXXXXXXXXXXXXXXXXX_001001,
    SYSCALL = 32'b000000_XXXXXXXXXXXXXXXXXXXX_001100,

    ADDI    = 32'b001000_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    ADDIU   = 32'b001001_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    ANDI    = 32'b001100_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    ORI     = 32'b001101_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    XORI    = 32'b001110_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    SLTI    = 32'b001010_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    SLTIU   = 32'b001011_XXXXXXXXXXXXXXXXXXXX_XXXXXX,

    LUI     = 32'b001111_XXXXXXXXXXXXXXXXXXXX_XXXXXX,

    BEQ     = 32'b000100_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    BNE     = 32'b000101_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    BLEZ    = 32'b000110_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    BGTZ    = 32'b000111_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    BGEZ    = 32'b000001_XXXXX00001XXXXXXXXXX_XXXXXX,
    BLTZ    = 32'b000001_XXXXX00000XXXXXXXXXX_XXXXXX,

    J       = 32'b000010_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    JAL     = 32'b000011_XXXXXXXXXXXXXXXXXXXX_XXXXXX,

    LB      = 32'b100000_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    LBU     = 32'b100100_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    LH      = 32'b100001_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    LHU     = 32'b100101_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    LW      = 32'b100011_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    SB      = 32'b101000_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    SH      = 32'b101001_XXXXXXXXXXXXXXXXXXXX_XXXXXX,
    SW      = 32'b101011_XXXXXXXXXXXXXXXXXXXX_XXXXXX
} instruction_code_t;

typedef logic [`INST_SH_HIGH - `INST_SH_LOW:0] shift_amount_t;
typedef logic [`INST_IMME_HIGH - `INST_IMME_LOW:0] immediate_t;
typedef logic [`INST_ADDR_HIGH - `INST_ADDR_LOW:0] absolute_jump_input_t;

typedef struct packed {
    instruction_code_t instructionCode;
    register_id_t registerS;
    register_id_t registerT;
    register_id_t registerD;
    shift_amount_t shiftAmount;
    immediate_t immediate;
    absolute_jump_input_t absoluteJumpInput;
} instruction_t;

// Include the file after enum
`include "Debug.sv"

module Decoder(
    input int_t instructionData,
    output instruction_t instruction
);

always_comb begin
`ifdef DEBUG_INSTRUCTION_CODE_ENUM
    instruction.instructionCode = instruction_code_t'(instructionData);
`else
    instruction.instructionCode = getInstructionCode(instructionData);
`endif
    instruction.registerS = register_id_t'(instructionData[`INST_RS_HIGH:`INST_RS_LOW]);
    instruction.registerT = register_id_t'(instructionData[`INST_RT_HIGH:`INST_RT_LOW]);
    instruction.registerD = register_id_t'(instructionData[`INST_RD_HIGH:`INST_RD_LOW]);
    instruction.shiftAmount = instructionData[`INST_SH_HIGH:`INST_SH_LOW];
    instruction.immediate = instructionData[`INST_IMME_HIGH:`INST_IMME_LOW];
    instruction.absoluteJumpInput = instructionData[`INST_ADDR_HIGH:`INST_ADDR_LOW];
end

endmodule

`endif // DECODER_INCLUDED
