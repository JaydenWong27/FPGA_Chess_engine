# Write build/fpga_top.bit into the A7-Lite's QSPI flash (ISSI IS25LP128F, 16 MB) so the
# FPGA loads the chess engine by itself at power-up. This replaces whatever was in the flash
# (the factory demo, the first time).
# Run from the repo root:
#   C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat -mode batch -nojournal -log build\flash.log -source scripts\flash_a7lite.tcl

set root [file normalize [file join [file dirname [info script]] ..]]
set bit  [file join $root build fpga_top.bit]
set mcs  [file join $root build fpga_top.mcs]
if {![file exists $bit]} {
    puts "FLASH: ERROR $bit not found, run scripts/build_a7lite.tcl first"
    exit 1
}

# Flash image: bitstream at address 0, quad SPI (matches BITSTREAM.CONFIG.SPI_BUSWIDTH 4 in the XDC)
write_cfgmem -force -format mcs -size 16 -interface SPIx4 -loadbit "up 0x00000000 $bit" -file $mcs
puts "FLASH: wrote $mcs"

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
if {[llength $targets] == 0} {
    puts "FLASH: ERROR no JTAG cable found"
    exit 1
}
current_hw_target [lindex $targets 0]
open_hw_target
set dev [lindex [get_hw_devices xc7a100t*] 0]
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev

create_hw_cfgmem -hw_device $dev [lindex [get_cfgmem_parts {is25lp128f-spi-x1_x2_x4}] 0]
set mem [get_property PROGRAM.HW_CFGMEM $dev]
set_property PROGRAM.ADDRESS_RANGE  {use_file} $mem
set_property PROGRAM.FILES          [list $mcs] $mem
set_property PROGRAM.PRM_FILE       {} $mem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $mem
set_property PROGRAM.BLANK_CHECK    0 $mem
set_property PROGRAM.ERASE          1 $mem
set_property PROGRAM.CFG_PROGRAM    1 $mem
set_property PROGRAM.VERIFY         1 $mem
set_property PROGRAM.CHECKSUM       0 $mem

# Vivado programs the flash through the FPGA: it first loads a small SPI-programmer design
create_hw_bitstream -hw_device $dev [get_property PROGRAM.HW_CFGMEM_BITFILE $dev]
program_hw_devices $dev
refresh_hw_device $dev
program_hw_cfgmem -hw_cfgmem $mem
puts "FLASH: flash erased, programmed and verified"

# Reload the FPGA from flash, the same way it boots at power-up
boot_hw_device $dev
after 3000
refresh_hw_device -update_hw_probes false $dev
puts "FLASH: booted from flash, DONE=[get_property REGISTER.CONFIG_STATUS.BIT14_DONE_PIN $dev]"
close_hw_target
