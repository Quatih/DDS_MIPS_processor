vlib work


<<<<<<< HEAD
vcom memory_config.vhd
vcom memory_ent.vhd
vcom MIPS_Processor_types.vhd
vcom pkg_control_names_v2.vhd
vcom tb_dpc.vhd
vcom test_memory.vhd
vcom controller.vhd
vcom controller_behaviour.vhd
vcom memory.vhd
vcom ALU_design.vhd
vcom tb_controller_datapath.vhd
vcom tb_cmp.vhd
vcom MIPS_Processor.vhd
vcom MIPS_dp_ctrl.vhd
vcom MIPS_Behaviour.vhd
vcom datapath.vhd
vcom datapath_rtl.vhd
vcom cnf_cmp_beh_dprtl.vhd
=======
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
vcom -quiet datapath.vhd
vcom -quiet datapath_rtl.vhd
vcom -quiet cnf_cmp_beh_dprtl.vhd
>>>>>>> 48e8e6b4fb896c086dae76e8e0ce70f3d713f707

vsim cnf_cmp_beh_dprtl

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
suppress 3930 

add wave *
run -all