`timescale 1ns/1ps

module tb_streamRegister;

    logic sys_clk;
    logic sys_rst_n;

    logic inputValid;
    logic inputReady;
    logic [7:0] inputData;

    logic outputValid;
    logic outputReady;
    logic [7:0] outputData;

    streamRegister dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .inputValid(inputValid),
        .inputReady(inputReady),
        .inputData(inputData),
        .outputValid(outputValid),
        .outputReady(outputReady),
        .outputData(outputData)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    // Offer one input word.
    // The task waits until inputReady is high because valid/ready
    // transfer only happens when both inputValid and inputReady are 1.
    task sendWord(input logic [7:0] dataByte);
        begin
            @(negedge sys_clk);
            inputData = dataByte;
            inputValid = 1'b1;

            while (!inputReady) begin
                @(negedge sys_clk);
            end

            @(negedge sys_clk);
            inputValid = 1'b0;
            inputData = 8'd0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_streamRegister.vcd");
        $dumpvars(0, tb_streamRegister);

        sys_rst_n = 1'b0;
        inputValid = 1'b0;
        inputData = 8'd0;
        outputReady = 1'b0;

        #200;
        sys_rst_n = 1'b1;

        // Normal transfer:
        // Downstream is ready before data arrives.
        // Expected:
        //   inputReady = 1
        //   data A1 is accepted
        //   outputValid becomes 1
        //   outputData = A1
        //   outputReady consumes it
        outputReady = 1'b1;
        sendWord(8'hA1);

        repeat (2) @(posedge sys_clk);

        // Backpressure:
        // Downstream is not ready.
        // Expected:
        //   data B2 is accepted into the register
        //   outputValid stays 1
        //   outputData stays B2
        //   inputReady goes 0 because the register is full
        outputReady = 1'b0;
        sendWord(8'hB2);

        repeat (4) @(posedge sys_clk);

        // Release backpressure:
        // Downstream becomes ready again.
        // Expected:
        //   outputValid && outputReady happens
        //   stored B2 transfers out
        //   register becomes empty
        //   inputReady returns to 1
        outputReady = 1'b1;

        repeat (3) @(posedge sys_clk);

        // Another normal transfer after release.
        sendWord(8'hC3);

        repeat (4) @(posedge sys_clk);

        $finish;
    end

endmodule
