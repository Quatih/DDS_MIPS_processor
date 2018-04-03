library ieee;
use ieee.std_logic_1164.all;
entity t is
  port (start, rdy_int, clk : in std_logic);
end t;

architecture demo of t is
begin

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
  --PSL start_clock_high2low_readylow: assert always ( {start='1'; start='0'}|-> {rdy_int='0'} );

end demo;