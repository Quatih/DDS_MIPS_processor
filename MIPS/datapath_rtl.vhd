

architecture rtl of datapath is
  constant zero     : word := (others=>'0');
  constant dontcare : word := (others=>'-'); 
  constant unknown  : word := (others=>'X');
  type states is (s_exec, s_readmemreg, s_readmempc, s_readstartpc, s_readstartreg, s_writemem, s_writestart);
  signal state : states;
  type mstates is (mem, exec);
  signal mstate : mstates;
  type register_file is array (0 to 31) 
    of std_logic_vector(word_length-1 downto 0);
  signal regfile  : register_file;
  signal spec_reg : std_logic_vector(word_length*2-1 downto 0) := (others =>'0'); --special register with lo, hi
    alias hi : word is spec_reg(word_length*2-1 downto word_length);
    alias lo : word is spec_reg(word_length -1 downto 0);
  signal pc  : word; -- unsigned(word_length*2-1 downto 0);
  signal instruction_i : word := zero;
    alias opcode : op_code is instruction_i(31 downto 26);
    alias rs : reg_code is instruction_i(25 downto 21);
    alias rt : reg_code is instruction_i(20 downto 16);
    alias rd : reg_code is instruction_i(15 downto 11);
    alias imm : std_logic_vector(15 downto 0) is instruction_i(15 downto 0);
    alias rtype : op_code is instruction_i(5 downto 0);
  signal control : control_bus;
  alias aluword : word is alu_result(word_length -1 downto 0);
  signal pc_i : word;
  signal ready_i : std_ulogic;
  signal mem_read_i : std_ulogic;
  signal mem_write_i : std_ulogic;
  signal mem_bus_out_i : word;
  signal op1, op2 : word;
  signal savereg : word;
  signal memcheck : std_ulogic := '0';
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
      -- regwrite <= data;
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

  mem_addr <= aluword when (control(mread) = '1' and control(msrc) = '1') or control(mwrite) = '1' else
              pc      when control(mread) = '1' else        
              unknown;
              
  mem_read <= mem_read_i;

  mem_write <= mem_write_i;

  mem_bus_out <= mem_bus_out_i;
  -- pc <= pc_i when control(mread) = '1' and mem_ready = '0';

  instruction <= instruction_i;
  -- memcheck <= '1', '0' after 40 ns when mem_ready = '1';
  -- make latch for instruction

  -- doesn't work ;(
  -- alu_op1 <=  read_reg(rs, regfile) when control(rread) = '1' else
  --             dontcare;
  -- alu_op2 <=  load_upper(imm) when control(alusrc) = '1' and control(immsl) = '1' else
  --             sign_extend(imm) when control(alusrc) = '1' else
  --             read_reg(rt, regfile) when control(rread) = '1' else
  --             dontcare; 
  alu_op1 <= op1;
  alu_op2 <= op2;
  -- do because of memory access, makes latch
  savereg <=  mem_bus_in when mem_ready = '1';
 
  -- spec_reg <= alu_result when control(wspreg) = '1';
process 
variable pctemp : word;
begin
  wait until rising_edge(clk);

  if reset = '1'  then
    -- regwrite <= zero;
    op1 <= dontcare;
    op2 <= dontcare;
    mem_bus_out_i <= dontcare;
    instruction_i <= zero;
    mem_write_i <= '0';
    mem_read_i <= '0';
    ready_i <= '0';
    regfile <= (others => (others => '0'));
    pc <= std_logic_vector(to_signed(text_base_address, word_length));
    pctemp := std_logic_vector(to_signed(text_base_address, word_length));
  else
    if ready_i = '0' then
      if mem_ready = '1' then
        if control(msrc) = '1' then
          ready_i <= '1';
          write_reg(rt, regfile, savereg);
          mem_read_i <= '0';
        elsif control(mread) = '1' then
          ready_i <= '1';
          mem_read_i <= '0';
          instruction_i <= savereg;
          pctemp := std_logic_vector(signed(pc) + 4);
        elsif control(mwrite) = '1' then
          ready_i <= '1';
          mem_write_i <= '0';
        else
          -- wait on ready from memory
        end if;
      elsif control(mread) = '1' then
        mem_read_i <= '1';
        mem_write_i <= '0';
      elsif control(mwrite) = '1' then
        mem_write_i <= '1';
        mem_read_i <= '0';
      end if;
    else
      ready_i <= '0';
      mem_read_i <= '0';
      mem_write_i <= '0';
    end if;

    -- use pctemp because otherwise it wasn't synthesizable
    if ready_i = '1' and mem_ready = '1' and control(mread) = '1' and control(pcincr) = '1' then
      pc <= pctemp;
    elsif control(pcimm) = '1' then
      pc <= std_logic_vector(signed(pc) + signed(seshift(imm)));
    end if;

    if control(mwrite) = '1' then
      mem_bus_out_i <= read_reg(rt, regfile);
      -- regwrite <= read_reg(rt, regfile);
    end if;

    if control(rread) = '1' then -- read from registers
    op1 <= read_reg(rs, regfile);
      if control(alusrc) = '1' and control(immsl) = '1' then
        op2 <= load_upper(imm);
      elsif control(alusrc) = '1' then
        op2 <= sign_extend(imm);
      else
        op2 <= read_reg(rt, regfile);
      end if;
    end if;


    if control(rwrite) = '1'  then
      if control(hireg) = '1' then -- if write from spreg (mfhi and mflo)
        write_reg(rd, regfile, hi);
      elsif control(loreg) = '1' then --lo
        write_reg(rd, regfile, lo);
      elsif control(rdest) = '1'  then --write to rd, all rtype instr 
        write_reg(rd, regfile, aluword);
      else
        write_reg(rt, regfile, aluword);
      end if;
    end if;
    if control(wspreg) = '1' then
      spec_reg <= alu_result;
    end if;
  end if;
end process;
end rtl;