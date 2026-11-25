.PHONY: compile elab run regress clean 


TEST ?= eval_test
SEED ?= 1
SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/eval/material.sv ../../rtl/eval/pst.sv ../../rtl/eval/eval_top.sv eval_if.sv eval_tb_pkg.sv tb_eval.sv

compile:
	xvlog -sv -L uvm $(SRCS)

elab: compile
	xelab -L uvm -timescale 1ns/1ps tb_eval -s tb_eval

run: elab
	xsim tb_eval -R -sv_seed $(SEED) -testplusarg UVM_TESTNAME=$(TEST) -log $(TEST)_$(SEED).log

regress: elab
	for s in 1 2 3 4 5 6 7 8 9 10; do $(MAKE) run TEST=eval_test SEED=$$s ; done 

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb
