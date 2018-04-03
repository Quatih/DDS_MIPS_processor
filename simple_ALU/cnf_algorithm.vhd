--------------------------------------------------------------
-- 
-- File             : cnf_algorithm.vhd
--
-- Related File(s)  : 
--      
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : configuration for test environment
--                  : behaviour <=> algorithm
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

configuration cnf_algorithm of test_environment is
  for structure
    for bhv:alu use entity work.alu(behaviour); end for;
    for design:alu use entity work.alu(algorithm); end for;
  end for;
end cnf_algorithm;

