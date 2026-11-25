# Build fpga_top for the A7-Lite in Vivado non-project mode.
# Run from the repo root:
#   C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat -mode batch -nojournal -log build\build.log -source scripts\build_a7lite.tcl
# Output: build\fpga_top.bit plus timing and utilization reports.

set root [file normalize [file join [file dirname [info script]] ..]]
set out  [file join $root build]
file mkdir $out

set srcs [list $root/rtl/common/chess_pkg.sv]
foreach d {move eval search top} {
    foreach f [lsort [glob -nocomplain $root/rtl/$d/*.sv]] {
        if {[file size $f] > 0} { lappend srcs $f }
    }
}
read_verilog -sv $srcs
read_xdc $root/constraints/a7lite.xdc

synth_design -top fpga_top -part xc7a100tfgg484-2
opt_design
place_design
phys_opt_design
route_design

report_timing_summary -max_paths 10 -file $out/timing.rpt
report_utilization -file $out/util.rpt
report_drc -file $out/drc.rpt

# Refuse to write a bitstream that misses timing: it might work on the bench and then fail warm.
set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "BUILD: worst setup slack = $wns ns"
if {$wns < 0} {
    puts "BUILD: ERROR timing not met, no bitstream written. See $out/timing.rpt"
    exit 1
}

write_bitstream -force $out/fpga_top.bit
puts "BUILD: wrote $out/fpga_top.bit"
