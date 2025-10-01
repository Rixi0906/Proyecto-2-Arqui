// alu.v
module ALU (
    input  [7:0] A,       // Operando A
    input  [7:0] B,       // Operando B (o Lit si use_lit=1 en el datapath)
    input  [6:0] opcode,  // 7-bit opcode
    output reg [7:0] R,   // Resultado
    output reg Z,         // Zero
    output reg N,         // Negative (R[7])
    output reg C,         // Carry
    output reg V          // Overflow (signed)
);

  wire [7:0] add_res = A + B;
  wire [7:0] sub_res = A - B;

  // helpers para overflow de suma/resta en 2's complement
  wire add_v = (A[7] == B[7]) && (add_res[7] != A[7]);
  wire sub_v = (A[7] != B[7]) && (sub_res[7] != A[7]);

  always @(*) begin
    // defaults
    R = 8'b0;
    Z = 1'b0;
    N = 1'b0;
    C = 1'b0;
    V = 1'b0;

    case (opcode)
      // -------- MOV / passthroughs --------
      // MOV B,A  (tu datapath carga B desde ALU)
      7'b0000001: begin
        R = A;              // PASS_A
      end
      // MOV B,Lit (tu datapath pone use_lit=1, así que "B" de la ALU ES el literal)
      7'b0000011: begin
        R = B;              // PASS_B (B es Lit cuando use_lit=1)
      end

      // -------- ADD --------
      // ADD A,B ; ADD B,A ; ADD A,Lit ; ADD B,Lit
      7'b0000100,
      7'b0000101,
      7'b0000110,
      7'b0000111: begin
        {C, R} = A + B;
        V = add_v;
      end

      // -------- SUB --------
      // SUB A,B ; SUB B,A ; SUB A,Lit ; SUB B,Lit
      7'b0001000,
      7'b0001001,
      7'b0001010,
      7'b0001011: begin
        {C, R} = A - B;     // C = ~borrow en Icarus (carry de la resta)
        V = sub_v;
      end

      // -------- AND --------
      7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: begin
        R = A & B;
        C = 1'b0; V = 1'b0;
      end

      // -------- OR --------
      7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011: begin
        R = A | B;
        C = 1'b0; V = 1'b0;
      end

      // -------- XOR --------
      7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011: begin
        R = A ^ B;
        C = 1'b0; V = 1'b0;
      end

      // -------- NOT --------
      // NOT A / NOT B (tu datapath decide el destino; aquí usamos A como fuente)
      7'b0010100, 7'b0010101, 7'b0010110, 7'b0010111: begin
        R = ~A;             // si quieres ~B, ajusta tu tabla de opcodes
        C = 1'b0; V = 1'b0;
      end

      // -------- SHL --------
      7'b0011100, 7'b0011101, 7'b0011110, 7'b0011111: begin
        R = A << 1;
        C = A[7];           // bit expulsado
        V = 1'b0;
      end

      // -------- SHR --------
      7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011: begin
        R = A >> 1;         // lógico; si quieres aritmético usa $signed(A) >>> 1
        C = A[0];           // bit expulsado
        V = 1'b0;
      end

      // -------- INC --------
      // INC B = B + 1 → tu datapath pone B como destino y Lit=1 (opcionalmente podrías tener un opcode exclusivo)
      7'b0100100: begin
        {C, R} = A + 8'd1;  // si tu INC usa A como fuente; si quieres incrementar B, cambia a B+1
        V = (A[7] == 1'b0) && (R[7] == 1'b1); // overflow de +1
      end

      default: begin
        R = 8'b0;
        C = 1'b0; V = 1'b0;
      end
    endcase

    // flags comunes
    Z = (R == 8'b0);
    N = R[7];
  end

endmodule
