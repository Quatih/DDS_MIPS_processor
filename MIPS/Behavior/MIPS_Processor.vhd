LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity MIPS_Processor IS
    generic (word_length : integer := 32 );
    port (
          clk : IN std_logic;
          bus_in : IN std_logic_vector(word_length-1 downto 0);
          bus_out : OUT std_logic_vector(word_length-1 downto 0);
          memory_location : OUT std_logic_vector(word_length-1 downto 0);
          read : OUT std_ulogic;
          write : OUT std_ulogic;
          ready : IN std_ulogic
          );
end MIPS_Processor;

architecture behavior of MIPS_Processor is
    component memory IS
  PORT(d_busout : OUT std_logic_vector(31 DOWNTO 0);
       d_busin  : IN  std_logic_vector(31 DOWNTO 0);
       a_bus    : IN  std_logic_vector(31 DOWNTO 0);
       clk      : IN  std_ulogic;
       write    : IN  std_ulogic;
       read     : IN  std_ulogic;
       ready    : OUT std_ulogic
       );
END component;

begin

end behavior;