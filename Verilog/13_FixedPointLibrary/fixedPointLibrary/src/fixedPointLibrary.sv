// Signed Q4.4 -> 8 bits total: 1 sign bit, 3 integer bits, 4 fractional bits
// 4 fractional bits, meaning stored integer is 2^4 times larger than the real value: "Scale factor"
// Scale factor: 2^4 = 16 => realValue = storedSignedInteger / 16


module fixedAdd (
    input logic signed [7:0] a,         // "signed": interpret "a" as a two's-complement signed number
    input logic signed [7:0] b,         // leftmost bit = 0 -> positive, leftmost bit = 1 -> negative
    output logic signed [7:0] result    // For signed, maximum value is 127, min -128
);

    assign result = a + b;              // Combinational

endmodule


module fixedSub (
    input logic signed [7:0] a,
    input logic signed [7:0] b,
    output logic signed [7:0] result
);

    assign result = a - b;

endmodule


module fixedMul (
    input logic signed [7:0] a,
    input logic signed [7:0] b,
    output logic signed [7:0] result
);

    logic signed [15:0] rawProduct;     // 8-bit x 8-bit = 16-bit -> Q8.8

    // Need in Q4.4 format, so divide by 16. NOT 256 as we need the other 16 for Q4.4
    assign rawProduct = a * b;          // Shift right by 4 bits then keep 8 bits
    assign result = rawProduct[11:4];   
    // ^ rawProduct[11:4] = arithmetic scaling right by 4 bits, then keeping the 8-bit Q4.4

endmodule