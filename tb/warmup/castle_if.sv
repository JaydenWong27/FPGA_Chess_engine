interface castle_if (input logic clk);
    logic valid;
    logic [3:0] castle_in, castle_out;
    logic [5:0] from_sq, to_sq;
endinterface