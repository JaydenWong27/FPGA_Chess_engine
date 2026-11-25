from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import argparse
import math
import chess
import chess.engine

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stockfish", required=True)
    ap.add_argument("--elo", type=int, default=1350)
    ap.add_argument("--games", type=int, default=20)
    ap.add_argument("--depth", type=int, default=2)
    ap.add_argument("--port")
    return ap.parse_args()

def open_engines(args):
    cmd = [sys.executable, str(ROOT / "host" / "uci.py"), "--depth", str(args.depth)]
    if args.port:
        cmd += ["--port", args.port]
    ours = chess.engine.SimpleEngine.popen_uci(cmd)

    sf = chess.engine.SimpleEngine.popen_uci(args.stockfish)
    sf.configure({"UCI_LimitStrength": True, "UCI_Elo": args.elo})
    return ours, sf

MAX_PLIES = 300

def play_game(ours, sf, ours_white):
    board = chess.Board()
    limit = chess.engine.Limit(time=0.1)

    while not board.is_game_over(claim_draw=True) and board.ply() < MAX_PLIES:
        ours_to_move = (board.turn == chess.WHITE) == ours_white
        engine = ours if ours_to_move else sf
        result = engine.play(board, limit)
        board.push(result.move)

    return board.result(claim_draw=True)


def our_points(result, ours_white):
    if result == "1/2-1/2" or result == "*":
        return 0.5
    white_won = (result == "1-0")
    return 1.0 if white_won == ours_white else 0.0

def elo_estimate(points, games, opp_elo):
    p = points / games
    p = min(max(p, 0.01), 0.99)
    return opp_elo + 400 * math.log10(p / (1 - p))

def main():
    args = parse_args()
    ours, sf = open_engines(args)
    points = 0.0
    try:
        for g in range(args.games):
            ours_white = (g % 2 == 0)
            result = play_game(ours, sf, ours_white)
            pts = our_points(result, ours_white)
            points += pts
            color = "W" if ours_white else "B"
            print(f"game {g+1:3d} ({color}) {result:8s} total {points}/{g+1}")
    finally:
        ours.quit()
        sf.quit()

    est = elo_estimate(points, args.games, args.elo)
    print(f"\nscore {points}/{args.games} vs Stockfish {args.elo} -> estimated Elo {est:.0f}")

if __name__ == "__main__":
    main()
