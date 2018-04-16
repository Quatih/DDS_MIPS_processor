library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;
entity controller is
	generic (word_length : natural);
	port (
		clk 			: in std_ulogic;
		reset 		: in std_ulogic;
		ctrl_std  : out std_logic_vector(0 to control_bus'length-1);
		ready			: in std_ulogic;
		opc       : in op_code;
		rtopc     : in op_code;
		cc 				: in cc_type;
		alu_ctrl 	: out cc_type;
		alu_ready : in std_ulogic
		);
end controller;


architecture behaviour of controller is
	alias cc_n : std_logic IS cc(2); -- negative
	alias cc_z : std_logic IS cc(1); -- zero
	alias cc_v : std_logic IS cc(0); -- overflow/compare
	signal control : control_bus;
begin
	ctrl_std <= ctlr2std(control);

	seq: process 
	begin
		if reset = '1' then
			control <= (others => '0');
			alu_ctrl <= (others =>'0');
			loop
				wait until clk = '1';
				exit when reset = '0';
			end loop;
		elsif(rising_edge(clk)) then
			control <= (mread => '1', others => '0'); 
			loop 
				wait until rising_edge(clk);
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
						alu_ctrl <= alu_mult;
						wait until alu_ready = '1'; -- when alu has finished mult, result is stored in special registers
						control <= (wspreg => '1', others => '0');
					when div  =>  
						control <= (alusrc => '1', rread => '1', others => '0');
						wait until rising_edge(clk);
						alu_ctrl <= alu_mult;
						wait until alu_ready = '1'; -- when alu has finished mult, result is stored in special registers
						control <= (wspreg => '1', others => '0');
					when orop =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						alu_ctrl <= alu_or;
						wait until alu_ready = '1';
						control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
					when add  =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						alu_ctrl <= alu_add;
						wait until alu_ready = '1';
						if(cc_v = '1') then
							assert false report "overflow situation in arithmetic operation" severity 
							note;
						else
							control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
						end if;
					when subop=>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						alu_ctrl <= alu_sub;
						wait until alu_ready = '1';
						if(cc_v = '1') then
							assert false report "overflow situation in arithmetic operation" severity 
							note;
						else
							control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
						end if;
					when slt  =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						alu_ctrl <= alu_lt;
						wait until alu_ready = '1';
						control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst

					when others =>  
						control <= (others => '0');
						assert false report "illegal r-type instruction" severity warning;
				end case;
				when lw   => 
					control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
					alu_ctrl <= alu_add;
					wait until alu_ready = '1';
					control <= (mread => '1', msrc => '1', others => '0'); --load word, stored in rd
				when sw   => 
					control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
					alu_ctrl <= alu_add;
					wait until alu_ready = '1';
					control <= (mwrite => '1', others => '0'); --save word
					wait until ready = '1';

				when beq  =>
					control <= (rread => '1', others => '0'); --calc addr
					alu_ctrl <= alu_sub;
					wait until alu_ready = '1';
					if(cc_z = '1') then
						control <= (pcimm => '1', others => '0');
					end if;
				when bgez	=>
					control <= (rread => '1', others => '0'); --calc addr
					alu_ctrl <= alu_gz;
					wait until alu_ready = '1';
					if(cc_v = '1') then
						control <= (pcimm => '1', others => '0');
					end if; 
				when ori	=>
					control <= (rread => '1', alusrc => '1', others => '0');
					alu_ctrl <= alu_or;
					wait until alu_ready = '1';
					control <= (rwrite => '1', others => '0');
				when addi =>
					control <= (rread => '1', alusrc => '1', others => '0');
					alu_ctrl <= alu_add;
					wait until alu_ready = '1';
					control <= (rwrite => '1', others => '0');
					
				when lui  =>
					control <= (rread => '1', alusrc => '1', immse => '1', others => '0');
					alu_ctrl <= alu_add; -- works because in lui, rs is 0;
					wait until alu_ready = '1';
					control <= (rwrite => '1', others => '0');
				when others =>
					control <= (others => '0'); 
					assert false report "illegal instruction" severity warning;
			end case;
		end if;
	end process;
end behaviour;