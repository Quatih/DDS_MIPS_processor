
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
USE work.memory_config.ALL;
architecture behaviour of MIPS_Processor is
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
      variable tmp : std_logic_vector(word_length*2-1 downto 0);
      variable data : integer; -- temp integer
      variable datareg : word; -- temp register
      variable cc : cc_type; -- clear condition code register;
        alias cc_n  : std_logic IS cc(2); -- negative
        alias cc_z  : std_logic IS cc(1); -- zero
        alias cc_v  : std_logic IS cc(0); -- overflow/compare
      variable current_instr: word;
        alias opcode : op_code IS current_instr(31 downto 26);
        alias rs : reg_code IS current_instr(25 downto 21);
        alias rt : reg_code IS current_instr(20 downto 16);
        alias rd : reg_code Is current_instr(15 downto 11);
        alias imm : std_logic_vector(15 downto 0) IS current_instr(15 downto 0);
        alias rtype : op_code IS current_instr(5 downto 0);
      
      procedure set_cc_rd (data : in integer;
                          cc : out cc_type;
                          regval : out word) is
        constant low  : integer := -2**(word_length - 1);
        constant high : integer := 2**(word_length - 1) - 1;
      begin
        if (data<low) or (data>high)
        then -- overflow
          ASSERT false REPORT "overflow situation in arithmetic operation" SEVERITY 
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
                            result : out word) IS
    -- Used 'global' signals are:
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
          EXIT;
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
                            data : in word) IS
    -- Used 'global' signals are:
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
        assert false report "Wrong access to register" severity failure;
      else
        ret := regfile(to_integer(unsigned(source)));
      end if;
    end read_data;

    procedure write_data( destination     : in reg_code;
                          regfile         : out register_file;
                          data            : in word)is
    begin
      if((unsigned(destination)) > regfile'high) then
        assert false report "Wrong access to register" severity failure;
      else
        regfile(to_integer(unsigned(destination))) := data;
      end if;
    end write_data;
      
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
      when "000000" => -- R-type
        case rtype is 
          when nop => assert false report "finished calculation" severity failure; 
          when mfhi | mflo => -- access lo, hi
            case rtype is 
              when mflo => datareg := lo;
              when mfhi => datareg := hi;
              when others => NULL;
            end case;
            write_data(rd, regfile, datareg);
          when mult | div => --store in lo, hi
            read_data(rs, regfile, rs_reg);
            rs_int := to_integer(signed(rs_reg));
            read_data(rt, regfile, rt_reg);
            rt_int := to_integer(signed(rt_reg));
            case rtype is
              when mult => 
                tmp := std_logic_vector(to_signed(rs_int*rt_int, word_length*2));
                hi := tmp(word_length*2-1 downto word_length);
                lo := tmp(word_length-1 downto 0);
              when div => 
                lo := std_logic_vector(to_signed(rs_int/rt_int, word_length));
                hi := std_logic_vector(to_signed(rs_int mod rt_int, word_length));
              when others => NULL;
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
          when beq => if(rs_int = rt_int) then
                        cc_v := '1';
                      else
                        cc_v := '0';
                      end if;
                      if(cc_v = '1') then
                        data := to_integer(signed(std_logic_vector'(imm & "00")));
                        pc := pc + data;
                      end if;
          when others => NULL;
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