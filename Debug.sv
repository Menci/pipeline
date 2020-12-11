`ifndef DEBUG_INCLUDED
`define DEBUG_INCLUDED

`include "Definitions.sv"
`include "Decoder.sv"

`ifndef SYNTHESIS
function string inspect(input instruction_t instruction);
    casez (instruction.operationCode)
        R:
            casez (instruction.functionCode)
                // rd = rs + rt
                R_ADDU:
                    return $sformatf(
                        "(addu) %s = %s + %s",
                        instruction.registerD.name(),
                        instruction.registerS.name(),
                        instruction.registerT.name()
                    );
                R_SUBU:
                    return $sformatf(
                        "(subu) %s = %s - %s",
                        instruction.registerD.name(),
                        instruction.registerS.name(),
                        instruction.registerT.name()
                    );
                R_JR:
                    return $sformatf(
                        "(jr) pc = %s",
                        instruction.registerS.name()
                    );
                R_SYSCALL:
                    return $sformatf(
                        "(syscall)"
                    );
            endcase
        ORI:
            return $sformatf(
                "(ori) %s = %s | 0x%h",
                instruction.registerT.name(),
                instruction.registerS.name(),
                instruction.immediate
            );
        LW:
            return $sformatf(
                "(lw) %s = *(%s + 0x%h)",
                instruction.registerT.name(),
                instruction.registerS.name(),
                instruction.immediate
            );
        SW:
            return $sformatf(
                "(sw) *(%s + 0x%h) = %s",
                instruction.registerS.name(),
                instruction.immediate,
                instruction.registerT.name()
            );
        BEQ:
            return $sformatf(
                "(beq) %s == %s => PC += 0x%h",
                instruction.registerS.name(),
                instruction.registerT.name(),
                instruction.immediate
            );
        BNE:
            return $sformatf(
                "(bne) %s != %s => PC += 0x%h",
                instruction.registerS.name(),
                instruction.registerT.name(),
                instruction.immediate
            );
        LUI:
            return $sformatf(
                "(lui) %s = 0x%h << 16",
                instruction.registerT.name(),
                instruction.immediate
            );
        JAL:
            return $sformatf(
                "(jal) PC = NearJump(PC, 0x%h)",
                instruction.immediate
            );
    endcase
endfunction
`else
function logic inspect(input instruction_t instruction);
    return 0;
endfunction
`endif

`endif // DEBUG_INCLUDED
