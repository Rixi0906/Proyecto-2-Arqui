module computer(
  input        clk,
  output [7:0] alu_out_bus  
);

  wire [7:0]  pc_out_bus;
  pc #(.WIDTH(8)) PC(.clk(clk), .pc(pc_out_bus));  
  wire [14:0] im_out_bus;               
  wire [6:0]  opcode = im_out_bus[14:8];
  wire [7:0]  lit    = im_out_bus[7:0];


  wire [7:0]  regA_out_bus, regB_out_bus;
  wire [7:0]  muxB_out_bus, muxA_out_bus;
  wire Z, N, C, V;


  reg  A, B;     
  reg  LA, LB;    
  reg  SA;     

  wire use_lit = A | B;

pc pc_inst(.clk(clk), .pc(pc_out_bus));
  instruction_memory IM(.address(pc_out_bus), .out(im_out_bus));

  always @(*) begin
    A = 1'b0; B = 1'b0;   
    LA = 1'b0; LB = 1'b0; 
    SA = 1'b0;            

    case (opcode)
      //MOV
      7'b0000000: begin 
        LA = 1'b1;      
        SA = 1'b0;     
      end
      7'b0000010: begin 
        LA = 1'b1;     
        SA = 1'b0;     
        A  = 1'b1;     
      end
      7'b0000001: begin 
        LB = 1'b1;     
      end
      7'b0000011: begin
        LB = 1'b1;      
        B  = 1'b1;    
      end

      // ADD 
      7'b0000100: begin 
        LA = 1'b1; SA = 1'b1;  
      end
      7'b0000110: begin 
        LA = 1'b1; SA = 1'b1;  
        A  = 1'b1;           
      end
      7'b0000101: begin 
        LB = 1'b1;      
      end
      7'b0000111: begin
        LB = 1'b1;           
        B  = 1'b1;            
      end

      // SUB
      7'b0001000: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0001010: begin 
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0001001: begin 
        LB = 1'b1;
      end
      7'b0001011: begin
        LB = 1'b1; B = 1'b1;
      end

      // AND
      7'b0001100: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0001110: begin 
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0001101: begin 
        LB = 1'b1;
      end
      7'b0001111: begin 
        LB = 1'b1; B = 1'b1;
      end

      // OR
      7'b0010000: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0010010: begin 
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0010001: begin 
        LB = 1'b1;
      end
      7'b0010011: begin 
        LB = 1'b1; B = 1'b1;
      end

      // XOR
      7'b0011000: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0011010: begin 
        LA = 1'b1; SA = 1'b1; A = 1'b1;
      end
      7'b0011001: begin 
        LB = 1'b1;
      end
      7'b0011011: begin 
        LB = 1'b1; B = 1'b1;
      end

      // NOT
      7'b0010100: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0010111: begin 
        LB = 1'b1;
      end

      7'b0010101: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0010110: begin 
        LB = 1'b1; SA = 1'b1;
      end

      // SHL
      7'b0011100: begin 
        LA = 1'b1; SA = 1'b1;
      end      
      7'b0011101: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0011110: begin 
        LB = 1'b1; SA = 1'b1;
      end
      7'b0011111: begin 
        LB = 1'b1;
      end

      // SHR
      7'b0100000: begin 
        LA = 1'b1; SA = 1'b1;
      end      
      7'b0100001: begin 
        LA = 1'b1; SA = 1'b1;
      end
      7'b0100010: begin 
        LB = 1'b1; SA = 1'b1;
      end
      7'b0100011: begin 
        LB = 1'b1;
      end
      
      // INC
      7'b0100100: begin 
        LB = 1'b1; B = 1'b1; 
      end

      default: ;
    endcase
  end


  mux2 muxB(.e0(regB_out_bus), .e1(lit), .c(use_lit), .out(muxB_out_bus));
  mux2 muxA(.e0(muxB_out_bus), .e1(alu_out_bus), .c(SA), .out(muxA_out_bus));

  register regA(.clk(clk), .data(muxA_out_bus), .load(LA), .out(regA_out_bus));
  register regB(.clk(clk), .data(alu_out_bus),   .load(LB), .out(regB_out_bus)); 

  ALU alu(
    .A(regA_out_bus),
    .B(muxB_out_bus),   
    .opcode(opcode),    
    .R(alu_out_bus),
    .Z(Z), .N(N), .C(C), .V(V)
  );
endmodule
