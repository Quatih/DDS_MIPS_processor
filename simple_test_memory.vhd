

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.memory_config.ALL;
ENTITY simple_test_memory IS
END simple_test_memory;

ARCHITECTURE tb OF simple_test_memory IS
  COMPONENT memory IS
    PORT(d_busout : OUT std_logic_vector(31 DOWNTO 0);
         d_busin  : IN  std_logic_vector(31 DOWNTO 0);
         a_bus    : IN  std_logic_vector(31 DOWNTO 0);
         clk      : IN  std_ulogic;
         write    : IN  std_ulogic;
         read     : IN  std_ulogic;
         ready    : OUT std_ulogic
         );
  END COMPONENT memory;

  SIGNAL d_busout : std_logic_vector(31 DOWNTO 0);
  SIGNAL d_busin  : std_logic_vector(31 DOWNTO 0):=(OTHERS=>'0');
  SIGNAL a_bus    : std_logic_vector(31 DOWNTO 0):=(OTHERS=>'0');
  SIGNAL clk      : std_ulogic:='0';
  SIGNAL write    : std_ulogic:='0';
  SIGNAL read     : std_ulogic:='0';
  SIGNAL ready    : std_ulogic;
  SIGNAL finished : boolean := false;

  PROCEDURE rd (addr : natural; 
                VARIABLE data   : OUT std_logic_vector(31 DOWNTO 0);
                SIGNAL d_in     : IN  std_logic_vector(31 DOWNTO 0);
                SIGNAL a_bus    : OUT std_logic_vector(31 DOWNTO 0);
                SIGNAL read     : OUT std_ulogic;
                SIGNAL ready    : IN  std_ulogic) IS
  BEGIN
    WAIT UNTIL clk='0';
    a_bus<=std_logic_vector(to_unsigned(addr,32));
    read<='1';
    LOOP
      WAIT UNTIL clk='0';
      EXIT WHEN ready='1';
    END LOOP;
    data := d_in;
    read <='0';
    LOOP
      WAIT UNTIL clk='0';
      EXIT WHEN ready='0';
    END LOOP;  
  END rd;  
  
  PROCEDURE wr (addr           : IN  natural; 
                data           : IN  integer;
                SIGNAL d_out   : OUT std_logic_vector(31 DOWNTO 0);
                SIGNAL a_bus   : OUT std_logic_vector(31 DOWNTO 0);
                SIGNAL write   : OUT std_ulogic;
                SIGNAL ready   : IN  std_ulogic) IS
  BEGIN
    WAIT UNTIL clk='0';
    a_bus <=std_logic_vector(to_unsigned(addr,32));
    write <='1';
    d_out <= std_logic_vector(to_signed(data,32));
    LOOP
      WAIT UNTIL clk='0';
      EXIT WHEN ready='1';
    END LOOP;
    write <='0';
    LOOP
      WAIT UNTIL clk='0';
      EXIT WHEN ready='0';
    END LOOP;  
  END wr;    
  
  
BEGIN
  mem:memory PORT MAP (d_busout,d_busin,a_bus,clk,write,read,ready);

  clk <= NOT clk AFTER 10 ns WHEN not finished;
  

  
  PROCESS
    VARIABLE do :std_logic_vector(31 DOWNTO 0);
  BEGIN
    WAIT UNTIL clk='0';
	-- read first instruction from the program
	rd(text_base_address,do,d_busout,a_bus,read,ready);
	-- read second instruction from the program
	rd(text_base_address+4,do,d_busout,a_bus,read,ready);	
	-- Write data to address data_base_address+8
  wr(data_base_address+8,20,d_busin,a_bus,write,ready);
	finished <= TRUE;	
  END PROCESS;

  
  
END tb;