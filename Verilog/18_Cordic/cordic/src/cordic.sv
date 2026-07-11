// Coordinate Rotation Digital Computer
// Computes trigonometric functions using:
// adds, subtracts, shifts, lookup constants
// Hardware-friendly alternative to using multipliers or floating-point math

module cordic (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic inputValid,
    input logic signed [15:0] angle,

    output logic outputValid,
    output logic signed [15:0] sinOut,
    output logic signed [15:0] cosOut
);

    localparam int ITERATIONS = 12;

    // CORDIC gain compensation.
    // Repeated CORDIC rotations increase vector length by about 1.646.
    // To compensate, start x at 1 / 1.646 = 0.607252935.
    // Q2.14: 0.607252935 * 16384 = 9949
    localparam logic signed [17:0] CORDIC_K = 18'sd9949;
    
    // atan(2^-i) constants in degrees * 256.
    // atan(1) = 45.000 degrees -> 11520
    // atan(1/2) = 26.565 degrees -> 6801
    // atan(1/4) = 14.036 degrees -> 3593
    // "automatic": Each call gets its own local storage, safer/default style
    function automatic logic signed [15:0] atanTable(input int index);
        begin
            case (index)
                0: atanTable = 16'sd11520;
                1: atanTable = 16'sd6801;
                2: atanTable = 16'sd3593;
                3: atanTable = 16'sd1824;
                4: atanTable = 16'sd916;
                5: atanTable = 16'sd458;
                6: atanTable = 16'sd229;
                7: atanTable = 16'sd115;
                8: atanTable = 16'sd57;
                9: atanTable = 16'sd29;
                10: atanTable = 16'sd14;
                11: atanTable = 16'sd7;
                default: atanTable = 16'sd0;
            endcase
        end
    endfunction
    
    typedef enum logic [1:0] {
        IDLE,
        ROTATE,
        DONE
    } cordicState;
    cordicState state;

    logic [3:0] iteration;

    // Internal x/y are 18-bit to give extra headroom during rotation.
    // Final outputs are converted back to 16-bit Q2.14.
    logic signed [17:0] xReg;
    logic signed [17:0] yReg;

    // zReg holds the remaining angle error.
    // The algorithm rotates until zReg is close to zero.
    logic signed [15:0] zReg;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state <= IDLE;
            iteration <= 4'd0;

            xReg <= 18'sd0;
            yReg <= 18'sd0;
            zReg <= 16'sd0;

            outputValid <= 1'b0;
            sinOut <= 16'sd0;
            cosOut <= 16'sd0;
        end else begin
            outputValid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (inputValid) begin
                        // Start vector: x = CORDIC_K, y = 0
                        // After rotation: x ≈ cos(angle), y ≈ sin(angle)
                        xReg <= CORDIC_K;
                        yReg <= 18'sd0;
                        zReg <= angle;

                        iteration <= 4'd0;
                        state <= ROTATE;
                    end
                end

                ROTATE: begin
                    // If remaining angle is positive, rotate counterclockwise.
                    // If remaining angle is negative, rotate clockwise.
                    // Shift by iteration implements multiply by 2^-iteration.
                    // x_next = x -/+ (y >>> i)
                    // y_next = y +/- (x >>> i)
                    // z_next = z -/+ atan(2^-i)
                    
                    // For a positive rotation, x uses -y, while y uses +x
                    // x_next = x*cos(theta) - y*sin(theta)
                    // y_next = y*cos(theta) + x*sin(theta)
                    if (zReg >= 16'sd0) begin
                        xReg <= xReg - (yReg >>> iteration); // Shift instead of multiply, shifting is cheaper hardware
                        yReg <= yReg + (xReg >>> iteration);
                        zReg <= zReg - atanTable(iteration);
                    end else begin
                        xReg <= xReg + (yReg >>> iteration);
                        yReg <= yReg - (xReg >>> iteration);
                        zReg <= zReg + atanTable(iteration);
                    end

                    if (iteration == ITERATIONS - 1) begin
                        state <= DONE;
                    end else begin
                        iteration <= iteration + 1'b1;
                    end
                end

                DONE: begin
                    // Icarus-safe narrowing cast.
                    // cosOut <= xReg[15:0];
                    // sinOut <= yReg[15:0];
                    cosOut <= 16'(xReg);
                    sinOut <= 16'(yReg);

                    outputValid <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule