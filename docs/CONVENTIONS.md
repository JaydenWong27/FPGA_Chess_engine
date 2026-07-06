# Basically what the conventions are

##Board coordinates to avoid problems later

#Square numbering uses little-endian rank-file:

- a1 = 0
- b1 = 1
- c1 = 2
- ...
- h1 = 7
- a2 = 8
- b2 = 9 
- ... and so on
- until h8 = 63

Formula: 

square = rank * 8 + file
file: a = 1, b = 1, c = 2, d = 3, ... , h = 7
rank: 1= 0; 2 = 1, ..., 8 = 7

each piece type has a 64 bit bitboard

each piece type has their own bitboards
- white pawns
- white kngihts
- white bishops
- white rooks
- white queens
- white king
- black pawns
- black knights
- black bishops
- black rooks
- black queens
- black king

bit n corresponds to square n

for example white king on e1 -> bit 4 set
black king on e8 -> bit 60 set


Position format

a full position contains 
- 12 piece bitboards
- side to move
- castling rights
- en passant square
- halfmove clock
- fullmove number, host only

Move encoding

bits 5:0 from square
bits 11:6 to square
bits 15:12 move flag
bits 19:16 promotion piece
bits 23:20 reserved

flags
0 = quiet
1 = capture
2 = double pawn push
3 = en passant
4 = castle kingside
5 = castle queenside
6 = promotion
7 = promotion capture

promotion pieces
0 = none
1 = knight
2 = bishop
3 = rook
4 = queen

Evaluation scale

centipawns score metric

pawn = 100
knight = 320
bishop = 330
rook = 500
queen = 900
king = 0

score width 

eval_score_t = signed 16 bit
normal eval range: -10000 to +10000
mate score: 30000

positive score means good for white

negamax
fixed-depth search in fpga
host handles nterative deepdning

depth = number of plies remaining
depth 0 = evaluate position

at first: moves are generated in determinisitc order:
pawn moves, knights, bishops, rooks, gueens, king
within each piece type, scan squares from 0 to 63

host sends: 
- position
- search depth

fpoga replies:
- best move
- score
- node count
- status

sent as FEN

castling is illegal when king is in check
the en passant is illegal if exposing own king
promotions generate knight, bishop, rook, or queen
the halfmove clock is tracked by host unless fpga needs it