.PHONY: compile elab run regress clean


TEST ?= search_test
SEED ?= 1
MAX_DEPTH ?= 3
SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/move/slider_hq.sv ../../rtl/move/leaper.sv ../../rtl/move/pawn.sv ../../rtl/move/legality.sv ../../rtl/move/make_move.sv ../../rtl/move/movegen_top.sv ../../rtl/eval/material.sv ../../rtl/eval/pst.sv ../../rtl/eval/eval_top.sv ../../rtl/search/stack_mem.sv ../../rtl/search/search_fsm.sv ../../rtl/search/search_top.sv search_if.sv search_tb_pkg.sv tb_search.sv

compile:
	xvlog -sv -L uvm $(SRCS)

elab: compile
	xelab -L uvm -timescale 1ns/1ps tb_search -s tb_search

run: elab
	xsim tb_search -R -sv_seed $(SEED) -testplusarg UVM_TESTNAME=$(TEST) -testplusarg MAX_DEPTH=$(MAX_DEPTH) -log $(TEST)_d$(MAX_DEPTH)_$(SEED).log

regress: elab
	for s in 1 2 3 4 5 6 7 8 9 10; do $(MAKE) run TEST=search_test SEED=$$s ; done

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb
