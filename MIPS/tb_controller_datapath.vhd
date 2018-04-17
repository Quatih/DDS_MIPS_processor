library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.processor_types.all;
use work.memory_config.all;
use work.control_names.all;

entity tb_dpc is
  generic (word_length : natural := 32);
end tb_dpc;

architecture behaviour of tb_dpc is
component controller is
	generic (word_length : natural);
	port (
		clk 			: in std_ulogic;
		reset 		: in std_ulogic;
		ctrl_std  : out std_logic_vector(0 to control_bus'length-1);
		ready			: in std_ulogic;
		opc       : in op_code;
		rtopc     : in op_code;
		cc 				: in cc_type;
		alu_ctrl 	: out cc_type;
		alu_ready : in std_ulogic
    );
  end component controller;

  component datapath is
    generic (word_length : natural);
    port (
      clk       : in std_ulogic;
      reset     : in std_ulogic;
      ctrl_std  : in std_logic_vector(0 to control_bus'length-1);
      ready     : out std_logic;
      opc       : out op_code;
      rtopc     : out op_code;
      alu_op1   : out word;
      alu_op2   : out word;
      alu_result: in std_logic_vector(word_length*2-1 downto 0);
      mem_bus_in : in std_logic_vector(word_length-1 downto 0);
      mem_bus_out : out std_logic_vector(word_length-1 downto 0);
      mem_addr : out std_logic_vector(word_length-1 downto 0);
      mem_write : out std_ulogic;
      mem_read : out std_ulogic;
      mem_ready : in std_ulogic
      );
  end component datapath;


  component memory is
  port(d_busout : out std_logic_vector(31 downto 0);
       d_busin  : in  std_logic_vector(31 downto 0);
       a_bus    : in  std_logic_vector(31 downto 0);
       clk      : in  std_ulogic;
       write    : in  std_ulogic;
       read     : in  std_ulogic;
       ready    : out std_ulogic
       );
  end component memory;
  
  signal mem_in_bus,mem_out_bus,mem_addr : word;
  signal control_bus : std_logic_vector(0 to control_bus'length-1);
  signal read,write,ready               : std_ulogic;
  signal reset                          : std_ulogic := '1';
  signal clk                            : std_ulogic := '0';
begin

ctrl:controller
  generic map (word_length)
  port map(mem_in_bus,mem_out_bus,mem_addr,clk,write,read,ready,reset);
dp:controller
  generic map (word_length)
  port map(mem_in_bus,mem_out_bus,mem_addr,clk,write,read,ready,reset);
mem:memory
  port map(mem_in_bus,mem_out_bus,mem_addr,clk,write,read,ready);
reset <= '1', '0' after 100 ns;
clk   <= not clk after 10 ns;
end behaviour;