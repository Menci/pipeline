`ifndef DATA_MEMORY_INCLUDED
`define DATA_MEMORY_INCLUDED

`include "Definitions.sv"

typedef enum logic [1:0] {
    WRITE_DISABLED,
    WRITE_BYTE,
    WRITE_HALF_WORD,
    WRITE_WORD
} dm_write_type_t;

typedef enum logic [2:0] {
    ORIGINAL,
    BYTE_SIGNED,
    BYTE_UNSIGNED,
    HALF_WORD_SIGNED,
    HALF_WORD_UNSIGNED
} dm_read_extract_extend_type_t;

module DataMemory(
    input logic clock,
    input int_t address,
    input dm_read_extract_extend_type_t extractExtendType,
    input dm_write_type_t writeType,
    input int_t dataWrite,

    output int_t dataRead,

    input int_t programCounter
);

logic [`DM_SIZE_BIT - 1:2] memoryAddress;
assign memoryAddress = address[`DM_SIZE_BIT - 1:2];

int_t memory [`DM_WORDS - 1:0];

// Initialization
initial begin
    for (integer i = 0; i < `DM_WORDS; i++)
        memory[i] = 0;
end

// Read
int_t originalDataRead;
assign originalDataRead = memory[memoryAddress];

byte_t extractedByte;
short_t extractedHalfWord;

always_comb begin
    extractedByte = 8'b0;
    extractedHalfWord = 16'b0;
    dataRead = originalDataRead;

    // Unaligned load
    case (extractExtendType)
        BYTE_SIGNED, BYTE_UNSIGNED: begin
            case (address[1:0])
                // [0, 8)
                2'b00: extractedByte = originalDataRead[`NTH_BYTE(0)];
                // [8, 16)
                2'b01: extractedByte = originalDataRead[`NTH_BYTE(1)];
                // [16, 24)
                2'b10: extractedByte = originalDataRead[`NTH_BYTE(2)];
                // [24, 32)
                2'b11: extractedByte = originalDataRead[`NTH_BYTE(3)];
            endcase

            case (extractExtendType)
                BYTE_SIGNED:   dataRead = {{24{extractedByte[7]}}, extractedByte};
                BYTE_UNSIGNED: dataRead = {24'b0, extractedByte};
            endcase
        end
        HALF_WORD_SIGNED, HALF_WORD_UNSIGNED: begin
            case (address[1])
                // [0, 16)
                1'b0: extractedHalfWord = originalDataRead[`NTH_HALF_WORD(0)];
                // [16, 32)
                1'b1: extractedHalfWord = originalDataRead[`NTH_HALF_WORD(1)];
            endcase

            case (extractExtendType)
                HALF_WORD_SIGNED:   dataRead = {{16{extractedHalfWord[15]}}, extractedHalfWord};
                HALF_WORD_UNSIGNED: dataRead = {16'b0, extractedHalfWord};
            endcase
        end
    endcase
end

// Write
logic writeEnabled;
int_t dataBeforeWrite, computedDataWrite;

always_comb begin
    writeEnabled = writeType != WRITE_DISABLED;
    dataBeforeWrite = memory[memoryAddress];
    computedDataWrite = 0;

    // Unaligned store
    case (writeType)
        WRITE_BYTE:
            case (address[1:0])
                // [0, 8)
                2'b00: computedDataWrite = {dataBeforeWrite[`NTH_BYTE(3)], dataBeforeWrite[`NTH_BYTE(2)], dataBeforeWrite[`NTH_BYTE(1)], dataWrite[`NTH_BYTE(0)]};
                // [8, 16)
                2'b01: computedDataWrite = {dataBeforeWrite[`NTH_BYTE(3)], dataBeforeWrite[`NTH_BYTE(2)], dataWrite[`NTH_BYTE(0)], dataBeforeWrite[`NTH_BYTE(0)]};
                // [16, 24)
                2'b10: computedDataWrite = {dataBeforeWrite[`NTH_BYTE(3)], dataWrite[`NTH_BYTE(0)], dataBeforeWrite[`NTH_BYTE(1)], dataBeforeWrite[`NTH_BYTE(0)]};
                // [24, 32)
                2'b11: computedDataWrite = {dataWrite[`NTH_BYTE(0)], dataBeforeWrite[`NTH_BYTE(2)], dataBeforeWrite[`NTH_BYTE(1)], dataBeforeWrite[`NTH_BYTE(0)]};
            endcase
        WRITE_HALF_WORD:
            case (address[1])
                // [0, 16)
                1'b0: computedDataWrite = {dataBeforeWrite[`NTH_HALF_WORD(1)], dataWrite[`NTH_HALF_WORD(0)]};
                // [16, 32)
                1'b1: computedDataWrite = {dataWrite[`NTH_HALF_WORD(0)], dataBeforeWrite[`NTH_HALF_WORD(0)]};
            endcase
        WRITE_WORD:
            computedDataWrite = dataWrite;
    endcase
end

always_ff @ (posedge clock)
    if (writeEnabled)
        memory[memoryAddress] <= computedDataWrite;

// Validation output
always_ff @ (posedge clock)
    if (writeEnabled)
        $display("@%h: *%h <= %h", programCounter, {{32 - `DM_SIZE_BIT{1'b0}}, memoryAddress, 2'b0}, computedDataWrite);

endmodule

`endif // DATA_MEMORY_INCLUDED
