"""Check the FPGA's search against the Python model over the UART, and time each search.

usage: python scripts/hw_check.py COM3 [max_depth] [positions]

Every (position, depth) must give the same move and score as model/search.py.
"""
from pathlib import Path
import sys
import time

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import chess
from model.encode import from_board, flatten
from model.reference import random_boards
from host.link import Link, ModelLink

port = sys.argv[1]
max_depth = int(sys.argv[2]) if len(sys.argv) > 2 else 4
count = int(sys.argv[3]) if len(sys.argv) > 3 else 10

boards = [chess.Board()] + list(random_boards(count - 1))
hw, model = Link(port, timeout=60), ModelLink()
bad = 0
for i, board in enumerate(boards):
    pos = flatten(from_board(board))
    for depth in range(1, max_depth + 1):
        t0 = time.perf_counter()
        hw_move, hw_score = hw.search(pos, depth)
        ms = (time.perf_counter() - t0) * 1000
        md_move, md_score = model.search(pos, depth)
        ok = (hw_move, hw_score, hw.last_nodes) == (md_move, md_score, model.last_nodes)
        bad += not ok
        cpn = hw.last_cycles / max(hw.last_nodes, 1)
        print(f"pos {i:2d} depth {depth}: fpga {hw_move:04x} {hw_score:6d} n={hw.last_nodes:7d}"
              f"  model {md_move:04x} {md_score:6d} n={model.last_nodes:7d}"
              f"  {cpn:6.1f} cyc/node  {ms:8.1f} ms  {'ok' if ok else 'MISMATCH'}", flush=True)
hw.close()
print(f"\n{len(boards) * max_depth - bad} / {len(boards) * max_depth} match")
sys.exit(1 if bad else 0)
