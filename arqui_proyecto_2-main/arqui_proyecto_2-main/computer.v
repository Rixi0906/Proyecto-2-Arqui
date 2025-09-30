module computer(clk, alu_out_bus);
   input clk;
   output [3:0] alu_out_bus;
   // Recominedo pasar todas estas señales para afuera para poder ser vistas en el waveform
   wire [3:0]   pc_out_bus;
   wire [8:0]   im_out_bus;
   wire [3:0]   regA_out_bus;
   wire [3:0]   regB_out_bus;
   wire [3:0]   muxB_out_bus;
   //wire [3:0] alu_out_bus;

   pc PC(.clk(clk),
         .pc(pc_out_bus));
   instruction_memory IM(.address(pc_out_bus),
                         .out(im_out_bus));
   register regA(.clk(clk),
                 .data(alu_out_bus),
                 .load(im_out_bus[6]),
                 .out(regA_out_bus));
   register regB(.clk(clk),
                 .data(alu_out_bus),
                 .load(im_out_bus[7]),
                 .out(regB_out_bus));

   mux2 muxB(.e0(regB_out_bus), 
             .e1(im_out_bus[7:0]), 
             .c(im_out_bus[8]),
             .out(muxB_out_bus));

   alu ALU(.a(regA_out_bus),
           .b(muxB_out_bus),
           .s(im_out_bus[5:4]),
           .out(alu_out_bus));
endmodule
