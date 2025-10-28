module ALU (
    input  [7:0] A,
    input  [7:0] B,
    input  [6:0] opcode,       // [14:8] de la instrucción
    output reg [7:0] R,
    output reg Z,
    output reg N,
    output reg C,
    output reg V
);
  // ====== OPCODES (según tu im.dat) ======
  localparam [6:0]
    OP_MOV_A_L      = 7'b0000010,  // no usa ALU (lo maneja control)
    OP_MOV_B_L      = 7'b0000011,  // no usa ALU

    // Mem ↔ Reg (el dato lo rutea control, ALU no hace nada)
    OP_MOV_A_DIR    = 7'b0100101,  // A <- DM[dir]
    OP_MOV_B_DIR    = 7'b0100110,  // B <- DM[dir]
    OP_MOV_DIR_A    = 7'b0100111,  // DM[dir] <- A
    OP_MOV_DIR_B    = 7'b0101000,  // DM[dir] <- B
    OP_MOV_BPTR_A   = 7'b0101011,  // DM[B]   <- A

    // Aritmética con memoria
    OP_ADD_A_DIR    = 7'b0101100,  // A <- A + DM[dir]
    OP_SUB_DIR      = 7'b0110011,  // DM[dir] <- A - B

    // Lógicas y shifts con dir/puntero
    OP_AND_A_PTRB   = 7'b0110110,  // A <- A & DM[B]
    OP_OR_B_DIR     = 7'b0111001,  // B <- B | DM[dir]
    OP_XOR_A_DIR    = 7'b0111111,  // A <- A ^ DM[dir]
    OP_NOT_PTRB     = 7'b0111110,  // DM[B] <- ~A   (ALU entrega ~A)

    OP_SHL_DIR_B    = 7'b1000100,  // DM[dir] <- B << 1   (ALU entrega B<<1)
    OP_SHR_PTRB     = 7'b1001000,  // DM[B]   <- A >> 1   (ALU entrega A>>1)

    OP_INC_DIR      = 7'b1001001,  // DM[dir] <- DM[dir] + 1   (ALU entrega D+1)
    OP_RST_PTRB     = 7'b1001100,  // DM[B]   <- 0  (no usa ALU, pero lo listamos)

    // Comparaciones / saltos
    OP_CMP_A_PTRB   = 7'b1010010,  // flags por (A - DM[B])
    OP_CMP_B_ZERO   = 7'b1001111,  // flags por (B - 0)
    OP_JMP          = 7'b1010000,  // PC <- imm (control)
    OP_JLE          = 7'b1011001,  // if (Z||N!=V) (control)
    OP_JGEZ_B       = 7'b1011000,  // if (B>=0) asumiendo V=0 tras CMP_B_ZERO
    OP_SUB_B_1      = 7'b0001011;  // B <- B - 1

  // ====== ALU ======
  reg [8:0] SUM, DIFF;
  reg       write_is_zero;   // para ops de solo flags

  always @* begin
    R = 8'h00; Z = 1'b0; N = 1'b0; C = 1'b0; V = 1'b0;
    SUM = 9'd0; DIFF = 9'd0; write_is_zero = 1'b0;

    case (opcode)
      // ------- Aritmética -------
      OP_ADD_A_DIR: begin
        SUM = {1'b0, A} + {1'b0, B};   // (control pone DM[dir] en B)
        R   = SUM[7:0];
        C   = SUM[8];
        V   = (A[7]==B[7]) && (R[7]!=A[7]);
      end

      OP_SUB_DIR: begin
        DIFF = {1'b0, A} + {1'b0, ~B} + 9'd1; // A - B  (resultado se guarda en DM[dir])
        R    = DIFF[7:0];
        C    = ~DIFF[8];
        V    = (A[7]!=B[7]) && (R[7]!=A[7]);
      end

      OP_SUB_B_1: begin
        DIFF = {1'b0, A} + {1'b0, 8'hFF}; // A = B, control rutea B->A
        R    = DIFF[7:0];
        C    = ~DIFF[8];
        V    = (A==8'h80); // underflow signed
      end

      // ------- Lógicas -------
      OP_AND_A_PTRB: R = A & B;       // B trae DM[B]
      OP_OR_B_DIR:   R = A | B;       // A trae B original, B trae DM[dir]
      OP_XOR_A_DIR:  R = A ^ B;       // B trae DM[dir]
      OP_NOT_PTRB:   R = ~A;          // guardar en DM[B] (control)

      // ------- Shifts / INC -------
      OP_SHL_DIR_B:  R = B << 1;      // guardar en DM[dir]
      OP_SHR_PTRB:   R = A >> 1;      // guardar en DM[B]

      OP_INC_DIR: begin               // R = (DM[dir]) + 1
        SUM = {1'b0, B} + 9'd1;       // B trae DM[dir]
        R   = SUM[7:0];
        C   = SUM[8];
        V   = (B==8'h7F);
      end

      // ------- Comparaciones (solo flags) -------
      OP_CMP_A_PTRB: begin
        DIFF = {1'b0, A} + {1'b0, ~B} + 9'd1; // A - DM[B]
        write_is_zero = 1'b1;
        C = ~DIFF[8];
        V = (A[7]!=B[7]) && (DIFF[7]!=A[7]);
        R = DIFF[7:0]; // para N/Z
      end

      OP_CMP_B_ZERO: begin
        write_is_zero = 1'b1;
        R = A;         // A aquí vendrá con B (control rutea B->A)
        C = 1'b0; V = 1'b0; // comparar con 0: útil para JGEZ
      end

      default: begin
        // MOVs, JMP, RST… se resuelven en control
        R = 8'h00; C = 1'b0; V = 1'b0;
      end
    endcase

    if (write_is_zero) begin
      // No “escribimos” a reg; solo flags:
      // R se usa igual para N/Z a partir del resultado de resta
    end
    Z = (R == 8'h00);
    N = R[7];
  end
endmodule
