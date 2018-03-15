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

package processor_types is
    subtype op_code is std_logic_vector (5 downto 0);
    subtype reg_code is std_logic_vector (4 downto 0);
    constant lw : instruction := "100011";
    constant sw : instruction := "101011";
    constant beq : instruction := "000100";
    constant add : instruction := "100000";
    constant addi : instruction := "001000";
    constant mult : instruction := "011000";
    constant ori : instruction := "001101";
    constant orop : instruction := "100101"; --orop = or operation
    constant sub : instruction := "100010";
    constant div : instruction := "011010";
    constant slt : instruction := "101010";
    constant mflo : instruction := "010010";
    constant mfhi : instruction := "010000";
    constant lui : instruction := "001111";
    constant nop : instruction := "000000";
    constant bgez : instruction := "000001";


end processor_types;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;

architecture behaviour of MIPS_Processor is
    type states is (fetch, decode, load, execute, store );
    signal bus_out_i, memory_location_i : std_logic_vector(word_length-1 downto 0);
    signal read_i, write_i: std_ulogic;
    variable pc : natural;
    variable cc : std_logic_vector (2 downto 0); -- clear condition code register;
        alias cc_n  : std_logic IS cc(2);
        alias cc_z  : std_logic IS cc(1);
        alias cc_v  : std_logic IS cc(0);
    variable current_instr: std_logic_vector(word_length -1 downto 0);
        alias opcode : op_code IS current_instr(31 downto 26);
        alias rs : reg_code IS current_instr(25 downto 21);
        alias rt : reg_code IS current_instr(20 downto 16);
        alias imm : reg_code IS current_instr(15 downto 0);
        alias rd : reg_code Is current_instr(15 downto 11);
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
            state := fetch;
        elsif rising_edge(clk) then
               -- fetch =>
            -- read from address
                current_instr := bus_in;
                -- memory_location_i <= pc; -- need to wait for a clock cycle to interface with it after this
                -- read_i <= '1';
              -- decode => -- decode instruction
                
                case opcode is
                    "000000" => -- R-type
                        
                    "001000" => -- I-type

                    "000010" => -- J-type
                    others => -- do nothing?
                end case;

            -- do whatever
            -- load => -- load data memory
                --memory_location_i <= "location";

            -- execute =>
            -- execute instruction
            -- store => 
            -- store results from ALU
                -- bus_out_i <= "result";
                -- write_i <= '1';
                -- increment program counter
                -- pc := pc + text_base_size;
             --   state = fetch;
        end if;
    end seq;

    read <= read_i;
    write <= write_i;
    bus_out <= bus_out_i;
    memory_location <= memory_location_i;
end behavior;