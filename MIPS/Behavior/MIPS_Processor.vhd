LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
entity MIPS_Processor IS
  generic (word_length : integer := 32 );
  port (clk : in std_logic;
        reset : in std_logic;
        bus_in : in std_logic_vector(word_length-1 downto 0);
        bus_out : out std_logic_vector(word_length-1 downto 0);
        memory_location : out std_logic_vector(word_length-1 downto 0);
        read : out std_ulogic;
        write : out std_ulogic;
        ready : in std_ulogic
        );
end MIPS_Processor;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
package processor_types is
  subtype word is std_logic_vector(31 downto 0);
  subtype op_code is std_logic_vector (5 downto 0);
  subtype reg_code is std_logic_vector (4 downto 0);
  constant lw   : op_code := "100011";
  constant sw   : op_code := "101011";
  constant beq  : op_code := "000100";
  constant add  : op_code := "100000";
  constant addi : op_code := "001000";
  constant mult : op_code := "011000";
  constant ori  : op_code := "001101";
  constant orop : op_code := "100101"; --orop = or operation
  constant subop  : op_code := "100010";
  constant div  : op_code := "011010";
  constant slt  : op_code := "101010";
  constant mflo : op_code := "010010";
  constant mfhi : op_code := "010000";
  constant lui  : op_code := "001111";
  constant nop  : op_code := "000000";
  constant bgez : op_code := "000001";

  -- source and dest codes
  constant none : reg_code := "00000";
  constant pseudo_instr : reg_code := "00001"; -- immediate, store in 
  constant reg_d0 : reg_code := "00010";
  constant reg_d1 : reg_code := "00011";
  constant reg_a0 : reg_code := "00100";
  constant reg_a1 : reg_code := "00101";
  constant a0_addr : reg_code := "00110"; -- memory address in a0
  constant a1_addr : reg_code := "00111"; -- memory address in a1
