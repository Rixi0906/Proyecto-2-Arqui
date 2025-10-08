module data_memory #(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 8,
  parameter DEPTH      = 1 << ADDR_WIDTH
)(
  input                       clk,
  input                       we,                     
  input  [ADDR_WIDTH-1:0]     addr,
  input  [DATA_WIDTH-1:0]     din,
  output [DATA_WIDTH-1:0]     dout
);
  
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Lectura combinacional 
  assign dout = mem[addr];

  // Escritura en flanco 
  always @(posedge clk) if (we) mem[addr] <= din;
endmodule
