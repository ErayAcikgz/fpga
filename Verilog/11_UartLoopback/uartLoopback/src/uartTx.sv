module uartTx (
    input logic sys_clk,
    input logic sys_rst_n,
    input logic [7:0] txData,
    input logic txStart,
    output logic txBusy,
    output logic uart_tx
);

    localparam int BAUD_TICK_MAX = 233;     // 27 MHz / 115200 = 234.375 clocks per UART bit

    typedef enum logic [2:0] {
        stateIdle,      // waits for txStart
        stateStart,     // sends start bit = 0
        stateData,      // sends 8 data bits, LSB first
        stateStop       // sends stop bit = 1
    } txState_t;

    txState_t txState;

    logic [7:0] baudCounter;    // counts clocks for each UART bit
    logic baudTick;             // one-clock pulse every UART bit time
    logic [2:0] bitIndex;       // tracks which data bit is being sent
    logic [7:0] txShiftReg;     // holds byte being transmitted

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            txState     <= stateIdle;
            baudCounter <= 8'd0;
            baudTick    <= 1'b0;
            bitIndex    <= 3'd0;
            txShiftReg  <= 8'd0;
            txBusy      <= 1'b0;
            uart_tx     <= 1'b1;
        end else begin
            baudTick <= 1'b0;

            if (txState != stateIdle) begin
                if (baudCounter == BAUD_TICK_MAX) begin
                    baudCounter <= 8'd0;
                    baudTick    <= 1'b1;
                end else begin
                    baudCounter <= baudCounter + 1'b1;
                end
            end else begin
                baudCounter <= 8'd0;
            end

            case (txState)
                stateIdle: begin
                    uart_tx <= 1'b1;
                    txBusy  <= 1'b0;

                    if (txStart) begin
                        txShiftReg <= txData;
                        bitIndex   <= 3'd0;
                        txBusy     <= 1'b1;
                        txState    <= stateStart;
                    end
                end

                stateStart: begin
                    uart_tx <= 1'b0;

                    if (baudTick) begin
                        txState <= stateData;
                    end
                end

                stateData: begin
                    uart_tx <= txShiftReg[0];

                    if (baudTick) begin
                        txShiftReg <= {1'b0, txShiftReg[7:1]};

                        if (bitIndex == 3'd7) begin
                            txState <= stateStop;
                        end else begin
                            bitIndex <= bitIndex + 1'b1;
                        end
                    end
                end

                stateStop: begin
                    uart_tx <= 1'b1;

                    if (baudTick) begin
                        txBusy  <= 1'b0;
                        txState <= stateIdle;
                    end
                end

                default: begin
                    txState <= stateIdle;
                    uart_tx <= 1'b1;
                    txBusy  <= 1'b0;
                end
            endcase
        end
    end

endmodule