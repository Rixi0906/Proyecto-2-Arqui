module computer(
  input        clk,
  output [7:0] alu_out_bus  // <-- expuesto para el testbench
);
  // --- Programa / instrucción ---
  wire [7:0]  pc_out_bus;
  pc #(.WIDTH(8)) PC(.clk(clk), .pc(pc_out_bus));  // PC cuenta 0..255
  wire [14:0] im_out_bus;               // [14:8]=opcode (7) + [7:0]=lit (8)
  wire [6:0]  opcode = im_out_bus[14:8];
  wire [7:0]  lit    = im_out_bus[7:0];

  // --- Datos (8 bits) ---
  wire [7:0]  regA_out_bus, regB_out_bus;
  wire [7:0]  muxB_out_bus, muxA_out_bus;
  wire Z, N, C, V;

  // --- Control con TU convención ---
  reg  A, B;      // A=1 ⇒ usar Lit hacia A ; B=1 ⇒ usar Lit hacia B
  reg  LA, LB;    // LA=1 ⇒ cargar A ; LB=1 ⇒ cargar B
  reg  SA;        // SA=0 ⇒ A<=muxB (MOV) ; SA=1 ⇒ A<=ALU (ops)

  // Literal hacia la ALU si A o B lo requieren
  wire use_lit = A | B;

  // --- PC e IM ---
pc pc_inst(.clk(clk), .pc(pc_out_bus));
  instruction_memory IM(.address(pc_out_bus), .out(im_out_bus));

  // --- Decoder (corrigido) ---
  always @(*) begin
    // defaults
    A = 1'b0; B = 1'b0;   // no usar Lit salvo que la instrucción lo pida
    LA = 1'b0; LB = 1'b0; // no cargar registros salvo que la instrucción lo pida
    SA = 1'b0;            // por defecto, MOV (A<=muxB) si es que se carga A

    case (opcode)
      // ===== MOV =====
      7'b0000000: begin // MOV A,B
        LA = 1'b1;      // cargar A
        SA = 1'b0;      // A <= muxB (que será B porque use_lit=0)
        // A=0, B=0
      end
      7'b0000010: begin // MOV A,Lit
        LA = 1'b1;      // cargar A
        SA = 1'b0;      // A <= muxB
        A  = 1'b1;      // usar Lit hacia A -> use_lit=1
      end
      7'b0000001: begin // MOV B,A
        LB = 1'b1;      // cargar B desde ALU
        // ALU debe hacer R=A para este opcode
        // A=0, B=0
      end
      7'b0000011: begin // MOV B,Lit
        LB = 1'b1;      // cargar B desde ALU
        B  = 1'b1;      // usar Lit hacia B -> use_lit=1
        // ALU debe hacer R=B; con use_lit=1, B de ALU es Lit
      end

      // ===== ADD =====
      7'b0000100: begin // ADD A,B   -> A = A + B
        LA = 1'b1; SA = 1'b1;  // A <= ALU
        // A=0, B=0
      end
      7'b0000110: begin // ADD A,Lit -> A = A + Lit
        LA = 1'b1; SA = 1'b1;  // A <= ALU
        A  = 1'b1;             // usar Lit hacia A
      end
      7'b0000101: begin // ADD B,A   -> B = B + A
        LB = 1'b1;             // B <= ALU
        // A=0, B=0
      end
      7'b0000111: begin // ADD B,Lit -> B = B + Lit
        LB = 1'b1;             // B <= ALU
        B  = 1'b1;             // usar Lit hacia B
      end

      // ===== SUB =====
      7'b0001000: begin // SUB A,B
        LA = 1'b1; SA = 1'b1;
      end
      7'b0001010: begin // SUB A,Lit
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0001001: begin // SUB B,A
        LB = 1'b1;
      end
      7'b0001011: begin // SUB B,Lit
        LB = 1'b1; B = 1'b1;
      end

      // ===== AND =====
      7'b0001100: begin // AND A,B
        LA = 1'b1; SA = 1'b1;
      end
      7'b0001110: begin // AND A,Lit
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0001101: begin // AND B,A
        LB = 1'b1;
      end
      7'b0001111: begin // AND B,Lit
        LB = 1'b1; B = 1'b1;
      end

      // ===== OR =====
      7'b0010000: begin // OR A,B
        LA = 1'b1; SA = 1'b1;
      end
      7'b0010010: begin // OR A,Lit
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0010001: begin // OR B,A
        LB = 1'b1;
      end
      7'b0010011: begin // OR B,Lit
        LB = 1'b1; B = 1'b1;
      end

      // ===== XOR =====
      7'b0011000: begin // XOR A,B
        LA = 1'b1; SA = 1'b1;
      end
      7'b0011010: begin // XOR A,Lit
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0011001: begin // XOR B,A
        LB = 1'b1;
      end
      7'b0011011: begin // XOR B,Lit
        LB = 1'b1; B = 1'b1;
      end

      // ===== NOT =====
      7'b0010100: begin // NOT A
        LA = 1'b1; SA = 1'b1;
      end
      7'b0010111: begin // NOT B
        LB = 1'b1;
      end

      // ===== SHL / SHR =====
      7'b0011100: begin // SHL A
        LA = 1'b1; SA = 1'b1;
      end
      7'b0011111: begin // SHL B
        LB = 1'b1;
      end
      7'b0100000: begin // SHR A
        LA = 1'b1; SA = 1'b1;
      end
      7'b0100011: begin // SHR B
        LB = 1'b1;
      end

      // ===== INC ===== (usa lit=1 en la instrucción)
      7'b0100100: begin // INC B = B + 1
        LB = 1'b1; B = 1'b1; // B usa Lit→1; ALU hace ADD
      end

      default: ;
    endcase
  end

  // --- muxB: RegB vs Lit (use_lit = A|B) ---
  mux2 muxB(.e0(regB_out_bus), .e1(lit), .c(use_lit), .out(muxB_out_bus));

  // --- muxA: A <= muxB (MOV) o A <= ALU (ops) ---
  mux2 muxA(.e0(muxB_out_bus), .e1(alu_out_bus), .c(SA), .out(muxA_out_bus));

  // --- Registros ---
  register regA(.clk(clk), .data(muxA_out_bus), .load(LA), .out(regA_out_bus));
  register regB(.clk(clk), .data(alu_out_bus),   .load(LB), .out(regB_out_bus)); // B siempre desde ALU

  // --- ALU ---
  ALU alu(
    .A(regA_out_bus),
    .B(muxB_out_bus),   // aquí llega RegB o Lit según use_lit
    .opcode(opcode),    // o traduce a alu_op si prefieres
    .R(alu_out_bus),
    .Z(Z), .N(N), .C(C), .V(V)
  );
endmodule
