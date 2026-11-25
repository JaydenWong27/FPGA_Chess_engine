module stack_mem 
import chess_pkg::*;
(
    input logic clk,

    input logic frame_we,
    input logic [5:0] frame_waddr,
    input frame_t frame_wdata,
    input logic [5:0] frame_raddr,
    output frame_t frame_rdata,

    input logic move_we,
    input logic [5:0] move_wply,
    input logic [7:0] move_widx,
    input move_t move_wdata,
    input logic [5:0] move_rply,
    input logic [7:0] move_ridx,
    output move_t move_rdata

);

frame_t frames [0:MAX_PLY-1];

always_ff @(posedge clk) begin
    if (frame_we) begin
        frames[frame_waddr] <= frame_wdata;
    end
    frame_rdata <= frames[frame_raddr];
end

move_t moves [0:(MAX_PLY*MAX_MOVES)-1];

always_ff @(posedge clk) begin
    if (move_we) begin
        moves[{move_wply,move_widx}] <= move_wdata;
    end
    move_rdata <= moves[{move_rply,move_ridx}];
end

endmodule 