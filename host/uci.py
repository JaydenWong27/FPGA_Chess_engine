from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import argparse
import chess
from host.link import Link, ModelLink
from host.driver import Engine

def send(text):
    print(text, flush=True)

def set_position(tokens):
    if tokens[1] == "startpos":
        board = chess.Board()
        rest = tokens[2:]
    elif tokens[1] == "fen":
        board = chess.Board(" ".join(tokens[2:8]))
        rest = tokens[8:]
    if rest and rest[0] == "moves":
        for m in rest[1:]:
            board.push_uci(m)
    return board

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port")
    ap.add_argument("--depth", type=int, default=3)
    args = ap.parse_args()

    link = Link(args.port) if args.port else ModelLink()
    engine = Engine(link, args.depth)
    board = chess.Board()

    for line in sys.stdin:
        tokens = line.split()
        if not tokens:
            continue
        cmd = tokens[0]

        if cmd == "uci":
            send("id name FPGA_Chess")
            send("id author Jayden Wong")
            send("uciok")
        elif cmd == "isready":
            send("readyok")
        elif cmd == "ucinewgame":
            board = chess.Board()
        elif cmd == "position":
            board = set_position(tokens)
        elif cmd == "go":
            move, score = engine.best_move(board)
            send(f"info depth {args.depth} score cp {score}")
            send("bestmove " + (move.uci() if move else "0000"))
        elif cmd == "quit":
            break

    link.close()

if __name__ == "__main__":
    main()