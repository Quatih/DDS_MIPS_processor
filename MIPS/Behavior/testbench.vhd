library ieee;
use ieee.std_logic_1164.all;
use work.processor_types.all;

entity testbench is
  generic (word_length : integer := 32);
end testbench;

architecture behaviour of testbench is
  component memory
  PORT(d_busout : OUT std_logic_vector(31 DOWNTO 0);
       d_busin  : IN  std_logic_vector(31 DOWNTO 0);
       a_bus    : IN  std_logic_vector(31 DOWNTO 0);
       clk      : IN  std_ulogic;
       write    : IN  std_ulogic;
       read     : IN  std_ulogic;
       ready    : OUT std_ulogic
       );
END component;

  component MIPS_Processor
  generic (word_length : integer );
  port (clk : in std_ulogic;
        reset : in std_ulogic;
        bus_in : in std_logic_vector(word_length-1 downto 0);
        bus_out : out std_logic_vector(word_length-1 downto 0);
        memory_location : out std_logic_vector(word_length-1 downto 0);
        read : out std_ulogic;
        write : out std_ulogic;
        ready : in std_ulogic
        );
  end component;

  signal data_from_cpu,data_to_cpu,addr : word;
  signal read,write,ready               : std_ulogic;
  signal reset                          : std_ulogic := '1';
  signal clk                            : std_ulogic := '0';
begin
  cpu:MIPS_Processor
      generic map (word_length)
      port map(clk,reset,data_to_cpu,data_from_cpu,addr,read,write,ready);
  mem:memory
      port map(data_from_cpu,data_to_cpu,addr,clk,write,read,ready);
  reset <= '1', '0' after 100 ns;
  clk   <= not clk after 10 ns;
end behaviour;