;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	SPDREP = r17
.def	SPD = r18
.def	waitcnt = r19
.def	olcnt = r20
.def	ilcnt = r21

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit
.equ	waittime = 10

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002					; INT0
		rcall	TURNUP
		reti

.org	$0004
		rcall	TURNDOWN
		reti

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:

		LDI		MPR, HIGH(RAMEND)	; Initialize the Stack Pointer
		OUT		SPH, MPR
		LDI		MPR, LOW(RAMEND)
		OUT		SPL, MPR

		LDI		MPR, $FF			; Configure I/O ports
		OUT		DDRB, MPR			; Port B is set up for outputs
		LDI		MPR, $00
		OUT		DDRD, MPR			; Port D is set up for Inputs

		LDI		MPR, $00			; Configure External Interrupts, if needed
		STS		EICRA, MPR			; Set INT0:1 to low level triggering

		LDI		MPR, 0b01110001		; Configure 8-bit Timer/Counters (Fast PWM, clear on compare match, no prescaling)
		OUT		TCCR0, MPR			; Set OC0 (PB4, Right Enable)
		OUT		TCCR2, MPR			; Set OC2 (PB7, Left Enable)

		LDI		MPR, 0b01100000		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)
		OUT		PORTB, MPR

		LDI		SPD, 255			; Set initial speed, display on Port B
		OUT		OCR0, SPD			; Set right motor initial speed
		OUT		OCR2, SPD			; Set left motor initial speed
		
		IN		MPR, PORTB
		ANDI	MPR, 0xF0
		LDI		SPDREP, 0x0F
		OR		MPR, SPDREP
		OUT		PORTB, MPR			; Ouput speed level

		LDI		MPR, 0b00000011		; Enable global interrupts (if any are used)
		OUT		EIMSK, MPR			; Enable INT0:1
		SEI

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;*	TURNUP: Turn up the speed
;*	Desc: Turns the speed of the motors up
;-----------------------------------------------------------
TURNUP:
		PUSH	MPR			
		
		CPI		SPD, $FF
		BREQ	SKIPUP	
			
		LDI		MPR, 17				; Increment by 17 due to weird gltich?
		ADD		SPD, MPR
		OUT		OCR0, SPD			; Set right motor speed
		OUT		OCR2, SPD			; Set left motor speed

		IN		MPR, PORTB
		ANDI	MPR, 0xF0
		INC		SPDREP
		OR		MPR, SPDREP
		OUT		PORTB, MPR			; Ouput speed level

LOOPUP:	
		IN		MPR, PIND
		COM		MPR
		BRNE	LOOPUP

		LDI		waitcnt, waittime
		RCALL	WAIT

SKIPUP:
		POP		MPR

		ret							; End a function with RET

;***********************************************************
;*	TURNDOWN: Turn down the speed
;*	Desc: Turns the speed of the motors down
;-----------------------------------------------------------
TURNDOWN:
		PUSH	MPR				
	
		CPI		SPD, $00
		BREQ	SKIPDN	

		LDI		MPR, -17				; Increment by 17 due to weird gltich?
		ADD		SPD, MPR
		OUT		OCR0, SPD			; Set right motor speed
		OUT		OCR2, SPD			; Set left motor speed

		IN		MPR, PORTB
		ANDI	MPR, 0xF0
		DEC		SPDREP
		OR		MPR, SPDREP
		OUT		PORTB, MPR			; Ouput speed level

LOOPDN:	
		IN		MPR, PIND
		COM		MPR
		BRNE	LOOPDN

		LDI		waitcnt, waittime
		RCALL	WAIT

SKIPDN:

		POP		MPR

		ret							; End a function with RET

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Func: Template function header
;*	Desc: Cut and paste this and fill in the info at the 
;*		  beginning of your functions
;-----------------------------------------------------------
FUNC:	; Begin a function with a label

		; Save variables by pushing them to the stack

		; Execute the function here
		
		; Restore variables by popping from stack in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program