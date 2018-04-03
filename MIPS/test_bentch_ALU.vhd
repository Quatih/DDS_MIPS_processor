LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity testbentch_ALU is 
end entity;

architecture behavior of testbentch_ALU is 

component ALU_design
				generic (datin_bus : integer := 32);
		PORT (
				result 			  : OUT std_logic_vector (2*datin_bus- 1 downto 0 );
				ready, cc		  : OUT std_logic;
				clk, start,reset : IN std_logic;
				inst 		  		  : IN std_logic_vector(2 downto 0);
				op1,op2		     : IN std_logic_vector(datin_bus-1 downto 0)  
				);
END component;
    SIGNAL result : std_logic_vector(63 downto 0);
		SIGNAL op1,op2 : std_logic_vector(31 downto 0);
		SIGNAL ready,cc               : std_logic;
		SIGNAL reset                          : std_ulogic := '1';
		SIGNAL clk ,start                           : std_ulogic := '0';
		SIGNAL inst : std_logic_vector(2 downto 0);
		BEGIN
					  ALU:ALU_design
							PORT MAP(result,ready,cc,clk,start,reset,inst,op1,op2);
						inst <= "001" , "000" After 1000 ns;	  
						op1 <= x"00000006", x"00000003" AFTER 1000 ns;
						op2 <= x"00000003", x"00000004" AFTER 1000 ns;  
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
