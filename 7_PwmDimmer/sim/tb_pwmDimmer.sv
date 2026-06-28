`timescale 1ns/1ps

module tb_pwmDimmer;

    logic sys_clk;
    logic sys_rst_n;
    logic led;

    pwmDimmer dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .led(led)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk;   // 27 MHz
    end

    initial begin
        sys_rst_n = 1'b0;
        #200;
        sys_rst_n = 1'b1;
    end

    initial begin
        $dumpfile("tb_pwmDimmer.vcd");
        $dumpvars(0, tb_pwmDimmer);

        #30_000_000;   // 30 ms
        $finish;
    end

endmodule
