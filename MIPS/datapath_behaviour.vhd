

architecture behaviour of datapath is
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
  main : process
    variable regresult : word;

    -- Proxy mem_read, calls mem_read in pkg_memory_access
    procedure memory_read(
      addr : in word; --std_logic_vector(word_length*2-1 downto 0);
      result : out word
    ) is
      -- used 'global' signals are:
      --   clk, reset, ready, read, a_bus, d_busin
      -- read data from addr in memory
      begin
        -- put address on output

      mem_addr <= std_logic_vector(addr);
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop -- ready must be low (handshake)
        if reset='1' then
          return;
        end if;
        exit when mem_ready='0';
        wait until clk='1';
      end loop;

      mem_read <= '1';
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop
        wait until clk='1';
        if reset='1' then
          return;
        end if;

        if mem_ready='1' then
          result := mem_bus_in;
          exit;
        end if;    
      end loop;
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      mem_read <= '0'; 
      mem_addr <= (others => '-');
    end memory_read;                    

    procedure memory_write(
      addr    : in word; --std_logic_vector(word_length*2-1 downto 0);
      data  : in word
    ) is
      -- used 'global' signals are:
      --   clk, reset, ready, write, a_bus, d_busout
      -- write data to addr in memory
    begin
      -- put address on output
      mem_addr <= std_logic_vector(addr);
      wait until clk='1';
      if reset='1' then
        return;
      end if;

      loop -- ready must be low (handshake)
        if reset='1' then
          return;
        end if;
        exit when mem_ready='0';
        wait until clk='1';
      end loop;
      mem_bus_out <= data;
      wait until clk='1';
      if reset='1' then
        return;
      end if;  
      mem_write <= '1';

      loop
        wait until clk='1';
        if reset='1' then
          return;
        end if;
          exit when mem_ready='1';  
      end loop;
      wait until clk='1';
      if reset='1' then
        return;
      end if;
      --
      mem_write <= '0';
      mem_bus_out <= (others => '-');
      mem_addr <= (others => '-');
    end memory_write;
  begin
    if(reset = '1') then
      mem_read <= '0';
      mem_write <= '0';
      mem_addr <= (others => '-');
      mem_bus_out <= (others => '0');
      opc <= (others => '0');
      rtopc <= (others => '0');
      pc <= std_logic_vector(to_unsigned(text_base_address, word_length));
      instruction <= (others => '0');
      ready_i <= '0';
      op1 <= (others => '0');
      op2 <= (others => '0');
      regfile <= (others => (others => '0'));
      spec_reg <= (others => '0');
	 else
    wait until rising_edge(clk);
    ready_i <= '0';
	 if(not(unsigned(ctrl_std) = to_unsigned(0, ctrl_std'length))) then
 
    if(control(pcincr) = '1') then
      pc <= std_logic_vector(unsigned(pc) + 4);
    elsif(control(pcimm) = '1') then
      regresult(31 downto 18) := (others => imm(15)); -- sign extend
      regresult(17 downto 2) := imm;
      regresult(1 downto 0) := (others => '0');

      pc <= std_logic_vector(signed(pc) + signed(regresult)); -- possibly error if signed(pc) is outside of mem range
    end if;
  
    --regstuff
    if control(rread) = '1' then
      read_reg(rs, regfile, regresult); 
      op1 <= regresult;
      if control(alusrc) = '1' then -- src is imm from instr
        if control(immsl) = '1' then -- shift left sign extend
          op2(15 downto 0) <= (others => '0');
          op2(31 downto 16) <= imm;
        else -- sign extend
          op2(31 downto 16) <= (others => imm(15)); -- sign extend imm
          op2(15 downto 0) <= imm;
        end if;
      else -- src is rt 
        read_reg(rt, regfile, regresult);
        op2 <= regresult;
      end if;
    elsif control(rwrite) = '1' then
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
    elsif control(mread) = '1' then --read mem
      if control(msrc) = '1' then --addr from alu
        memory_read(std_logic_vector(unsigned(aluword)),regresult);
        write_reg(rt, regfile, regresult);
      else -- addr from pc
        memory_read(std_logic_vector(pc), regresult);-- not sure if correct pc is loaded, because signal
        instruction <= regresult;
        opc <= regresult(31 downto 26); -- not sure if works because of signals, needs testing
        rtopc <= regresult(5 downto 0); -- possibly not necessary depending on opc, could be a power waste but trade-off vs extra hardware to check if opc is 0
      end if;
      ready_i <= '1';
    elsif control(mwrite) = '1' then -- write memory
      read_reg(rt, regfile, regresult);
      -- unsigned conversion because the output of the alu is signed, and memory addresses are unsigned
      memory_write(std_logic_vector(unsigned(aluword)),regresult); 
      ready_i <= '1'; -- ready used for memread and write ops
    end if;
	 end if;
    end if;
  end process;

end behaviour;

