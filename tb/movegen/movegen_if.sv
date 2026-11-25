interface movegen_if (input logic clk);
    logic rst_n;
    logic start;
    logic [527:0] pos;
    logic move_valid;
    logic [15:0] move;
    logic done;
endinterface
