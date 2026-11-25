module pawn
    import chess_pkg::*;
(
    input square_t sq, // pawn's square
    input logic color, // 0 = white, 1 = black
    input bitboard_t occ, // every piece on board (WHITE | BLACK)
    input bitboard_t enemy, // Opp pieces
    input logic ep_valid, // state word
    input square_t ep_sq, // from state word

    output bitboard_t push, // square it can move forward ( single + double)
    output bitboard_t cap, // suqare it can capture on (include en passant)
    output bitboard_t att // square it can attack diagonally
);

    logic [63:0] empty;
    logic [63:0] pos;

    bitboard_t w_push_valid;
    bitboard_t w_double_push_valid;

    bitboard_t b_push_valid;
    bitboard_t b_double_push_valid;

    bitboard_t ep_bb;

    bitboard_t w_push;
    bitboard_t w_att;
    bitboard_t w_cap;

    bitboard_t b_push;
    bitboard_t b_att;
    bitboard_t b_cap;

    assign pos = 64'd1 << sq;
    assign empty = ~occ;

    // for white
    
    assign w_push_valid = (pos << 8) & empty;
    assign w_double_push_valid = ((w_push_valid & RANK_3) << 8 ) & empty;
    assign w_push = w_push_valid | w_double_push_valid;
    assign w_att = (pos << 7) & (~FILE_H) | (pos << 9) & (~FILE_A);
    
    assign w_cap = w_att & (enemy | ep_bb);

    // for black
    assign b_push_valid = (pos >> 8) & empty;
    assign b_double_push_valid = ((b_push_valid & RANK_6) >> 8) & empty;
    assign b_push = b_push_valid | b_double_push_valid;
    assign b_att = (pos >> 7) & (~FILE_A) | (pos >> 9) & (~FILE_H);

    assign b_cap = b_att & (enemy | ep_bb);

    // pawn can capture diag onto enemy piece or en passant square
    assign ep_bb = ep_valid ? (64'd1 << ep_sq) : 64'd0;

    assign push = color ? b_push : w_push;
    assign cap = color ? b_cap : w_cap;
    assign att = color ? b_att : w_att;




endmodule