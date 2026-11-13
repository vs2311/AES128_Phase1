# synth_report.tcl : synthesis ONLY (no board needed) to get area and timing numbers.
#
# Run after create_project.tcl, in the Vivado Tcl Console:
#     source synth_report.tcl
#
# The core has 260 I/O pins (128 key + 128 plaintext + control), more than a small
# FPGA package has, so it is synthesized "out of context" (as an IP block, no pins).
# This is the normal way to measure a core's area/timing before adding a wrapper
# (the UART wrapper comes in Phase 2).

set root [file normalize ..]
file mkdir reports

# 100 MHz target clock
set xdc [open reports/clock.xdc w]
puts $xdc "create_clock -period 10.000 -name clk \[get_ports clk\]"
close $xdc

read_verilog [glob $root/rtl/*.v]
read_xdc reports/clock.xdc
synth_design -top aes128_core -part xc7a35tcpg236-1 -mode out_of_context

report_utilization    -file reports/utilization_synth.txt
report_timing_summary -file reports/timing_synth.txt

puts "Reports written to vivado/reports/ : utilization_synth.txt, timing_synth.txt"
puts "Look for: Slice LUTs, Slice Registers (utilization) and WNS (timing; positive = meets 100 MHz)."
