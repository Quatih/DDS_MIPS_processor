--------------------------------------------------------------
-- 
-- File             : datapath_std.vhd
--
-- Related File(s)  : pkg_control_names.vhd
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : March 1, 2016
-- 
-- Contents         : entity description of datapath_std
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

library ieee;
use ieee.std_logic_1164.all;
use work.control_names.all;
entity datapath_std is
  generic (bw : natural := 4);
  port (op1,op2  : in  std_logic_vector(bw-1 downto 0);
--        control  : in  control_bus;
        ctrl_std  : std_logic_vector(0 to control_bus'length-1);
        clk      : in  std_logic;
        res      : out std_logic_vector(2*bw-1 downto 0));
end datapath_std;

