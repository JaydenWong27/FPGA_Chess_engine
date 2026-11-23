`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import search_tb_pkg::*;

module tb_search;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    search_if eif (.clk(clk));

    search_top #(
        .PST_FILE("../../rtl/eval/pst_init.hex")
        ) dut (
        .clk(eif.clk),
        .rst_n(eif.rst_n),
        .start(eif.start),
        .root_pos(eif.pos),
        .depth(eif.depth),
        .done(eif.done),
        .best_move(eif.best_move),
        .best_score(eif.best_score)
    );

    // Stimulus
    initial begin
        //set
        uvm_config_db#(virtual search_if)::set(null, "*", "vif", eif);
        run_test();

    end

    initial begin
        eif.rst_n = 0;
        repeat (5) @(posedge clk);
        eif.rst_n = 1;
    end
endmodule
