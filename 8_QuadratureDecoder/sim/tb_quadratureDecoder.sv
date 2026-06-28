`timescale 1ns/1ps

module tb_quadratureDecoder;

    logic sys_clk;
    logic sys_rst_n;
    logic quad_a;
    logic quad_b;
    logic [5:0] led;

    quadratureDecoder dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .quad_a(quad_a),
        .quad_b(quad_b),
        .led(led)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk;   // 27 MHz
    end

    task stepQuadrature(input logic a, input logic b);
        begin
            quad_a = a;
            quad_b = b;
            #10_000;
        end
    endtask

    initial begin
        sys_rst_n = 1'b0;
        quad_a = 1'b0;
        quad_b = 1'b0;

        #200;
        sys_rst_n = 1'b1;

        // Forward: 00 -> 01 -> 11 -> 10 -> 00
        stepQuadrature(1'b0, 1'b1);
        stepQuadrature(1'b1, 1'b1);
        stepQuadrature(1'b1, 1'b0);
        stepQuadrature(1'b0, 1'b0);

        stepQuadrature(1'b0, 1'b1);
        stepQuadrature(1'b1, 1'b1);
        stepQuadrature(1'b1, 1'b0);
        stepQuadrature(1'b0, 1'b0);

        // Reverse: 00 -> 10 -> 11 -> 01 -> 00
        stepQuadrature(1'b1, 1'b0);
        stepQuadrature(1'b1, 1'b1);
        stepQuadrature(1'b0, 1'b1);
        stepQuadrature(1'b0, 1'b0);

        #50_000;
        $finish;
    end

    initial begin
        $dumpfile("tb_quadratureDecoder.vcd");
        $dumpvars(0, tb_quadratureDecoder);
    end

endmodule
