module test;
    reg           clk = 0;
    wire [7:0]    regA_out;
    wire [7:0]    regB_out;
    
    reg           mov_test_failed = 1'b0;
    reg           add_test_failed = 1'b0;
    reg           shl_test_failed = 1'b0;

    // ------------------------------------------------------------
    // IMPORTANTE!! Editar con el modulo de su computador
    // ------------------------------------------------------------
    computer Comp(.clk(clk), .alu_out_bus(alu_out_bus));
    // ------------------------------------------------------------

    // ------------------------------------------------------------
    // IMPORTANTE!! Editar para que la variable apunte a la salida
    // de los registros de su computador.
    // ------------------------------------------------------------
    assign regA_out = Comp.regA.out;
    assign regB_out = Comp.regB.out;
    // ------------------------------------------------------------

    initial begin
        $dumpfile("out/dump.vcd");
        $dumpvars(0, test);
        $readmemb("im.dat", Comp.IM.mem);

        // --- Test 0: MOV Literal Instructions ---
        $display("\n----- STARTING TEST 0: MOV A,Lit & MOV B,Lit -----");

        #3;
        $display("CHECK @ t=%0t: After MOV A, 42 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd42) begin
            $error("FAIL: regA expected 42, got %d", regA_out);
            mov_test_failed = 1'b1;
        end

        #2;
        $display("CHECK @ t=%0t: After MOV B, 123 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd123) begin
            $error("FAIL: regB expected 123, got %d", regB_out);
            mov_test_failed = 1'b1;
        end
        
        if (!mov_test_failed) begin
            $display(">>>>> MOV TEST PASSED! <<<<< ");
        end else begin
            $display(">>>>> MOV TEST FAILED! <<<<< ");
        end

        // --- Test 1: ADD Instruction ---
        $display("\n----- STARTING TEST 1: ADD A, B -----");

        #2;
        $display("CHECK @ t=%0t: After MOV A, 2 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd2) begin
            $error("FAIL: regA expected 2, got %d", regA_out);
            add_test_failed = 1'b1;
        end

        #2;
        $display("CHECK @ t=%0t: After MOV B, 3 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd3) begin
            $error("FAIL: regB expected 3, got %d", regB_out);
            add_test_failed = 1'b1;
        end

        #2;
        $display("CHECK @ t=%0t: After ADD A, B -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd5) begin
            $error("FAIL: regA expected 5 (2+3), got %d", regA_out);
            add_test_failed = 1'b1;
        end

        if (!add_test_failed) begin
            $display(">>>>> ADD TEST PASSED! <<<<< ");
        end else begin
            $display(">>>>> ADD TEST FAILED! <<<<< ");
        end

        // --- Test 2: SHL Instruction ---
        $display("\n----- STARTING TEST 2: SHL A, A -----");

        #2;
        $display("CHECK @ t=%0t: After MOV A, 5 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd5) begin
            $error("FAIL: regA expected 5, got %d", regA_out);
            shl_test_failed = 1'b1;
        end

        #2;
        $display("CHECK @ t=%0t: After SHL A, A -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd10) begin
            $error("FAIL: regA expected 10 (5<<1), got %d", regA_out);
            shl_test_failed = 1'b1;
        end

        if (!shl_test_failed) begin
            $display(">>>>> SHL TEST PASSED! <<<<< ");
        end else begin
            $display(">>>>> SHL TEST FAILED! <<<<< ");
        end

        #2;
        $finish;
    end

    // Clock Generator
    always #1 clk = ~clk;

endmodule