module movegen_top 
import chess_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic start,
    input position_t pos,

    output logic move_valid,
    output move_t move,
    output logic done
);


    typedef enum logic [2:0] {
        IDLE = 3'b000,
        LOAD_TYPE = 3'b001,
        LOAD_FROM = 3'b010,
        LOAD_TO = 3'b011,
        EMIT = 3'b100,
        DONE = 3'b101
    } mg_state_t;

    mg_state_t state;
    logic [2:0] ptype; // which piece  type we're on 
    bitboard_t from_set;
    square_t from;
    bitboard_t to_set;

    bitboard_t us_bb, them_bb;
    bitboard_t knight_att, king_att, targets;
    bitboard_t occ;
    bitboard_t rook_att, bishop_att;
    bitboard_t pawn_push, pawn_cap, pawn_att;

    square_t to;
    move_t cand;
    position_t after;
    square_t king_sq;
    logic attacked;

    logic d_attacked, e_attacked, f_attacked;
    logic is_pawn_move, is_capture, is_promotion, is_double_push, is_en_passant;
    logic [1:0] promo_cnt;
    logic ok_king_side, ok_queen_side;
    logic is_castle_ks, is_castle_qs;

    square_t base;

    function automatic [5:0] lsb(input logic [63:0] x);
        logic [5:0] position_last_one;
        position_last_one = '0;
        for (int i = 63; i >= 0; i--) begin
            if(x[i] == 1'b1) begin
                position_last_one = i;
            end
        end
        return position_last_one;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        ptype <= BB_PAWNS;
                        state <= LOAD_TYPE;
                    end
                end
                LOAD_TYPE: begin
                    from_set <= pos.bb[ptype] & us_bb;
                    state <= LOAD_FROM;
                end
                LOAD_FROM: begin
                    if (from_set == 0) begin
                        if (ptype == BB_KINGS) begin
                            state <= DONE;
                        end else begin
                            ptype <= ptype + 1;
                            state <= LOAD_TYPE;
                        end
                    end else begin
                        from <= lsb(from_set);
                        from_set <= from_set & (from_set - 1);
                        state <= LOAD_TO;
                    end
                end
                LOAD_TO: begin
                    promo_cnt <= '0;
                    to_set <= targets;
                    state <= EMIT;
                end
                EMIT: begin
                    if (to_set == 0) begin
                        state <= LOAD_FROM;
                    end else begin
                        if(is_promotion && promo_cnt != 3) begin
                            promo_cnt <= promo_cnt + 1;
                        end else begin
                            promo_cnt <= '0;
                            to_set <= to_set & (to_set - 1);
                        end
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // combinational part of the code

    assign us_bb = pos.bb[BB_WHITE + pos.state.stm]; // stm = 0 gives us = WHITE
    assign them_bb = pos.bb[BB_WHITE + !pos.state.stm]; // stm = 1 black 7  = swaps them

    assign occ = us_bb | them_bb; // is occupancy

    assign is_pawn_move = (ptype == BB_PAWNS);
    assign is_capture = them_bb[to]; 
    assign is_promotion = is_pawn_move & (to[5:3] == 3'd7 || to[5:3] == 3'd0); // [5:3] is rank and [2:0] is file
    assign is_double_push = is_pawn_move & (to[5:3] == (from[5:3] + 3'b010) || (from[5:3]) == (to[5:3] + 3'b010));
    assign is_en_passant = is_pawn_move && pos.state.ep_valid && to == pos.state.ep_sq ;
    assign is_castle_ks = (ptype == BB_KINGS) && (to == from + 2); // king jumps 2 files right
    assign is_castle_qs = (ptype == BB_KINGS) && (from == to + 2); // king jumps 2 files left

    slider_hq u_slider (
        .sq(from),
        .occ(occ),
        .rook_att(rook_att),
        .bishop_att(bishop_att)
    );

    pawn u_pawn (
        .sq(from),
        .color(pos.state.stm),
        .occ(occ),
        .enemy(them_bb),
        .ep_valid(pos.state.ep_valid),
        .ep_sq(pos.state.ep_sq),
        .push(pawn_push),
        .cap(pawn_cap),
        .att(pawn_att)
    );

    leaper u_leaper (
        .sq(from),
        .knight_att(knight_att),
        .king_att(king_att)
    );

    always_comb begin
        case (ptype)
            BB_PAWNS: targets = pawn_push | pawn_cap;
            BB_KNIGHTS: targets = knight_att;
            BB_BISHOPS: targets = bishop_att;
            BB_ROOKS: targets = rook_att;
            BB_QUEENS: targets = bishop_att | rook_att;
            BB_KINGS: targets = king_att | (ok_king_side ? 64'd1 << (base + 6) : 64'd0) | (ok_queen_side ? 64'd1 << (base + 2) : 64'd0);
            default: targets = '0;
        endcase
        targets = targets & ~us_bb;
    end

    assign to = lsb(to_set);


    always_comb begin
        cand.from_sq = from;
        cand.to_sq = to;
        if (is_promotion) begin
            cand.flags = {1'b1, is_capture, ~promo_cnt};
        end else if (is_en_passant) begin
            cand.flags = FLAG_EN_PASSANT_CAPTURE;
        end else if (is_double_push) begin
            cand.flags = FLAG_DOUBLE_PAWN_PUSH;
        end else if (is_castle_ks) begin
            cand.flags = FLAG_CASTLE_KING_SIDE;
        end else if (is_castle_qs) begin
            cand.flags = FLAG_CASTLE_QUEEN_SIDE;
        end else if (is_capture) begin
            cand.flags = FLAG_CAPTURE;
        end else begin
            cand.flags = FLAG_QUIET_MOVE;
        end
    end

    make_move u_make (
        .pos(pos),
        .move(cand),
        .new_pos(after)
    );

    assign king_sq = lsb(after.bb[BB_KINGS] & after.bb[BB_WHITE + pos.state.stm]);
    legality u_legal (
        .pos(after), 
        .sq(king_sq), 
        .by(!pos.state.stm),
        .attacked(attacked)
        );

    assign base = pos.state.stm ? 6'd56 : 6'd0;

    legality u_chk_d (
        .pos(pos),
        .sq(base + 3),
        .by(!pos.state.stm),

        .attacked(d_attacked)
    );

    legality u_chk_e (
        .pos(pos),
        .sq(base + 4),
        .by(!pos.state.stm),

        .attacked(e_attacked)
    );

    legality u_chk_f (
        .pos(pos),
        .sq(base + 5),
        .by(!pos.state.stm),

        .attacked(f_attacked)
    );

    assign ok_king_side = (pos.state.stm ? pos.state.castle[2] : pos.state.castle[0]) && !occ[base + 5] && !occ[base + 6] && (!e_attacked && !f_attacked);
    assign ok_queen_side = (pos.state.stm ? pos.state.castle[3] : pos.state.castle[1]) && !occ[base + 1] && !occ[base + 2] && !occ[base + 3] && (!e_attacked && !d_attacked);

    assign move = cand;
    assign move_valid = (state == EMIT) && (to_set != '0) && !attacked;
    assign done = (state == DONE); 



endmodule