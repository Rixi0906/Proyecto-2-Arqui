// data_memory.v — 256x8, lectura combinacional, escritura sincrónica
module data_memory #(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 8,
  parameter DEPTH      = 1 << ADDR_WIDTH
)(
  input                       clk,
  input                       we,                     // write enable
  input  [ADDR_WIDTH-1:0]     addr,
  input  [DATA_WIDTH-1:0]     din,
  output [DATA_WIDTH-1:0]     dout
);
  // *** IMPORTANTE: el array debe llamarse 'mem' (lo pide el profe/test) ***
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Lectura combinacional (para poder hacer LOAD en 1 ciclo)
  assign dout = mem[addr];

  // Escritura en flanco (STORE en 1 ciclo)
  always @(posedge clk) if (we) mem[addr] <= din;
endmodule
