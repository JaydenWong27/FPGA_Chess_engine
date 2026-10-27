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
  unflat_start = unflatten(start_start)
  assert unflat_start == start

  after_e4 = Position(bb=start.bb, stm=1, castle=0b1111, ep_sq=20, ep_valid=1)
  unflat_e4 = unflatten(flatten(after_e4))
  assert unflat_e4 == after_e4
  
