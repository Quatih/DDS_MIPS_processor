--------------------------------------------------------------
-- 
-- File             : controller_std-behaviour.vhd
--
-- Related File(s)  : pkg_control_names.vhd
--                  : controller_std.vhd
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : March 1, 2016
-- 
-- Contents         : behavioural description of controller_std
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

architecture behaviour of controller_std is
  signal rdy_int : std_ulogic;
  signal   control : control_bus;
begin

  ctrl_std <= ctlr2std(control);

  cntrl:process
    variable count : natural range 0 to bw-1;
    constant add   : std_logic := '0';
    constant mul   : std_logic := '1';
    variable insti : std_logic;
  begin
    rst: loop
	  if reset='1' then
        control<=(others=>'0'); rdy_int<='1'; insti:='0';
        wait until rising_edge(clk);		
      else
	    lp_start:loop
          control<=(others=>'0'); rdy_int<='1';
          exit when start='1';
          wait until rising_edge(clk);
          exit rst when reset='1';
        end loop lp_start; 
        insti:=inst; rdy_int<='0';
	    control<=(enable_r1 | enable_r2 | enable_r3 | init => '1', others=>'0');
        wait until rising_edge(clk);
        exit rst when reset='1';	
        case insti is
          when add => control<=(enable_r1 | enable_r3 | addition => '1', others=>'0'); rdy_int<='0';
                      wait until rising_edge(clk);
                      exit rst when reset='1';
          when others => count:=bw-1;
                      repeat:loop
                        control<=(enable_r1 | enable_r3 | shift_add => '1',others=>'0'); rdy_int<='0';
                        wait until rising_edge(clk);
                        exit rst when reset='1';
                        exit repeat when count=0;
                        count:=count-1;
                      end loop repeat;
        end case;
      end if;
    end loop rst;
  end process;

  ready <= rdy_int;
  
end behaviour;

