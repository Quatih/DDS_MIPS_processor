vlib work


vcom -quiet memory_config.vhd
vcom -quiet memory_ent.vhd
vcom -quiet MIPS_Processor_types.vhd
vcom -quiet pkg_control_names_v2.vhd
vcom -quiet tb_dpc.vhd
vcom -quiet test_memory.vhd
vcom -quiet controller.vhd
vcom -quiet controller_behaviour.vhd
vcom -quiet memory.vhd
vcom -quiet ALU_design.vhd
vcom -quiet tb_controller_datapath.vhd
vcom -quiet tb_cmp.vhd
vcom -quiet MIPS_Processor.vhd
vcom -quiet MIPS_dp_ctrl.vhd
vcom -quiet MIPS_Behaviour.vhd
vcom -quiet datapath.vho
vcom -quiet cnf_cmp_beh_dpsynth.vhd

vsim cnf_cmp_beh_dpsynth

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
suppress 3930 

add wave *
run -all