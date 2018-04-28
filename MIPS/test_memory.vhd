LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.memory_config.ALL;

ARCHITECTURE test OF memory IS
  ALIAS word_address : std_logic_vector(31 DOWNTO 2) IS a_bus(31 DOWNTO 2);
  SIGNAL d_busouti : std_logic_vector(31 DOWNTO 0);
  CONSTANT unknown : std_logic_vector(31 DOWNTO 0) := (OTHERS=>'X');  
  TYPE states IS (idle, rd_wr_nrdy, rd_wr_rdy);
  SIGNAL state : states := idle; -- models state of handshake protocol
BEGIN

  PROCESS
    TYPE text_segment IS ARRAY 
       (natural RANGE text_base_address/4 TO text_base_address/4+text_base_size) -- in model has each memory location 4 bytes, therefore divide by 4
       OF string(8 DOWNTO 1);
    TYPE data_segment IS ARRAY 
       (natural RANGE data_base_address/4 TO data_base_address/4+data_base_size)
       OF string(8 DOWNTO 1);
       
    VARIABLE prg:text_segment:=
           (
-- Code      , -- Basic                     Source
--           , --
"3c011001" , --  lui $1,4097           7            lw $11, Num
"8c2b0000" , --  lw $11,0($1)               
"000bb020" , --  add $22,$0,$11        8    
"340a0001" , --  ori $10,$0,1          11   
"000a5025" , --  or $10,$0,$10         12   
"20190002" , --  addi $25,$0,2         15   
"201a0005" , --  addi $26,$0,5         16   
"033a0018" , --  mult $25,$26          17   
"00006012" , --  mflo $12              18   
"02cc001a" , --  div $22,$12           23   
"0000a012" , --  mflo $20              24   
"22b50001" , --  addi $21,$21,1        25   
"22a90001" , --  addi $9,$21,1         26   
"20010000" , --  addi $1,$0,0          27   
"10340005" , --  beq $1,$20,5               
"0014b020" , --  add $22,$0,$20        28   
"3c170064" , --  lui $23,100           30   
"02d7c02a" , --  slt $24,$22,$23       31   
"20010001" , --  addi $1,$0,1          33   
"1038fff5" , --  beq $1,$24,-11             
"016c001a" , --  div $11,$12           39   
"00006812" , --  mflo $13              40   
"00007010" , --  mfhi $14              41   
"01ee7820" , --  add $15,$15,$14       42   
"000d5820" , --  add $11,$0,$13        43   
"012a4822" , --  sub $9,$9,$10         44   
"0521fff9" , --  bgez $9,-7            45   
"3c011001" , --  lui $1,4097           49   
"ac2f0000" , --  sw $15,0($1)               
"00000000" , --  nop                   54  
               
OTHERS => "00000000" 
            );
  
    VARIABLE data:data_segment:=
           ("0000007b", OTHERS=>"00000000");
  
    VARIABLE address:natural;  
    VARIABLE data_out:std_logic_vector(31 DOWNTO 0);
    
  BEGIN
    WAIT UNTIL rising_edge(clk);
    address:=to_integer(unsigned(word_address));
    -- check text segments
    IF (address >= text_base_address/4) AND (address <=text_base_address/4 + text_base_size) THEN  
       d_busouti <= unknown;    
      IF write='1' THEN
        prg(address):=binvec2hex(d_busin);
      ELSIF read='1' THEN
        d_busouti <= hexvec2bin(prg(address));
      END IF;
    ELSIF (address >= data_base_address/4) AND (address <=data_base_address/4 + data_base_size) THEN
      d_busouti <= unknown;
      IF write='1' THEN
        data(address):=binvec2hex(d_busin);
      ELSIF read='1' THEN
        d_busouti <= hexvec2bin(data(address));
      END IF;    
    ELSIF read='1' OR write='1' THEN  -- address not in text/data segment; read/write not valid.
      REPORT "out of memory range" SEVERITY warning;
      d_busouti <= unknown;
    END IF;
  END PROCESS;
  
  d_busout <= d_busouti WHEN state=rd_wr_rdy ELSE unknown;
  
  -- code below is used to model handshake; variable 'dly' can also be another value than 1 (in state idle) 
  handshake_protocol:PROCESS
    VARIABLE dly : natural; -- nmb of delays models delay 
  BEGIN
    WAIT UNTIL clk='1';
    CASE state IS
      WHEN idle        => IF read='1' OR write='1' THEN state<=rd_wr_nrdy; END IF; dly:=1;
      WHEN rd_wr_nrdy  => IF dly>0 THEN dly:=dly-1; ELSE state<=rd_wr_rdy; END IF;
      WHEN rd_wr_rdy   => IF read='0' AND write='0' THEN state<=idle; END IF;
    END CASE;
  END PROCESS;

  ready <= '1' WHEN state=rd_wr_rdy ELSE '0';
  
  ASSERT NOT (read='1' AND write='1') REPORT "memory: read and write are active" SEVERITY error;
  
  ASSERT (a_bus(1 DOWNTO 0)="00") OR (state=idle) REPORT "memory: not an aligned address" SEVERITY error;   
  
END test;