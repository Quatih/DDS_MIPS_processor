library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity alu is
  generic (w : natural :=64);
  port (op1, op2 : in std_logic_vector(w-1 downto 0);
        ins : in std_logic_vector(7 downto 0); -- equivalent to ins (mul,div,slt,beq,bgez,add,sub, or)
        start : in std_logic;
        rst : in std_logic;
        clk : in std_logic;
        res : out std_logic_vector(w*2-1 downto 0);
        ready : out std_logic;
        cc : out std_logic_vector(2 downto 0)
    );
end alu;
architecture behavior of alu is
  signal ready_i : std_logic := '1';
begin 
  alu: process
    constant default : std_logic_vector(w*2-1 downto 0) := (others => '0');
    variable op1i, op2i : std_logic_vector(w-1 downto 0);
  begin
    wait until rising_edge(clk);
    if reset = '1' then
      ready_i <= '1'; res <= default;
      elsif start = '1' then
        ready_i <= '0', '1' after 50 ns;
        op1i <= unsigned (op1);
        op2i <= unsigned (op2);
        case ins
          when "10000000" => res <=                                                       --multiplication algorithm
          when "01000000" => res <=                                                         --division algorithm
          when "00100000" => if op1i < op2i then
                              res <= std_logic_vector(res'right => '1', others =>'0');
                            else  
                              res <= default;                                              --slt algorithm
          when "00010000" => if op1i = op2i then
                              res <= std_logic_vector(res'right => '1', others =>'0');
                            else  
                              res <= default;                                      --beq algorithm. Branch if res=1
          when "00001000" => if op1 >= std_logic_vector(others => '0') then
                              res <= std_logic_vector(res'right => '1', others =>'0');
                            else  
                              res <= default;                                    --bgez algorithm. Branch if res=1
          when "00000100" => res <= op1i + op2i;                                            --add algorithm
          when "00000010" => op2i := not(op2i)+'1';
                            res <= op1 + op2;                                              --sub algorithm
          when "00000001" => res <= op1i or op2i;                                          --or operation
        end case;
      end if;
    end if;
  end process;
  ready <= ready_i;
end behavior;

