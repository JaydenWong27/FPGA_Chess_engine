module movegen_top 
import chess_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input logic start,
    input position_t pos,

    output logic move_valid,
    output move_t move,
    output logic done
);


    typedef enum logic [2:0] {
        IDLE = 3'b000,
        LOAD_TYPE = 3'b001,
        LOAD_FROM = 3'b010,
        EMIT = 3'b011,
        DONE = 3'b100
    } mg_state_t;

    mg_state_t state_t;

    function automatic [63:0] lsb(input logic [63:0] x);
        logic [5:0] position_last_one;
        position_last_one = '0;
        for (int i = 63; i >= 0; i--) begin
            if(x[i] == 1'b1) begin
                position_last_one = i;
            end
        end
        return position_last_one;
    endfunction



endmodule