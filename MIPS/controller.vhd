LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
USE work.memory_config.ALL;

entity controller is
    generic (word_length : natural);
    port (
			clk : in std_ulogic;
			ready : in std_ulogic;
			reset : in std_ulogic;
			cc : in cc_type;
				alias cc_n  : std_logic IS cc(2); -- negative
				alias cc_z  : std_logic IS cc(1); -- zero
				alias cc_v  : std_logic IS cc(0); -- overflow/compare
			control  : out control_bus;
			instr : in word;
			alu_out : out alu_code;
			alu_ready : in std_ulogic
			);
end controller;


architecture behaviour of controller is
    type register_file is array (0 to 31) 
    of word;
    signal current_instr : word;
			alias opcode : op_code IS current_instr(31 downto 26);
			alias rs : reg_code IS current_instr(25 downto 21);
			alias rt : reg_code IS current_instr(20 downto 16);
			alias rd : reg_code Is current_instr(15 downto 11);
			alias imm : hword IS current_instr(15 downto 0);
			alias rtype : op_code IS current_instr(5 downto 0);

begin
    current_instr <= instr;
    seq: process 
    begin
        if reset = '1' then
            control <= (others => '0');
            read <= '0';
            write <= '0';
            memory_location <= (others => '-');
            bus_out <= (others => '-');
            loop
              wait until clk = '1';
              exit when reset = '0';
            end loop;
        elsif(rising_edge(clk)) then
					control <= (read_mem => '1', others => '0'); 
					loop 
						wait until rising_edge(clk);
						exit when ready = '1';
					end loop;
					case opcode is --decode instruction
						when "00000"=>
						case rtype is 
							when nop  =>  assert false report "finished calculation" severity failure;
							when mfhi =>  control <= (rwrite => '1', spreg => '1', lohisel =>'1', others => '0');
							when mflo =>  control <= (rwrite => '1', spreg => '1', others => '0');
							when mult =>  
								control <= (alusrc => '1', rread => '1', others => '0');
								alu_out <= alu_mult;
								wait until alu_ready = '1';
							when div  =>  
								control <= (alusrc => '1', rread => '1', others => '0');
								alu_out <= alu_div;
								wait until alu_ready = '1'; 
							when orop =>  
								control <= (rread => '1', others => '0') -- move to alu inputs, 
								alu_out <= alu_or;
								wait until alu_ready = '1';
								control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
							when add  =>  
								control <= (rread => '1', others => '0') -- move to alu inputs, 
								alu_out <= alu_add;
								wait until alu_ready = '1';
								control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst

							when subop=>  
								control <= (rread => '1', others => '0') -- move to alu inputs, 
								alu_out <= alu_sub;
								wait until alu_ready = '1';
								control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst

							when slt  =>  
								control <= (rread => '1', others => '0') -- move to alu inputs, 
								alu_out <= alu_lt;
								wait until alu_ready = '1';
								control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst

							when others =>  
								control <= (others => '0');
								assert false report "illegal r-type instruction" severity warning;
						end case;
						when lw   => 
							control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
							alu_out <= alu_add;
							wait until alu_ready = '1';
							control <= (mread => '1', msrc => '1', others => '0'); --load word
							wait until ready = '1';
							control <= (rwrite => '1', wregsrc => '1', others => '0'); --write word to reg
						when sw   => 
							control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
							alu_out <= alu_add;
							wait until alu_ready = '1';
							control <= (mwrite => '1', msrc => '1', others => '0'); --load word
							wait until ready = '1';

						when beq  =>
							control <= (rread => '1', others => '0'); --calc addr
							alu_out <= alu_sub;
							wait until alu_ready = '1';
							if(cc_z = '1') then
								control <= (pcimm => '1', others => '0');
							end if;
						when bgez	=>
							control <= (rread => '1', others => '0'); --calc addr
							alu_out <= alu_gz;
							wait until alu_ready = '1';
							if(cc_v = '1') then
								control <= (pcimm => '1', others => '0');
							end if; 
						when ori	=>
							control <= (rread => '1', alusrc => '1', others => '0');
							alu_out <= alu_or;
							wait until alu_ready = '1';
							control <= (rwrite => '1', others => '0');
						when addi =>
							control <= (rread => '1', alusrc => '1', others => '0');
							alu_out <= alu_add;
							wait until alu_ready = '1';
							control <= (rwrite => '1', others => '0');
							
						when lui  =>
							control <= (rread => '1', alusrc => '1', immse => '1', others => '0');
							alu_out <= alu_add; -- works because in lui, rs is 0;
							wait until alu_ready = '1';
							control <= (rwrite => '1', others => '0');
						when others =>
							control <= (others => '0'); 
							assert false report "illegal instruction" severity warning;
					end case;
					
        end if;
    end process;
end behaviour;