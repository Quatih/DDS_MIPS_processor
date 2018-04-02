--------------------------------------------------------------
-- 
-- File             : cnf_behaviour.vhd
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
-- Contents         : configuration for test environment of behaviour
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

configuration cnf_behaviour of test_environment is
  for behaviour
    for bhv:alu use entity work.alu(behaviour); end for;
  end for;
end cnf_behaviour;

