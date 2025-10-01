module instruction_memory(address, out);
   input [7:0] address;
   output [14:0] out;

   wire [7:0]   address;
   wire [14:0]   out;

   reg [14:0]    mem [0:255];

   assign out = mem[address];
endmodule
