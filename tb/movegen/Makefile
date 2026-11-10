.PHONY: compile elab run regress clean 


TEST ?= slider_test
SEED ?= 1
SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/move/slider_hq.sv slider_if.sv slider_tb_pkg.sv tb_slider.sv

MG_SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/move/slider_hq.sv ../../rtl/move/leaper.sv ../../rtl/move/pawn.sv ../../rtl/move/legality.sv ../../rtl/move/make_move.sv ../../rtl/move/movegen_top.sv movegen_if.sv movegen_tb_pkg.sv tb_movegen.sv

compile:
	xvlog -sv -L uvm $(SRCS)

elab: compile
	xelab -L uvm -timescale 1ns/1ps tb -s tb_slider

run: elab
	xsim tb_slider -R -sv_seed $(SEED) -testplusarg UVM_TESTNAME=$(TEST) -log $(TEST)_$(SEED).log

regress: elab
	for s in 1 2 3 4 5 6 7 8 9 10; do $(MAKE) run TEST=slider_test SEED=$$s ; done 

compile_movegen:
	xvlog -sv -L uvm $(MG_SRCS)

elab_movegen: compile_movegen
	xelab -L uvm -timescale 1ns/1ps tb_movegen -s tb_movegen

run_movegen: elab_movegen
	xsim tb_movegen -R -sv_seed $(SEED) -testplusarg UVM_TESTNAME=movegen_test -log movegen_$(SEED).log

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb
