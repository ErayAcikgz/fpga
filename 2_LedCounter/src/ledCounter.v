module led_counter (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    output wire [5:0] led
);

    // A 32-bit counter increments every clock cycle.
    // We display selected upper bits on the LEDs so the changes are slow
    // enough to see with the human eye.
    reg [31:0] counter;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            counter <= 32'd0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    // counter[26:21] changes slowly enough to be visible.
    // Invert the bits so logical 1 means LED on visually.
    assign led = ~counter[26:21];

endmodule
