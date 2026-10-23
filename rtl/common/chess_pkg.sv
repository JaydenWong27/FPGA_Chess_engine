package chess_pkg;
  typedef logic [5:0] square_t;
  typedef logic [63:0] bitboard_t;
  typedef logic signed [15:0] score_t;

  typedef struct packed {
    logic [3:0] reserved; // bits 15:12, always 0
    logic       ep_valid; // bit 11
    square_t     ep_sq;   // bits:10:5
    logic [3:0] castle;   // bits 4:1, written q k Q K
    logic        stm; //bit 0, 0 = white to move
  } state_t;

  typedef struct packed {
    state_t    state; // bits 527:512
    bitboard_t [7:0] bb; // bb[i] at bits 64i+63 : 64i
  } position_t;
  
  localparam int MATE       = 32000; // top of the mate band
  localparam int INF        = 32001; // Search window limit
  localparam int DRAW       = 0; // Stalemate 
  localparam int MAX_PLY    = 64; // Stack frames 0-63
  localparam int MATE_BOUND = 31936; // MATE - MAX_PLY , score whose reaches this is a mate 

  //Masks all for different purposes when calculating using the engine 
  localparam logic [63:0] MASK64 = 64'hFFFF_FFFF_FFFF_FFFF; // Triming python integers to 64 bits. RTL doesn't need it but stays in both files to keep them in steps
  localparam logic [63:0] FILE_A = 64'h0101_0101_0101_0101; 
  localparam logic [63:0] FILE_B = 64'h0202_0202_0202_0202; // A and H stopping east, west and diagonal shifts from wrapping around board edge
  localparam logic [63:0] FILE_G = 64'h4040_4040_4040_4040;
  localparam logic [63:0] FILE_H = 64'h8080_8080_8080_8080; // B and G, same thing for knight jumps that move two files sideways
  localparam logic [63:0] RANK_1 = 64'h0000_0000_0000_00FF;
  localparam logic [63:0] RANK_2 = 64'h0000_0000_0000_FF00; // Promotion squares, and rule that no pawn ever stands there for 1 and 8
  localparam logic [63:0] RANK_3 = 64'h0000_0000_00FF_0000;
  localparam logic [63:0] RANK_6 = 64'h0000_FF00_0000_0000; // Pawns starting ranks and last rank before promotion
  localparam logic [63:0] RANK_7 = 64'h00FF_0000_0000_0000;
  localparam logic [63:0] RANK_8 = 64'hFF00_0000_0000_0000; // Single pushes that can carry on into a double push

  localparam int COLOR_WHITE     = 0;
  localparam int COLOR_BLACK     = 1;
  localparam int PT_NONE         = 0;
  localparam int PT_KING         = 6;
  localparam int BB_PAWNS        = 0;

  localparam logic [3:0] FLAG_QUIET_MOVE             = 4'b0000;
  localparam logic [3:0] FLAG_DOUBLE_PAWN_PUSH       = 4'b0001;
  localparam logic [3:0] FLAG_CASTLE_KING_SIDE       = 4'b0010;
  localparam logic [3:0] FLAG_CASTLE_QUEEN_SIDE      = 4'b0011;
  localparam logic [3:0] FLAG_CAPTURE                = 4'b0100;
  localparam logic [3:0] FLAG_EN_PASSANT_CAPTURE     = 4'b0101;
  localparam logic [3:0] FLAG_PROMOTE_TO_KNIGHT      = 4'b1000;
  localparam logic [3:0] FLAG_PROMOTE_TO_BISHOP      = 4'b1001;
  localparam logic [3:0] FLAG_PROMOTE_TO_ROOK        = 4'b1010;
  localparam logic [3:0] FLAG_PROMOTE_TO_QUEEN       = 4'b1011;
  localparam logic [3:0] FLAG_CAPTURE_PROMOTE_KNIGHT = 4'b1100;
  localparam logic [3:0] FLAG_CAPTURE_PROMOTE_BISHOP = 4'b1101;
  localparam logic [3:0] FLAG_CAPTURE_PROMOTE_ROOK   = 4'b1110;
  localparam logic [3:0] FLAG_CAPTURE_PROMOTE_QUEEN  = 4'b1111;

  localparam int FLAG_BIT_CAPTURE = 2;
  localparam int FLAG_BIT_PROMO   = 3;

  localparam logic [15:0] NULL_MOVE = 16'h0000;
  localparam int          MAX_MOVES = 256;

  localparam logic [7:0] SYNC = 8'hA5;
  localparam logic [7:0] TYPE_SEARCH = 8'h01;
  localparam logic [7:0] TYPE_PING =  8'h02;
  localparam logic [7:0] TYPE_RESULT = 8'h81;
  localparam logic [7:0] TYPE_PONG = 8'h82;
  localparam logic [7:0] STATUS_OK = 8'h00;
  localparam logic [7:0] STATUS_BAD_CHECKSUM = 8'h01;
  localparam logic [7:0] STATUS_BAD_TYPE = 8'h02;
  localparam logic [7:0] STATUS_BAD_DEPTH = 8'h03;
  localparam int LEN_SEARCH = 71;
  localparam int LEN_RESULT = 13;
  localparam int LEN_PING = 4;
  localparam int LEN_PONG = 7;
  localparam int BAUD = 115200;

  localparam logic [7:0] VERSION_MAJOR = 8'h01;
  localparam logic [7:0] VERSION_MINOR = 8'h00;

  localparam int PT_PAWN = 1;
  localparam int PT_KNIGHT = 2;
  localparam int PT_BISHOP = 3;
  localparam int PT_ROOK = 4;
  localparam int PT_QUEEN = 5;

  localparam int BB_KNIGHTS = 1;
  localparam int BB_BISHOPS = 2;
  localparam int BB_ROOKS = 3;
  localparam int BB_QUEENS = 4;
  localparam int BB_KINGS = 5;
  localparam int BB_WHITE = 6;
  localparam int BB_BLACK = 7;

  function automatic int piece_value(input int pt);
    case (pt)
      PT_PAWN: return 100;
      PT_KNIGHT: return 320;
      PT_BISHOP: return 330;
      PT_ROOK: return 500;
      PT_QUEEN: return 900;
      default: return 0; //PT_NONE and PT_KING
    endcase
  endfunction

  function automatic logic [3:0] castle_keep(input logic [5:0] sq);
    case (sq)
      0: return 4'b1101; // a1: white queen_side
      4: return 4'b1100; // e1: both white rights
      7: return 4'b1110; /// h1: white king-side
      56: return 4'b0111; // a8: black queen_side
      60: return 4'b0011; // e8: both black rghts
      63: return 4'b1011; // black king side 
      default: return 4'b1111;
    endcase
  endfunction

  typedef struct packed {
    logic [3:0] flags; // bits 15:12
    square_t     to_sq; // bits 11:6
    square_t     from_sq; //bits 5:0
  } move_t;
  
endpackage
