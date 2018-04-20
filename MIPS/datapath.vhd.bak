

library ieee;
use ieee.std_logic_1164.all;
use work.control_names.all;
entity datapath is
  generic (bw : natural := 4);
  port (op1,op2  : in  std_logic_vector(bw-1 downto 0);
--        control  : in  control_bus;
        ctrl_std  : std_logic_vector(0 to control_bus'length-1);
        clk      : in  std_logic;
        res      : out std_logic_vector(2*bw-1 downto 0));
end datapath;
