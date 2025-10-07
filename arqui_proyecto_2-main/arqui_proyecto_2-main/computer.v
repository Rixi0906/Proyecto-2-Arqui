module computer(
  input        clk,
  output [7:0] alu_out_bus
);
  // =========================
  //  Señales internas
  // =========================
  wire [7:0]  pc_out_bus;
  wire [14:0] im_out_bus;
  wire [6:0]  opcode;
  wire [7:0]  lit;

  wire [7:0] regA_out_bus, regB_out_bus;

  // ---- ALU inputs seleccionables ----
  reg  selA_is_B;        // 0 -> ALU.A = regA ; 1 -> ALU.A = regB (o fuente de unario)
  reg  [1:0] selB;       // 0 -> ALU.B = regB ; 1 -> regA ; 2 -> lit

  wire [7:0] aluA_in = selA_is_B ? regB_out_bus : regA_out_bus;
  wire [7:0] aluB_in = (selB==2) ? lit : (selB==1 ? regA_out_bus : regB_out_bus);

  // ---- Rutas de carga a A y B ----
  wire [7:0] path_ALU_to_A;
  wire [7:0] path_to_A;
  wire [7:0] path_mov_to_B;
  wire [7:0] path_to_B;

  // Flags (por ahora no usados en control)
  wire Z, N, C, V;

  // Control
  reg  LA, LB;         // load A / load B
  reg  SA;             // 0: A <= (operando B/reg/lit) ; 1: A <= ALU
  reg  SB;             // 0: B <= A ; 1: B <= lit  (para MOV)
  reg  SB_ALU;         // 1: B <= ALU (para ops sobre B)

  // =========================
  //  PC e instrucción
  // =========================
  pc #(.WIDTH(8)) pc_inst(
    .clk(clk),
    .pc(pc_out_bus)
  );

  instruction_memory IM(
    .address(pc_out_bus),
    .out(im_out_bus)
  );

  assign opcode = im_out_bus[14:8];
  assign lit    = im_out_bus[7:0];

  // =========================
  //  Muxes de datos
  // =========================

  // Para A: (SA=0) pasa el otro operando (B o lit) como MOV A,* ; (SA=1) pasa ALU
  assign path_ALU_to_A = alu_out_bus;

  wire [7:0] other_to_A = (selB==2) ? lit : regB_out_bus; // usado en MOV A,*
  assign path_to_A = SA ? path_ALU_to_A : other_to_A;

  // Para B: MOV (A o lit) o resultado de ALU
  assign path_mov_to_B = SB ? lit : regA_out_bus;
  assign path_to_B     = SB_ALU ? alu_out_bus : path_mov_to_B;

  // Registros
  register regA(
    .clk(clk),
    .data(path_to_A),
    .load(LA),
    .out(regA_out_bus)
  );

  register regB(
    .clk(clk),
    .data(path_to_B),
    .load(LB),
    .out(regB_out_bus)
  );

  // =========================
  //  ALU
  // =========================
  ALU alu(
    .A(aluA_in),
    .B(aluB_in),
    .opcode(opcode),
    .R(alu_out_bus),
    .Z(Z), .N(N), .C(C), .V(V)
  );

  // =========================
  //  Unidad de Control
  // =========================
  always @* begin
    // Defaults seguros
    LA = 1'b0; LB = 1'b0;
    SA = 1'b0; SB = 1'b0; SB_ALU = 1'b0;
    selA_is_B = 1'b0; // ALU.A = A
    selB = 2'd0;      // ALU.B = B

    case (opcode)

      // ===== MOV =====
      7'b0000010: begin // MOV A, Lit
        selB = 2'd2;    // (para other_to_A)
        SA = 1'b0;
        LA = 1'b1;
      end
      7'b0000011: begin // MOV B, Lit
        SB = 1'b1;      // B <= lit
        LB = 1'b1;
      end
      7'b0000000: begin // MOV A, B
        selB = 2'd0;    // other_to_A = B
        SA = 1'b0; LA = 1'b1;
      end
      7'b0000001: begin // MOV B, A
        SB = 1'b0;      // B <= A
        LB = 1'b1;
      end

      // ===== ADD =====
      7'b0000100: begin // ADD A, B  -> A=A+B
        selA_is_B = 1'b0; selB = 2'd0; SA=1'b1; LA=1'b1;
      end
      7'b0000101: begin // ADD B, A  -> B=A+B
        selA_is_B = 1'b0; selB = 2'd0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0000110: begin // ADD A, Lit -> A=A+Lit
        selA_is_B = 1'b0; selB = 2'd2; SA=1'b1; LA=1'b1;
      end
      7'b0000111: begin // ADD B, Lit -> B=B+Lit
        selA_is_B = 1'b1; selB = 2'd2; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== SUB =====
      7'b0001000: begin // SUB A, B  -> A=A-B
        selA_is_B = 1'b0; selB = 2'd0; SA=1'b1; LA=1'b1;
      end
      7'b0001001: begin // SUB B, A  -> B=A-B
        selA_is_B = 1'b0; selB = 2'd0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0001010: begin // SUB A, Lit -> A=A-Lit
        selA_is_B = 1'b0; selB = 2'd2; SA=1'b1; LA=1'b1;
      end
      7'b0001011: begin // SUB B, Lit -> B=B-Lit
        selA_is_B = 1'b1; selB = 2'd2; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== AND =====
      7'b0001100: begin // AND A, B
        selA_is_B = 1'b0; selB = 2'd0; SA=1'b1; LA=1'b1;
      end
      7'b0001101: begin // AND B, A
        selA_is_B = 1'b0; selB = 2'd0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0001110: begin // AND A, Lit
        selA_is_B = 1'b0; selB = 2'd2; SA=1'b1; LA=1'b1;
      end
      7'b0001111: begin // AND B, Lit
        selA_is_B = 1'b1; selB = 2'd2; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== OR =====
      7'b0010000: begin // OR A, B
        selA_is_B = 1'b0; selB = 2'd0; SA=1'b1; LA=1'b1;
      end
      7'b0010001: begin // OR B, A
        selA_is_B = 1'b0; selB = 2'd0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0010010: begin // OR A, Lit
        selA_is_B = 1'b0; selB = 2'd2; SA=1'b1; LA=1'b1;
      end
      7'b0010011: begin // OR B, Lit
        selA_is_B = 1'b1; selB = 2'd2; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== NOT (unario: usa ALU.A como fuente) =====
      7'b0010100: begin // NOT A, A
        selA_is_B = 1'b0; SA=1'b1; LA=1'b1;
      end
      7'b0010101: begin // NOT A, B  (fuente=B, destino=A)
        selA_is_B = 1'b1; SA=1'b1; LA=1'b1;
      end
      7'b0010110: begin // NOT B, A  (fuente=A, destino=B)
        selA_is_B = 1'b0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0010111: begin // NOT B, B
        selA_is_B = 1'b1; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== XOR =====
      7'b0011000: begin // XOR A, B
        selA_is_B = 1'b0; selB = 2'd0; SA=1'b1; LA=1'b1;
      end
      7'b0011001: begin // XOR B, A
        selA_is_B = 1'b0; selB = 2'd0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0011010: begin // XOR A, Lit
        selA_is_B = 1'b0; selB = 2'd2; SA=1'b1; LA=1'b1;
      end
      7'b0011011: begin // XOR B, Lit
        selA_is_B = 1'b1; selB = 2'd2; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== SHL (unario, fuente en ALU.A) =====
      7'b0011100: begin // SHL A, A
        selA_is_B = 1'b0; SA=1'b1; LA=1'b1;
      end
      7'b0011101: begin // SHL A, B
        selA_is_B = 1'b1; SA=1'b1; LA=1'b1;
      end
      7'b0011110: begin // SHL B, A
        selA_is_B = 1'b0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0011111: begin // SHL B, B
        selA_is_B = 1'b1; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== SHR (unario) =====
      7'b0100000: begin // SHR A, A
        selA_is_B = 1'b0; SA=1'b1; LA=1'b1;
      end
      7'b0100001: begin // SHR A, B
        selA_is_B = 1'b1; SA=1'b1; LA=1'b1;
      end
      7'b0100010: begin // SHR B, A
        selA_is_B = 1'b0; SB_ALU=1'b1; LB=1'b1;
      end
      7'b0100011: begin // SHR B, B
        selA_is_B = 1'b1; SB_ALU=1'b1; LB=1'b1;
      end

      // ===== INC B =====
      7'b0100100: begin // INC B  -> B = B + 1
        selA_is_B = 1'b1;       // A de la ALU <- regB (A+1 lo hace la ALU)
        SB_ALU=1'b1; LB=1'b1;
      end

      default: ;
    endcase
  end
endmodule
