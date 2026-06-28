module uartLoopback (
    input logic sys_clk,
    input logic sys_rst_n,
    input logic uart_rx,
    output logic uart_tx,
    output logic [5:0] led
);

    logic [7:0] rxData;
    logic rxValid;

    logic [7:0] txData;
    logic txStart;
    logic txBusy;

    uartRx rxInst (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .uart_rx(uart_rx),
        .rxData(rxData),
        .rxValid(rxValid)
    );

    uartTx txInst (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .txData(txData),
        .txStart(txStart),
        .txBusy(txBusy),
        .uart_tx(uart_tx)
    );

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            txData  <= 8'd0;
            txStart <= 1'b0;
        end else begin
            txStart <= 1'b0;

            if (rxValid && !txBusy) begin
                txData  <= rxData;
                txStart <= 1'b1;
            end
        end
    end

    assign led = ~rxData[5:0];

endmodule