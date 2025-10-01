// pc.v — Program Counter simple
module pc #(parameter WIDTH = 8) (
  input                  clk,
  output reg [WIDTH-1:0] pc
);
  initial pc = {WIDTH{1'b0}};
  always @(posedge clk) begin
    pc <= pc + 1'b1;      // con WIDTH=4 cuenta 0..15 y se desborda a 0
  end
endmodule