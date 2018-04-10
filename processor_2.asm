/*
 * processor_2.asm
 *
 *  Created: 3/7/2018 2:54:31 PM
 *   Author: simne844
 */ 



 
 
STACK:
		ldi r16,HIGH (RAMEND)
		out SPH,r16
		ldi r16,LOW(RAMEND)
		out SPL,r16

INIT_PORTS:
		ldi r16,$01
		out DDRA,r16
		ldi	r16,$02
		out	DDRD, r16

INIT_BLUETOOTH:
		ldi r16,$07
		out UBRRL,r16
		ldi r16,(1<<RXEN)|(1<<TXEN)
		out UCSRB,r16		
		ldi r16,(1<<URSEL)|(1<<USBS)|(1<<UCSZ0)|(1<<UCSZ1)
		out UCSRC,r16
		
		
		in r16,UDR


START:	
		sbis UCSRA, RXC
		jmp START

		in r16, UDR
		cpi r16, $A5
		brne START
START_MOTOR:
		sbi PORTA,0
STOP_ALARM:
		sbis PINB,0
		rjmp STOP_ALARM
		cbi PORTA,0 ;stop motor
		ldi r16,$77
		out UDR,r16
		rjmp START

	



/*
DELAY:
		ldi r16,$FF
LOOP_1:
		ldi r17,$FF
LOOP_2: 
		ldi r18,$FF
LOOP_3:
		dec r18
		brne LOOP_3
		dec r17
		brne LOOP_2
		dec r16
		brne LOOP_1
		ret
		*/