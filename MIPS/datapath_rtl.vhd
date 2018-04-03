


library ieee;
use ieee.numeric_std.all;
architecture rtl of datapath is
  constant zerobw_1      : std_logic_vector(bw-2 downto 0) := (others=>'0');
  constant zerobw        : std_logic_vector(bw-1 downto 0) := (others=>'0');
  constant dontcare      : std_logic_vector(bw-1 downto 0) := (others=>'-'); 
  signal s               : std_logic_vector(bw downto 0);
  signal a,b,ir1,ir2,ir3 : std_logic_vector(bw-1 downto 0);
  signal r1,r2,r3        : std_logic_vector(bw-1 downto 0);

  signal control : control_bus;
begin
 
  control <= std2ctlr(ctrl_std);

  ir1 <= s(0) & r1(bw-1 downto 1) when control(shift_add)='1' else
         s(bw-1 downto 0)         when control(addition)='1'  else
         op1                      when control(init)='1'      else
         dontcare;

  ir2 <= op2;

  ir3 <= s(bw downto 1)   when control(shift_add)='1' else
         zerobw_1 & s(bw) when control(addition)='1'  else
         zerobw           when control(init)='1'      else
         dontcare;

  a   <= r3        when control(shift_add)='1' else
         r1        when control(addition)='1'  else
         dontcare;

  b   <= r2        when control(addition)='1'                else
         r2        when control(shift_add)='1' and r1(0)='1' else
         zerobw    when control(shift_add)='1' and r1(0)='0' else
         dontcare;

  s   <= std_logic_vector( ('0'&unsigned(a)) + unsigned(b));

  res <= r3 & r1;
  
  registers:process
  begin
    wait until rising_edge(clk);
    if control(enable_r1)='1' then r1<=ir1; end if;
    if control(enable_r2)='1' then r2<=ir2; end if;
    if control(enable_r3)='1' then r3<=ir3; end if;
  end process;
end rtl;

