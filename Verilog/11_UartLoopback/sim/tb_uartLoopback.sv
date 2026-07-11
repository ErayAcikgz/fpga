`timescale 1ns/1ps

module tb_uartLoopback;
    logic sys_clk;
    logic sys_rst_n;
    logic uart_rx;
    logic uart_tx;
    logic [5:0] led;

    uartLoopback dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led(led)    
);

    initial begin
        sys_clk <= 1'b0;
        forever #18.518 sys_clk = ~sys_clk;     // 27 MHz
    end

    task sendUartByte(input logic [7:0] dataByte);
        integer i;
        begin
            uart_rx = 1'b0;              // Start bit
            #8670;

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = dataByte[i];   // LSB first
                #8670;
            end

            uart_rx = 1'b1;              // stop bit
            #8670;
        end
    endtask

    initial begin
        sys_rst_n = 1'b0;
        uart_rx = 1'b1;     // UART idle high
        #200;

        sys_rst_n = 1'b1;
        #20_000;

        sendUartByte(8'h55);
        #200_000;

        sendUartByte(8'h41);
        #200_000;

        $finish;
    end

    initial begin
        $dumpfile("sim/tb_uartLoopback.vcd");
        $dumpvars(0, tb_uartLoopback);
    end

endmodule
