# ==== Fuentes ====
VERILOG_FILES = alu.v mux2.v register.v pc.v instruction_memory.v data_memory.v computer.v

# Usa TB para elegir testbench (por defecto el normal)
TB ?= testbench.v
TESTBENCH_FILE = $(TB)

YOSYS_SCRIPT = yosys.tcl

# ==== Salidas ====
OUT_DIR = out
OUT_FILE = computer
WAVEFORM_FILE = $(OUT_DIR)/dump.vcd

# ==== Targets ====
.PHONY: all build run wave synth clean mem mem-build mem-run

all: build run

$(OUT_DIR):
	@mkdir -p $(OUT_DIR)

build: $(OUT_DIR)
	@echo "Construyendo con $(TESTBENCH_FILE)..."
	iverilog -o $(OUT_DIR)/$(OUT_FILE) $(VERILOG_FILES) $(TESTBENCH_FILE)
	@echo "OK: $(OUT_DIR)/$(OUT_FILE)"

run:
	@echo "Ejecutando simulación..."
	vvp $(OUT_DIR)/$(OUT_FILE)

wave:
	@echo "Abriendo GTKWave..."
	gtkwave $(WAVEFORM_FILE)

synth: $(OUT_DIR)
	@echo "Síntesis con Yosys..."
	yosys -c $(YOSYS_SCRIPT)
	@echo "Síntesis completa."

clean:
	@echo "Limpiando..."
	@rm -rf $(OUT_DIR)
	@rm -f yosys.log
	@echo "Listo."

# ==== Atajos para el test de memoria ====
mem: mem-build mem-run

mem-build: $(OUT_DIR)
	@echo "Construyendo con testbench_memory.v..."
	iverilog -o $(OUT_DIR)/$(OUT_FILE) $(VERILOG_FILES) testbench_memory.v
	@echo "OK: $(OUT_DIR)/$(OUT_FILE)"

mem-run:
	@echo "Ejecutando simulación (memoria)..."
	vvp $(OUT_DIR)/$(OUT_FILE)
