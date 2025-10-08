module ALU (
    input  [7:0] A,    
    input  [7:0] B,    
    input  [6:0] opcode,
    output reg [7:0] R,
    output reg Z,
    output reg N,
    output reg C,
    output reg V
);

  // ADD con memoria
  localparam [6:0] OP_ADD_A_DIR = 7'b0101100;  
  localparam [6:0] OP_ADD_B_DIR = 7'b0101101;  
  // CMP 
  localparam [6:0] OP_CMP_AB    = 7'b1001101;  // CMP A,B

  wire [8:0] SUM  = {1'b0, A} + {1'b0, B};
  wire [8:0] DIFF = {1'b0, A} - {1'b0, B};

  always @* begin
    R = 8'h00; C = 1'b0; V = 1'b0;

    casez (opcode)
      // ----------------- ADD -----------------
      // Básicos: A,B / B,A / A,lit / B,lit  +  Memorias: A,(dir) / B,(dir)
      7'b0000100, 7'b0000101, 7'b0000110, 7'b0000111,
      OP_ADD_A_DIR, OP_ADD_B_DIR: begin
        {C, R} = SUM;                          // C = carry
        V = (A[7] == B[7]) && (R[7] != A[7]);  
      end

      // Básicos: A,B / B,A / A,lit / B,lit  +  CMP A,B
      7'b0001000, 7'b0001001, 7'b0001010, 7'b0001011,
      OP_CMP_AB: begin
        R = DIFF[7:0];
        C = DIFF[8];                           
        V = (A[7] != B[7]) && (R[7] != A[7]);  
      end

      // ----------------- AND ------------------
      7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: R = A & B;

      // ----------------- OR -------------------
      7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011: R = A | B;

      // ----------------- NOT (unario, usa A) --
      // El decoder decide si A contiene A o B (selA_is_B)
      7'b0010100, 7'b0010101, 7'b0010110, 7'b0010111: R = ~A;

      // ----------------- XOR ------------------
      7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011: R = A ^ B;

      // ----------------- SHL (unario, usa A) --
      7'b0011100, 7'b0011101, 7'b0011110, 7'b0011111: R = A << 1;

      // ----------------- SHR (unario, usa A) --
      7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011: R = A >> 1;

      // ----------------- INC (unario, usa A) --
      // Para INC B, el decoder debe poner A = B (selA_is_B=1)
      7'b0100100: begin
        {C, R} = {1'b0, A} + 9'd1;
        V = (A[7] == 1'b0) && (R[7] == 1'b1); 
      end

      default: begin
        R = 8'h00; C = 1'b0; V = 1'b0;
      end
    endcase

    // Flags comunes
    Z = (R == 8'h00);
    N = R[7];
  end
endmodule
// ----------------- End ALU -----------------
