// One-word valid/ready stream register.
// Stores one DATA_WIDTH-wide word.

// A transfer happens only when valid && ready.
// If outputReady is 0, downstream is not ready.
// This block must hold outputValid and outputData stable.

module streamRegister #(
    parameter int DATA_WIDTH = 8
) (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic inputValid,
    output logic inputReady,
    input logic [DATA_WIDTH-1:0] inputData,

    output logic outputValid,
    input logic outputReady,
    output logic [DATA_WIDTH-1:0] outputData
);

    logic full; // = 1 means outputDta contains a word, = 0 means register is empty
    assign inputReady = !full;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            full <= 1'b0;
            outputValid <= 1'b0;
            outputData <= '0;
        end else begin
            if (outputValid && outputReady) begin
                full <= 1'b0;
                outputValid <= 1'b0;
            end

            if (inputValid && inputReady) begin
                outputData <= inputData;
                full <= 1'b1;
                outputValid <= 1'b1;
            end
        end
    end

endmodule