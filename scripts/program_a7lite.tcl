# Load build/fpga_top.bit into the A7-Lite over the on-board USB-JTAG (lost on power-off).
# Run from the repo root:
#   C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat -mode batch -nojournal -nolog -source scripts\program_a7lite.tcl

set root [file normalize [file join [file dirname [info script]] ..]]
set bit  [file join $root build fpga_top.bit]
if {![file exists $bit]} {
    puts "PROGRAM: ERROR $bit not found, run scripts/build_a7lite.tcl first"
    exit 1
}

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "PROGRAM: targets = $targets"
if {[llength $targets] == 0} {
    puts "PROGRAM: ERROR no JTAG cable found; check the JTAG USB-C port and drivers"
    exit 1
}
current_hw_target [lindex $targets 0]
open_hw_target

set dev [lindex [get_hw_devices xc7a100t*] 0]
if {$dev eq ""} {
    puts "PROGRAM: ERROR no xc7a100t on the chain, found: [get_hw_devices]"
    exit 1
}
current_hw_device $dev
set_property PROGRAM.FILE $bit $dev
program_hw_devices $dev
puts "PROGRAM: done, DONE=[get_property REGISTER.CONFIG_STATUS.BIT14_DONE_PIN $dev]"
close_hw_target
