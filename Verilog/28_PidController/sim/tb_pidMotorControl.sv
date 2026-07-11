`timescale 1ns/1ps

module tb_pidMotorControl;

    logic sys_clk;
    logic sys_rst_n;

    logic sampleEnable;

    logic signed [15:0] setpoint;
    logic signed [15:0] measuredValue;

    logic signed [15:0] kp;
    logic signed [15:0] ki;
    logic signed [15:0] kd;

    logic signed [15:0] controlOutput;
    logic outputValid;

    fpgaPidMotorControl dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .sampleEnable(sampleEnable),

        .setpoint(setpoint),
        .measuredValue(measuredValue),

        .kp(kp),
        .ki(ki),
        .kd(kd),

        .controlOutput(controlOutput),
        .outputValid(outputValid)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    task applySample(input logic signed [15:0] newMeasuredValue);
        begin
            @(negedge sys_clk);
            measuredValue = newMeasuredValue;
            sampleEnable = 1'b1;

            @(negedge sys_clk);
            sampleEnable = 1'b0;

            wait (outputValid == 1'b1);
            @(posedge sys_clk);

            $display("setpoint=%0d measured=%0d error=%0d output=%0d hex=%04h", setpoint, measuredValue, dut.currentError, controlOutput, controlOutput);
        end
    endtask

    initial begin
        $dumpfile("sim/tb_pidMotorControl.vcd");
        $dumpvars(0, tb_pidMotorControl);

        sys_rst_n = 1'b0;

        sampleEnable = 1'b0;

        setpoint = 16'sd0;
        measuredValue = 16'sd0;

        kp = 16'sd0;
        ki = 16'sd0;
        kd = 16'sd0;

        #200;
        sys_rst_n = 1'b1;

        // Gains: kp = 1.0, ki = 0.25, kd = 0.5
        kp = 16'sh0100;
        ki = 16'sh0040;
        kd = 16'sh0080;

        // Target is 10.0 in Q8.8
        setpoint = 16'sh0A00;

        // Simulated measured values approach setpoint: 0.0, 2.0, 5.0, 8.0, 9.0, 10.0, 11.0
        // As measured value approaches setpoint, error gets smaller
        // When measured value exceeds setpoint, error becomes negative

        applySample(16'sh0000); // measured = 0.0
        applySample(16'sh0200); // measured = 2.0
        applySample(16'sh0500); // measured = 5.0
        applySample(16'sh0800); // measured = 8.0
        applySample(16'sh0900); // measured = 9.0
        applySample(16'sh0A00); // measured = 10.0
        applySample(16'sh0B00); // measured = 11.0

        // Saturation test
        kp = 16'sh7F00;
        ki = 16'sd0;
        kd = 16'sd0;
        setpoint = 16'sh7F00;
        measuredValue = -16'sh7F00;

        applySample(measuredValue);

        repeat (6) @(posedge sys_clk);

        $finish;
    end

endmodule
