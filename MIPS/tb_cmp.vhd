library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;

entity tb_cmp is
  generic (word_length : natural := 32);
end tb_cmp;

architecture structure of tb_cmp is

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

    signal cmp_data_from_cpu, cmp_data_to_cpu, cmp_addr : word;
    signal cmp_read, cmp_write, cmp_ready : std_ulogic;
  begin


    proc_beh:mips_processor
    generic map (word_length)
    port map(data_to_cpu,data_from_cpu,addr,clk,write,read,ready,reset);
    mem_beh:memory
    port map(data_to_cpu,data_from_cpu,addr,clk,write,read,ready);


    proc_cmp:mips_processor
      generic map (word_length)
      port map(cmp_data_to_cpu,cmp_data_from_cpu,cmp_addr,clk,cmp_write,cmp_read,cmp_ready,reset);
    mem_cmp:memory
      port map(cmp_data_to_cpu,cmp_data_from_cpu,cmp_addr,clk,cmp_write,cmp_read,cmp_ready);
    reset <= '1', '0' after 100 ns;
    clk   <= not clk after 10 ns;


  process
  begin
    wait until rising_edge(clk);
    assert data_to_cpu    = cmp_data_to_cpu   report "discrepancy between data from memory" severity note;
    assert data_from_cpu  = cmp_data_from_cpu report "discrepancy between data to memory" severity note;
    assert addr           = cmp_addr          report "discrepancy between addr" severity note;
    assert write          = cmp_write         report "discrepancy between write" severity note;
    assert read           = cmp_read          report "discrepancy between read" severity note;
    assert ready          = cmp_ready         report "discrepancy between ready" severity note;
    
  end process;

end structure;