

architecture rtl of datapath is
  constant zero       : word := (others=>'0');
  constant dontcare   : word := (others=>'-'); 
  
  type register_file is array (0 to 31) 
    of std_logic_vector(word_length-1 downto 0);
  signal regfile  : register_file;
  signal spec_reg : std_logic_vector(word_length*2-1 downto 0); --special register with lo, hi
    alias hi : word is spec_reg(word_length*2-1 downto word_length);
    alias lo : word is spec_reg(word_length -1 downto 0);
  signal pc  : word; -- unsigned(word_length*2-1 downto 0);
  signal instruction : word;
    alias opcode : op_code is instruction(31 downto 26);
    alias rs : reg_code is instruction(25 downto 21);
    alias rt : reg_code is instruction(20 downto 16);
    alias rd : reg_code is instruction(15 downto 11);
    alias imm : std_logic_vector(15 downto 0) is instruction(15 downto 0);
    alias rtype : op_code is instruction(5 downto 0);
  signal control : control_bus;
  signal ready_i : std_ulogic;
  alias aluword : word is alu_result(word_length -1 downto 0);
  signal op1, op2 : word;


  procedure read_reg(source          : in reg_code;
                     signal regfile  : in register_file;
                     ret             : out word ) is
  begin
    if((unsigned(source)) > regfile'high) then
      assert false report "wrong access to register" severity failure;
    else
      ret := regfile(to_integer(unsigned(source)));
    end if;
  end read_reg;

  procedure write_reg(destination     : in reg_code;
                      signal regfile  : out register_file;
                      data            : in word)is
  begin
    if((unsigned(destination)) > regfile'high) then
      assert false report "wrong access to register" severity failure;
    else
      regfile(to_integer(unsigned(destination))) <= data;
    end if;
  end write_reg;
  
begin
  control <= std2ctlr(ctrl_std);
  -- using control conversion
  ready <= ready_i;
  alu_op1 <= op1;
  alu_op2 <= op2;


process 
begin
  wait until clk = '1'
end process;
end rtl;

