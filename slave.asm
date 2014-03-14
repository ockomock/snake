
/* Slave */
	
.INCLUDE "m8def.inc"

	.def TMP = r16
	.def DIR = r17
	.def HEAD = r18
	.def CURRENT_DIR = r19
	.def FRAME_DELAY = r20
	.def FRAME_COUNTER = r21
	.def SNAKE_SIZE = r22
	.def LOOP_COUNTER = r23
	
	.def RANDOM = r24
	.def TMP2 = r25
	
		; load RANDOM
		ldi RANDOM,0x00

		; no part added to start with
		; 0x80 = PART_ADDED
		ldi TMP,0x00
		sts 0x100,TMP

		; for RNG
		ldi TMP,0x00
		sts 0x101,TMP

		ldi TMP,0xFF
		out DDRD,TMP
		ldi CURRENT_DIR,0x00

		; set default snake size
		ldi SNAKE_SIZE,0x01

		; load FRAME_DELAY
		ldi FRAME_DELAY,0x19
		mov FRAME_COUNTER, FRAME_DELAY

SPI_Init:
		sbi DDRB,DDB4		; Set MISO as an output.
		ldi TMP,0b01101100	; Set SPI as a Slave, with interrupt disabled,
		out SPCR,TMP		; MSB first and SPI mode 3.

STACK_INIT:
		ldi r16, low(RAMEND)	;load r16 with low byte of last sram address
		out SPL, r16			;setup SP low byte			
		ldi r16, high(RAMEND)	;same with high byte
		out SPH, r16	

		rcall CLEAR_SNAKE

SNAKE_INIT:
		ldi TMP,0x94
		sts 0x61,TMP	// HEAD
		

		// Grön
		ldi TMP,0x00
		sts 0x63,TMP
		ldi TMP,0x01
		sts 0x64,TMP
		ldi TMP,0x02
		sts 0x65,TMP
		ldi TMP,0x03
		sts 0x66,TMP
		ldi TMP,0x04
		sts 0x67,TMP
		ldi TMP,0x05
		sts 0x68,TMP
		ldi TMP,0x06
		sts 0x69,TMP
		ldi TMP,0x07
		sts 0x6A,TMP

		// Röd
		ldi TMP,0xF0
		sts 0x6B,TMP
		ldi TMP,0xF1
		sts 0x6C,TMP
		ldi TMP,0xF2
		sts 0x6D,TMP
		ldi TMP,0xF3
		sts 0x6E,TMP
		ldi TMP,0xF4
		sts 0x6F,TMP
		ldi TMP,0xF5
		sts 0x70,TMP
		ldi TMP,0xF6
		sts 0x71,TMP
		ldi TMP,0xF7
		sts 0x72,TMP

		

MAINLOOP:
		; decrease FRAME_COUNTER
		dec FRAME_COUNTER

		; increase RANDOM
		;ldi TMP,RANDOM
		dec RANDOM
		rcall DELAY
SKIP:


		; display food
		;lds TMP,0x9F			; load food
		;out PORTD,TMP			; display food
		;rcall DELAY

		rcall DRAW_SNAKE
		rcall UPDATE

		rjmp MAINLOOP

; set the on/off bit to 0 in every position
CLEAR_SNAKE:
		ldi LOOP_COUNTER,0x60	; start from head

		ldi XL,0x60
		ldi XH,0x00
CLEAR_LOOP:
		ldi TMP,0b00001000
		st X+,TMP

		inc LOOP_COUNTER
		cpi LOOP_COUNTER,0xA0	; loop over all 64 pieces
		brne CLEAR_LOOP
		ret


START_GAME_:

		rcall CLEAR_SNAKE

		; snake size 5
		ldi SNAKE_SIZE,0x05

		ldi TMP,0x91
		sts 0x61,TMP	// HEAD
		ldi TMP,0x92
		sts 0x62,TMP
		ldi TMP,0x93
		sts 0x63,TMP
		ldi TMP,0x94
		sts 0x64,TMP
		ldi TMP,0x95
		sts 0x65,TMP

		; store the food
		; 0xA0 = FOOD
		ldi TMP,0x55
		andi TMP,0b10100101
		sts 0x9F,TMP

		ret

/**
	Draw snake
**/

