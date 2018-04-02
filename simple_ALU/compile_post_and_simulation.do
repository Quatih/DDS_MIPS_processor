# run the script compile_all.do before this script

# In the generated output files of quartus the name of the entity is changed
# to prevent a conflict with the entity name alu that is already
# in the working environment
# There is a difference. The generic value is really realized and is not
# part of the entity. An alternatieve is to rename the entity alu for synthesis.

# vdel -all
# vlib work
# do compile_all.do
#
# 
vcom alu_realization.vho 
vcom test_environment_realization.vhd
vsim -sdftyp /realization/=alu_vhd_fast.sdo -t ps work.test_environment(realization)