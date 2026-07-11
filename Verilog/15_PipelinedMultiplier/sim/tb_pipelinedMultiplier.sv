`timescale 1ns/1ps

module tb_pipelinedMultiplier;

    logic sys_clk;
    logic sys_rst_n;

    logic inputValid;
    logic signed [7:0] a;
    logic signed [7:0] b;

    logic outputValid;
    logic signed [7:0] result;

    pipelinedMultiplier dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .inputValid(inputValid),
        .a(a),
        .b(b),
        .outputValid(outputValid),
        .result(result)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    // Drive one valid multiplication input for one clock cycle.
    // Inputs are changed on the falling edge so they are stable before the DUT samples them on the next rising edge.
    task sendMultiply(input logic signed [7:0] inputA, input logic signed [7:0] inputB); begin
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

    initial begin
        $dumpfile("sim/tb_pipelinedMultiplier.vcd");
        $dumpvars(0, tb_pipelinedMultiplier);

        sys_rst_n = 1'b0;
        inputValid = 1'b0;
        a = 8'sd0;
        b = 8'sd0;

        #200;
        sys_rst_n = 1'b1;

        // 2.0 * 2.0 = 4.0
        // 8'sh20 * 8'sh20 -> 8'sh40
        sendMultiply(8'sh20, 8'sh20);

        // 7.0 * 2.0 = 14.0, too large for Q4.4
        // Saturates to +7.9375 = 8'sh7F
        sendMultiply(8'sh70, 8'sh20);

        // -7.0 * 2.0 = -14.0, too small for Q4.4
        // Saturates to -8.0 = 8'sh80
        sendMultiply(8'sh90, 8'sh20);

        // 1.5 * 2.0 = 3.0
        // 8'sh18 * 8'sh20 -> 8'sh30
        sendMultiply(8'sh18, 8'sh20);

        // 0.5 * 0.5 = 0.25
        // 8'sh08 * 8'sh08 -> 8'sh04
        sendMultiply(8'sh08, 8'sh08);

        // Let the final pipeline result drain out, 8 is a safe margin
        repeat (8) @(posedge sys_clk); // Wait for 8 @(posedge sys_clk);

        $finish;
    end

endmodule
