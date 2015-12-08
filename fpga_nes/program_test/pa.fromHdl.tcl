
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name program_test -dir "C:/NESBoy/fpga_nes/program_test/planAhead_run_2" -part xc3s200ft256-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "decoder.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {decoder.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top decoder $srcset
add_files [list {decoder.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s200ft256-4
