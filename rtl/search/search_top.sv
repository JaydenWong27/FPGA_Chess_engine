
module search_top 
import chess_pkg::*;
#(
    parameter string PST_FILE = "pst_init.hex"
) (
    input logic clk,
    input logic rst_n,
    input logic start,

    input position_t root_pos,
    input logic [5:0] depth,

    output logic done,
    output move_t best_move,
    output score_t best_score
);

    //movegen group wires
    logic mg_start;
    position_t mg_pos;
    logic mg_move_valid;
    move_t mg_move;
    logic mg_done;

    //eval group wires
    logic ev_start;
    position_t ev_pos;
    logic ev_done;
    score_t ev_score;

    //frame stack
    logic frame_we;
    logic [5:0] frame_waddr;
    frame_t frame_wdata;
    logic [5:0] frame_raddr;
    frame_t frame_rdata;

    // move lists
    logic move_we;
    logic [5:0] move_wply;
    logic [7:0] move_widx;
    move_t move_wdata;
    logic [5:0] move_rply;
    logic [7:0] move_ridx;
    move_t move_rdata;

    search_fsm u_fsm (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .root_pos(root_pos),
        .depth(depth),
        .done(done),
        .best_move(best_move),
        .best_score(best_score),

        // movegen

        .mg_start(mg_start),
        .mg_pos(mg_pos),
        .mg_move_valid(mg_move_valid),
        .mg_move(mg_move),
        .mg_done(mg_done),

    // eval

        .ev_start(ev_start),
        .ev_pos(ev_pos),
        .ev_done(ev_done),
        .ev_score(ev_score),

    // frame stack and move lists

        .frame_we(frame_we),
        .frame_waddr(frame_waddr),
        .frame_wdata(frame_wdata),
        .frame_raddr(frame_raddr),
        .frame_rdata(frame_rdata),

        .move_we(move_we),
        .move_wply(move_wply),
        .move_widx(move_widx),
        .move_wdata(move_wdata),
        .move_rply(move_rply),
        .move_ridx(move_ridx),
        .move_rdata(move_rdata)
    );

    movegen_top u_movegen (
        .clk(clk),
        .rst_n(rst_n),
        .start(mg_start),
        .pos(mg_pos),
        .move_valid(mg_move_valid),
        .move(mg_move),
        .done(mg_done)
    );

    eval_top #
    (.PST_FILE(PST_FILE))
    u_eval 
    (
        .clk(clk),
        .rst_n(rst_n),
        .start(ev_start),
        .pos(ev_pos),
        .done(ev_done),
        .score(ev_score),
        .mat_score(),
        .pst_score()
    );

    stack_mem u_stack (
        .clk(clk),

        .frame_we(frame_we),
        .frame_waddr(frame_waddr),
        .frame_wdata(frame_wdata),
        .frame_raddr(frame_raddr),
        .frame_rdata(frame_rdata),

        .move_we(move_we),
        .move_wply(move_wply),
        .move_widx(move_widx),
        .move_wdata(move_wdata),
        .move_rply(move_rply),
        .move_ridx(move_ridx),
        .move_rdata(move_rdata)
    );



endmodule