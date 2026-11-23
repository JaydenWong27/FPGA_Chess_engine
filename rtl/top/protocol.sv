module protocol
    import chess_pkg::*;
(
    input logic clk,
    input logic rst_n,

    // from uart_rx
    input logic [7:0] rx_data,
    input logic rx_valid,

    // to/from uart_tx
    output logic [7:0] tx_data,
    output logic tx_start,
    input logic tx_busy,

    // to/from search_top
    output logic start,
    output position_t root_pos,
    output logic [5:0] depth,
    input logic done,
    input move_t best_move,
    input score_t best_score
);

    typedef enum logic [2:0] {
        WAIT_HDR = 3'b000,
        GET_DEPTH = 3'b001,
        GET_POS = 3'b010,
        GO = 3'b011,
        WAIT_DONE = 3'b100,
        SEND = 3'b101,
        SEND_WAIT = 3'b110 
    } state_t;

    state_t state;
    logic [6:0] byte_cnt;
    logic [39:0] out_buf;

    assign start = (state == GO);
    assign tx_start = (state == SEND) && !tx_busy;
    assign tx_data = out_buf[39:32];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= WAIT_HDR;
            byte_cnt <= '0;
        end else begin
            case (state)
                WAIT_HDR: begin
                if (rx_valid && rx_data == 8'hA5) begin
                    state <= GET_DEPTH;
                    end
                end

                GET_DEPTH: if (rx_valid) begin
                    depth <= rx_data[5:0];
                    byte_cnt <= '0;
                    state <= GET_POS;
                end

                GET_POS: if (rx_valid) begin
                    root_pos <= {root_pos[519:0], rx_data};
                    if (byte_cnt == 65) begin
                        state <= GO;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end

                GO: begin
                    state <= WAIT_DONE;
                end

                WAIT_DONE: if (done) begin
                    out_buf <= {8'h5A, best_move, best_score};
                    byte_cnt <= '0;
                    state <= SEND;
                end

                SEND: begin
                    if (!tx_busy) begin
                        state <= SEND_WAIT;
                    end
                end

                SEND_WAIT: if (!tx_busy) begin
                    out_buf <= {out_buf[31:0], 8'h00};
                    if (byte_cnt == 4) begin
                        state <= WAIT_HDR;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                        state <= SEND;
                    end
                end

            endcase
        end
    end

endmodule