--------------------------------------------------------------
-- 
-- File             : alu.vhd
--
-- Related File(s)  : 
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August  23, 2012
-- 
-- Contents         : entity description of alu
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity alu is
  generic (bw      : natural := 5);
  port (op1,op2    : in  std_logic_vector(bw-1 downto 0);
        inst,start : in  std_logic;
        reset      : in  std_logic;
		clk        : in  std_logic;
        ready      : out std_logic;
        res        : out std_logic_vector(2*bw-1 downto 0)); 
end alu;
