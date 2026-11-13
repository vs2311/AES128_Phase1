# create_project.tcl : builds the Vivado project and runs the main simulation.
#
# How to use (Vivado 2020.x or newer):
#   1. Open Vivado.
#   2. In the Tcl Console at the bottom, type:
#        cd <path-to>/AES128_Phase1/vivado
#        source create_project.tcl
#   3. The simulator opens, runs tb_aes128_core, and prints results in the Tcl Console.
#
# Part number: Artix-7 xc7a35t (Basys3). Simulation does not need a board,
# so any part works; change it if your lab uses another FPGA.

set proj_name aes128_phase1
set proj_dir  [file normalize ./$proj_name]
set root      [file normalize ..]

create_project $proj_name $proj_dir -part xc7a35tcpg236-1 -force

# Design sources
add_files -norecurse [glob $root/rtl/*.v]
set_property top aes128_core [current_fileset]

# Simulation sources (testbenches + test vector memory file)
add_files -fileset sim_1 -norecurse [glob $root/tb/*.v]
add_files -fileset sim_1 -norecurse $root/tb/test_vectors.mem
set_property top tb_aes128_core [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation
# Add the most useful signals to the waveform window
catch {
    add_wave {{/tb_aes128_core/clk}} {{/tb_aes128_core/start}} {{/tb_aes128_core/busy}} \
             {{/tb_aes128_core/done}} {{/tb_aes128_core/dut/round}} \
             {{/tb_aes128_core/dut/state}} {{/tb_aes128_core/dut/round_key}} \
             {{/tb_aes128_core/ciphertext}}
    restart
    run all
}
puts "Simulation finished. sim_results.txt is in: $proj_dir/$proj_name.sim/sim_1/behav/xsim/"
