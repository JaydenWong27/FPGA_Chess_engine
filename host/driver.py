from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from model.encode import from_board, flatten, move_to_chess

class Engine:
    def __init__(self, link, depth=3):
        self.link = link
        self.depth = depth

    def best_move(self, board):
        pos_int = flatten(from_board(board))

        word, score = self.link.search(pos_int, self.depth)

        if word == 0:
            return None, score

        move = move_to_chess(word)


        if move not in board.legal_moves:
            raise ValueError(f"engine returned illegal move {move.uci()} (word {word:04x})")

        return move, score


if __name__ == "__main__":
    import chess
    from host.link import ModelLink

    eng = Engine(ModelLink(), depth=2)
    board = chess.Board()
    for _ in range(6):
        move, score = eng.best_move(board)
        print(board.fen(), "->", move, score)
        if move is None:
            break
        board.push(move)