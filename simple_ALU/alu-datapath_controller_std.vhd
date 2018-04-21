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
-- Creation Date    : March 1, 2016
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
architecture datapath_controller_std of alu is
  signal control : std_logic_vector(0 to control_bus'length-1);
  component datapath_std 
    generic (bw : natural := 4);
    port (op1,op2  : in  std_logic_vector(bw-1 downto 0);
--        control  : in  control_bus;
          ctrl_std  : std_logic_vector(0 to control_bus'length-1);
          clk      : in  std_logic;
          res      : out std_logic_vector(2*bw-1 downto 0));
  end component;        
  component controller_std
    generic (bw : natural := 4);
    port (inst     : in  std_logic;
          start    : in  std_logic;
          clk      : in  std_logic;
          reset    : in  std_ulogic;
          -- control  : out control_bus;
          ctrl_std : out std_logic_vector(0 to control_bus'length-1);  
          ready    : out std_logic);
  end component;
begin
  dp:datapath_std
     generic map (bw)
     port map (op1,op2,control,clk,res);
  ct:controller_std
     generic map (bw)
     port map (inst,start,clk,reset,control,ready); 
end datapath_controller_std;



