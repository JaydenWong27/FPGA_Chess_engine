from pathlib import Path
import sys
import chess
import random

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import os

from model.constants import CASTLE_KEEP, MASK64

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

if __name__ == "__main__":
    gen_castle()
    gen_attacks()

