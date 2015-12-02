;***********************************************************
;*
;*	main.asm
;*
;*	Performs (x+y)^2
;*
;*	This is the skeleton file Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Steven Gloyd
;*	   Date: 10/21/2015
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; An operand
.def	B = r4					; Another operand

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter

.equ	addrA = $0100			; Beginning Address of Operand A data
.equ	addrB = $0103			; Beginning Address of Operand B data
.equ	LAddrP = $0106			; Beginning Address of Product Result
.equ	HAddrP = $010B			; End Address of Product Result
.equ	SUM = $010C


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
INIT:							; The initialization routine
		LDI		mpr, low(RAMEND); Initialize Stack Pointer
		OUT		SPL, mpr
		LDI		mpr, high(RAMEND)
		OUT		SPH, mpr

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't load anything
								; to it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Setup the add funtion
		; Add the two 16-bit numbers
		
		LDI ZL, LOW(PARAMS<<1)	; Point Z at the position in prog memory where the parameters are stored
		LDI ZH, HIGH(PARAMS<<1)
		
		LDI XL, LOW(addrA)		; Point X at the position in data memory where we will store A
		LDI XH, HIGH(addrA)
		
		LPM mpr, Z+				; Load first low byte into data memory
		ST X+, mpr

		LPM mpr, Z+				; Load first high byte into data memory
		ST X, mpr

		LDI XL, LOW(addrB)		; Switch X to the position in data memory where we will store B
		LDI XH, HIGH(addrB)

		LPM mpr, Z+				; Load second low byte into data memory
		ST X+, mpr

		LPM mpr, Z				; Load second high byte into data memory
		ST X, mpr		

		RCALL ADD16				;rcall	ADD16 - Call the add function

		LDI YL, LOW(SUM)
		LDI YH, HIGH(SUM)

		LDI XL, LOW(addrA)		; Point X at the position in data memory where we will store A
		LDI XH, HIGH(addrA)

		LDI ZL, LOW(addrB)		; Switch X to the position in data memory where we will store B
		LDI ZH, HIGH(addrB)

		LD mpr, Y+				; Load the first byte of sum into addrA and addrB
		ST X+, mpr
		ST Z+, mpr

		LD mpr, Y+				; Load the second byte of sum into addrA and addrB
		ST X+, mpr
		ST Z+, mpr

		LD mpr, Y+				; Load the third byte of sum into addrA and addrB
		ST X+, mpr
		ST Z+, mpr

		RCALL MUL24

		; Multiply two 24-bit numbers
		;rcall	MUL24			; Call the multiply function

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		PUSH ZL				; Save variable by pushing them to the stack
		PUSH ZH
		PUSH XL
		PUSH XH
		PUSH A
		PUSH B

		LDI ZL, LOW(addrA)	; Set Z to point at addrA for storage
		LDI ZH, HIGH(addrA)

		LDI XL, LOW(addrB)	; Set X to point at addrB
		LDI XH, HIGH(addrB)

		LDI YL, LOW(SUM)	; Set Y to point to the sum location
		LDI YH, HIGH(SUM)

		LD A, Z+			; Load low bytes into A and B
		LD B, X+

		ADD A, B			; Add A and B

		ST Y+, A			; Store int SUM

		LD A, Z				; Load high bytes into A and B
		LD B, X

		ADC A, B			; Add A and B

		ST Y+, A			; Store in SUM+1

		ADC zero, zero		; Add Zero to Zero with Carry to get carry

		ST Y, zero			; Store the carry into Y

		CLR zero			; Clear zero again
		
		POP B				; Restore variable by popping them from the stack in reverse order
		POP A
		POP XH
		POP XL
		POP ZH
		POP ZL

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data


PARAMS:
.db		0xFF, 0xFF, 0xFF, 0xFF	; A(L:H), B(L:H)
PARAMS_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program