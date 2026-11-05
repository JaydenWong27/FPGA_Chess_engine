module make_move 
import chess_pkg::*;
(

    input position_t pos,
    input move_t move,
    output position_t new_pos

);

    bitboard_t from_bb;
    bitboard_t to_bb;
    logic us;
    logic [2:0] piece;

    square_t ep_cap_sq;
    bitboard_t ep_cap_bb;
    square_t rook_from, rook_to;
    bitboard_t rook_from_bb, rook_to_bb;

    assign ep_cap_sq = us ? move.to_sq + 6'd8 : move.to_sq - 6'd8;
    assign ep_cap_bb = 64'd1 << ep_cap_sq;

    assign rook_from = (move.flags == FLAG_CASTLE_KING_SIDE) ? move.to_sq + 6'd1 : move.to_sq - 6'd2;
    assign rook_to = (move.flags == FLAG_CASTLE_KING_SIDE) ? move.to_sq - 6'd1 : move.to_sq + 6'd1;
    assign rook_from_bb = 64'd1 << rook_from;
    assign rook_to_bb = 64'd1 << rook_to;

    assign us = pos.state.stm;
    assign to_bb = 64'd1 << move.to_sq;
    assign from_bb = 64'd1 << move.from_sq;

    always_comb begin
        new_pos = pos;
        piece = BB_PAWNS;
        for (int i = BB_PAWNS; i <= BB_KINGS; i++) begin
            if (pos.bb[i] & from_bb)
                piece = i;
        end

        for(int i = BB_PAWNS; i <= BB_BLACK; i++) begin
            new_pos.bb[i] = new_pos.bb[i] & ~to_bb;
        end

        new_pos.bb[piece] = new_pos.bb[piece] & ~from_bb;
        new_pos.bb[BB_WHITE + us] = new_pos.bb[BB_WHITE + us] & ~from_bb;

                if (move.flags[3]) begin
            new_pos.bb[move.flags[1:0] + 1] = new_pos.bb[move.flags[1:0] + 1] | to_bb;
        end else begin
            new_pos.bb[piece] = new_pos.bb[piece] | to_bb;
        end
        new_pos.bb[BB_WHITE + us] = new_pos.bb[BB_WHITE + us] | to_bb;

        if (move.flags == FLAG_EN_PASSANT_CAPTURE) begin
            for (int i = BB_PAWNS; i <= BB_BLACK; i++) begin
                new_pos.bb[i] = new_pos.bb[i] & ~ep_cap_bb;
            end
        end

        if (move.flags == FLAG_CASTLE_KING_SIDE || move.flags == FLAG_CASTLE_QUEEN_SIDE ) begin
            new_pos.bb[BB_ROOKS] = (new_pos.bb[BB_ROOKS] & ~rook_from_bb) | rook_to_bb;
            new_pos.bb[BB_WHITE + us] = (new_pos.bb[BB_WHITE + us] & ~rook_from_bb) | rook_to_bb;
        end

        new_pos.state.stm    = ~us;
        new_pos.state.castle = pos.state.castle & castle_keep(move.from_sq) & castle_keep(move.to_sq);

        if (move.flags == FLAG_DOUBLE_PAWN_PUSH) begin
            new_pos.state.ep_valid = 1'b1;
            new_pos.state.ep_sq    = us ? move.from_sq - 6'd8 : move.from_sq + 6'd8;
        end else begin
            new_pos.state.ep_valid = 1'b0;
            new_pos.state.ep_sq    = '0;
        end

        new_pos.state.reserved = '0;

    end



endmodule