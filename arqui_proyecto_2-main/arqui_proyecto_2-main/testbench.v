module test;
   reg cl = 0;
   wire [3:0] alu_out_bus;

   computer Comp(.clk(cl), .alu_out_bus(alu_out_bus));

   initial begin
     $dumpfile("out/dump.vcd");
     $dumpvars(0, test);

     $readmemb("im.dat", Comp.IM.mem);

     $display("mem[0] = %h", Comp.IM.mem[0]);
     $display("mem[1] = %h", Comp.IM.mem[1]);
     $display("mem[2] = %h", Comp.IM.mem[2]);
     $display("mem[3] = %h", Comp.IM.mem[3]);

     $monitor("At time %t, pc = 0x%h, im = b%b, regA = 0x%h, regB = 0x%h, alu=0x%h (b=0x%h)",
              $time, Comp.pc_out_bus, Comp.im_out_bus, Comp.regA_out_bus, Comp.regB_out_bus, alu_out_bus,
              Comp.im_out_bus[3:0]);

     wait (Comp.PC.pc == 3);
     #2;
     $finish;
   end

   always #1 cl = ~cl;
endmodule
