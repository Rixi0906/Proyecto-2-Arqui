
module computer(
  input        clk,
  output [7:0] alu_out_bus
);

  // ===== Señales básicas =====
  wire [7:0]  pc_out_bus;
  wire [14:0] im_out_bus;

  wire [6:0]  opcode = im_out_bus[14:8];
  wire [7:0]  lit    = im_out_bus[7:0];

  // ===== Registros generales =====
  wire [7:0]  regA_out_bus, regB_out_bus;

  // ===== Instruction memory & PC =====
  reg  [7:0] next_pc;

  pc #(8) PC0(
    .clk     (clk),
    .next_pc (next_pc),
    .pc      (pc_out_bus)
  );

  instruction_memory IM(
    .address (pc_out_bus),
    .out     (im_out_bus)
  );

  // ===== Reg A y B =====
  reg        loadA, loadB;
  reg  [7:0] path_to_A, path_to_B;

  register regA(
    .clk  (clk),
    .data (path_to_A),
    .load (loadA),
    .out  (regA_out_bus)
  );

  register regB(
    .clk  (clk),
    .data (path_to_B),
    .load (loadB),
    .out  (regB_out_bus)
  );

  // ===== Data memory =====
  reg        dmem_we;
  reg  [7:0] dmem_addr;        // MUX: lit (directo) o regB (indirecto)
  wire [7:0] dmem_dout;

  // Fuente de datos para escribir en memoria:
  // 00 -> A, 01 -> B, 10 -> ALU, 11 -> 0
  reg  [1:0] dmem_src_sel;
  wire [7:0] dmem_din =
    (dmem_src_sel==2'b00) ? regA_out_bus :
    (dmem_src_sel==2'b01) ? regB_out_bus :
    (dmem_src_sel==2'b10) ? alu_out_bus  :
                            8'h00;

  data_memory DM(
    .clk (clk),
    .we  (dmem_we),
    .addr(dmem_addr),
    .din (dmem_din),
    .dout(dmem_dout)
  );

  // ===== ALU =====
  // A_input selector: 0->regA, 1->regB
  reg        selA_is_B;
  // B_input selector:
  // 00->regB, 01->regA, 10->lit, 11->DM[dmem_addr]
  reg  [1:0] selB_src;

  wire [7:0] aluA_in = selA_is_B ? regB_out_bus : regA_out_bus;
  wire [7:0] aluB_in = (selB_src==2'd0) ? regB_out_bus :
                       (selB_src==2'd1) ? regA_out_bus :
                       (selB_src==2'd2) ? lit          :
                                          dmem_dout;

  wire [7:0] alu_R;
  wire       Zr, Nr, Cr, Vr;

  ALU alu0(
    .A      (aluA_in),
    .B      (aluB_in),
    .opcode (opcode),
    .R      (alu_R),
    .Z      (Zr),
    .N      (Nr),
    .C      (Cr),
    .V      (Vr)
  );

  assign alu_out_bus = alu_R; // para debug/TB

  // ===== OPCODES (ajusta si tu pauta usa otros códigos) =====
  localparam [6:0]
    OP_MOV_A_L      = 7'b0000010,
    OP_MOV_B_L      = 7'b0000011,

    OP_MOV_A_DIR    = 7'b0100101,  // A <- DM[lit]
    OP_MOV_B_DIR    = 7'b0100110,  // B <- DM[lit]
    OP_MOV_DIR_A    = 7'b0100111,  // DM[lit] <- A
    OP_MOV_DIR_B    = 7'b0101000,  // DM[lit] <- B
    OP_MOV_BPTR_A   = 7'b0101011,  // DM[B]   <- A

    OP_ADD_A_DIR    = 7'b0101100,  // A <- A + DM[lit]
    OP_SUB_DIR      = 7'b0110011,  // DM[lit] <- A - B

    OP_AND_A_PTRB   = 7'b0110110,  // A <- A & DM[B]
    OP_OR_B_DIR     = 7'b0111001,  // B <- B | DM[lit]
    OP_XOR_A_DIR    = 7'b0111111,  // A <- A ^ DM[lit]
    OP_NOT_PTRB     = 7'b0111110,  // DM[B] <- ~A

    OP_SHL_DIR_B    = 7'b1000100,  // DM[lit] <- B << 1
    OP_SHR_PTRB     = 7'b1001000,  // DM[B]   <- A >> 1

    OP_INC_DIR      = 7'b1001001,  // DM[lit] <- DM[lit] + 1
    OP_RST_PTRB     = 7'b1001100,  // DM[B]   <- 0

    OP_CMP_A_PTRB   = 7'b1010010,  // flags por (A - DM[B])
    OP_CMP_B_ZERO   = 7'b1001111,  // flags por (B - 0)
 
    OP_JMP          = 7'b1010000,  // PC <- lit
    OP_JMP_2        = 7'b1010011,  // PC <- lit  (segunda variante usada en im.dat)

    OP_JLE          = 7'b1011001,  // if Z || (N!=V)
    OP_JGEZ_B       = 7'b1011000,  // if B>=0 (usando CMP_B_ZERO)

    OP_SUB_B_1      = 7'b0001011;  // B <- B - 1

  // ===== Control =====
  reg take_jump;

  always @* begin
    // Defaults seguros
    next_pc       = pc_out_bus + 8'd1;
    take_jump     = 1'b0;

    selA_is_B     = 1'b0;
    selB_src      = 2'd0;

    loadA         = 1'b0;
    loadB         = 1'b0;

    path_to_A     = alu_R;
    path_to_B     = alu_R;

    dmem_we       = 1'b0;
    dmem_addr     = lit;       // por defecto direccion directa
    dmem_src_sel  = 2'b00;     // por defecto A (si se escribe)

    case (opcode)
      // ---------------- MOV inmediatos ----------------
      OP_MOV_A_L: begin path_to_A = lit; loadA = 1'b1; end
      OP_MOV_B_L: begin path_to_B = lit; loadB = 1'b1; end

      // ------------- MOV con memoria (directo) -------------
      OP_MOV_A_DIR: begin dmem_addr = lit; path_to_A = dmem_dout; loadA = 1'b1; end
      OP_MOV_B_DIR: begin dmem_addr = lit; path_to_B = dmem_dout; loadB = 1'b1; end
      OP_MOV_DIR_A: begin dmem_addr = lit; dmem_we = 1'b1; dmem_src_sel = 2'b00; end // A -> DM
      OP_MOV_DIR_B: begin dmem_addr = lit; dmem_we = 1'b1; dmem_src_sel = 2'b01; end // B -> DM
      OP_MOV_BPTR_A:begin dmem_addr = regB_out_bus; dmem_we = 1'b1; dmem_src_sel = 2'b00; end

      // ------------- Aritmética / Lógicas -------------
      // A <- A + DM[lit]
      OP_ADD_A_DIR: begin
        dmem_addr = lit;
        selA_is_B = 1'b0;          // A_input = A
        selB_src  = 2'd3;          // B_input = DM[lit]
        loadA     = 1'b1;          // escribe A con alu_R
      end

      // DM[lit] <- A - B
      OP_SUB_DIR: begin
        selA_is_B = 1'b0;          // A_input = A
        selB_src  = 2'd0;          // B_input = B
        dmem_addr = lit;
        dmem_we   = 1'b1;
        dmem_src_sel = 2'b10;      // ALU -> DM
      end

      // A <- A & DM[B]
      OP_AND_A_PTRB: begin
        dmem_addr = regB_out_bus;  // direccion indirecta
        selA_is_B = 1'b0;          // A_input = A
        selB_src  = 2'd3;          // B_input = DM[B]
        loadA     = 1'b1;
      end

      // B <- B | DM[lit]
      OP_OR_B_DIR: begin
        dmem_addr = lit;
        selA_is_B = 1'b1;          // A_input = B
        selB_src  = 2'd3;          // B_input = DM[lit]
        loadB     = 1'b1;
      end

      // A <- A ^ DM[lit]
      OP_XOR_A_DIR: begin
        dmem_addr = lit;
        selA_is_B = 1'b0;          // A_input = A
        selB_src  = 2'd3;          // B_input = DM[lit]
        loadA     = 1'b1;
      end

      // DM[B] <- ~A
      OP_NOT_PTRB: begin
        selA_is_B = 1'b0;          // A_input = A (ALU hará ~A)
        dmem_addr = regB_out_bus;
        dmem_we   = 1'b1;
        dmem_src_sel = 2'b10;      // ALU -> DM (no A crudo)
      end

      // DM[lit] <- B << 1
      OP_SHL_DIR_B: begin
        selA_is_B = 1'b1;          // A_input = B (ALU shiftea A_input)
        dmem_addr = lit;
        dmem_we   = 1'b1;
        dmem_src_sel = 2'b10;      // ALU -> DM
      end

      // DM[B] <- A >> 1
      OP_SHR_PTRB: begin
        selA_is_B = 1'b0;          // A_input = A
        dmem_addr = regB_out_bus;
        dmem_we   = 1'b1;
        dmem_src_sel = 2'b10;      // ALU -> DM
      end

      // DM[lit] <- DM[lit] + 1
      OP_INC_DIR: begin
        dmem_addr = lit;           // leer celda
        // Para que ALU incremente ese dato:
        // A_input puede ser B o A; usamos B_input = DM, y ALU implementa +1
        // Si tu ALU implementa INC usando B como operando, basta con:
        selA_is_B = 1'b1;          // A_input = B (cómodo según tu ALU)
        selB_src  = 2'd3;          // B_input = DM[lit]
        dmem_we   = 1'b1;
        dmem_src_sel = 2'b10;      // escribir alu_R
      end

      // DM[B] <- 0
      OP_RST_PTRB: begin
        dmem_addr = regB_out_bus;
        dmem_we   = 1'b1;
        dmem_src_sel = 2'b11;      // constante 0
      end

      // --------- Comparaciones y saltos ---------
      // flags <- (A - DM[B])
      OP_CMP_A_PTRB: begin
        dmem_addr = regB_out_bus;
        selA_is_B = 1'b0;          // A_input = A
        selB_src  = 2'd3;          // B_input = DM[B]
        // sin writes (solo flags)
      end

      // flags <- (B - 0)
      OP_CMP_B_ZERO: begin
        selA_is_B = 1'b1;          // A_input = B
        selB_src  = 2'd2;          // B_input = lit (0 si instrucción codifica 0)
      end


      OP_JMP,
      OP_JMP_2: begin
        take_jump = 1'b1;
      end


      // JLE: Z || (N != V)
      OP_JLE: begin
        take_jump = (Zr || (Nr != Vr));
      end

      // “JGEZ B”: tras CMP_B_ZERO, B>=0 equivale a N==0
      OP_JGEZ_B: begin
        take_jump = (Nr == 1'b0);
      end

      // B <- B - 1
      OP_SUB_B_1: begin
        selA_is_B = 1'b1;          // A_input = B
        selB_src  = 2'd2;          // B_input = lit (=1 en tu ALU para dec)
        loadB     = 1'b1;
      end

      default: ; // NOP
    endcase

    if (take_jump) next_pc = lit;
  end

endmodule
