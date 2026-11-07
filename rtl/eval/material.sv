module material
 import chess_pkg::*;
 (
    input position_t pos,
    output score_t materials

);

function automatic int pop_count (bitboard_t number); // declared inside module static by default, count keeps value from previous call 
//second call would start counting form wherever first one eded. 
    int count = 0;
    for (int i = 0; i < 64; i++) begin
        if(number[i] == 1) begin
            count++;
        end
    end
    return count;
endfunction

always_comb begin
    int total;
    total = 0;
    for (int i = 0; i <= BB_QUEENS; i++) begin
        int white_pieces;
        int black_pieces;
        int add_up;
        white_pieces = pop_count(pos.bb[i] & pos.bb[BB_WHITE]);
        black_pieces = pop_count(pos.bb[i] & pos.bb[BB_BLACK]);

        add_up = (white_pieces - black_pieces) * piece_value(i + 1);
        total = total + add_up;
    end

    materials = score_t'(total);
end



endmodule
