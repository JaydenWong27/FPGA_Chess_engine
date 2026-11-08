module eval_top
    import chess_pkg::*;
#(
    parameter string PST_FILE = "pst_init.hex"
) (
    input  logic      clk,
    input  logic      rst_n,
    input  logic      start,     // pulse for one clock; pos is sampled on this clock
    input  position_t pos,
    output logic      done,      // high for one clock when score is ready
    output score_t    score,     // side to move's point of view
    output score_t    mat_score, // material, white's point of view (for the testbench)
    output score_t    pst_score  // PST sum, white's point of view (for the testbench)
);

    position_t copy;      // snapshot of pos taken on start; material reads this
    logic      pst_done;  // pst finished; score is registered on the next edge
    int        total;     // material + pst, negated when black is to move

    material u_material (
        .pos       (copy),
        .materials (mat_score)
    );

    // pst takes its own snapshot of pos on start, so it gets the live input
    pst #(
        .PST_FILE (PST_FILE)
    ) u_pst (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .pos   (pos),
        .done  (pst_done),
        .pst   (pst_score)
    );

    // All maths in int (32-bit signed); the conventions guarantee the result fits in 16 bits
    always_comb begin
        total = int'(mat_score) + int'(pst_score);
        if (copy.state.stm) begin
            total = -total;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            done <= 1'b0;
        end else begin
            if (start) begin
                copy <= pos;
            end

            if (pst_done) begin
                score <= score_t'(total);
                done  <= 1'b1;
            end else begin
                done  <= 1'b0;
            end
        end
    end

endmodule
