# compile order 
# The configuration (files that start with: cnf_...) can be 
# used to simulate the different design steps.
#
# packages
vcom pkg_control_names.vhd
#
# controller
vcom controller.vhd
vcom controller-behaviour.vhd
vcom controller-fsm.vhd
#
# datapath
vcom datapath.vhd
vcom datapath-rtl.vhd

# alu
vcom alu.vhd
vcom alu-behaviour.vhd
vcom alu-algorithm.vhd
vcom alu-datapath_controller.vhd
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

