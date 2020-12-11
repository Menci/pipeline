`ifndef DEBUG_INCLUDED
`define DEBUG_INCLUDED

`include "Definitions.sv"
`include "Decoder.sv"

`ifndef SYNTHESIS
`define DEBUG_INSTRUCTION_CODE_ENUM
`endif

`ifdef DEBUG_INSTRUCTION_CODE_ENUM
function instruction_code_t getInstructionCode(input int_t instructionData);
    casex (instruction_code_t'(instructionData))
        ADD:     return ADD;
        ADDU:    return ADDU;
        SUB:     return SUB;
        SUBU:    return SUBU;
        SLL:     return SLL;
        SRL:     return SRL;
        SRA:     return SRA;
        SLLV:    return SLLV;
        SRLV:    return SRLV;
        SRAV:    return SRAV;
        AND:     return AND;
        OR:      return OR;
        XOR:     return XOR;
        NOR:     return NOR;
        SLT:     return SLT;
        SLTU:    return SLTU;
        MULT:    return MULT;
        MULTU:   return MULTU;
        DIV:     return DIV;
        DIVU:    return DIVU;
        MFHI:    return MFHI;
        MTHI:    return MTHI;
        MFLO:    return MFLO;
        MTLO:    return MTLO;
        JR:      return JR;
        JALR:    return JALR;
        SYSCALL: return SYSCALL;
        ADDI:    return ADDI;
        ADDIU:   return ADDIU;
        ANDI:    return ANDI;
        ORI:     return ORI;
        XORI:    return XORI;
        SLTI:    return SLTI;
        SLTIU:   return SLTIU;
        LUI:     return LUI;
        BEQ:     return BEQ;
        BNE:     return BNE;
        BLEZ:    return BLEZ;
        BGTZ:    return BGTZ;
        BGEZ:    return BGEZ;
        BLTZ:    return BLTZ;
        J:       return J;
        JAL:     return JAL;
        LB:      return LB;
        LBU:     return LBU;
        LH:      return LH;
        LHU:     return LHU;
        LW:      return LW;
        SB:      return SB;
        SH:      return SH;
        SW:      return SW;
    endcase
endfunction
`endif

`endif // DEBUG_INCLUDED
