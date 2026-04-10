# Makefile

VIVADO = vivado -mode batch -source scripts/build.tcl -notrace
TOP = FPGA_Top

.PHONY: all synth impl bit clean synth_timing


all: synth impl bit

synth:
	$(VIVADO) -tclargs synth

impl:
	$(VIVADO) -tclargs impl

bit:
	$(VIVADO) -tclargs bitstream


clean:
	@echo "--- Cleaning Vivado logs and temporary files ---"
	rm -rf *.log *.jou .Xil/
	@echo "--- Cleanup completed."
	

synth_timing:
	$(VIVADO) -tclargs synth_timing
