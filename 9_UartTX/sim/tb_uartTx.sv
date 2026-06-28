`timescale 1ns/1ps          // Sets simulation time: baseTimeUnit/precision

module tb_uartTx;           // Simulation-only module, has no ports

    logic sys_clk;          // Fake simulation signals, connected to real design
    logic sys_rst_n;
    logic uart_tx;

    uartTx dut (            // Instantiate design, dut: "device under test"
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .uart_tx(uart_tx)
    );

    initial begin                               // Fake 27 MHz clock
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk;     // Half clock, clock toggles every 18.518 ns
    end

    initial begin           // Fake reset 
        sys_rst_n = 1'b0;
        #200;               // Reset starts active (active-low) and is released after 200 ns
        sys_rst_n = 1'b1;
    end

    initial begin                       // Waveform dump
        $dumpfile("tb_uartTx.vcd");     // Waveform file
        $dumpvars(0, tb_uartTx);        // Record all signals ("0") under "tb_uartTx"

        #1000000;                       // Run for 1.000.000 ns = 1ms
        $finish;                        // Stop simulation
    end

endmodule
