

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
    mem_bus_in  : in  std_logic_vector(word_length-1 downto 0);
    mem_bus_out : out std_logic_vector(word_length-1 downto 0);
    mem_addr    : out std_logic_vector(word_length-1 downto 0);
    mem_write   : out std_ulogic;
    mem_read    : out std_ulogic;
    mem_ready   : in  std_ulogic
    );
end datapath;

architecture rtl of datapath is
  constant zero       : word := (others=>'0');
  constant dontcare   : word := (others=>'-'); 
  type register_file is array (0 to 31) 
    of std_logic_vector(word_length-1 downto 0);
  signal regfile  : register_file;
  signal spec_reg : std_logic_vector(word_length*2-1 downto 0); --special register with lo, hi
    alias hi : word is spec_reg(word_length*2-1 downto word_length);
    alias lo : word is spec_reg(word_length -1 downto 0);
  signal pc       : unsigned(word_length-1 downto 0); -- unsigned(word_length*2-1 downto 0);
  signal reg1, reg2, regw : word;
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
      pc <= to_unsigned(text_base_address, word_length);
      ready_i <= '0';
      alu_op1 <= (others => '0');
      alu_op2 <= (others => '0');
      loop
				wait until clk = '1';
				exit when reset = '0';
			end loop;
    end if;
    wait until rising_edge(clk);

    ready_i <= '0';
    if(control(pcincr) = '1') then
      pc <= pc + 4;
    elsif(control(pcimm) = '1') then
      regresult(31 downto 18) := (others => '0');
      regresult(17 downto 2) := imm;
      regresult(1 downto 0) := (others => '0');
      pc <= unsigned(regresult);
    end if;
  
    --regstuff
    if control(rread) = '1' then
      read_reg(rs, regfile, regresult); 
      alu_op1 <= regresult;
      if control(alusrc) = '1' then -- src is imm from instr
        if control(immse) = '1' then
            alu_op2(31 downto 16) <= (others => '0');
            alu_op2(15 downto 0) <= imm;
          else
            alu_op2(31 downto 16) <= (others => imm(15)); -- assign sign extended of imm
            alu_op2(15 downto 0) <= imm;
          end if;
      else -- src is rt 
        read_reg(rt, regfile, regresult);
        alu_op2 <= regresult;
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
        opc <= opcode; -- not sure if works because of signals, needs testing
        rtopc <= rtype; -- possibly not necessary depending on opc, could be a power waste but trade-off vs extra hardware to check if opc is 0
      end if;
      ready_i <= '1';
    elsif control(mwrite) = '1' then -- write memory
      read_reg(rt, regfile, regresult);
      -- unsigned conversion because the output of the alu is signed, and memory addresses are unsigned
      memory_write(std_logic_vector(unsigned(aluword)),regresult); 
      ready_i <= '1';
    end if;
    
  end process;

end rtl;