DRAW_SNAKE:
		;mov LOOP_COUNTER,SNAKE_SIZE
		ldi LOOP_COUNTER,0x40    ; 64 rutor
		ldi XL,0x60
		ldi XH,0x00
DRAW_LOOP:
		;test
		;ldi XL,0x60
		;ldi XH,0x00

		;add XL,LOOP_COUNTER
		ld TMP,X+
		out portd,TMP
		rcall DELAY

		
		
		dec LOOP_COUNTER
		;cpi LOOP_COUNTER,0x02
		brne DRAW_LOOP;brsh
		ret					; RETURN DRAW_SNAKE

UPDATE:

		lds HEAD,0x61

SPI_RECV:
		sbis SPSR,SPIF
		rjmp SPI_RECV
		in DIR,SPDR

		; change direction?
		cpi DIR,0xFF
		breq FRAME_THINGY


		/** 
			make sure the new DIR isn't opposite to CURRENT_DIR
		**/
TEST_VALID_DIR:
		cpi DIR,0x00		; up?
		breq TEST_UP
		cpi DIR,0x01		; right?
		breq TEST_RIGHT
		cpi DIR,0x02		; down?
		breq TEST_DOWN			
		cpi DIR,0x03		; left?
		breq TEST_LEFT

		lds HEAD,0x61
		
TEST_UP:
		cpi CURRENT_DIR,0x02	; last dir down?
		breq FRAME_THINGY
		;rcall ADD_PART			; JUST FOR TESTING!!!!!!!
		rjmp UPDATE_DIR
TEST_DOWN:
		cpi CURRENT_DIR,0x00	; last dir up?
		breq FRAME_THINGY
		rjmp UPDATE_DIR
TEST_LEFT:		
		cpi CURRENT_DIR,0x01	; last dir right?
		breq FRAME_THINGY
		rjmp UPDATE_DIR
TEST_RIGHT:
		cpi CURRENT_DIR,0x03	; last dir left?
		breq FRAME_THINGY
		rjmp UPDATE_DIR

		; this only runs if the new direction is allowed
UPDATE_DIR:
		; store the received direction
		mov CURRENT_DIR,DIR
FRAME_THINGY:
		

		; should the position get updated?
		; if not - return
		cpi FRAME_COUNTER,0x00
		breq DO_UPDATE
		ret								; RETURN UPDATE

START_GAME:
		rjmp START_GAME_

/**
	Allting i DO_UPDATE körs med ett bestämt intervall
	FRAME_DELAY (r20) bestämmer intervallet
	Just nu är det UPDATE_BODY och UPDATE_HEAD som ligger här

	DRAW_SNAKE ligger t.ex inte här för att den ska köras så fort som möjligt
**/
DO_UPDATE:	
		rcall UPDATE_BODY
		rcall UPDATE_HEAD
		cpi SNAKE_SIZE,0x01
		brne TEST_BODY_COLLISION
		rcall TEST_DIF_SELECT
		ret								; RETURN DO_UPDATE

/**
	Test collision with body parts here
**/
TEST_BODY_COLLISION:
		mov LOOP_COUNTER,SNAKE_SIZE
BODY_COLLISION_LOOP:
		; get position of part
		ldi XL,0x60
		ldi XH,0x00
		add XL,LOOP_COUNTER
		ld TMP,X	; store the position

		; get head position
		lds HEAD,0x61

		; compare head with part
		cp TMP,HEAD
		breq DEATHSCREEN

		dec LOOP_COUNTER
		cpi LOOP_COUNTER,0x02
		brsh BODY_COLLISION_LOOP

		ret							; RETURN TEST_BODY_COLLISION

TEST_DIF_SELECT:
		lds HEAD,0x61
		lsr HEAD
		lsr HEAD
		lsr HEAD
		lsr HEAD

		cpi HEAD,0x01
		breq GO_START
		cpi HEAD,0x0F
		breq FASTER

		rjmp RETTTT

FASTER:
		ldi FRAME_DELAY,0x09
GO_START:
		rcall START_GAME
RETTTT:
		ret

UPDATE_BODY:
		mov TMP,SNAKE_SIZE
		;dec TMP
		mov LOOP_COUNTER,TMP;SNAKE_SIZE
