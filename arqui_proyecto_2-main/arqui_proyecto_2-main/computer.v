module computer(
  input        clk,
  output [7:0] alu_out_bus
);

  wire [7:0]  pc_out_bus;
  wire [14:0] im_out_bus;
  wire [6:0]  opcode;
  wire [7:0]  lit;
  wire [7:0] regA_out_bus, regB_out_bus;
 
  reg        selA_is_B;
  reg  [1:0] selB;

  wire [7:0] aluA_in = selA_is_B ? regB_out_bus : regA_out_bus;
  wire [7:0] aluB_in =
      (selB==2'b11) ? dmem_dout :
      (selB==2'b10) ? lit :
      (selB==2'b01) ? regA_out_bus :
                      regB_out_bus;
  wire [7:0] path_ALU_to_A;
  wire [7:0] path_to_A;


  reg  [1:0] selOtherA;
  wire [7:0] other_to_A =
      (selOtherA==2'b10) ? dmem_dout :
      (selOtherA==2'b01) ? lit :
                           regB_out_bus;

  reg  [1:0] selWriteB;

  wire [7:0] path_mov_to_B_old = SB ? lit : regA_out_bus;
  wire [7:0] path_to_B_old     = SB_ALU ? alu_out_bus : path_mov_to_B_old;

  wire [7:0] path_to_B =
      (selWriteB==2'b00) ? path_to_B_old :
      (selWriteB==2'b01) ? regA_out_bus  :
      (selWriteB==2'b10) ? lit           :
                           dmem_dout;

  // Flags
  wire Z, N, C, V;
  reg  Zr, Nr, Cr, Vr;

  reg  LA, LB;         
  reg  SA;             
  reg  SB;             
  reg  SB_ALU;         

  wire [7:0] pc_plus1   = pc_out_bus + 8'd1;
  reg        take_jump;
  wire [7:0] jump_target = lit;   
  wire [7:0] pc_next     = take_jump ? jump_target : pc_plus1;

  pc #(.WIDTH(8)) pc_inst(
    .clk(clk),
    .next_pc(pc_next),
    .pc(pc_out_bus)
  );

  instruction_memory IM(
    .address(pc_out_bus),
    .out(im_out_bus)
  );

  assign opcode = im_out_bus[14:8];
  assign lit    = im_out_bus[7:0];

  reg         dmem_we;   
  wire [7:0]  dmem_addr = lit;     
  wire [7:0]  dmem_din;
  wire [7:0]  dmem_dout;

  reg         dmem_src_is_A;       
  assign dmem_din = dmem_src_is_A ? regA_out_bus : regB_out_bus;

  data_memory DM(
    .clk (clk),
    .we  (dmem_we),
    .addr(dmem_addr),
    .din (dmem_din),
    .dout(dmem_dout)
  );

  assign path_ALU_to_A = alu_out_bus;
  assign path_to_A     = SA ? path_ALU_to_A : other_to_A;

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

  ALU alu(
    .A(aluA_in),
    .B(aluB_in),
    .opcode(opcode),
    .R(alu_out_bus),
    .Z(Z), .N(N), .C(C), .V(V)
  );

  always @(posedge clk) begin
    Zr <= Z; Nr <= N; Cr <= C; Vr <= V;
  end

  localparam [6:0]
    OP_MOV_A_DIR  = 7'b0100101,   
    OP_MOV_B_DIR  = 7'b0100110,   
    OP_MOV_DIR_A  = 7'b0100111,   
    OP_MOV_DIR_B  = 7'b0101000,   
    OP_ADD_A_DIR  = 7'b0101100,   
    OP_ADD_B_DIR  = 7'b0101101,   
    OP_CMP_AB     = 7'b1001101,   
    OP_JMP        = 7'b1010000,   
    OP_JEQ        = 7'b1010100;   


  

  always @* begin
    
    LA=0; LB=0;
    SA=0; SB=0; SB_ALU=0;
    selA_is_B=0; selB=2'b00;
    selOtherA = 2'b00;
    selWriteB = 2'b00;
    dmem_we=0; dmem_src_is_A=0;
    take_jump=0;

    case (opcode)

      // MOV
      7'b0000010: begin // MOV A, Lit
        selOtherA = 2'b01; // lit
        SA = 1'b0; LA = 1'b1;
      end
      7'b0000011: begin // MOV B, Lit
        // esquema legado
        SB = 1'b1; LB = 1'b1;
      end
      7'b0000000: begin // MOV A, B
        selOtherA = 2'b00; // B
        SA = 1'b0; LA = 1'b1;
      end
      7'b0000001: begin // MOV B, A
      
        SB = 1'b0; LB = 1'b1;
      end

      // ADD
      7'b0000100: begin // ADD A, B  -> A=A+B
        selA_is_B = 1'b0; selB = 2'b00; SA=1; LA=1;
      end
      7'b0000101: begin // ADD B, A  -> B=A+B
        selA_is_B = 1'b0; selB = 2'b00; SB_ALU=1; LB=1;
      end
      7'b0000110: begin // ADD A, Lit
        selA_is_B = 1'b0; selB = 2'b10; SA=1; LA=1;
      end
      7'b0000111: begin // ADD B, Lit
        selA_is_B = 1'b1; selB = 2'b10; SB_ALU=1; LB=1;
      end

      // SUB
      7'b0001000: begin // SUB A, B
        selA_is_B = 1'b0; selB = 2'b00; SA=1; LA=1;
      end
      7'b0001001: begin // SUB B, A  (B := A - B)
        selA_is_B = 1'b0; selB = 2'b00; SB_ALU=1; LB=1;
      end
      7'b0001010: begin // SUB A, Lit
        selA_is_B = 1'b0; selB = 2'b10; SA=1; LA=1;
      end
      7'b0001011: begin // SUB B, Lit
        selA_is_B = 1'b1; selB = 2'b10; SB_ALU=1; LB=1;
      end

      // AND
      7'b0001100: begin // AND A, B
        selA_is_B = 1'b0; selB = 2'b00; SA=1; LA=1;
      end
      7'b0001101: begin // AND B, A
        selA_is_B = 1'b0; selB = 2'b00; SB_ALU=1; LB=1;
      end
      7'b0001110: begin // AND A, Lit
        selA_is_B = 1'b0; selB = 2'b10; SA=1; LA=1;
      end
      7'b0001111: begin // AND B, Lit
        selA_is_B = 1'b1; selB = 2'b10; SB_ALU=1; LB=1;
      end

      // OR
      7'b0010000: begin // OR A, B
        selA_is_B = 1'b0; selB = 2'b00; SA=1; LA=1;
      end
      7'b0010001: begin // OR B, A
        selA_is_B = 1'b0; selB = 2'b00; SB_ALU=1; LB=1;
      end
      7'b0010010: begin // OR A, Lit
        selA_is_B = 1'b0; selB = 2'b10; SA=1; LA=1;
      end
      7'b0010011: begin // OR B, Lit
        selA_is_B = 1'b1; selB = 2'b10; SB_ALU=1; LB=1;
      end

      // NOT
      7'b0010100: begin // NOT A, A
        selA_is_B = 1'b0; SA=1; LA=1;
      end
      7'b0010101: begin // NOT A, B
        selA_is_B = 1'b1; SA=1; LA=1;
      end
      7'b0010110: begin // NOT B, A
        selA_is_B = 1'b0; SB_ALU=1; LB=1;
      end
      7'b0010111: begin // NOT B, B
        selA_is_B = 1'b1; SB_ALU=1; LB=1;
      end

      // XOR
      7'b0011000: begin // XOR A, B
        selA_is_B = 1'b0; selB = 2'b00; SA=1; LA=1;
      end
      7'b0011001: begin // XOR B, A
        selA_is_B = 1'b0; selB = 2'b00; SB_ALU=1; LB=1;
      end
      7'b0011010: begin // XOR A, Lit
        selA_is_B = 1'b0; selB = 2'b10; SA=1; LA=1;
      end
      7'b0011011: begin // XOR B, Lit
        selA_is_B = 1'b1; selB = 2'b10; SB_ALU=1; LB=1;
      end

      // SHL
      7'b0011100: begin // SHL A, A
        selA_is_B = 1'b0; SA=1; LA=1;
      end
      7'b0011101: begin // SHL A, B
        selA_is_B = 1'b1; SA=1; LA=1;
      end
      7'b0011110: begin // SHL B, A
        selA_is_B = 1'b0; SB_ALU=1; LB=1;
      end
      7'b0011111: begin // SHL B, B
        selA_is_B = 1'b1; SB_ALU=1; LB=1;
      end

      // SHR
      7'b0100000: begin // SHR A, A
        selA_is_B = 1'b0; SA=1; LA=1;
      end
      7'b0100001: begin // SHR A, B
        selA_is_B = 1'b1; SA=1; LA=1;
      end
      7'b0100010: begin // SHR B, A
        selA_is_B = 1'b0; SB_ALU=1; LB=1;
      end
      7'b0100011: begin // SHR B, B
        selA_is_B = 1'b1; SB_ALU=1; LB=1;
      end

      // INC B
      7'b0100100: begin // INC B
        selA_is_B = 1'b1; SB_ALU=1; LB=1;
      end

      // LOAD / STORE / ADD
      OP_MOV_A_DIR: begin      // MOV A, (dir)
        selOtherA = 2'b10;    
        SA = 1'b0; LA = 1'b1;
      end

      OP_MOV_B_DIR: begin      // MOV B, (dir)
        selWriteB = 2'b11;     
        LB = 1'b1;
      end

      OP_MOV_DIR_A: begin      // MOV (dir), A
        dmem_src_is_A = 1'b1;  
        dmem_we = 1'b1;
      end

      OP_MOV_DIR_B: begin      // MOV (dir), B
        dmem_src_is_A = 1'b0;  
        dmem_we = 1'b1;
      end

      OP_ADD_A_DIR: begin      // A := A + DM[dir]
        selB = 2'b11;        
        selA_is_B = 1'b0; SA=1; LA=1;
      end

      OP_ADD_B_DIR: begin      // B := B + DM[dir] 
        selB = 2'b11;         
        selA_is_B = 1'b1;      // A de ALU = B 
        SB_ALU=1; LB=1;
      end

      //CMP
      OP_CMP_AB: begin         
      end

      OP_JMP: begin
        take_jump = 1'b1;      // pc_next = lit
      end

      OP_JEQ: begin
        take_jump = Zr;
      end

      default: ;
    endcase
  end
endmodule
