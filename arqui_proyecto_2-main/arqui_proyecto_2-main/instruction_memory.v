module instruction_memory(
  input  [7:0]  address,
  output [14:0] out
);
  reg [14:0] mem [0:255];

  initial begin
    $readmemb("im.dat", mem);
  end

  assign out = mem[address];
endmodule