UPDATE_LOOP:
		; move the parts

		; get position from part infront
		mov TMP,LOOP_COUNTER
		dec TMP		; index offset to the part infront
		ldi XL,0x60
		ldi XH,0x00
		add XL,TMP
		ld TMP,X	; store the position from the part infront
		
		; update the current parts position
		mov TMP2,LOOP_COUNTER
		ldi XL,0x60
		ldi XH,0x00
		add XL,TMP2
		st X,TMP

		dec LOOP_COUNTER
		cpi LOOP_COUNTER,0x01
		brsh UPDATE_LOOP

		; new part added?
		lds TMP,0x100
		cpi TMP,0x01
		brne ADD_NOTHING
		inc SNAKE_SIZE				; increment the snake size
		ldi TMP,0x00
		sts 0x100,TMP				; reset PART_ADDED

ADD_NOTHING:
		ret							; RETURN UPDATE_BODY

DEATHSCREEN:
	rjmp DEATHSCREEN_

UPDATE_HEAD:
		
		/* compare da shit */
		cpi CURRENT_DIR,0x00		; up?
		breq UP
		cpi CURRENT_DIR,0x01		; right?
		breq RIGHT
		cpi CURRENT_DIR,0x02		; down?
		breq DOWN			
		cpi CURRENT_DIR,0x03		; left?
		breq LEFT
		rjmp RESET_COUNTER							; RETURN UPDATE

		lds HEAD,0x61
		
UP:
		; special case for UP to not change color
		mov TMP,HEAD
		andi TMP,0x0F
		cpi TMP,0x00
		breq SPECIAL_CASE

		dec HEAD
		rjmp CHECK_FOOD_COLLISION
SPECIAL_CASE:
		ldi TMP2,0x07
		add TMP,TMP2				; add 7 to head Y

		andi HEAD,0xF0				; OR in the new Y value
		or HEAD,TMP

		rjmp CHECK_FOOD_COLLISION
DOWN:
		inc HEAD
		rjmp CHECK_FOOD_COLLISION
LEFT:		
		ldi TMP,0x20
		sub HEAD,TMP
		rjmp CHECK_FOOD_COLLISION
RIGHT:
		ldi TMP,0x20
		add HEAD,TMP
		rjmp CHECK_FOOD_COLLISION

CHECK_FOOD_COLLISION:
		; make on/off bit zero
		andi HEAD,0b11110111

		lds TMP,0x9F				; load food position
		ori TMP,0b00010000			; make red

		cp TMP,HEAD					; head.pos == food.pos?
		brne RESET_COUNTER

		; food collision!
		ldi TMP,0xF0
		out SPDR,TMP
		rcall ADD_PART				; add part
		rcall SPAWN_FOOD			; spawn new food

RESET_COUNTER:		; reset the counter after FRAME_DELAY frames
		andi HEAD,0b11110111	; and
		sts 0x61,HEAD				; update the heads position
		mov FRAME_COUNTER,FRAME_DELAY

		ret							; RETURN UPDATE_HEAD

SPAWN_FOOD:
		dec RANDOM
		mov TMP,RANDOM				; TEMP!!!!!! just spawn a new food piece
		ori TMP,0b00010000			; make red
		andi TMP,0b11110111

		; loop stuff
		ldi LOOP_COUNTER,0x00
		ldi XL,0x61
		ldi XH,0x00
SPAWN_LOOP:	
		;add XL,LOOP_COUNTER
		ld TMP2,X+	; get part position

		; compare with the random food position
		cp TMP2,TMP
		breq SPAWN_FOOD

		inc LOOP_COUNTER
		cp LOOP_COUNTER,SNAKE_SIZE
		brne SPAWN_LOOP

		; food position OK!
		andi TMP,0b11100111
		sts 0x9F,TMP

		ret							; RETURN SPAWN_FOOD

ADD_PART:
		; get position from part infront
		ldi XL,0x60
		ldi XH,0x00
		add XL,SNAKE_SIZE	; X points to the last part
		ld TMP,X			; TMP stores the value from the last part

		inc XL				; increment XL to point to the new part
		st X,TMP			; store the position at the back

		; set the PART_ADDED byte
		ldi TMP,0x01
		sts 0x100,TMP

		; don't increment SNAKE_SIZE here
		; it's done in UPDATE_BODY

		ret							; RETURN ADD_PART



