LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
package processor_types is
  subtype word is std_logic_vector(31 downto 0);
  subtype op_code is std_logic_vector (5 downto 0);
  subtype reg_code is std_logic_vector (4 downto 0);
  subtype cc_type is std_logic_vector (2 downto 0);
  subtype alu_code is std_logic_vector (2 downto 0);
  subtype hword is std_logic_vector (15 downto 0);
  subtype alu_instr is std_logic_vector(2 downto 0);
  
  constant lw   : op_code := "100011";
  constant sw   : op_code := "101011";
  constant beq  : op_code := "000100";
  constant add  : op_code := "100000";
  constant addi : op_code := "001000";
  constant mult : op_code := "011000";
  constant ori  : op_code := "001101";
  constant orop : op_code := "100101"; --orop = or operation
  constant subop: op_code := "100010"; -- sub operation
  constant div  : op_code := "011010";
  constant slt  : op_code := "101010";
  constant mflo : op_code := "010010";
  constant mfhi : op_code := "010000";
  constant lui  : op_code := "001111";
  constant nop  : op_code := "000000";
  constant bgez : op_code := "000001";

  constant alu_add  : alu_code := "000";
  constant alu_mult : alu_code := "001";
  constant alu_sub  : alu_code := "010";
  constant alu_div  : alu_code := "011";
  constant alu_or   : alu_code := "100";
  constant alu_and  : alu_code := "101";
  constant alu_lt   : alu_code := "110";
  constant alu_gz   : alu_code := "111";
  
end processor_types;
