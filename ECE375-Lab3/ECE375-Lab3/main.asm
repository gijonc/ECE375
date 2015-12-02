;***********************************************************
;*
;*	 Author: Steven Gloyd
;*	   Date: 10/14/15
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register required for LCD Driver
.def	ReadCnt = r23


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		ldi		mpr, LOW(RAMEND); Initialize Stack Pointer
		OUT		SPL, mpr		; Init the 2 stack pointer registers
		ldi		mpr, HIGH(RAMEND)
		OUT		SPH, mpr

		; Initialize LCD Display
		RCALL	LCDInit			; An RCALL statement

		; Move strings from Program Memory to Data Memory
		ldi		YL, LOW(0x0100)
		ldi		YH, HIGH(0x0100)
		ldi		ZL,	LOW(STRING<<1)
		ldi		ZH, HIGH(STRING<<1)
		ldi		ReadCnt, LCDMaxCnt

LOADLOOPONE:
		LPM		mpr, Z+
		ST		Y+, mpr
		DEC		ReadCnt
		BRNE	LOADLOOPONE		; A while loop will go here

		ldi		YL, LOW(0x0110)
		ldi		YH, HIGH(0x0110)
		ldi		ReadCnt, LCDMaxCnt

LOADLOOPTWO:
		LPM		mpr, Z+
		ST		Y+, mpr
		DEC		ReadCnt
		BRNE	LOADLOOPTWO		; A while loop will go here

		; NOTE that there is no RET or RJMP from INIT, this is
		; because the next instruction executed is the first for
		; the main program

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Display the strings on the LCD Display
		RCALL	LCDWrite		; An RCALL statement
		
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order\
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

;----------------------------------------------------------
; An example of storing a string, note the preceeding and
; appending labels, these help to access the data
;----------------------------------------------------------
STRING:
.DB		"Steven Gloyd    "
.DB		"My First AVR    "		; Storing the string in Program Memory
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

