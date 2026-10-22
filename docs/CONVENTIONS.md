Purpose and rules of this doc
This doc is the contract for the engine: the RTL in rtl/, the golden model in model/, the testbenches in tb/ and the host in host/ all follow it bit for bit. When two of them disagree, the one that breaks this doc is wrong.
• Each section states the rules first, then Why for the reasoning.
• Target device: AMD/Xilinx Artix-7 XC7A100T-2FTG256, built with Vivado.
• This is conventions version 1.0. A change bumps the version, adds a Changelog row, and updates rtl/common/chess_pkg.sv, model/encode.py and host/link.py in the same commit.
• In the repo this lives as docs/CONVENTIONS.md (export this doc as Markdown). It also covers what the scaffold's docs/DECISIONS.md was for, so that file can go.
Squares and bitboards
Squares are numbered 0–63 with a1 = 0 and h8 = 63 (little-endian rank-file, LERF), and bit n of every bitboard is square n.
Item
Rule
Square index
8 × rank + file, both counted from 0 (rank 0 is rank 1, file 0 is the a-file)
Examples
a1 = 0, h1 = 7, e4 = 28, a8 = 56, h8 = 63
Rank and file of a square
rank = bits 5:3, file = bits 2:0
Vertical flip (a1 ↔ a8)
sq XOR 56
Horizontal flip (a1 ↔ h1)
sq XOR 7
Bitboard
64 bits; bit n is square n; bit 0 is the least significant bit
Bytes of a bitboard
byte k holds rank k + 1, so byte 0 is rank 1
Shifts. Shifting left moves pieces toward higher squares. A shift with a sideways part first clears the file it would wrap from.
Direction
Shift
Clear first
North
left 8
nothing
South
right 8
nothing
East
left 1
FILE_H
West
right 1
FILE_A
North-east
left 9
FILE_H
North-west
left 7
FILE_A
South-east
right 7
FILE_H
South-west
right 9
FILE_A
Knight jumps of 6 or 10 move two files sideways, so they clear two files first (A and B, or G and H). Jumps of 15 or 17 clear one, like the diagonal shifts.
Masks
Name
Value
MASK64
0xFFFF_FFFF_FFFF_FFFF
FILE_A
0x0101_0101_0101_0101
FILE_H
0x8080_8080_8080_8080
RANK_1
0x0000_0000_0000_00FF
RANK_2
0x0000_0000_0000_FF00
RANK_3
0x0000_0000_00FF_0000
RANK_6
0x0000_FF00_0000_0000
RANK_7
0x00FF_0000_0000_0000
RANK_8
0xFF00_0000_0000_0000
The 64-bit rule. Every bitboard is exactly 64 bits. The RTL wraps at 64 bits by its width; the Python model masks with MASK64 after every left shift, subtraction and NOT.
Why
• It is the most common layout, and python-chess uses it (A1 = 0 to H8 = 63), so the model and the oracle compare boards with no remapping.
• Rank and file are bit fields of the index, so they cost nothing in hardware.
• Each byte is one rank, so hex dumps read rank by rank and little-endian transmission sends rank 1 first.
• Python integers never overflow, so without the mask the model and the RTL disagree on values that are each correct. This matters most for the subtraction at the heart of Hyperbola Quintessence.
Pieces and colours
White is 0 and black is 1, and piece types run from 1 (pawn) to 6 (king), with 0 meaning no piece.
Code
Colour
0
White
1
Black
Code
Piece type
Letter (white / black)
0
none
. in board printouts
1
Pawn
P / p
2
Knight
N / n
3
Bishop
B / b
4
Rook
R / r
5
Queen
Q / q
6
King
K / k
• Code 7 is reserved and never produced.
• The side-to-move bit uses the same coding: 0 means white to move.
• python-chess uses WHITE = True and BLACK = False. Convert only in model/encode.py: our colour is 1 when python-chess's colour is False.
• python-chess numbers piece types exactly like this, so they pass through unchanged.
Why
• Matching python-chess's piece numbers removes a translation step, and with it a class of bugs.
• With white = 0, the colour bit picks the colour board directly (board 6 + colour) and drives the negate-if-black step as a single wire.
• Code 0 for an empty square gives every lookup a natural no-piece answer.
Position
A position is eight 64-bit bitboards plus a 16-bit state word, 528 bits in all. The halfmove clock and fullmove number live only on the host.
Bitboards
Index
Name
Holds
0
PAWNS
pawns of both colours
1
KNIGHTS
knights of both colours
2
BISHOPS
bishops of both colours
3
ROOKS
rooks of both colours
4
QUEENS
queens of both colours
5
KINGS
kings of both colours
6
WHITE
every white piece
7
BLACK
every black piece
• The board for piece type t is index t − 1; the board for colour c is index 6 + c.
• Derived, never stored: occupied = WHITE OR BLACK; empty = NOT occupied, masked to 64 bits; pieces of type t and colour c = board[t − 1] AND board[6 + c].
Invariants (testbenches assert these on every position)
1. The six piece boards never overlap, and WHITE and BLACK never overlap.
2. The six piece boards together cover exactly WHITE OR BLACK.
3. Each colour has exactly one king.
4. No pawn stands on rank 1 or rank 8.
5. If EP_VALID is 1, EP_SQ is on rank 6 when white is to move and on rank 3 when black is to move.
State word (16 bits)
Bits
Field
Meaning
0
STM
side to move: 0 = white, 1 = black
1
CASTLE_WK
white may castle king-side (FEN K)
2
CASTLE_WQ
white may castle queen-side (FEN Q)
3
CASTLE_BK
black may castle king-side (FEN k)
4
CASTLE_BQ
black may castle queen-side (FEN q)
10:5
EP_SQ
en passant target square
11
EP_VALID
1 = EP_SQ is meaningful
15:12
reserved
always 0
Bits 4:1 together form the 4-bit CASTLE field, in FEN's KQkq order from bit 1 up. When EP_VALID is 0, EP_SQ is 0.
Update rules for every move
• STM flips.
• A double pawn push sets EP_SQ to the square the pawn skipped and EP_VALID to 1, whether or not an en passant capture is possible. Every other move sets both to 0.
• Castling rights: CASTLE = CASTLE AND KEEP[from] AND KEEP[to]. KEEP is 1111 for every square except these, written as CASTLE bits q k Q K:
Square
KEEP
Clears
a1 (0)
1101
white queen-side
e1 (4)
1100
both white rights
h1 (7)
1110
white king-side
a8 (56)
0111
black queen-side
e8 (60)
0011
both black rights
h8 (63)
1011
black king-side
Flattened form. As a single 528-bit number, board i occupies bits 64i + 63 down to 64i, and the state word occupies bits 527:512. This is the integer cocotb reads from a position bus and the integer model/encode.py builds, so two positions compare with one equality check.
FEN
• The model reads FENs with six fields, or four with the clocks missing; missing clocks default to halfmove 0 and fullmove 1.
• The castling field is - or a subset of KQkq. X-FEN and Shredder-FEN castling are not supported.
• When writing a FEN, the en passant field shows EP_SQ whenever EP_VALID is 1.
Why
• 8 boards, not 12. A copy holds 512 bits of boards instead of 768. The AND that picks white knights is one layer of LUTs, the mover's pieces are one stored board instead of a six-way OR, python-chess stores the same eight boards, and a UART packet carries 64 bytes of boards instead of 96.
• A separate EP_VALID bit. Square 0 is a real square, so there is no safe magic value for no en passant. One bit removes that whole class of bug.
• EP set after every double push. The hardware never checks for an adjacent enemy pawn, and perft counts don't change. python-chess's board.ep_square follows the same rule; its default FEN output does not.
• Clocks on the host. v1 search ignores the 50-move rule and repetition, so the hardware never needs them.
• KEEP masks. One lookup per square covers king moves, rook moves and rook captures alike, with no special cases.
• One flattened integer. Comparing the model with the RTL becomes a single equality check instead of nine.
Moves
A move is a 16-bit word: from-square in bits 5:0, to-square in bits 11:6, and a 4-bit flag in bits 15:12. The word 0x0000 means no move.
Bits
Field
5:0
FROM square
11:6
TO square
15:12
FLAGS
FLAGS
Binary
Move
0
0000
quiet move
1
0001
double pawn push
2
0010
castle king-side
3
0011
castle queen-side
4
0100
capture
5
0101
en passant capture
8
1000
promote to knight
9
1001
promote to bishop
10
1010
promote to rook
11
1011
promote to queen
12
1100
capture and promote to knight
13
1101
capture and promote to bishop
14
1110
capture and promote to rook
15
1111
capture and promote to queen
• Codes 6 and 7 are never produced.
• FLAGS bit 3 means promotion and FLAGS bit 2 means capture, en passant included. In a promotion, the new piece type is FLAGS bits 1:0 plus 2.
• NULL_MOVE = 0x0000 (a1 to a1), which is never legal.
What make-move does for each kind
Kind
Encoding
Effect beyond moving the piece
Castle king-side, white
e1 (4) to g1 (6), FLAGS 2
rook h1 (7) to f1 (5)
Castle queen-side, white
e1 (4) to c1 (2), FLAGS 3
rook a1 (0) to d1 (3)
Castle king-side, black
e8 (60) to g8 (62), FLAGS 2
rook h8 (63) to f8 (61)
Castle queen-side, black
e8 (60) to c8 (58), FLAGS 3
rook a8 (56) to d8 (59)
Double push
FROM to FROM ± 16, FLAGS 1
EP_SQ = FROM ± 8, EP_VALID = 1
En passant
TO = EP_SQ, FLAGS 5
remove the pawn on TO − 8 (white moving) or TO + 8 (black moving)
Capture
FLAGS bit 2 set
clear TO from every board before placing the mover
Promotion
FLAGS bit 3 set
remove the pawn; place the new piece on TO
Rules perft will catch. The move generator must get these right:
• Castling needs every square between king and rook empty, and the king may not start in check, cross an attacked square or land on one. On the queen-side, the b-file square must be empty but may be attacked.
• An en passant capture removes two pawns from one rank at once, which can expose the king to a rook or queen on that rank.
• When testing where the king may go, take the king out of the occupancy first. Otherwise it blocks a checking slider's ray, and retreating along that ray looks safe.
Move lists
• A move list holds legal moves only, in a 256-entry buffer indexed by 8 bits. No chess position has more than 218 legal moves, so the count also fits in 8 bits.
• An empty list means checkmate if the side to move is in check, otherwise stalemate.
Generation order (v1 placeholder)
• By moving piece type: pawn, knight, bishop, rook, queen, king.
• Then by FROM ascending, then TO ascending. The four promotions of one FROM and TO come queen, rook, bishop, knight, since the queen is almost always best.
• This order is replaced by whatever the RTL generator actually emits once it is designed, with a version bump. Perft doesn't depend on order; search node counts do.
• v1 search tries moves in list order, with no reordering.
UCI strings (host only). FROM and TO in algebraic form plus a lowercase promotion letter: e2e4, e7e8q. Castling is the king's move, e1g1.
Why
• FROM and TO fit 6 bits each, and the 4-bit flag table is the standard scheme from the Chess Programming Wiki's Encoding Moves page.
• Every question make-move asks is one wire: promotion is bit 3, capture is bit 2, the new piece is bits 1:0 plus 2.
• The flags carry what FROM and TO can't: the rook's move in castling, the pawn removed in en passant, and the square to set after a double push.
• Clearing TO from every board on a capture means make-move never needs the captured piece's type.
• Legal-only lists make mate and stalemate detection a test for an empty list, make perft a sum of list lengths, and keep a was-any-move-legal flag out of the search controller.
• Encoding castling as the king's move matches UCI, so the host converts it with no special case.
Scores
Scores are 16-bit signed centipawns from the side to move's point of view. Mate sits at 32000, and −32768 never appears.
Constant
Value
Meaning
MATE
32000
top of the mate band
INF
32001
search window limit, above every real score
DRAW
0
stalemate
MAX_PLY
64
stack frames 0–63
MATE_BOUND
31936
MATE − MAX_PLY; a score whose absolute value reaches this is a mate score
• A side to move that is checkmated at ply p, counting the root as ply 0, scores −(MATE − p).
• Scores whose absolute value is below MATE_BOUND are evaluations. Evaluation can never reach the band (see Evaluation).
• The root window starts at −INF to +INF.
• Host conversion for UCI: let p = MATE − |score|. A positive mate score is sent as score mate (p + 1) / 2, a negative one as score mate −p / 2, using integer division. Anything else is sent as score cp with the score.
Why
• 16 bits gives about ±32,000. A whole extra queen is 900, so ordinary scores never come close.
• The mate band sits above every evaluation, so a mate is never confused with being far ahead on material.
• Subtracting the ply makes a faster mate score higher for the winner and a slower one higher for the loser. The engine finishes won games and drags out lost ones.
• INF sits just above MATE, so the window never collides with a real score.
• Negamax negates scores constantly, and −32768 has no positive twin in 16 bits. Keeping every value within ±32001 makes every negation safe.
Evaluation (v1)
Evaluation is material plus piece-square tables, computed from white's point of view and negated when black is to move.
\text{eval}_{\text{white}} = \sum_{\text{white pieces}} \left( \text{VALUE}[t] + \text{PST}[t][sq] \right) - \sum_{\text{black pieces}} \left( \text{VALUE}[t] + \text{PST}[t][sq \oplus 56] \right)
The returned score is eval_white when STM is 0 and −eval_white when STM is 1.
Piece
VALUE (centipawns)
Pawn
100
Knight
320
Bishop
330
Rook
500
Queen
900
King
0
• PST is six tables of 64 signed entries, written from white's point of view and indexed by LERF square. A black piece looks up the flipped square, sq XOR 56.
• The v1 tables are the Chess Programming Wiki's Simplified Evaluation Function by Tomasz Michniewski; the king uses its middlegame table.
• Those tables are printed with rank 8 on top. The entry at printed position i, counting 0–63 in reading order, belongs to square i XOR 56.
• Integer arithmetic only, with no division or rounding, so the model and the RTL agree exactly.
• The largest possible absolute value of eval_white is about 11,200: nine queens and every other piece against a bare king, plus table bonuses. That is far below MATE_BOUND, so no clamp is needed; any future evaluation must also stay below it.
rtl/eval/pst_init.hex, written by scripts/gen_pst.py and loaded with $readmemh:
• 384 lines, one entry per line: 16-bit two's complement as 4 lowercase hex digits, no prefix.
• Line n holds piece type n / 64 + 1 (integer division) and square n mod 64.
• The tables hold positional bonuses only; material values are added separately.
Why
• The Simplified Evaluation Function is small, well known and good enough to play real chess. Tuning comes later.
• Computing once from white's view and negating at the end fits negamax with a single conditional negate.
• One table per piece type serves both colours through the vertical flip.
• The king is worth 0 because both kings are always on the board, so their values cancel.
• Copying printed tables without the flip is one of the most common evaluation bugs; stating it here prevents it.
• Material and tables stay separate to match material.sv (popcount times value) and pst.sv (table sum). The total is the same either way.
Search (v1)
The FPGA runs a fixed-depth negamax alpha-beta search (fail-soft) on an explicit stack with copy-make, and returns the best move, its score and the node count.
At every node (ply = distance from the root; the host sends depth d, from 1 to 63):
1. Count it: NODES = NODES + 1. The root and the leaves count too.
2. If ply = d, return the evaluation. There is no quiescence search in v1.
3. Generate the legal move list. If it is empty, return −(MATE − ply) when the side to move is in check, otherwise DRAW.
4. Set best = −INF, then try the moves in list order. For each one:
    1. score = −(the child's result, searched with the window −beta to −alpha).
    2. If score > best, set best = score.
    3. If score > alpha, set alpha = score and remember this move as the best move.
    4. If alpha ≥ beta, stop trying moves (a cutoff).
5. Return best.
At the root
• The window is −INF to +INF.
• The best move is the first move in list order whose score beats alpha; a later move with an equal score does not replace it.
• With at least one legal move the result is never NULL_MOVE, because every score beats −INF.
• If the root has no legal moves, the result is NULL_MOVE with score −MATE (checkmate) or DRAW (stalemate). The host should never send such a position.
How it is built (the model mirrors these steps exactly)
• No recursion: one stack frame per ply, frames 0–63.
• Copy-make: a child frame's position is a copy of its parent's with the move applied. Going back up simply discards the child.
• A frame holds the position, the move list, its count, the next-move index, alpha, beta, best score and best move.
• v1 has no quiescence search, transposition table, move reordering or pruning beyond alpha-beta.
Memory per pipeline on the XC7A100T
Store
Size
Kept in
Cost
Positions
64 × 528 bits ≈ 33 Kb
distributed RAM, no read latency
about 700 of 63,400 LUTs
Move lists
64 × 256 × 16 bits = 256 Kb
block RAM, one clock to read
about 8 of 135 BRAM36 blocks
Frame scalars
64 × 80 bits ≈ 5 Kb
distributed RAM
about 110 LUTs
Why
• Negamax with alpha-beta is the standard full-width search. Depth is fixed because the host runs iterative deepening.
• Fail-soft returns each node's real best score or bound and never clamps a leaf. It visits exactly the same nodes as fail-hard, with fewer places for the model and the RTL to differ.
• Hardware has no call stack, hence the explicit stack.
• Undoing a move is the most bug-prone code in an engine, and a 528-bit copy is cheap here, hence copy-make.
• Stored legal lists keep the search controller simple, and on this chip they cost about 6% of block RAM per pipeline.
• MAX_PLY is 64, not 32: it is cheap on the XC7A100T and leaves room for quiescence search, which goes past the nominal depth.
• A fixed node-count rule lets the testbench compare the model's count with the RTL's exactly.
• Wide, shallow memories go in distributed RAM and narrow, deep ones in block RAM, because that is where each is cheapest.
Host link (UART)
The host and the FPGA exchange fixed-size packets over UART at 115200 baud, 8N1, with every multi-byte field little-endian.
• Every packet is SYNC (0xA5), TYPE, SEQ, the payload, then CHK.
• CHK is the XOR of every byte from TYPE through the last payload byte.
• A reply echoes the request's SEQ, and its TYPE is the request's TYPE plus 0x80.
• A bitboard travels as 8 bytes, byte k being rank k + 1. The state word, the move and the score each travel as 2 bytes, low byte first.
SEARCH request, host to FPGA, 71 bytes
Offset
Bytes
Field
0
1
SYNC = 0xA5
1
1
TYPE = 0x01
2
1
SEQ
3
64
boards 0–7, 8 bytes each
67
2
state word
69
1
DEPTH, 1–63
70
1
CHK
RESULT reply, FPGA to host, 13 bytes
Offset
Bytes
Field
0
1
SYNC = 0xA5
1
1
TYPE = 0x81
2
1
SEQ, echoed
3
2
best move
5
2
score, signed
7
4
NODES, unsigned
11
1
STATUS
12
1
CHK
PING and PONG
Packet
Direction
Bytes
PING
host to FPGA
0xA5, 0x02, SEQ, CHK
PONG
FPGA to host
0xA5, 0x82, SEQ, VERSION_MAJOR, VERSION_MINOR, PIPELINES, CHK
STATUS codes
Code
Meaning
0
OK
1
bad checksum; no search was run
2
unknown TYPE
3
DEPTH outside 1–63
4–255
reserved
• Any error is answered with a RESULT reply carrying best move 0, score 0, NODES 0 and a non-zero STATUS.
• A receiver that loses track discards bytes until a SYNC that starts a packet with a valid CHK. Payload bytes may equal 0xA5; fixed lengths, not escaping, keep that safe.
• v1 has no abort command, so the host picks depths that finish in time.
Why
• Fixed-size packets make the receiver in protocol.sv a byte counter and a few registers.
• Little-endian matches Python's x.to_bytes(8, 'little') and makes byte k of a board rank k + 1, so a byte dump reads like the board.
• SEQ lets the host match each reply to its request and drop stale replies after a timeout.
• An XOR checksum is one 8-bit register in hardware and catches single-bit errors.
• NODES comes back so the testbench can compare it with the model and the host can measure speed.
• PING reports the conventions version, so the host never talks to an out-of-date bitstream unknowingly.
• 115200 baud is a safe bring-up speed: a SEARCH request takes about 6 ms. Raising it later is a one-constant change on each side, and a faster link lets the host hand out more searches per second.
Golden model and verification
The Python model in model/ implements every rule in this doc bit for bit. python-chess is the referee for the rules of chess, never for our bit formats.
• model/encode.py is the only place that converts between python-chess and our formats: colour bit, boards, state word, moves and packets.
• The model masks every intermediate to 64 bits after shifts, subtractions and NOT.
• The model uses the same move order, evaluation, search steps and node counting as the RTL.
• Compare en passant against python-chess's board.ep_square, not its FEN string.
• Perft positions are the start position, Kiwipete, and positions 3, 4 and 5 from the Chess Programming Wiki's Perft Results page. Deep counts come from that page; python-chess checks shallow depths and runs perft divide.
What each testbench compares
Testbench
Stimulus
Must match
tb/movegen/test_slider_hq.py
all 64 squares × many occupancies: empty, full, edges, random
python-chess attack sets
tb/movegen/test_movegen.py
the perft positions
legal move sets, ignoring order, and perft counts
tb/eval/test_eval.py
perft positions and positions from random games
the model's evaluation, exactly
tb/search/test_search.py
test positions at depths 1–4
the model's best move, score and NODES, exactly
• Positions on any bus are compared as the 528-bit flattened integer.
• Order-sensitive comparison of move lists starts once the generation order is final.
Text files in vectors/
• One record per line, fields separated by single spaces; a line starting with # is a comment.
• Hex without 0x, in lowercase, with 64-bit values padded to 16 digits.
Why
• One translation point means one place to look when the model and the oracle disagree.
• python-chess already knows the rules, so correctness never rests on our own code agreeing with itself.
• Comparing move sets before the order is fixed lets move generation be tested now, long before search exists.
Architecture decisions (v1)
The host does the clever, irregular work in Python and the FPGA does the regular, high-volume search, the same split Deep Blue and Hydra used.
The GUI talks UCI to the host, the host sends one SEARCH packet per search, and the FPGA answers with one RESULT.
Decision
v1 choice
Why
Position format
8 bitboards plus a 16-bit state word
a third less copying than 12 boards, free in logic, matches python-chess
Score format
16-bit signed centipawns, mate band at 32000
plenty of headroom; mate never mixes with ordinary scores
Move generation
one piece type at a time, over several clocks
simplest to build and verify; widen it only if measurements show it is the bottleneck
Undoing moves
copy-make
no undo logic to get wrong; copies are cheap in distributed RAM
Move lists
stored per ply, legal moves only
simplest search controller; about 8 of 135 block RAMs per pipeline
Work split
host: UCI, game state, clocks, repetition, iterative deepening, time management; FPGA: fixed-depth search
irregular logic is easy in Python; repetitive work is fast in hardware
Device and tools
XC7A100T-2FTG256 with Vivado; pins and timing in one .xdc file
the board you have; Vivado keeps both kinds of constraint together
• On this chip the scarcest budget is your time, not logic or memory. When two options are close, v1 takes the one that is easier to verify.
• Move generation is lean for simplicity, not scarcity: the XC7A100T has 63,400 LUTs and room for several pipelines.
• The UART link limits how many searches per second the host can hand out, at about 6 ms per request. That is fine while each request is a whole search; a Hydra-style split with many small jobs needs a faster link.
Deferred to later versions
v1 leaves the following out on purpose. Add them roughly in this order, each with a version bump where it changes a rule here.
1. Quiescence search, which keeps searching captures past the nominal depth. It is the biggest single strength gain after v1.
2. Move ordering: captures by most valuable victim and least valuable attacker (MVV-LVA), then killer moves. This also settles the final generation order.
3. A transposition table, on the host first and later perhaps in spare block RAM.
4. Several search pipelines with a distributor and an aggregator (array_top.sv).
5. A faster host link, then a Hydra-style split in which the host searches the top of the tree.
6. Pruning: null-move pruning and late-move reductions.
7. A richer evaluation with mobility, king safety and pawn structure, then tuning.
8. An abort command, so the host can stop a search when its time runs out.
Glossary
Term
Meaning
Ply
one side's move; search depth is counted in plies
Bitboard
a 64-bit number with one bit per square
LERF
the square numbering used here: a1 = 0, h8 = 63
Centipawn
a hundredth of a pawn; scores are in centipawns
Negamax
every score is from the side to move's view, and a parent's score is minus its child's
Alpha-beta
skips branches that cannot change the result; alpha and beta bound the window
Fail-soft
a node returns its real best score, even when it falls outside the window
Copy-make
copy the position, apply the move to the copy, and discard the copy to undo
Perft
counts every leaf of the move tree to a fixed depth, to check move generation
Perft divide
perft split by first move, to find which move is wrong
Quiescence search
keeps searching captures past the nominal depth, so a score is never taken mid-exchange
Golden model
the Python version of the engine that the RTL must match bit for bit
Hyperbola Quintessence
the subtraction trick that computes sliding-piece attacks
MVV-LVA
capture ordering: most valuable victim first, then least valuable attacker
Changelog
Date
Version
Change
2026-10-22
1.0
First version: XC7A100T target, MAX_PLY 64, all v1 rules
