// alu.v
module ALU (
    input  [7:0] A,       // operando A (normalmente RegA)
    input  [7:0] B,       // operando B (o Literal si el datapath activa el mux)
    input  [6:0] opcode,  // opcode de 7 bits
    output reg [7:0] R,   // resultado
    output reg Z,         // Zero
    output reg N,         // Negative (bit 7)
    output reg C,         // Carry (en resta = !borrow)
    output reg V          // Overflow en 2's complement
);

  // Sumas/restas anchas para capturar carry/borrow
  wire [8:0] SUM  = {1'b0, A} + {1'b0, B};
  wire [8:0] DIFF = {1'b0, A} - {1'b0, B};

  always @* begin
    // Defaults (NOP)
    R = 8'h00;
    C = 1'b0;
    V = 1'b0;

    case (opcode)

      // ===== MOV / PASS =====
      // Estas dos te permiten hacer MOV usando la ALU cuando el destino es B.
      7'b0000001,               // MOV B,A -> PASS A
      7'b0001101,               // AND B,A (si solo quisieras PASS A, mantén este aquí como alias)
      7'b0010001,               // OR  B,A (alias)
      7'b0011001,               // XOR B,A (alias)
      7'b0010110,               // NOT B,A -> (~A) (se re-define abajo, queda aquí como recordatorio)
      7'b0011110,               // SHL B,A (se re-define abajo)
      7'b0100010: begin         // SHR B,A (se re-define abajo)
        R = A;
        C = 1'b0; V = 1'b0;
      end

      7'b0000011,               // MOV B, Lit -> PASS B (el mux ya pone el literal por B)
      7'b0000000,               // MOV A,B (si SA=0 en tu datapath, la ALU se ignora; lo dejamos benigno)
      7'b0000010: begin         // MOV A, Lit (ídem)
        R = B;
        C = 1'b0; V = 1'b0;
      end

      // ===== ADD =====
      // A + (B|Lit) o B + (A|Lit) según tu decoder
      7'b0000100,               // ADD A,B
      7'b0000101,               // ADD B,A
      7'b0000110,               // ADD A,Lit
      7'b0000111: begin         // ADD B,Lit
        R = SUM[7:0];
        C = SUM[8];
        V = (~(A[7]^B[7])) & (A[7]^R[7]);   // overflow suma 2's comp
      end

      // ===== SUB =====
      7'b0001000,               // SUB A,B
      7'b0001001,               // SUB B,A
      7'b0001010,               // SUB A,Lit
      7'b0001011: begin         // SUB B,Lit
        R = DIFF[7:0];
        C = DIFF[8];                         // en resta: C=1 ⇒ no hubo borrow
        V = (A[7]^B[7]) & (A[7]^R[7]);       // overflow resta 2's comp
      end

      // ===== AND =====
      7'b0001100,               // AND A,B
      7'b0001101,               // AND B,A
      7'b0001110,               // AND A,Lit
      7'b0001111: begin         // AND B,Lit
        R = A & B;
        C = 1'b0; V = 1'b0;
      end

      // ===== OR =====
      7'b0010000,               // OR A,B
      7'b0010001,               // OR B,A
      7'b0010010,               // OR A,Lit
      7'b0010011: begin         // OR B,Lit
        R = A | B;
        C = 1'b0; V = 1'b0;
      end

      // ===== XOR =====
      7'b0011000,               // XOR A,B
      7'b0011001,               // XOR B,A
      7'b0011010,               // XOR A,Lit
      7'b0011011: begin         // XOR B,Lit
        R = A ^ B;
        C = 1'b0; V = 1'b0;
      end

      // ===== NOT =====
      7'b0010100,               // NOT A     -> ~A
      7'b0010110: begin         // NOT B,A   -> ~A (se escribe en B vía decoder)
        R = ~A;
        C = 1'b0; V = 1'b0;
      end
      7'b0010111,               // NOT B     -> ~B
      7'b0010101: begin         // NOT A,B   -> ~B (se escribe en A vía decoder)
        R = ~B;
        C = 1'b0; V = 1'b0;
      end

      // ===== SHL (lógico) =====
      // Carry = bit expulsado MSB. V=0 (puedes cambiar a (src[7]^R[7]) si tu pauta lo pide).
      7'b0011100,               // SHL A
      7'b0011110: begin         // SHL B,A  (desplazar A, destino B)
        R = A << 1;
        C = A[7];
        V = 1'b0;
      end
      7'b0011111,               // SHL B
      7'b0011101: begin         // SHL A,B  (desplazar B, destino A)
        R = B << 1;
        C = B[7];
        V = 1'b0;
      end

      // ===== SHR (lógico) =====
      // Carry = bit expulsado LSB. V=0.
      7'b0100000,               // SHR A
      7'b0100010: begin         // SHR B,A  (desplazar A, destino B)
        R = A >> 1;
        C = A[0];
        V = 1'b0;
      end
      7'b0100011,               // SHR B
      7'b0100001: begin         // SHR A,B  (desplazar B, destino A)
        R = B >> 1;
        C = B[0];
        V = 1'b0;
      end

      // ===== INC =====
      // Si tu decoder hace INC B como "B <- B + 1", llega B por el puerto B o A (según tu datapath).
      7'b0100100: begin         // INC B
        {C, R} = {1'b0, B} + 9'd1;   // incrementa B
        V = (~B[7]) & R[7];          // overflow de +1
      end

      // ===== DEFAULT / NOP =====
      default: begin
        R = 8'h00; C = 1'b0; V = 1'b0;
      end
    endcase

    // Flags comunes post-resultado
    Z = (R == 8'h00);
    N = R[7];
  end
endmodule
