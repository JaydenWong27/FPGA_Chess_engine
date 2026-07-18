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


pieces = [
    (white_pawns, "P"), (white_knights, "N"), (white_bishops, "B"),
    (white_rooks, "R"), (white_queens, "Q"), (white_kings, "K"),
    (black_pawns, "p"), (black_knights , "n"), (black_bishops, "b"),
    (black_rooks, "r"), (black_queens, "q"), (black_kings, "k"),
]

def print_board():
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
        
print_board()

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






