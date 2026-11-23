.PHONY: compile elab run clean

SRCS = ../../rtl/common/chess_pkg.sv ../../rtl/top/uart.sv tb_uart.sv

compile:
	xvlog -sv $(SRCS)

elab: compile
	xelab -timescale 1ns/1ps tb_uart -s tb_uart

run: elab
	xsim tb_uart -R -log uart.log

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb
