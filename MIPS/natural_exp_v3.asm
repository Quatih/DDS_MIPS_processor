## Demo exponent (e^x) with x is an integer value  
## e^x = 1 + x + x^2/2! + x^3/3! + ... x^n/n!
## An integer divison is used, i.e.  7/3 is equal to 2.
## To have more precision 1000 x e^x is determined.
## The global structure of the program is:
## - section x^n calculates power(x,n)
## - section n! calculates the faculty of n
## - section series approximates 1000xe^x;
##   note that it is not an efficient program; 
##   calculation of x^n and n! does not use the previous term (i.e. x^(n-1) and (n-1)!)
## For readability pseudo instructions are used.
## https://en.wikibooks.org/wiki/MIPS_Assembly/Pseudoinstructions
## 
.data
N:  .word 7 # number of terms of the series 
X:  .word -1 # X  
EX: .word 0 # e^X (result)
.text
.globl  main
main:
b	ser # branch always to ser; is assembled to: bgez $0, ser
#### x^n
#	ori $5, $0, 5    # n
#	ori $6, $0, 2    # x
# pre-condition for power: x is in $6, and n is in $5
xn:	ori $7, $0, 1    # res
nxt:	ble $5, $0, fexp # if [R5]<=[$0] branch; assembled to slt $1, $0, %5 and beq $1, $0, fexp
	mult $7, $6      # LO=res * x
	mflo $7          # res=res * x
	addi $15, $0, 1
	sub $5, $5, $15  # n=n-1
	b nxt
fexp:	b fxn
##### end x^n
##### n!
#:	ori $8, $0, 5    # n
# pre-condition for faculty: n is in $8
f:	ori $9, $0, 1    # res
nfac:	addi $15, $0, 1
	ble $8, $0, ffac # branch if [$8]<=[$0]; assembled to slt and beq
	mult $9, $8      # res=res*n
	mflo $9
	addi $15, $0, 1
	sub $8, $8, $15  # n=n-1	
	b nfac           
ffac:	b ff
##### end n!	
##### series
ser:	
  lw $10, N              # number of terms; assembled in LUI and LW (this depends on location of N)
  lw $13, X              # value x
	ori $11, $0, 1    # index
	ori $12, $0, 1000 # approximation exp (first term always 1) (multiplied with 1000)
	#or $13, $0, 2    # value x
# ntrm:	slt $15, $11, $10 # branch greater or equal
#	beq $15, $0, rdy
ntrm:	ble $10, $11, rdy	
	or $5, $0, $11    # calculate x^n
	or $6, $0, $13
	b xn    # branch always to xn; calculate x^n
fxn:	# result x^n in $7
	addi $15, $0, 1000
	mult $7, $15      # LO=multiply with 1000
	mflo $7
	or $8, $0, $11 
	b f               # branch always to f; calculate n!
ff:	# result n! in $9
	div  $7, $9       # 1000x2^n/n! in $14
	mflo $14
	add $12, $12, $14 # sn=s(n-1)+term
	add $11, $11, 1   # i++
	b ntrm  # branch always to ntrm
rdy:	  sw $12,EX # e^x in EX
  nop
	.data
# End of file
