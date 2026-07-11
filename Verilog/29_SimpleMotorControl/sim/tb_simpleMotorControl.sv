`timescale 1ns/1ps

module tb_simpleMotorControl;

    logic sys_clk;
    logic sys_rst_n;

    logic sampleEnable;

    logic signed [15:0] setpoint;
    logic signed [15:0] measuredPosition;

    logic signed [15:0] kp;
    logic signed [15:0] ki;
    logic signed [15:0] kd;

    logic signed [15:0] controlOutput;
    logic outputValid;

    int sampleCount;

    pidMotorControl pidController (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .sampleEnable(sampleEnable),

        .setpoint(setpoint),
        .measuredValue(measuredPosition),

        .kp(kp),
        .ki(ki),
        .kd(kd),

        .controlOutput(controlOutput),
        .outputValid(outputValid)
    );

    motorModel motorModel (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .sampleEnable(sampleEnable),
        .command(controlOutput),

        .measuredPosition(measuredPosition)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    task runSample;
        begin
            @(negedge sys_clk);
            sampleEnable = 1'b1;

            @(negedge sys_clk);
            sampleEnable = 1'b0;

            wait (outputValid == 1'b1);
            @(posedge sys_clk);

            sampleCount = sampleCount + 1;

            $display(
                "sample=%0d setpoint=%0d measured=%0d error=%0d control=%0d velocity=%0d", sampleCount, setpoint, measuredPosition, 
                    pidController.currentError, controlOutput, motorModel.velocity);
        end
    endtask

    initial begin
        $dumpfile("sim/tb_simpleMotorControl.vcd");
        $dumpvars(0, tb_simpleMotorControl);

        sys_rst_n = 1'b0;
        sampleEnable = 1'b0;
        sampleCount = 0;

        setpoint = 16'sd0;

        kp = 16'sd0;
        ki = 16'sd0;
        kd = 16'sd0;

        #200;
        sys_rst_n = 1'b1;

        // PID gains: kp = 0.50, ki = 0.02, kd = 0.25
        kp = 16'sh0080;
        ki = 16'sh0005;
        kd = 16'sh0040;

        // Step command: Target position = +10.0
        setpoint = 16'sh0A00;

        // Let the closed-loop system respond to the step input
        repeat (120) begin
            runSample();
        end

        // Reverse direction: Target position = -5.0
        setpoint = -16'sd1280;

        repeat (120) begin
            runSample();
        end

        // Return to zero
        setpoint = 16'sd0;

        repeat (120) begin
            runSample();
        end

        repeat (8) @(posedge sys_clk);

        $finish;
    end

endmodule