/**
	Delay
**/
DELAY:
		ldi TMP,0x80
		mov r2,TMP
		clr r3
DELAY_LOOP:
		inc r2	;adiw r26, 1		; "add immediate to word": r26:r27 are incremented
		brne DELAY_LOOP
		ret							; RETURN DELAY

DEATHSCREEN_:
DCLEAR_SNAKE:
		ldi LOOP_COUNTER,0x60	; start from head

		ldi XL,0x60
		ldi XH,0x00
DCLEAR_LOOP:
		ldi TMP,0b00001000
		st X+,TMP

		inc LOOP_COUNTER
		cpi LOOP_COUNTER,0xA0	; loop over all 64 pieces
		brne DCLEAR_LOOP

		ldi TMP,0x51
		sts 0x61,TMP
		ldi TMP,0x71
		sts 0x62,TMP
		ldi TMP,0x91
		sts 0x63,TMP
		ldi TMP,0xB1
		sts 0x64,TMP
		ldi TMP,0x12
		sts 0x66,TMP
		ldi TMP,0x32
		sts 0x67,TMP
		ldi TMP,0x72
		sts 0x68,TMP
		ldi TMP,0x92
		sts 0x69,TMP
		ldi TMP,0xD2
		sts 0x6A,TMP
		ldi TMP,0xF2
		sts 0x6B,TMP
		ldi TMP,0x13
		sts 0x6C,TMP
		ldi TMP,0xF3
		sts 0x6D,TMP
		ldi TMP,0x14
		sts 0x6E,TMP
		ldi TMP,0xF4
		sts 0x6F,TMP
		ldi TMP,0x35
		sts 0x70,TMP
		ldi TMP,0x75
		sts 0x71,TMP
		ldi TMP,95
		sts 0x72,TMP
		ldi TMP,0xD5
		sts 0x73,TMP
		ldi TMP,0x56
		sts 0x74,TMP
		ldi TMP,0x76
		sts 0x75,TMP
		ldi TMP,0x96
		sts 0x76,TMP
		ldi TMP,0xB6
		sts 0x77,TMP
		ldi TMP,0x57
		sts 0x78,TMP
		ldi TMP,0x77
		sts 0x79,TMP
		ldi TMP,0x97
		sts 0x7A,TMP
		ldi TMP,0xB7
		sts 0x7B,TMP
		ldi TMP,0x52
		sts 0x7C,TMP
		ldi TMP,0x31
		sts 0x7D,TMP
		ldi TMP,0xD1
		sts 0x7E,TMP
		ldi TMP,0xB2
		sts 0x7F,TMP
		ldi TMP,0x55
		sts 0x80,TMP
		ldi TMP,0x95
		sts 0x81,TMP
		ldi TMP,0xB5
		sts 0x82,TMP
		ldi TMP,0x73
		sts 0x83,TMP
		ldi TMP,0x93
		sts 0x84,TMP
		ldi TMP,0x74
		sts 0x85,TMP
		ldi TMP,0x94
		sts 0x86,TMP
		ldi TMP,0x23
		sts 0x87,TMP
		ldi TMP,0x43
		sts 0x88,TMP
		ldi TMP,0x24
		sts 0x89,TMP
		ldi TMP,0x44
		sts 0x8A,TMP
		ldi TMP,0xA3
		sts 0x8B,TMP
		ldi TMP,0xC3
		sts 0x8C,TMP
		ldi TMP,0xA4
		sts 0x8D,TMP
		ldi TMP,0xC4
		sts 0x8E,TMP

DPRINT_DEATH:
		;mov LOOP_COUNTER,SNAKE_SIZE
		ldi LOOP_COUNTER,0x40    ; 64 rutor
		ldi XL,0x60
		ldi XH,0x00
DDRAW_LOOP:
		;test
		;ldi XL,0x60
		;ldi XH,0x00

		;add XL,LOOP_COUNTER
		ld TMP,X+
		out portd,TMP
		rcall DELAY

		
		
		dec LOOP_COUNTER
		;cpi LOOP_COUNTER,0x02
		brne DDRAW_LOOP;brsh
		rjmp DPRINT_DEATH
