import chess
from model.reference import random_boards
from model.search import negamax, alphabeta, search
from model.constants import MATE, INF, DRAW

def test_mate_in_one():
    board = chess.Board("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
    score, move = search(board, 2)
    assert move == chess.Move.from_uci("a1a8")
    assert score == MATE - 1

def test_stalemate():
    board = chess.Board("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
    score, move = search(board, 1)
    assert score == DRAW and move is None

def test_takes_free_queen():
    board = chess.Board("4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1")
    score, move = search(board, 1)
    assert chess.Move.from_uci("e4d5")

def test_alphabeta_matches_negamax():
    for board in random_boards(20, seed=5):
        assert alphabeta(board, 2, 0, -INF, INF) == negamax(board, 2, 0)
