LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity MIPS_Processor IS
    generic (word_length : integer := 32 );
    port (
          clk : IN std_logic;
          reset : IN std_logic;
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
    signal bus_out_i, memory_location_i : std_logic_vector(word_length-1 downto 0);
    signal read_i, write_i: std_ulogic;
    signal pc : unsigned range 0 to (2^word_length)/4; --div4 since the pc points to bytes in memory  
begin
    process (clk, reset)

    begin
        if reset = '0' then
            read_i <= '0';
            write_i <= '0';
            bus_out_i <= (others => '0');
            memory_location_i <= std_logic_vector(text_base_address); 
        elsif rising_edge(clk) then
            -- read from address
            -- decode instruction
            -- load from memory
            -- execute instruction
            -- store results from ALU
            -- increment program counter
        end if;
    end seq;

    read <= read_i;
    write <= write_i;
    bus_out <= bus_out_i;
    memory_location <= memory_location_i;
end behavior;