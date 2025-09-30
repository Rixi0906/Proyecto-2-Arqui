module register(clk, data, load, out);
   input clk, load;
   input [3:0] data;
   output [3:0] out;

   wire         clk, load;
   wire [3:0]   data;
   reg [3:0]    out;

   initial begin
	   out = 0;
   end

   always @(posedge clk) begin
	   if (load) begin
		   out <= data;
	   end
   end
endmodule
