// Adds verification checks to a FIFO
// "Did the design ever violate a rule?"

module checkedSyncFifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16,
    parameter int ADDR_WIDTH = 4
) (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic writeEnable,
    input logic [DATA_WIDTH-1:0] writeData,
    output logic full,

    input logic readEnable,
    output logic [DATA_WIDTH-1:0] readData,
    output logic empty,

    output logic [ADDR_WIDTH:0] count
);

    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    logic [ADDR_WIDTH-1:0] writePointer;
    logic [ADDR_WIDTH-1:0] readPointer;

    logic writeValid;
    logic readValid;

    assign full = (count == DEPTH);
    assign empty = (count == 0);

    assign writeValid = writeEnable && !full;
    assign readValid = readEnable && !empty;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            writePointer <= '0;
            readPointer <= '0;
            readData <= '0;
            count <= '0;
        end else begin
            if (writeValid) begin
                memory[writePointer] <= writeData;
                writePointer <= writePointer + 1'b1;
            end

            if (readValid) begin
                readData <= memory[readPointer];
                readPointer <= readPointer + 1'b1;
            end

            case ({writeValid, readValid})
                2'b10: begin
                    count <= count + 1'b1;
                end

                2'b01: begin
                    count <= count - 1'b1;
                end

                default: begin
                    count <= count;
                end
            endcase
        end
    end

    // Assertions below are checked during simulation
    // If a condition becomes false, the simulator prints an error
    // `ifndef SYNTHESIS prevents these checks from being synthesized into FPGA hardware by synthesis tools.

    `ifndef SYNTHESIS

    // Previous-cycle copies
    // These help check that illegal writes/reads did not incorrectly change count
    logic [ADDR_WIDTH:0] previousCount;
    logic previousFull;
    logic previousEmpty;
    logic previousWriteEnable;
    logic previousReadEnable;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            previousCount <= '0;
            previousFull <= 1'b0;
            previousEmpty <= 1'b1;
            previousWriteEnable <= 1'b0;
            previousReadEnable <= 1'b0;
        end else begin
            previousCount <= count;
            previousFull <= full;
            previousEmpty <= empty;
            previousWriteEnable <= writeEnable;
            previousReadEnable <= readEnable;
        end
    end

    always_ff @(posedge sys_clk) begin
        if (sys_rst_n) begin
            // Count must never exceed FIFO depth
            assert (count <= DEPTH)
                else $error("ASSERT FAILED: count exceeded DEPTH. count=%0d DEPTH=%0d", count, DEPTH);

            // Flag consistency
            assert (full == (count == DEPTH))
                else $error("ASSERT FAILED: full flag inconsistent with count.");

            assert (empty == (count == 0))
                else $error("ASSERT FAILED: empty flag inconsistent with count.");

            // full and empty should not both be true for a nonzero-depth FIFO
            assert (!(full && empty))
                else $error("ASSERT FAILED: full and empty both high.");

            // If previous cycle attempted write while full and no read happened, count must not increase
            if (previousWriteEnable && previousFull && !previousReadEnable) begin
                assert (count == previousCount)
                    else $error("ASSERT FAILED: write while full changed count.");
            end

            // If previous cycle attempted read while empty and no write happened, count must not decrease
            if (previousReadEnable && previousEmpty && !previousWriteEnable) begin
                assert (count == previousCount)
                    else $error("ASSERT FAILED: read while empty changed count.");
            end
        end
    end

    `endif

endmodule