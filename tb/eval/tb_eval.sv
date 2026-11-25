`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import eval_tb_pkg::*;

module tb_eval;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    eval_if eif (.clk(clk));

    eval_top #(
        .PST_FILE("../../rtl/eval/pst_init.hex")
        ) dut (
        .clk(eif.clk),
        .rst_n(eif.rst_n),
        .start(eif.start),
        .pos(eif.pos),
        .done(eif.done),
        .score(eif.score),
        .mat_score(eif.mat_score),
        .pst_score(eif.pst_score)
    );

    // Stimulus
    initial begin
        //set
        uvm_config_db#(virtual eval_if)::set(null, "*", "vif", eif);
        run_test();

    end

    initial begin
        eif.rst_n = 0;
        repeat (5) @(posedge clk);
        eif.rst_n = 1;
    end
endmodule
