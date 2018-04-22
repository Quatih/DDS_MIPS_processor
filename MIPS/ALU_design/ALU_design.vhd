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


<<<<<<< HEAD

	procedure mult_booth(	op1, op2 	: in std_logic_vector;
		signal result : out std_logic_vector(63 downto 0)) is
		variable mult1, mult2, minus_multi : signed (32-1 downto 0);
		variable prod_sft_add : std_logic_vector(32*2 downto 0);
		constant ub : natural := 32*2; -- upper bound
		constant lb : natural := 32+1; -- lower bound
		constant word_length : integer :=32;
	begin
		mult1 := signed(op1);
		mult2 := signed(op2);
		prod_sft_add(ub downto lb) := (others => '0');
		prod_sft_add(word_length downto 1) := std_logic_vector(mult1);
		prod_sft_add(0) := '0';
		minus_multi := signed(op2 );
		for i in 0 to word_length-1 loop
=======
>>>>>>> f8eebf5a6e49668e2e1131230b24b7e5ae2a661e


	procedure mult_booth(	op1, op2 	: in std_logic_vector;
		signal result : out signed (word_length*2 -1 downto 0)) is
				variable mult1, mult2, minus_multi : signed (word_length-1 downto 0);
				variable prod_sft_add : std_logic_vector(word_length*2 downto 0);
				constant ub : natural := word_length*2; -- upper bound
				constant lb : natural := word_length+1; -- lower bound
				begin
				mult1 := signed(op1);
				mult2 := signed(op2);
				prod_sft_add(ub downto lb) := (others => '0');
				prod_sft_add(word_length downto 1) := std_logic_vector(mult1);
				prod_sft_add(0) := '0';
				minus_multi := signed(op2 );
				for i in 0 to word_length-1 loop
				wait until falling_edge(clk);
				case prod_sft_add(1 downto 0) is
				when "00"|"11" => 
				prod_sft_add := prod_sft_add(ub) & prod_sft_add(ub downto 1);
				when "01"      => 
				prod_sft_add(ub downto lb) := std_logic_vector(signed(prod_sft_add(ub downto lb)) + mult2);
				prod_sft_add := prod_sft_add(ub) & prod_sft_add(ub downto 1);
				when "10"      => 
