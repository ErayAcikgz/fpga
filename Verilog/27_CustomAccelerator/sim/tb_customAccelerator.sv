`timescale 1ns/1ps

module tb_customAccelerator;

    logic sys_clk;
    logic sys_rst_n;

    logic writeEnable;
    logic [7:0] writeAddress;
    logic [31:0] writeData;

    logic readEnable;
    logic [7:0] readAddress;
    logic [31:0] readData;

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_INPUT_A = 8'h04;
    localparam logic [7:0] ADDR_INPUT_B = 8'h08;
    localparam logic [7:0] ADDR_INPUT_C = 8'h0C;
    localparam logic [7:0] ADDR_RESULT  = 8'h10;
    localparam logic [7:0] ADDR_STATUS  = 8'h14;

    customAccelerator dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .writeEnable(writeEnable),
        .writeAddress(writeAddress),
        .writeData(writeData),

        .readEnable(readEnable),
        .readAddress(readAddress),
        .readData(readData)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    task writeRegister(input logic [7:0] address, input logic [31:0] data);
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

    task readRegister(input logic [7:0] address);
        begin
            @(negedge sys_clk);
            readAddress = address;
            readEnable = 1'b1;

            @(negedge sys_clk);
            readEnable = 1'b0;
            readAddress = 8'd0;
        end
    endtask

    task waitForDone;
        begin
            readRegister(ADDR_STATUS);

            while (readData[0] != 1'b1) begin
                readRegister(ADDR_STATUS);
            end
        end
    endtask

    task checkResult(input logic [31:0] expectedResult);
        begin
            readRegister(ADDR_RESULT);

            if (readData !== expectedResult) begin
                $display(
                    "ERROR: expected result %0d / 0x%08h, got %0d / 0x%08h", expectedResult, expectedResult, readData,readData);
            end else begin
                $display(
                    "PASS: result = %0d / 0x%08h", readData, readData);
            end
        end
    endtask

    task runAccelerator(input logic [31:0] inputA, input logic [31:0] inputB, input logic [31:0] inputC, input logic [31:0] expectedResult);
        begin
            writeRegister(ADDR_INPUT_A, inputA);
            writeRegister(ADDR_INPUT_B, inputB);
            writeRegister(ADDR_INPUT_C, inputC);

            writeRegister(ADDR_CONTROL, 32'h0000_0001);

            waitForDone();

            checkResult(expectedResult);
        end
    endtask

    initial begin
        $dumpfile("sim/tb_customAccelerator.vcd");
        $dumpvars(0, tb_customAccelerator);

        sys_rst_n = 1'b0;

        writeEnable = 1'b0;
        writeAddress = 8'd0;
        writeData = 32'd0;

        readEnable = 1'b0;
        readAddress = 8'd0;

        #200;
        sys_rst_n = 1'b1;

        // result = 3 * 4 + 5 = 17
        runAccelerator(32'd3, 32'd4, 32'd5, 32'd17);

        // result = 10 * 20 + 7 = 207
        runAccelerator(32'd10, 32'd20, 32'd7, 32'd207);

        // result = 255 * 2 + 1 = 511
        runAccelerator(32'd255, 32'd2, 32'd1, 32'd511);

        repeat (6) @(posedge sys_clk);

        $display("Complete.");
        $finish;
    end

endmodule
