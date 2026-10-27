import chess

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
