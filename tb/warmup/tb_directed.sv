`timescale 1ns/1ps

module tb;

    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    logic [3:0] castle_in;
    logic [3:0] castle_out;
    logic [5:0] from_sq;
    logic [5:0] to_sq;

    // dis the DUT
    castle_update dut (
        .castle_in (castle_in), 
        .castle_out (castle_out),
        .from_sq (from_sq), 
        .to_sq (to_sq)
    );

    // You can do a task if  you want lots of tests basically

    task automatic check (
        input logic [3:0] c_in,
        input logic [5:0] f_sq,
        input logic [5:0] t_sq,
        input logic [3:0] exp_out
    );
    castle_in = c_in;
    from_sq = f_sq;
    to_sq = t_sq;
    #1;
    if (castle_out !== exp_out)
        $error("FAIL: in %b from %0d to %0d: got %b, exp %b", c_in, f_sq, t_sq, castle_out, exp_out);
    else
        $display("PASS: in %b from %0d to %0d: %b", c_in, f_sq, t_sq, castle_out);

    endtask

    logic [3:0] expected;

    // Stimulus
    initial begin

        // Test 1

        #5;
        castle_in = 4'b1111;
        from_sq = 6'd12;
        to_sq = 6'd28;
        
        expected = 4'b1111;
        #1;
        if (castle_out !== expected)
            $error("FAIL: got %b, expected %b", castle_out, expected);
        else
            $display("PASS: %b", castle_out);

        // Test 2

        #5;
        castle_in = 4'b1111;
        from_sq = 6'd0;
        to_sq = 6'd8;

        expected = 4'b1101;

        #1;
        if (castle_out !== expected)
            $error("FAIL: got %b, expected %b", castle_out, expected);
        else
            $display("PASS: %b", castle_out);

        // Test 3
        #5;
        castle_in = 4'b0101;
        from_sq = 6'd7;
        to_sq = 6'd6;

        expected = 4'b0100;
        #1;
        if (castle_out !== expected)
            $error("FAIL: got %b, expected %b", castle_out, expected);
        else
            $display("PASS: %b", castle_out);

        // Test 4
        #5;
        castle_in = 4'b0000;
        from_sq = 6'd4;
        to_sq = 6'd6;

        expected = 4'b0000;
        #1;
        if (castle_out !== expected)
            $error("FAIL: got %b, expected %b", castle_out, expected);
        else
            $display("PASS: %b", castle_out);

        check(4'b1111, 4, 6, 4'b1100);
        check(4'b1111, 60, 52, 4'b0011);
        check(4'b1111, 7, 63, 4'b1010);
        check(4'b1111, 56, 0, 4'b0101 );
        $finish;


    end

endmodule