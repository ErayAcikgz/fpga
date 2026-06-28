module uartRx (
    input logic sys_clk,
    input logic sys_rst_n,
    input logic uart_rx,
    output logic [5:0] led
);

    localparam int BAUD_TICK_MAX = 233;          // 27 MHz / 115200 ≈ 234.375 clocks per UART bit
    localparam int HALF_BAUD_TICK_MAX = 116;     // half-bit delay for start-bit centering

    typedef enum logic [2:0] {
        stateIdle,      // waits for start bit
        stateStart,     // confirms start bit in the middle
        stateData,      // samples 8 data bits, LSB first
        stateStop,      // checks stop bit = 1
        stateDone       // updates output byte
    } rxState_t;

    rxState_t rxState;

    logic [7:0] baudCounter;    // counts clocks between UART samples
    logic [2:0] bitIndex;       // tracks which data bit is being received
    logic [7:0] rxShiftReg;     // stores incoming UART byte
    logic [7:0] receivedByte;   // last valid received byte

    logic rxSync0;              // first synchronizer flip-flop
    logic rxSync1;              // synchronized UART RX signal

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rxState      <= stateIdle;
            baudCounter  <= 8'd0;
            bitIndex     <= 3'd0;
            rxShiftReg   <= 8'd0;
            receivedByte <= 8'd0;
            rxSync0      <= 1'b1;
            rxSync1      <= 1'b1;
        end else begin
            rxSync0 <= uart_rx;
            rxSync1 <= rxSync0;

            case (rxState)
                stateIdle: begin
                    baudCounter <= 8'd0;
                    bitIndex    <= 3'd0;

                    if (rxSync1 == 1'b0) begin
                        rxState <= stateStart;
                    end
                end

                stateStart: begin
                    if (baudCounter == HALF_BAUD_TICK_MAX) begin
                        baudCounter <= 8'd0;

                        if (rxSync1 == 1'b0) begin
                            rxState <= stateData;
                        end else begin
                            rxState <= stateIdle;
                        end
                    end else begin
                        baudCounter <= baudCounter + 1'b1;
                    end
                end

                stateData: begin
                    if (baudCounter == BAUD_TICK_MAX) begin
                        baudCounter <= 8'd0;
                        rxShiftReg[bitIndex] <= rxSync1;

                        if (bitIndex == 3'd7) begin
                            rxState <= stateStop;
                        end else begin
                            bitIndex <= bitIndex + 1'b1;
                        end
                    end else begin
                        baudCounter <= baudCounter + 1'b1;
                    end
                end

                stateStop: begin
                    if (baudCounter == BAUD_TICK_MAX) begin
                        baudCounter <= 8'd0;

                        if (rxSync1 == 1'b1) begin
                            rxState <= stateDone;
                        end else begin
                            rxState <= stateIdle;
                        end
                    end else begin
                        baudCounter <= baudCounter + 1'b1;
                    end
                end

                stateDone: begin
                    receivedByte <= rxShiftReg;
                    rxState      <= stateIdle;
                end

                default: begin
                    rxState <= stateIdle;
                end
            endcase
        end
    end

    assign led = ~receivedByte[5:0];

endmodule