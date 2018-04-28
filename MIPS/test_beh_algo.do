vlib work


<<<<<<< HEAD
vcom memory_config.vhd
vcom memory_ent.vhd
vcom MIPS_Processor_types.vhd
vcom pkg_control_names_v2.vhd
vcom tb_dpc.vhd
vcom test_memory.vhd
vcom memory.vhd
vcom tb_cmp.vhd
vcom MIPS_Processor.vhd
vcom MIPS_Behaviour.vhd
vcom MIPS_Algorithm.vhd
vcom datapath.vhd
vcom datapath_rtl.vhd
vcom cnf_cmp_beh_algo.vhd
=======
vcom -quiet memory_config.vhd
vcom -quiet memory_ent.vhd
vcom -quiet MIPS_Processor_types.vhd
vcom -quiet pkg_control_names_v2.vhd
vcom -quiet tb_dpc.vhd
vcom -quiet test_memory.vhd
vcom -quiet memory.vhd
vcom -quiet tb_cmp.vhd
vcom -quiet MIPS_Processor.vhd
vcom -quiet MIPS_Behaviour.vhd
vcom -quiet MIPS_Algorithm.vhd
vcom -quiet datapath.vhd
vcom -quiet datapath_rtl.vhd
vcom -quiet cnf_cmp_beh_algo.vhd
>>>>>>> 48e8e6b4fb896c086dae76e8e0ce70f3d713f707

vsim cnf_cmp_beh_algo

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
suppress 3930 

add wave *
run -all