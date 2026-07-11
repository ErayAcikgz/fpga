module edgeDetector (
    input  wire clk,
    input  wire signalIn,
    output reg  fallingEdgePulse
);

    reg signalPrev;

    always @(posedge clk) begin
        // Store previous value of the input signal.
        signalPrev <= signalIn;

        // Detect falling edge:
        // previous = 1
        // current  = 0
        if ((signalPrev == 1'b1) && (signalIn == 1'b0)) begin
            fallingEdgePulse <= 1'b1;
        end else begin
            fallingEdgePulse <= 1'b0;
        end
    end

endmodule