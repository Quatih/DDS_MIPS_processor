--------------------------------------------------------------
-- 
-- File             : cnf_controller_behaviour_std.vhd
--
-- Related File(s)  : 
--      
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : March 1, 2016
-- 
-- Contents         : configuration for test environment
--                  : behaviour <=>
--                  :  datapath_std(rtl)+controller_std(behaviour)
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

configuration cnf_controller_behaviour_std of test_environment is
  for structure
    for bhv:alu use entity work.alu(behaviour); end for;
    for design:alu use entity work.alu(datapath_controller_std);
      for datapath_controller_std
        for dp:datapath_std use entity work.datapath_std(rtl); end for;
        for ct:controller_std use entity work.controller_std(behaviour); end for;
      end for;
    end for;
  end for;
end cnf_controller_behaviour_std;

