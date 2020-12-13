# Pipeline

Pipelined MIPS processor in Verilog.

Supported instructions:

```
* add, addu, sub, subu, sll, srl, sra, sllv, srlv, srav, and, or, xor, nor, slt, sltu
* addi, addiu, andi, ori, xori, slti, sltiu
* lui
* mult, multu, div, divu, mfhi, mflo, mthi, mtlo
* beq, bne, blez, bgtz, bltz, bgez
* jr, jalr, j, jal
* lb, lbu, lh, lhu, lw, sb, sh, sw
* syscall (issues a $stop to pause simulation)
```

Advanced features such as exceptions, interrupts, privilege level and paging are NOT supported.

Run it with Vivado. The testbench file is:

```verilog
module mips_tb;

reg reset, clock;

TopLevel topLevel(.reset(reset), .clock(clock));

integer k;
initial begin
    reset = 1;
    clock = 0; #1;
    clock = 1; #1;
    clock = 0; #1;
    reset = 0; #1;
    
    $stop;

    #1;
    for (k = 0; k < 5000; k = k + 1) begin
        clock = 1; #5;
        clock = 0; #5;
    end

    $finish;
end
    
endmodule
```
