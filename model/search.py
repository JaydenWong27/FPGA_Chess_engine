from pathlib import Path
import sys
import chess
import random

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import os

from model.constants import MATE, INF, DRAW
from model.encode import from_board
from model.engine_model import evaluate


def hw_key(board, move):
    piece   = board.piece_type_at(move.from_square) - 1
    frm     = move.from_square
    to      = move.to_square

    if move.promotion is not None:
        promo = 5 - move.promotion 
    else :
        promo = 0

    return (piece, frm, to, promo)

def negamax(board, depth, ply):
    if (depth == 0):
        return evaluate(from_board(board)), None

    moves = sorted(board.legal_moves, key=lambda m: hw_key(board, m))

    if not moves:
        if (board.is_check() is True):
            return -(MATE - ply), None
        return DRAW, None

    best = -INF
    best_move = None
    for m in moves:
        board.push(m)
        score, _ = negamax(board, depth - 1, ply + 1)
        score = -score
        board.pop()

        if score > best:
            best = score
            best_move = m

    return best, best_move

def alphabeta(board, depth, ply, alpha, beta):
    if (depth == 0):
        return evaluate(from_board(board)), None

    moves = sorted(board.legal_moves, key=lambda m: hw_key(board, m))

    if not moves:
        if (board.is_check() is True):
            return -(MATE - ply), None
        return DRAW, None

    best = -INF
    best_move = None
    for m in moves:
        board.push(m)
        score, _ = alphabeta(board, depth - 1, ply + 1, -beta, -alpha)
        score = -score
        board.pop()

        if score > best:
            best = score
            best_move = m

        if score > alpha:
            alpha = score

        if alpha >= beta:
            break

    return best, best_move

def search(board, depth):
    return alphabeta(board, depth, 0, -INF, INF)