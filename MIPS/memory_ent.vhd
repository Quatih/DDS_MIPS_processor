LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.memory_config.ALL;
ENTITY memory IS
  PORT(d_busout : OUT std_logic_vector(31 DOWNTO 0);
       d_busin  : IN  std_logic_vector(31 DOWNTO 0);
       a_bus    : IN  std_logic_vector(31 DOWNTO 0);
       clk      : IN  std_ulogic;
       write    : IN  std_ulogic;
       read     : IN  std_ulogic;
       ready    : OUT std_ulogic
       );
END memory;