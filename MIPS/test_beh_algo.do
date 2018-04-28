vlib work


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

vsim cnf_cmp_beh_algo

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
suppress 3930 

add wave *
run -all