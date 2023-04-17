export PATH:=/opt/quartus13.0sp1/quartus/bin:/cygdrive/c/Hwdev/quartus130sp1/quartus/bin:/opt/modelsim201/modelsim_ase/bin:/cygdrive/c/Hwdev/modelsim181/modelsim_ase/win32aloem:${PATH}

.PHONY: build program report testbench clean

build:
	quartus_sh --no_banner --flow compile scandoubler -c scandoubler

program:
	quartus_pgm --no_banner --mode=jtag -o "BVP;output_files/scandoubler.pof"

report:
	cat output_files/scandoubler.*.smsg output_files/scandoubler.*.rpt |grep -e Error -e Critical -e Warning |grep -v -e "Family doesn't support jitter analysis" -e "Force Fitter to Avoid Periphery Placement Warnings"

testbench: testbench_scandoubler

testbench_scandoubler: V=$@.v scandoubler.v

testbench_%:
	test ! -d work || rm -rf work
	vlib work
	test ! -n "$(filter %.v,${V})" || vlog -quiet -sv $(filter %.v,${V})
	test ! -n "$(filter %.vhd %.vhdl,${V})" || vcom -quiet $(filter %.vhd %.vhdl,${V})
	vsim ${VSIMFLAGS} -batch -quiet -do 'run -all' $@
	test ! -r transcript || rm transcript

clean:
	rm -rf db/ incremental_db/ output_files/ ivl_vhdl_work/ work/ *.bin *.mem *.vcd

-include Makefile.local
