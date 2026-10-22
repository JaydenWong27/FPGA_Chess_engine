package chess_pkg;
  localparam int MATE = 32000; // top of the mate band
  localparam int INF = 32001; // Search window limit
  localparam int DRAW = 0; // Stalemate 
  localparam int MAX_PLY = 64; // Stack frames 0-63
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
