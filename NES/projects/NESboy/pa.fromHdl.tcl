
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name NESboy -dir "C:/NESBoy/fpga_nes/NESboy/planAhead_run_1" -part xc6slx4tqg144-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "C:/NESBoy/verilog_files/fpganes-master/fpganes-master/src/Nexys4_Master.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {../../verilog_files/fpganes-master/fpganes-master/src/dsp.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set_property top FirFilter $srcset
add_files [list {C:/NESBoy/verilog_files/fpganes-master/fpganes-master/src/Nexys4_Master.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx4tqg144-3
