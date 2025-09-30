// alu.v
module ALU (
    input  [7:0] A,      // Operando A
    input  [7:0] B,      // Operando B
    input  [6:0] opcode, // Código de operación 
    output reg [7:0] R,  // Resultado
    output reg Z,        // Zero flag
    output reg N,        // Negative flag
    output reg C,        // Carry flag
    output reg V         // Overflow flag
);

    always @(*) begin
        // Valores por defecto
        R = 8'b0;
        Z = 0;
        N = 0;
        C = 0;
        V = 0;

        case(opcode)
            // MOV
            7'b0000000: R = B;    // MOV A,B
            7'b0000001: R = A;    // MOV B,A

            // ADD
            7'b0000100: {C,R} = A + B; // ADD A,B
            7'b0000101: {C,R} = B + A; // ADD B,A

            // SUB
            7'b0001000: {C,R} = A - B; // SUB A,B
            7'b0001001: {C,R} = B - A; // SUB B,A

            // AND
            7'b0001100: R = A & B; // AND A,B
            7'b0001101: R = B & A; // AND B,A

            // OR
            7'b0010000: R = A | B;
            7'b0010001: R = B | A;

            // NOT
            7'b0010100: R = ~A;   // NOT A
            7'b0010111: R = ~B;   // NOT B

            // XOR
            7'b0011000: R = A ^ B;
            7'b0011001: R = B ^ A;

            // SHL
            7'b0011100: R = A << 1; // shift left A
            7'b0011111: R = B << 1; // shift left B

            // SHR
            7'b0100000: R = A >> 1;
            7'b0100011: R = B >> 1;

            // INC
            7'b0100100: R = B + 1;

            default: R = 8'b0;
        endcase

        
        Z = (R == 0);
        N = R[7];
    end

endmodule