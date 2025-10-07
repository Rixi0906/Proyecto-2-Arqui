module ALU (
    input  [7:0] A,    // Operando A de la ALU (fuente elegida por control)
    input  [7:0] B,    // Operando B de la ALU (según instrucción: otro reg o literal)
    input  [6:0] opcode,
    output reg [7:0] R,
    output reg Z,
    output reg N,
    output reg C,
    output reg V
);
  wire [8:0] SUM  = {1'b0, A} + {1'b0, B};
  wire [8:0] DIFF = {1'b0, A} - {1'b0, B};

  always @* begin
    R = 8'h00; C = 1'b0; V = 1'b0;

    casez (opcode)
      // ----------------- ADD -----------------
      7'b0000100, 7'b0000101, 7'b0000110, 7'b0000111: begin
        {C, R} = SUM;
        V = (A[7] == B[7]) && (R[7] != A[7]);
      end

      // ----------------- SUB (A - B) ----------
      7'b0001000, 7'b0001001, 7'b0001010, 7'b0001011: begin
        R = DIFF[7:0];
        // Nota: C como borrow no estándar; si lo necesitas: C = ~DIFF[8];
        V = (A[7] != B[7]) && (R[7] != A[7]);
      end

      // ----------------- AND ------------------
      7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: R = A & B;

      // ----------------- OR -------------------
      7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011: R = A | B;

      // ----------------- NOT (unario, usa A) --
      7'b0010100, 7'b0010101, 7'b0010110, 7'b0010111: R = ~A;

      // ----------------- XOR ------------------
      7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011: R = A ^ B;

      // ----------------- SHL (unario, usa A) --
      7'b0011100, 7'b0011101, 7'b0011110, 7'b0011111: R = A << 1;

      // ----------------- SHR (unario, usa A) --
      7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011: R = A >> 1;

      // ----------------- INC B -----------------
      7'b0100100: begin
        {C, R} = {1'b0, A} + 9'd1; // A debe venir con el contenido de B
        V = (A[7] == 1'b0) && (R[7] == 1'b1); // overflow de 127->128
      end

      default: begin
        R = 8'h00; C = 1'b0; V = 1'b0;
      end
    endcase

    Z = (R == 8'h00);
    N = R[7];
  end
endmodule
// ----------------- End of ALU -----------------