end processor_types;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
USE work.memory_config.ALL;
architecture behaviour of MIPS_Processor is
  signal bus_out_i, memory_location_i : word;
  signal read_i, write_i: std_ulogic;
  begin
    process
      variable pc : natural;
      variable a0 : word;
      variable a1 : word;
      variable d0 : word;
      variable d1 : word;
      variable lo : word; -- special for mult and div
      variable hi : word; -- special for mult and div
      variable rs_reg : word; -- temp register
      variable rt_reg : word; -- temp register
      variable rs_int : integer;
      variable rt_int : integer;
      variable tmp : std_logic_vector(word_length*2-1 downto 0);
      variable data : integer; -- temp variable
      variable datareg : word; -- temp variable
      variable cc : std_logic_vector (2 downto 0); -- clear condition code register;
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
                          cc : out std_logic_vector(2 downto 0);
                          regval : out word) is
        constant low  : integer := -2**(word_length - 1);
        constant high : integer := 2**(word_length - 1) - 1;
      begin
        if (data<low) or (data>high)
        then -- overflow
          ASSERT false REPORT "overflow situation in arithmetic operation" SEVERITY 
          note;
          cc_v:='1'; cc_n:='-'; cc_z:='-';
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
          regval := std_logic_vector(to_unsigned(data, word_length));
        end if;
    end set_cc_rd;

    procedure memory_read (addr   : in natural;
                            result : out word) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    begin
      -- put address on output

      memory_location_i <= std_logic_vector(to_unsigned(addr,word_length));
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

      read_i <= '1';
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

      read_i <= '0'; 
      memory_location_i <= (others => '0');
    end memory_read;                         

    procedure memory_write(addr : in natural;
                            data : in word) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, write, a_bus, d_busout
    -- write data to addr in memory
    begin
      -- put address on output
      memory_location_i <= std_logic_vector(to_unsigned(addr,word_length));
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

      bus_out_i <= data;
      wait until clk='1';
      if reset='1' then
        return;
      end if;  
      write_i <= '1';

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
      write_i <= '0';
      bus_out_i <= (others => '0');
      memory_location_i <= (others => '0');
    end memory_write;

    procedure read_data(source          : in reg_code;
                        d0, d1, a0, a1  : in word;
                        ret             : out word ) is
    begin
      case source is
        when none => ret := (others => '0');
        when pseudo_instr => NULL;
        when reg_d0 => ret := d0;
        when reg_d1 => ret := d1;
        when reg_a0 => ret := a0;
        when reg_a1 => ret := a1;
        -- when a0_addr => memory_read(a0, ret);
        -- when a1_addr => memory_read(a1, ret);
        when others => assert false report "illegal source when reading data" severity warning;
      end case;
    end read_data;

    procedure write_data( destination     : in reg_code;
                          d0, d1, a0, a1  : inout word;
                          data            : in word)is
    begin
      case destination is
        when none => NULL;
        when pseudo_instr => NULL;
        when reg_d0 => d0 := data;
        when reg_d1 => d1 := data;
        when reg_a0 => a0 := data;
        when reg_a1 => a1 := data;
        -- when a0_addr => memory_write(a0, data);
        -- when a1_addr => memory_write(a1, data);
        when others => assert false report "illegal source when reading data" severity warning;
      end case;
    end write_data;
      
  begin
    if reset = '1' then
        read_i <= '0';
        write_i <= '0';
        bus_out_i <= (others => '0');
        memory_location_i <= (others => '0');
        pc := text_base_address; -- starting address to base address
        cc := (others => '0');
        loop
          wait until clk = '1';
          exit when reset = '0';
        end loop;
    end if;
    pc := pc + 1;
    memory_read(pc, current_instr); -- read instruction

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
            write_data(rd, d0, d1, a0, a1, datareg);
          when mult | div => --store in lo, hi
            read_data(rs, d0, d1, a0, a1, rs_reg);
            rs_int := to_integer(signed(rs_reg));
            read_data(rt, d0, d1, a0, a1, rt_reg);
            rt_int := to_integer(signed(rt_reg));
            case rtype is
              when mult => 
                tmp := std_logic_vector(to_signed(rs_int*rt_int, word_length*2));
                hi := tmp(word_length*2-1 downto word_length-1);
                lo := tmp(word_length-1 downto 0);
              when div => 
                datareg := std_logic_vector(to_signed(rs_int/rt_int, word_length));
                lo := datareg;
                datareg := std_logic_vector(to_signed(rs_int mod rt_int, word_length));
                hi := datareg;
              when others => NULL;
            end case;
          when orop =>
            read_data(rs, d0, d1, a0, a1, rs_reg);
            read_data(rt, d0, d1, a0, a1, rt_reg);
            datareg := rs_reg or rt_reg;
            write_data(rd, d0, d1, a0, a1, datareg);
          when others =>
            read_data(rs, d0, d1, a0, a1, rs_reg);
            rs_int := to_integer(signed(rs_reg));
            read_data(rt, d0, d1, a0, a1, rt_reg);
            rt_int := to_integer(signed(rt_reg));
            case rtype is                                                  
              when add => data := rs_int + rt_int;
              when subop => data := rs_int - rt_int;
              when slt => 
                if(rs_int < rt_int) then
                    data := 0;
                else
                    data := 1;
                end if;        
              when others => assert false report "illegal r-type instruction" severity warning;
            end case;
            set_cc_rd(data, cc, datareg);
            write_data(rd, d0, d1, a0, a1, datareg);
        end case;
      when sw | beq => --uses rt_int
        read_data(rs, d0, d1, a0, a1, rs_reg);
        rs_int := to_integer(signed(rs_reg));
        read_data(rt, d0, d1, a0, a1, rt_reg);
        rt_int := to_integer(signed(rt_reg));
        case opcode is
          when sw =>  data := rs_int+to_integer(signed(imm));
                      memory_write(data, rt_reg);
          when beq => if(rs_int = rt_int) then
                        cc_z := '1';
                      else
                        cc_z := '0';
                      end if;
                      if(cc_z = '1') then
                        data := to_integer(signed(imm & "00"));
                        pc := pc + data;
                      end if;
          when others => NULL;
        end case;
      when others => -- uses only rs_int
        read_data(rs, d0, d1, a0, a1, rs_reg);
        rs_int := to_integer(signed(rs_reg));
        case opcode is
          when lw =>  data := rs_int+to_integer(signed(imm));
                      memory_read(data, datareg);
                      write_data(rt, d0, d1, a0, a1, datareg);                  
          when lui => datareg := (others =>'0');
                      datareg(word_length-1 downto word_length/2-1) := imm;
                      write_data(rt, d0, d1, a0, a1, datareg);
          when ori => datareg := (others=> '0');
                      datareg(15 downto 0) := imm;
                      datareg := rs_reg or datareg;
                      write_data(rt,d0,d1,a0,a1,datareg);
          when addi =>  data := rs_int + to_integer(signed(imm));
                        set_cc_rd(data, cc, datareg);
                        write_data(rt,d0,d1,a0,a1,datareg);
          when bgez =>  set_cc_rd(rs_int, cc, datareg);
                        if(cc_z = '1') then
                          data := to_integer(signed(imm & "00"));
                          pc := pc + data;
                        end if;
          when others => assert false report "illegal instruction" severity warning;
        end case;

    end case;
  end process;

  read <= read_i;
  write <= write_i;
  bus_out <= bus_out_i;
  memory_location <= memory_location_i;
end behaviour;