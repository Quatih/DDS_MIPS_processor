LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
USE work.memory_config.ALL;

entity controller is
    generic (word_length : natural);
    port (
        control  : out control_bus;
        instr : in word;
        alu_ops : out alu_bus;
        bus_in : in std_logic_vector(word_length-1 downto 0);
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
    type register_file is array (0 to 31) 
    of word;
    signal current_instr : word;
        alias opcode : op_code IS current_instr(31 downto 26);
        alias rs : reg_code IS current_instr(25 downto 21);
        alias rt : reg_code IS current_instr(20 downto 16);
        alias rd : reg_code Is current_instr(15 downto 11);
        alias imm : hword IS current_instr(15 downto 0);
        alias rtype : op_code IS current_instr(5 downto 0);

begin
    current_instr <= instr;
    seq: process 
    begin
        if reset = '1' then
            control <= (others => '0');
            read <= '0';
            write <= '0';
            memory_location <= (others => '-');
            bus_out <= (others => '-');
            loop
              wait until clk = '1';
              exit when reset = '0';
            end loop;
        elsif(rising_edge(clk)) then
            control <= (read_mem => '1', others => '0'); 
            loop 
                wait until rising_edge(clk);
                exit when ready = '1';
            end loop;

            case opcode is --decode instruction
                when "00000"=>
                case rtype is 
                    when nop    => assert false report "finished calculation" severity failure;
                    when mfhi   => control <= (rwrite => '1', rdest => '1', spreg => '1', lohisel =>'1', others => '0');
                                   wait until rising_edge(clk);
                    when mflo   => control <= (rwrite => '1', rdest => '1', spreg => '1', others => '0');
                                   wait until rising_edge(clk);
                    when mult   => 
                    when div    => 
                    when orop   => 
                    when add    => 
                    when subop  => 
                    when slt    => 
                    when others =>
                        control <= (others => '0');
                        assert false report "illegal r-type instruction" severity warning;
                end case;
                when lw     =>
                when sw     =>
                when beq    =>
                when bgez   =>
                when ori    =>
                when addi   =>
                when lui    =>
                
                when others =>
                    control <= (others => '0'); 
                    assert false report "illegal instruction" severity warning;
            end case;
            
        end if;
    end process;
end behaviour;