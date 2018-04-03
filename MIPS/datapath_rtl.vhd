library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;

entity datapath is
  generic (word_length : natural);
  port (
    clk       : in std_ulogic;
    ready     : out std_ulogic;
    reset     : in std_ulogic;
    ctrl_std  : in std_logic_vector(0 to control_bus'length-1);
    opc       : out op_code;
    rtopc     : out op_code;
    ready_out : out std_ulogic
    alu_op1   : out word;
    alu_op2   : out word;
    alu_result: in std_logic_vector(word_length*2 downto 0)
    );
end datapath;

architecture rtl of datapath is
  constant zero       : word := (others=>'0');
  constant dontcare   : word := (others=>'-'); 
  
  type register_file is array (0 to 31) 
    of std_logic_vector(word_length-1 downto 0);
  signal regfile  : register_file;
  signal lo, hi   : word; --special register
  signal pc       : unsigned(word_length*2 downto 0);
  signal reg1, reg2, regw : word;
  signal instruction : word;
    alias opcode : op_code is current_instr(31 downto 26);
    alias rs : reg_code is current_instr(25 downto 21);
    alias rt : reg_code is current_instr(20 downto 16);
    alias rd : reg_code is current_instr(15 downto 11);
    alias imm : hword is current_instr(15 downto 0);
    alias rtype : op_code is current_instr(5 downto 0);
  signal control : control_bus;
begin


  control <= std2ctlr(ctrl_std);



  lo <= alu_result(word_length-1 downto 0) when control(spreg) = '1' and control(lohisel) = '0' else
        lo;

  hi <= alu_result(word_length-1 downto 0) when control(spreg) = '1' and control(lohisel) = '1' else
        hi;
  
end rtl;

