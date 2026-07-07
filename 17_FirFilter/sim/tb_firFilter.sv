`timescale 1ns/1ps

module tb_firFilter;

    logic sys_clk;
    logic sys_rst_n;

    logic sampleValid;
    logic signed [7:0] sampleIn;

    logic outputValid;
    logic signed [15:0] sampleOut;

    firFilter dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .sampleValid(sampleValid),
        .sampleIn(sampleIn),
        .outputValid(outputValid),
        .sampleOut(sampleOut)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    task sendSample (input logic signed [7:0] inputSample);
        begin
            @(negedge sys_clk);
            sampleIn = inputSample;
            sampleValid = 1'b1;

            @(negedge sys_clk);
            sampleValid = 1'b0;
            sampleIn = 8'sd0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_firFilter.vcd");
        $dumpvars(0, tb_firFilter);

        sys_rst_n = 1'b0;
        sampleValid = 1'b0;
        sampleIn = 8'sd0;

        #200;
        sys_rst_n = 1'b1;

        // Feed constant 4.0.
        // 4.0 in Q4.4: 4.0 * 16 = 64 = 8'sh40
        // Coefficients are all 0.25.
        // Expected output ramp:
        // after 1st sample: 0.25 * 4.0 = 1.0 -> 16'sh0010
        // after 2nd sample: 0.50 * 4.0 = 2.0 -> 16'sh0020
        // after 3rd sample: 0.75 * 4.0 = 3.0 -> 16'sh0030
        // after 4th sample: 1.00 * 4.0 = 4.0 -> 16'sh0040
        sendSample(8'sh40);
        sendSample(8'sh40);
        sendSample(8'sh40);
        sendSample(8'sh40);
        sendSample(8'sh40);

        // Now feed zero. This shows the old samples leaving the delay line.
        // Expected output decay:
        // 3.0 -> 16'sh0030
        // 2.0 -> 16'sh0020
        // 1.0 -> 16'sh0010
        // 0.0 -> 16'sh0000
        sendSample(8'sh00);
        sendSample(8'sh00);
        sendSample(8'sh00);
        sendSample(8'sh00);

        // Signed test.
        // Feed -4.0: -4.0 * 16 = -64 = 8'shC0
        // Expected ramp:
        // -1.0 -> 16'shFFF0
        // -2.0 -> 16'shFFE0
        // -3.0 -> 16'shFFD0
        // -4.0 -> 16'shFFC0
        sendSample(8'shC0);
        sendSample(8'shC0);
        sendSample(8'shC0);
        sendSample(8'shC0);

        repeat (4) @(posedge sys_clk);

        $finish;
    end

endmodule
        
