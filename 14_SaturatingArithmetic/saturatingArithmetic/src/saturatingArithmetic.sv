// Signed Q4.4 saturating arithmetic. Min = -8.0 (8'sh80), Max = +7.9375 (8'sh7F)
// Without saturation, 7.0 + 2.0 might wrap into a negative number

module satAdd (
    input logic signed [7:0] a,
    input logic signed [7:0] b,
    output logic signed [7:0] result
);

    localparam logic signed [8:0] MAX_Q4_4 = 9'sd127;
    localparam logic signed [8:0] MIN_Q4_4 = -9'sd128;

    logic signed [8:0] wideSum;         // left_index - right_index + 1 = no_bits

    assign wideSum = a + b;

    always_comb begin
        if (wideSum > MAX_Q4_4) begin
            result = 8'sh7F;
        end else if (wideSum < MIN_Q4_4) begin
            result = 8'sh80;
        end else begin
            // Icarus Verilog warns about constant part-selects inside always_comb.
            // Original syntax: result = wideSum[7:0];
            // Since the value is already range-checked, this 8-bit cast is safe.
            result = 8'(wideSum);  // Convert wideSum to exactly 8 bits
        end
    end

endmodule


module satSub (
    input logic signed [7:0] a,
    input logic signed [7:0] b,
    output logic signed [7:0] result
);

    localparam logic signed [8:0] MAX_Q4_4 = 9'sd127;
    localparam logic signed [8:0] MIN_Q4_4 = -9'sd128;

    logic signed [8:0] wideDiff;

    assign wideDiff = a - b;

    always_comb begin
        if (wideDiff > MAX_Q4_4) begin
            result = 8'sh7F;
        end else if (wideDiff < MIN_Q4_4) begin
            result = 8'sh80;
        end else begin
            result = 8'(wideDiff);
        end
    end

endmodule


module satMul (
    input logic signed [7:0] a,
    input logic signed [7:0] b,
    output logic signed [7:0] result
);

    localparam logic signed [15:0] MAX_Q4_4 = 16'sd127;
    localparam logic signed [15:0] MIN_Q4_4 = -16'sd128;
    
    logic signed [15:0] rawProduct;
    logic signed [15:0] scaledProduct;

    assign rawProduct = a * b;

    // Q4.4 * Q4.4 = Q8.8.
    // Arithmetic shift right by 4 returns the product to Q4.4 scale.
    assign scaledProduct = rawProduct >>> 4;

    always_comb begin
        if (scaledProduct > MAX_Q4_4) begin
            result = 8'sh7F;
        end else if (scaledProduct < MIN_Q4_4) begin
            result = 8'sh80;
        end else begin
            result = 8'(scaledProduct);
        end
    end

endmodule