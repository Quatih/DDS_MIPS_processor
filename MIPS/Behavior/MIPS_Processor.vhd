LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity MIPS_Processor IS
    generic (word_length : integer := 32 );
    port (
          clk : in std_logic;
          reset : in std_logic;
          bus_in : in std_logic_vector(word_length-1 downto 0);
          bus_out : out std_logic_vector(word_length-1 downto 0);
          memory_location : out std_logic_vector(word_length-1 downto 0);
          read : out std_ulogic;
          write : out std_ulogic;
          ready : in std_ulogic
          );
end MIPS_Processor;

package processor_types is
    subtype word is std_logic_vector(word_length -1 downto 0);
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

    -- source and dest codes
    constant none : reg_code := "00000";
    constant imm : reg_code := "00001"; -- immediate, store in 
    constant reg_d0 : reg_code := "00010";
    constant reg_d1 : reg_code := "00011";
    constant reg_a0 : reg_code := "00100";
    constant reg_a1 : reg_code := "00101";
    constant a0_addr : reg_code := "00110"; -- memory address in a0
    constant a1_addr : reg_code := "00111"; -- memory address in a1
end processor_types;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;

architecture behaviour of MIPS_Processor is
    signal bus_out_i, memory_location_i : word;
    signal read_i, write_i: std_ulogic;
    variable pc : natural;
    variable a0 : word;
    variable a1 : word;
    variable d0 : word;
    variable d1 : word;
    variable cc : std_logic_vector (2 downto 0); -- clear condition code register;
        alias cc_n  : std_logic IS cc(2); -- negative
        alias cc_z  : std_logic IS cc(1); -- zero
        alias cc_v  : std_logic IS cc(0); -- overflow/compare
    variable current_instr: word;
        alias opcode : op_code IS current_instr(31 downto 26);
        alias rs : reg_code IS current_instr(25 downto 21);
        alias rt : reg_code IS current_instr(20 downto 16);
        alias imm : reg_code IS current_instr(15 downto 0);
        alias rd : reg_code Is current_instr(15 downto 11);
        alias rtype : op_code IS current_instr(5 downto 0);

    procedure set_cc (data : in integer)
        constant low  : integer := -2**(word_length - 1);
        constant high : integer := 2**(word_length - 1) - 1;
        begin
            if (data<low) or (data>high)
            then -- overflow
                ASSERT false REPORT "overflow situation in arithmetic operation" SEVERITY 
                note;
                cc_v:='1'; cc_n:='-'; cc_z:='-';
            else
                cc_v:='0'; 
                if(data <0) then
                    cc_n:='1';
                else
                    cc_n = '0'
                end if; 
                if(data = 0) then
                    cc_z = '1';
                else
                    cc_z = '0';       
                end if;
            end if;
    end set_cc;

    procedure memory_read (addr   : in natural;
                           result : out word) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    begin
      -- put address on output
      memory_location_i <= std_logic_vector(to_unsigned(addr,word_length));
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop -- ready must be low (handshake)
        if reset='1' then
          return;
        end if;
        exit when ready='0';
        wait until clk='1';
      end loop;

      read_i <= '1';
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop
        wait until clk='1';
        if reset='1' then
          return;
        end if;

        if ready='1' then
          result := bus_in;
          EXIT;
        end if;    
      end loop;
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      read_i <= '0'; 
      memory_location_i <= (others => '0';
    end memory_read;                         

    procedure memory_write(addr : in natural;
                           data : in std_logic_vector(word_length-1 downto 0)) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, write, a_bus, d_busout
    -- write data to addr in memory
      VARIABLE add : bit16;
    begin
      -- put address on output
      memory_location_i <= std_logic_vector(to_unsigned(addr,word_length));
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop -- ready must be low (handshake)
        if reset='1' then
          return;
        end if;
        exit when ready='0';
        wait until clk='1';
      end loop;

      bus_out_i <= data;
      wait until clk='1';
      if reset='1' then
        return;
      end if;  
      write_i <= '1';

      loop
        wait until clk='1';
        if reset='1' then
          return;
        end if;
         exit when ready='1';  
      end loop;
      wait until clk='1';
      if reset='1' then
        return;
      end if;
      --
      write_i <= '0';
      bus_out_i <= (others => '0');
      memory_location_i <= (others => '0');
    end memory_write;

    procedure read_data(source : in reg_code )
    begin
        case source is

        end case;
    end read_data;
begin
    process
    begin
        if reset = '1' then
            read_i <= '0';
            write_i <= '0';
            bus_out_i <= (others => '0');
            memory_location_i <= (others => '0');
            pc := text_base_address; -- starting address to base address
            cc := (others => '0');
            loop
                wait until clk = '1';
                exit when reset = '0';
            end loop;

        elsif rising_edge(clk) then
            pc := pc + 1;
            memory_read(pc, current_instr); -- read instruction

            case opcode is
                when "000000" => -- R-type
                    case rtype is 
                        when nop => assert false report 
                                    "illegal r-type instruction" severity failure                        
                        when add => 
                        when addi =>
                        when mflo =>
                        when mfhi =>
                        when mult =>
                        when sub =>
                        when div => 
                        when slt =>
                        when others => -- add assert warning
                    end case;
                when lw =>
                when sw =>
                when lui =>
                when beq =>
                when ori =>
                when orop =>
                when bgez =>
                when others => -- Illegal opcode, assert
            end case;

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
end behaviour;