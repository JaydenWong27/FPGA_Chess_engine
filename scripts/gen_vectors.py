from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import os

from model.constants import CASTLE_KEEP

folder = ROOT / "vectors"
file_path =  folder / "castle_update.txt"

os.makedirs(folder, exist_ok=True)

with open(file_path, "w") as f:
    f.write("# castle_in from_sq to_sq castle_out\n") #whatever isthe comment line

    for castle in range (16):
        for from_square in range (64):
            for to_square in range (64):
                answer = castle & CASTLE_KEEP[from_square] & CASTLE_KEEP[to_square]
                f.write(f"{castle:x} {from_square:02x} {to_square:02x} {answer:x}\n")

