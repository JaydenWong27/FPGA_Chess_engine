from dataclasses import dataclass

white_pawns = 0xFF << 8
black_pawns = 0xFF << 48
white_knights = 0x42 << 0
black_knights = 0x42 << 56
white_bishops = 0x24 << 0
black_bishops = 0x24 << 56
white_rooks = 0x81 << 0
black_rooks = 0x81 << 56
white_queens = 0x08 << 0
black_queens = 0x08 << 56
white_kings = 0x10 << 0
black_kings = 0x10 << 56

@dataclass
class Position:
    white_pawns: int
    white_knights: int
    white_bishops: int
    white_rooks: int
    white_queens: int
    white_kings: int
    black_pawns: int
    black_knights: int
    black_bishops: int
    black_rooks: int
    black_queens: int
    black_kings: int
    side_to_move: bool
    white_left_castle: bool
    white_right_castle: bool
    black_left_castle: bool
    black_right_castle: bool
    en_passant_square: int
    halfmove_clock: int
    fullmove_number: int

def print_board(pos):
    pieces = [
        (pos.white_pawns, "P"), (pos.white_knights, "N"), (pos.white_bishops, "B"),
        (pos.white_rooks, "R"), (pos.white_queens, "Q"), (pos.white_kings, "K"),
        (pos.black_pawns, "p"), (pos.black_knights, "n"), (pos.black_bishops, "b"),
        (pos.black_rooks, "r"), (pos.black_queens, "q"), (pos.black_kings, "k"),
    ]
    for rank in range(7, -1, -1):
        row = ""
        for file in range(8):
            square = rank * 8 + file
            char = "."
            for bitboard, letter in pieces:
                if (bitboard >> square) & 1:
                    char = letter
                    break
            row += char + " "
        print(row)



def start_position():
    return Position(
        white_pawns=white_pawns, white_knights=white_knights, white_bishops=white_bishops,
        white_rooks=white_rooks, white_queens=white_queens, white_kings=white_kings,
        black_pawns=black_pawns, black_knights=black_knights, black_bishops=black_bishops,
        black_rooks=black_rooks, black_queens=black_queens, black_kings=black_kings,
        side_to_move=True,
        white_left_castle=True, white_right_castle=True,
        black_left_castle=True, black_right_castle=True,
        en_passant_square=None,
        halfmove_clock=0,
        fullmove_number=1,
    )


print_board(start_position())



