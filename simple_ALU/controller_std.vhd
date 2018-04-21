--------------------------------------------------------------
-- 
-- File             : controller_std.vhd
--
-- Related File(s)  : pkg_control_names.vhd
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : March 1, 2016
-- 
-- Contents         : entity description of controller_std
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
entity controller_std is
  generic (bw : natural := 2);
  port (inst     : in  std_logic;
        start    : in  std_logic;
        clk      : in  std_logic;
        reset    : in  std_logic;
        -- control  : out control_bus;
        ctrl_std : out std_logic_vector(0 to control_bus'length-1);        
        ready    : out std_logic);
end controller_std;

