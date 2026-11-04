module pawn
    import chess_pkg::*;
(
    input square_t sq, // pawn's square
    input logic color, // 0 = white, 1 = black
    input bitboard_t occ, // every piece on board (WHITE | BLACK)
    input bitboard_t enemy, // Opp pieces
    input logic ep_valid, // state word
    input logic square_t, // from state word

    output bitboard_t push, // square it can move forward ( single + double)
    output bitboard_t cap, // suqare it can capture on (include en passant)
    output bitboard_t att // square it can attack diagonally
);

    logic [63:0] pos;
    pos = 64'd1 << sq;
    empty = ~occ;

    // for white
    logic w_push_valid = (pos << 8) & empty;
    logic w_double_push_valid = ((single & RANK_3) << 8 ) & empty;

    assign push = push_valid | double_push_valid;

    assign att = (pos << 7) & (~FILE_H) | (pos << 9) & (~FILE_A);
    
    // pawn can capture diag onto enemy piece or en passant square
    logic ep_bb = ep_valid ? (64'd1 << ep_sq) : 64'd0;
    cap = att & (enemy | ep_bb)

    // for black
    logic 





endmodule