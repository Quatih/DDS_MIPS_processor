-- File memory_config_test.vhd
-- (too) simple test bench of the conversion functions that are declared
-- in package memory_config.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.memory_config.ALL;
ENTITY memory_config_test IS
  PORT(a4    : IN  std_logic_vector(3 DOWNTO 0) := (OTHERS=>'0');  
       a5    : IN  std_logic_vector(4 DOWNTO 0) := (OTHERS=>'0'); 
       a32   : IN  std_logic_vector(31 DOWNTO 0):= (OTHERS=>'0');
       aio4  : INOUT string(1 DOWNTO 1);
       aio5  : INOUT string(2 DOWNTO 1);  
       aio32 : INOUT string(8 DOWNTO 1);
       ao4   : OUT std_logic_vector(3 DOWNTO 0);  
       ao8   : OUT  std_logic_vector(7 DOWNTO 0); 
       ao32  : OUT  std_logic_vector(31 DOWNTO 0)       
       
       );
END memory_config_test;

ARCHITECTURE bhv OF memory_config_test IS
BEGIN
  aio4  <= binvec2hex(a4);
  aio5  <= binvec2hex(a5);  
  aio32 <= binvec2hex(a32);
  ao4   <= hexvec2bin(aio4);
  ao8   <= hexvec2bin(aio5);
  ao32  <= hexvec2bin(aio32);
  
END bhv;
