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
    white_kingside_castle: bool
    white_queenside_castle: bool
    black_kingside_castle: bool
    black_queenside_castle: bool
    en_passant_square: int
    halfmove_clock: int
    fullmove_number: int


def occupancy(pos):
    white_occupied = (
        pos.white_pawns | pos.white_knights | pos.white_bishops |
        pos.white_rooks | pos.white_queens | pos.white_kings
    )
    black_occupied = (
        pos.black_pawns | pos.black_knights | pos.black_bishops |
        pos.black_rooks | pos.black_queens | pos.black_kings
    )
    all_occupied = white_occupied | black_occupied
    return white_occupied, black_occupied, all_occupied

def pawn_pushes(pos):
    moves = []
    white_occupied, black_occupied, all_occupied = occupancy(pos)
    if pos.side_to_move:
        pawns = pos.white_pawns
        direction = 8
    else:
        pawns = pos.black_pawns
        direction = -8
    for square in range(64):
        if (pawns >> square) & 1:
            target = square + direction
            if not (all_occupied >> target) & 1:
                moves.append((square, target,0,0))
    return moves
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
        white_kingside_castle=True, white_queenside_castle=True,
        black_kingside_castle=True, black_queenside_castle=True,
        en_passant_square=None,
        halfmove_clock=0,
        fullmove_number=1,
    )


if __name__ == "__main__":
    print_board(start_position())
    w, b, a = occupancy(start_position())
    print(hex(w), hex(b), hex(a))
    print(pawn_pushes(start_position()))



def parse_fen(fen):
    fields = fen.split(" ")
    side_to_move = fields[1] == "w"
    white_kingside_castle = "K" in fields[2]
    white_queenside_castle = "Q" in fields[2]
    black_kingside_castle = "k" in fields[2]
    black_queenside_castle = "q" in fields[2]
    halfmove_clock = int(fields[4])
    fullmove_number = int(fields[5])
    ranks = fields[0].split("/")
    ep_field = fields[3]
    if ep_field == "-":
        en_passant_square = None
    else:
        ep_file = ord(ep_field[0]) - ord("a")
        ep_rank = int(ep_field[1]) - 1
        en_passant_square = ep_rank * 8 + ep_file
    wt_pawn = 0
    wt_knight = 0
    wt_bishop = 0
    wt_rook = 0
    wt_queen = 0
    wt_king = 0
    bl_pawn = 0
    bl_knight = 0
    bl_bishop = 0
    bl_rook = 0
    bl_queen = 0
    bl_king = 0
    for rank_index, rank_string in zip(range(7, -1, -1), ranks):
        file_index = 0
        for char in rank_string:
            if char.isdigit():
                file_index += int(char)
            else:
                square = rank_index * 8 + file_index
                if char == "P":
                    wt_pawn |= (1 << square)
                elif char == "N":
                    wt_knight |= (1 << square)
                elif char == "B":
                    wt_bishop |= (1 << square)
                elif char == "R":
                    wt_rook |= (1 << square)
                elif char == "Q":
                    wt_queen |= (1 << square)
                elif char == "K":
                    wt_king |= (1 << square)
                elif char == "p":
                    bl_pawn |= (1 << square)
                elif char == "n":
                    bl_knight |= (1 << square)
                elif char == "b":
                    bl_bishop |= (1 << square)
                elif char == "r":
                    bl_rook |= (1 << square)
                elif char == "q":
                    bl_queen |= (1 << square)
                elif char == "k":
                    bl_king |= (1 << square)
                file_index += 1
    return Position(
    white_pawns=wt_pawn, white_knights=wt_knight, white_bishops=wt_bishop,
    white_rooks=wt_rook, white_queens=wt_queen, white_kings=wt_king,
    black_pawns=bl_pawn, black_knights=bl_knight, black_bishops=bl_bishop,
    black_rooks=bl_rook, black_queens=bl_queen, black_kings=bl_king,
    side_to_move=side_to_move,
    white_kingside_castle=white_kingside_castle, white_queenside_castle=white_queenside_castle,
    black_kingside_castle=black_kingside_castle, black_queenside_castle=black_queenside_castle,
    en_passant_square=en_passant_square,
    halfmove_clock=halfmove_clock,
    fullmove_number=fullmove_number,
)

    
