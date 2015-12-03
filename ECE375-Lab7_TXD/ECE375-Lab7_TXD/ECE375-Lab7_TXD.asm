;***********************************************************
;*
;*	Lab 7 - Remote Trasmitter
;*
;*	ECE375 lab 7 remote transmitter for TekBot control
;*
;*	This is the TRANSMIT skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Steven Gloyd
;*	   Date: 11/26/15
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.equ	EngDirR = 5				; Motor Control Bit Definitions
.equ	EngDirL = 6
.equ	EngEnR = 4
.equ	EngEnL = 7

.equ	ADDR = $55				; Define Remote Address (Nick's: $27)

; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forwards Command
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backwards Command
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Command
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Command
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Command
.equ	Freez =   ($80|$F8)
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$003C
		RCALL	TSTTR
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
	LDI		MPR, $08			; Set Port D's lower nibble to be inputs except TXR1, upper nibble to be inputs
	OUT		DDRD, MPR

	LDI		MPR, $FF			; Set Port B to outputs
	OUT		DDRB, MPR
	
	;USART1
	LDI		MPR, $01			;Set baudrate to 2400bps
	STS		UBRR1H, MPR
	LDI		MPR, $A0
	STS		UBRR1L, MPR

	LDI		MPR, (1<<RXCIE1|1<<RXEN1|1<<TXEN1)										;Enable transmitter
	STS		UCSR1B, MPR
	LDI		MPR, (1<<UPM11|1<<USBS1|1<<UCSZ11|1<<UCSZ10)		;Set frame format: 8 data bits, 2 stop bits
	STS		UCSR1C, MPR

	;Other
	SEI

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		IN		MPR, PIND		; Poll PortD for inputs
		ANDI	MPR, $F3		; Isolate Inputs

		LDI		R17, $E3		; Check if Forward is pressed (0b11010000)
		CP		MPR, R17
		BRNE	SKPFWD
		RCALL	TRANSFWD

SKPFWD: LDI		R17, $D3		; Check if Reverse is pressed (0b11100000)
		CP		MPR, R17
		BRNE	SKPREV
		RCALL	TRANSREV

SKPREV: LDI		R17, $B3		; Check if Right is pressed (0b10110000)
		CP		MPR, R17
		BRNE	SKPRGT
		RCALL	TRANSRGT

SKPRGT: LDI		R17, $73		; Check if Left is pressed (0b01110000)
		CP		MPR, R17
		BRNE	SKPLFT
		RCALL	TRANSLFT

SKPLFT:	LDI		R17, $F1
		CP		MPR, R17
		BRNE	SKPHLT
		RCALL	TRANSHLT

SKPHLT:	LDI		R17, $F2
		CP		MPR, R17
		BRNE	SKPTAG
		RCALL	TRANSTAG

SKPTAG:	RJMP	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

TRANSFWD:
		PUSH	MPR
		PUSH    R17

REFWDA:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	REFWDA			; Loop if not ready for new message
		LDI		MPR, ADDR
		STS		UDR1, MPR

REFWD:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	REFWD			; Loop if not ready for new message
		LDI		MPR, MovFwd
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

		RET

TRANSREV:
		PUSH	MPR
		PUSH    R17

REREVA:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	REREVA			; Loop if not ready for new message
		LDI		MPR, ADDR
		STS		UDR1, MPR

REREV:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	REREV			; Loop if not ready for new message
		LDI		MPR, MovBck
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

		RET	

TRANSRGT:
		PUSH	MPR
		PUSH    R17

RERGTA:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RERGTA			; Loop if not ready for new message
		LDI		MPR, ADDR
		STS		UDR1, MPR

RERGT:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RERGT			; Loop if not ready for new message
		LDI		MPR, TurnR
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

		RET	

TRANSLFT:
		PUSH	MPR
		PUSH    R17

RELFTA:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RELFTA			; Loop if not ready for new message
		LDI		MPR, ADDR
		STS		UDR1, MPR

RELFT:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RELFT			; Loop if not ready for new message
		LDI		MPR, TurnL
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

		RET	

TRANSHLT:
		PUSH	MPR
		PUSH    R17

REHLTA:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	REHLTA			; Loop if not ready for new message
		LDI		MPR, ADDR
		STS		UDR1, MPR

REHLT:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	REHLT			; Loop if not ready for new message
		LDI		MPR, HALT
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

		RET

TRANSTAG:
		PUSH	MPR
		PUSH    R17

RETAGA:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RETAGA			; Loop if not ready for new message
		LDI		MPR, ADDR
		STS		UDR1, MPR

RETAG:	LDS		R17, UCSR1A		; Check if UDR1 is empty, i.e. ready to send new message
		SBRS	R17, UDRE1
		RJMP	RETAG			; Loop if not ready for new message
		LDI		MPR, Freez
		STS		UDR1, MPR
		
		POP		R17
		POP		MPR

		RET

TSTTR:
		PUSH	MPR
		
		LDS		MPR, UDR1
		OUT		PORTB, MPR
		
		POP		MPR

		RET

;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************