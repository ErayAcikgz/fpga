`timescale 1ns/1ps

module tb_uartRx;

    logic sys_clk;
    logic sys_rst_n;
    logic uart_rx;
    logic [5:0] led;

    uartRx dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .uart_rx(uart_rx),
        .led(led)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk;   // 27 MHz
    end

    task sendUartByte(input logic [7:0] dataByte);
        integer i;
        begin
            // start bit
            uart_rx = 1'b0;
            #8670;

            // data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = dataByte[i];
                #8670;
            end

            // stop bit
            uart_rx = 1'b1;
            #8670;
        end
    endtask

    initial begin
        sys_rst_n = 1'b0;
        uart_rx   = 1'b1;   // UART idle high

        #200;
        sys_rst_n = 1'b1;

        #20_000;

        sendUartByte(8'h55);

        #50_000;

        sendUartByte(8'h41);

        #50_000;

        $finish;
    end

    initial begin
        $dumpfile("sim/tb_uartRx.vcd");
        $dumpvars(0, tb_uartRx);
    end

endmodule
