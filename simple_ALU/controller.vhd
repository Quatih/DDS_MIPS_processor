--------------------------------------------------------------
-- 
-- File             : controller.vhd
--
-- Related File(s)  : pkg_control_names.vhd
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : entity description of controller
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
entity controller is
  generic (bw : natural := 2);
  port (inst     : in  std_logic;
        start    : in  std_logic;
        clk      : in  std_logic;
        reset    : in  std_logic;
        control  : out control_bus;
        ready    : out std_logic);
end controller;

