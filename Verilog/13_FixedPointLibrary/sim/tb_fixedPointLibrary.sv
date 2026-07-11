`timescale 1ns/1ps

module tb_fixedPointLibrary;

    logic signed [7:0] a;
    logic signed [7:0] b;

    logic signed [7:0] addResult;
    logic signed [7:0] subResult;
    logic signed [7:0] mulResult;

    fixedAdd addInst (
        .a(a),
        .b(b),
        .result(addResult)
    );

    fixedSub subInst (
        .a(a),
        .b(b),
        .result(subResult)
    );

    fixedMul mulInst (
        .a(a),
        .b(b),
        .result(mulResult)
    );

    initial begin
        $dumpfile("sim/tb_fixedPointLibrary.vcd");      // Waveform recordings must be enabled before the signals change
        $dumpvars(0, tb_fixedPointLibrary);             // Below commands change signals, so dumpfile() and dumpvars() were run first

        // Comments say which operation is being checked for that instance, 
        // all 3 operations happen at the same time regardless of order

        // 1.0 + 0.5 = 1.5
        a = 8'sh10;
        b = 8'sh08;
        #10;

        // 1.5 - 0.5 = 1.0
        a = 8'sh18;
        b = 8'sh08;
        #10;

        // 1.5 * 2.0 = 3.0
        a = 8'sh18;
        b = 8'sh20;
        #10;

        // -1.0 * 2.0 = -2.0
        a = 8'shF0;
        b = 8'sh20;
        #10;

        // 0.5 * 0.5 = 0.25
        a = 8'sh08;
        b = 8'sh08;
        #10;

        $finish;
    end

endmodule
