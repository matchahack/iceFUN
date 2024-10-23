PROJ      = controller
DEVICE    = 8k
FILES = controller.v

.PHONY: all clean

all:
	yosys -p "synth_ice40 -top main -json $(PROJ).json" $(FILES)
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf iceFUN.pcf
	icepack $(PROJ).asc $(PROJ).bin
	iceFUNprog $(PROJ).bin

clean:
	rm *.asc *.bin *blif *.out *.json *.history *.vcd .sconsign.dblite