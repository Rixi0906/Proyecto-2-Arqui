module pc
#(parameter WIDTH = 8)
(
  input                  clk,
  input  [WIDTH-1:0]     next_pc,   
  output reg [WIDTH-1:0] pc = {WIDTH{1'b0}}
);
  always @(posedge clk) begin
    pc <= next_pc;        
  end
endmodule
