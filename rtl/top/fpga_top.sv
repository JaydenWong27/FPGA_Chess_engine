module fpga_top 
    import chess_pkg::*;
(
    input logic clk,
    input logic rst_btn_n,
    input logic uart_rx,
    output logic uart_tx,
    output logic [1:0] led
);

logic rst_s1, rst_n;

always_ff @(posedge clk) begin
    rst_s1 <= rst_btn_n;
    rst_n <= rst_s1;
end

logic [7:0] rx_data;
logic rx_valid;

logic [7:0] tx_data;
logic tx_start;

logic tx_busy;
logic start;
position_t root_pos;
logic [5:0] depth;
logic done;
move_t best_move;
score_t best_score;

uart_rx u_rx (
    .clk(clk),
    .rst_n(rst_n),
    .rx(uart_rx),
    .rx_data(rx_data),
    .rx_valid(rx_valid)
);

uart_tx u_tx (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(uart_tx),
    .tx_busy(tx_busy)
);

protocol u_proto (
    .clk(clk),
    .rst_n(rst_n),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .start(start),
    .root_pos(root_pos),
    .depth(depth),
    .done(done),
    .best_move(best_move),
    .best_score(best_score)
);

search_top #(
    .PST_FILE("pst_init.hex")
) u_search (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .root_pos(root_pos),
    .depth(depth),
    .done(done),
    .best_move(best_move),
    .best_score(best_score)
);

// LEDs on the A7-Lite light when the pin is low.
// led[0]: heartbeat (~1.5 Hz), shows the bitstream is loaded and the clock runs.
// led[1]: on while a search is running.
logic [24:0] beat = '0;
logic        busy;

always_ff @(posedge clk) begin
    beat <= beat + 1;
    if (!rst_n) begin
        busy <= 1'b0;
    end else if (start) begin
        busy <= 1'b1;
    end else if (done) begin
        busy <= 1'b0;
    end
end

assign led[0] = ~beat[24];
assign led[1] = ~busy;

endmodule