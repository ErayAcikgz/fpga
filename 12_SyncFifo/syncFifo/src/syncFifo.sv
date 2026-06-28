// Parameterized module, makes module reusable, can instantiate a different FIFO later
module syncFifo #(                      // Constants, compile-time
    parameter int DATA_WIDTH = 8,       
    parameter int DEPTH = 16,
    parameter int ADDR_WIDTH = 4
) (                                     // Ports
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
    
    // logic [MSB_index:LSB_index] "variableName" [indexFirstAddress:indexLastAddress]
    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];  

    logic [ADDR_WIDTH-1:0] writePointer;
    logic [ADDR_WIDTH-1:0] readPointer;

    logic writeValid;
    logic readValid;

    assign full = (count == DEPTH);     // Combinational: updates when "count" changes
    assign empty = (count == 0);

    assign writeValid = writeEnable && !full;
    assign readValid = readEnable && !empty;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin     // Sequential: clock dependent
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
endmodule