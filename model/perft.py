
import chess
import sys
from model.reference import perft

positions = [("start", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", [20, 400, 8902]),
            ("kiwipete", "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", ]

for name, fen, counts in POSITIONS:
  for depth, expected in enumerate(counts, start=1):
    value = perft(chess.Board(fen), depth)
    
