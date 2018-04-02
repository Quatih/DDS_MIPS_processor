--------------------------------------------------------------
-- 
-- File             : alu-algorithm.vhd
--
-- Related File(s)  : 
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : algorithm of alu
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

architecture algorithm of alu is
  signal rdy_int : std_logic :='1'; 
begin
  
  alu:process
    constant add : std_logic := '0';
    constant mul : std_logic := '1';
    constant allzero : std_logic_vector(2*bw-1 downto 0) := (others => '0');
    variable op1i,op2i : unsigned (bw-1 downto 0);
    function addshift_multiply (op1,op2 : unsigned) return unsigned is
      variable tmp : unsigned (op1'length downto 0);
      variable op1i : unsigned(op1'range);
    begin
      op1i := op1;
      tmp := (others => '0');
      for i in 1 to op1i'length loop
        if op1i(0)='1' then
          tmp := tmp + op2; --add
        end if;
        op1i := tmp(0) & op1i(op1i'length-1 downto 1); -- shift
        tmp  := '0'    & tmp(op1i'length downto 1);
      end loop;
      return tmp(op1i'length-1 downto 0) & op1i;
    end addshift_multiply;		
  begin
    wait until rising_edge(clk);
    if reset='1' then
      rdy_int <='1'; res <= allzero;
    else
      if start='1' then
        rdy_int<='0', '1' after 50 ns; -- delay is used to simulate protocol
   	    op1i := unsigned(op1);
        op2i := unsigned(op2);
        case inst is
          when add    => res <= std_logic_vector(resize (('0'&op1i + op2i),2*bw));
          when others => res <= std_logic_vector(addshift_multiply(op1i,op2i));
        end case;	
       end if;
     end if;
  end process alu;  
  
  ready <= rdy_int;
  
  -- check I/O timing
  check_stable_inputs:process
  begin
    wait until rising_edge(clk);
    if start='1' then
      assert inst'stable report "input INST not stable" severity warning;
      assert op1'stable  report "input OP1 not stable"  severity warning;	  
      assert op2'stable  report "input OP2 not stable"  severity warning;	  
    end if;
  end process;
  
  transition_start_high2low:process
    variable prv_start : std_logic :='0';
  begin
    wait until rising_edge(clk);
    if prv_start='1' and start='0' then
      assert rdy_int='0' report "incorrect transition start from high to low; rdy_int is not '0'" severity warning;
    end if;
    prv_start:=start;
  end process;
  
  --transition of start from high to low only allowed when ready is low
  --PSL default clock is rising_edge(clk);
  --PSL start_high2low_readylow: assert always ( {start='1'; start='0'}|-> {rdy_int='0'} );                             
end algorithm;

