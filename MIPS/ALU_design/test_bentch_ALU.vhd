LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.processor_types.all;

entity testbentch_ALU is 
end entity;

architecture behavior of testbentch_ALU is 
component alu_design
				generic (word_length : integer := 32);
		PORT (
				result 			       : OUT std_logic_vector (2*word_length- 1 downto 0 );
				ready		          : out std_logic;
				cc 				         : out cc_type;
				clk, start,reset : IN std_logic;
				inst 		  		      : IN alu_instr;
				op1,op2		        : IN std_logic_vector(word_length-1 downto 0)  
				);
END component;
    SIGNAL result : std_logic_vector(63 downto 0);
		SIGNAL op1,op2 : std_logic_vector(31 downto 0);
		SIGNAL ready                         : std_logic;
		signal cc                            : cc_type;
		SIGNAL reset                          : std_ulogic := '1';
		SIGNAL clk ,start                           : std_ulogic := '0';
		SIGNAL inst : std_logic_vector(2 downto 0);
		BEGIN
					  ALU:ALU_design
							PORT MAP(result,ready,cc,clk,start,reset,inst,op1,op2);
						inst <= "001" , "000" After 1000 ns;	  
						op1 <= x"0001_500A", x"00000003" AFTER 1000 ns;
						op2 <= x"0001_500A", x"00000004" AFTER 1000 ns;  
					  reset <= '1', '0' AFTER 100 ns;
					  clk   <= NOT clk AFTER 10 ns;
					  start <= '1', '0' After 500 ns;

END behavior;
--				--------------------------------------------------------
--					CONFIGURATION test_of_mem_proc OF testbentch_mem_proc IS
--					  FOR behavior
--						 FOR cpu:MIPS_Processor USE ENTITY work.MipS_Processor; END FOR;
--						 FOR mem:memory USE ENTITY work.memory (behaviour); END FOR;
--					  END FOR;
--					END test_of_mem_proc;
