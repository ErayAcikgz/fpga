module quadratureDecoder (
    input logic sys_clk,
    input logic sys_rst_n,
    input logic quad_a,
    input logic quad_b,
    output logic [4:0] led
);

    // Synchronizer registers
    // Each signal gets its own two-flop synchronizer.
    logic quadA_sync0;
    logic quadA_sync1;
    logic quadB_sync0;
    logic quadB_sync1;

    // Previous and current quadrature state.
    //   bit 1 = A
    //   bit 0 = B
    logic [1:0] quadState;
    logic [1:0] quadStatePrev;

    // Signed position counter.
    // It increments for one direction and decrements for the other.
    // LEDs show the low 6 bits of the position.
    logic [4:0] positionCounter;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            quadA_sync0     <= 1'b0;
            quadA_sync1     <= 1'b0;
            quadB_sync0     <= 1'b0;
            quadB_sync1     <= 1'b0;
            quadState       <= 2'b00;
            quadStatePrev   <= 2'b00;
            positionCounter <= 6'd0;
        end else begin
            // Synchronize external quadrature inputs
            quadA_sync0 <= quad_a;
            quadA_sync1 <= quadA_sync0;
            quadB_sync0 <= quad_b;
            quadB_sync1 <= quadB_sync0;

            // Store previous state and sample current synchronized state
            quadStatePrev <= quadState;
            quadState     <= {quadA_sync1, quadB_sync1};

            // 3. Decode quadrature transition
            // Valid clockwise sequence example:
            //   00 -> 01 -> 11 -> 10 -> 00
            // Valid counterclockwise sequence example:
            //   00 -> 10 -> 11 -> 01 -> 00
            // Invalid transitions, such as 00 -> 11, are ignored.
            case ({quadStatePrev, quadState})
                // Forward transitions
                4'b0001,
                4'b0111,
                4'b1110,
                4'b1000: begin
                    positionCounter <= positionCounter + 1'b1;
                end

                // Reverse transitions
                4'b0010,
                4'b1011,
                4'b1101,
                4'b0100: begin
                    positionCounter <= positionCounter - 1'b1;
                end

                // No movement or invalid transition
                default: begin
                    positionCounter <= positionCounter;
                end
            endcase
        end
    end

    assign led = ~positionCounter;

endmodule