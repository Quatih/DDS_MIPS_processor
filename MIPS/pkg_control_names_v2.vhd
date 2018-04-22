-------------------------------------------------------------
-- 
-- File             : pkg_control_names.vhd
--
-- Related File(s)  :                     
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : March 1, 2016
-- 
-- Contents         : control signals used in datapath and controller
--
-- Change Log 
--   Author         : Sighvatur I. Gislason
--   Email          : hvatig@gmail.com
--   Date           : 3.4.2018  
--   Changes        : adjust control signals and added alu signals
--

library ieee;
use ieee.std_logic_1164.all;
package control_names is
  type control_signals is
   (rdest,  --read from rt (0) or rd (1) 
    msrc,   --addr input to mem, pc(0) or alu(1)
    -- mdst,   --destination of memory read, instruction(0), reg(1) 
    rwrite, --write to a register (1)
    rread,  --read from register(1)
    mwrite, --write to memory (1)
    mread,  --read from memory (1)
    alusrc, --source of op2 of alu, rsource(0) or seimm(1)
    immsl,  --sign extend to wl(0) or sl to wl(1)
    wspreg, --write to special register
    rspreg, --read from special registers to rsource
    loreg,
    hireg,
    -- lohisel,--lo(0), hi(1) to rsource
    -- pcincr, --increment the pc
    pcimm   --add to pc from imm(1)
    );  


  -- do not change the following type declaration
  type control_bus is array (control_signals) of std_logic;  
  
  function ctlr2std(i:control_bus) return std_logic_vector;
  function std2ctlr(i:std_logic_vector) return control_bus;  
  
end control_names;

package body control_names is
  function ctlr2std(i:control_bus) return std_logic_vector is
    variable res : std_logic_vector(0 to control_bus'length-1);
  begin
    res := (others=>'0');
    for lp in control_signals'left to control_signals'right loop
      if i(lp)='1' then res(control_signals'POS(lp)):='1'; end if;
    end loop;
    return res;
  end function ctlr2std;

  function std2ctlr(i:std_logic_vector) return control_bus is
    variable res : control_bus;
  begin
    res := (others => '0');
    for lp in i'range loop
      if i(lp)='1' then res(control_signals'VAL(lp)):='1'; end if;
    end loop;
    return res;
  end function std2ctlr; 

end control_names;

