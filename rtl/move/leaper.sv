module leaper 
    import chess_pkg::*;
(
    input square_t sq,
    output bitboard_t knight_att,
    output bitboard_t king_att
);

    logic [63:0] pos;

    assign pos = 64'd1 << sq;

    assign king_att = (pos << 8) | (pos << 7) & (~FILE_H) | (pos << 9) & (~FILE_A)
        | (pos << 1) & (~FILE_A) | (pos >> 1) & (~FILE_H)  | (pos >> 7) & (~FILE_A)
        | (pos >> 8) | (pos >> 9)  & (~FILE_H);

    assign knight_att = (pos << 6) & (~FILE_G) & (~FILE_H) 
        | (pos << 10) & (~FILE_A) & (~FILE_B) 
        | (pos << 15) & (~FILE_H) | (pos << 17) & (~FILE_A) 
        | (pos >> 6) & (~FILE_A) & (~FILE_B) 
        | (pos >> 10) & (~FILE_G) & (~FILE_H)
        | (pos >> 15) & (~FILE_A) | (pos >> 17) & (~FILE_H);



endmodule