// 8-bit CPU

module tinyCpu (
    input logic sys_clk,
    input logic sys_rst_n,

    output logic halted,
    output logic [7:0] programCounter,
    output logic [15:0] currentInstruction,

    output logic [7:0] debugR0,
    output logic [7:0] debugR1,
    output logic [7:0] debugR2,
    output logic [7:0] debugR3,
    output logic [7:0] debugR4,
    output logic [7:0] debugR5,
    output logic [7:0] debugR6,
    output logic [7:0] debugR7,
    output logic [7:0] debugMem10
);

    // Map instructions to opcodes
    localparam logic [3:0] OP_NOP   = 4'h0;
    localparam logic [3:0] OP_ADD   = 4'h1;
    localparam logic [3:0] OP_SUB   = 4'h2;
    localparam logic [3:0] OP_AND   = 4'h3;
    localparam logic [3:0] OP_OR    = 4'h4;
    localparam logic [3:0] OP_ADDI  = 4'h5;
    localparam logic [3:0] OP_LOAD  = 4'h6;
    localparam logic [3:0] OP_STORE = 4'h7;
    localparam logic [3:0] OP_JUMP  = 4'h8;
    localparam logic [3:0] OP_HALT  = 4'hF;

    // Simulated memory
    logic [15:0] instructionMemory [0:255]; // Program storage
    logic [7:0] dataMemory [0:255];         // Load/store memory

    // CPU working registers (r0, r1... r7)
    logic [7:0] registerFile [0:7];         // r0 is forced to zero (RISC-V/MIPS) 
    // A zero register gives the CPU a permanent constant 0, simplifies hardware and instruction encoding

    // Arithmetic Instructions: [15:12] opcode, [11:9] rd, [8:6] rs1, [5:3] rs2, [2:0] unused
    // Immediate Instructions: [15:12] opcode, [11:9] rd, [8:6] rs1, [5:0] immediate
    // e.g. ADDI r1, r0, 5 -> r1 = r0 + 5
    logic [3:0] opcode;
    logic [2:0] rd;     // Destination register
    logic [2:0] rs1;    // Source register 1
    logic [2:0] rs2;    // Source register 2
    logic signed [5:0] immediate6;
    logic signed [7:0] signExtendedImmediate;
    logic [7:0] address8;

    logic [5:0] storeAddress6;
    assign storeAddress6 = currentInstruction[5:0];

    // Fetch
    assign currentInstruction = instructionMemory[programCounter];

    // Decode
    // CPU can't understand ADD r3, r1, r2 -> ADD is opcode, leftmost 3 bits
    // Decoder converts bits into:
    assign opcode = currentInstruction[15:12];
    assign rd = currentInstruction[11:9];
    assign rs1 = currentInstruction[8:6];
    assign rs2 = currentInstruction[5:3];

    // ADDI uses 6-bit signed immediate, but CPU registers are 8 bits
    // 6-bit immediate is extended to 8 bits while preserving the sign
    assign immediate6 = currentInstruction[5:0];                        // Lower 6 bits of currentInstruction
    assign signExtendedImmediate = {{2{immediate6[5]}}, immediate6};    // Repeat immediate6[5] two times
    // 000101 -> immediate6[5] = 0 -> {2{0}} = 00 -> signExtendedImmediate = 00_000101 = 00000101 = +5
    // 111111 -> immediate6[5] = 1 -> {2{1}} = 11 -> signExtendedImmediate = 11_111111 = 11111111 = -1

    assign address8 = currentInstruction[7:0];  // Extracts lower 8 bits of the instruction as an address
    // if 0001_0000 -> 0x10 -> JUMP -> programCounter = address8 -> if address8 = 8'd20 => instructionMemory[20]

    // GTKWave Debug
    assign debugR0 = registerFile[0];
    assign debugR1 = registerFile[1];
    assign debugR2 = registerFile[2];
    assign debugR3 = registerFile[3];
    assign debugR4 = registerFile[4];
    assign debugR5 = registerFile[5];
    assign debugR6 = registerFile[6];
    assign debugR7 = registerFile[7];

    assign debugMem10 = dataMemory[8'h10];

    integer i;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            programCounter <= 8'd0;
            halted <= 1'b0;

            for (i = 0; i < 8; i = i + 1) begin
                registerFile[i] <= 8'd0;
            end

            for (i = 0; i < 256; i = i + 1) begin
                dataMemory[i] <= 8'd0;
            end
        end else begin
            if (!halted) begin
                case (opcode)
                    OP_NOP: begin
                        programCounter <= programCounter + 8'd1;
                    end

                    OP_ADD: begin
                        if (rd != 3'd0) begin
                            registerFile[rd] <= registerFile[rs1] + registerFile[rs2];
                        end

                        programCounter <= programCounter + 8'd1;
                    end

                    OP_SUB: begin
                        if (rd != 3'd0) begin
                            registerFile[rd] <= registerFile[rs1] - registerFile[rs2];
                        end

                        programCounter <= programCounter + 8'd1;
                    end

                    OP_AND: begin
                        if (rd != 3'd0) begin
                            registerFile[rd] <= registerFile[rs1] & registerFile[rs2];
                        end

                        programCounter <= programCounter + 8'd1;
                    end

                    OP_OR: begin
                        if (rd != 3'd0) begin
                            registerFile[rd] <= registerFile[rs1] | registerFile[rs2];
                        end

                        programCounter <= programCounter + 8'd1;
                    end

                    OP_ADDI: begin
                        if (rd != 3'd0) begin
                            registerFile[rd] <= registerFile[rs1] + signExtendedImmediate;
                        end

                        programCounter <= programCounter + 8'd1;
                    end

                    OP_LOAD: begin
                        if (rd != 3'd0) begin
                            registerFile[rd] <= dataMemory[address8];
                        end

                        programCounter <= programCounter + 8'd1;
                    end

                    OP_STORE: begin
                        dataMemory[{2'b00, storeAddress6}] <= registerFile[rs1];

                        programCounter <= programCounter + 8'd1;
                    end

                    // PC = 5, instructionMemory[5] -> JUMP 12 -> After the clock edge -> PC = 12, instructionMemory[12]
                    OP_JUMP: begin
                        programCounter <= address8;
                    end

                    OP_HALT: begin
                        halted <= 1'b1;
                        programCounter <= programCounter;
                    end

                    default: begin
                        halted <= 1'b1;
                    end
                endcase

                // Keep r0 hardwired to zero
                registerFile[0] <= 8'd0;
            end
        end
    end

endmodule
