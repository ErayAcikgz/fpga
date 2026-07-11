`timescale 1ns/1ps

module tb_macUnit;
    
    logic sys_clk;
    logic sys_rst_n;

    logic clear;
    logic inputValid;
    logic signed [7:0] a;
    logic signed [7:0] b;

    logic outputValid;
    logic signed [15:0] accumulator;

    macUnit dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .clear(clear),
        .inputValid(inputValid),
        .a(a),
        .b(b),
        .outputValid(outputValid),
        .accumulator(accumulator)
);

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    
    // One MAC operation per clock cyle
    // Inputs change on falling edge for stability, DUT samples them on the next rising edge
    task sendMac(
        input logic signed [7:0] inputA,
        input logic signed [7:0] inputB
    );
        begin
            @(negedge sys_clk);
            a = inputA;
            b = inputB;
            inputValid = 1'b1;

            @(negedge sys_clk);
            inputValid = 1'b0;
            a = 8'sd0;
            b = 8'sd0;
        end
    endtask

    task clearAccumulator;
        begin
            @(negedge sys_clk);
            clear = 1'b1;

            @(negedge sys_clk);
            clear = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_macUnit.vcd");
        $dumpvars(0, tb_macUnit);
        
        sys_rst_n = 1'b0;
        clear = 1'b0;
        inputValid = 1'b0;
        a = 8'sd0;
        b = 8'sd0;

        #200;
        sys_rst_n = 1'b1;

        // 1.0 * 2.0 = 2.0
        // 0.5 * 2.0 = 1.0
        // 1.5 * 2.0 = 3.0
        // Final sum: 2.0 + 1.0 + 3.0 = 6.0
        // Q4.4 stored: 6.0 * 16 = 96 = 16'sh0060
        sendMac(8'sh10, 8'sh20);
        sendMac(8'sh08, 8'sh20);
        sendMac(8'sh18, 8'sh20);

        clearAccumulator();

        // -1.0 * 2.0 = -2.0
        // 0.5  * 2.0 =  1.0
        // Final sum: -1.0
        // Q4.4 stored: -1.0 * 16 = -16 = 16'shFFF0
        sendMac(8'shF0, 8'sh20);
        sendMac(8'sh08, 8'sh20);

        repeat (4) @(posedge sys_clk);

        $finish;
    end

endmodule
