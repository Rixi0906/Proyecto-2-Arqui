module mux2(e0, e1, c, out);
   input [7:0] e0, e1;
   input       c;
   output [7:0] out;
   
   wire [7:0]   e0, e1;
   wire         c;
   reg [7:0]    out;
   
   always @(e0, e1, c) begin
     case(c)
		   'b0: out = e0;
		   'b1: out = e1;
	   endcase
   end
endmodule
