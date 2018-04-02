--------------------------------------------------------------
-- 
-- File             : test_environment-behaviour.vhd
--
-- Related File(s)  : alu.vhd
--      
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : simple test environment for alu
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

architecture behaviour of test_environment is
  component alu is
    generic (bw      : natural := 5);
    port (op1,op2    : in  std_logic_vector(bw-1 downto 0);
          inst,start : in  std_logic;
          reset      : in  std_logic;
          clk        : in  std_logic;
          ready      : out std_logic;
          res        : out std_logic_vector(2*bw-1 downto 0)); 
  end component alu;
  constant addition : std_logic := '0';
  constant multiplication : std_logic := '1';
  signal reset,inst,start,ready : std_logic;
  signal clk : std_logic := '0';
  signal op1,op2 :std_logic_vector(bw-1 downto 0);
  signal res : std_logic_vector(2*bw-1 downto 0);
  signal finished : boolean := false; -- used to stop simulation
begin

  bhv: alu 
    generic map (bw)
    port map (op1,op2,inst,start,reset,clk,ready,res); 

  clk <= not clk after 5 ns when not finished;

  process
    -- protocol assumes that data is set (operands and instruction)
    procedure protocol (
      signal clk, ready : IN  std_logic;
      signal start : OUT std_logic) is
    begin
      assert ready='1' report "alu is busy!" severity warning;
      start<='1';
      wait until falling_edge(clk);
	  lp0:loop
	    wait until falling_edge(clk);
        if ready='0' then
          start<='0';
          exit;
        end if;
      end loop lp0;
      lp1:loop
        wait until falling_edge(clk);
        exit when ready='1';
      end loop lp1;
    end protocol;

    variable operand1, operand2 : integer RANGE 0 TO 2**bw-1;

  begin
    reset<='1'; start<='0';
    inst<='0'; op1<=(others=>'0'); op2<=(others=>'0');
    wait until falling_edge(clk);
    reset<='0';
    for instruction in addition to multiplication loop
      inst <= instruction;
      op1<=(others=>'0'); op2<=(others=>'0'); -- test zero operands
      protocol (clk,ready,start);
      op1<=(others=>'1'); op2<=(others=>'0'); -- test ones and zeros operands
      protocol (clk,ready,start);
      op1<=(others=>'0'); op2<=(others=>'1'); -- test zeros and ones operands
      protocol (clk,ready,start);   
      op1<=(others=>'1'); op2<=(others=>'1'); -- test ones and ones operands
      protocol (clk,ready,start);
      loop_op1: for operand1 in 1 to 2**bw-1 loop  -- some other values
        op1 <= std_logic_vector(to_unsigned(operand1,bw));
        loop_op2: for operand2 in 1 to 2**bw-1 loop  -- some other values
          op2 <= std_logic_vector(to_unsigned(operand2,bw));
          protocol (clk,ready,start);
          exit loop_op2 when operand2 > 15;  -- exhaustive testing takes too long
        end loop loop_op2;
        exit loop_op1 when operand1 > 15;    -- exhaustive testing takes too long
      end loop loop_op1;
    end loop;
    assert false report "simulation finished" severity note;
    finished <= true;
    wait;
  end process;

end behaviour;
