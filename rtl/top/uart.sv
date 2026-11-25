module uart_tx
    import chess_pkg::*;
 #(
    parameter int CLK_HZ = 50_000_000,
    parameter int CLKS_PER_BIT = CLK_HZ / BAUD    
)(
    input logic clk,
    input logic rst_n,
    input logic tx_start,
    input logic [7:0] tx_data,
    output logic tx,
    output logic tx_busy
);


typedef enum logic [1:0] {
    IDLE = 2'b00,
    START = 2'b01,
    DATA = 2'b10,
    STOP = 2'b11
} state_t;

state_t state;

localparam int CNT_W = $clog2(CLKS_PER_BIT);
logic [CNT_W-1:0] clk_cnt;
logic [2:0] bit_idx;
logic [7:0] temp_reg;

assign tx_busy = (state != IDLE);

always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
        clk_cnt <= '0;
        bit_idx <= '0;
        tx <= 1'b1;
    end else begin
        case(state)
            IDLE: begin
                tx <= 1'b1;
                if (tx_start) begin
                    temp_reg <= tx_data;
                    state <= START;
                end else begin
                    temp_reg <= '0;
                    state <= IDLE;
                end
            end

            START: begin
                tx <= 1'b0;
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    state <= DATA;
                    clk_cnt <= 0;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            DATA: begin
                tx <= temp_reg[bit_idx];
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    clk_cnt <= '0;
                    if (bit_idx == 7) begin
                        bit_idx <= '0;
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            STOP: begin
                tx <= 1;
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    state <= IDLE;
                    clk_cnt <= '0;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
    endcase
    end
end

endmodule

module uart_rx 
    import chess_pkg::*;
 #(
    parameter int CLK_HZ = 50_000_000,
    parameter int CLKS_PER_BIT = CLK_HZ / BAUD 
)(
    input logic clk,
    input logic rst_n,
    input logic rx,
    output logic [7:0] rx_data,
    output logic rx_valid
);

logic rx_s1;
logic rx_s2;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        rx_s1 <= '1;
        rx_s2 <= '1;
    end else begin
        rx_s1 <= rx;
        rx_s2 <= rx_s1;
    end
end


typedef enum logic [1:0] {
    IDLE = 2'b00,
    START = 2'b01,
    DATA = 2'b10,
    STOP = 2'b11
} state_t;

state_t state;

localparam int CNT_W = $clog2(CLKS_PER_BIT);
localparam int HALF_BIT = CLKS_PER_BIT / 2;
logic [CNT_W-1:0] clk_cnt;
logic [2:0] bit_idx;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
        clk_cnt <= '0;
        bit_idx <= '0;
        rx_valid <= 1'b0;
    end else begin
        rx_valid <= 1'b0;

        case(state)
            IDLE: begin
                if (rx_s2 == 0) begin
                    state <= START;
                end
            end

            START: begin
                if (clk_cnt == HALF_BIT - 1) begin
                    if (rx_s2 == 0) begin
                        state <= DATA;
                        clk_cnt <= '0;
                    end else begin
                        state <= IDLE;
                        clk_cnt <= '0;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            DATA: begin
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    clk_cnt <= '0;
                    rx_data[bit_idx] <= rx_s2;
                    if (bit_idx == 7) begin
                        bit_idx <= '0;
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            STOP: begin
                if (clk_cnt == CLKS_PER_BIT-1) begin
                    state <= IDLE;
                    clk_cnt <= '0;
                    rx_valid <= 1;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
    endcase
    end
end



endmodule