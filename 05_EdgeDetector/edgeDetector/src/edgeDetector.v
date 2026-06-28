module edgeDetector (
    input wire sys_clk,
    input wire button_n,
    output wire led
);
    localparam DEBOUNCE_MAX = 19'd269_999;
    localparam PULSE_MAX = 24'd13_499_999;

    // Synchronizer registers
    reg buttonSync0;
    reg buttonSync1;

    // Debounce registers
    reg buttonLastSample;
    reg buttonStable;
    reg [18:0] debounceCounter;

    // Edge detector register
    reg buttonStablePrev;

    // Pulse stretcher registers
    reg [23:0] pulseCounter;
    reg pulseVisible;

    always @(posedge sys_clk) begin
        // Synchronize the asynchronous button input
        buttonSync0 <= button_n;
        buttonSync1 <= buttonSync0;

        // Debounce logic
        if (buttonSync1 != buttonLastSample) begin
            buttonLastSample <= buttonSync1;
            debounceCounter  <= 19'd0;
        end else begin
            // If the candidate value has stayed unchanged long enough,
            // accept it as the stable debounced button state.
            if (debounceCounter == DEBOUNCE_MAX) begin
                buttonStable <= buttonLastSample;
            end else begin
                debounceCounter <= debounceCounter + 1'b1;
            end
        end

        // Save previous debounced state
        buttonStablePrev <= buttonStable;

        // Falling-edge detection
        if ((buttonStablePrev == 1'b1) && (buttonStable == 1'b0)) begin
            pulseVisible <= 1'b1;
            pulseCounter <= 24'd0;
        end else begin
            // Pulse stretching
            if (pulseVisible) begin
                if (pulseCounter == PULSE_MAX) begin
                    pulseVisible <= 1'b0;
                    pulseCounter <= 24'd0;
                end else begin
                    pulseCounter <= pulseCounter + 1'b1;
                end
            end
        end
    end

    assign led = ~pulseVisible;

endmodule
