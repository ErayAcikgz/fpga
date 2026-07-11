// Register-controlled custom accelerator
// A CPU would not connect directly to internal RTL signals. Instead, software sees a small register map.
// hardware block + register map + start/done/busy protocol = accelerator peripheral
// result = (inputA * inputB) + inputC

module customAccelerator (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic writeEnable,
    input logic [7:0] writeAddress,
    input logic [31:0] writeData,

    input logic readEnable,
    input logic [7:0] readAddress,
    output logic [31:0] readData
);

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_INPUT_A = 8'h04;
    localparam logic [7:0] ADDR_INPUT_B = 8'h08;
    localparam logic [7:0] ADDR_INPUT_C = 8'h0C;
    localparam logic [7:0] ADDR_RESULT  = 8'h10;
    localparam logic [7:0] ADDR_STATUS  = 8'h14;

    typedef enum logic [1:0] {
        IDLE,
        EXECUTE,
        FINISH
    } state_t;

    state_t state;

    logic [31:0] controlReg;
    logic [31:0] inputAReg;
    logic [31:0] inputBReg;
    logic [31:0] inputCReg;
    logic [31:0] resultReg;
    logic [31:0] statusReg;

    logic startPulse;

    logic [63:0] multiplyResult;
    logic [63:0] macResult;

    assign startPulse = writeEnable && (writeAddress == ADDR_CONTROL) && writeData[0];

    assign multiplyResult = inputAReg * inputBReg;
    assign macResult = multiplyResult + inputCReg;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state <= IDLE;

            controlReg <= 32'd0;
            inputAReg <= 32'd0;
            inputBReg <= 32'd0;
            inputCReg <= 32'd0;
            resultReg <= 32'd0;
            statusReg <= 32'd0;
        end else begin
            if (writeEnable) begin
                case (writeAddress)
                    ADDR_CONTROL: begin
                        controlReg <= writeData;
                    end

                    ADDR_INPUT_A: begin
                        inputAReg <= writeData;
                    end

                    ADDR_INPUT_B: begin
                        inputBReg <= writeData;
                    end

                    ADDR_INPUT_C: begin
                        inputCReg <= writeData;
                    end

                    default: begin
                    end
                endcase
            end

            case (state)
                IDLE: begin
                    statusReg[1] <= 1'b0; // busy
                    controlReg[0] <= 1'b0; // auto-clear start bit

                    if (startPulse) begin
                        statusReg[0] <= 1'b0; // done
                        statusReg[1] <= 1'b1; // busy
                        state <= EXECUTE;
                    end
                end

                EXECUTE: begin
                    resultReg <= macResult[31:0];
                    state <= FINISH;
                end

                FINISH: begin
                    statusReg[0] <= 1'b1; // done
                    statusReg[1] <= 1'b0; // busy
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    statusReg <= 32'd0;
                end
            endcase
        end
    end

    always_comb begin
        if (readEnable) begin
            case (readAddress)
                ADDR_CONTROL: begin
                    readData = controlReg;
                end

                ADDR_INPUT_A: begin
                    readData = inputAReg;
                end

                ADDR_INPUT_B: begin
                    readData = inputBReg;
                end

                ADDR_INPUT_C: begin
                    readData = inputCReg;
                end

                ADDR_RESULT: begin
                    readData = resultReg;
                end

                ADDR_STATUS: begin
                    readData = statusReg;
                end

                default: begin
                    readData = 32'd0;
                end
            endcase
        end else begin
            readData = 32'd0;
        end
    end

endmodule
