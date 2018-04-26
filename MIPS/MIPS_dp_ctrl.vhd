
architecture mips_dp_ctrl of MIPS_Processor is

component controller is
	generic (word_length : natural);
	port (
		clk 			: in 	std_ulogic;
		reset 		: in	std_ulogic;
		ctrl_std  : out std_logic_vector(0 to control_bus'length-1);
    ready			: in 	std_ulogic;
    instruction: in word;
		-- opc       : in 	op_code;
		-- rtopc     : in 	op_code;
		cc 				: in 	cc_type;
		alu_ctrl 	: out alu_instr;
		alu_ready : in 	std_ulogic;
		alu_start : out std_ulogic
    );
  end component controller;

  component datapath is
    generic (word_length : natural);
    port (
      clk         : in  std_ulogic;
      reset       : in  std_ulogic;
      ctrl_std    : in  std_logic_vector(0 to control_bus'length-1);
      ready       : out std_logic;
      instruction : out word;
      -- opc         : out op_code;
      -- rtopc       : out op_code;
      alu_op1     : out word;
      alu_op2     : out word;
      alu_result  : in  std_logic_vector(word_length*2-1 downto 0);
      mem_bus_in  : in  word;
      mem_bus_out : out word;
      mem_addr    : out word;
      mem_write   : out std_ulogic;
      mem_read    : out std_ulogic;
      mem_ready   : in  std_ulogic;
      regwrite : out word
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

  component alu_design is
		generic (word_length : integer := 32);
		port (
				result 		: out std_logic_vector (2*word_length- 1 downto 0 );
				ready		  : out std_logic;
				cc 				: out cc_type;
				clk, start,reset : in std_logic;
				inst 		  : in alu_instr;
				op1, op2 	: in std_logic_vector(word_length-1 downto 0)  
				);
  end component alu_design;
  

  signal control_bus : std_logic_vector(0 to control_bus'length-1);

  -- signal opc, rtopc : op_code;
  signal dpready : std_ulogic;
  signal instruction : word;
  signal alu_op1, alu_op2 : word;
  signal alu_result : std_logic_vector(word_length*2-1 downto 0);
  signal alu_ready  : std_ulogic;
  signal alu_ctrl   : alu_instr;
  signal alu_start  : std_ulogic;
  signal cc         : cc_type;
begin

ctrl:controller
  generic map (word_length)
  port map(clk, reset, control_bus, dpready, instruction, cc, alu_ctrl, alu_ready, alu_start);
dp:datapath
  generic map (word_length)
  port map(clk, reset, control_bus, dpready, instruction, alu_op1, alu_op2, 
          alu_result, bus_in, bus_out, memory_location, write, read, ready);
alu:alu_design
  generic map (word_length)
  port map(alu_result, alu_ready, cc, clk, alu_start, reset, alu_ctrl, alu_op1, alu_op2);

end mips_dp_ctrl;