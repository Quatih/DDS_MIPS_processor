LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
USE work.memory_config.ALL;

entity controller is
    generic (word_length : natural);
    port (bus_in : in std_logic_vector(word_length-1 downto 0);
        bus_out : out std_logic_vector(word_length-1 downto 0);
        memory_location : out std_logic_vector(word_length-1 downto 0);
        clk : in std_ulogic;
        write : out std_ulogic;
        read : out std_ulogic;
        ready : in std_ulogic;
        reset : in std_ulogic
        );
end controller;


architecture behaviour of controller is
begin
    seq: process 
    begin
        if reset = '1' then
        
        elsif(rising_edge(clk)) then
            --read instruction from memory, inc pc
            --decode instruction
            --execute
            --store results
            
        end if;
    end process;
end behaviour;