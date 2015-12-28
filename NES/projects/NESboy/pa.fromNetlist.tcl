
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name NESboy -dir "C:/NESBoy/fpga_nes/NESboy/planAhead_run_2" -part xc6slx4tqg144-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/NESBoy/fpga_nes/NESboy/NES_Nexys4.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/NESBoy/fpga_nes/NESboy} }
set_property target_constrs_file "C:/NESBoy/verilog_files/fpganes-master/fpganes-master/src/Nexys4_Master.ucf" [current_fileset -constrset]
add_files [list {C:/NESBoy/verilog_files/fpganes-master/fpganes-master/src/Nexys4_Master.ucf}] -fileset [get_property constrset [current_run]]
link_design
