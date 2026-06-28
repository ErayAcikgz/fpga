module resettableCounter (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    output wire [5:0] led
);

    // Tang Nano 9K onboard clock: 27 MHz.
    // 27,000,000 cycles = 1 second.
    //
    // 6,749,999 gives a tick every 0.25 seconds:
    // 27,000,000 / 4 = 6,750,000 cycles.
    // Since the counter includes zero, terminal count is 6,750,000 - 1.
    localparam TICK_MAX = 24'd6_749_999;

    reg [23:0] tickCounter;
    reg [5:0]  displayCounter;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tickCounter    <= 24'd0;
            displayCounter <= 6'd0;
        end else begin
            if (tickCounter == TICK_MAX) begin
                tickCounter    <= 24'd0;
                displayCounter <= displayCounter + 1'b1;
            end else begin
                tickCounter <= tickCounter + 1'b1;
            end
        end
    end

    // Tang Nano 9K LEDs are active-low.
    assign led = ~displayCounter;

endmodule