from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import serial
from model.encode import unflatten, to_board, move_from_chess
from model.search import search as model_search
HDR_CMD = 0xA5
HDR_REPLY = 0x5A
POS_BYTES = 66

class Link:
    def __init__(self, port, baud=115200, timeout=30):
        self.ser = serial.Serial(port, baud, timeout=timeout)

    def search(self, pos_int, depth):

        packet = bytes([HDR_CMD, depth]) + pos_int.to_bytes(POS_BYTES, "big")

        self.ser.reset_input_buffer()
        self.ser.write(packet)

        reply = self.ser.read(5)
        if len(reply) != 5:
            raise TimeoutError(f"got {len(reply)} of 5 reply bytes")
        if reply[0] != HDR_REPLY:
            raise ValueError(f"bad reply header {reply[0]:02x}")

        move = int.from_bytes(reply[1:3], "big")
        score = int.from_bytes(reply[3:5], "big", signed=True)
        return move, score

    def close(self):
        self.ser.close()

class ModelLink:
    def search(self, pos_int, depth):
        board = to_board(unflatten(pos_int))
        score, move = model_search(board, depth)
        word = 0 if move is None else move_from_chess(board, move)
        return word, score

    def close(self):
        pass
