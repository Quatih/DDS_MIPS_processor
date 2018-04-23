library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
architecture behaviour of mips_processor is
  signal calc : signed (word_length*2 -1 downto 0);
  begin
    process
      type register_file is array (0 to 31) 
                    of std_logic_vector(word_length-1 downto 0);
      variable pc : natural;
      variable regfile : register_file;
      variable lo : word; -- special for mult and div
      variable hi : word; -- special for mult and div
      variable rs_reg : word; -- temp register
      variable rt_reg : word; -- temp register
      variable rs_int : integer; -- temp integer representation
      variable rt_int : integer; -- temp integer representation
      variable rs_int_i : std_logic_vector(word_length - 1 downto 0); -- temp integer representation
      variable rt_int_i : std_logic_vector(word_length -1 downto 0) ; -- temp integer representation
      variable tmp : std_logic_vector(word_length*2-1 downto 0);
      variable data : integer; -- temp integer
      variable datareg : word; -- temp register
      variable cc : cc_type; -- clear condition code register;
        alias cc_n  : std_logic is cc(2); -- negative
        alias cc_z  : std_logic is cc(1); -- zero
        alias cc_v  : std_logic is cc(0); -- overflow/compare
      variable current_instr: word;
        alias opcode : op_code is current_instr(31 downto 26);
        alias rs : reg_code is current_instr(25 downto 21);
        alias rt : reg_code is current_instr(20 downto 16);
        alias rd : reg_code is current_instr(15 downto 11);
        alias imm : hword is current_instr(15 downto 0);
        alias rtype : op_code is current_instr(5 downto 0);
      
      
      procedure set_cc_rd (data : in integer;
                          cc : out cc_type;
                          regval : out word) is
        constant low  : integer := -2**(word_length - 1);
        constant high : integer := 2**(word_length - 1) - 1;
      begin
        if (data<low) or (data>high)
        then -- overflow
          assert false report "overflow situation in arithmetic operation" severity 
          note;
          cc_v:='1'; cc_n:='-'; cc_z:='-'; -- correct?
          regval := (others => '-');
        else
          cc_v:='0'; 
          if(data <0) then
            cc_n:='1';
          else
            cc_n := '0';
          end if; 
          if(data = 0) then
            cc_z := '1';
          else
            cc_z := '0';       
          end if;
          regval := std_logic_vector(to_signed(data, word_length));
        end if;
    end set_cc_rd;

    procedure memory_read (addr   : in natural;
                            result : out word) is
    -- used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    begin
      -- put address on output

      memory_location <= std_logic_vector(to_unsigned(addr,word_length));
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop -- ready must be low (handshake)
        if reset='1' then
          return;
        end if;
        exit when ready='0';
        wait until clk='1';
      end loop;

      read <= '1';
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop
        wait until clk='1';
        if reset='1' then
          return;
        end if;

        if ready='1' then
          result := bus_in;
          exit;
        end if;    
      end loop;
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      read <= '0'; 
      memory_location <= (others => '-');
    end memory_read;                         

    procedure memory_write(addr : in natural;
                            data : in word) is
    -- used 'global' signals are:
    --   clk, reset, ready, write, a_bus, d_busout
    -- write data to addr in memory
    begin
      -- put address on output
      memory_location <= std_logic_vector(to_unsigned(addr,word_length));
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop -- ready must be low (handshake)
        if reset='1' then
          return;
        end if;
        exit when ready='0';
        wait until clk='1';
      end loop;

      bus_out <= data;
      wait until clk='1';
      if reset='1' then
        return;
      end if;  
      write <= '1';

      loop
        wait until clk='1';
        if reset='1' then
          return;
        end if;
          exit when ready='1';  
      end loop;
      wait until clk='1';
      if reset='1' then
        return;
      end if;
      --
      write <= '0';
      bus_out <= (others => '-');
      memory_location <= (others => '-');
    end memory_write;

    procedure read_data(source          : in reg_code;
                        regfile         : in register_file;
                        ret             : out word ) is
    begin
      if((unsigned(source)) > regfile'high) then
        assert false report "wrong access to register" severity failure;
      else
        ret := regfile(to_integer(unsigned(source)));
      end if;
    end read_data;

    procedure write_data( destination     : in reg_code;
                          regfile         : out register_file;
                          data            : in word)is
    begin
      if((unsigned(destination)) > regfile'high) then
        assert false report "wrong access to register" severity failure;
      else
        regfile(to_integer(unsigned(destination))) := data;
      end if;
    end write_data;


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
            prod_sft_add(ub downto lb) := std_logic_vector(signed(prod_sft_add(ub downto lb)) - minus_multi);
            prod_sft_add := prod_sft_add(ub) & prod_sft_add(ub downto 1);
            when others => prod_sft_add := (others => '0'); 
            end case;
            end loop;
            result <= signed(prod_sft_add(ub downto 1)); -- result is where??
end mult_booth;
    
  begin
    if reset = '1' then
      read <= '0';
      write <= '0';
      -- bus_out <= (others => '0');
      -- memory_location <= (others => '0');
      pc := text_base_address; -- starting address to base address
      cc := (others => '0');
      regfile := (others => (others => '0'));
      lo := (others => '0');
      hi := (others => '0');
      bus_out <= (others => '-');
      loop
        wait until clk = '1';
        exit when reset = '0';
      end loop;
    else
    
    memory_read(pc, current_instr); -- read instruction
    pc := pc + 4;
    case opcode is
      when "000000" => -- r-type
        case rtype is 
          when nop => assert false report "finished calculation" severity failure; 
          when mfhi | mflo => -- access lo, hi
            case rtype is 
              when mflo => datareg := lo;
              when mfhi => datareg := hi;
              when others => null;
            end case;
            write_data(rd, regfile, datareg);
          when mult | div => --store in lo, hi
            read_data(rs, regfile, rs_reg);
            rs_int := to_integer(signed(rs_reg));
            rs_int_i :=std_logic_vector(to_signed(rs_int,word_length)) ;
            read_data(rt, regfile, rt_reg);
            rt_int := to_integer(signed(rt_reg));
            rt_int_i := std_logic_vector(to_signed(rt_int,word_length));
            case rtype is
              when mult => 
                mult_booth(rs_int_i, rt_int_i, calc);
                tmp := std_logic_vector(calc);
                --tmp := std_logic_vector(to_signed(rs_int*rt_int, word_length*2));
                hi := tmp(word_length*2-1 downto word_length);
                lo := tmp(word_length-1 downto 0);
              when div => 
                lo := std_logic_vector(to_signed(rs_int/rt_int, word_length));
                hi := std_logic_vector(to_signed(rs_int mod rt_int, word_length));
              when others => null;
            end case;
          when orop =>
            read_data(rs, regfile, rs_reg);
            read_data(rt, regfile, rt_reg);
            datareg := rs_reg or rt_reg;
            write_data(rd, regfile, datareg);
          when others =>
            read_data(rs, regfile, rs_reg);
            rs_int := to_integer(signed(rs_reg));
            read_data(rt, regfile, rt_reg);
            rt_int := to_integer(signed(rt_reg));
            case rtype is                                                  
              when add => data := rs_int + rt_int;
              when subop => data := rs_int - rt_int;
              when slt => 
                if(rs_int < rt_int) then
                    data := 1;
                else
                    data := 0;
                end if;        
              when others => assert false report "illegal r-type instruction" severity warning;
            end case;
            set_cc_rd(data, cc, datareg);
            write_data(rd, regfile, datareg);
        end case;
      when sw | beq => --uses rt_int
        read_data(rs, regfile, rs_reg);
        rs_int := to_integer(signed(rs_reg));
        read_data(rt, regfile, rt_reg);
        rt_int := to_integer(signed(rt_reg));
        case opcode is
          when sw =>  data := rs_int+to_integer(signed(imm));
                      memory_write(data, rt_reg);
          when beq => data := rs_int - rt_int;
                      set_cc_rd(data, cc, datareg);
                      if(cc_z = '1') then
                        data := to_integer(signed(std_logic_vector'(imm & "00"))); -- se and shift
                        pc := pc + data;
                      end if;
          when others => null;
        end case;
      when others => -- uses only rs_int
        read_data(rs, regfile, rs_reg);
        rs_int := to_integer(signed(rs_reg));
        case opcode is
          when lw =>  data := rs_int+to_integer(signed(imm));
                      memory_read(data, datareg);
                      write_data(rt, regfile, datareg);                  
          when lui => datareg := (others =>'0');  
                      datareg(word_length-1 downto word_length/2) := imm;
                      write_data(rt, regfile, datareg);
          when ori => datareg := (others=> '0');
                      datareg(15 downto 0) := imm;
                      datareg := rs_reg or datareg;
                      write_data(rt,regfile,datareg);
          when addi =>  data := rs_int + to_integer(signed(imm));
                        set_cc_rd(data, cc, datareg);
                        write_data(rt,regfile,datareg);
          when bgez =>  set_cc_rd(rs_int, cc, datareg);
                        if(rs_int > 0) then
                          cc_v := '1';
                        else 
                          cc_v := '0';
                        end if;
                        if(cc_z = '1' or cc_v = '1') then
                          data := to_integer(signed(std_logic_vector'(imm & "00")));
                          pc := pc + data;
                        end if;
          when others => assert false report "illegal instruction" severity warning;
        end case;

    end case;
    end if;
  end process;

end behaviour;