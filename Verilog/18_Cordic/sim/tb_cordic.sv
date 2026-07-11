`timescale 1ns/1ps

module tb_cordic;

    logic sys_clk;
    logic sys_rst_n;

    logic inputValid;
    logic signed [15:0] angle;

    logic outputValid;
    logic signed [15:0] sinOut;
    logic signed [15:0] cosOut;

    cordic dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .inputValid(inputValid),
        .angle(angle),
        .outputValid(outputValid),
        .sinOut(sinOut),
        .cosOut(cosOut)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    // Send one angle command.
    // angle is degrees * 256.
    task sendAngle(input logic signed [15:0] inputAngle);
        begin
            @(negedge sys_clk);
            angle = inputAngle;
            inputValid = 1'b1;

            @(negedge sys_clk);
            inputValid = 1'b0;
            angle = 16'sd0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_cordic.vcd");
        $dumpvars(0, tb_cordic);

        sys_rst_n = 1'b0;
        inputValid = 1'b0;
        angle = 16'sd0;

        #200;
        sys_rst_n = 1'b1;

        // 0 degrees:
        // cos(0) = 1.0, cosOut = 16'sh3FFF
        // sin(0) = 0.0, sinOut = 16'sh0000 
        sendAngle(16'sd0);

        // CORDIC takes several clock cycles to finish, so testbench can't immediately send the next angle
        wait (outputValid == 1'b1); // Pause the testbench until outputValid becomes 1, 
        @(posedge sys_clk);         // outputValid is only a one-cycle pulse, extra clock edge lets the output cycle complete cleanly

        // 45 degrees, 45 * 256 = 11520
        // cos(45) ≈ 0.707, cosOut ≈ 16'sh2D41
        // sin(45) ≈ 0.707, sinOut ≈ 16'sh2D42 
        sendAngle(16'sd11520);

        wait (outputValid == 1'b1);
        @(posedge sys_clk);

        // 90 degrees, 90 * 256 = 23040
        // cos(90) = 0.0, cosOut ≈ 16'sh0000
        // sin(90) = 1.0, sinOut ≈ 16'sh3FFF  
        sendAngle(16'sd23040);

        wait (outputValid == 1'b1);
        @(posedge sys_clk);

        // -45 degrees, -45 * 256 = -11520
        // cos(-45) ≈ 0.707, cosOut ≈ 16'sh2D43
        // sin(-45) ≈ -0.707, sinOut ≈ 16'shD2BF 
        sendAngle(-16'sd11520);

        wait (outputValid == 1'b1);
        repeat (4) @(posedge sys_clk);

        $finish;
    end

endmodule
