LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;



ENTITY ALU_design IS
				generic (datin_bus : integer := 32);
		PORT (
				result 			  : OUT std_logic_vector (2*datin_bus- 1 downto 0 );
				ready, cc		  : OUT std_logic;
				clk, start,reset : IN std_logic;
				inst 		  		  : IN std_logic_vector(2 downto 0);
				op1,op2		     : IN std_logic_vector(datin_bus-1 downto 0)  
				);
END ALU_design;

ARCHITECTURE ALU OF AlU_design IS
     signal Z : std_logic_vector(2*datin_bus-1 downto 0) := (others => '0');
	  signal cci :  std_logic := '0';
	  signal readyi : std_logic := '0';
	  
Function multiply(op1,op2 : std_logic_vector) return std_logic_vector is 
begin
return std_logic_vector(unsigned(op1) * unsigned(op2));
end multiply;


begin
		process (clk,reset) 
		
		begin

		if (reset = '1') then
			Z <= (others => '0');
			readyi  <= '0';
			cci     <= '0';
		elsif (start = '1')
		then
			case inst is 
			 when "000" =>   Z <= std_logic_vector(x"00000000" & unsigned(op1) + unsigned(op2));			-----ADD 
 	     	 when "001" =>   Z <= multiply(op1,op2);					    	-----Mult
			 when "010" =>   Z <= std_logic_vector(x"00000000" & unsigned(op1) - unsigned(op2));			-----Subs
			 when "011" =>   Z <= std_logic_vector(x"00000000" & unsigned(op1) / unsigned(op2));			-----Div
			 when "100" =>   Z <= std_logic_vector(unsigned(op1) * unsigned(op2));							-----
			 when "101" =>   Z <= std_logic_vector(unsigned(op1) * unsigned(op2));							-----
			 when "110" =>   Z <= std_logic_vector(unsigned(op1) * unsigned(op2));							-----
			 when "111" =>   Z <= std_logic_vector(unsigned(op1) * unsigned(op2));							-----
			 when others =>  Z <= Z;																			----- all othere are cases
			 end case;
		END IF;
		end process;

		result 		<= Z;
--		op1i			<= op1;
--		op2i 			<= op2;
		cc 			<= cci;
		ready			<=  readyi;
END ALU;
  
