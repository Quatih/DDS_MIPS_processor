--------------------------------------------------------------
-- 
-- File             : specifi.vhd
-- Related File(s)  : 
--
-- Author           : E. Molenkamp
-- Email            : molenkam@cs.utwente.nl
-- 
-- Project          : ODS exercise 3
-- Creation Date    : february 2004
-- 
-- Contents         : package       Processor_types
--                  : package body  Processor_types
--                  : entity        processor
--                  : architecture  behaviour of processor
--                  : entity        memory
--                  : architecture  behaviour of memory
--                  : entity        dut
--                  : architecture  memory_processor of dut
--                  : configuration test_of_mem_proc
--
-- History          :
--
--------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
PACKAGE processor_types IS
  SUBTYPE bit16 IS std_ulogic_vector (15 DOWNTO 0);
  SUBTYPE bit8  IS std_ulogic_vector  (7 DOWNTO 0);
  SUBTYPE bit4  IS std_ulogic_vector  (3 DOWNTO 0);
  SUBTYPE bit3  IS std_ulogic_vector  (2 DOWNTO 0);

  -- instruction set
  CONSTANT mov:      bit8:="00000000";
  
  CONSTANT subt:     bit8:="00100000";
  CONSTANT abssub:   bit8:="00100001";
  CONSTANT absmsub:  bit8:="00100010";

  CONSTANT add:      bit8:="00100100";
  CONSTANT absadd:   bit8:="00100101";
  CONSTANT absmadd:  bit8:="00100110";

  CONSTANT maxi:     bit8:="00101000";
  CONSTANT maxa:     bit8:="00101001";
  CONSTANT mini:     bit8:="00101010";
  CONSTANT mina:     bit8:="00101011";

  CONSTANT absl:     bit8:="00101100";
  CONSTANT absmin:   bit8:="00101101";

  CONSTANT mul:      bit8:="00101110";
  CONSTANT absmul:   bit8:="00101111";

  CONSTANT kl:       bit8:="00110000";
  CONSTANT klg:      bit8:="00110001";
  CONSTANT kla:      bit8:="00110010";
  CONSTANT klga:     bit8:="00110011";
  CONSTANT comp:     bit8:="00110100";

  CONSTANT asl:      bit8:="01000000";
  CONSTANT asr:      bit8:="01000001";
  CONSTANT lsl:      bit8:="01000010";
  CONSTANT lsr:      bit8:="01000011";
  CONSTANT rol_87:   bit8:="01000100";
  CONSTANT ror_87:   bit8:="01000101";

  CONSTANT bra:      bit8:="10000000";
  CONSTANT beq:      bit8:="10000001";
  CONSTANT bne:      bit8:="10000010";
  CONSTANT bvs:      bit8:="10000011";
  CONSTANT bvc:      bit8:="10000100";
  CONSTANT bpl:      bit8:="10000101";
  CONSTANT bmi:      bit8:="10000110";

  CONSTANT nset:     bit8:="11100000";
  CONSTANT nclr:     bit8:="11100001";
  CONSTANT zset:     bit8:="11100010";
  CONSTANT zclr:     bit8:="11100011";
  CONSTANT vset:     bit8:="11100100";
  CONSTANT vclr:     bit8:="11100101";

  CONSTANT inca:     bit8:="11110000";
  CONSTANT deca:     bit8:="11110001";

-- source and destination
  CONSTANT none:     bit4:="0000";
  CONSTANT imm:      bit4:="0001";
  CONSTANT rd0:      bit4:="0010";
  CONSTANT rd1:      bit4:="0011";
  CONSTANT ra0:      bit4:="0100";
  CONSTANT ra1:      bit4:="0101";
  CONSTANT a0_ind:   bit4:="0110";
  CONSTANT a1_ind:   bit4:="0111";
  
  
-- sets the conditonal code register bits and rd.
  PROCEDURE set_cc_rd (data : IN integer;
                       cc   : OUT bit3;
                       rd   : OUT bit16);
