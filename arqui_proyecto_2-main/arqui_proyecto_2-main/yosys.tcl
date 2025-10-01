#EJERCICIO: Rellenar los archivos verilog
yosys read_verilog alu.v register.v pc.v instruction_memory.v mux2.v computer.v

yosys synth -top computer
yosys write_verilog out/netlist.v

yosys stat
yosys tee -q -o "out/computer.rpt" stat


