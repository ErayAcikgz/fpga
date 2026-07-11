`timescale 1ns/1ps

module tb_nnAccelerator;

    logic sys_clk;
    logic sys_rst_n;

    logic writeEnable;
    logic [7:0] writeAddress;
    logic [31:0] writeData;

    logic readEnable;
    logic [7:0] readAddress;
    logic [31:0] readData;

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_STATUS  = 8'h04;

    localparam logic [7:0] ADDR_X0 = 8'h10;
    localparam logic [7:0] ADDR_X1 = 8'h14;
    localparam logic [7:0] ADDR_X2 = 8'h18;
    localparam logic [7:0] ADDR_X3 = 8'h1C;

    localparam logic [7:0] ADDR_W00 = 8'h20;
    localparam logic [7:0] ADDR_W01 = 8'h24;
    localparam logic [7:0] ADDR_W02 = 8'h28;
    localparam logic [7:0] ADDR_W03 = 8'h2C;

    localparam logic [7:0] ADDR_W10 = 8'h30;
    localparam logic [7:0] ADDR_W11 = 8'h34;
    localparam logic [7:0] ADDR_W12 = 8'h38;
    localparam logic [7:0] ADDR_W13 = 8'h3C;

    localparam logic [7:0] ADDR_W20 = 8'h40;
    localparam logic [7:0] ADDR_W21 = 8'h44;
    localparam logic [7:0] ADDR_W22 = 8'h48;
    localparam logic [7:0] ADDR_W23 = 8'h4C;

    localparam logic [7:0] ADDR_W30 = 8'h50;
    localparam logic [7:0] ADDR_W31 = 8'h54;
    localparam logic [7:0] ADDR_W32 = 8'h58;
    localparam logic [7:0] ADDR_W33 = 8'h5C;

    localparam logic [7:0] ADDR_B0 = 8'h60;
    localparam logic [7:0] ADDR_B1 = 8'h64;
    localparam logic [7:0] ADDR_B2 = 8'h68;
    localparam logic [7:0] ADDR_B3 = 8'h6C;

    localparam logic [7:0] ADDR_Y0 = 8'h70;
    localparam logic [7:0] ADDR_Y1 = 8'h74;
    localparam logic [7:0] ADDR_Y2 = 8'h78;
    localparam logic [7:0] ADDR_Y3 = 8'h7C;

    nnAccelerator dut (
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
        forever #18.518 sys_clk = ~sys_clk;
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

    task checkOutput(input logic [7:0] address, input logic signed [15:0] expectedValue, input string name);
        begin
            readRegister(address);

            if (readData[15:0] !== expectedValue) begin
                $display("ERROR: %s expected 0x%04h, got 0x%04h", name, expectedValue, readData[15:0]);
            end else begin
                $display("PASS: %s = 0x%04h", name, readData[15:0]);
            end
        end
    endtask

    task startAccelerator;
        begin
            writeRegister(ADDR_CONTROL, 32'h0000_0001);
            waitForDone();
        end
    endtask

    task loadTestOne;
        begin
            // x = [1.0, 2.0, 3.0, 4.0]
            writeRegister(ADDR_X0, 32'h0000_0010);
            writeRegister(ADDR_X1, 32'h0000_0020);
            writeRegister(ADDR_X2, 32'h0000_0030);
            writeRegister(ADDR_X3, 32'h0000_0040);

            // W row 0 = [1, 0, 0, 0]
            writeRegister(ADDR_W00, 32'h0000_0010);
            writeRegister(ADDR_W01, 32'h0000_0000);
            writeRegister(ADDR_W02, 32'h0000_0000);
            writeRegister(ADDR_W03, 32'h0000_0000);

            // W row 1 = [0, 1, 0, 0]
            writeRegister(ADDR_W10, 32'h0000_0000);
            writeRegister(ADDR_W11, 32'h0000_0010);
            writeRegister(ADDR_W12, 32'h0000_0000);
            writeRegister(ADDR_W13, 32'h0000_0000);

            // W row 2 = [1, 1, 1, 1]
            writeRegister(ADDR_W20, 32'h0000_0010);
            writeRegister(ADDR_W21, 32'h0000_0010);
            writeRegister(ADDR_W22, 32'h0000_0010);
            writeRegister(ADDR_W23, 32'h0000_0010);

            // W row 3 = [-1, -1, -1, -1]
            writeRegister(ADDR_W30, 32'h0000_00F0);
            writeRegister(ADDR_W31, 32'h0000_00F0);
            writeRegister(ADDR_W32, 32'h0000_00F0);
            writeRegister(ADDR_W33, 32'h0000_00F0);

            // Biases: b0 = 0.0, b1 = 0.0, b2 = -2.0, b3 = +1.0
            writeRegister(ADDR_B0, 32'h0000_0000);
            writeRegister(ADDR_B1, 32'h0000_0000);
            writeRegister(ADDR_B2, 32'h0000_FFE0);
            writeRegister(ADDR_B3, 32'h0000_0010);
        end
    endtask

    task loadTestTwo;
        begin
            // x = [-1.0, 2.0, -3.0, 4.0]
            writeRegister(ADDR_X0, 32'h0000_00F0);
            writeRegister(ADDR_X1, 32'h0000_0020);
            writeRegister(ADDR_X2, 32'h0000_00D0);
            writeRegister(ADDR_X3, 32'h0000_0040);

            // Every W row = [1, 1, 1, 1]
            writeRegister(ADDR_W00, 32'h0000_0010);
            writeRegister(ADDR_W01, 32'h0000_0010);
            writeRegister(ADDR_W02, 32'h0000_0010);
            writeRegister(ADDR_W03, 32'h0000_0010);

            writeRegister(ADDR_W10, 32'h0000_0010);
            writeRegister(ADDR_W11, 32'h0000_0010);
            writeRegister(ADDR_W12, 32'h0000_0010);
            writeRegister(ADDR_W13, 32'h0000_0010);

            writeRegister(ADDR_W20, 32'h0000_0010);
            writeRegister(ADDR_W21, 32'h0000_0010);
            writeRegister(ADDR_W22, 32'h0000_0010);
            writeRegister(ADDR_W23, 32'h0000_0010);

            writeRegister(ADDR_W30, 32'h0000_0010);
            writeRegister(ADDR_W31, 32'h0000_0010);
            writeRegister(ADDR_W32, 32'h0000_0010);
            writeRegister(ADDR_W33, 32'h0000_0010);

            // Dot product = -1 + 2 - 3 + 4 = 2.0
            // b0 = 0.0 -> y0 = 2.0
            // b1 = -3.0 -> y1 = -1.0 -> ReLU -> 0
            // b2 = +1.0 -> y2 = 3.0
            // b3 = -2.0 -> y3 = 0.0
            writeRegister(ADDR_B0, 32'h0000_0000);
            writeRegister(ADDR_B1, 32'h0000_FFD0);
            writeRegister(ADDR_B2, 32'h0000_0010);
            writeRegister(ADDR_B3, 32'h0000_FFE0);
        end
    endtask

    initial begin
        $dumpfile("sim/tb_nnAccelerator.vcd");
        $dumpvars(0, tb_nnAccelerator);

        sys_rst_n = 1'b0;

        writeEnable = 1'b0;
        writeAddress = 8'd0;
        writeData = 32'd0;

        readEnable = 1'b0;
        readAddress = 8'd0;

        #200;
        sys_rst_n = 1'b1;

        // Test 1
        // Expected: y0 = 1.0 -> 0x0010, y1 = 2.0 -> 0x0020, y2 = 8.0 -> 0x0080, y3 = 0.0 -> 0x0000
        loadTestOne();
        startAccelerator();

        checkOutput(ADDR_Y0, 16'sh0010, "test1 y0");
        checkOutput(ADDR_Y1, 16'sh0020, "test1 y1");
        checkOutput(ADDR_Y2, 16'sh0080, "test1 y2");
        checkOutput(ADDR_Y3, 16'sh0000, "test1 y3");

        // Test 2
        // Expected: y0 = 2.0 -> 0x0020, y1 = 0.0 -> 0x0000, y2 = 3.0 -> 0x0030, y3 = 0.0 -> 0x0000
        loadTestTwo();
        startAccelerator();

        checkOutput(ADDR_Y0, 16'sh0020, "test2 y0");
        checkOutput(ADDR_Y1, 16'sh0000, "test2 y1");
        checkOutput(ADDR_Y2, 16'sh0030, "test2 y2");
        checkOutput(ADDR_Y3, 16'sh0000, "test2 y3");

        repeat (8) @(posedge sys_clk);

        $finish;
    end

endmodule
