// Simple simulated motor/plant model

module motorModel (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic sampleEnable,
    input logic signed [15:0] command,

    output logic signed [15:0] measuredPosition
);

    logic signed [31:0] position;
    logic signed [31:0] velocity;

    logic signed [31:0] commandExtended;
    logic signed [31:0] damping;
    logic signed [31:0] acceleration;
    logic signed [31:0] nextVelocity;
    logic signed [31:0] nextPosition;

    assign commandExtended = {{16{command[15]}}, command};

    // Damping
    // If velocity is positive, damping is positive and reduces acceleration
    // If velocity is negative, damping is negative and also opposes motion
    assign damping = velocity >>> 3;
    assign acceleration = commandExtended - damping;

    // Divide acceleration by 8 to make the model slower and more stable
    assign nextVelocity = velocity + (acceleration >>> 3);

    // Divide velocity by 16 before adding to position
    // This makes position change gradually sample by sample
    assign nextPosition = position + (nextVelocity >>> 4);

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

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            position <= 32'sd0;
            velocity <= 32'sd0;
            measuredPosition <= 16'sd0;
        end else begin
            if (sampleEnable) begin
                velocity <= nextVelocity;
                position <= nextPosition;
                measuredPosition <= saturate16(nextPosition);
            end
        end
    end

endmodule