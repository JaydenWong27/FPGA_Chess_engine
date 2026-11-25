interface eval_if (input logic clk);
    logic rst_n;
    logic start;
    logic [527:0] pos;
    logic done;
    logic signed [15:0] score;
    logic signed [15:0] mat_score;
    logic signed [15:0] pst_score;
endinterface
