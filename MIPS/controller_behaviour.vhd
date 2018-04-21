

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
				wait until rising_edge(clk);
				alu_ctrl <= alu_code;
				alu_start <= '1';
				loop -- wait until alu is finished
				wait until rising_edge(clk);
					if reset = '1' then 
						return;
					end if;
					alu_start <= '0';
					exit when alu_ready = '1';
				end loop;
				alu_start <= '0';
				alu_ctrl <= (others =>'-');
		end procedure;

		procedure wait_dp is
		begin
			loop 
				wait until rising_edge(clk);
				control <= (others => '0');
				if reset = '1' then 
					exit;
				end if;
				exit when ready = '1';
			end loop;
		end procedure;
	begin
		if reset = '1' then
			control <= (others => '0');
			alu_ctrl <= (others => '0');
			alu_start <= '0';
			cc_reg <= (others => '0');
			loop
				wait until rising_edge(clk);
				exit when reset = '0';
			end loop;
		end if;
		if(rising_edge(clk)) then
			control <= (mread => '1', pcincr => '1', others => '0'); 
			wait_dp;
			case opc is --decode instruction 
				when "000000"=> -- rtype instruction
				case rtopc is 
					when nop  => assert false report "finished calculation" severity failure;
					when mfhi => 
						control <= (rwrite => '1', rspreg => '1', lohisel =>'1', others => '0');
						wait until rising_edge(clk);
					when mflo => 
						control <= (rwrite => '1', rspreg => '1', lohisel =>'0', others => '0');
						wait until rising_edge(clk);
					when mult =>  
						control <= (rread => '1', others => '0');
						wait until rising_edge(clk);
						send_alu(alu_mult);
						control <= (wspreg => '1', others => '0');
						wait until rising_edge(clk);
					when div  =>  
						control <= (rread => '1', others => '0');
						wait until rising_edge(clk);
						send_alu(alu_div);
						control <= (wspreg => '1', others => '0');
						wait until rising_edge(clk);
					when orop =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_or);
						control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst						
						wait until rising_edge(clk);
					when add  =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_add);
						cc_reg <= cc;
						if(cc_v = '1') then
							assert false report "overflow situation in arithmetic operation" severity 
							note;
						else
							control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
							wait until rising_edge(clk);
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
							wait until rising_edge(clk);
						end if;
					when slt  =>  
						control <= (rread => '1', others => '0'); -- move to alu inputs, 
						send_alu(alu_lt);
						control <= (rdest => '1', rwrite => '1', others => '0'); --move from alu to rdst
						wait until rising_edge(clk);
					when others =>  
						control <= (others => '0');
						assert false report "illegal r-type instruction" severity warning;
				end case;
				when lw   => 
					control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
					send_alu(alu_add);
					control <= (mread => '1', msrc => '1', others => '0'); --load word, stored in rd
					wait_dp;
				when sw   => 
					control <= (rread => '1', alusrc => '1', others => '0'); --calc addr
					send_alu(alu_add);
					control <= (mwrite => '1', others => '0'); --save word
					wait_dp;
				when beq  =>
					control <= (rread => '1', others => '0'); --calc addr
					send_alu(alu_sub);
					cc_reg <= cc;
					if(cc_z = '1') then 
						control <= (pcimm => '1', others => '0');
						wait until rising_edge(clk);
					end if;
				when bgez	=>
					control <= (rread => '1', others => '0'); --calc addr
					send_alu(alu_gz);
					cc_reg <= cc;
					if(cc_v = '1') then
						control <= (pcimm => '1', others => '0');
						wait until rising_edge(clk);
					end if; 
				when ori	=>
					control <= (rread => '1', alusrc => '1', others => '0');
					send_alu(alu_or);
					control <= (rwrite => '1', others => '0');
					wait until rising_edge(clk);
				when addi =>
					control <= (rread => '1', alusrc => '1', others => '0');
					send_alu(alu_add);
					control <= (rwrite => '1', others => '0');
					
					wait until rising_edge(clk);
				when lui  =>
					control <= (rread => '1', alusrc => '1', immsl => '1', others => '0');
					send_alu(alu_add); -- works because in lui, rs is 0;
					control <= (rwrite => '1', others => '0');
					wait until rising_edge(clk);
				when others =>
					control <= (others => '0'); 
					assert false report "illegal instruction" severity warning;
			end case;
		end if;
	end process;
end behaviour;