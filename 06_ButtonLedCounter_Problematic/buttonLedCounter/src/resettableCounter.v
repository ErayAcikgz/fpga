module buttonLedCounter (
    input  wire       sys_clk,
    input  wire       button_n,
    output wire [5:0] led
);

    wire buttonStable;
    wire buttonPressPulse;

    reg [5:0] displayCounter;

    buttonDebounce buttonDebounce_inst (
        .clk(sys_clk),
        .button_n(button_n),
        .buttonStable(buttonStable)
    );

    edgeDetector edgeDetector_inst (
        .clk(sys_clk),
        .signalIn(buttonStable),
        .fallingEdgePulse(buttonPressPulse)
    );

    always @(posedge sys_clk) begin
        if (buttonPressPulse) begin
            displayCounter <= displayCounter + 1'b1;
        end
    end

    assign led = ~displayCounter;

endmodule