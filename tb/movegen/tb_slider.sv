`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import slider_tb_pkg::*;

module tb;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    slider_if sif (.clk(clk));

    slider_hq dut (
        .sq (sif.sq),
        .occ (sif.occ),
        .rook_att (sif.rook_att),
        .bishop_att (sif.bishop_att)
    );

    // Stimulus
    initial begin
        //set
        uvm_config_db#(virtual slider_if)::set(null, "*", "vif", sif);
        run_test();

    end

endmodule
