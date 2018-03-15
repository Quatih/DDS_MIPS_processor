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

package processor_types is
  subtype word is std_logic_vector(word_length -1 downto 0);
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
  constant sub  : op_code := "100010";
  constant div  : op_code := "011010";
  constant slt  : op_code := "101010";
  constant mflo : op_code := "010010";
  constant mfhi : op_code := "010000";
  constant lui  : op_code := "001111";
  constant nop  : op_code := "000000";
  constant bgez : op_code := "000001";

  -- source and dest codes
  constant none : reg_code := "00000";
  constant instr_imm : reg_code := "00001"; -- immediate, store in 
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

architecture behaviour of MIPS_Processor is
  signal bus_out_i, memory_location_i : word;
  signal read_i, write_i: std_ulogic;
  variable pc : natural;
  variable a0 : word;
  variable a1 : word;
  variable d0 : word;
  variable d1 : word;
  variable muldiv : std_logic_vector(word_length*2 -1 downto 0);
    alias lo : word is muldiv(word_length*2 -1 downto word_length -1);
    alias hi : word is muldiv(word_length -1 downto 0);
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
    alias imm : reg_code IS current_instr(15 downto 0);
    alias rd : reg_code Is current_instr(15 downto 11);
    alias rtype : op_code IS current_instr(5 downto 0);

  procedure set_cc_rd (data : in integer
                      cc : out std_logic_vector(2 downto 0)
                      regval : out word) is
    constant low  : integer := -2**(word_length - 1);
    constant high : integer := 2**(word_length - 1) - 1;
    begin
      if (to_signed(data)<low) or (to_signed(data)>high)
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
            cc_n = '0'
        end if; 
        if(data = 0) then
            cc_z = '1';
        else
            cc_z = '0';       
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
    memory_location_i <= (others => '0';
  end memory_read;                         

  procedure memory_write(addr : in natural;
                          data : in word) IS
  -- Used 'global' signals are:
  --   clk, reset, ready, write, a_bus, d_busout
  -- write data to addr in memory
    VARIABLE add : bit16;
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

  function read_data(source : in reg_code ) return integer is;
  variable ret : integer;
  begin
    case source is
      when none => ret := 0;
      when instr_imm => ret := to_integer(imm);
      when reg_d0 => ret := d0;
      when reg_d1 => ret := d1;
      when reg_a0 => ret := a0;
      when reg_a1 => ret := a1;
      when a0_addr => memory_read(a0, ret);
      when a1_addr => memory_read(a1, ret);
      when others => assert false report "illegal source when reading data" severity warning;
    end case;
    return ret;
  end read_data;

  procedure write_data(destination : in reg_code;
                        d0, d1, a0, a1 : inout word;
                        data : in word)is
  begin
    case destination is
      when none => NULL;
      when instr_imm => NULL;
      when reg_d0 => d0 := data;
      when reg_d1 => d1 := data;
      when reg_a0 => a0 := data;
      when reg_a1 => a1 := data;
      when a0_addr => memory_write(a0, data);
      when a1_addr => memory_write(a1, data);
        when others => assert false report "illegal source when reading data" severity warning;
    end case;
  end write_data;

begin
  process
      variable tmp : std_logic_vector(word_length*2-1 downto 0);
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
          when mult | div =>
            case rtype is
              when mult => 
                tmp := std_logic_vector(to_unsigned(read_data(rs)*read_data(rt), word_length*2));
                hi := tmp(word_length*2-1 downto word_length-1);
                lo := tmp(word_length-1 downto 0);
              when div => 
                lo := read_data(rs)/read_data(rt);
                hi := read_data(rs) mod read_data(rt);
            end case;
          when others =>
            case rtype is 
              when nop => assert false report "finished calculation" severity failure;                                                  
              when add => data := read_data(rs) + read_data(rt);
              when mflo => data := lo;
              when mfhi => data := hi;
              when sub => data := read_data(rs) - read_data(rt);
              when orop => data := read_data(rs) or read_data(rt));
              when slt => 
                if(read_data(rs) < read_data(rt)) then
                    data := '1'
                else
                    data := '0';
                end if;        
              when others => assert false report "illegal r-type instruction" severity warning;
            end case;
            set_cc_rd(data, cc, datareg);
            write_data(rd, d0, d1, a0, a1, datareg);
        end case;
      when lw =>  data := memory_read(read_data(to_integer(rs)+to_integer(imm)), datareg);
                  write_data(rt, d0, d1, a0, a1, datareg)
      when sw =>  data := read_data(rt);
                  datareg := std_logic_vector(to_unsigned(data, word_length));
                  memory_write(read_data(to_integer(rs)+to_integer(imm)), datareg)
      when lui => datareg := (word_length-1 downto word_length/2-1 => imm, others =>'0');
                  write_data(rt, d0, d1, a0, a1, datareg)
      when beq => cc_z := read_data(rs) = read_data(rt);
                  if(cc_z) then
                    data := to_integer(imm & "00");
                    pc := pc + data;
                  end if;
      when ori => datareg := (15 downto 0 => imm, others=> '0');
                  data := read_data(rs);
                  datareg := std_logic_vector(to_unsigned(data, word_length)) or datareg;
                  write_data(rt,d0,d1,a0,a1,datareg);
      when addi =>  data := read_data(rs) + read_data(imm);
                    set_cc_rd(data, cc, datareg);
                    write_data(rt,d0,d1,a0,a1,datareg);
      when bgez =>  data := read_data(rs);
                    set_cc_rd(data, cc, datareg);
                    if(cc_z) then
                      data := to_integer(imm && "00");
                      pc := pc + data;
                    end if;
      when others => assert false report "illegal instruction" severity warning;
    end case;
  end seq;

  read <= read_i;
  write <= write_i;
  bus_out <= bus_out_i;
  memory_location <= memory_location_i;
end behaviour;