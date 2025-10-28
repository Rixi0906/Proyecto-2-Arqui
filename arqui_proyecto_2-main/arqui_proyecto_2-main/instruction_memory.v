
module instruction_memory(
  input  [7:0] address,
  output [14:0] out
);
  reg [14:0] mem [0:255];

`ifndef SYNTHESIS

  initial begin
    $readmemb("im.dat", mem);
  end
`endif

  assign out = mem[address];
endmodule

