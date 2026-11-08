import chess
import random 

def perft(board, depth):

    if (depth == 0):
        return 1
    else:
        total = 0
        for move in board.legal_moves:
            board.push(move)
            total = total + perft(board, depth - 1)
            board.pop()
        return total

def divide(board, depth):
    if (depth == 0):
        return 1
    else: 
        counts = {}
        for move in board.legal_moves:
            board.push(move)
            counts[move.uci()] = perft(board, depth - 1) 
            board.pop()
        return counts

def random_boards(n, seed=3):
    rng = random.Random(seed)
    boards = []
    for _ in range (n):
        board = chess.Board()
        for _ in range(rng.randint(1, 120)):
            moves = list(board.legal_moves)
            if not moves:
                break
            board.push(rng.choice(moves))
        boards.append(board)
    return boards
