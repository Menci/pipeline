`ifndef DEFINITIONS_INCLUDED
`define DEFINITIONS_INCLUDED

// Instruction memory & data memory size
`define IM_SIZE_BIT 12
`define DM_SIZE_BIT 13

`define IM_WORDS (1 << (`IM_SIZE_BIT - 2))
`define DM_WORDS (1 << (`DM_SIZE_BIT - 2))

// Multiplication & division delay cycles
`define MUL_DELAY_CYCLES 5
`define DIV_DELAY_CYCLES 5

typedef logic [63:0] long_t;
typedef logic [31:0] int_t;
typedef logic [15:0] short_t;
typedef logic [7:0] byte_t;

`define NTH_BYTE(i) ((i + 1) * 8 - 1):(i * 8)
`define NTH_HALF_WORD(i) ((i + 1) * 16 - 1):(i * 16)

`endif // DEFINITIONS_INCLUDED
