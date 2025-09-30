module instruction_memory(address, out);
   input [3:0] address;
   output [8:0] out;

   wire [3:0]   address;
   wire [8:0]   out;

   reg [8:0]    mem [0:15];

   assign out = mem[address];
endmodule
