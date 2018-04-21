library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;
entity controller is
	generic (word_length : natural);
	port (
		clk 			: in 	std_ulogic;
		reset 		: in	std_ulogic;
		ctrl_std  : out std_logic_vector(0 to control_bus'length-1);
		ready			: in 	std_ulogic;
		opc       : in 	op_code;
		rtopc     : in 	op_code;
		cc 				: in 	cc_type;
		alu_ctrl 	: out alu_instr;
		alu_ready : in 	std_ulogic;
		alu_start : out std_ulogic
		);
end controller;
