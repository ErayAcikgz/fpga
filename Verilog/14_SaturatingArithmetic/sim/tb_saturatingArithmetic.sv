`timescale 1ns/1ps

module tb_saturatingArithmetic;

    logic signed [7:0] a;
    logic signed [7:0] b;

    logic signed [7:0] addResult;
    logic signed [7:0] subResult;
    logic signed [7:0] mulResult;

    satAdd addInst (
        .a(a),
        .b(b),
        .result(addResult)
    );

    satSub subInst (
        .a(a),
        .b(b),
        .result(subResult)
    );

    satMul mulInst (
        .a(a),
        .b(b),
        .result(mulResult)
    );

    initial begin
        $dumpfile("sim/tb_saturatingArithmetic.vcd");
        $dumpvars(0, tb_saturatingArithmetic);

        // Check add saturation: 7.0 + 2.0 -> max
        a = 8'sh70;
        b = 8'sh20;
        #10;

        // Check sub saturation: -7.0 - 2.0 -> min
        a = 8'sh90;
        b = 8'sh20;
        #10;

        // Check normal multiply: 2.0 * 2.0 -> 4.0
        a = 8'sh20;
        b = 8'sh20;
        #10;

        // Check positive multiply saturation: 7.0 * 2.0 -> max
        a = 8'sh70;
        b = 8'sh20;
        #10;

        // Check negative multiply saturation: -7.0 * 2.0 -> min
        a = 8'sh90;
        b = 8'sh20;
        #10;

        // Check normal add: 1.0 + 0.5 -> 1.5
        a = 8'sh10;
        b = 8'sh08;
        #10;

        // Check normal sub: 1.5 - 0.5 -> 1.0
        a = 8'sh18;
        b = 8'sh08;
        #10;

        $finish;
    end

endmodule
