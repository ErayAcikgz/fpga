`timescale 1ns/1ps

module tb_asyncFifo;

    logic writeClk;
    logic writeRst_n;
    logic writeEnable;
    logic [7:0] writeData;
    logic full;

    logic readClk;
    logic readRst_n;
    logic readEnable;
    logic [7:0] readData;
    logic empty;

    int errorCount;

    asyncFifo dut (
        .writeClk(writeClk),
        .writeRst_n(writeRst_n),
        .writeEnable(writeEnable),
        .writeData(writeData),
        .full(full),

        .readClk(readClk),
        .readRst_n(readRst_n),
        .readEnable(readEnable),
        .readData(readData),
        .empty(empty)
    );

    initial begin
        writeClk = 1'b0;
        forever #10 writeClk = ~writeClk; // 50 MHz write clock
    end

    initial begin
        readClk = 1'b0;
        forever #17 readClk = ~readClk; // Different read clock
    end

    // Write one byte into the FIFO
    // This task waits while full is high
    // A write transfer happens on writeClk when: writeEnable && !full
    task writeByte(input logic [7:0] dataByte);
        begin
            @(negedge writeClk);

            while (full) begin
                @(negedge writeClk);
            end

            writeData = dataByte;
            writeEnable = 1'b1;

            @(negedge writeClk);
            writeEnable = 1'b0;
            writeData = 8'd0;
        end
    endtask

    // Read one byte and compare it against the expected value
    // This task waits while empty is high
    // A read transfer happens on readClk when: readEnable && !empty
    task readByteExpect(input logic [7:0] expectedByte);
        begin
            @(negedge readClk);

            while (empty) begin
                @(negedge readClk);
            end

            readEnable = 1'b1;

            @(posedge readClk);
            #1;

            if (readData !== expectedByte) begin
                $display("ERROR: expected %02h, got %02h at time %0t", expectedByte, readData, $time);
                errorCount = errorCount + 1;
            end else begin
                $display("PASS: read %02h at time %0t", readData, $time);
            end

            @(negedge readClk);
            readEnable = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_asyncFifo.vcd");
        $dumpvars(0, tb_asyncFifo);

        writeRst_n = 1'b0;
        readRst_n = 1'b0;

        writeEnable = 1'b0;
        writeData = 8'd0;

        readEnable = 1'b0;

        errorCount = 0;

        #200;

        writeRst_n = 1'b1;
        readRst_n = 1'b1;

        // Give synchronizers time to settle after reset
        repeat (5) @(posedge writeClk);
        repeat (5) @(posedge readClk);

        // Basic order test.
        // FIFO must preserve order: A1, B2, C3, D4
        fork
            begin
                writeByte(8'hA1);
                writeByte(8'hB2);
                writeByte(8'hC3);
                writeByte(8'hD4);
            end

            begin
                readByteExpect(8'hA1);
                readByteExpect(8'hB2);
                readByteExpect(8'hC3);
                readByteExpect(8'hD4);
            end
        join

        // Fill-pressure test
        // Write many values before reading
        // This exercises pointer wrap and full/empty behavior
        fork
            begin
                writeByte(8'h10);
                writeByte(8'h11);
                writeByte(8'h12);
                writeByte(8'h13);
                writeByte(8'h14);
                writeByte(8'h15);
                writeByte(8'h16);
                writeByte(8'h17);
                writeByte(8'h18);
                writeByte(8'h19);
                writeByte(8'h1A);
                writeByte(8'h1B);
                writeByte(8'h1C);
                writeByte(8'h1D);
                writeByte(8'h1E);
                writeByte(8'h1F);
            end

            begin
                // Delay reads so FIFO fills first.
                repeat (20) @(posedge readClk);

                readByteExpect(8'h10);
                readByteExpect(8'h11);
                readByteExpect(8'h12);
                readByteExpect(8'h13);
                readByteExpect(8'h14);
                readByteExpect(8'h15);
                readByteExpect(8'h16);
                readByteExpect(8'h17);
                readByteExpect(8'h18);
                readByteExpect(8'h19);
                readByteExpect(8'h1A);
                readByteExpect(8'h1B);
                readByteExpect(8'h1C);
                readByteExpect(8'h1D);
                readByteExpect(8'h1E);
                readByteExpect(8'h1F);
            end
        join

        repeat (10) @(posedge readClk);

        if (errorCount == 0) begin
            $display("ASYNC FIFO TEST PASSED");
        end else begin
            $display("ASYNC FIFO TEST FAILED with %0d error(s)", errorCount);
        end

        $finish;
    end

endmodule
