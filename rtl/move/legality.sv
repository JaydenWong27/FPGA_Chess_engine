module legality 
    import chess_pkg::*;
(

    input position_t pos,
    input square_t sq, // the king's square
    input logic by, // square to test

    output logic attacked
);

    bitboard_t occ;
    bitboard_t rook_att;
    bitboard_t bishop_att;

    bitboard_t knight_att;
    bitboard_t king_att;

    assign occ = pos.bb[BB_WHITE] | pos.bb[BB_BLACK];

    slider_hq u_slide (
        .sq(sq),
        .occ(occ),
        .rook_att(rook_att),
        .bishop_att(bishop_att)
    );

    leaper u_leaper(
        .sq(sq),
        .knight_att(knight_att),
        .king_att(king_att)
    );

    bitboard_t pawn_att;

    pawn u_pawn (
        .sq(sq),
        .color(~by),
        .occ('0),
        .enemy('0),
        .ep_valid(1'b0),
        .ep_sq('0),

        .push(),
        .cap(),
        .att(pawn_att)
    );

    bitboard_t them;
    assign them = by ? pos.bb[BB_BLACK] : pos.bb[BB_WHITE];

    assign attacked = | ( (rook_att & them & (pos.bb[BB_ROOKS] | pos.bb[BB_QUEENS]))
                      | (bishop_att & them & (pos.bb[BB_BISHOPS] | pos.bb[BB_QUEENS]))
                      | (knight_att & them & (pos.bb[BB_KNIGHTS]))
                      | (king_att & them & (pos.bb[BB_KINGS]))
                      | (pawn_att & them & (pos.bb[BB_PAWNS])));


endmodule