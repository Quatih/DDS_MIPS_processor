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
    type states is (fetch, decode, load, execute, store );
    signal bus_out_i, memory_location_i : std_logic_vector(word_length-1 downto 0);
    signal read_i, write_i: std_ulogic;
    variable pc : natural;
    variable cc : std_logic_vector (2 downto 0); -- clear condition code register;
    variable instructon_reg : std_logic_vector(7 downto 0);
    variable state : states :=
begin
    process (clk, reset)
    variable opcode : std_logic_vector(5 downto 0);
    begin
        if reset = '0' then
            read_i <= '0';
            write_i <= '0';
            bus_out_i <= (others => '0');
            memory_location_i <= (others => '0');
            pc := text_base_address; -- starting address to base address
            cc := (others => '0');
        elsif rising_edge(clk) then

            -- read from address
                -- memory_location_i <= pc; -- need to wait for a clock cycle to interface with it after this
                -- read_i <= '1';
            -- decode instruction
            opcode := bus_in(31 downto 26);
            case opcode is
                "000000" => -- R-type

                "001000" => -- I-type

                "000010" => -- J-type
                others => -- do nothing?
            end case;
            -- do whatever
            -- load data memory
                --memory_location_i <= "location";
            -- execute instruction
            -- store results from ALU
                -- bus_out_i <= "result";
                -- write_i <= '1';
            -- increment program counter
                -- pc := pc + text_base_size;
        end if;
    end seq;

    read <= read_i;
    write <= write_i;
    bus_out <= bus_out_i;
    memory_location <= memory_location_i;
end behavior;