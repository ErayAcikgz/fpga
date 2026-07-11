`timescale 1ns/1ps

module tb_checkedSyncFifo;

    logic sys_clk;
    logic sys_rst_n;

    logic writeEnable;
    logic [7:0] writeData;
    logic full;

    logic readEnable;
    logic [7:0] readData;
    logic empty;

    logic [4:0] count;

    checkedSyncFifo dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .writeEnable(writeEnable),
        .writeData(writeData),
        .full(full),

        .readEnable(readEnable),
        .readData(readData),
        .empty(empty),

        .count(count)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    task writeByte(input logic [7:0] dataByte);
        begin
            @(negedge sys_clk);
            writeData = dataByte;
            writeEnable = 1'b1;

            @(negedge sys_clk);
            writeEnable = 1'b0;
            writeData = 8'd0;
        end
    endtask

    task readByte;
        begin
            @(negedge sys_clk);
            readEnable = 1'b1;

            @(negedge sys_clk);
            readEnable = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_checkedSyncFifo.vcd");
        $dumpvars(0, tb_checkedSyncFifo);

        sys_rst_n = 1'b0;
        writeEnable = 1'b0;
        writeData = 8'd0;
        readEnable = 1'b0;

        #200;
        sys_rst_n = 1'b1;

        // Reset condition should produce: count = 0, empty = 1, full  = 0
        repeat (2) @(posedge sys_clk);

        // Normal writes
        // Expected: count increases to 3
        writeByte(8'h11);
        writeByte(8'h22);
        writeByte(8'h33);

        // Normal reads
        // Expected: count decreases back to 0
        readByte();
        readByte();
        readByte();

        // Try to read while empty
        // Expected: no underflow, count remains 0
        readByte();

        // Fill FIFO completely
        // Expected: count reaches 16, full becomes 1
        writeByte(8'hA0);
        writeByte(8'hA1);
        writeByte(8'hA2);
        writeByte(8'hA3);
        writeByte(8'hA4);
        writeByte(8'hA5);
        writeByte(8'hA6);
        writeByte(8'hA7);
        writeByte(8'hA8);
        writeByte(8'hA9);
        writeByte(8'hAA);
        writeByte(8'hAB);
        writeByte(8'hAC);
        writeByte(8'hAD);
        writeByte(8'hAE);
        writeByte(8'hAF);

        // Try to write while full
        // Expected: no overflow, count remains 16
        writeByte(8'hFF);

        // Drain part of FIFO
        readByte();
        readByte();
        readByte();
        readByte();

        // Simultaneous read and write
        // Expected: count unchanged
        @(negedge sys_clk);
        writeData = 8'h55;
        writeEnable = 1'b1;
        readEnable = 1'b1;

        @(negedge sys_clk);
        writeEnable = 1'b0;
        readEnable = 1'b0;
        writeData = 8'd0;

        repeat (8) @(posedge sys_clk);

        $display("checkedSyncFifo simulation completed.");

        $finish;
    end

endmodule
