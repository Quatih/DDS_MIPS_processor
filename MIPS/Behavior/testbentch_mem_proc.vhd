LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity testbentch_mem_proc is 
end entity;

architecture behavior of testbentch_mem_proc is 

component memory  
		PORT(d_busout : OUT std_logic_vector(31 DOWNTO 0);
			d_busin  : IN  std_logic_vector(31 DOWNTO 0);
			a_bus    : IN  std_logic_vector(31 DOWNTO 0);
			clk      : IN  std_ulogic;
			write    : IN  std_ulogic;
			read     : IN  std_ulogic;
			ready    : OUT std_ulogic
			);
end component;

component MIPS_Processor
			generic (word_length : integer := 32 );
		PORT (
          clk : IN std_logic;
          reset : IN std_logic;
          bus_in : IN std_logic_vector(word_length-1 downto 0);
          bus_out : OUT std_logic_vector(word_length-1 downto 0);
          memory_location : OUT std_logic_vector(word_length-1 downto 0);
          read : OUT std_ulogic;
          write : OUT std_ulogic;
          ready : IN std_ulogic
          );
end component;			 
		SIGNAL data_from_cpu,data_to_cpu,addr : std_logic_vector(31 downto 0);
		SIGNAL read,write,ready               : std_ulogic;
		SIGNAL reset                          : std_ulogic := '1';
		SIGNAL clk                            : std_ulogic := '0';
		BEGIN
					  cpu:MIPS_Processor
							PORT MAP(clk,reset,data_to_cpu,data_from_cpu,addr,read,write,ready);
					  mem:memory
							--GENERIC MAP (1 ns)
							PORT MAP (data_from_cpu,data_to_cpu,addr,clk,write,read,ready);
					  reset <= '1', '0' AFTER 1000 ns;
					  clk   <= NOT clk AFTER 10 ns;
END behavior;
--				--------------------------------------------------------
--					CONFIGURATION test_of_mem_proc OF testbentch_mem_proc IS
--					  FOR behavior
--						 FOR cpu:MIPS_Processor USE ENTITY work.MipS_Processor; END FOR;
--						 FOR mem:memory USE ENTITY work.memory (behaviour); END FOR;
--					  END FOR;
--					END test_of_mem_proc;