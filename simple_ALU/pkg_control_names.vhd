--------------------------------------------------------------
-- 
-- File             : pkg_control_names.vhd
--
-- Related File(s)  :                     
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : control signals used in datapath and controller
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

library ieee;
use ieee.std_logic_1164.all;
package control_names is
  type control_signals is
     (enable_r1,enable_r2,enable_r3,init,shift_add,addition);

  -- do not change the following type declaration
  type control_bus is array (control_signals) of std_logic;  
end control_names;


