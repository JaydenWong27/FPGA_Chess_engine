module slider_hq
    import chess_pkg::*;
(
    input square_t sq, //square
    input bitboard_t occ, // occupancy 
    output bitboard_t rook_att,
    output bitboard_t bishop_att

);

function automatic [63:0] rev64(input logic [63:0] x);
    logic [63:0] out;
    for (int i = 0; i < 64; i++) begin
        out[i] = x[63-i];
    end
    return out;
endfunction

function automatic [63:0] file_mask(input logic [5:0] sq);
    logic [63:0] file_masked;
    file_masked = '0;
    for (int i = 0; i < 64; i++) begin
        if ((i % 8 == sq % 8) && (i != sq)) begin
            file_masked[i] = 1;
        end
    end
    return file_masked;
endfunction

function automatic [63:0] rank_mask(input logic [5:0] sq);
    logic [63:0] rank_masked;
    rank_masked = '0;
    for (int i = 0; i < 64; i++) begin
        if ((i / 8 == sq / 8) && (i != sq)) begin
            rank_masked[i] = 1;
        end
    end
    return rank_masked;
endfunction

function automatic [63:0] diag_mask(input logic [5:0] sq);
    int file_sq, rank_sq, file_i, rank_i, diag_i;
    logic [63:0] diagonal_masked;

    file_sq = sq % 8;
    rank_sq = sq / 8;
    diagonal_masked = '0;

    for (int i = 0; i < 64; i++) begin
        file_i = i % 8;
        rank_i = i / 8;
        diag_i = rank_i - file_i;

        if ((diag_i == (rank_sq - file_sq)) && (i != sq)) begin
            diagonal_masked[i] = 1;
        end
    end
    return diagonal_masked;
endfunction

function automatic [63:0] anti_mask(input logic [5:0] sq);
    int file_sq, rank_sq, file_i, rank_i, diag_i;
    logic [63:0] anti_diagonal_masked;

    file_sq = sq % 8;
    rank_sq = sq / 8;
    anti_diagonal_masked = '0;

    for (int i = 0; i < 64; i++) begin
        file_i = i % 8;
        rank_i = i / 8;
        diag_i = rank_i + file_i;
        if ((diag_i == (rank_sq + file_sq)) && (i != sq)) begin
            anti_diagonal_masked[i] = 1;
        end
    end
    return anti_diagonal_masked;
endfunction

function automatic [63:0] line_att(input logic [5:0] sq, input logic [63:0] occ, input logic [63:0] mask);

    logic [63:0] o;
    logic [63:0] r;
    logic [63:0] att;

    o = occ & mask;

    r = 64'd1 << sq;

    att = ((o - 2*r) ^ rev64(rev64(o) - 2 * rev64(r))) & mask;

    return att;

endfunction

assign rook_att = line_att(sq, occ, file_mask(sq)) | line_att(sq, occ, rank_mask(sq));
assign bishop_att = line_att(sq, occ, diag_mask(sq)) | line_att(sq, occ, anti_mask(sq));


endmodule