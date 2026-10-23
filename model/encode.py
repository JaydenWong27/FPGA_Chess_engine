from dataclasses import dataclass
from model.constants import MASK64


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
  return Position(bb == bb,
                  stm= w & 1,
                  castle=(w >> 1) & 0xF,
                  ep_sq = (w >> 5) & 0x3F,
                  ep_valid = (w >> 11) & 1
                 )
  
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
