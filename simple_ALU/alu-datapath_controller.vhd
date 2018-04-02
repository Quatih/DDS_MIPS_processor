--------------------------------------------------------------
-- 
-- File             : alu-datapath_controller.vhd
--
-- Related File(s)  : datapath.vhd
--                  : controller.vhd
--                  : pkg_control_names.vhd
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : structural description of alu
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
architecture datapath_controller of alu is
  signal control : control_bus;
  component datapath 
    generic (bw : natural := 4);
    port (op1,op2  : in  std_logic_vector(bw-1 downto 0);
          control  : in  control_bus;
          clk      : in  std_logic;
          res      : out std_logic_vector(2*bw-1 downto 0));
  end component;        
  component controller
    generic (bw : natural := 4);
    port (inst     : in  std_logic;
          start    : in  std_logic;
          clk      : in  std_logic;
          reset    : in  std_ulogic;
          control  : out control_bus;
          ready    : out std_logic);
  end component;
begin
  dp:datapath
     generic map (bw)
     port map (op1,op2,control,clk,res);
  ct:controller
     generic map (bw)
     port map (inst,start,clk,reset,control,ready); 
end datapath_controller;



