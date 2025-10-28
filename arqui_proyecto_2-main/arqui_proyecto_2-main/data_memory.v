module data_memory(
  input        clk,
  input        we,
  input  [7:0] addr,
  input  [7:0] din,
  output [7:0] dout
);
  reg [7:0] mem [0:255];

`ifndef SYNTHESIS
  // SOLO SIMULACIÓN (si cargas estado inicial, o haces prints)
  initial begin
    // $readmemb("dm.dat", mem);  // si usas
    // $display("DM init...");
  end
`endif

  assign dout = mem[addr];
  always @(posedge clk) if (we) mem[addr] <= din;
endmodule
