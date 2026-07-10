// Safely pass data from one clock domain to another.
// Do not directly pass multi-bit binary counters across clock domains.
// Instead: binary pointer -> Gray-code pointer -> two-flop synchronizer -> compare
// Gray Code: Only one bit changes at a time. This reduces ambiguity when the other clock domain samples the pointer.

module asyncFifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic writeClk,
    input logic writeRst_n,
    input logic writeEnable,
    input logic [DATA_WIDTH-1:0] writeData,
    output logic full,

    input logic readClk,
    input logic readRst_n,
    input logic readEnable,
    output logic [DATA_WIDTH-1:0] readData,
    output logic empty
);

    localparam int DEPTH = 1 << ADDR_WIDTH; // Memory Depth = 2^ADDR_WIDTH = 16
    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Binary pointers are used locally for addressing memory
    // ADDR_WIDTH + 1, extra MSB distinguishes full from empty
    logic [ADDR_WIDTH:0] writeBinary;
    logic [ADDR_WIDTH:0] writeBinaryNext;
    logic [ADDR_WIDTH:0] readBinary;
    logic [ADDR_WIDTH:0] readBinaryNext;

    // Gray-code pointers are used for clock-domain crossing
    logic [ADDR_WIDTH:0] writeGray;
    logic [ADDR_WIDTH:0] writeGrayNext;
    logic [ADDR_WIDTH:0] readGray;
    logic [ADDR_WIDTH:0] readGrayNext;

    // Synchronized pointers crossing into the opposite clock domain
    logic [ADDR_WIDTH:0] readGrayWriteClk1;
    logic [ADDR_WIDTH:0] readGrayWriteClk2;
    logic [ADDR_WIDTH:0] writeGrayReadClk1;
    logic [ADDR_WIDTH:0] writeGrayReadClk2;

    logic writeValid;
    logic readValid;
    logic fullNext;
    logic emptyNext;

    assign writeValid = writeEnable && !full;
    assign readValid = readEnable && !empty;

    function automatic logic [ADDR_WIDTH:0] binaryToGray(input logic [ADDR_WIDTH:0] binaryValue);
        begin
            binaryToGray = binaryValue ^ (binaryValue >> 1);  // Binary to Gray-code conversion formula
            // "^" is bitwise XOR
        end
    endfunction

    // Local Next pointers
    assign writeBinaryNext = writeBinary + writeValid;
    assign readBinaryNext = readBinary + readValid;

    assign writeGrayNext = binaryToGray(writeBinaryNext);
    assign readGrayNext = binaryToGray(readBinaryNext);

    // Full detection
    // FIFO is full when advancing the write pointer would make it equal to
    // the read pointer with the two most-significant Gray-code bits inverted.
    assign fullNext = (writeGrayNext == {~readGrayWriteClk2[ADDR_WIDTH:ADDR_WIDTH-1],readGrayWriteClk2[ADDR_WIDTH-2:0]});

    // Empty detection.
    // FIFO is empty when the next read pointer equals the synchronized write pointer.
    assign emptyNext = (readGrayNext == writeGrayReadClk2);

    // Write clock domain.
    always_ff @(posedge writeClk or negedge writeRst_n) begin
        if (!writeRst_n) begin
            writeBinary <= '0;
            writeGray <= '0;

            readGrayWriteClk1 <= '0;
            readGrayWriteClk2 <= '0;

            full <= 1'b0;
        end else begin
            // Synchronize read pointer into write clock domain.
            readGrayWriteClk1 <= readGray;
            readGrayWriteClk2 <= readGrayWriteClk1;

            // Write data only when FIFO is not full.
            if (writeValid) begin
                memory[writeBinary[ADDR_WIDTH-1:0]] <= writeData;
                writeBinary <= writeBinaryNext;
                writeGray <= writeGrayNext;
            end

            full <= fullNext;
        end
    end

    // Read clock domain.
    always_ff @(posedge readClk or negedge readRst_n) begin
        if (!readRst_n) begin
            readBinary <= '0;
            readGray <= '0;

            writeGrayReadClk1 <= '0;
            writeGrayReadClk2 <= '0;

            readData <= '0;
            empty <= 1'b1;
        end else begin
            // Synchronize write pointer into read clock domain.
            writeGrayReadClk1 <= writeGray;
            writeGrayReadClk2 <= writeGrayReadClk1;

            // Read data only when FIFO is not empty.
            if (readValid) begin
                readData <= memory[readBinary[ADDR_WIDTH-1:0]];
                readBinary <= readBinaryNext;
                readGray <= readGrayNext;
            end

            empty <= emptyNext;
        end
    end

endmodule