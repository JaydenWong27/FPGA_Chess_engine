.PHONY: compile elab run regress clean 


TEST ?= castle_test
SEED ?= 1
SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/move/castle_update.sv castle_if.sv castle_tb_pkg.sv tb_top.sv

compile:
	xvlog -sv -L uvm $(SRCS)

elab: compile
	xelab -L uvm -timescale 1ns/1ps tb -s tb_snap

run: elab
	xsim tb_snap -R -sv_seed $(SEED) -testplusarg UVM_TESTNAME=$(TEST) -log $(TEST)_$(SEED).log

regress: elab
	for s in 1 2 3 4 5 6 7 8 9 10; do $(MAKE) run TEST=castle_full_test SEED=$$s ; done 

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb
