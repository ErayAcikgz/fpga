// Process is done in 3 seperate but short clock cyles instead of 1 long clock cyle
// Timing is improved, but output arrives with latency

module pipelinedMultiplier (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic inputValid,
    input logic signed [7:0] a,
    input logic signed [7:0] b,

    output logic outputValid,
    output logic signed [7:0] result
);

    localparam logic signed [15:0] MAX_Q4_4 = 16'sd127;
    localparam logic signed [15:0] MIN_Q4_4 = -16'sd128;

    logic stage1Valid;
    logic signed [7:0] stage1A;
    logic signed [7:0] stage1B;

    // Raw product Q8.8
    logic stage2Valid;
    logic signed [15:0] rawProduct;
    
    // Q8.8 -> Q4.4
    logic stage3Valid;
    logic signed [15:0] scaledProduct;

    // Saturation
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            stage1Valid <= 1'b0;
            stage1A <= 8'sd0;
            stage1B <= 8'sd0;

            stage2Valid <= 1'b0;
            rawProduct <= 16'sd0;

            stage3Valid <= 1'b0;
            scaledProduct <= 16'sd0;

            outputValid <= 1'b0;
            result <= 8'sd0;
        end else begin
            // Capture inputs
            stage1Valid <= inputValid;
            stage1A <= a;
            stage1B <= b;

            // Multiply
            stage2Valid <= stage1Valid;
            rawProduct <= stage1A * stage1B;
            
            // Scale back to Q4.4
            stage3Valid <= stage2Valid;
            scaledProduct <= rawProduct >>> 4;  // Arithmetic shift to preserve sign for negatives

            // Saturate and output
            outputValid <= stage3Valid;

            if (scaledProduct > MAX_Q4_4) begin
                result <= 8'sh7F;
            end else if (scaledProduct < MIN_Q4_4) begin
                result <= 8'sh80;
            end else begin
                result <= 8'(scaledProduct); // To fix Icarus Verilog warning
            end
        end
    end

endmodule
