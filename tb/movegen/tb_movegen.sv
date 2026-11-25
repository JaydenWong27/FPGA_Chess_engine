`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import movegen_tb_pkg::*;

module tb_movegen;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    movegen_if mif (.clk(clk));

    movegen_top dut (
        .clk(clk),
        .rst_n(mif.rst_n),
        .start(mif.start),
        .pos(mif.pos),

        .move_valid(mif.move_valid),
        .move(mif.move),
        .done(mif.done)
    );

    // Stimulus
    initial begin
        //set
        uvm_config_db#(virtual movegen_if)::set(null, "*", "vif", mif);
        run_test();

    end

    initial begin
        mif.rst_n = 0;
        repeat (5) @(posedge clk);
        mif.rst_n = 1;
    end

endmodule
