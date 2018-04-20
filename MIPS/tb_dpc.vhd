library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;

entity tb_dpc is
  generic (word_length : natural := 32);
end tb_dpc;