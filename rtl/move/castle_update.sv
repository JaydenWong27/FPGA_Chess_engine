module castle_update
    import chess_pkg::*;
(
    input logic [3:0] castle_in,
    input square_t from_sq,
    input square_t to_sq,
    output logic [3:0] castle_out

);

assign castle_out = castle_in & castle_keep(from_sq) & castle_keep(to_sq);

endmodule