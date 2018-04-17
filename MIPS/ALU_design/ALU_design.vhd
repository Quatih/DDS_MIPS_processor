library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;

entity alu_design is
		generic (word_length : integer := 32);
		port (
				result 		: out std_logic_vector (2*word_length- 1 downto 0 );
				ready		  : out std_logic;
				cc 				: out cc_type;
				clk, start,reset : in std_logic;
				inst 		  : in alu_instr;
				op1, op2 	: in std_logic_vector(word_length-1 downto 0)  
				);
end alu_design;

architecture alu of alu_design is

	signal calc 	: signed (2*word_length-1 downto 0);
	signal cci 		:  cc_type;
		alias cc_n 	: std_logic IS cci(2); -- negative
		alias cc_z 	: std_logic IS cci(1); -- zero
		alias cc_v 	: std_logic IS cci(0); -- overflow/compare
	signal readyi : std_logic := '0';
	constant zero : signed(31 downto 0) := (others => '0');

	function multiply(op1,op2 : std_logic_vector) return signed is 
	begin
		return signed(op1) * signed(op2);
	end multiply;

	procedure set_cc(check : in signed;
									signal cc : out cc_type) is
		alias cc_n : std_logic IS cc(2); -- negative
		alias cc_z : std_logic IS cc(1); -- zero
		alias cc_v : std_logic IS cc(0); -- overflow/compare
		constant low  : integer := -2**(word_length - 1);
		constant high : integer := 2**(word_length - 1) - 1;
	begin
		if(check < 0) then
			cc_n <= '1';
		else
			cc_n <= '0';
		end if;
		if(check = 0) then
			cc_z <= '1';
		else
			cc_z <= '0';
		end if;
		if(check > high) or (check < low) then
			cc_v <= '1';
		else 
			cc_v <= '0';
		end if;
	end set_cc;

begin
	seq: process
	begin

	if reset = '1' then
		calc <= (others => '0');
		readyi  <= '0';
		cci     <= (others => '0');
	end if;
	wait until rising_edge(clk);
	if start = '1' then
		case inst is
			when alu_add => 	calc <= signed(op1) + signed(op2);
											set_cc(calc,cc);
		when alu_mult => 	calc <= multiply(op1,op2);
											set_cc(calc,cc);
		when alu_sub 	=> 	calc <= signed(op1) - signed(op2);
											set_cc(calc,cc);
		when alu_div =>   calc(word_length*2-1 downto word_length) <= signed(op1) mod signed(op2);
											calc(word_length-1 downto 0) <= signed(op1) / signed(op2);
											set_cc(calc,cc);
		when alu_or 	=> 	calc(word_length-1 downto 0) <= signed(op1 or op2);
											set_cc(calc,cc);
		when alu_and 	=> 	calc(word_length-1 downto 0) <= signed(op1 and op2);
											set_cc(calc,cc);
		when alu_lt		=> 	if(signed(op1) < signed(op2)) then
												calc <= to_signed(1, word_length*2);
												cc_v <= '1';
											else
												calc <= to_signed(0, word_length*2);
												cc_v <= '1';
											end if;
		when alu_gz	=> 		if(signed(op1) >= zero) then
												cc_v <= '1';
											else
												cc_v <= '0';
											end if;
											calc <= (others => '-'); -- don't care what the output is in this case
		when others 	=> 	assert false report "Invalid alu instruction" severity warning;
		end case;
		wait until rising_edge(clk); -- to make sure outputs are stable?
		readyi <= '1';
	end if;
	end process;

	result 		<= std_logic_vector(calc);
--		op1i			<= op1;
--		op2i 			<= op2;
	cc 			<= cci;
	ready			<=  readyi;
end alu;
  
