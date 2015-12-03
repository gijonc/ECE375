;***********************************************************
;*
;*	Lab 7 - TekBot Toy
;*
;*	ECE375 lab 7 TekBot toy
;*
;*	This is the RECEIVE skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Steven Gloyd
;*	   Date: 12/2/15
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.DEF	MSG = R17
.DEF	PRVMSG = R18
.def	PRVCMD = R19
.DEF	WAITCNT = R20
.DEF	ILCNT = R21
.DEF	OLCNT = R22
.def	HEALTH = R23

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotID = $55				;(Enter you group ID here (8bits)); Unique XD ID (MSB = 0)

.equ	ZERO = $00
.equ	WTime = 100

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd =	(1<<EngDirR|1<<EngDirL)		;0b01100000 Move Forwards Command
.equ	MovBck =	$00							;0b00000000 Move Backwards Command
.equ	TurnR =		(1<<EngDirL)				;0b01000000 Turn Right Command
.equ	TurnL =		(1<<EngDirR)				;0b00100000 Turn Left Command
.equ	Halt =		(1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Command
.equ	FRZCMD =	$F8							;0b11111000 Shoot Command
.equ	FREEZ =		$FF							;0B11111111	Freeze Command
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	LDI		MPR, HIGH(RAMEND)
	OUT		SPH, MPR
	LDI		MPR, LOW(RAMEND)
	OUT		SPL, MPR
	
	;I/O Ports
	LDI		MPR, $08			; Set Port D to be inputs except TXR1
	OUT		DDRD, MPR

	LDI		MPR, $FF			; Set Port B to outputs
	OUT		DDRB, MPR

	;USART1
	LDI		MPR, $01			;Set baudrate to 2400bps
	STS		UBRR1H, MPR
	LDI		MPR, $A0
	STS		UBRR1L, MPR

	LDI		MPR, (1<<RXEN1|1<<TXEN1)										;Enable transmitter
	STS		UCSR1B, MPR
	LDI		MPR, (1<<UPM11|1<<USBS1|1<<UCSZ11|1<<UCSZ10)		;Set frame format: 8 data bits, 2 stop bits
	STS		UCSR1C, MPR

	;Other
	LDI		PRVCMD, MOVFWD		; Initialize values
	LDI		HEALTH, 4

	LDI		MPR, MOVFWD			; Start moving forward
	OUT		PORTB, MPR


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		SBIS	PIND, PIND0			; Check if either bumper was hit and respond accordingly
		RCALL	HITRIGHT
		SBIS	PIND, PIND1
		RCALL	HITLEFT

		LDS		MPR, UCSR1A			; Check if there is a new message
		SBRS	MPR, RXC1			; If not, jump back to main
		RJMP	MAIN

		MOV		PRVMSG, MSG			; Store the last message
		LDS		MSG, UDR1			; Load in the new message
		
		SBRS	MSG, 7				; If the top bit of the msg is set (CMD) continue
		RJMP	MAIN				; Else its garbage and jump to main

		CPI		MSG, FREEZ			; If the message is a freeze command, call freeze
		BRNE	SKPFRZ
		RCALL	FREEZE
		RJMP	MAIN

SKPFRZ: LDI		MPR, BOTID			; Past this point, we require the prvmsg to have been the correct address
		CPSE	PRVMSG, MPR				
		RJMP	MAIN

		CPI		MSG, FRZCMD
		BRNE	SKPST
		RCALL	SHOOT
		RJMP	MAIN

SKPST:	LSL		MSG					; Only valid motor commands will make it here
		MOV		PRVCMD, MSG			; Save the motor command for restoration after freezing
		OUT		PORTB, MSG			; Shift if left and out it to the motors

END:	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HITRIGHT:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backwards command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		rcall	Wait

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forwards command
		out		PORTB, mpr	; Send command to port

		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret					; Return from subroutine


;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HITLEFT:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backwards command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forwards command
		out		PORTB, mpr	; Send command to port

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine


;----------------------------------------------------------------
; Sub:	Freeze
; Desc:	Halts the robot when it is hit by a freeze
;----------------------------------------------------------------

FREEZE:
		CPI		PRVMSG, BOTID			; Don't freeze if the sending address was its own
		BREQ	CNCL

		LDI		MPR, HALT
		OUT		PORTB, MPR
		
		LDI		WAITCNT, 250			; Wait	5 seconds
		RCALL	WAIT
		RCALL	WAIT

		DEC		HEALTH					; Remove a life
		CPI		HEALTH, 0				; If lives are at 0
DEAD:	BREQ	DEAD					; Loop forever
		OUT		PORTB, PRVCMD			; Otherwise, restore the previous valid motor state

CNCL:	RET


;----------------------------------------------------------------
; Sub:	Shoot
; Desc:	Fires a Freez shot to other robots
;----------------------------------------------------------------

SHOOT:
		LDI		WAITCNT, 2				; Wait so we dont have too many messages flying around
		RCALL	WAIT

		LDS		MPR, UCSR1A
		SBRS	MPR, UDRE1
		RJMP	SHOOT
		LDI		MPR, BOTID
		STS		UDR1, MPR
		
RETRY:	LDS		MPR, UCSR1A				; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	MPR, UDRE1
		RJMP	RETRY					; Loop if not ready for new message
		LDI		MPR, FREEZ				; When ready, load a FREEZ command to be sent
		STS		UDR1, MPR

		RET


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
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************