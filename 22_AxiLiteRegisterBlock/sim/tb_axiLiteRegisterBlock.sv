`timescale 1ns/1ps

module tb_axiLiteRegisterBlock;

    logic sys_clk;
    logic sys_rst_n;

    logic writeEnable;
    logic [7:0] writeAddress;
    logic [31:0] writeData;

    logic readEnable;
    logic [7:0] readAddress;
    logic [31:0] readData;

    logic done;
    logic busy;

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_INPUT_A = 8'h04;
    localparam logic [7:0] ADDR_INPUT_B = 8'h08;
    localparam logic [7:0] ADDR_RESULT  = 8'h0C;
    localparam logic [7:0] ADDR_STATUS  = 8'h10;

    axiLiteRegisterBlock dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .writeEnable(writeEnable),
        .writeAddress(writeAddress),
        .writeData(writeData),

        .readEnable(readEnable),
        .readAddress(readAddress),
        .readData(readData),

        .done(done),
        .busy(busy)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    // Simulated bus write
    task busWrite(input logic [7:0] address, input logic [31:0] data);
        begin
            @(negedge sys_clk);
            writeAddress = address;
            writeData = data;
            writeEnable = 1'b1;

            @(negedge sys_clk);
            writeEnable = 1'b0;
            writeAddress = 8'd0;
            writeData = 32'd0;
        end
    endtask

    // Simulated bus read
    task busRead(input logic [7:0] address);
        begin
            @(negedge sys_clk);
            readAddress = address;
            readEnable = 1'b1;

            @(negedge sys_clk);
            readEnable = 1'b0;
            readAddress = 8'd0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_axiLiteRegisterBlock.vcd");
        $dumpvars(0, tb_axiLiteRegisterBlock);

        sys_rst_n = 1'b0;

        writeEnable = 1'b0;
        writeAddress = 8'd0;
        writeData = 32'd0;

        readEnable = 1'b0;
        readAddress = 8'd0;

        #200;
        sys_rst_n = 1'b1;

        // Software writes operands.
        busWrite(ADDR_INPUT_A, 32'd15);
        busWrite(ADDR_INPUT_B, 32'd27);

        // Software starts hardware operation
        // control bit 0 = start
        busWrite(ADDR_CONTROL, 32'h0000_0001);

        // Software reads result
        // Expected: result = 15 + 27 = 42 = 0x0000002A
        busRead(ADDR_RESULT);

        // Software reads status
        // Expected: status bit 0 done = 1, status bit 1 busy = 0, status = 0x00000001
        busRead(ADDR_STATUS);

        // Second operation
        busWrite(ADDR_INPUT_A, 32'd100);
        busWrite(ADDR_INPUT_B, 32'd23);
        busWrite(ADDR_CONTROL, 32'h0000_0001);

        // Expected: result = 123 = 0x0000007B
        busRead(ADDR_RESULT);
        busRead(ADDR_STATUS);

        repeat (4) @(posedge sys_clk);

        $finish;
    end

endmodule
