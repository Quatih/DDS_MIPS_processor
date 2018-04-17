LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;


entity boothmulti is 
		generic (datain_bus :integer := 32);
			PORT (
				result 			  : OUT std_logic_vector (2*datain_bus- 1 downto 0 );
				ready, cc		  : OUT std_logic;
				clk, start,reset : IN std_logic;
				inst 		  		  : IN std_logic_vector(2 downto 0);
				op1,op2		     : IN std_logic_vector(datain_bus-1 downto 0)  
				);
END boothmulti;

Architecture multiply of  boothmulti is 
			signal prod_result : std_logic_vector(2*datain_bus-1 downto 0):= (others=> '0');
			signal busy 		 : std_logic := '0';
			signal done			 : std_logic := '0';
begin			
			process
				variable multiplier  : std_logic_vector(datain_bus-1 		downto 0):= (others => '0');
				variable multiplicand: std_logic_vector(datain_bus-1 		downto 0):= (others => '0');
				variable prod_sft_add: std_logic_vector(2*datain_bus   downto 0):= (others => '0');
				variable minus_multi : std_logic_vector(datain_bus-1 		downto 0):= (others => '0' );
				variable i : integer range 0 to 31;
				--variable state_check : std_logic_vector(1 					downto 0):= (prod_sft_add(1) & prod_sft_add(0));
				begin
			wait until rising_edge(clk);
			   if (reset = '1') then
						multiplier  				  := op1;
						multiplicand 				  := op2;
						prod_sft_add(64 downto 33):= (others => '0');
						prod_sft_add(32 downto 1) := multiplier;
						prod_sft_add(0)			  := '0';
						minus_multi  := std_logic_vector(signed(not op2 ) + 1);
						--state_check  := (others => '0');
				elsif (start = '1' and reset = '0') then 
					if (i<32) then
					  busy <= '1';
					  case prod_sft_add(1 downto 0) is
					  when "00"|"11" => prod_sft_add := prod_sft_add(64) & prod_sft_add(64 downto 1);
					  when "01"      => prod_sft_add(64 downto 33) := std_logic_vector(signed(multiplier) + signed(multiplier) );
											  prod_sft_add := prod_sft_add(64) & prod_sft_add(64 downto 1);
					  when "10"      => prod_sft_add(64 downto 33) := std_logic_vector(signed(multiplier) - signed(minus_multi ) );
											  prod_sft_add := prod_sft_add(64) & prod_sft_add(64 downto 1);
					  when others => prod_sft_add := (others => '0');
					  end case;
					  i := i + 1;
					  end if;
					  busy <= '0';
				 else 
		           multiplier := (others => '1');
					  multiplicand := (others => '1');
					  prod_sft_add := (others => '1');
				 end if;
				 ready <= busy;
				end process;
end multiply;				