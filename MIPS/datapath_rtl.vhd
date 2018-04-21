

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
      
  function sign_extend(vec : hword) return word
    variable ret : word;
  begin
    ret(31 downto 16) <= (others => vec(15)); -- sign extend imm
    ret(15 downto 0) <= vec;
    return ret;
  end sign_extend;
  
  function load_upper(vec : hword) return word
    variable ret : word;
  begin
    ret(31 downto 16) <= vec; -- sign extend imm
    ret(15 downto 0) <= (others => '0');
    return ret;
  end load_upper;

  function seshift(vec : hword) return word --sign extend and shift
    variable ret : word;
  begin
      ret(31 downto 18) := (others => vec(15)); -- sign extend
      ret(17 downto 2) := vec;
      ret(1 downto 0) := (others => '0');
    return ret;
  end seshift;

begin
  control <= std2ctlr(ctrl_std);
  -- using control conversion
  ready <= ready_i;

  alu_op1 <=  read_reg(rs) when control(rread) = '1' else
              dontcare;
  alu_op2 <=  read_reg(rt)      when control(rread) = '1' else
              sign_extend(imm)  when control(rread) = '1' and control(alusrc) = '1' else
              load_upper(imm)   when control(rread) = '1' and control(alusrc) = '1' and control(immsl) = '1' else 
              dontcare; -- or alu_op2?
  pc <= std_logic_vector(unsigned(pc) + 4) when control(pcincr) = '1' else
        std_logic_vector(signed(pc) + signed(seshift(imm))) when control(pcimm) = '1' else
        pc;

process 
begin
  wait until clk = '1'
  if(rwrite = '1') then
    if control(rspreg) = '1' then -- if write from spreg (mfhi and mflo)
      if control(lohisel) = '1' then --hi
        write_reg(rd, regfile, hi);
      else --lo
        write_reg(rd, regfile, lo);
      end if;
    elsif(control(rdest) = '1') then --write to rd, all rtype instr 
      write_reg(rd, regfile, aluword);
    else
      write_reg(rt, regfile, aluword);
    end if;
  end if;
end process;
end rtl;

