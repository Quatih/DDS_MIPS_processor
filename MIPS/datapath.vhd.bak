library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;
--use work.memory_access.all;
entity datapath is
  generic (word_length : natural);
  port (
    clk         : in  std_ulogic;
    reset       : in  std_ulogic;
    ctrl_std    : in  std_logic_vector(0 to control_bus'length-1);
    ready       : out std_logic;
    opc         : out op_code;
    rtopc       : out op_code;
    alu_op1     : out word;
    alu_op2     : out word;
    alu_result  : in  std_logic_vector(word_length*2-1 downto 0);
    mem_bus_in  : in  word;
    mem_bus_out : out word;
    mem_addr    : out word;
    mem_write   : out std_ulogic;
    mem_read    : out std_ulogic;
    mem_ready   : in  std_ulogic
    );
end datapath;