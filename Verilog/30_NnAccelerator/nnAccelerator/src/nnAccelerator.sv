// Register-controlled neural-network dense-layer accelerator

module nnAccelerator (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic writeEnable,
    input logic [7:0] writeAddress,
    input logic [31:0] writeData,

    input logic readEnable,
    input logic [7:0] readAddress,
    output logic [31:0] readData
);

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_STATUS  = 8'h04;

    localparam logic [7:0] ADDR_X0 = 8'h10;
    localparam logic [7:0] ADDR_X1 = 8'h14;
    localparam logic [7:0] ADDR_X2 = 8'h18;
    localparam logic [7:0] ADDR_X3 = 8'h1C;

    localparam logic [7:0] ADDR_W00 = 8'h20;
    localparam logic [7:0] ADDR_W01 = 8'h24;
    localparam logic [7:0] ADDR_W02 = 8'h28;
    localparam logic [7:0] ADDR_W03 = 8'h2C;

    localparam logic [7:0] ADDR_W10 = 8'h30;
    localparam logic [7:0] ADDR_W11 = 8'h34;
    localparam logic [7:0] ADDR_W12 = 8'h38;
    localparam logic [7:0] ADDR_W13 = 8'h3C;

    localparam logic [7:0] ADDR_W20 = 8'h40;
    localparam logic [7:0] ADDR_W21 = 8'h44;
    localparam logic [7:0] ADDR_W22 = 8'h48;
    localparam logic [7:0] ADDR_W23 = 8'h4C;

    localparam logic [7:0] ADDR_W30 = 8'h50;
    localparam logic [7:0] ADDR_W31 = 8'h54;
    localparam logic [7:0] ADDR_W32 = 8'h58;
    localparam logic [7:0] ADDR_W33 = 8'h5C;

    localparam logic [7:0] ADDR_B0 = 8'h60;
    localparam logic [7:0] ADDR_B1 = 8'h64;
    localparam logic [7:0] ADDR_B2 = 8'h68;
    localparam logic [7:0] ADDR_B3 = 8'h6C;

    localparam logic [7:0] ADDR_Y0 = 8'h70;
    localparam logic [7:0] ADDR_Y1 = 8'h74;
    localparam logic [7:0] ADDR_Y2 = 8'h78;
    localparam logic [7:0] ADDR_Y3 = 8'h7C;

    typedef enum logic [1:0] {
        IDLE,
        MAC,
        ACTIVATE,
        FINISH
    } state_t;

    state_t state;

    logic [31:0] controlReg;
    logic [31:0] statusReg;

    logic signed [7:0] x0;
    logic signed [7:0] x1;
    logic signed [7:0] x2;
    logic signed [7:0] x3;

    logic signed [7:0] w00;
    logic signed [7:0] w01;
    logic signed [7:0] w02;
    logic signed [7:0] w03;

    logic signed [7:0] w10;
    logic signed [7:0] w11;
    logic signed [7:0] w12;
    logic signed [7:0] w13;

    logic signed [7:0] w20;
    logic signed [7:0] w21;
    logic signed [7:0] w22;
    logic signed [7:0] w23;

    logic signed [7:0] w30;
    logic signed [7:0] w31;
    logic signed [7:0] w32;
    logic signed [7:0] w33;

    logic signed [15:0] b0;
    logic signed [15:0] b1;
    logic signed [15:0] b2;
    logic signed [15:0] b3;

    logic signed [15:0] y0;
    logic signed [15:0] y1;
    logic signed [15:0] y2;
    logic signed [15:0] y3;

    logic [1:0] row;
    logic [1:0] col;

    logic signed [7:0] currentInput;
    logic signed [7:0] currentWeight;

    logic signed [15:0] rawProduct;
    logic signed [31:0] scaledProduct;

    logic signed [31:0] acc0;
    logic signed [31:0] acc1;
    logic signed [31:0] acc2;
    logic signed [31:0] acc3;

    logic startPulse;
    assign startPulse = writeEnable && (writeAddress == ADDR_CONTROL) && writeData[0];

    assign rawProduct = currentInput * currentWeight;
    assign scaledProduct = rawProduct >>> 4;

    always_comb begin
        case (col)
            2'd0: currentInput = x0;
            2'd1: currentInput = x1;
            2'd2: currentInput = x2;
            2'd3: currentInput = x3;
            default: currentInput = 8'sd0;
        endcase
    end

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

    function automatic logic signed [15:0] saturate16(input logic signed [31:0] value);
        begin
            if (value > 32'sd32767) begin
                saturate16 = 16'sh7FFF;
            end else if (value < -32'sd32768) begin
                saturate16 = 16'sh8000;
            end else begin
                saturate16 = 16'(value);
            end
        end
    endfunction

    function automatic logic signed [15:0] reluSaturate16(input logic signed [31:0] value);
        begin
            if (value < 32'sd0) begin
                reluSaturate16 = 16'sd0;
            end else begin
                reluSaturate16 = saturate16(value);
            end
        end
    endfunction

    function automatic logic [31:0] signExtend16To32(input logic signed [15:0] value);
        begin
            signExtend16To32 = {{16{value[15]}}, value};
        end
    endfunction

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state <= IDLE;

            controlReg <= 32'd0;
            statusReg <= 32'd0;

            x0 <= 8'sd0;
            x1 <= 8'sd0;
            x2 <= 8'sd0;
            x3 <= 8'sd0;

            w00 <= 8'sd0;
            w01 <= 8'sd0;
            w02 <= 8'sd0;
            w03 <= 8'sd0;

            w10 <= 8'sd0;
            w11 <= 8'sd0;
            w12 <= 8'sd0;
            w13 <= 8'sd0;

            w20 <= 8'sd0;
            w21 <= 8'sd0;
            w22 <= 8'sd0;
            w23 <= 8'sd0;

            w30 <= 8'sd0;
            w31 <= 8'sd0;
            w32 <= 8'sd0;
            w33 <= 8'sd0;

            b0 <= 16'sd0;
            b1 <= 16'sd0;
            b2 <= 16'sd0;
            b3 <= 16'sd0;

            y0 <= 16'sd0;
            y1 <= 16'sd0;
            y2 <= 16'sd0;
            y3 <= 16'sd0;

            row <= 2'd0;
            col <= 2'd0;

            acc0 <= 32'sd0;
            acc1 <= 32'sd0;
            acc2 <= 32'sd0;
            acc3 <= 32'sd0;
        end else begin
            if (writeEnable) begin
                case (writeAddress)
                    ADDR_CONTROL: controlReg <= writeData;

                    ADDR_X0: x0 <= writeData[7:0];
                    ADDR_X1: x1 <= writeData[7:0];
                    ADDR_X2: x2 <= writeData[7:0];
                    ADDR_X3: x3 <= writeData[7:0];

                    ADDR_W00: w00 <= writeData[7:0];
                    ADDR_W01: w01 <= writeData[7:0];
                    ADDR_W02: w02 <= writeData[7:0];
                    ADDR_W03: w03 <= writeData[7:0];

                    ADDR_W10: w10 <= writeData[7:0];
                    ADDR_W11: w11 <= writeData[7:0];
                    ADDR_W12: w12 <= writeData[7:0];
                    ADDR_W13: w13 <= writeData[7:0];

                    ADDR_W20: w20 <= writeData[7:0];
                    ADDR_W21: w21 <= writeData[7:0];
                    ADDR_W22: w22 <= writeData[7:0];
                    ADDR_W23: w23 <= writeData[7:0];

                    ADDR_W30: w30 <= writeData[7:0];
                    ADDR_W31: w31 <= writeData[7:0];
                    ADDR_W32: w32 <= writeData[7:0];
                    ADDR_W33: w33 <= writeData[7:0];

                    ADDR_B0: b0 <= writeData[15:0];
                    ADDR_B1: b1 <= writeData[15:0];
                    ADDR_B2: b2 <= writeData[15:0];
                    ADDR_B3: b3 <= writeData[15:0];

                    default: begin
                    end
                endcase
            end

            case (state)
                IDLE: begin
                    statusReg[1] <= 1'b0;  // busy
                    controlReg[0] <= 1'b0; // auto-clear start bit

                    if (startPulse) begin
                        statusReg[0] <= 1'b0; // done
                        statusReg[1] <= 1'b1; // busy

                        acc0 <= {{16{b0[15]}}, b0};
                        acc1 <= {{16{b1[15]}}, b1};
                        acc2 <= {{16{b2[15]}}, b2};
                        acc3 <= {{16{b3[15]}}, b3};

                        row <= 2'd0;
                        col <= 2'd0;

                        state <= MAC;
                    end
                end

                MAC: begin
                    case (row)
                        2'd0: acc0 <= acc0 + scaledProduct;
                        2'd1: acc1 <= acc1 + scaledProduct;
                        2'd2: acc2 <= acc2 + scaledProduct;
                        2'd3: acc3 <= acc3 + scaledProduct;
                        default: begin
                        end
                    endcase

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
                    y0 <= reluSaturate16(acc0);
                    y1 <= reluSaturate16(acc1);
                    y2 <= reluSaturate16(acc2);
                    y3 <= reluSaturate16(acc3);

                    state <= FINISH;
                end

                FINISH: begin
                    statusReg[0] <= 1'b1; // done
                    statusReg[1] <= 1'b0; // busy

                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    statusReg <= 32'd0;
                end
            endcase
        end
    end

    always_comb begin
        if (readEnable) begin
            case (readAddress)
                ADDR_CONTROL: readData = controlReg;
                ADDR_STATUS: readData = statusReg;

                ADDR_X0: readData = {{24{x0[7]}}, x0};
                ADDR_X1: readData = {{24{x1[7]}}, x1};
                ADDR_X2: readData = {{24{x2[7]}}, x2};
                ADDR_X3: readData = {{24{x3[7]}}, x3};

                ADDR_W00: readData = {{24{w00[7]}}, w00};
                ADDR_W01: readData = {{24{w01[7]}}, w01};
                ADDR_W02: readData = {{24{w02[7]}}, w02};
                ADDR_W03: readData = {{24{w03[7]}}, w03};

                ADDR_W10: readData = {{24{w10[7]}}, w10};
                ADDR_W11: readData = {{24{w11[7]}}, w11};
                ADDR_W12: readData = {{24{w12[7]}}, w12};
                ADDR_W13: readData = {{24{w13[7]}}, w13};

                ADDR_W20: readData = {{24{w20[7]}}, w20};
                ADDR_W21: readData = {{24{w21[7]}}, w21};
                ADDR_W22: readData = {{24{w22[7]}}, w22};
                ADDR_W23: readData = {{24{w23[7]}}, w23};

                ADDR_W30: readData = {{24{w30[7]}}, w30};
                ADDR_W31: readData = {{24{w31[7]}}, w31};
                ADDR_W32: readData = {{24{w32[7]}}, w32};
                ADDR_W33: readData = {{24{w33[7]}}, w33};

                ADDR_B0: readData = signExtend16To32(b0);
                ADDR_B1: readData = signExtend16To32(b1);
                ADDR_B2: readData = signExtend16To32(b2);
                ADDR_B3: readData = signExtend16To32(b3);

                ADDR_Y0: readData = signExtend16To32(y0);
                ADDR_Y1: readData = signExtend16To32(y1);
                ADDR_Y2: readData = signExtend16To32(y2);
                ADDR_Y3: readData = signExtend16To32(y3);

                default: readData = 32'd0;
            endcase
        end else begin
            readData = 32'd0;
        end
    end

endmodule