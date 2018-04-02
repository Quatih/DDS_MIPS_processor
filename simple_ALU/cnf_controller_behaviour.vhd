--------------------------------------------------------------
-- 
-- File             : cnf_controller_behaviour.vhd
--
-- Related File(s)  : 
--      
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 22, 2011
-- 
-- Contents         : configuration for test environment
--                  : behaviour <=>
--                  :  datapath(rtl)+controller(behaviour)
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

configuration cnf_controller_behaviour of test_environment is
  for structure
    for bhv:alu use entity work.alu(behaviour); end for;
    for design:alu use entity work.alu(datapath_controller);
      for datapath_controller
        for dp:datapath use entity work.datapath(rtl); end for;
        for ct:controller use entity work.controller(behaviour); end for;
      end for;
    end for;
  end for;
end cnf_controller_behaviour;

