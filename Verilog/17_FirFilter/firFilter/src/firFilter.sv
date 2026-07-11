// Fixed-point finite impulse-response filter
// y[n] = c0*x[n] + c1*x[n-1] + c2*x[n-2] + c3*x[n-3]
// Moving-average filter, all coefficients = 0.25 -> 0.25 * 16 = 4 = 8'sh04
// => y[n] = 0.25*x[n] + 0.25*x[n-1] + 0.25*x[n-2] + 0.25*x[n-3]

module firFilter (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic sampleValid,
    input logic signed [7:0] sampleIn,

    output logic outputValid,
    output logic signed [15:0] sampleOut
);

    // Fixed Q4.4 coefficients
    localparam logic signed [7:0] C0 = 8'sh04; // 0.25
    localparam logic signed [7:0] C1 = 8'sh04;
    localparam logic signed [7:0] C2 = 8'sh04;
    localparam logic signed [7:0] C3 = 8'sh04;

    // Delay line:
    // x0 = newest sample
    // x1 = previous sample
    // x2 = sample before that
    // x3 = oldest sample
    logic signed [7:0] x0;
    logic signed [7:0] x1;
    logic signed [7:0] x2;
    logic signed [7:0] x3;

    // Raw products
    // Q4.4 * Q4.4 = Q8.8
    // 8-bit * 8-bit = 16-bit product
    logic signed [15:0] p0Raw;
    logic signed [15:0] p1Raw;
    logic signed [15:0] p2Raw;
    logic signed [15:0] p3Raw;

    assign p0Raw = x0 * C0;
    assign p1Raw = x1 * C1;
    assign p2Raw = x2 * C2;
    assign p3Raw = x3 * C3;

    // Scaled products
    logic signed [15:0] p0;
    logic signed [15:0] p1;
    logic signed [15:0] p2;
    logic signed [15:0] p3;

    assign p0 = p0Raw >>> 4;
    assign p1 = p1Raw >>> 4;
    assign p2 = p2Raw >>> 4;
    assign p3 = p3Raw >>> 4;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            x0 <= 8'sd0;
            x1 <= 8'sd0;
            x2 <= 8'sd0;
            x3 <= 8'sd0;

            outputValid <= 1'b0;
            sampleOut <= 16'sd0;
        end else begin
            outputValid <= 1'b0; // Default: no new output unless a new sample arrives
        
            if (sampleValid) begin
                // Shift delay line, new sample is x0, older samples move down the line
                x3 <= x2;
                x2 <= x1;
                x1 <= x0;
                x0 <= sampleIn;

                // Important:
                // Nonblocking assignments update after this clock edge, this sum uses the OLD x0/x1/x2/x3 values.
                // To include the new sampleIn immediately, we use sampleIn directly for the newest term instead of x0.
                sampleOut <= ((sampleIn * C0) >>> 4) + p0 + p1 + p2;

                outputValid <= 1'b1;
            end
        end
    end

endmodule
