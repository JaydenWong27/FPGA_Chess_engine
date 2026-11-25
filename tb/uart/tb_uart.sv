`timescale 1ns/1ps
module tb_uart;
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    logic rst_n;
    logic tx_start;
    logic [7:0] tx_data;
    logic line;
    logic tx_busy;
    logic [7:0] rx_data;
    logic rx_valid;

    int errors;

    uart_tx #(
        .CLKS_PER_BIT(8)) 
        u_tx ( 
            .clk(clk), 
            .rst_n(rst_n), 
            .tx_start(tx_start), 
            .tx_data(tx_data), 
            .tx(line), 
            .tx_busy(tx_busy) 
            );

    uart_rx #(
        .CLKS_PER_BIT(8)) 
        u_rx ( 
            .clk(clk), 
            .rst_n(rst_n), 
            .rx(line), 
            .rx_data(rx_data), 
            .rx_valid(rx_valid) 
            );

            initial begin
                rst_n    = 0;
                tx_start = 0;
                repeat (5) @(posedge clk);   // <- ; here: just wait
                rst_n = 1;
            end

            initial begin
                errors = 0;
                wait (rst_n === 1);

                for (int b = 0; b < 256; b++) begin
                    @(negedge clk);
                    tx_data = b;
                    tx_start = 1;
                    @(negedge clk);
                    tx_start = 0;


                    fork
                        @(posedge clk iff rx_valid === 1);
                        begin
                            repeat (200) @(posedge clk);
                            $error("timeout on byte %02h", b);
                            errors++;

                        end
                    join_any
                    disable fork;

                    if (rx_data !== b[7:0]) begin
                        errors++;
                        $error("byte %02h: got %02h", b[7:0], rx_data);
                    end

                    wait (tx_busy == 0);
                end

                if (errors == 0) begin
                    $display("PASS");
                end else begin
                    $display("FAIL: %0d errors", errors);
                end
                
                $finish;
            end
            
endmodule
