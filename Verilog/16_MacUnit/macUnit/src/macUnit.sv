// Fixed-Point Multiply-Accumulate
// accumulator = accumulator + (a * b)

module macUnit (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic clear,
    input logic inputValid,
    input logic signed [7:0] a,
    input logic signed [7:0] b,

    output logic outputValid,
    output logic signed [15:0] accumulator // 16 bits so accumulator has more room for storage
);

    logic signed [15:0] rawProduct;
    logic signed [15:0] scaledProduct;

    assign rawProduct = a * b;
    assign scaledProduct = rawProduct >>> 4;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            accumulator <= 16'sd0;
            outputValid <= 1'b0;
        end else begin
            outputValid <= 1'b0;    // Default, no new accumulated output this cycle
        
            if (clear) begin        // Clear has priority over accumulation
                accumulator <= 16'sd0;
            end else if (inputValid) begin
                accumulator <= accumulator + scaledProduct;
                outputValid <= 1'b1;
            end
        end
     end

endmodule
