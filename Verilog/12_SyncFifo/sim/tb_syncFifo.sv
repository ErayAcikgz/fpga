`timescale 1ns/1ps

module tb_syncFifo;

    logic sys_clk;
    logic sys_rst_n;

    logic writeEnable;
    logic [7:0] writeData;
    logic full;

    logic readEnable;
    logic [7:0] readData;
    logic empty;

    logic [4:0] count;

    syncFifo dut (
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
        forever #18.518 sys_clk = ~sys_clk;
    end

    task writeByte(input logic [7:0] dataByte);
        begin
            // Change inputs away from FIFO sampling edge.
            @(negedge sys_clk);

            // Request one FIFO write.
            writeData = dataByte;
            writeEnable = 1'b1;

            // FIFO samples writeEnable/writeData on next rising edge.

            @(negedge sys_clk);

            // End one-clock write pulse.
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
        sys_rst_n = 1'b0;
        writeEnable = 1'b0;
        writeData = 8'd0;
        readEnable = 1'b0;

        #200;
        sys_rst_n = 1'b1;

        writeByte(8'h11);
        writeByte(8'h22);
        writeByte(8'h33);

        readByte();
        readByte();
        readByte();

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

        writeByte(8'hFF);

        readByte();
        readByte();
        readByte();
        readByte();

        @(negedge sys_clk);
        writeData = 8'h55;
        writeEnable = 1'b1;
        readEnable = 1'b1;

        @(negedge sys_clk);
        writeEnable = 1'b0;
        readEnable = 1'b0;
        writeData = 8'd0;

        #1000;
        $finish;
    end

    initial begin
        $dumpfile("sim/tb_syncFifo.vcd");
        $dumpvars(0, tb_syncFifo);
    end

endmodule
