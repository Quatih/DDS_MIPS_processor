LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
entity MIPS_Processor IS
  generic (word_length : integer);
  port (bus_in : in std_logic_vector(word_length-1 downto 0);
        bus_out : out std_logic_vector(word_length-1 downto 0);
        memory_location : out std_logic_vector(word_length-1 downto 0);
        clk : in std_ulogic;
        write : out std_ulogic;
        read : out std_ulogic;
        ready : in std_ulogic;
        reset : in std_ulogic
        );
end MIPS_Processor;