#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2021 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#---------------------------------------------------------------
# CCID:                 < swastik >
# Lecture Section:      < A1 >
# Instructor:           < J. Nelson Amaral >
# Lab Section:          < D01 >
# Teaching Assistant:   < Siva Chowdeswar Nandipati, Islam Ali  >
#---------------------------------------------------------------
# 

.include "common.s"

#----------------------------------
#        STUDENT SOLUTION
#----------------------------------

#This function translates RISC-V code that is stored in memory at address found in a0 into ARM code and stores that ARM code into the memory address found in a1.

#------------------------------------------------------------------------------
# RISCVtoARM_ALU
# Args:
#	s0: used for moving contents of a0 into a storage register 
#	t1: temporary register to store 0xFFFFFFFF
#	s1: to remeber the addres of a pointer to pre-allocated memory where you will have to write ARM instructions.
#	a0: pointer to memory containing a RISC-V function. The end of the RISC-V instructions is marked by the sentinel word 0xFFFFFFFF.
#
# the main function in the program that enables or controlls the execution of other sub functions. 
#------------------------------------------------------------------------------
RISCVtoARM_ALU:
	addi sp, sp, -12
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	
	mv s0, a0
	mv s1, a1
	
	Loop1:
		lw a0, 0(s0)
		addi s0, s0, 4
		li t1, 0xFFFFFFFF
		beq a0, t1, exit
		jal translateALU
	
		sw a0, 0(s1)
		addi s1, s1, 4
		jal Loop1
	 
	exit:
		lw ra, 0(sp)
		lw s0, 4(sp)
		lw s1, 8(sp)
		addi sp, sp, 12
		ret 
	

#This function translates a single ALU R-type or I-type instruction into an ARM instruction.
#------------------------------------------------------------------------------
# translateALU:
# Args:
#	a0: untranslated RISC-V instruction
#	t0: to store the contents after logical shifting
#	t1: getting the opcode
#	t2: getting the 31st bit
#	t3: storing the temp value
#	t4: storing the temp value
#	t5: storing the values for which we can make the ARM instruction work out when changed from ARU
#	t6: storing the values for which we can make the ARM instruction work out when changed from ARU
#	
#	
# the functiuon which converts the RISC-V instruction to ARM instruction
#------------------------------------------------------------------------------
translateALU:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	slli t0, a0, 25
	srli t0, t0, 25
	
	slli t1, a0, 17
	srli t1, a0, 29
	slli t2, a0, 1
	srli t2, t0, 31
	
	li t3, 19
	li t4, 51
	
	beq t0, t3, Itype
	beq t0, t4, Rtype
	
	Itype:
		# differentiating cases according to the values of opcode
		li t3, 7
		li t4, 6
		li t5, 5 
		li t6, 1
		beq t1, t3, ANDI
		beq t1, t4, ORI
		beq t1, zero, ADDI 
		beq t1, t5, branch1
		beq t1, t6, SLLI 
		
		branch1:
			beq t2, zero, SRLI
			jal SRAI
							
	Rtype:
		# differentiating cases according to the values of opcode
		li t3, 7
		li t4, 6
		li t5, 5 
		li t6, 1
		beq t1, t3, AND
		beq t1, t4, OR
		beq t1, zero, branch2
		beq t1, t5, branch3
		beq t1, t6, SLL
		
		branch2:
			beq t2, zero, ADD
			jal SUB
		
		branch3:
			beq t2, zero, SRL
			jal SRA
			
	ANDI:

		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		mv t0, a0
		jal computeRotation
		mv a0, t5 #immediate
		slli t4, t4, 12
		slli t3, t3, 16
		add a0, a0, t4
		add a0, a0, t3
		li t6, 3616
		li t5, 0
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6 
		
		jal done
					
	AND:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #target register
		mv t5, a0
		
		addi a0, t5, 0
		slli t4, t4, 12
		add a0, a0, t4
		slli t3, t3, 16
		add a0, a0, t3
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 0
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6 
		
		jal done
	
	ORI:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		mv t0, a0
		jal computeRotation
		mv a0, t5 #immediate
		slli t4, t4, 12
		slli t3, t3, 16
		add a0, a0, t4
		add a0, a0, t3
		li t6, 3616
		li t5, 12
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done 
	
	OR:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #target register
		mv t5, a0
		
		add a0, t5, zero
		slli t4, t4, 12
		add a0, a0, t4
		slli t3, t3, 16
		add a0, a0, t3
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 12
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6 
		
		jal done

	
	ADDI:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		mv t0, a0
		jal computeRotation
		mv a0, t5 #immediate
		slli t4, t4, 12
		slli t3, t3, 16
		add a0, a0, t4
		add a0, a0, t3
		li t6, 3616
		li t5, 4
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6 

		jal done
	
	ADD:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #target register
		mv t5, a0
		
		add a0, t5, zero
		slli t4, t4, 12
		add a0, a0, t4
		slli t3, t3, 16
		add a0, a0, t3
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 4
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6 
		
		jal done
	
	SUB:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #target register
		mv t5, a0
		
		add a0, t5, zero
		slli t4, t4, 12
		add a0, a0, t4
		slli t3, t3, 16
		add a0, a0, t3
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 2
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done 
	
	SRAI:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #immediate
		mv t5, a0
		
		li t6, 4
		slli t5, t5, 3
		add t6, t6, t5
		mv a0, t3
		slli t6, t6, 5
		add a0, a0, t6
		slli t4, t4, 12
		add a0, a0, t4
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 13
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6 
		
		jal done
	
	SRLI:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #immediate
		mv t5, a0
		
		li t6, 4
		slli t5, t5, 3
		add t6, t6, t5
		mv a0, t3
		slli t6, t6, 5
		add a0, a0, t6
		slli t4, t4, 12
		add a0, a0, t4
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 13
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done
	SLLI:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #immediate
		mv t5, a0
		
		li t6, 4
		slli t5, t5, 3
		add t6, t6, t5
		mv a0, t3
		slli t6, t6, 5
		add a0, a0, t6
		slli t4, t4, 12
		add a0, a0, t4
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 13
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done
	
	SRA:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #immediate
		mv t5, a0
		
		li t6, 4
		slli t5, t5, 3
		add t6, t6, t5
		mv a0, t3
		slli t6, t6, 5
		add a0, a0, t6
		slli t4, t4, 12
		add a0, a0, t4
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 13
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done
	
	SRL:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #immediate
		mv t5, a0
		
		li t6, 4
		slli t5, t5, 3
		add t6, t6, t5
		mv a0, t3
		slli t6, t6, 5
		add a0, a0, t6
		slli t4, t4, 12
		add a0, a0, t4
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 13
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done
	
	SLL:
		mv a0, t0
		slli a0, a0, 12
		srli a0, a0, 27	
		jal translateRegister
		mv t3, a0 #source register
		slli a0, t0, 20
		srli a0, a0, 27
		jal translateRegister
		mv t4, a0#destination register
		slli a0, t0, 7
		srli a0, a0, 27
		jal translateRegister #immediate
		mv t5, a0
		
		li t6, 4
		slli t5, t5, 3
		add t6, t6, t5
		mv a0, t3
		slli t6, t6, 5
		add a0, a0, t6
		slli t4, t4, 12
		add a0, a0, t4
		
		# generation of upper12 bits
		li t6, 3616
		li t5, 13
		slli t5, t5, 1
		add t6, t6, t5
		srli t6, t6, 20
		add a0, a0, t6
		
		jal done
	
							
	
	

