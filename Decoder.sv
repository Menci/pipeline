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

typedef enum logic [`INST_OP_HIGH - `INST_OP_LOW:0] {
    R   = 6'b000000,
    ORI = 6'b001101,
    LW  = 6'b100011,
    SW  = 6'b101011,
    BEQ = 6'b000100,
    BNE = 6'b000101,
    LUI = 6'b001111,
    JAL = 6'b000011
} operation_code_t;

typedef enum logic [`INST_FUNC_HIGH - `INST_FUNC_LOW:0] {
    R_ADDU    = 6'b100001,
    R_SUBU    = 6'b100011,
    R_JR      = 6'b001000,
    R_SYSCALL = 6'b001100
} function_code_t;

typedef logic [`INST_SH_HIGH - `INST_SH_LOW:0] shift_amount_t;
typedef logic [`INST_IMME_HIGH - `INST_IMME_LOW:0] immediate_t;
typedef logic [`INST_ADDR_HIGH - `INST_ADDR_LOW:0] absolute_jump_input_t;

typedef struct packed {
    operation_code_t operationCode;
    register_id_t registerS;
    register_id_t registerT;
    register_id_t registerD;
    shift_amount_t shiftAmount;
    function_code_t functionCode;
    immediate_t immediate;
    absolute_jump_input_t absoluteJumpInput;
} instruction_t;

module Decoder(
    input int_t instructionData,
    output instruction_t instruction
);

assign instruction.operationCode = operation_code_t'(instructionData[`INST_OP_HIGH:`INST_OP_LOW]);
assign instruction.registerS = register_id_t'(instructionData[`INST_RS_HIGH:`INST_RS_LOW]);
assign instruction.registerT = register_id_t'(instructionData[`INST_RT_HIGH:`INST_RT_LOW]);
assign instruction.registerD = register_id_t'(instructionData[`INST_RD_HIGH:`INST_RD_LOW]);
assign instruction.shiftAmount = instructionData[`INST_SH_HIGH:`INST_SH_LOW];
assign instruction.functionCode = function_code_t'(instructionData[`INST_FUNC_HIGH:`INST_FUNC_LOW]);
assign instruction.immediate = instructionData[`INST_IMME_HIGH:`INST_IMME_LOW];
assign instruction.absoluteJumpInput = instructionData[`INST_ADDR_HIGH:`INST_ADDR_LOW];

endmodule

`endif // DECODER_INCLUDED
