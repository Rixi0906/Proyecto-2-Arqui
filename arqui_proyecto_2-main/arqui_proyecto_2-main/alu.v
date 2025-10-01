// alu.v
module ALU (
    input  [7:0] A,       // operando A 
    input  [7:0] B,       // operando B 
    input  [6:0] opcode,  
    output reg [7:0] R,   // resultado
    output reg Z,         // Zero
    output reg N,         // Negative 
    output reg C,         // Carry
    output reg V          // Overflow 
);

  wire [8:0] SUM  = {1'b0, A} + {1'b0, B};
  wire [8:0] DIFF = {1'b0, A} - {1'b0, B};

  always @* begin
    R = 8'h00;
    C = 1'b0;
    V = 1'b0;

    case (opcode)

      //MOV
      7'b0000001, 7'b0001101, 7'b0010001, 7'b0011001, 7'b0010110, 7'b0011110, 7'b0100010: begin       
        R = A;
        C = 1'b0; V = 1'b0;
      end

      7'b0000011, 7'b0000000, 7'b0000010: begin         
        R = B;
        C = 1'b0; V = 1'b0;
      end

      // ADD
      7'b0000100, 7'b0000101, 7'b0000110, 7'b0000111: begin         
        R = SUM[7:0];
        C = SUM[8];
        V = (~(A[7]^B[7])) & (A[7]^R[7]);   
      end

      // SUB
      7'b0001000, 7'b0001001, 7'b0001010, 7'b0001011: begin       
        R = DIFF[7:0];
        C = DIFF[8];                         
        V = (A[7]^B[7]) & (A[7]^R[7]);      
      end

      // AND
      7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: begin
        R = A & B;
        C = 1'b0; V = 1'b0;
      end

      //OR
      7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011: begin  
        R = A | B;
        C = 1'b0; V = 1'b0;
      end

      // XOR
      7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011: begin    
        R = A ^ B;
        C = 1'b0; V = 1'b0;
      end

      // NOT
      7'b0010100, 7'b0010110: begin
        R = ~A;
        C = 1'b0; V = 1'b0;
      end
      7'b0010111, 7'b0010101: begin    
        R = ~B;
        C = 1'b0; V = 1'b0;
      end

      // SHL 
      7'b0011100,              
      7'b0011110: begin        
        R = A << 1;
        C = A[7];
        V = 1'b0;
      end
      7'b0011111,              
      7'b0011101: begin        
        R = B << 1;
        C = B[7];
        V = 1'b0;
      end

      // SHR 
      7'b0100000,              
      7'b0100010: begin         
        R = A >> 1;
        C = A[0];
        V = 1'b0;
      end
      7'b0100011,            
      7'b0100001: begin       
        R = B >> 1;
        C = B[0];
        V = 1'b0;
      end

      //INC
      7'b0100100: begin         
        {C, R} = {1'b0, B} + 9'd1;   
        V = (~B[7]) & R[7];         
      end

      //DEFAULT 
      default: begin
        R = 8'h00; C = 1'b0; V = 1'b0;
      end
    endcase

    Z = (R == 8'h00);
    N = R[7];
  end
endmodule
