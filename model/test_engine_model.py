import random
import chess
from pathlib import Path
from model.encode import from_board
from model.engine_model import PST, evaluate
from model.constants import MATE_BOUND
from model.reference import random_boards

ROOT = Path(__file__).resolve().parent.parent

# catch missing flip, unflipped would be 5, 25 and -40
def test_pst_flip():
    assert PST[0][48] == 50
    assert PST[0][12] == -20

def test_eval_start():
    assert evaluate(from_board(chess.Board())) == 0

# White's pawn goes from -20 to +20: white + 40, black to move, so -40
def test_eval_after_e4():
        board = chess.Board()
        board.push_san("e4")
        assert evaluate(from_board(board)) == -40 

# mirror () swaps colour, flips board and side to move score mustn't change 
def test_eval_mirror():
    for board in random_boards(300):
         assert evaluate(from_board(board)) == evaluate(from_board(board.mirror())), board.fen()

def test_eval_below_mate_band():
     for board in random_boards(300):
          assert abs(evaluate(from_board(board))) < MATE_BOUND, board.fen()


def test_pst_hex_file():
     lines = (ROOT / "rtl" / "eval" / "pst_init.hex").read_text().splitlines()
     assert len(lines) == 384
     for n, line in enumerate(lines):
          assert len(line) == 4 and line == line.lower(), f"line {n}:  {line}"
          assert int(line, 16) == PST[n // 64][n % 64] & 0xFFFF, f"line {n}"

def test_eval_material():
    assert evaluate(from_board(chess.Board("4k3/8/8/8/8/8/8/3QK3 w - - 0 1"))) == 895
    assert evaluate(from_board(chess.Board("4k3/8/8/8/8/8/8/3QK3 b - - 0 1"))) == -895
