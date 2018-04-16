
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;
package memory_access is
  procedure memory_read (
    addr                : in word;
    signal mem_addr     : out word;
    reset               : in std_ulogic;
    mem_ready           : in std_ulogic;
    signal mem_read     : out std_ulogic;
    signal mem_bus_in   : in word;
    clk                 : in std_ulogic;
    result              : out word);


  procedure memory_write(
    addr                : in word;    
    signal mem_addr     : out word;--unsigned(63 downto 0);
    reset               : in std_ulogic;
    mem_ready           : in std_ulogic;
    signal mem_write    : out std_ulogic;
    signal mem_bus_out  : out word;
    clk                 : in std_ulogic;
    data                : in word);

end memory_access;

package body memory_access is
  procedure memory_read(
    addr                : in word;
    signal mem_addr     : out word;
    reset               : in std_ulogic;
    mem_ready           : in std_ulogic;
    signal mem_read     : out std_ulogic;
    signal mem_bus_in   : in word;
    clk                 : in std_ulogic;
    result              : out word) is
    -- used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    begin
      -- put address on output

    mem_addr <= std_logic_vector(addr);
    wait until clk='1';
    if reset='1' then
      return;
    end if;

    loop -- ready must be low (handshake)
      if reset='1' then
        return;
      end if;
      exit when mem_ready='0';
      wait until clk='1';
    end loop;

    mem_read <= '1';
    wait until clk='1';
    if reset='1' then
      return;
    end if;

    loop
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      if mem_ready='1' then
        result := mem_bus_in;
        exit;
      end if;    
    end loop;
    wait until clk='1';
    if reset='1' then
      return;
    end if;

    mem_read <= '0'; 
    mem_addr <= (others => '-');
  end memory_read;                         

  procedure memory_write(   
    addr                : in word;
    signal mem_addr     : out word;
    reset               : in std_ulogic;
    mem_ready           : in std_ulogic;
    signal mem_write    : out std_ulogic;
    signal mem_bus_out  : out word;
    clk                 : in std_ulogic;
    data                : in word) is
  -- used 'global' signals are:
  --   clk, reset, ready, write, a_bus, d_busout
  -- write data to addr in memory
  begin
    -- put address on output
    mem_addr <= std_logic_vector(addr);
    wait until clk='1';
    if reset='1' then
      return;
    end if;

    loop -- ready must be low (handshake)
      if reset='1' then
        return;
      end if;
      exit when mem_ready='0';
      wait until clk='1';
    end loop;
    mem_bus_out <= data;
    wait until clk='1';
    if reset='1' then
      return;
    end if;  
    mem_write <= '1';

    loop
      wait until clk='1';
      if reset='1' then
        return;
      end if;
        exit when mem_ready='1';  
    end loop;
    wait until clk='1';
    if reset='1' then
      return;
    end if;
    --
    mem_write <= '0';
    mem_bus_out <= (others => '-');
    mem_addr <= (others => '-');
  end memory_write;
end;