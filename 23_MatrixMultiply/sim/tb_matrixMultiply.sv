`timescale 1ns/1ps

module tb_matrixMultiply;

    logic sys_clk;
    logic sys_rst_n;

    logic start;
    logic busy;
    logic done;

    logic signed [7:0] x0;
    logic signed [7:0] x1;
    logic signed [7:0] x2;
    logic signed [7:0] x3;

    logic signed [7:0] w00;
    logic signed [7:0] w01;
    logic signed [7:0] w02;
    logic signed [7:0] w03;

    logic signed [7:0] w10;
    logic signed [7:0] w11;
    logic signed [7:0] w12;
    logic signed [7:0] w13;

    logic signed [7:0] w20;
    logic signed [7:0] w21;
    logic signed [7:0] w22;
    logic signed [7:0] w23;

    logic signed [7:0] w30;
    logic signed [7:0] w31;
    logic signed [7:0] w32;
    logic signed [7:0] w33;

    logic signed [15:0] y0;
    logic signed [15:0] y1;
    logic signed [15:0] y2;
    logic signed [15:0] y3;

    matrixVectorMultiply dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .start(start),

        .x0(x0),
        .x1(x1),
        .x2(x2),
        .x3(x3),

        .w00(w00),
        .w01(w01),
        .w02(w02),
        .w03(w03),

        .w10(w10),
        .w11(w11),
        .w12(w12),
        .w13(w13),

        .w20(w20),
        .w21(w21),
        .w22(w22),
        .w23(w23),

        .w30(w30),
        .w31(w31),
        .w32(w32),
        .w33(w33),

        .busy(busy),
        .done(done),

        .y0(y0),
        .y1(y1),
        .y2(y2),
        .y3(y3)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    task startOperation;
        begin
            @(negedge sys_clk);
            start = 1'b1;

            @(negedge sys_clk);
            start = 1'b0;

            wait (done == 1'b1);
            @(posedge sys_clk);
        end
    endtask

    initial begin
        $dumpfile("sim/tb_matrixMultiply.vcd");
        $dumpvars(0, tb_matrixMultiply);

        sys_rst_n = 1'b0;
        start = 1'b0;

        x0 = 8'sd0;
        x1 = 8'sd0;
        x2 = 8'sd0;
        x3 = 8'sd0;

        w00 = 8'sd0;
        w01 = 8'sd0;
        w02 = 8'sd0;
        w03 = 8'sd0;

        w10 = 8'sd0;
        w11 = 8'sd0;
        w12 = 8'sd0;
        w13 = 8'sd0;

        w20 = 8'sd0;
        w21 = 8'sd0;
        w22 = 8'sd0;
        w23 = 8'sd0;

        w30 = 8'sd0;
        w31 = 8'sd0;
        w32 = 8'sd0;
        w33 = 8'sd0;

        #200;
        sys_rst_n = 1'b1;

        // Vector: x = [1.0, 2.0, 3.0, 4.0]
        // Q4.4:
        x0 = 8'sh10;
        x1 = 8'sh20;
        x2 = 8'sh30;
        x3 = 8'sh40;

        // Matrix:
        //   [1 0 0 0
        //    0 1 0 0
        //    1 1 1 1
        //    1 2 3 4]
        // Expected real outputs: y0 = 1, y1 = 2, y2 = 10, y3 = 30
        // Q4.4: y0 = 16'sh0010, y1 = 16'sh0020, y2 = 16'sh00A0, y3 = 16'sh01E0

        w00 = 8'sh10;
        w01 = 8'sh00;
        w02 = 8'sh00;
        w03 = 8'sh00;

        w10 = 8'sh00;
        w11 = 8'sh10;
        w12 = 8'sh00;
        w13 = 8'sh00;

        w20 = 8'sh10;
        w21 = 8'sh10;
        w22 = 8'sh10;
        w23 = 8'sh10;

        w30 = 8'sh10;
        w31 = 8'sh20;
        w32 = 8'sh30;
        w33 = 8'sh40;

        startOperation();

        // Signed test
        // Vector: x = [-1.0, 2.0, -3.0, 4.0]
        // Matrix: all rows = [1, 1, 1, 1]
        // Expected: -1 + 2 - 3 + 4 = 2.0 -> 16'sh0020

        x0 = 8'shF0;
        x1 = 8'sh20;
        x2 = 8'shD0;
        x3 = 8'sh40;

        w00 = 8'sh10;
        w01 = 8'sh10;
        w02 = 8'sh10;
        w03 = 8'sh10;

        w10 = 8'sh10;
        w11 = 8'sh10;
        w12 = 8'sh10;
        w13 = 8'sh10;

        w20 = 8'sh10;
        w21 = 8'sh10;
        w22 = 8'sh10;
        w23 = 8'sh10;

        w30 = 8'sh10;
        w31 = 8'sh10;
        w32 = 8'sh10;
        w33 = 8'sh10;

        startOperation();

        repeat (6) @(posedge sys_clk);

        $finish;
    end

endmodule
