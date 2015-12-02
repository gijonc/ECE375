;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 7 of ECE 375
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
.def	mpr = r16				; Multi-Purpose Register
.DEF	MPR2 = R23
.DEF	ADDR = R17
.DEF	CMD = R18
.DEF	PRVCMD = R19
.DEF	WAITCNT = R20
.DEF	ILCNT = R21
.DEF	OLCNT = R22

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotID = $27				;(Enter you group ID here (8bits)); Unique XD ID (MSB = 0)

.equ	ZERO = $00

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd =	(1<<EngDirR|1<<EngDirL)		;0b01100000 Move Forwards Command
.equ	MovBck =	$00							;0b00000000 Move Backwards Command
.equ	TurnR =		(1<<EngDirL)				;0b01000000 Turn Right Command
.equ	TurnL =		(1<<EngDirR)				;0b00100000 Turn Left Command
.equ	Halt =		(1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Command
.equ	FREEZ =		$F0							;0B11110000	Freeze Command
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
.org	$0002					;- Right whisker
		RCALL	HITRIGHT
		RETI

.org	$0004					;- Left whisker
		RCALL	HITLEFT
		RETI

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
	
	;Interrupts
	LDI		MPR, $03			; Enable INT0:1, leave as default low level
	OUT		EIMSK, MPR

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
	LDI		ADDR, BOTID
	LDI		CMD, MOVFWD

	SEI


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		LDS		MPR, UCSR1A
		SBRS	MPR, RXC1
		RJMP	MAIN
		RCALL	RECEIVE

		CPI		ADDR, BOTID		; Check if the last recieved ADDR is valid 
		BRNE	END				; If not, do nothing different
		
		CPI		CMD, FREEZ		; Check if the CMD is to shoot
		BRNE	NOFIRE			; If its not, don't shoot
		RCALL	TRANSFRZ
		MOV		CMD, PRVCMD		; After, load back the last valid motor command

NOFIRE:	OUT		PORTB, CMD		; If the address is valid, load the command to the motors

END:	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

RECEIVE:
		PUSH	MPR
		
		LDS		MPR, UDR1		; Read in recieved data
		SBRC	MPR, 7			; If its 0 (ID) load it into ADDR. Otherwise (1 is a command) load into CMD
		RJMP	CMDREC
		MOV		ADDR, MPR
		RJMP	ENDREC
		
CMDREC:	CPI		MPR, $FF		; Check if the recieved CMD is a freeze from another TekBot
		BRNE	SKPFRZ			; If not move on
		RCALL	FREEZE			; If so call FREEZE
		RJMP	ENDREC			; DO NOT save this command as a motor command

SKPFRZ:	LSL		MPR				; Convert the serial transmission into a motor command
		LDI		MPR2, FREEZ		; Check if the command is the shoot command
		CPSE	MPR, MPR2		; Never load PRVCMD with a shoot command
		MOV		PRVCMD, CMD
		MOV		CMD, MPR		; Load any command into CMD


ENDREC:	POP		MPR

		RET


HITRIGHT:
		LDI		MPR, $FF
		OUT		PORTB, MPR
		RET


HITLEFT:
		RET


FREEZE:
		//LDI		MPR, BOTID
		//CPSE	ADDR, MPR
		LDI		CMD, $55

		RET


TRANSFRZ:
		PUSH	MPR
		PUSH    R17

		LDI		WAITCNT, 2
		RCALL	WAIT

RE:		LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RE				; Loop if not ready for new message
		LDI		MPR, BOTID
		STS		UDR1, MPR

RE2:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RE2				; Loop if not ready for new message
		LDI		MPR, $FF
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

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

