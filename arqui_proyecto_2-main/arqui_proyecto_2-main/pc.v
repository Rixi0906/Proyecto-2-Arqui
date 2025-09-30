module pc(clk, pc);
   input clk;
   output [3: 0] pc;

   reg [3:0]     pc;
   wire          clk;

   initial begin
	   pc = 0;
   end

   always @(posedge clk) begin
	   pc <= pc + 1;
   end
endmodule
