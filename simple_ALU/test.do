force clk 0, 1 10ns -rep 20ns
force inst 0
force op1 00110
force op2 01010
force start 0
run 100ns
force reset 1
run 100ns
force reset 0
run
force start 1
run 20ns
force start 0
run 100ns
force inst 1
force start 1
run 20ns
force inst 0
force start 0
run 100ns
force start 1
force inst 1
run 60ns
force start 0
run 100ns