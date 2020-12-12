`ifndef DEFINITIONS_INCLUDED
`define DEFINITIONS_INCLUDED

typedef logic [31:0] int_t;
typedef logic [15:0] short_t;
typedef logic [7:0] byte_t;

`define NTH_BYTE(i) ((i + 1) * 8 - 1):(i * 8)
`define NTH_HALF_WORD(i) ((i + 1) * 16 - 1):(i * 16)

`endif // DEFINITIONS_INCLUDED
