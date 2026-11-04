.PHONY: compile elab run regress clean 


TEST ?= slider_test
SEED ?= 1
SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/move/slider_hq.sv slider_if.sv slider_tb_pkg.sv tb_slider.sv

compile:
	xvlog -sv -L uvm $(SRCS)

elab: compile
	xelab -L uvm -timescale 1ns/1ps tb -s tb_slider

run: elab
	xsim tb_slider -R -sv_seed $(SEED) -testplusarg UVM_TESTNAME=$(TEST) -log $(TEST)_$(SEED).log

regress: elab
	for s in 1 2 3 4 5 6 7 8 9 10; do $(MAKE) run TEST=slider_test SEED=$$s ; done 

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb
