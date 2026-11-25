## MicroPhase A7-Lite (XC7A100T-2FGG484), pins from the A7-Lite R1.1 schematic.
## Banks 15 and 34 run at 3.3 V, so everything here is LVCMOS33.
## Bank 35 is the DDR3 at 1.5 V and is not used.

## 50 MHz oscillator U10 (clock-capable pin, bank 15)
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 20.000 -name clk [get_ports clk]

## Key K3, the board's RESET button: 10k pull-up, pressed = low
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports rst_btn_n]

## CH340E USB-UART: uart_tx goes to the CH340's RXD, uart_rx comes from its TXD
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports uart_rx]

## LED1 (D6) and LED2 (D5): 3.3 V -> LED -> 1k -> pin, so an LED is on when the pin is low
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

## The reset button and UART RX are asynchronous and go through 2-flop synchronizers;
## the outputs are slow (UART, LEDs). None of them need I/O timing.
set_false_path -from [get_ports {rst_btn_n uart_rx}]
set_false_path -to [get_ports {uart_tx led[*]}]

## Configuration bank is 3.3 V (CFGBVS tied to VCCO_0 = 3.3 V); flash is quad SPI
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
