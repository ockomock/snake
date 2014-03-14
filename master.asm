
/* Master */

.INCLUDE "m8def.inc"

	.def SCORE = r17
	.def TMP = r16
	.def S_INPUT = r18

		ldi TMP,0xFF
		out DDRD,TMP

		ldi SCORE,0x00

SPI_Init:
		sbi DDRB,DDB3			; Set MOSI as output.
		sbi DDRB,DDB5			; Set SCK as output.
		sbi DDRB,DDB2			; Set SS' as output.
		ldi r16,0b01111101		; Set SPI as a Master, with interrupt disabled,
		out SPCR,TMP			; MSB first, SPI mode 3 and clock frequency fosc/16.


AD_INIT:
		ldi r16,0b10000101
		out ADCSR,TMP
 

STACK_INIT:
		ldi TMP,LOW(RAMEND)
		out SPL,TMP
		ldi TMP,HIGH(RAMEND)
		out SPH,TMP


MAINLOOP:

/**
	Send X
**/
READ_ADX:
		ldi TMP,0b01000001 ; etta sist = x
		out ADMUX,TMP
		sbi ADCSR,ADSC

WAIT_ADX:
		sbis ADCSR,ADIF
		rjmp WAIT_ADX
 
		in TMP,ADCH
		cpi TMP,0x03
		breq RIGHT
		cpi TMP,0x00
		breq LEFT
		rjmp READ_ADY

RIGHT:	
		ldi TMP,0x01
		rjmp SEND
LEFT:
		ldi TMP,0x03
		rjmp SEND

/**
	Send Y
**/
READ_ADY:
		ldi TMP,0b01000000 ; nolla sist = y
		out ADMUX,TMP
		sbi ADCSR,ADSC

WAIT_ADY:
		sbis ADCSR,ADIF
		rjmp WAIT_ADY
 
		in TMP,ADCH
		cpi TMP,0x03
		breq UP
		cpi TMP,0x00
		breq DOWN
		rjmp NO_DIRECTION	; skicka om du inte rör dig?
UP:	
		ldi TMP,0x00
		rjmp SEND
DOWN:
		ldi TMP,0x02
		rjmp SEND

NO_DIRECTION:				; no direction
		ldi TMP,0xFF
		rjmp SEND

SEND:
		rcall SPI_SEND
		rjmp MAINLOOP		; Hoppa till MAINLOOP

SPI_SEND:
		out SPDR,TMP
SPI_WAIT:
		sbis SPSR,SPIF
		rjmp SPI_WAIT
		in S_INPUT,SPDR
		
		cpi S_INPUT,0xF0
		breq ADD_SCORE

		out PORTD,SCORE
		ret

ADD_SCORE:
		inc SCORE
		rcall CHECK_SCORE
		ret

CHECK_SCORE:
	mov TMP,SCORE
	lsl TMP
	lsl TMP
	lsl TMP
	lsl TMP
	cpi TMP,0xA0
	breq ADD_6
	ret

ADD_6:
	inc SCORE
	inc SCORE
	inc SCORE
	inc SCORE
	inc SCORE
	inc SCORE
	ret

DELAY:
	ldi r20,0x00
	loop:
	ldi r21,0x00
	loop2:
	inc r21
	cpi r21,0xFF
	brne loop2
	inc r20
	cpi r20,0xFF
	brne loop
	ret
/*
DELAY:
		; delay
		ldi r20,0x00
		loop:
		ldi r21,0x00
		loop2:
		ldi r22,0x00
		loop3:
		inc r22
		cpi r22,0x20
		brne loop3
		inc r21
		cpi r21,0x20
		brne loop2
		inc r20
		cpi r20,0x20
		brne loop
		ret

		*/
