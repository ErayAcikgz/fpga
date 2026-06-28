module pwmDimmer (
    input logic sys_clk,
    input logic sys_rst_n,
    output logic led
);

    logic [7:0] pwmCounter;

    // dutyCycle = 0   -> off
    // dutyCycle = 128 -> about 50%
    // dutyCycle = 255 -> almost fully on
    logic [7:0] dutyCycle;

    // Fade update interval: 20 ms.
    localparam logic [19:0] FADE_TICK_MAX = 20'd539_999;

    logic [19:0] fadeCounter;

    // Fade direction:
    // 1 = getting brighter
    // 0 = getting dimmer
    logic fadeUp;

    // Logical LED-on signal before active-low inversion.
    logic pwmOn;

    assign pwmOn = (pwmCounter < dutyCycle);

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pwmCounter  <= 8'd0;
            dutyCycle   <= 8'd0;
            fadeCounter <= 20'd0;
            fadeUp      <= 1'b1;
        end else begin
            // Free-running 8-bit PWM counter.
            pwmCounter <= pwmCounter + 1'b1;

            // Slow fade timebase.
            if (fadeCounter == FADE_TICK_MAX) begin
                fadeCounter <= 20'd0;

                // Update brightness once per fade tick.
                if (fadeUp) begin
                    if (dutyCycle == 8'd255) begin
                        fadeUp    <= 1'b0;
                        dutyCycle <= dutyCycle - 1'b1;
                    end else begin
                        dutyCycle <= dutyCycle + 1'b1;
                    end
                end else begin
                    if (dutyCycle == 8'd0) begin
                        fadeUp    <= 1'b1;
                        dutyCycle <= dutyCycle + 1'b1;
                    end else begin
                        dutyCycle <= dutyCycle - 1'b1;
                    end
                end
            end else begin
                fadeCounter <= fadeCounter + 1'b1;
            end
        end
    end

    assign led = ~pwmOn;

endmodule
