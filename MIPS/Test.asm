.data
B: .word 
Num: .word 123

.text
    lw $11, Num     	
	add $22, $0, $11	      #num stored for no.of digit calculation
	ori $10, $0,  1		      #dummy line to test ori Statement
	or $10, $0, $10		      #dummy line to test or statement
	
    #to get reg12 with value 10. it does by multipling two registers reg25 and reg26 having the value 2 and 5
	addi $25, $0, 2		
	addi $26, $0, 5
	mult $25, $26		     
	mflo $12
		
	#calculates number of digits in the given number
	Loop:
	div $22, $12
	mflo $20 		         #last digit
	addi $21, $21, 1	     #counter increment
	addi $9, $21, 1		     #transfers counter value+1 to main program	
	beq $20, 0, Main
	add $22, $0, $20
	lui $23, 100		     #dummy line to test lui statemenrt
	slt $24, $22, $23  	     #dummy line to test slt statement
	beq $24, 1, Loop
		
	
	#calculate sum of digits
	Main:
	div $11, $12
	mflo $13 
	mfhi $14                 #reminder
	add $15, $15, $14	     #add digits
	add $11, $0,$13			
	sub $9, $9, $10		     #decrementing counter value
	bgez $9,Main
		
	#storing value in reg15
	sw $15, B                #store result
	End:                     #end 
	nop 
	.data
	
        
	
	
	
	
	
	
	

	
	
	
