# Pipeline

Pipelined MIPS processor in Verilog.

Supported instructions:

```
* addu, subu
* ori
* lw, sw
* beq, bne
* lui
* jr, jal
* syscall (issues a $stop to pause simulation)
```

Run it with Vivado. The testbench file is:

```verilog
module mips_tb;

reg reset;
reg clock;

integer k;

TopLevel topLevel(.reset(reset), .clock(clock));

initial begin
    reset = 1;

    clock = 0;
    #1;
    clock = 1;
    #1;
    clock = 0;
    #1;
    
    reset = 0;
    #1;
    
    $stop;
    
    #1;

    for (k = 0; k < 5000; k = k + 1) begin
        clock = 1;
        #5;
        clock = 0;
        #5;
    end

    $finish;
end
    
endmodule
```
