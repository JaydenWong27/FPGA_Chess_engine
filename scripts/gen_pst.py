from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from model.engine_model import PST

with open(ROOT / "rtl" / "eval" / "pst_init.hex", "w") as f:
    for t in range(6):
        for sq in range(64):
            f.write(f"{PST[t][sq] & 0xFFFF:04x}\n") # 0xFFFF gives 16 bit two's complememnt so -20 becomes ffac
