
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
USE work.memory_config.ALL;
architecture algorithm of MIPS_Processor is
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
        alias imm : hword IS current_instr(15 downto 0);
        alias rtype : op_code IS current_instr(5 downto 0);
      constant one : word := (0 => '1', others =>'0');
      constant zero : word := (others => '0');
      constant dontcare : word := (others => '-');
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
          cc_v:='1'; cc_n:='-'; cc_z:='-';
          regval := dontcare;
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
          regval := std_logic_vector(to_unsigned(data, word_length));
        end if;
    end set_cc_rd;

    procedure set_cc_equal ( a, b : in word; cc : out cc_type) is
    begin
      if(a=b) then  
        cc_v := '1';
      else
        cc_v := '0';
      end if;
    end set_cc_equal;

    procedure set_cc_less ( a, b : in word; cc : out cc_type) is
    begin
      if(a<b) then  
        cc_v := '1';
      else
        cc_v := '0';
      end if;
    end set_cc_less;

    function orvectors (a, b : in std_logic_vector) return word is
      variable tmp : word := (others =:> '0');
    begin
      tmp
    end orvectors

    procedure memory_read (addr   : in natural;
                            result : out word) is
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
      memory_location <= dontcare;
    end memory_read;                         

    procedure memory_write(addr : in natural;
                            data : in word) is
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
      bus_out <= dontcare;
      memory_location <= dontcare;
    end memory_write;

    procedure read_data(source          : in reg_code;
                        regfile         : in register_file;
                        ret             : out word) is
    begin
      if(unsigned(source) > regfile'high) then
        assert false report "Wrong access to register" severity failure;
      else
        ret := regfile(to_integer(unsigned(source)));
      end if;
    end read_data;

    procedure write_data( destination     : in reg_code;
                          regfile         : out register_file;
                          data            : in word) is
    begin
      if(unsigned(destination) > regfile'high) then
        assert false report "Wrong access to register" severity failure;
      else
        regfile(to_integer(unsigned(destination))) := data;
      end if;
    end write_data;
      
    -- return a word based on input vector, sign extended.
    function to_word_length_se(invector : std_logic_vector) return word is
    begin
      return resize(signed(invector), word_length);
    end to_word_length_se;

    function addvectors(a, b : word) return word is
        variable ret : signed (word_length-1 downto 0);
      begin
        ret := signed(a) + signed(b); 
      return std_logic_vector(ret); 
    end addvectors;

    function subvectors(a, b : word) return word is
      variable ret : signed (word_length-1 downto 0);
    begin
      ret := signed(a) - signed(b); 
    return std_logic_vector(ret); 
    end subvectors;

    -- Shift word left
    function shiftleft (a : word, num : integer) return word is
        variable ret : word := zero;
      begin
        ret(word_length -1 downto 0+num) := a(word_length - 1 - num downto 0); 
        return ret;
    end shiftleft;

    -- Arithmetic shift word right
    function shiftright (a : word, num : integer) return word is
      variable ret : word;
    begin
      ret := (word_length -1 - num downto 0 => a(word_length - 1 downto num), others => a'left); 
      return ret;
    end shiftright;

  begin
    if reset = '1' then
      read <= '0';
      write <= '0';
      -- bus_out <= (others => '0');
      -- memory_location <= (others => '0');
      pc := text_base_address; -- starting address to base address
      cc := (others => '0');
      regfile := (others => (others => '0'));
      lo := zero;
      hi := zero;
      bus_out <= dontcare;
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
                lo := tmp(word_length-1 downto 0);
                hi := tmp(word_length*2-1 downto word_length);
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
              when slt => set_cc_less(rs_reg, rt_reg, cc);
                if(cc_v = '1') then
                    data := 1;
                else
                    data := 0;
                end if;        
              when others => assert false report "illegal r-type instruction" severity warning;
            end case;
            set_cc_rd(data, cc, datareg);
            write_data(rd, regfile, datareg);
        end case;
      when sw | beq => -- needs rs and rt
        read_data(rs, regfile, rs_reg);
        read_data(rt, regfile, rt_reg);
        case opcode is
          when sw =>  datareg := addvectors(rs_reg,to_word_length(imm));
                      memory_write(to_integer(datareg), rt_reg);
          when beq => set_cc_equal(rs_reg, rt_reg, cc);
                      if(cc_v = '1') then
                        data := to_integer(shiftleft(imm,2));
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
          when lui => datareg := zero;  
                      datareg(word_length-1 downto word_length/2) := imm;
                      write_data(rt, regfile, datareg);
          when ori => datareg := zero;
                      datareg(15 downto 0) := imm;
                      datareg := rs_reg or datareg;
                      write_data(rt,regfile,datareg);
          when addi =>  data := rs_int + to_integer(signed(imm));
                        set_cc_rd(data, cc, datareg);
                        write_data(rt,regfile,datareg);
          when bgez =>  set_cc_rd(rs_int, cc, datareg);
                        if(cc_z = '1') then
                          data := to_integer(signed(std_logic_vector'(imm & "00")));
                          pc := pc + data;
                        end if;
          when others => assert false report "illegal instruction" severity warning;
        end case;
    end case;
    end if;
  end process;
end behaviour;