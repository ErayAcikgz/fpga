module buttonDebounce (
    input  wire clk,
    input  wire button_n,
    output reg  buttonStable
);

    // Tang Nano 9K onboard clock: 27 MHz.
    //
    // Debounce interval: 10 ms.
    // 27,000,000 cycles/sec * 0.010 sec = 270,000 cycles.
    // Terminal count = 270,000 - 1.
    localparam DEBOUNCE_MAX = 19'd269_999;

    reg buttonSync0;
    reg buttonSync1;
    reg buttonLastSample;
    reg [18:0] debounceCounter;

    always @(posedge clk) begin
        // Synchronize external asynchronous button input.
        buttonSync0 <= button_n;
        buttonSync1 <= buttonSync0;

        // If the synchronized input changed, restart debounce timing.
        if (buttonSync1 != buttonLastSample) begin
            buttonLastSample <= buttonSync1;
            debounceCounter  <= 19'd0;
        end else begin
            // If the input has stayed unchanged long enough,
            // accept it as the stable debounced state.
            if (debounceCounter == DEBOUNCE_MAX) begin
                buttonStable <= buttonLastSample;
            end else begin
                debounceCounter <= debounceCounter + 1'b1;
            end
        end
    end

endmodule