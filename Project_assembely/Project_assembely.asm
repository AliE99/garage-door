/*
 * Project_assembely.asm
 *
 *  Created: 1/27/2021 2:54:01 PM
 *   Author: MohammadAmin Shafiee
 */ 


 .INCLUDE "M32DEF.INC"

 .ORG 0
	JMP MAIN
	
.ORG 0x02
	JMP EX0_ISR
.ORG 0x04
	JMP EX1_ISR
.ORG 0x06
	JMP EX2_ISR

MAIN:
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16

	; R17 is used for keep track of things 
	LDI R17, 0x0
	; R18 
	LDI R16, 0x00
	OUT DDRC, R16 ; make portc input
	LDI R16, 0xFF
	OUT DDRA, R16 ; make porta output

	SBI PORTD, 2 ; INT0
	SBI PORTD, 3 ; INT1
	SBI PORTB, 2 ; INT2

	LDI R16, (1<<ISC01 | 1<<ISC11)
	OUT MCUCR, R16
	; enabling interrupts
	LDI R16, (1<<INT1 | 1<<INT0 | 1<<INT2)
	OUT GICR, R16
	SEI

HERE: JMP HERE

; means someone is passing through the door
EX0_ISR:
	LDI R20, 0x01
	EOR R17, R20 ;toggling the state of door passing
	RETI

EX1_ISR:
	IN R20, PINC
	
	CPI R20, 0x01 ; its opening
		BREQ IS_OPENING
	CPI R20, 0x02 ; its half opening
		BREQ IS_HALF_OPENING
	CPI R20, 0x04 ; its closing
		BREQ IS_CLOSING
	
	JMP OVER
IS_OPENING:
	CPI R17, 0x01 ;SOMEONE IS PASSING THROUGH
	BREQ MUST_MAINTAIN_POSITION
		;no one is passing door must be closed
		LDI R16, 0x01
		OUT PORTA, R16
		JMP OVER
	 		
	MUST_MAINTAIN_POSITION:
		LDI R16, 0x02
		OUT PORTA, R16
  
	JMP OVER

IS_HALF_OPENING:
	CPI R17, 0x01; someone is PASSING THROUGH
	BREQ MUST_OPEN_THE_DOOR_I
		LDI R16, 0x02 ; else can maintain position which is HALF OPEN
		OUT PORTA, R16
		JMP OVER

IS_CLOSING:
	CPI R17, 0x01 ; if someone is passing through
	BREQ MUST_OPEN_THE_DOOR_I
		LDI R16, 0x01; door must be closed because no one is passing 
		OUT PORTA, R16
		JMP OVER

MUST_OPEN_THE_DOOR_I:
	LDI R16, 0x04
	OUT PORTA, R16

OVER:
	
	RETI

EX2_ISR:
	SBIS PORTB, 2; if 1 skip (means its closed skip)
	JMP OPENING_POSITION

		CPI R17, 0x01 ; if someone pass through the door
		BREQ HOLD_POSITION
			; means no one is passing through the door and door can be closed
			LDI R16, 0x01 ;
			OUT PORTA, R16
			JMP over2
		; means door was open and someone is passing through the door door must keep the position(open)
		HOLD_POSITION:
			LDI R16, 0x02
			OUT PORTA, R16
			JMP over2
	; means requested opening the door
	OPENING_POSITION:
		CPI R17, 0x01 ; if someone is passing through the door
		BREQ MUST_OPEN_THE_DOOR 
			; means no one on door and door was colosed must hol the position
			JMP HOLD_POSITION

		MUST_OPEN_THE_DOOR:
			; door must be opened
			LDI R16, 0x04
			OUT PORTA, R16
	over2:
		
		RETI

	