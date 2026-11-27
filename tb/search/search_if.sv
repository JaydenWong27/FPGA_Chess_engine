interface search_if (input logic clk);
    logic rst_n;
    logic start;
    logic [527:0] pos;
    logic done;
    logic [5:0] depth;
    logic [15:0] best_move;
    logic signed [15:0] best_score;
    logic [31:0] nodes;
    logic [31:0] cycles;
endinterface
