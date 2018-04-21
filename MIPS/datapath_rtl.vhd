

architecture rtl of datapath is
  constant zero       : word := (others=>'0');
  constant dontcare   : word := (others=>'-'); 
  type states is (s_exec, s_readmemreg, s_readmempc, s_readstartpc, s_readstartreg, s_writemem, s_writestart);
  signal state : states;
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
  alias aluword : word is alu_result(word_length -1 downto 0);
  signal pc_i : word;
  signal ready_i : std_ulogic;
  signal op1, op2 : word;
  function read_reg(source          : in reg_code;
                     signal regfile  : in register_file) return word is
    variable ret : word;
  begin
    if((unsigned(source)) > regfile'high) then
      assert false report "wrong access to register" severity failure;
      ret := (others => '-');
    else 
      ret := regfile(to_integer(unsigned(source)));
    end if;
    return ret;
  end read_reg;

  procedure write_reg(signal destination  : in reg_code;
                      signal regfile      : out register_file;
                      signal data         : in word) is
  begin
    if((unsigned(destination)) > regfile'high) then
      assert false report "wrong access to register" severity failure;
    else
      regfile(to_integer(unsigned(destination))) <= data;
    end if;
  end write_reg;
      
  function sign_extend(vec : hword) return word is
    variable ret : word;
  begin
    ret(31 downto 16) := (others => vec(15)); -- sign extend imm
    ret(15 downto 0) := vec;
    return ret;
  end sign_extend;
  
  function load_upper(vec : hword) return word is
    variable ret : word;
  begin
    ret(31 downto 16) := vec; -- sign extend imm
    ret(15 downto 0) := (others => '0');
    return ret;
  end load_upper;

  function seshift(vec : hword) return word is --sign extend and shift
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
  ready <=  ready_i;

  pc <= pc_i;

  alu_op1 <= op1;
  alu_op2 <= op2;
process 
begin
  wait until clk = '1';

  if(reset = '1') then
    mem_read <= '0';
    mem_write <= '0';
    mem_addr <= dontcare;
    mem_bus_out <= dontcare;
    opc <= (others => '-');
    rtopc <= (others => '-');
    instruction <= zero;
    regfile <= (others => (others => '0'));
    spec_reg <= (others => '0');
    state <= s_exec;
    pc_i <= std_logic_vector(to_unsigned(text_base_address, word_length));
  else
    if control(mread) = '1' and state = s_exec then
      if mem_ready = '0' then
        if control(msrc) = '1' then -- addr from alu
          mem_addr <= aluword;
          mem_read <= '1';
          state <= s_readmemreg;
        else -- addr from pc
          mem_addr <= pc;
          mem_read <= '1';
          pc_i <= std_logic_vector(unsigned(pc) + 4);
          state <= s_readmempc;
        end if;
      elsif control(msrc) = '1' then
        state <= s_readstartreg;
      else
        state <= s_readstartpc;
      end if;
    elsif control(mwrite) = '1' and state = s_exec then
      if mem_ready = '0' then
        mem_addr <= aluword;
        mem_bus_out <= read_reg(rt, regfile);
        mem_write <= '1';
        state <= s_writemem;
      else
        state <= s_writestart;
      end if;
    end if;
      
    case state is
      when s_readmemreg =>
        if mem_ready = '1' then
          write_reg(rt, regfile, mem_bus_in);
          mem_read <= '0'; 
          mem_addr <= dontcare;
          ready_i <= '1';
          state <= s_exec;
        end if;
      when s_readmempc =>
        if mem_ready = '1' then
          instruction <= mem_bus_in;
          mem_read <= '0'; 
          mem_addr <= dontcare;
          opc <= mem_bus_in(31 downto 26);
          rtopc <= mem_bus_in(5 downto 0);    
          
          ready_i <= '1';   
          state <= s_exec;
        end if;
      when s_readstartpc =>
        if mem_ready = '0' then
          mem_addr <= pc;
          mem_read <= '1';
          pc_i <= std_logic_vector(unsigned(pc) + 4);
          state <= s_readmempc;
        end if;
      when s_readstartreg =>
        if mem_ready = '0' then
          mem_addr <= aluword;
          mem_read <= '1';
          state <= s_readmemreg;
        end if;
      when s_writestart =>
        if mem_ready = '0' then
          mem_addr <= read_reg(rd, regfile);
          mem_write <= '1';
          state <= s_writemem;
        end if;
      when s_writemem =>
        if(mem_ready = '1') then
          mem_write <= '0'; 
          mem_addr <= dontcare;
          state <= s_exec;
          ready_i <= '1';
        end if;
      when s_exec => --anything other than memory
        if control(rread) = '1' then
          op1 <=  read_reg(rs, regfile);
          if control(alusrc) = '1' then
            if(control(immsl) = '1') then
              op2 <= load_upper(imm);
            else
              op2 <= sign_extend(imm);
            end if;
          else
            op2 <= read_reg(rt, regfile);
          end if;
        end if;
       if control(rwrite) = '1' then
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
        elsif control(wspreg) = '1' then
          spec_reg <= alu_result;
          -- or add if(lohisel)
        elsif control(pcimm) = '1' then
          pc_i <= std_logic_vector(signed(pc) + signed(seshift(imm)));
        end if;
        ready_i <= '0';
      when others => --'no other states'
    end case;
  end if;
end process;
end rtl;