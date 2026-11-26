Step 0: Measure first

Before optimizing, make the hardware tell you how much work it did. Otherwise you can't tell whether a change helped.

Two counters in search_top:
nodes counts +1 every time search_fsm enters NODE.
cycles counts every clock while the search is busy.
A longer reply packet: add 8 bytes (nodes + cycles) after the move and score. Update protocol.sv (out_buf and the byte count) and host/link.py (read 13 bytes instead of 5).
Three numbers for every change:
nodes: did move ordering cut the tree?
cycles per node: did the hardware get faster per position?
Elo: did it actually play better?
Step 1: Captures first (move ordering)

Why it helps. Alpha-beta only cuts off branches once it has found a good move. If the strong move (usually a capture) is tried first, the other moves get refuted quickly and skipped. Same answer, far fewer nodes.

The property to test: at the root you search with a full window (−INF, +INF), so the root score can't change when only the move order changes. Only the best move may differ, when two moves tie. When you regenerate the search vectors, every score must stay identical. That's a great sanity check.

Simplest hardware version: a two-ended move list. Each ply already has 256 slots in stack_mem. During GEN:

Write tactical moves (flags[2] | flags[3], meaning captures, en passant and promotions) from the front: slots 0, 1, 2, …
Write quiet moves from the back: slots 255, 254, …
frame_t needs two counters (ncap, nquiet) instead of one count.
To iterate, turn the search index k into a slot: slot = (k < ncap) ? k : 255 − (k − ncap). Captures come first, then quiet moves in generation order.

This needs no second movegen pass, just a different write address.

Python model: sort with key = (0 if tactical else 1, hw_key(...)). Captures keep your existing hardware order among themselves, and so do quiet moves.

Later upgrade (MVV-LVA): among captures, try "most valuable victim, least valuable attacker" first: pawn takes queen before queen takes pawn. A classic hardware trick is a sorted shift-register list:

Each new capture gets a score, for example victim_value * 8 − attacker_index.
Every slot compares itself with the new score in parallel, in one clock, and shifts.
That's an insertion sort with no loop.
Step 2: Quiescence search

The problem it fixes. At depth 0 you evaluate immediately, even in the middle of an exchange: "I just took a knight with my queen" scores as +3 even though the queen gets recaptured. That's the horizon effect, and it's your biggest weakness.

The algorithm. At depth 0, keep searching only tactical moves until the position is quiet:

qsearch(pos, alpha, beta, ply):
    stand = eval(pos)                       # "stand pat": I may decline all captures
    if stand >= beta or ply == MAX_PLY-1: return stand
    best = stand; alpha = max(alpha, stand)
    for m in tactical moves (captures first):
        score = -qsearch(child, -beta, -alpha, ply+1)
        best = max(best, score); alpha = max(alpha, score)
        if alpha >= beta: break
    return best

In alphabeta, depth == 0 now calls qsearch instead of evaluate.

How it maps onto your FSM. Nearly all of it is reuse:

A node is a QS node when ply >= root_depth. That needs no new field: you already have ply and root_depth.
NODE: for a QS node, start eval (ev_start becomes ply >= root_depth) and go to a new state, QS_STAND.
QS_STAND: wait for ev_done.
If ev_score >= cur.beta: result = ev_score, go to RETURN (a cutoff).
Otherwise: cur.best = ev_score and cur.alpha = max(alpha, ev_score), then go to GEN.
GEN in a QS node: write only tactical moves. The easy first version is a filter in search_fsm (move_we = GEN && mg_move_valid && (!qs || tactical)), with movegen unchanged.
No moves at the end of GEN: in a QS node, return cur.best (the stand-pat score), not mate/draw. "No captures" doesn't mean checkmate.
Everything else stays the same: NEXT / FETCH / PUSH / RETURN / UPDATE already do negamax and alpha-beta. The old EVAL leaf state goes away.

Pitfalls to decide up front. The Python model must do exactly the same thing in each case:

Which moves count: all four promotions, or queen promotions only? En passant: yes.
In check at a QS node: standing pat is technically wrong there. In the first version, ignore it in both the model and the RTL. Later: if in_check (search_fsm already computes it), don't stand pat and search all moves.
Frame stack depth: you have 64 frames. The ply == MAX_PLY-1 guard stops a long capture chain from overflowing it.

Later speed-up: stop movegen from even generating quiet moves in QS, by adding a captures_only input. For non-pawns, targets &= them_bb. For pawns, use pawn_cap | (pawn_push & promotion rank). That saves the cycles wasted legality-checking quiet moves, but the filter version is correct and easier to start with.

Step 3: Make each position cheap
3a. Incremental eval (the big one)

The insight: your eval is a sum over pieces: each piece adds ±(value + PST[square]). A move only changes 2–4 pieces, so instead of re-adding all ~32 pieces at every leaf (about 35 clocks), update the sum as each move is made.

Store the score in the frame. Add a score_t eval_w (from white's point of view) to frame_t. Compute it once for the root with your existing eval_top.
Every move is a few "remove piece X from A" / "add piece X on B" terms. Each term is one lookup: contrib(color, piece, sq) = ±(value[piece] + PST[piece][color ? sq^56 : sq]).
Move	Terms
quiet move	remove mover at from, add mover at to: 2
capture	the same 2, plus remove the victim: 3
en passant	3 (the victim isn't on the to square)
promotion	remove pawn, add promoted piece (+ remove the victim if it's a capture)
castling	king out and in, rook out and in: 4
Hardware: a small block next to make_move with up to 4 table lookups plus an adder, giving child_eval = parent_eval + delta.
Each lookup needs its own read port, so either use 4 copies of the small LUT ROM, or dual-port BRAMs and let PUSH take 2 clocks.
The leaf (or QS stand-pat) eval becomes stm ? −eval_w : eval_w, which costs 0 clocks.
Verification: keep eval_top in the testbench as a reference checker, and assert at every node that eval_w == full eval(pos). If the incremental sum ever drifts, it fires on the exact move that broke it. In the Python model, also add an apply_delta and assert it matches evaluate() on random games.
3b. Cheaper legality (later)

Right now every candidate move runs make_move plus a full "is my king attacked?" check. That's the long path that failed timing. The standard approach (it's how Stockfish does it) computes three things once per node:

checkers: the enemy pieces giving check.
pinned: your pieces that can't leave the line to your king.
The enemy attack map, used for king moves.

Then each candidate is just a few masks:

King moves: to must not be attacked.
Single check: to must capture the checker or block the ray.
Pinned piece: it must stay on the pin line.
En passant: keep the full check for this rare case only.

This turns legality into a few AND gates, which makes a higher clock and more moves per clock possible.

3c. A faster clock (last)
Find and cut the slow paths: use the timing report (build/timing.rpt) to find the critical paths, add registers there, then generate 100 MHz from the 50 MHz input with an MMCM.
One number to change outside the RTL: the UART's CLK_HZ parameter.
Why your testbenches survive it: your blocks talk through start/done handshakes, so adding pipeline stages doesn't break the protocol, and the UVM tests wait for done.
