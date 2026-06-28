module buttonDebounce (
    input  wire sys_clk,
    input  wire button_n,
    output wire led
);

    localparam DEBOUNCE_MAX = 25'd26_999_999; // 1 s

    // External button input is asynchronous to sys_clk.
    // These two registers form a two-flop synchronizer.
    reg buttonSync0;
    reg buttonSync1;

    // Debounce state.
    reg buttonLastSample;
    reg buttonStable;
    reg [24:0] debounceCounter;

    always @(posedge sys_clk) begin
        // Synchronizer chain.
        buttonSync0 <= button_n;
        buttonSync1 <= buttonSync0;

        // If the synchronized input changed, restart the debounce timer.
        if (buttonSync1 != buttonLastSample) begin
            buttonLastSample <= buttonSync1;
            debounceCounter  <= 25'd0;
        end else begin
            // If the input has stayed unchanged for 1 second, accept it as the stable button state.
            if (debounceCounter == DEBOUNCE_MAX) begin
                buttonStable <= buttonLastSample;
            end else begin
                debounceCounter <= debounceCounter + 1'b1;
            end
        end
    end

    // The LED turns on when the debounced button is pressed.
    assign led = buttonStable;

endmodule