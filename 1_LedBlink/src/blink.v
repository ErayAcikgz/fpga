module blink (
    input  wire sys_clk,
    input  wire sys_rst_n,
    output reg  [5:0] led
);

    // Tang Nano 9K onboard clock is 27 MHz.
    // 13,499,999 gives roughly 0.5 s toggle interval.
    localparam COUNTER_MAX = 24'd13_499_999;

    reg [23:0] counter;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            counter <= 24'd0;
            led     <= 6'b111110;
        end else begin
            if (counter == COUNTER_MAX) begin
                counter <= 24'd0;
                led     <= {led[4:0], led[5]};
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
