module fpgaPidMotorControl (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic sampleEnable,

    input logic signed [15:0] setpoint,
    input logic signed [15:0] measuredValue,

    input logic signed [15:0] kp,
    input logic signed [15:0] ki,
    input logic signed [15:0] kd,

    output logic signed [15:0] controlOutput,
    output logic outputValid
);

    logic signed [15:0] currentError;
    logic signed [15:0] previousError;
    logic signed [15:0] errorDelta;

    logic signed [31:0] integralAccumulator;

    logic signed [31:0] proportionalProduct;
    logic signed [47:0] integralProduct;
    logic signed [31:0] derivativeProduct;

    logic signed [31:0] proportionalTerm;
    logic signed [31:0] integralTerm;
    logic signed [31:0] derivativeTerm;

    logic signed [31:0] pidSum;

    assign currentError = setpoint - measuredValue;
    assign errorDelta = currentError - previousError;

    // Q8.8 * Q8.8 = Q16.16
    assign proportionalProduct = currentError * kp;

    // integralAccumulator is 32-bit Q24.8
    // Multiplying by Q8.8 gives Q32.16
    assign integralProduct = integralAccumulator * ki;

    // Q8.8 * Q8.8 = Q16.16
    assign derivativeProduct = errorDelta * kd;

    // Shift right by 8 to convert Q16.16 back to Q24.8 / Q8.8 scale
    assign proportionalTerm = proportionalProduct >>> 8;
    assign integralTerm = integralProduct >>> 8;
    assign derivativeTerm = derivativeProduct >>> 8;

    assign pidSum = proportionalTerm + integralTerm + derivativeTerm;

    function automatic logic signed [15:0] saturate16(input logic signed [31:0] value);
        begin
            if (value > 32'sd32767) begin
                saturate16 = 16'sh7FFF;
            end else if (value < -32'sd32768) begin
                saturate16 = 16'sh8000;
            end else begin
                saturate16 = 16'(value);
            end
        end
    endfunction

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            previousError <= 16'sd0;
            integralAccumulator <= 32'sd0;
            controlOutput <= 16'sd0;
            outputValid <= 1'b0;
        end else begin
            outputValid <= 1'b0;

            if (sampleEnable) begin
                integralAccumulator <= integralAccumulator + currentError;
                previousError <= currentError;
                controlOutput <= saturate16(pidSum);

                outputValid <= 1'b1;
            end
        end
    end

endmodule