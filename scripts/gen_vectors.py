from pathlib import Path
import sys
import chess
import random

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import os

from model.constants import CASTLE_KEEP, MASK64
from model.encode import from_board, flatten, move_from_chess
from model.engine_model import material, pst_score , evaluate
from model.reference import random_boards
from model.perft import POSITIONS
from model.search import search

folder = ROOT / "vectors"
file_path =  folder / "castle_update.txt"
os.makedirs(folder, exist_ok=True)

def gen_castle():

    with open(file_path, "w") as f:
        f.write( "#castle_in from_sq to_sq castle_out \n")
        for castle in range (16):
            for from_square in range (64):
                for to_square in range (64):
                    answer = castle & CASTLE_KEEP[from_square] & CASTLE_KEEP[to_square]
                    f.write(f"{castle:x} {from_square:02x} {to_square:02x} {answer:x}\n")


def slider_attacks(sq, occ):
    rank = chess.BB_RANK_ATTACKS[sq][occ & chess.BB_RANK_MASKS[sq]]
    file = chess.BB_FILE_ATTACKS[sq][occ & chess.BB_FILE_MASKS[sq]]
    diag = chess.BB_DIAG_ATTACKS[sq][occ & chess.BB_DIAG_MASKS[sq]]

    rook = rank | file
    bishop = diag
    return rook, bishop

def write_attacks(name, cases):
    path = folder / "attacks" / name
    with open(path, "w") as f:
        f.write("# sq occupancy rook_attacks bishop_attacks\n")
        for sq, occ in cases: 
            rook, bishop = slider_attacks(sq, occ)
            f.write(f"{sq:02x} {occ:016x} {rook:016x} {bishop:016x}\n")

def gen_attacks():
    os.makedirs(folder / "attacks", exist_ok=True)

    write_attacks("empty.txt", [(sq, 0) for sq in range(64)])
    write_attacks("full.txt",  [(sq, MASK64) for sq in range(64)])
    write_attacks("single.txt", [(sq, 1 << b) for sq in range(64) for b in range(64) if b != sq])
    random.seed(1)
    write_attacks("random.txt", [(sq, random.getrandbits(64)) for sq in range(64) for _ in range(200)])

def gen_eval():
    os.makedirs(folder / "eval", exist_ok=True)                
    with open(folder / "eval" / "eval.txt", "w") as f:
        f.write("# position material pst score\n")        
        for board in eval_boards():
            pos = from_board(board)                                 
            f.write(f"{flatten(pos):0132x} {h16(material(pos))} {h16(pst_score(pos))} {h16(evaluate(pos))}\n")
     
def h16(x):
    return f"{x & 0xFFFF:04x}" #16-bit two's complement and a 4 hex digit

def eval_boards():
    boards = [chess.Board(fen) for _, fen, _ in POSITIONS]
    boards += random_boards(1000, seed=11)
    boards += [
        chess.Board("4k3/8/8/8/8/8/8/4K3 w - - 0 1"),
        chess.Board("4k3/8/8/8/8/8/8/QQQ1K3 w - - 0 1"),
        chess.Board("qqq1k3/8/8/8/8/8/8/4K3 w - - 0 1"),
    ]
    flipped = []
    for board in boards:
        other = board.copy()
        other.turn = not other.turn
        other.ep_square = None
        flipped.append(other)
    return boards + flipped

def movegen_boards():
    boards = [chess.Board(fen) for _, fen, _ in POSITIONS]
    boards += random_boards(500, seed=15)
    boards += [
        chess.Board("8/8/8/K2pP2r/8/8/8/7k w - d6 0 1")
    ]
    return boards

def gen_movegen():
    os.makedirs( folder / "movegen" , exist_ok=True)
    with open(folder / "movegen" / "positions.txt", "w") as f:
        f.write("# position count moves\n")
        for board in movegen_boards():
            pos = from_board(board)
            moves = sorted(move_from_chess(board, m) for m in board.legal_moves)
            f.write(f"{flatten(pos):0132x} {len(moves):02x} {' '.join(f'{m:04x}' for m in moves )}\n")

def search_boards():
    search_boards = [chess.Board(fen) for _, fen, _ in POSITIONS]
    search_boards += random_boards(50, seed=17)
    search_boards += [
        chess.Board("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1"),
        chess.Board("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1"),
        chess.Board("4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1")
    ]
    return search_boards


def gen_search():
    os.makedirs( folder / "search" , exist_ok=True)
    with open(folder / "search" / "search.txt" , "w") as f:
        f.write("# position depth move score\n")
        for board in search_boards():
            pos = from_board(board)
            for depth in range(1,4):
                score, move = search(board, depth)
                if move is None:
                    m = 0
                else: 
                    m = move_from_chess(board, move)
                f.write(f"{flatten(pos):0132x} {depth:02x} {m:04x} {h16(score)}\n")


if __name__ == "__main__":
    gen_castle()
    gen_attacks()
    gen_eval()
    gen_movegen()
    gen_search()


