`timescale 1ns/1ps

module tb_tinyCpu;

    logic sys_clk;
    logic sys_rst_n;

    logic halted;
    logic [7:0] programCounter;
    logic [15:0] currentInstruction;

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

    logic [7:0] debugR0;
    logic [7:0] debugR1;
    logic [7:0] debugR2;
    logic [7:0] debugR3;
    logic [7:0] debugR4;
    logic [7:0] debugR5;
    logic [7:0] debugR6;
    logic [7:0] debugR7;
    logic [7:0] debugMem10;

    tinyCpu dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .halted(halted),
        .programCounter(programCounter),
        .currentInstruction(currentInstruction),

        .debugR0(debugR0),
        .debugR1(debugR1),
        .debugR2(debugR2),
        .debugR3(debugR3),
        .debugR4(debugR4),
        .debugR5(debugR5),
        .debugR6(debugR6),
        .debugR7(debugR7),
        .debugMem10(debugMem10)
    );

    initial begin
        sys_clk = 1'b0;
        forever #18.518 sys_clk = ~sys_clk; // 27 MHz clock
    end

    // Encode R-type instructions
    function automatic logic [15:0] encodeR(input logic [3:0] opcode, input logic [2:0] rd, input logic [2:0] rs1, input logic [2:0] rs2);
        begin
            encodeR = {opcode, rd, rs1, rs2, 3'b000};
        end
    endfunction

    // Encode ADDI
    function automatic logic [15:0] encodeAddi(input logic [2:0] rd, input logic [2:0] rs1, input logic signed [5:0] imm6);
        begin
            encodeAddi = {OP_ADDI, rd, rs1, imm6};
        end
    endfunction

    // Encode LOAD
    function automatic logic [15:0] encodeLoad(input logic [2:0] rd, input logic [7:0] addr);
        begin
            encodeLoad = {OP_LOAD, rd, 1'b0, addr};
        end
    endfunction

    // Encode STORE
    function automatic logic [15:0] encodeStore(input logic [2:0] rs1, input logic [7:0] addr);
        begin
            encodeStore = {OP_STORE, 3'b000, rs1, addr[5:0]};
        end
    endfunction

    // This STORE encoding keeps rs1 in bits [8:6].
    //
    // Because the instruction is only 16 bits, this version uses a 6-bit address
    // for STORE. That is enough for this project.
    //
    // LOAD uses an 8-bit address.
    // This asymmetry is not ideal ISA design, but it keeps the decoder simple.

    function automatic logic [15:0] encodeJump(input logic [7:0] addr);
        begin
            encodeJump = {OP_JUMP, 4'b0000, addr};
        end
    endfunction

    function automatic logic [15:0] encodeHalt;
        begin
            encodeHalt = {OP_HALT, 12'd0};
        end
    endfunction

    task checkRegister(input logic [2:0] regIndex, input logic [7:0] expectedValue);
        begin
            if (dut.registerFile[regIndex] !== expectedValue) begin
                $display(
                    "ERROR: r%0d expected %0d / 0x%02h, got %0d / 0x%02h", regIndex, expectedValue, expectedValue, dut.registerFile[regIndex], dut.registerFile[regIndex]);
            end else begin
                $display(
                    "PASS: r%0d = %0d / 0x%02h", regIndex, dut.registerFile[regIndex], dut.registerFile[regIndex]);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/tb_tinyCpu.vcd");
        $dumpvars(0, tb_tinyCpu);

        sys_rst_n = 1'b0;

        // Program:
        // r1 = 5
        // r2 = 7
        // r3 = r1 + r2 = 12
        // mem[0x10] = r3
        // r4 = mem[0x10] = 12
        // r5 = r4 - r1 = 7
        // r6 = r5 & r2 = 7
        // r7 = r6 | r1 = 7
        // halt

        dut.instructionMemory[8'd0] = encodeAddi(3'd1, 3'd0, 6'sd5);
        dut.instructionMemory[8'd1] = encodeAddi(3'd2, 3'd0, 6'sd7);
        dut.instructionMemory[8'd2] = encodeR(OP_ADD, 3'd3, 3'd1, 3'd2);
        dut.instructionMemory[8'd3] = encodeStore(3'd3, 8'h10);
        dut.instructionMemory[8'd4] = encodeLoad(3'd4, 8'h10);
        dut.instructionMemory[8'd5] = encodeR(OP_SUB, 3'd5, 3'd4, 3'd1);
        dut.instructionMemory[8'd6] = encodeR(OP_AND, 3'd6, 3'd5, 3'd2);
        dut.instructionMemory[8'd7] = encodeR(OP_OR, 3'd7, 3'd6, 3'd1);
        dut.instructionMemory[8'd8] = encodeHalt();

        #200;
        sys_rst_n = 1'b1;

        wait (halted == 1'b1);

        @(posedge sys_clk);

        $display("CPU halted.");
        $display("Final PC = %0d", programCounter);

        checkRegister(3'd0, 8'd0);
        checkRegister(3'd1, 8'd5);
        checkRegister(3'd2, 8'd7);
        checkRegister(3'd3, 8'd12);
        checkRegister(3'd4, 8'd12);
        checkRegister(3'd5, 8'd7);
        checkRegister(3'd6, 8'd7);
        checkRegister(3'd7, 8'd7);

        if (dut.dataMemory[8'h10] !== 8'd12) begin
            $display(
                "ERROR: mem[0x10] expected 12 / 0x0C, got %0d / 0x%02h",
                dut.dataMemory[8'h10],
                dut.dataMemory[8'h10]
            );
        end else begin
            $display("PASS: mem[0x10] = 12 / 0x0C");
        end

        repeat (4) @(posedge sys_clk);

        $finish;
    end

endmodule
