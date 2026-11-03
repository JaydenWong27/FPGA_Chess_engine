`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import castle_tb_pkg::*;

module tb;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    castle_if cif (.clk(clk));

    castle_update dut (
        .castle_in (cif.castle_in),
        .castle_out (cif.castle_out),
        .from_sq (cif.from_sq),
        .to_sq (cif.to_sq)
    );

    // Stimulus
    initial begin
        //set
        uvm_config_db#(virtual castle_if)::set(null, "*", "vif", cif);
        run_test();

    end

endmodule
