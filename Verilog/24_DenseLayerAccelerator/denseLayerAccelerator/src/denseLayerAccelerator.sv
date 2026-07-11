// 4-input, 4-output signed Q4.4 dense layer accelerator.
// y = ReLU(W*x + b)
// ReLU: if value < 0: output = 0, else: output = value

module denseLayerAccelerator (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic start,

    input logic signed [7:0] x0,
    input logic signed [7:0] x1,
    input logic signed [7:0] x2,
    input logic signed [7:0] x3,

    input logic signed [7:0] w00,
    input logic signed [7:0] w01,
    input logic signed [7:0] w02,
    input logic signed [7:0] w03,

    input logic signed [7:0] w10,
    input logic signed [7:0] w11,
    input logic signed [7:0] w12,
    input logic signed [7:0] w13,

    input logic signed [7:0] w20,
    input logic signed [7:0] w21,
    input logic signed [7:0] w22,
    input logic signed [7:0] w23,

    input logic signed [7:0] w30,
    input logic signed [7:0] w31,
    input logic signed [7:0] w32,
    input logic signed [7:0] w33,

    input logic signed [15:0] b0,
    input logic signed [15:0] b1,
    input logic signed [15:0] b2,
    input logic signed [15:0] b3,

    output logic busy,
    output logic done,

    output logic signed [15:0] y0,
    output logic signed [15:0] y1,
    output logic signed [15:0] y2,
    output logic signed [15:0] y3
);

    typedef enum logic [1:0] {
        IDLE,
        MAC,
        ACTIVATE,
        FINISH
    } state_t;

    state_t state;

    // Output neuron
    logic [1:0] row;

    // Input weight
    logic [1:0] col;

    logic signed [7:0] currentInput;
    logic signed [7:0] currentWeight;

    logic signed [15:0] rawProduct;
    logic signed [15:0] scaledProduct;

    logic signed [15:0] acc0;
    logic signed [15:0] acc1;
    logic signed [15:0] acc2;
    logic signed [15:0] acc3;

    logic signed [15:0] biased0;
    logic signed [15:0] biased1;
    logic signed [15:0] biased2;
    logic signed [15:0] biased3;

    assign rawProduct = currentWeight * currentInput;
    assign scaledProduct = rawProduct >>> 4;

    // Bias addition is separated so ReLU logic is easy to read
    assign biased0 = acc0 + b0;
    assign biased1 = acc1 + b1;
    assign biased2 = acc2 + b2;
    assign biased3 = acc3 + b3;

    // Select vector element
    always_comb begin
        case (col)
            2'd0: currentInput = x0;
            2'd1: currentInput = x1;
            2'd2: currentInput = x2;
            2'd3: currentInput = x3;
            default: currentInput = 8'sd0;
        endcase
    end

    // Select matrix element
    always_comb begin
        case ({row, col})
            4'b00_00: currentWeight = w00;
            4'b00_01: currentWeight = w01;
            4'b00_10: currentWeight = w02;
            4'b00_11: currentWeight = w03;

            4'b01_00: currentWeight = w10;
            4'b01_01: currentWeight = w11;
            4'b01_10: currentWeight = w12;
            4'b01_11: currentWeight = w13;

            4'b10_00: currentWeight = w20;
            4'b10_01: currentWeight = w21;
            4'b10_10: currentWeight = w22;
            4'b10_11: currentWeight = w23;

            4'b11_00: currentWeight = w30;
            4'b11_01: currentWeight = w31;
            4'b11_10: currentWeight = w32;
            4'b11_11: currentWeight = w33;

            default: currentWeight = 8'sd0;
        endcase
    end

    // ReLU helper
    function automatic logic signed [15:0] relu(input logic signed [15:0] value);
        begin
            if (value < 16'sd0) begin
                relu = 16'sd0;
            end else begin
                relu = value;
            end
        end
    endfunction


    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state <= IDLE;

            row <= 2'd0;
            col <= 2'd0;

            busy <= 1'b0;
            done <= 1'b0;

            acc0 <= 16'sd0;
            acc1 <= 16'sd0;
            acc2 <= 16'sd0;
            acc3 <= 16'sd0;

            y0 <= 16'sd0;
            y1 <= 16'sd0;
            y2 <= 16'sd0;
            y3 <= 16'sd0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        acc0 <= 16'sd0;
                        acc1 <= 16'sd0;
                        acc2 <= 16'sd0;
                        acc3 <= 16'sd0;

                        y0 <= 16'sd0;
                        y1 <= 16'sd0;
                        y2 <= 16'sd0;
                        y3 <= 16'sd0;

                        row <= 2'd0;
                        col <= 2'd0;

                        busy <= 1'b1;
                        state <= MAC;
                    end
                end

                MAC: begin
                    busy <= 1'b1;

                    // Accumulate one product per clock.
                    case (row)
                        2'd0: acc0 <= acc0 + scaledProduct;
                        2'd1: acc1 <= acc1 + scaledProduct;
                        2'd2: acc2 <= acc2 + scaledProduct;
                        2'd3: acc3 <= acc3 + scaledProduct;
                        default: begin
                        end
                    endcase

                    // Advance through 4 columns per row, then next row.
                    if (col == 2'd3) begin
                        col <= 2'd0;

                        if (row == 2'd3) begin
                            state <= ACTIVATE;
                        end else begin
                            row <= row + 1'b1;
                        end
                    end else begin
                        col <= col + 1'b1;
                    end
                end

                ACTIVATE: begin
                    // Add bias and apply ReLU
                    // These use acc0..acc3 after all MAC operations are done
                    y0 <= relu(biased0);
                    y1 <= relu(biased1);
                    y2 <= relu(biased2);
                    y3 <= relu(biased3);

                    state <= FINISH;
                end

                FINISH: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
    