-- sets the conditonal code register bits and rd.
  TYPE bool2std_ulogic_table IS ARRAY (boolean) OF std_ulogic;
  CONSTANT bool2std:bool2std_ulogic_table:=(false=>'0', true=>'1');
  TYPE direction IS (left,right);
  TYPE domain IS (logical,arithmetic);
  FUNCTION shift(x : std_ulogic_vector; dir:direction; mode:domain)
           RETURN std_ulogic_vector;
  FUNCTION rotate(x: std_ulogic_vector; dir:direction)
           RETURN std_ulogic_vector;
  FUNCTION member(x:std_ulogic_vector;list:std_ulogic_vector)
           RETURN boolean;
           -- is x member of the list, where x is a std_ulogic_vector
           -- and list is a concentatenation of these std_ulogic_vectors
           -- exa. x=001 and list=000_100_011, hence x is not in the list
  
END processor_types;

PACKAGE body processor_types IS
  PROCEDURE set_cc_rd (data : IN integer;
                       cc   : OUT bit3;
                       rd   : OUT bit16) IS
    ALIAS cc_n : std_ulogic IS cc(2);
    ALIAS cc_z : std_ulogic IS cc(1);
    ALIAS cc_v : std_ulogic IS cc(0);
    CONSTANT low  : integer := -2**15;
    CONSTANT high : integer := 2**15-1;
  BEGIN
    IF (data<low) or (data>high)
      THEN -- overflow
        ASSERT false REPORT "overflow situation in arithmetic operation" SEVERITY 
        note;
        cc_v:='1'; cc_n:='-'; cc_z:='-'; rd:=(OTHERS=>'-');
      ELSE
        cc_v:='0'; cc_n:=bool2std(data<0); cc_z:=bool2std(data=0);
        rd := std_ulogic_vector(to_signed(data,16));
    END IF;
  END set_cc_rd;

  FUNCTION shift(x : std_ulogic_vector; dir:direction; mode:domain)
           RETURN std_ulogic_vector IS
    VARIABLE tmp : std_ulogic_vector(x'LENGTH DOWNTO 1):=x;
  BEGIN
    CASE dir IS
    WHEN left  => RETURN tmp(tmp'LENGTH-1 DOWNTO 1) & '0';
    WHEN right =>
      CASE mode IS
        WHEN logical    => RETURN '0' & tmp(tmp'LENGTH DOWNTO 2);
        WHEN arithmetic => RETURN tmp(tmp'LENGTH) & tmp(tmp'LENGTH DOWNTO 2);
      END CASE;
    END CASE;
  END shift;

  FUNCTION rotate(x: std_ulogic_vector; dir:direction) 
           RETURN std_ulogic_vector IS
    VARIABLE tmp : std_ulogic_vector(x'LENGTH DOWNTO 1):=x;
  BEGIN
    CASE dir IS
      WHEN left  => RETURN tmp(tmp'LENGTH-1 DOWNTO 1) & tmp(tmp'LENGTH);
      WHEN right => RETURN tmp(1) & tmp(tmp'LENGTH DOWNTO 2);
    END CASE;
  END rotate;

  FUNCTION member(x:std_ulogic_vector;list:std_ulogic_vector) RETURN boolean IS
    VARIABLE lgt_x : natural := x'LENGTH;
    VARIABLE lgt_list : natural := list'LENGTH;
    VARIABLE llist : std_ulogic_vector(0 TO list'LENGTH-1):=list;
    VARIABLE i : natural := 0;
  BEGIN
    while i<lgt_list LOOP
      IF x=llist(i TO i+lgt_x-1) THEN RETURN true; END IF;
      i:=i+lgt_x;
    END LOOP;
    RETURN false;
  END member;  
  
END processor_types;

-------------------------------------------------     
-------------------------------------------------     
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.processor_types.ALL;
ENTITY processor IS
  PORT (d_busout: OUT bit16;
        d_busin : IN  bit16;
        a_bus   : OUT bit16;
        write   : OUT std_ulogic;
        read    : OUT std_ulogic;
        ready   : IN  std_ulogic;
        reset   : IN  std_ulogic;
        clk     : IN  std_ulogic);
END processor;

LIBRARY ieee;
USE ieee.numeric_std.ALL;
ARCHITECTURE behaviour OF processor IS
BEGIN
  PROCESS
    VARIABLE pc : natural;
    VARIABLE a0 : bit16;
    VARIABLE a1 : bit16;
    VARIABLE d0 : bit16;
    VARIABLE d1 : bit16;    
    VARIABLE cc : bit3;
      ALIAS cc_n  : std_ulogic IS cc(2);
      ALIAS cc_z  : std_ulogic IS cc(1);
      ALIAS cc_v  : std_ulogic IS cc(0);
    VARIABLE data : bit16;
    VARIABLE current_instr:bit16;
      ALIAS op  : bit8 IS current_instr(15 DOWNTO 8);
      ALIAS src : bit4 IS current_instr( 7 DOWNTO 4);
      ALIAS dst : bit4 IS current_instr( 3 DOWNTO 0);
    VARIABLE error_src_dst  : boolean;    -- error in src or dst in insruction
    VARIABLE rs,rd          : bit16;      -- temporary variables
    VARIABLE rs_int, rd_int : integer;    -- integer representation of rs, rd.
    VARIABLE rs_low, rd_low : integer;    --    "        "  positions 7..0 of rs and rd.
    VARIABLE rc            : std_ulogic;  --    "
    VARIABLE displacement  : bit16;
    VARIABLE jump          : boolean;     -- used in branch instructions
    VARIABLE tmp           : bit16;
    CONSTANT one           : bit16 := (0 => '1', OTHERS => '0');
    CONSTANT dontcare      : bit16 := (OTHERS => '-');
    
    PROCEDURE memory_read (addr   : IN natural;
                           result : OUT bit16) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, read, a_bus, d_busin
    -- read data from addr in memory
    BEGIN
      -- put address on output
      a_bus <= std_ulogic_vector(to_unsigned(addr,16));
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;

      LOOP -- ready must be low (handshake)
        IF reset='1' THEN
          RETURN;
        END IF;
        EXIT WHEN ready='0';
        WAIT UNTIL clk='1';
      END LOOP;

      read <= '1';
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;

      LOOP
        WAIT UNTIL clk='1';
        IF reset='1' THEN
          RETURN;
        END IF;

        IF ready='1' THEN
          result:=d_busin;
          EXIT;
        END IF;    
      END LOOP;
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;

      read <= '0'; 
      a_bus <= dontcare;
    END memory_read;                         

    PROCEDURE memory_write(addr : IN natural;
                           data : IN bit16) IS
    -- Used 'global' signals are:
    --   clk, reset, ready, write, a_bus, d_busout
    -- write data to addr in memory
      VARIABLE add : bit16;
    BEGIN
      -- put address on output
      a_bus <= std_ulogic_vector(to_unsigned(addr,16));
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;

      LOOP -- ready must be low (handshake)
        IF reset='1' THEN
          RETURN;
        END IF;
        EXIT WHEN ready='0';
        WAIT UNTIL clk='1';
      END LOOP;

      d_busout <= data;
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;  
      write <= '1';

      LOOP
        WAIT UNTIL clk='1';
        IF reset='1' THEN
          RETURN;
        END IF;
         EXIT WHEN ready='1';  
      END LOOP;
      WAIT UNTIL clk='1';
      IF reset='1' THEN
        RETURN;
      END IF;
      --
      write <= '0';
      d_busout <= dontcare;
      a_bus <= dontcare;
    END memory_write;
    
    PROCEDURE read_data(s_d    : IN bit4;
                        d0, d1 : IN bit16;
                        a0, a1 : IN bit16;
                        pc     : inout natural;
                        data   : OUT bit16) IS   
    -- read data from d0,d1,a0,a1,(a0),(a1),imm
      VARIABLE tmp : bit16;
    BEGIN
      CASE s_d IS
        WHEN rd0    => data := d0;
        WHEN rd1    => data := d1;
        WHEN ra0    => data := a0;
        WHEN ra1    => data := a1;
        WHEN a0_ind => memory_read(to_integer(unsigned(a0)),data);
        WHEN a1_ind => memory_read(to_integer(unsigned(a1)),data);
        WHEN imm    => memory_read(pc,data);
                       pc := pc + 1;
        WHEN OTHERS => ASSERT false REPORT "illegal src/dst while reading data"
                       SEVERITY warning;
      END CASE;
    END read_data;
    
    PROCEDURE write_data(s_d    : IN bit4;
                         d0, d1 : INOUT bit16;
                         a0, a1 : INOUT bit16;
                         pc     : INOUT natural;
                         data   : IN bit16) IS   
    -- write data to d0,d1,a0,a1,(a0),(a1),imm
      VARIABLE tmp:bit16;
      VARIABLE addr: bit16;
    BEGIN
      CASE s_d IS
        WHEN rd0    => d0:=data;
        WHEN rd1    => d1:=data;
        WHEN ra0    => a0 := data;
        WHEN ra1    => a1 := data;
        WHEN a0_ind => memory_write(to_integer(unsigned(a0)),data);
        WHEN a1_ind => memory_write(to_integer(unsigned(a1)),data);
        WHEN imm    => memory_read(pc,addr);
                       pc := pc + 1;
                       memory_write(to_integer(unsigned(addr)),data);
        WHEN OTHERS => ASSERT false REPORT "illegal src or dst while writing data"
                       SEVERITY warning;
      END CASE;
    END write_data;

  BEGIN 
    --
    -- check FOR reset active
    --
    IF reset='1' THEN
      read <= '0';
      write <= '0';
      pc := 0;
      cc := "000"; -- clear condition code register
      LOOP         -- synchrone reset
        WAIT UNTIL clk='1';
        EXIT WHEN reset='0';
      END LOOP;
    END IF;
    --
    -- fetch next instruction
    --
    memory_read(pc,current_instr);
    IF reset /= '1' THEN
      pc:=pc+1;
      --
      -- decode & execute
      -- 
      CASE op IS
      
       WHEN mov =>
         error_src_dst:= NOT member(src,rd0&rd1&ra0&ra1&a0_ind&a1_ind&imm) or
                         NOT member(dst,rd0&rd1&ra0&ra1&a0_ind&a1_ind&imm) or
                         ((src=imm) and (dst=imm));
         ASSERT NOT error_src_dst REPORT "illegal inst. mov"
           SEVERITY warning;
         read_data(src,d0,d1,a0,a1,pc,rs);
         write_data(dst,d0,d1,a0,a1,pc,rs);
         cc := cc;  -- condition code register is unchanged.

       WHEN subt|abssub|absmsub|add|absadd|absmadd|maxi|maxa|mini|mina|
            absl|absmin|mul|absmul =>
         error_src_dst:= NOT member(src,rd0&rd1&a0_ind&a1_ind&imm) or
                         NOT member(dst,rd0&rd1);
         ASSERT NOT error_src_dst REPORT "illegal inst. ARITHMETIC" SEVERITY warning;
         read_data(src,d0,d1,a0,a1,pc,rs); rs_int:=to_integer(signed(rs));
                                           rs_low:=to_integer(signed(rs(7 DOWNTO 0)));
         read_data(dst,d0,d1,a0,a1,pc,rd); rd_int:=to_integer(signed(rd));
                                           rd_low:=to_integer(signed(rd(7 DOWNTO 0)));
         CASE op IS
           WHEN subt    => rd_int :=       rd_int - rs_int;
           WHEN abssub  => rd_int :=  abs( rd_int - rs_int );
           WHEN absmsub => rd_int := -abs( rd_int - rs_int );
           WHEN add     => rd_int :=       rd_int + rs_int;
           WHEN absadd  => rd_int :=  abs( rd_int + rs_int );
           WHEN absmadd => rd_int := -abs( rd_int + rs_int );

           WHEN maxi    => IF      rs_int > rd_int
                             THEN rd_int:=rs_int;
                           END IF;
           WHEN maxa    => IF abs(rs_int) > abs(rd_int)
                             THEN rd_int:=abs(rs_int);
                             ELSE rd_int:=abs(rd_int);
                           END IF;
           WHEN mini    => IF      rs_int < rd_int
                             THEN rd_int:=rs_int;
                           END IF;
           WHEN mina    => IF abs(rs_int) < abs(rd_int)
                             THEN rd_int:=abs(rs_int);
                             ELSE rd_int:=abs(rd_int);
                           END IF;
           WHEN absl    => rd_int := abs(rs_int);
           WHEN absmin  => rd_int := -abs(rs_int);
           WHEN mul     => rd_int :=      rd_low * rs_low;
           WHEN absmul  => rd_int := abs (rd_low * rs_low);
           WHEN OTHERS  => NULL;
         END CASE;
         set_cc_rd(rd_int,cc,rd);
         write_data(dst,d0,d1,a0,a1,pc,rd);

       WHEN kl|klg|kla|klga|comp =>
         error_src_dst:= NOT member(src,rd0&rd1&a0_ind&a1_ind&imm) or
                         NOT member(dst,rd0&rd1);
         ASSERT NOT error_src_dst REPORT "illegal inst. COMPARE" SEVERITY warning;
         read_data(src,d0,d1,a0,a1,pc,rs); rs_int:=to_integer(signed(rs));
         read_data(dst,d0,d1,a0,a1,pc,rd); rd_int:=to_integer(signed(rd));
         CASE op IS
           WHEN kl      => cc_v := bool2std(     rd_int <  rs_int);
           WHEN klg     => cc_v := bool2std(     rd_int <= rs_int );
           WHEN kla     => cc_v := bool2std(abs(rd_int) <  abs(rs_int));
           WHEN klga    => cc_v := bool2std(abs(rd_int) <= abs(rs_int));
           WHEN comp    => cc_v := bool2std( rd = rs);
           WHEN OTHERS  => NULL;
         END CASE;
         cc_n := '-'; cc_z := '-';

       WHEN asl|asr|lsl|lsr|rol_87|ror_87 =>
         error_src_dst:= NOT member(src,none) or
                         NOT member(dst,rd0&rd1);
         ASSERT NOT error_src_dst REPORT "illegal inst. SHIFT" SEVERITY warning;
         read_data(dst,d0,d1,a0,a1,pc,rd);
         CASE op IS
           WHEN asl => rd:=shift(rd,left,arithmetic);
           WHEN asr => rd:=shift(rd,right,arithmetic);
           WHEN lsl => rd:=shift(rd,left,logical);
           WHEN lsr => rd:=shift(rd,right,logical);
           WHEN rol_87 => rd:=rotate(rd,left);
           WHEN ror_87 => rd:=rotate(rd,right);
           WHEN OTHERS  => NULL;
         END CASE;
         cc := "---";
         write_data(dst,d0,d1,a0,a1,pc,rd);

       WHEN bra|beq|bne|bvs|bvc|bpl|bmi =>
         error_src_dst:= NOT member(src,none) or
                         NOT member(dst,a0_ind&a1_ind&imm);
         ASSERT NOT error_src_dst REPORT "illegal inst. BRANCH" SEVERITY warning;
         CASE op IS
           WHEN bra => jump := TRUE;
           WHEN beq => jump := cc_z='1';
           WHEN bne => jump := cc_z='0';
           WHEN bvs => jump := cc_v='1';
           WHEN bvc => jump := cc_v='0';
           WHEN bpl => jump := cc_n='0';
           WHEN bmi => jump := cc_n='1';
           WHEN OTHERS  => NULL;
         END CASE;
         -- condition code register has NOT changed
         IF jump
           THEN
             CASE dst IS
               WHEN imm    => memory_read(pc,displacement);
                              pc := pc +1;
               WHEN a0_ind => memory_read(to_integer(unsigned(a0)),displacement);
               WHEN a1_ind => memory_read(to_integer(unsigned(a1)),displacement);
               WHEN OTHERS => ASSERT false REPORT "illegal destination in BRANCH instruction"
                              SEVERITY warning;
             END CASE;
             pc := pc + to_integer(signed(displacement));
           ELSE IF dst=imm THEN pc := pc + 1; END IF;  -- skip contents next address
         END IF;  

       WHEN nset|nclr|zset|zclr|vset|vclr =>
         error_src_dst:= NOT member(src,none) or
                         NOT member(dst,none);
         ASSERT NOT error_src_dst REPORT "illegal instruction SET or CLR of CC" SEVERITY warning;
         CASE op IS
           WHEN nset    => cc_n:='1';
           WHEN nclr    => cc_n:='0';
           WHEN zset    => cc_z:='1';
           WHEN zclr    => cc_z:='0';
           WHEN vset    => cc_v:='1';
           WHEN vclr    => cc_v:='0';
           WHEN OTHERS  => NULL;
         END CASE;
         -- other condition code bits will be NOT changed

       WHEN inca|deca =>
         error_src_dst:= NOT member(src,none) or
                         NOT member(dst,ra0&ra1);
         ASSERT NOT error_src_dst REPORT "illegal inst. INCA, DECA" SEVERITY warning;
         CASE op IS 
           WHEN inca =>
             CASE dst IS
               WHEN ra0 => IF a0 = (a0'RANGE => '1') -- upper bound?
                             THEN a0 := (OTHERS => '-');
                             ELSE a0 := std_ulogic_vector(unsigned(a0)+1);
                           END IF;
               WHEN ra1 => IF a1 = (a1'RANGE => '1') -- upper bound?
                             THEN a1 := (OTHERS => '-');
                             ELSE a1 := std_ulogic_vector(unsigned(a1)+1);
                           END IF;
               WHEN OTHERS  => NULL;
             END CASE;
           WHEN deca =>
             CASE dst IS
               WHEN ra0 => IF a0 = (a0'RANGE => '0') -- lower bound?
                             THEN a0 := (OTHERS => '-');
                             ELSE a0 := std_ulogic_vector(unsigned(a0)-1);
                           END IF;
               WHEN ra1 => IF a1 = (a1'RANGE => '0') -- lower bound?
                             THEN a1 := (OTHERS => '-');
                             ELSE a1 := std_ulogic_vector(unsigned(a1)-1);
                           END IF;
               WHEN OTHERS  => NULL;
             END CASE;
           WHEN OTHERS => NULL;
         END CASE;    
         cc := "---";

       WHEN OTHERS => ASSERT false REPORT "illegal instruction" SEVERITY warning;

      END CASE;
    END IF;
  END PROCESS;    
END behaviour;

-------------------------------------------------------

-- The entity memory contains conversion functions used in the automatically
-- generated architecture for the memeory.
-- Declaring it locally prevents from using it elsewehere in a design unit.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.processor_types.ALL;
ENTITY memory IS
  GENERIC (tpd  : time := 1 ns);
  PORT(d_busout : OUT bit16;
       d_busin  : IN  bit16;
       a_bus    : IN  bit16;
       write    : IN  std_ulogic;
       read     : IN  std_ulogic;
       ready    : OUT std_ulogic);

  PROCEDURE int2bitv(int : IN integer; bitv: OUT std_ulogic_vector) IS
  BEGIN
    bitv:=std_ulogic_vector(to_signed(int,bitv'LENGTH));
  END int2bitv; 
  
  FUNCTION bitv2int(bitv : IN std_ulogic_vector) RETURN integer IS
  BEGIN
    RETURN to_integer(signed(bitv));
  END bitv2int;

  FUNCTION bitv2nat (bitv : IN std_ulogic_vector) RETURN natural IS
  BEGIN
    RETURN to_integer(unsigned(bitv));
  END bitv2nat;
END memory;
--------------------------------------------------------
ARCHITECTURE behaviour OF memory IS
BEGIN
  PROCESS
    CONSTANT low_address:natural:=0;
    CONSTANT high_address:natural:=300;  -- upper limit of the memory
                                         -- INCREASE this number IF the program
                                         -- needs more memory. Don't FORget
                                         -- that the addresses used to write
                                         -- to and read from should be available.
    TYPE memory_array IS
      ARRAY (natural RANGE low_address TO high_address) OF integer;
    VARIABLE mem:memory_array:=
           (18,                   --        mov #6,d0        0000 0000 0001 0010
            6,                    --                         0000 0000 0000 0110
            20,                   --        mov #62,a0       0000 0000 0001 0100
            62,                   --                         0000 0000 0011 1110
            21,                   --        mov #63,a1       0000 0000 0001 0101
            63,                   --                         0000 0000 0011 1111
            19,                   --        mov #1,d1        0000 0000 0001 0011
            1,                    --                         0000 0000 0000 0001
            54,                   --        mov d1,(a0)      0000 0000 0011 0110
            55,                   --        mov d1,(a1)      0000 0000 0011 0111
            13347,                -- lbl:   comp d0,d1       0011 0100 0010 0011
            -31999,               --        bvs einde:       1000 0011 0000 0001
            9,                    --                         0000 0000 0000 1001
            9235,                 --        add #1,d1        0010 0100 0001 0011
            1,                    --                         0000 0000 0000 0001
            55,                   --        mov d1,(a1)      0000 0000 0011 0111
            11875,                --        mul (a0),d1      0010 1110 0110 0011
            -3836,                --        deca a0          1111 0001 0000 0100
            54,                   --        mov d1,(a0)      0000 0000 0011 0110
            115,                  --        mov (a1),d1      0000 0000 0111 0011
            -32767,               --        bra lbl:         1000 0000 0000 0001
            -12,                  --                         1111 1111 1111 0100
            -32767,               -- einde: bra einde:       1000 0000 0000 0001
            -2,                   --                         1111 1111 1111 1110
          OTHERS => 0
         );   
    VARIABLE address:natural;  
    VARIABLE data_out:bit16;
    CONSTANT unknown : bit16 := (OTHERS=>'-');
  BEGIN
    ready <= '0' AFTER tpd;
    --
    -- WAIT FOR a command
    --
    WAIT UNTIL (read='1') OR (write='1');
    address:=bitv2nat(a_bus);
    ASSERT (address>=low_address) and (address<=high_address)
      REPORT "out of memory range" SEVERITY warning;
    IF write='1'
      THEN
        mem(address):=bitv2int(d_busin);
        ready<='1' AFTER tpd;
        WAIT UNTIL write='0';                -- WAIT UNTIL END of write cycle
      ELSE -- read ='1';
        int2bitv(mem(address),data_out);
        d_busout <= data_out;
        ready<='1' AFTER tpd;
        WAIT UNTIL read='0';
        d_busout <= unknown;
    END IF;
  END PROCESS;
END behaviour;
-------------------------------------------------------------
ENTITY dut IS
END dut;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.processor_types.ALL;
ARCHITECTURE memory_processor OF dut IS
  component memory
    GENERIC (tpd  : time := 1 ns);
    PORT(d_busout : OUT bit16;
         d_busin  : IN  bit16;
         a_bus    : IN  bit16;
         write    : IN  std_ulogic;
         read     : IN  std_ulogic;
         ready    : OUT std_ulogic);
  END component;
  component processor
    PORT (d_busout: OUT bit16;
          d_busin : IN  bit16;
          a_bus   : OUT bit16;
          write   : OUT std_ulogic;
          read    : OUT std_ulogic;
          ready   : IN  std_ulogic;
          reset   : IN  std_ulogic;
          clk     : IN  std_ulogic);
  END component;
  SIGNAL data_from_cpu,data_to_cpu,addr : bit16;
  SIGNAL read,write,ready               : std_ulogic;
  SIGNAL reset                          : std_ulogic := '1';
  SIGNAL clk                            : std_ulogic := '0';
BEGIN
  cpu:processor
      PORT MAP(data_from_cpu,data_to_cpu,addr,write,read,ready,reset,clk);
  mem:memory
      GENERIC MAP (1 ns)
      PORT MAP (data_to_cpu,data_from_cpu,addr,write,read,ready);
  reset <= '1', '0' AFTER 100 ns;
  clk   <= NOT clk AFTER 10 ns;
END memory_processor;
--------------------------------------------------------
CONFIGURATION test_of_mem_proc OF dut IS
  FOR memory_processor
    FOR cpu:processor USE ENTITY work.processor (behaviour); END FOR;
    FOR mem:memory USE ENTITY work.memory (behaviour); END FOR;
  END FOR;
END test_of_mem_proc;