<<<<<<< HEAD
					prod_sft_add(ub downto lb) := std_logic_vector(signed(prod_sft_add(ub downto lb)) - minus_multi);
					prod_sft_add := prod_sft_add(ub) & prod_sft_add(ub downto 1);
				when others => prod_sft_add := prod_sft_add; 
			end case;
		end loop;
		result <= signed(std_logic_vector(prod_sft_add(ub downto 1))); 
	end mult_booth;

	procedure division( op1, op2 	: in std_logic_vector(31 downto 0);
	signal result : out std_logic_vector(64-1 downto 0)) is

		Variable q         : std_logic_vector(31 downto 0);
		Variable m         : std_logic_vector(32 downto 0);
		Variable a         : std_logic_vector(32 downto 0);
		variable count     : integer ;
		constant r_size    : integer := 32;
		Variable y         : integer;
		Variable z         : integer;
		Variable j         : std_logic_vector(31 downto 0);
		Variable k         : std_logic_vector(31 downto 0);
		Variable Quo_inter : std_logic_vector(31 downto 0) ;
		Variable remin     : std_logic_vector(31 downto 0) ;
		Variable Quo       : std_logic_vector(31 downto 0) ;
				
	begin
		y:= to_integer(signed(op1));
		z:= to_integer(signed(op2)); 
		j := std_logic_vector(to_unsigned(y, j'length));        					
		k := std_logic_vector(to_unsigned(z, k'length));       						   
		q := j;
		m := std_logic_vector(resize(signed(k),m'length));
		a := (others => '0');
		count := m'length-1;

		---Non-restoring division algorithm
		for i in 0 to count-1 loop																					
			if(a(r_size) = '1') then
				a(r_size downto 0)   := a(r_size-1 downto 0)&q(r_size-1);
				q(r_size-1 downto 0) := q(r_size-2 downto 0)&'0';
				a                    := std_logic_vector(signed(a) + signed(m));
				if(a(r_size) = '0') then
					q(0) := '1';
				else
					q(0) := '0';
				end if;   
				count := count-1;
				else 
				a(r_size downto 0)   := a(r_size-1 downto 0)&q(r_size-1);
				q(r_size-1 downto 0) := q(r_size-2 downto 0)&'0';
				a                    := std_logic_vector(signed(a) - signed(m));
				if(a(r_size) = '0') then
					q(0) := '1';
				else
					q(0) := '0';
				end if;   
				count := count-1;
			end if;
		end loop;

		---Reminder and Quotient correction
		if(a(r_size) = '1') then													
				a         :=std_logic_vector(signed(a) + signed(m));
				Quo_inter := q;
				remin     := a(r_size-1 downto 0);
		else
				Quo_inter := q;
				remin     := a(r_size-1 downto 0);
		end if;  		
		if(y<0) then
			if(z<0) then
				Quo := Quo_inter;
			else 
				Quo := std_logic_vector(unsigned((not Quo_inter)) + 1);
			end if;
		else
			if(z<0) then
			Quo := std_logic_vector(unsigned((not Quo_inter)) + 1);
			else
				Quo := Quo_inter;
			end if;
		end if;  
		
		---Final result stored in result(63 downto 0) 
		result(63 downto 32) <= (remin);
		result(31 downto 0)  <= (Quo);
		wait;

	end procedure;		




=======
				prod_sft_add(ub downto lb) := std_logic_vector(signed(prod_sft_add(ub downto lb)) - minus_multi);
				prod_sft_add := prod_sft_add(ub) & prod_sft_add(ub downto 1);
				when others => prod_sft_add := (others => '0'); 
				end case;
				end loop;
				result <= signed(prod_sft_add(ub downto 1)); -- result is where??
	end mult_booth;
>>>>>>> f8eebf5a6e49668e2e1131230b24b7e5ae2a661e
begin
	seq: process
		variable lop1, lop2 : signed(word_length*2-1 downto 0) := (others => '0');
		variable sresult : integer;
		
		procedure set_cc(data : in integer;
										signal cc : out cc_type) is
			constant low  : integer := -2**(word_length - 1);
			constant high : integer := 2**(word_length - 1) - 1;
		begin
			if (data<low) or (data>high)
			then -- overflow
				assert false report "overflow situation in arithmetic operation" severity 
				note;
				cc_v<='1'; cc_n<='-'; cc_z<='-'; -- correct?
			else
				cc_v<='0'; 
				if(data <0) then
					cc_n<='1';
				else
					cc_n <= '0';
				end if; 
				if(data = 0) then
					cc_z <= '1';
				else
					cc_z <= '0';       
				end if;
			end if;
		end set_cc;
	begin

	if reset = '1' then
		calc <= (others => '0');
		readyi  <= '0';
		cci     <= (others => '0');
		loop
			wait until rising_edge(clk);
			exit when reset = '0';
		end loop;
	end if;
	wait until rising_edge(clk);
	if start = '1' then
		readyi <= '0';
		lop1(word_length-1 downto 0) := signed(op1);
		lop1(word_length*2-1 downto word_length) := (others => op1(31));
		lop2(word_length-1 downto 0) := signed(op2);
		lop2(word_length*2-1 downto word_length) := (others => op2(31));
		case inst is
			when alu_add => sresult := to_integer(signed(op1) + signed(op2));
											set_cc(sresult,cci);
											calc <= to_signed(sresult, word_length*2);
		when alu_mult => 	
											--sresult := to_integer(signed(op1)*signed(op2));
											--set_cc(sresult, cci);
											--calc <= to_signed(sresult, word_length*2);
											mult_booth(op1, op2, calc);
											set_cc(to_integer(calc),cci);
		when alu_sub 	=> 	sresult := to_integer(signed(op1) - signed(op2));
											calc <= to_signed(sresult, word_length*2);
											set_cc(sresult,cci);
		when alu_div =>   calc(word_length*2-1 downto word_length) <= signed(op1) mod signed(op2);
											calc(word_length-1 downto 0) <= signed(op1) / signed(op2);
											set_cc(to_integer(calc),cci);
		when alu_or 	=> 	calc(word_length-1 downto 0) <= signed(op1 or op2);
											set_cc(to_integer(calc),cci);
		when alu_and 	=> 	calc(word_length-1 downto 0) <= signed(op1 and op2);
											set_cc(to_integer(calc),cci);
		when alu_lt		=> 	
											if(signed(op1) < signed(op2)) then
												calc <= to_signed(1, word_length*2);
												cc_v <= '1';
											else
												calc <= to_signed(0, word_length*2);
												cc_v <= '0';
											end if;
		when alu_gz	=> 		if(signed(op1) >= zero) then
												cc_v <= '1';
											else
												cc_v <= '0';
											end if;
											calc <= (others => '-'); -- don't care what the output is in this case
		when others 	=> 	assert false report "Invalid alu instruction" severity warning;
		end case;
		--wait until rising_edge(clk); -- to make sure outputs are stable?
		readyi <= '1';
	else
		readyi <= '0';
	end if;
	end process;

	result 		<= std_logic_vector(calc);
--		op1i			<= op1;
--		op2i 			<= op2;
	cc 			<= cci;
	ready			<=  readyi;
end alu;
  
