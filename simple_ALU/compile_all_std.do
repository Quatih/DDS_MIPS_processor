# compile order 
# The configuration (files that start with: cnf_...) can be 
# used to simulate the different design steps.
#
# packages
# vcom pkg_control_names.vhd
vcom pkg_control_names_v2.vhd
#
# controller
vcom controller.vhd
vcom controller-behaviour.vhd
vcom controller-fsm.vhd
# control with std_logic_vector in I/O
vcom controller_std.vhd;
vcom controller_std-behaviour.vhd
#
# datapath
vcom datapath.vhd
vcom datapath-rtl.vhd
# datapath with std_logic_vector in I/O
vcom datapath_std.vhd
vcom datapath_std-rtl.vhd
# alu
vcom alu.vhd
vcom alu-behaviour.vhd
vcom alu-algorithm.vhd
vcom alu-datapath_controller.vhd
# alue with std_logic_vector in I/O
vcom alu-datapath_controller_std.vhd
#
# test environment
vcom test_environment.vhd
vcom test_environment_behaviour.vhd
vcom test_environment_structure.vhd
#
# configuration
vcom cnf_behaviour.vhd
vcom cnf_algorithm.vhd
vcom cnf_controller_behaviour.vhd
vcom cnf_controller_fsm.vhd
vcom cnf_controller_behaviour_std.vhd

