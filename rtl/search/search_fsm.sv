module search_fsm 
import chess_pkg::*;
(
    input logic clk,
    input logic rst_n,

// commands
    input logic start,
    input position_t root_pos,
    input logic [5:0] depth,
    output logic done,
    output move_t best_move,
    output score_t best_score,
    output logic [31:0] nodes,
    output logic [31:0] cycles,

// movegen

    output logic mg_start,
    output position_t mg_pos,
    input logic mg_move_valid,
    input move_t mg_move,
    input logic mg_done,

// eval

    output logic ev_start,
    output position_t ev_pos,
    input logic ev_done,
    input score_t ev_score,

// frame stack and move lists

    output logic frame_we,
    output logic [5:0] frame_waddr,
    output frame_t frame_wdata,
    output logic [5:0] frame_raddr,
    input frame_t frame_rdata,

    output logic move_we,
    output logic [5:0] move_wply,
    output logic [7:0] move_widx,
    output move_t move_wdata,
    output logic [5:0] move_rply,
    output logic [7:0] move_ridx,
    input move_t move_rdata
);

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

typedef enum logic [3:0] {
    IDLE,
    NODE,
    QS_STAND,
    GEN,
    NEXT,
    FETCH,
    PUSH,
    RETURN,
    POP_WAIT,
    UPDATE,
    DONE
}  search_state_t;

search_state_t state;

frame_t cur;

logic [5:0] ply;
logic [5:0] root_depth;

score_t result;

position_t child_pos;
square_t king_sq;
logic in_check;

make_move u_make (
    .pos(cur.pos),
    .move(cur.move),
    .new_pos(child_pos)
);


assign king_sq = lsb(cur.pos.bb[BB_KINGS] & cur.pos.bb[BB_WHITE + cur.pos.state.stm]);

legality u_check (
    .pos(cur.pos),
    .sq(king_sq),
    .by(!cur.pos.state.stm),
    .attacked(in_check)
);

logic qs;
logic stand_cut;
logic tactical;
logic [7:0] total;
logic keep;

assign keep = mg_move_valid && (!qs || tactical);
assign stand_cut = (ev_score >= cur.beta) || (ply == MAX_PLY - 1);
assign qs = (ply >= root_depth);
assign tactical = mg_move.flags[2] | mg_move.flags[3];
assign total = cur.ncap + cur.nquiet;
assign mg_pos = cur.pos;
assign ev_pos = cur.pos;

assign mg_start = ((state == NODE) && !qs)
               || ((state == QS_STAND) && ev_done && !stand_cut);
assign ev_start = (state == NODE) && qs;
assign done = state == DONE;
assign move_we = (state == GEN) && keep;
assign move_wply = ply;
assign move_widx = tactical ? cur.ncap : (8'd255 - cur.nquiet);
assign move_wdata = mg_move;
assign move_rply = ply;
assign move_ridx = (cur.idx < cur.ncap) ? cur.idx : (8'd255 - (cur.idx - cur.ncap));
assign frame_we = state == PUSH;
assign frame_waddr = ply;
assign frame_wdata = cur;
assign frame_raddr = ply - 1;

score_t up_score;
score_t new_best;
score_t new_alpha;

logic cutoff;

always_comb begin
    up_score = -result;
    new_best = (up_score > cur.best) ? up_score : cur.best;
    new_alpha = (up_score > cur.alpha) ? up_score : cur.alpha;
    cutoff = (new_alpha >= cur.beta);
end

always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        case (state) 
            IDLE:  begin // waiting for search request, 
                if (start) begin
                    cur.pos <= root_pos;
                    cur.alpha <= -INF; 
                    cur.beta <= INF;
                    cur.best <= -INF;
                    cur.best_move <= '0;
                    cur.move <= '0;
                    cur.ncap <= '0;
                    cur.nquiet <= '0;
                    cur.idx <= '0;
                    ply <= '0;
                    root_depth <= depth;
                    state <= NODE;
                end
            end
            NODE: begin //decide if this is leaf, one clock and assign alreadypulse
                if (qs) begin
                    state <= QS_STAND;
                end else begin
                    state <= GEN;
                end
            end
            QS_STAND: begin
                if (ev_done) begin
                    if (stand_cut) begin
                        result <= ev_score;
                        state <= RETURN;
                    end else begin
                        cur.best <= ev_score;
                        if (ev_score > cur.alpha)
                            cur.alpha <= ev_score;
                        state <= GEN;
                    end
                end
            end
            GEN: begin 
                if (keep) begin
                    if (tactical) cur.ncap   <= cur.ncap + 1;
                    else          cur.nquiet <= cur.nquiet + 1;
                end
                if (mg_done) begin
                    if (total == 0) begin            // no (kept) moves
                        if (qs)
                            result <= cur.best;
                        else
                            result <= in_check ? score_t'(-(MATE - ply)) : score_t'(DRAW);
                        state <= RETURN;
                    end else begin                   // there are moves
                        cur.idx <= '0;
                        state <= NEXT;
                    end
                end
            end
            NEXT: begin
                if (cur.idx == total) begin // every move has been tried
                    result <= cur.best;
                    state <= RETURN;
                end else begin
                    state <= FETCH;
                end
            end

            FETCH: begin
                cur.move <= move_rdata;
                state <= PUSH;
            end

            PUSH: begin
                cur.pos <= child_pos;
                cur.alpha <= -cur.beta;
                cur.beta <= -cur.alpha;
                cur.best <= -INF;
                cur.best_move <= '0;
                cur.move <= '0;
                cur.ncap <= '0;
                cur.nquiet <= '0;
                cur.idx <= '0;
                ply <= ply + 1;
                state <= NODE;

            end

            RETURN: begin
                if (ply == 0) begin
                    best_move <= cur.best_move;
                    best_score <= result;
                    state <= DONE;
                end else begin
                    ply <= ply - 1;
                    state <= POP_WAIT;
                end
            end

            POP_WAIT: begin
                cur <= frame_rdata;
                state <= UPDATE;
            end

            UPDATE: begin
                if (up_score > cur.best) begin
                    cur.best <= up_score;
                    cur.best_move <= cur.move;
                end

                cur.alpha <= new_alpha;
                cur.idx <= cur.idx + 1;

                if (cutoff) begin
                    result <= new_best;
                    state <= RETURN;
                end else begin
                    state <= NEXT;
                end
            end

            DONE: begin
                state <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
end

always_ff @(posedge clk) begin
    if (!rst_n) begin
        nodes <= '0;
        cycles <= '0;
    end else if (state == IDLE && start) begin
        nodes <= '0;
        cycles <= '0;
    end else if (state != IDLE && state != DONE) begin
        cycles <= cycles + 1;
        if (state == NODE) begin
             nodes <= nodes + 1;
        end
    end
end


endmodule