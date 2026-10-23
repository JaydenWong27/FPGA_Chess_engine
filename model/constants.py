MATE       = 32000   # top of the mate band
INF        = 32001   # Search window limit
DRAW       = 0   # Stalemate 
MAX_PLY    = 64   # Stack frames 0-63
MATE_BOUND = MATE - MAX_PLY   # MATE - MAX_PLY , score whose reaches this is a mate 

#Masks all for different purposes when calculating using the engine 
MASK64 = 0xFFFF_FFFF_FFFF_FFFF   # Triming python egers to 64 bits. RTL doesn't need it but stays in both files to keep them in steps
FILE_A =   0x0101_0101_0101_0101  
FILE_B =   0x0202_0202_0202_0202   # A and H stopping east, west and diagonal shifts from wrapping around board edge
FILE_G =   0x4040_4040_4040_4040 
FILE_H =   0x8080_8080_8080_8080   # B and G, same thing for knight jumps that move two files sideways
RANK_1 =   0x0000_0000_0000_00FF 
RANK_2 =   0x0000_0000_0000_FF00   # Promotion squares, and rule that no pawn ever stands there for 1 and 8
RANK_3 =   0x0000_0000_00FF_0000 
RANK_6 =   0x0000_FF00_0000_0000   # Pawns starting ranks and last rank before promotion
RANK_7 =   0x00FF_0000_0000_0000 
RANK_8 =   0xFF00_0000_0000_0000   # Single pushes that can carry on o a double push

COLOR_WHITE     = 0 
COLOR_BLACK     = 1 
PT_NONE         = 0 
PT_KING         = 6 
BB_PAWNS        = 0 

FLAG_QUIET_MOVE             = 0b0000 
FLAG_DOUBLE_PAWN_PUSH       = 0b0001 
FLAG_CASTLE_KING_SIDE       = 0b0010 
FLAG_CASTLE_QUEEN_SIDE      = 0b0011 
FLAG_CAPTURE                = 0b0100 
FLAG_EN_PASSANT_CAPTURE     = 0b0101 
FLAG_PROMOTE_TO_KNIGHT      = 0b1000 
FLAG_PROMOTE_TO_BISHOP      = 0b1001 
FLAG_PROMOTE_TO_ROOK        = 0b1010 
FLAG_PROMOTE_TO_QUEEN       = 0b1011 
FLAG_CAPTURE_PROMOTE_KNIGHT = 0b1100 
FLAG_CAPTURE_PROMOTE_BISHOP = 0b1101 
FLAG_CAPTURE_PROMOTE_ROOK   = 0b1110 
FLAG_CAPTURE_PROMOTE_QUEEN  = 0b1111 

FLAG_BIT_CAPTURE = 2 
FLAG_BIT_PROMO   = 3 

NULL_MOVE = 0x0000 
MAX_MOVES = 256 

SYNC = 0xA5 
TYPE_SEARCH = 0x01 
TYPE_PING =  0x02 
TYPE_RESULT = 0x81 
TYPE_PONG = 0x82 
STATUS_OK = 0x00 
STATUS_BAD_CHECKSUM = 0x01 
STATUS_BAD_TYPE = 0x02 
STATUS_BAD_DEPTH = 0x03 
LEN_SEARCH = 71 
LEN_RESULT = 13 
LEN_PING = 4 
LEN_PONG = 7 
BAUD = 115200 

VERSION_MAJOR = 0x01 
VERSION_MINOR = 0x00 

PT_PAWN = 1 
PT_KNIGHT = 2 
PT_BISHOP = 3 
PT_ROOK = 4 
PT_QUEEN = 5 

BB_KNIGHTS = 1 
BB_BISHOPS = 2 
BB_ROOKS = 3 
BB_QUEENS = 4 
BB_KINGS = 5 
BB_WHITE = 6 
BB_BLACK = 7 

# Tables (Functions in the package)
VALUE = (0, 100, 320, 330, 500, 900, 0) #these are indexed by piece type: none, P , N , B , R , Q, K

_KEEP = {0: 0b1101, 4: 0b1100, 7: 0b1110, 56: 0b0111, 60: 0b0011, 63: 0b1011}
CASTLE_KEEP = tuple(_KEEP.get(sq, 0b1111) for sq in range (64))
