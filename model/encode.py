import chess

from dataclasses import dataclass
from model.constants import (MASK64, BB_PAWNS, BB_KNIGHTS, BB_BISHOPS, BB_ROOKS, BB_QUEENS, BB_KINGS, BB_WHITE, BB_BLACK)

PIECE_BOARD = {"p": BB_PAWNS, "n": BB_KNIGHTS, "b": BB_BISHOPS,
               "r": BB_ROOKS, "q": BB_QUEENS, "k": BB_KINGS}

CASTLE_BIT = {"K" : 1, "Q" : 2, "k" : 4, "q" : 8}
# basically this is just a class called positions
@dataclass(frozen=True) # writes boring parts for us so we don't have to do this later
class Position:
  bb:        tuple #8 bitboards: PAWNS, KNIGHTS, BISHOPS, ROOKS, QUEENS, KINGS< WHite, BLACK
  stm:       int
  castle:    int
  ep_sq:     int
  ep_valid:  int 

def start_position():
  return Position(
    bb=(
        (0xFF << 8) | (0xFF << 48), #pawns
        (0x42 << 0) | (0x42 << 56), #Knights
        (0x24 << 0) | (0x24 << 56), #bishops
        (0x81 << 0) | (0x81 << 56), #rooks
        (0x08 << 0) | (0x08 << 56), #queens
        (0x10 << 0) | (0x10 << 56), #kings
        (0xFF << 0) | (0xFF << 8), #white
        (0xFF << 48) | (0xFF << 56), #black
    ),
    stm = 0, castle =0b1111, ep_sq = 0, ep_valid = 0,
  )

def state_word(pos):
  return (pos.stm | 
          (pos.castle << 1) | 
          (pos.ep_sq << 5) | 
          (pos.ep_valid << 11)
         )

def flatten(pos):
  n = 0
  for i, board in enumerate (pos.bb):
    n |= board << (64 * i) 
  n |= state_word(pos) << 512
  return n
def unflatten(n):
  boards = []
  for i in range(8):
    boards.append((n >> (64*i)) & MASK64)
  bb = tuple(boards)
  w = (n >> 512) & 0xFFFF
  return Position(bb = bb,
                  stm= w & 1,
                  castle=(w >> 1) & 0xF,
                  ep_sq = (w >> 5) & 0x3F,
                  ep_valid = (w >> 11) & 1
                 )

def from_fen(fen):
  fen_field = fen.split()
  if len(fen_field) not in (4,6):
    raise ValueError(f"FEN needs 4 or 6 fields: {fen}")
  boards = [0] * 8
  ranks = fen_field[0].split("/")
  for rank_index, rank_string in zip(range(7, -1, -1), ranks):
    file_index = 0
    for char in rank_string:
      if char.isdigit():
        file_index += int(char)
      else:
        square_mask = 1 << (rank_index * 8 + file_index)
        boards[PIECE_BOARD[char.lower()]] |= square_mask     # type bit
        if char.isupper():                                   # colour bit
          boards[BB_WHITE] |= square_mask
        else:
          boards[BB_BLACK] |= square_mask
        file_index += 1
        
  side = fen_field[1]
  if side == "w":
    stm = 0
  elif side == "b":
    stm = 1
  else:
    raise ValueError(f"side to move must be w or b: {side}")

  #castle
  castle = 0
  for char in fen_field[2]:
    if char != "-":
      castle |= CASTLE_BIT[char] 

  ep_field = fen_field[3]
  if ep_field == "-":
    ep_sq = 0
    ep_valid = 0
  else: 
    ep_file = ord(ep_field[0]) - ord("a")
    ep_rank = int(ep_field[1]) - 1
    ep_sq = ep_rank * 8 + ep_file
    ep_valid = 1
      
  return Position(bb=tuple(boards), stm=stm, castle=castle, ep_sq=ep_sq, ep_valid=ep_valid)

def to_fen(pos):
  ranks = []
  for rank_index in range(7, -1,-1):
    text = ""
    empty = 0
    for file_index in range(8):
      letter = piece_at(pos, rank_index * 8 + file_index)
      if letter is None:
        empty += 1
      else:
        if empty > 0:
          text = text + str(empty)
          empty = 0
        text = text + letter
    if empty > 0:
      text = text + str(empty)
    ranks.append(text)
  placement = "/".join(ranks)    
  
  if(pos.stm == 0):
     side = "w"
  else:
    side = "b"

  castling = ""
  for letter, bit in CASTLE_BIT.items():
    if pos.castle & bit:
      castling = castling + letter
  if castling == "":
    castling = "-"

  if pos.ep_valid == 1:
    ep = "abcdefgh"[pos.ep_sq % 8] + str(pos.ep_sq // 8 + 1)
  else:
    ep = "-"

  return " ".join([placement, side, castling, ep,"0", "1"])



  

def piece_at(pos, square):
  mask = 1 << square
  if ((pos.bb[BB_WHITE] | pos.bb[BB_BLACK]) & mask) == 0:
    return None

  for letter, index in PIECE_BOARD.items():
    if pos.bb[index] & mask:
      if(pos.bb[BB_WHITE] & mask):
        return letter.upper()
      else:
        return letter
        
      



if __name__ == "__main__":
  start = start_position()
  for board in start.bb:
    print(f"{board:016x}")
  print(f"{state_word(start):#06x}") 
  after_e4 = Position(bb=start.bb, stm=1, castle=0b1111, ep_sq=20, ep_valid=1)
  print(f"{state_word(after_e4):#06x}")
  print(f"{flatten(start):0132x}")
  print(unflatten(flatten(start)) == start)
  print(unflatten(flatten(after_e4)) == after_e4)
  START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
  print(from_fen(START_FEN) == start)
  print(f"{state_word(from_fen('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1')):#06x}")
  print(to_fen(start) == START_FEN)
  E4_FEN = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
  print(to_fen(from_fen(E4_FEN)) == E4_FEN)
  KIWI = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -"
  print(to_fen(from_fen(KIWI)) == KIWI + " 0 1")
