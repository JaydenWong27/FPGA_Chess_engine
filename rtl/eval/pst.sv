module pst 
import chess_pkg::*; 
#(
    parameter string PST_FILE = "pst_init.hex"

) (
    input logic clk,
    input logic rst_n,
    input logic start,
    input position_t pos,
    output logic done,
    output score_t pst
);

typedef enum logic [1:0] {
    IDLE = 2'b00,
    RUN = 2'b01,
    DONE = 2'b10
} state_t;

state_t state;
bitboard_t remaining;
position_t copy;
int signed acc;

logic signed [15:0] pst_rom [0:383] ; // $readmemh fills from left index with 383:0 line 0 of file end up in entry 383

bitboard_t mask;
logic [2:0] ptype;
logic is_black;
square_t sq;
logic [8:0] addr;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        case (state)
        IDLE: begin
            if (start) begin
                copy <= pos;
                remaining <= pos.bb[BB_WHITE] | pos.bb[BB_BLACK];
                acc <= 0;
                state <= RUN;
            end
        end

        RUN: begin
            if (remaining == 0) begin
                state <= DONE;
            end else begin
                if (is_black) begin
                    acc <= acc - pst_rom[addr];
                end else begin
                    acc <= acc + pst_rom[addr];
                end

                remaining <= remaining & (remaining - 1);
            end
        end


        DONE: begin
            state <= IDLE;
        end

        endcase

    end
end

function automatic [5:0] lsb(input logic [63:0] x);
    logic [5:0] position_last_one;
    position_last_one = '0;
    for (int i = 63; i >= 0; i--) begin
        if(x[i] == 1'b1) begin
            position_last_one = i;
        end
    end
    return position_last_one;
endfunction

always_comb begin
    mask = remaining & -remaining;
    ptype = 0;
    for (int i = 0; i <= 5; i++) begin
        if((copy.bb[i] & mask) != 0) begin
            ptype = i;
        end

    end
        is_black = (copy.bb[BB_BLACK] & mask) ? 1'b1 : '0;
        sq = lsb(remaining);
        if (is_black) begin
            addr = {ptype, sq ^ 6'd56};
        end else begin
            addr = {ptype , sq};
        end
end

initial 
$readmemh(PST_FILE, pst_rom);

assign done = (state == DONE);
assign pst = score_t'(acc);




endmodule