`timescale 1ns/1ps

module tb_spiMaster;

    logic sys_clk;
    logic sys_rst_n;

    logic start;
    logic [7:0] txData;
    logic [7:0] rxData;
    logic busy;
    logic done;

    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;

    logic [7:0] slaveTxData;
    logic [7:0] slaveRxData;

    spiMaster dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .start(start),
        .txData(txData),
        .rxData(rxData),
        .busy(busy),
        .done(done),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    // Simple SPI mode-0 slave model
    // Receives MOSI on rising edges of sclk, changes MISO on falling edges of sclk
    initial begin
        miso = 1'b0;
        slaveTxData = 8'h3C;
        slaveRxData = 8'd0;

        forever begin
            // Wait for transaction to start
            @(negedge cs_n);

            // Put first slave bit on MISO before first rising edge
            miso = slaveTxData[7];

            // Receive/transmit 8 bits, MSB-first
            for (int i = 7; i >= 0; i--) begin
                @(posedge sclk);
                slaveRxData[i] = mosi;

                if (i != 0) begin
                    @(negedge sclk);
                    miso = slaveTxData[i-1];
                end
            end

            // Wait for transaction to end
            @(posedge cs_n);
            miso = 1'b0;
        end
    end

    task startTransfer(input logic [7:0] masterByte, input logic [7:0] slaveByte);
        begin
            @(negedge sys_clk);
            txData = masterByte;
            slaveTxData = slaveByte;
            slaveRxData = 8'd0;
            start = 1'b1;

            @(negedge sys_clk);
            start = 1'b0;

            wait (done == 1'b1);
            @(posedge sys_clk);
        end
    endtask

    initial begin
        $dumpfile("sim/tb_spiMaster.vcd");
        $dumpvars(0, tb_spiMaster);

        sys_rst_n = 1'b0;
        start = 1'b0;
        txData = 8'd0;

        #200;
        sys_rst_n = 1'b1;

        // Master sends A5, slave sends 3C
        // Expected: rxData = 3C, slaveRxData = A5
        startTransfer(8'hA5, 8'h3C);

        // Master sends 5A, slave sends C3
        // Expected: rxData = C3, slaveRxData = 5A
        startTransfer(8'h5A, 8'hC3);

        repeat (6) @(posedge sys_clk);

        $finish;
    end

endmodule
