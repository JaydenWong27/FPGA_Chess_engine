import random
import chess
import pytest
from model.encode import (start_position, state_word, flatten, unflatten, 
from_fen, to_fen, piece_at, from_board, to_board, pack_move, unpack_move, 
move_from_chess, move_to_chess, check_invariants, Position) 

START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
E4_FEN = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
KIWIPETE_FEN = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"

def test_start_state_word():
  assert state_word(start_position()) == 0x001e

def test_e4_state_word():
  start = start_position()
  after_e4 = Position(bb=start.bb, stm=1, castle=0b1111, ep_sq=20, ep_valid=1)
  assert state_word(after_e4) == 0x0a9f

def test_start_boards():
  start = start_position()
  assert start.bb == (
    0x00ff00000000ff00, # pawns
    0x4200000000000042, # knights
    0x2400000000000024, # bishops
    0x8100000000000081, # rooks
    0x0800000000000008, # queens
    0x1000000000000010, # kings
    0x000000000000ffff, # white
    0xffff000000000000, # black
  )

def test_flatten_start():
  start = start_position()
  flat = flatten(start)
  assert f"{flat:0132x}" == "001effff000000000000000000000000ffff1000000000000010080000000000000881000000000000812400000000000024420000000000004200ff00000000ff00"
  

def test_round_trips():
  start = start_position()
  flat_start = flatten(start)
  unflat_start = unflatten(flat_start)
  assert unflat_start == start

  after_e4 = Position(bb=start.bb, stm=1, castle=0b1111, ep_sq=20, ep_valid=1)
  unflat_e4 = unflatten(flatten(after_e4))
  assert unflat_e4 == after_e4
  
def test_from_fen_start():
  start = start_position()
  assert from_fen(START_FEN) == start

def test_from_fen_e4_state():
  assert state_word(from_fen(E4_FEN)) == 0x0a9f

def test_to_fen_round_trips():
  assert to_fen(from_fen(START_FEN)) == START_FEN
  assert to_fen(from_fen(E4_FEN)) == E4_FEN
  assert to_fen(from_fen(KIWIPETE_FEN)) == KIWIPETE_FEN

def test_four_field_fen():
  bit_field = from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -")
  four_bit_field = to_fen(bit_field)
  assert four_bit_field == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

def test_piece_at():
  start = start_position()
  assert piece_at(start, 4) == "K"
  assert piece_at(start, 59) == "q"
  assert piece_at(start, 28) == None

def test_bad_fens():
  with pytest.raises(ValueError):
    from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0")
  with pytest.raises(ValueError):
    from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1")

def test_from_board_start():
  start = start_position()
  assert (from_board(chess.Board()) == start_position())

def test_from_board_matches_from_fen():
  assert (from_board(chess.Board(START_FEN)) == from_fen(START_FEN))
  assert (from_board(chess.Board(E4_FEN)) == from_fen(E4_FEN))
  assert (from_board(chess.Board(KIWIPETE_FEN)) == from_fen(KIWIPETE_FEN))
          
def test_to_board_round_trip():
  start = start_position()
  assert  (from_board(to_board(start)) == start)

def test_from_board_after_e4():
  board = chess.Board()
  board.push_san("e4")
  assert state_word(from_board(board)) == 0x0a9f

def test_castling_rights_lost():
  board = chess.Board(KIWIPETE_FEN)
  board.push_san("Kf1")
  assert from_board(board).castle == 0b1100

def test_pack_move_examples():
  assert pack_move(12,28,1) == 0x170c
  assert pack_move(4,6,2) == 0x2184
  assert pack_move(52,60,11) == 0xbf34

  
def test_unpack_move():
  assert unpack_move(0x170c) == (12,28,1)
  assert unpack_move(pack_move(52,60,11)) == (52,60,11)

def test_move_from_chess_e4():
  board = chess.Board()
  move = chess.Move.from_uci("e2e4")
  assert move_from_chess(board, move) == 0x170c
  

def test_move_to_chess():
  assert move_to_chess(0x170c).uci() == "e2e4"
  assert move_to_chess(0xbf34).uci() == "e7e8q"

def test_move_round_trips():
  for fen in (START_FEN, E4_FEN, KIWIPETE_FEN):
    board = chess.Board(fen)
    for move in board.legal_moves:
      assert move_to_chess(move_from_chess(board, move)) == move

def test_invariants_pass():
  check_invariants(start_position())
  check_invariants(from_fen(E4_FEN))
  check_invariants(from_fen(KIWIPETE_FEN))

def test_invariants_rule_1():
  s = start_position()
  broken = Position(bb=(s.bb[0] | 1,) + s.bb[1:], stm=0, castle=0, ep_sq=0, ep_valid=0)
  with pytest.raises(ValueError, match="rule 1"):
    check_invariants(broken)

def test_invariants_rule_2():
  s = start_position()
  broken = Position(bb=s.bb[:6] + (s.bb[6] & ~1, s.bb[7]), stm=0, castle=0, ep_sq=0, ep_valid=0)
  with pytest.raises(ValueError, match="rule 2"):
    check_invariants(broken)

def test_invariants_rule_3():
  with pytest.raises(ValueError, match="rule 3"):
    check_invariants(from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBKKBNR w - - 0 1"))
  with pytest.raises(ValueError, match="rule 3"):
    check_invariants(from_fen("rnbkkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - - 0 1"))
  
def test_invariants_rule_4():
  with pytest.raises(ValueError, match="rule 4"):
    check_invariants(from_fen("rnbqkPnr/pppppppp/8/8/8/8/PPPPPPP1/RNBQKBNR w - - 0 1"))


def test_invariants_rule_5():
  s = start_position()
  broken = Position(bb=s.bb, stm=0, castle=15, ep_sq=20, ep_valid=0)
  with pytest.raises(ValueError, match="rule 5"):
    check_invariants(broken)
  with pytest.raises(ValueError, match="rule 5"):
    check_invariants(from_fen("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e4 0 1"))
    

def test_random_games():
  random.seed(1)
  flags_seen = set()
  for game in range(50):
    board = chess.Board()
    for ply in range(200):
      pos = from_board(board) 
      assert pos == from_fen(board.fen(en_passant="fen"))
      assert from_fen(to_fen(pos)) == pos
      assert unflatten(flatten(pos)) == pos
      check_invariants(pos)
      moves = list(board.legal_moves)
      if not moves:
        break
      for move in moves:
        word = move_from_chess(board, move)
        assert move_to_chess(move_from_chess(board, move)) == move
        flags_seen.add(word >> 12)
      board.push(random.choice(moves))
  assert len(flags_seen) == 14

  