#This function converts the number of a RISC-V register passed in a0 into the number of a corresponding ARM register.
#------------------------------------------------------------------------------
# translateRegister:
# Args:
#	a0:  RISC-V register to translate.
#	t registers: all the temporary registers
#	
# function responsiblke for the conversion  of registers..
#------------------------------------------------------------------------------
translateRegister:
	li t0, 3
	li t1, 10
	li t2, 23
	li t3, 12
	
	blt a0, t0, Trans1 #translation for 1st case
	blt a0, t1, Trans2 #translation for 2st case
	blt a0, t2, Trans3 #translation for 3st case
	bgt a0, t3, Trans4 #translation for 4st case
	
	Trans1:
		add a0, a0, zero
		ret
		
	Trans2:
		li t4, 5
		sub a0, a0, t4
		ret
	
	Trans3:
		li t4, 13
		sub a0, a0, t4
		ret
		
	Trans4:
		li t4, 14
		blt a0, t4, Trans5
		li a0, 14
		ret
		
		Trans5:
			li a0, 13
			ret		
			
					

#This function uses the immediate passed in a0 to generate rotate and immediate fields for an ARM immediate instruction. The function treats the immediate as an unsigned number.
#------------------------------------------------------------------------------
# computeRotation
# Args:
#	a0: RISC-V immediate in the bottom 20 bits.
#	t0: storing immediate 128
#	t5: used for temperory storage
#	
#	
# the function for the rotation of the immediate to 12 bit binary
#------------------------------------------------------------------------------
computeRotation:
	
	slli a0, a0, 12
	srli a0, a0, 12
	
	li t0, 128
	blt a0, t0, gone
	
	Loop2:
		li t6, 0
		blt a0, t0, gone
		srli t5, a0, 30
		slli a0, a0, 2
		add a0, a0, t5
		beq zero, zero, Loop2
	gone:
		ret
	
done:
	lw ra, 0(sp)
	ret	




