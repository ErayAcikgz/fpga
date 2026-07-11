// 4x4 signed Q4.4 matrix-vector multiply
// Q8.8 -> Q4.4 scale
// Outputs are 16-bit signed accumulators so the dot products have more range


module matrixVectorMultiply (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic start,
    
    // Vector
    input logic signed [7:0] x0,
    input logic signed [7:0] x1,
    input logic signed [7:0] x2,
    input logic signed [7:0] x3,

    // Matrix
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

    output logic busy,
    output logic done,

    // Result vector
    output logic signed [15:0] y0,
    output logic signed [15:0] y1,
    output logic signed [15:0] y2,
    output logic signed [15:0] y3
);

    typedef enum logic [1:0] {
        IDLE,
        RUN,
        FINISH
    } state_t;

    state_t state;

    // y0, y1, y2, y3
    logic [1:0] row;

    // Current weight
    logic [1:0] col;

    logic signed [7:0] currentWeight;
    logic signed [7:0] currentInput;

    logic signed [15:0] rawProduct;
    logic signed [15:0] scaledProduct;

    assign rawProduct = currentWeight * currentInput;

    // Arithmetic shift keeps negative products signed
    assign scaledProduct = rawProduct >>> 4;

    // Select current vector element
    always_comb begin
        case (col)
            2'd0: currentInput = x0;
            2'd1: currentInput = x1;
            2'd2: currentInput = x2;
            2'd3: currentInput = x3;
            default: currentInput = 8'sd0;
        endcase
    end

    // Select current matrix weight
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

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state <= IDLE;

            row <= 2'd0;
            col <= 2'd0;

            busy <= 1'b0;
            done <= 1'b0;

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
                        // Clear outputs before a new operation
                        y0 <= 16'sd0;
                        y1 <= 16'sd0;
                        y2 <= 16'sd0;
                        y3 <= 16'sd0;

                        row <= 2'd0;
                        col <= 2'd0;

                        busy <= 1'b1;
                        state <= RUN;
                    end
                end

                RUN: begin
                    busy <= 1'b1;

                    // Accumulate current product into the selected output row
                    case (row)
                        2'd0: y0 <= y0 + scaledProduct;
                        2'd1: y1 <= y1 + scaledProduct;
                        2'd2: y2 <= y2 + scaledProduct;
                        2'd3: y3 <= y3 + scaledProduct;
                        default: begin
                        end
                    endcase

                    // Move to next matrix element
                    if (col == 2'd3) begin
                        col <= 2'd0;

                        if (row == 2'd3) begin
                            state <= FINISH;
                        end else begin
                            row <= row + 1'b1;
                        end
                    end else begin
                        col <= col + 1'b1;
                    end
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