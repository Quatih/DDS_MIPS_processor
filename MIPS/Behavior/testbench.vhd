library ieee;
use ieee.std_logic_1164.all;
use work.processor_types.all;

entity testbench is
  generic (word_length : integer := 32);
end testbench;

architecture behaviour of testbench is
  component memory
  port(d_busout : out std_logic_vector(31 downto 0);
       d_busin  : in  std_logic_vector(31 downto 0);
       a_bus    : in  std_logic_vector(31 downto 0);
       clk      : in  std_ulogic;
       write    : in  std_ulogic;
       read     : in  std_ulogic;
       ready    : out std_ulogic
       );
end component;

  component mips_processor
  generic (word_length : integer );
  port (bus_in : in std_logic_vector(word_length-1 downto 0);
        bus_out : out std_logic_vector(word_length-1 downto 0);
        memory_location : out std_logic_vector(word_length-1 downto 0);
        clk : in std_ulogic;
        write : out std_ulogic;
        read : out std_ulogic;
        ready : in std_ulogic;
        reset : in std_ulogic
        );
  end component;

  signal data_from_cpu,data_to_cpu,addr : word;
  signal read,write,ready               : std_ulogic;
  signal reset                          : std_ulogic := '1';
  signal clk                            : std_ulogic := '0';
begin
  cpu:mips_processor
      generic map (word_length)
      port map(data_from_cpu,data_to_cpu,addr,clk,write,read,ready,reset);
  mem:memory
      port map(data_from_cpu,data_to_cpu,addr,clk,write,read,ready);
  reset <= '1', '0' after 100 ns;
  clk   <= not clk after 10 ns;
end behaviour;