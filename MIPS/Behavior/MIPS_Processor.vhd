LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity MIPS_Processor is
    generic (word_length : integer := 32);
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
    subtype opcode is std_logic_vector (5 downto 0);
    subtype regcode is std_logic_vector (4 downto 0);
    constant lw : instruction := "100011";
    constant sw : instruction := "101011";


end processor_types;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;

architecture behaviour of MIPS_Processor is
    signal bus_out_i, memory_location_i : std_logic_vector(word_length-1 downto 0);
    signal read_i, write_i: std_ulogic;
    variable pc : natural;
    variable cc : std_logic_vector (2 downto 0); -- clear condition code register;
        alias cc_n  : std_logic is cc(2);
        alias cc_z  : std_logic is cc(1);
        alias cc_v  : std_logic is cc(0);
    variable current_instr: std_logic_vector(word_length -1 downto 0);
        alias op : instruction is current_instr(31 downto 26);
        alias rtype : instruction is current_instr(5 downto 0);
        alias rs : regcode is current_instr(25 downto 21);
        alias rt : regcode is current_instr(20 downto 16);
        alias imm : regcode is current_instr(15 downto 0);
        alias rd : regcode is current_instr(15 downto 11);


    PROCEDURE memory_read (addr   : IN natural;
        result : OUT std_logic_vector(word_length-1 downto 0)) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    BEGIN
        -- put address on output
        memory_location_i <= std_logic_vector(to_unsigned(addr,16));
        WAIT UNTIL clk='1';
            IF reset='1' THEN
                RETURN;
        END IF;

        LOOP -- ready must be low (handshake)
            IF reset='1' THEN
                RETURN;
            END IF;
            EXIT WHEN ready='0';
            WAIT UNTIL clk='1';
        END LOOP;

        read_i <= '1';
        WAIT UNTIL clk='1';
        IF reset='1' THEN
            RETURN;
        END IF;

        LOOP
            WAIT UNTIL clk = '1';
            IF reset = '1' THEN
                RETURN;
            END IF;

            IF ready='1' THEN
                result := bus_in;
                EXIT;
            END IF;    
        END LOOP;

        WAIT UNTIL clk='1';
        IF reset='1' THEN
            RETURN;
        END IF;

        read_i <= '0'; 
        memory_location_i <= (OTHERS => '-');
    END memory_read;                         
    
    PROCEDURE memory_write(addr : IN natural;
                           data : IN std_logic_vector(word_length-1 downto 0)) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, write, a_bus, d_busout
    -- write data to addr in memory
      VARIABLE add : std_logic_vector(word_length-1 downto 0);
    BEGIN
      -- put address on output
      memory_location_i <= std_ulogic_vector(to_unsigned(addr,16));
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;

      LOOP -- ready must be low (handshake)
        IF reset='1' THEN
          RETURN;
        END IF;
        EXIT WHEN ready='0';
        WAIT UNTIL clk='1';
      END LOOP;

      bus_out_i <= data;
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;  
      write_i <= '1';

      LOOP
        WAIT UNTIL clk='1';
        IF reset='1' THEN
          RETURN;
        END IF;
         EXIT WHEN ready='1';  
      END LOOP;
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;
      --
      write_i <= '0';
      bus_out_i <= (others => '0');
      memory_location_i <= (others => '0');
    END memory_write;

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
            memory_read(pc, current_instr);
            case op is
                when r => 
                    case rtype is
                        when others => -- illegal, add assert
                    end case;
                when others => -- illegal, add assert
            end case;
        end if;
    end seq;

    read <= read_i;
    write <= write_i;
    bus_out <= bus_out_i;
    memory_location <= memory_location_i;
end behavior;