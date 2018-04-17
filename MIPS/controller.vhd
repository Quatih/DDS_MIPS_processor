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


architecture behaviour of controller is
	signal cc_reg : cc_type;
	alias cc_n : std_logic IS cc(2); -- negative
	alias cc_z : std_logic IS cc(1); -- zero
	alias cc_v : std_logic IS cc(0); -- overflow/compare
	signal control : control_bus;
begin
	ctrl_std <= ctlr2std(control);

	seq: process 
	  -- procedure to initiate alu
		procedure send_alu(alu_code : alu_instr) is
			begin
				
				loop -- wait until dp has finished
					wait until rising_edge(clk);
					control <= (others => '0');
					if reset = '1' then 
						return;
					end if;
					exit when ready = '1';
				end loop;
				alu_ctrl <= alu_code;
				alu_start <= '1';
				loop -- wait until alu is finished
				wait until rising_edge(clk);
					if reset = '1' then 
						return;
					end if;
					exit when alu_ready = '1';
				end loop;
				alu_start <= '0';
				alu_ctrl <= (others =>'-');
		end procedure;
	begin
		if reset = '1' then
			control <= (others => '0');
			alu_ctrl <= (others => '0');
			alu_start <= '0';
			cc_reg <= (others => '0');
			loop
				wait until clk = '1';
				exit when reset = '0';
			end loop;
		elsif(rising_edge(clk)) then
			control <= (mread => '1', pcincr => '1', others => '0'); 
			wait until rising_edge(clk);
			loop 
				wait until rising_edge(clk);
				control <= (others => '0');
				if reset = '1' then 
					exit seq;
				end if;
				exit when ready = '1';
			end loop;
			case opc is --decode instruction 
				when "000000"=> -- rtype instruction
				case rtopc is 
					when nop  => assert false report "finished calculation" severity failure;
					when mfhi => control <= (rwrite => '1', rspreg => '1', lohisel =>'1', others => '0');
					when mflo => control <= (rwrite => '1', rspreg => '1', lohisel =>'0', others => '0');
					when mult =>  
						control <= (alusrc => '1', rread => '1', others => '0');
						wait until rising_edge(clk);
						send_alu(alu_mult);
						control <= (wspreg => '1', others => '0');
					when div  =>  
						control <= (alusrc => '1', rread => '1', others => '0');
						wait until rising_edge(clk);
						send_alu(alu_mult);
						control <= (wspreg => '1', others => '0');
					when orop =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_or);
						control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
					when add  =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_add);
						cc_reg <= cc;
						if(cc_v = '1') then
							assert false report "overflow situation in arithmetic operation" severity 
							note;
						else
							control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
						end if;
					when subop=>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_sub);
						cc_reg <= cc;
						if(cc_v = '1') then
							assert false report "overflow situation in arithmetic operation" severity 
							note;
						else
							control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
						end if;
					when slt  =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_lt);
						control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst

					when others =>  
						control <= (others => '0');
						assert false report "illegal r-type instruction" severity warning;
				end case;
				when lw   => 
					control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
					send_alu(alu_add);
					control <= (mread => '1', msrc => '1', others => '0'); --load word, stored in rd
					wait until ready = '1';
				when sw   => 
					control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
					send_alu(alu_add);
					control <= (mwrite => '1', others => '0'); --save word
					wait until ready = '1';
				when beq  =>
					control <= (rread => '1', others => '0'); --calc addr
					send_alu(alu_sub);
					cc_reg <= cc;
					if(cc_v = '1') then 
						control <= (pcimm => '1', others => '0');
					end if;
				when bgez	=>
					control <= (rread => '1', others => '0'); --calc addr
					send_alu(alu_gz);
					cc_reg <= cc;
					if(cc_v = '1') then
						control <= (pcimm => '1', others => '0');
						wait until ready = '1';
					end if; 
				when ori	=>
					control <= (rread => '1', alusrc => '1', others => '0');
					send_alu(alu_or);
					control <= (rwrite => '1', others => '0');
				when addi =>
					control <= (rread => '1', alusrc => '1', others => '0');
					send_alu(alu_add);
					control <= (rwrite => '1', others => '0');
				when lui  =>
					control <= (rread => '1', alusrc => '1', immsl => '1', others => '0');
					send_alu(alu_add); -- works because in lui, rs is 0;
					control <= (rwrite => '1', others => '0');
				when others =>
					control <= (others => '0'); 
					assert false report "illegal instruction" severity warning;
			end case;
		end if;
	end process;
end behaviour;