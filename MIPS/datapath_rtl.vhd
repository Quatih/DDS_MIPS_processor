

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;
package memory_access is
    procedure memory_read (addr   : in unsigned(word_length*2 downto 0);
                            result : out word) is
    -- used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    begin
      -- put address on output

      memory_location <= std_logic_vector(addr);
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

    procedure memory_write(addr : in unsigned(word_length*2 downto 0);
                            data : in word) is
    -- used 'global' signals are:
    --   clk, reset, ready, write, a_bus, d_busout
    -- write data to addr in memory
    begin
      -- put address on output
      memory_location <= std_logic_vector(addr);
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
end memory_access;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;
use work.memory_access.all;
entity datapath is
  generic (word_length : natural);
  port (
    clk       : in std_ulogic;
    ready     : out std_ulogic;
    reset     : in std_ulogic;
    ctrl_std  : in std_logic_vector(0 to control_bus'length-1);
    opc       : out op_code;
    rtopc     : out op_code;
    alu_op1   : out word;
    alu_op2   : out word;
    alu_result: in std_logic_vector(word_length*2 downto 0)
    mem_bus_in : in std_logic_vector(word_length-1 downto 0);
    mem_bus_out : out std_logic_vector(word_length-1 downto 0);
    mem_addr : out std_logic_vector(word_length-1 downto 0);
    mem_write : out std_ulogic;
    mem_read : out std_ulogic;
    mem_ready : in std_ulogic
    );
end datapath;


architecture rtl of datapath is
  constant zero       : word := (others=>'0');
  constant dontcare   : word := (others=>'-'); 
  
  type register_file is array (0 to 31) 
    of std_logic_vector(word_length-1 downto 0);
  signal regfile  : register_file;
  signal lo, hi   : word; --special register
  signal pc       : unsigned(word_length*2 downto 0);
  signal reg1, reg2, regw : word;
  signal instruction : word;
    alias opcode : op_code is current_instr(31 downto 26);
    alias rs : reg_code is current_instr(25 downto 21);
    alias rt : reg_code is current_instr(20 downto 16);
    alias rd : reg_code is current_instr(15 downto 11);
    alias imm : hword is current_instr(15 downto 0);
    alias rtype : op_code is current_instr(5 downto 0);
  signal control : control_bus;
  
  procedure read_reg(source          : in reg_code;
                      regfile         : in register_file;
                      ret             : out word ) is
  begin
    if((unsigned(source)) > regfile'high) then
      assert false report "wrong access to register" severity failure;
    else
      ret := regfile(to_integer(unsigned(source)));
    end if;
  end read_data;

  procedure write_reg( destination     : in reg_code;
                        regfile         : out register_file;
                        data            : in word)is
  begin
    if((unsigned(destination)) > regfile'high) then
      assert false report "wrong access to register" severity failure;
    else
      regfile(to_integer(unsigned(destination))) := data;
    end if;
  end write_data;
  
begin
  -- using control conversion
  control <= std2ctlr(ctrl_std);
  lo <= alu_result(word_length-1 downto 0) when control(wspreg) = '1' else
        lo;

  hi <= alu_result(word_length-1 downto 0) when control(wpreg) = '1' else
        hi;  
  pc <= pc + 4 when control(pcincr) = '1' else
        pc + signed(imm & "00") when control(pcimm) = '1' else
        pc;
  
  regaccess : process
  variable regresult : word;
  begin
    wait until rising_edge(clk)
    if control(rread) = '1' then
      read_reg(rs, regfile, regresult); 
      alu_op1 <= regresult;
      if control(alusrc) = '1' then -- src is imm from instr
        if control(immse) = '1' then
            alu_op2 <= (31 downto 0 => imm, others => '0');
          else
            alu_op2 <= (15 downto 0 => imm, others => imm'left); -- assign sign extended of imm
          end if;
      else -- src is rt 
        read_reg(rt, regfile, regresult);
        alu_op2 <= regresult;
      end if;
    end if;
  end process;

  memaccess: process 
    variable regresult : word;
  begin
    wait until rising_edge(clk)
    if control(memread) = '1' then 
      if control(msrc) = '1' then --addr from alu
        memory_read(unsigned(alu_result(word_length-1 downto 0),regresult);
        write_reg(rt, regfile, regresult);
      else -- addr from pc
        memory_read(pc, instruction);
        opc <= opcode; -- not sure if works because of signals, needs testing
        rtopc <= rtype; -- possibly not necessary depending on opc, could be a power waste but trade-off vs extra hardware to check if opc is 0
      end if;
    else
    end if;
      
  end process;

end rtl;

