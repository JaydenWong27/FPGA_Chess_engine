import chess
import sys
from model.reference import perft

POSITIONS = [
    ("start", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", [20, 400, 8902]),
    ("kiwipete", "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", [48, 2039, 97862]),
    ("pos3", "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1", [14, 191, 2812]),
    ("pos4", "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", [6, 264, 9467]),
    ("pos5", "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8", [44, 1486, 62379]),
]

failures = 0
for name, fen, counts in POSITIONS:
    for depth, expected in enumerate(counts, start=1):
        value = perft(chess.Board(fen), depth)
        if value == expected:
            status = "OK"
        else:
            failures += 1
            status = f"FAIL (expected {expected})"
        print(f"{name:<10} depth {depth}  {value:>6}  {status}")

if failures > 0:
    print(f"{failures} failed")
    sys.exit(1)
else:
    print("all passed")
