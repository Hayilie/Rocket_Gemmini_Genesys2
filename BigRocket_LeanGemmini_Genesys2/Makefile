# Makefile

VIVADO = vivado -mode batch -source scripts/build.tcl -notrace
TOP = FPGA_Top

.PHONY: all synth impl bit clean synth_timing

# Varsayılan hedef
all: synth impl bit

synth:
	$(VIVADO) -tclargs synth

impl:
	$(VIVADO) -tclargs impl

bit:
	$(VIVADO) -tclargs bitstream


clean:
	@echo "--- Vivado loglari ve gecici dosyalar temizleniyor ---"
	rm -rf *.log *.jou .Xil/
	@echo "--- Temizlik tamamlandi."
	

synth_timing:
	$(VIVADO) -tclargs synth_timing
