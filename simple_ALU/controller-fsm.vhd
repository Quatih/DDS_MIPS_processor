--------------------------------------------------------------
-- 
-- File             : controller-fsm.vhd
--
-- Related File(s)  : pkg_control_names.vhd
--                  : controller.vhd
--
-- Author           : E. Molenkamp
-- Email            : e.molenkamp@utwente.nl
-- 
-- Project          : Digital system design
-- Creation Date    : August 23, 2012
-- 
-- Contents         : fsm description of controller
--
-- Change Log 
--   Author         : 
--   Email          : 
--   Date           :  
--   Changes        :
--

architecture fsm of controller is
  signal rdy_int : std_ulogic;
begin
  process
    type states is (idle,ini,add,mul);
    variable state : states;
    variable count : natural range 0 to bw-1;
  begin
    wait until rising_edge(clk); 
    if reset='1' then
      rdy_int<='1';
      count:=0;
      state:=idle;
      control<=(others=>'0');
    else
      case state is
        when idle         => if start='1' then
                                state:=ini;
                             end if;
        when ini          => if inst='1' then
                               state:=mul; count:=bw-1;
                             else
                               state:=add;
                             end if;
        when add          => state:=idle;
        when mul          => if count>0 then
                               count:=count-1;
                             else
                               state:=idle;
                             end if;
      end case;  

      case state is
        when idle         => control<=(others=>'0'); rdy_int<='1';
        when ini          => control<=(enable_r1 | enable_r2 | enable_r3 | init=>'1', others=>'0');
                             rdy_int<='1';
        when add          => control<=(enable_r1 | enable_r3 | addition=>'1', others=>'0');
                             rdy_int<='0';
        when mul          => control<=(enable_r1 | enable_r3 | shift_add=>'1', others=>'0');
                             rdy_int<='0';
      end case;  
    end if;
  end process;

  ready <= rdy_int;

end fsm;
