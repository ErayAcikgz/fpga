// Simplified register-bus model to teach core ideas
// CPU controls registers with sofware, hardware uses registers for operation and writes result back to registers, CPU receives result from registers

module axiLiteRegisterBlock (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic writeEnable,
    input logic [7:0] writeAddress,
    input logic [31:0] writeData,

    input logic readEnable,
    input logic [7:0] readAddress,
    output logic [31:0] readData,

    output logic done,
    output logic busy
);
    
    // The +4 spacing is because each register is 32 bits = 4 bytes
    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_INPUT_A = 8'h04;
    localparam logic [7:0] ADDR_INPUT_B = 8'h08;
    localparam logic [7:0] ADDR_RESULT  = 8'h0C;
    localparam logic [7:0] ADDR_STATUS  = 8'h10;

    logic [31:0] controlReg;
    logic [31:0] inputAReg;
    logic [31:0] inputBReg;
    logic [31:0] resultReg;
    logic [31:0] statusReg;

    logic startPulse;

    // startPulse is true for one clock when software writes 1 to control bit 0
    assign startPulse = writeEnable && (writeAddress == ADDR_CONTROL) && writeData[0];

    assign done = statusReg[0];
    assign busy = statusReg[1];

        always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            controlReg <= 32'd0;
            inputAReg <= 32'd0;
            inputBReg <= 32'd0;
            resultReg <= 32'd0;
            statusReg <= 32'd0;
        end else begin
            // Default: done is a sticky status bit until a new operation starts
            // busy stays controlled by the operation state below.

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

                    default: begin
                        // Writes to read-only or unmapped addresses are ignored
                    end
                endcase
            end

            if (startPulse) begin
                statusReg[0] <= 1'b0; // done = 0
                statusReg[1] <= 1'b1; // busy = 1

                // Simple one-cycle "hardware accelerator":
                resultReg <= inputAReg + inputBReg;

                // Since this operation is combinational/simple, finish immediately
                statusReg[0] <= 1'b1; // done = 1
                statusReg[1] <= 1'b0; // busy = 0
            end
        end
    end

    // Combinational read mux
    // The bus master chooses an address. This block returns the register value at that address
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
