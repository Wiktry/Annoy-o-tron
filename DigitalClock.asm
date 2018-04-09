/*
 * DigitalClock.asm
 *
 *  Created: 2/23/2018 12:03:46 PM
 *   Author: Wiktor
 *
 *	Based on work by:
 *	 Donald Weiman
 *	http://web.alfredstate.edu/faculty/weimandn/programming/lcd/ATmega328/LCD_code_asm_8d.html
 */ 

; ***************************************************************************
;	Kopplad enligt:
;
;                -----------        ----------
;               | ATmega16A |      |   LCD    |
;               |           |      |          |
;   Sound <-----|PB6     PA7|----->|D7        |
;   -----       |        PA6|----->|D6        |
;  | RTC |      |        PA5|----->|D5        |
;  | INT |<-----|INT0    PA4|----->|D4        |
;  | SCL |<-----|        PA3|----->|D3        |
;  | SDA |<-----|        PA2|----->|D2        |
;   -----       |        PA1|----->|D1        |
;   -----       |        PA0|----->|D0        |
;  |  PB |      |           |----->|backlight |
;  |  <- |<-----|PB4     PB2|----->|E         |
;  | ENT |<-----|PB5     PB1|----->|RW        |
;  |  -> |<-----|PB6     PB0|----->|RS        |
;   -----		|			|		----------
;               |           |      | Bluetooth |
;				|		 PC0|----->|SCL		   |
;				|		 PC1|----->|SDA		   |
;				|		 PD0|----->|IN		   |
;				|        PD1|----->|OUT        |
;                -----------        -----------
;
; ***************************************************************************

.equ    fclk                = 9000000     ; system clock frequency (for delays)

; register usage
.def    temp                = R16           ; temporary storage
.def	in_menu				= R22			; Set if you are in the menu
.def	alarm_active		= R23			; Set of the alarm is currently active

; Storage space for the current time
.equ	Time_One_Sec		= $64
.equ	Time_Ten_Sec		= $65
.equ	Time_One_Min		= $66
.equ	Time_Ten_Min		= $67
.equ	Time_One_Hour		= $68
.equ	Time_Ten_Hour		= $69

; Storage space for the temporary time
.equ	Temp_Time_One_Min	= $6A
.equ	Temp_Time_Ten_Min	= $6B
.equ	Temp_Time_One_Hour	= $6C
.equ	Temp_Time_Ten_Hour	= $6D

; Storage space for alarms
.equ	Alarm_Current_Hour	= $6E
.equ	Alarm_Current_Min	= $6F
.equ	Alarm_Storage_One_Min	= $70
.equ	Alarm_Storage_One_Hour	= $71
.equ	Alarm_Storage_Two_Min	= $72
.equ	Alarm_Storage_Two_Hour	= $73
.equ	Alarm_Storage_Three_Min	= $74
.equ	Alarm_Storage_Three_Hour= $75
.equ	Alarm_Storage_Four_Min	= $76
.equ	Alarm_Storage_Four_Hour	= $77
.equ	Alarm_Last_Used		= $78

;	Sound information
.equ	Beep_Pitch  = 255	; Victory beep pitch
.equ	Beep_Lenght = 255	; Victory beep length

; Push Buttons In-ports
.equ	PBL_port			= PORTB			; push button left
.equ	PBL_pin				= PINB
.equ	PBL_bit				= PORTB4
.equ	PBL_ddr				= DDRB

.equ	PBE_port			= PORTB			; push button enter
.equ	PBE_pin				= PINB
.equ	PBE_bit				= PORTB5
.equ	PBE_ddr				= DDRB

.equ	PBR_port			= PORTB			; push button right
.equ	PBR_pin				= PINB
.equ	PBR_bit				= PORTB6
.equ	PBR_ddr				= DDRB

; Clock ports
.equ	SCL_port			= PORTB
.equ	SCL_bit				= PORTB3
.equ	SCL_ddr				= DDRB

.equ	SDA_port			= PORTB
.equ	SDA_bit				= PORTB4
.equ	SDA_ddr				= DDRB

; Speaker port
.equ	SPEAKER_port		= PORTB
.equ	SPEAKER_bit			= PORTB3
.equ	SPEAKER_ddr			= DDRB

; Bluetooth ports
.equ	BLUE_IN_port		= PORTD
.equ	BLUE_IN_bit			= PORTD0
.equ	BLUE_IN_ddr			= DDRD

.equ	BLUE_OUT_pin		= PIND
.equ	BLUE_OUT_bit		= PORTD1
.equ	BLUE_OUT_ddr		= DDRD

.equ	BLUE_CTS_port		= PORTC
.equ	BLUE_CTS_bit		= PORTC1
.equ	BLUE_CTS_ddr		= DDRC

.equ	BLUE_RTS_port		= PORTC
.equ	BLUE_RTS_bit		= PORTC0
.equ	BLUE_RTS_ddr		= DDRC

; Interrupt port
.equ	INT0_pin			= PIND
.equ	INT0_port			= PORTD
.equ	INT0_bit			= PORTD2
.equ	INT0_ddr			= DDRD

; LCD interface (should agree with the diagram above)
.equ    lcd_A7_port         = PORTA         ; lcd D7 connection
.equ    lcd_A7_bit          = PORTA7
.equ    lcd_A7_ddr          = DDRA

.equ    lcd_A6_port         = PORTA         ; lcd D6 connection
.equ    lcd_A6_bit          = PORTA6
.equ    lcd_A6_ddr          = DDRA

.equ    lcd_A5_port         = PORTA         ; lcd D5 connection
.equ    lcd_A5_bit          = PORTA5
.equ    lcd_A5_ddr          = DDRA

.equ    lcd_A4_port         = PORTA         ; lcd D4 connection
.equ    lcd_A4_bit          = PORTA4
.equ    lcd_A4_ddr          = DDRA

.equ    lcd_A3_port         = PORTA         ; lcd D3 connection
.equ    lcd_A3_bit          = PORTA3
.equ    lcd_A3_ddr          = DDRA

.equ    lcd_A2_port         = PORTA         ; lcd D2 connection
.equ    lcd_A2_bit          = PORTA2
.equ    lcd_A2_ddr          = DDRA

.equ    lcd_A1_port         = PORTA         ; lcd D1 connection
.equ    lcd_A1_bit          = PORTA1
.equ    lcd_A1_ddr          = DDRA

.equ    lcd_A0_port         = PORTA         ; lcd D0 connection
.equ    lcd_A0_bit          = PORTA0
.equ    lcd_A0_ddr          = DDRA

.equ    lcd_E_port          = PORTB         ; lcd Enable pin
.equ    lcd_E_bit           = PORTB2
.equ    lcd_E_ddr           = DDRB

.equ    lcd_RW_port         = PORTB         ; lcd Enable pin
.equ    lcd_RW_bit          = PORTB1
.equ    lcd_RW_ddr          = DDRB

.equ    lcd_RS_port         = PORTB         ; lcd Register Select pin
.equ    lcd_RS_bit          = PORTB0
.equ    lcd_RS_ddr          = DDRB

.equ    lcd_BL_port         = PORTB         ; lcd backlight
.equ    lcd_BL_bit          = PORTB5
.equ    lcd_BL_ddr          = DDRB

; LCD module information
.equ    lcd_LineOne         = 0x00          ; start of line 1
.equ    lcd_LineTwo         = 0x40          ; start of line 2

; LCD instructions
.equ    lcd_Clear           = 0b00000001    ; replace all characters with ASCII 'space'
.equ    lcd_Home            = 0b00000010    ; return cursor to first position on first line
.equ    lcd_EntryMode       = 0b00000110    ; shift cursor from left to right on read/write
.equ    lcd_DisplayOff      = 0b00001000    ; turn display off
.equ    lcd_DisplayOn       = 0b00001100    ; display on, cursor off, don't blink character
.equ    lcd_FunctionReset   = 0b00110000    ; reset the LCD
.equ    lcd_FunctionSet8bit = 0b00111000    ; 8-bit data, 2-line display, 5 x 7 font
.equ    lcd_SetCursor       = 0b10000000    ; set cursor position


; ****************************** Reset Vector *******************************

.org	0x0000
	rjmp START

; ****************************** Interrupt Vector ***************************

.org INT0addr
jmp time_increase

; ****************************** Information to be displayed ****************

.org	INT_VECTORS_SIZE

Hello_World:
.db		"HELLO WORLD",0

Set_Time:
.db		"SET TIME:",0

Set_Alarm:
.db		"SET ALARM:",0,0

Saved_Alarms:
.db		"SAVED ALARMS:",0

Arrow:
.db		"-> ",0

Four_Empty:
.db		"    ",0,0

OK_To_Set:
.db		"OK to set time",0,0

OK_To_Save:
.db		"OK to save alarm",0,0

; ****************************** Main Program Code **************************

START:

;	Initiate stack pointer
    ldi     temp,low(RAMEND)
    out     SPL,temp
    ldi     temp,high(RAMEND)
    out     SPH,temp

;	Initiate interrupts
	ldi		temp, $03
	out		MCUCR, temp
	ldi		temp, $40
	out		GICR, temp

;	Initiate Ports
	sbi     lcd_A7_ddr, lcd_A7_bit          ; 8 data lines - output for LCD
    sbi     lcd_A6_ddr, lcd_A6_bit
    sbi     lcd_A5_ddr, lcd_A5_bit
    sbi     lcd_A4_ddr, lcd_A4_bit
    sbi     lcd_A3_ddr, lcd_A3_bit
    sbi     lcd_A2_ddr, lcd_A2_bit
    sbi     lcd_A1_ddr, lcd_A1_bit
    sbi     lcd_A0_ddr, lcd_A0_bit

	sbi     lcd_E_ddr,  lcd_E_bit           ; E line - output
	sbi     lcd_RW_ddr, lcd_RW_bit          ; RW line - output
    sbi     lcd_RS_ddr, lcd_RS_bit          ; RS line - output
	sbi		lcd_BL_ddr, lcd_BL_bit			; Backlight - output

	sbi		SPEAKER_ddr, SPEAKER_bit		; Speaker - output

	cbi		PBL_ddr, PBL_bit				; Push Buttons
	cbi		PBE_ddr, PBE_bit
	cbi		PBR_ddr, PBR_bit

//	sbi		INT0_ddr, INT0_bit				; Interrupt - input
	cbi		INT0_ddr, INT0_bit
	sbi		INT0_port, INT0_bit
			

;	Initiate Bloutooth
	sbi		BLUE_CTS_ddr, BLUE_CTS_bit
	cbi		BLUE_CTS_port, BLUE_CTS_bit
	sbi		BLUE_RTS_ddr, BLUE_RTS_bit
	cbi		BLUE_RTS_port, BLUE_RTS_bit

	ldi		temp, $07
	clr		r17
	out		UBRRL, temp	
	ldi		temp, (1<<RXEN)|(1<<TXEN)
	out		UCSRB, temp
	sbi		URSEL, 7
	ldi		temp, (1<<URSEL)|(1<<USBS)|(1<<UCSZ1)|(1<<UCSZ0)|(0<<UPM1)
	out		UCSRC, temp 

	sbi		BLUE_OUT_ddr, BLUE_OUT_bit

;	Call LCD_INIT to start and reset the LCD
	call	LCD_INIT

;	Reset the time
	ldi		temp, $01
	sts		Time_One_Min, temp
	clr		temp
	sts		Time_One_Sec, temp
	sts		Time_Ten_Sec, temp
	sts		Time_Ten_Min, temp
	sts		Time_One_Hour, temp
	sts		Time_Ten_Hour, temp
	sts		Temp_Time_One_Min, temp
	sts		Temp_Time_Ten_Min, temp
	sts		Temp_Time_One_Hour, temp
	sts		Temp_Time_Ten_Hour, temp

;	Reset Alarms
	sts		Alarm_Current_Hour, temp
	sts		Alarm_Current_Min, temp
	sts		Alarm_Storage_One_Min, temp
	sts		Alarm_Storage_One_Hour, temp
	sts		Alarm_Storage_Two_Min, temp
	sts		Alarm_Storage_Two_Hour, temp
	sts		Alarm_Storage_Three_Min, temp
	sts		Alarm_Storage_Three_Hour, temp
	sts		Alarm_Storage_Four_Min, temp
	sts		Alarm_Storage_Four_Hour, temp
	sts		Alarm_Last_Used, temp

;	Clear in_menu
	clr		in_menu
;	Clear alarm_active
	clr		alarm_active

;	Write out hello world on the display, see here for display writing example
	ldi		ZH,	high(Hello_World)
	ldi		ZL,	low(Hello_World)
	ldi		temp, lcd_LineOne
	call    lcd_write_string

	ldi     temp, 10                      ; 4.1 mS delay (min)
    call    delayTx1mS

;	Write out the current alarm
	//call	CURRENT_ALARM

;	Interrupts from this point on
	sei

	call	MAIN_LOOP
	ldi		temp, 10


MAIN_LOOP:
	
;	Backlight on for either left or right
/*
	sbic	PBL_pin, PBL_bit
	call	backlight_on_left
	sbic	PBR_pin, PBR_bit
	call	backlight_on_right
*/
;	Enter the menu system
	sbic	PBE_pin, PBE_bit
	call	main_menu
	clr		in_menu

;	Check for alarm done signal from CPU2
	sbrc	alarm_active, 0
	call	check_alarm_done
	
	rjmp		MAIN_LOOP


; ============================== MENU SUBROUTINES ==========================
; Name: main_menu
; Purpose: The hub for all menu related happenings

main_menu:
;	Set the in_menu bit
	ser		in_menu
;	Call button_wait
	call	button_wait
;	Call the first menu option
	jmp		menu_first_option				

	
; --------------------------------------------------------------------------
; Name: menu_first_option
; Purpose: Display and loop for the first option

menu_first_option:
	
;	Clear the display
	call	lcd_clear_instruction			

;	Arrow infront of selected option
	ldi		temp, $7E
	out		PORTA, temp
	call	lcd_write_character

;	Print out the first menu option upon entering
	ldi		ZH, high(Set_Time)
	ldi		ZL, low(Set_Time)
	call	lcd_write_string

;	Print out the second menu option upon entering
	ldi		ZH, high(Set_Alarm)
	ldi		ZL, low(Set_Alarm)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

menu_first_option_loop:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		menu_second_option

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		menu_third_option

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		set_time_option				; Insert call
	
;	Loop
	rjmp	menu_first_option_loop

; --------------------------------------------------------------------------
; Name: menu_second_option
; Purpose: Display and loop for the second option

menu_second_option:
	
;	Clear the display
	call	lcd_clear_instruction
	
;	Arrow infront of selected option
	ldi		temp, $7E
	out		PORTA, temp
	call	lcd_write_character		

;	Print out the first menu option upon entering
	ldi		ZH, high(Set_Alarm)
	ldi		ZL, low(Set_Alarm)
	ldi		temp, lcd_lineOne
	call	lcd_write_string

;	Print out the second menu option upon entering
	ldi		ZH, high(Saved_Alarms)
	ldi		ZL, low(Saved_Alarms)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

menu_second_option_loop:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		menu_third_option

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		menu_first_option

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		set_alarm_option
	
;	Loop
	rjmp	menu_second_option_loop

; --------------------------------------------------------------------------
; Name: menu_third_option
; Purpose: Display and loop for the third option

menu_third_option:
	
;	Clear the display
	call	lcd_clear_instruction
	
;	Arrow infront of selected option
	ldi		temp, $7E
	out		PORTA, temp
	call	lcd_write_character			

;	Print out the first menu option upon entering
	ldi		ZH, high(Saved_Alarms)
	ldi		ZL, low(Saved_Alarms)
	ldi		temp, lcd_lineOne
	call	lcd_write_string

;	Print out the second menu option upon entering
	ldi		ZH, high(Set_Time)
	ldi		ZL, low(Set_Time)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

menu_third_option_loop:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		menu_first_option

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		menu_second_option

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		saved_alarms_option
	
;	Loop
	rjmp	menu_third_option_loop

; --------------------------------------------------------------------------
; Name: check_alarm_done
; Purpose: Check for alarm done signal from CPU2

check_alarm_done:
	sbis	UCSRA, RXC
	ret
	
	in		temp, UDR
	cpi		temp, $77
	brne	check_alarm_done_ret
	clr		alarm_active

check_alarm_done_ret:
	ret
	

; --------------------------------------------------------------------------
; Name: set_time_option
; Purpose: Set the current time

set_time_option:
;	Clear the display
	call	lcd_clear_instruction

;	Print out "OK to set time" on the second line
	ldi		ZH, high(OK_To_Set)
	ldi		ZL, low(OK_To_Set)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

set_time_option_loop:
;	For fast stepping
	sbic	PBR_pin, PBR_bit
	call	temp_time_create

;	For slow stepping
	sbic	PBL_pin, PBL_bit
	call	temp_time_create_slow

;	When finished
	sbic	PBE_pin, PBE_bit
	rjmp	set_time_option_done	

	rjmp	set_time_option_loop

;	When you press the done button
set_time_option_done:
	call	button_wait						; Wait for button relese

	lds		temp,Temp_Time_One_Min			; Set first digit min
	sts		Time_One_Min, temp

	lds		temp,Temp_Time_Ten_Min			; Set second digit min
	sts		Time_Ten_Min, temp

	lds		temp,Temp_Time_One_Hour			; Set first digit hour
	sts		Time_One_Hour, temp

	lds		temp,Temp_Time_Ten_Hour			; Set second digit hour
	sts		Time_Ten_Hour, temp

	clr		temp							; Set seconds to 0
	sts		Time_One_Sec, temp
	sts		Time_Ten_Sec, temp

	ret

; --------------------------------------------------------------------------
; Name: set_alarm_option
; Purpose: Create and set an alarm

set_alarm_option:
;	Clear the display
	call	lcd_clear_instruction

;	Print out "OK to set time" on the second line
	ldi		ZH, high(OK_To_Save)
	ldi		ZL, low(OK_To_Save)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

set_alarm_option_loop:
;	For fast stepping
	sbic	PBR_pin, PBR_bit
	call	temp_time_create

;	For slow stepping
	sbic	PBL_pin, PBL_bit
	call	temp_time_create_slow

;	When finished
	sbic	PBE_pin, PBE_bit
	rjmp	set_alarm_option_done	

	rjmp	set_alarm_option_loop

;	When you press the done button
set_alarm_option_done:
	call	button_wait						; Wait for button relese

	push	r0
	push	r17

;	Check if another alarm has alredy been set
	lds		temp, Alarm_Current_Min			; Check the first part
	cpi		temp, $00
	brne	set_alarm_option_done_prev
	lds		temp, Alarm_Current_Hour		; Check the second part
	cpi		temp, $00
	brne	set_alarm_option_done_prev
	jmp		set_alarm_option_done_noalarm	; Set Current Alarm

;	Store old alarm
set_alarm_option_done_prev:
	lds		temp, Alarm_Last_Used
	cpi		temp, $00
	breq	set_alarm_option_done_alarm_one
	cpi		temp, $01
	breq	set_alarm_option_done_alarm_two
	cpi		temp, $02
	breq	set_alarm_option_done_alarm_three
	cpi		temp, $03
	breq	set_alarm_option_done_alarm_four

;	Move Current Alarm to Alarm Storage 1
set_alarm_option_done_alarm_one:
	lds		temp, Alarm_Current_Hour
	sts		Alarm_Storage_One_Hour, temp
	lds		temp, Alarm_Current_Min
	sts		Alarm_Storage_One_Min, temp
	ldi		temp, $01
	sts		Alarm_Last_Used, temp
	jmp		set_alarm_option_done_noalarm

;	Move Current Alarm to Alarm Storage 2
set_alarm_option_done_alarm_two:
	lds		temp, Alarm_Current_Hour
	sts		Alarm_Storage_Two_Hour, temp
	lds		temp, Alarm_Current_Min
	sts		Alarm_Storage_Two_Min, temp
	ldi		temp, $02
	sts		Alarm_Last_Used, temp
	jmp		set_alarm_option_done_noalarm

;	Move Current Alarm to Alarm Storage 3
set_alarm_option_done_alarm_three:
	lds		temp, Alarm_Current_Hour
	sts		Alarm_Storage_Three_Hour, temp
	lds		temp, Alarm_Current_Min
	sts		Alarm_Storage_Three_Min, temp
	ldi		temp, $03
	sts		Alarm_Last_Used, temp
	jmp		set_alarm_option_done_noalarm

;	Move Current Alarm to Alarm Storage 4
set_alarm_option_done_alarm_four:
	lds		temp, Alarm_Current_Hour
	sts		Alarm_Storage_Four_Hour, temp
	lds		temp, Alarm_Current_Min
	sts		Alarm_Storage_Four_Min, temp
	ldi		temp, $00
	sts		Alarm_Last_Used, temp
	jmp		set_alarm_option_done_noalarm

;	If no previus alarm is detected, or the prev alarm was moved
set_alarm_option_done_noalarm:
	ldi		r17, 16
	
	lds		temp,Temp_Time_Ten_Min			; Load in second digit min
	muls	temp,r17						; Multiply with 10
	lds		temp,Temp_Time_One_Min			; Set first digit min
	add		temp, r0						; Add together
	sts		Alarm_Current_Min, temp			; Store

	lds		temp,Temp_Time_Ten_Hour			; Load in second digit hour
	muls	temp,r17						; Multiply with 10
	lds		temp,Temp_Time_One_Hour			; Set first digit hour
	add		temp, r0						; Add together
	sts		Alarm_Current_Hour, temp		; Store

	jmp		set_alarm_option_done_ret
	

;	Pop and ret
set_alarm_option_done_ret:
	pop		r17
	pop		r0
	ret

; --------------------------------------------------------------------------
; Name: saved_alarms_option
; Purpose: Choose a previusly created alarm

;	First alarm option
saved_alarms_option:
	
;	Clear the display
	call	lcd_clear_instruction

;	Print out Alarm_Current_Hour
	push	r17
	lds		temp, Alarm_Storage_One_Hour
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_One_Hour
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	;	Print ":"
	ldi		temp, $3A
	out		PORTA, temp
	call	lcd_write_character

;	Print out Alarm_Current_Min
	lds		temp, Alarm_Storage_One_Min
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_One_Min
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	pop		r17

;	Print out the second menu option upon entering
	ldi		ZH, high(OK_To_Set)
	ldi		ZL, low(OK_To_Set)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

saved_alarms_option_loop_one:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		saved_alarms_option_two

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		saved_alarms_option_four

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		set_saved_alarm_one
	
;	Loop
	rjmp	saved_alarms_option_loop_one


;	Second alarm option
saved_alarms_option_two:
	
;	Clear the display
	call	lcd_clear_instruction

;	Print out Alarm_Current_Hour
	push	r17
	lds		temp, Alarm_Storage_Two_Hour
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_Two_Hour
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	;	Print ":"
	ldi		temp, $3A
	out		PORTA, temp
	call	lcd_write_character

;	Print out Alarm_Current_Min
	lds		temp, Alarm_Storage_Two_Min
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_Two_Min
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	pop		r17

;	Print out the second menu option upon entering
	ldi		ZH, high(OK_To_Set)
	ldi		ZL, low(OK_To_Set)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

saved_alarms_option_loop_two:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		saved_alarms_option_three

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		saved_alarms_option

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		set_saved_alarm_two
	
;	Loop
	rjmp	saved_alarms_option_loop_two


;	Third alarm option
saved_alarms_option_three:
	
;	Clear the display
	call	lcd_clear_instruction

;	Print out Alarm_Current_Hour
	push	r17
	lds		temp, Alarm_Storage_Three_Hour
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_Three_Hour
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	;	Print ":"
	ldi		temp, $3A
	out		PORTA, temp
	call	lcd_write_character

;	Print out Alarm_Current_Min
	lds		temp, Alarm_Storage_Three_Min
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_Three_Min
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	pop		r17

;	Print out the second menu option upon entering
	ldi		ZH, high(OK_To_Set)
	ldi		ZL, low(OK_To_Set)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

saved_alarms_option_loop_three:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		saved_alarms_option_four

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		saved_alarms_option_two

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		set_saved_alarm_three
	
;	Loop
	rjmp	saved_alarms_option_loop_three


;	Fourth alarm option
saved_alarms_option_four:
	
;	Clear the display
	call	lcd_clear_instruction

;	Print out Alarm_Current_Hour
	push	r17
	lds		temp, Alarm_Storage_Four_Hour
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_Four_Hour
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	;	Print ":"
	ldi		temp, $3A
	out		PORTA, temp
	call	lcd_write_character

;	Print out Alarm_Current_Min
	lds		temp, Alarm_Storage_Four_Min
	ldi		r17, $F0						; Get the first number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Storage_Four_Min
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number

	pop		r17

;	Print out the second menu option upon entering
	ldi		ZH, high(OK_To_Set)
	ldi		ZL, low(OK_To_Set)
	ldi		temp, lcd_lineTwo
	call	lcd_write_string

;	Call button_wait
	call	button_wait

saved_alarms_option_loop_four:
;	Go forward through the menu
	sbic	PBR_pin, PBR_bit
	jmp		saved_alarms_option

;	Go backwards through the menu
	sbic	PBL_pin, PBL_bit
	jmp		saved_alarms_option_three

;	Enter the chosen option
	sbic	PBE_pin, PBE_bit
	jmp		set_saved_alarm_four
	
;	Loop
	rjmp	saved_alarms_option_loop_four


; --------------------------------------------------------------------------
; Name: set_saved_alarm
; Purpose: Set a previusly created alarm

set_saved_alarm_one:
	push	r17
	lds		temp, Alarm_Storage_One_Hour
	lds		r17, Alarm_Current_Hour
	sts		Alarm_Storage_One_Hour, r17
	sts		Alarm_Current_Hour, temp
	lds		temp, Alarm_Storage_One_Min
	lds		r17, Alarm_Current_Min
	sts		Alarm_Storage_One_Min, r17
	sts		Alarm_Current_Min, temp
	pop		r17
	jmp		set_saved_alarm_ret

set_saved_alarm_two:
	push	r17
	lds		temp, Alarm_Storage_Two_Hour
	lds		r17, Alarm_Current_Hour
	sts		Alarm_Storage_Two_Hour, r17
	sts		Alarm_Current_Hour, temp
	lds		temp, Alarm_Storage_Two_Min
	lds		r17, Alarm_Current_Min
	sts		Alarm_Storage_Two_Min, r17
	sts		Alarm_Current_Min, temp
	pop		r17
	jmp		set_saved_alarm_ret

set_saved_alarm_three:
	push	r17
	lds		temp, Alarm_Storage_Three_Hour
	lds		r17, Alarm_Current_Hour
	sts		Alarm_Storage_Three_Hour, r17
	sts		Alarm_Current_Hour, temp
	lds		temp, Alarm_Storage_Three_Min
	lds		r17, Alarm_Current_Min
	sts		Alarm_Storage_Three_Min, r17
	sts		Alarm_Current_Min, temp
	pop		r17
	jmp		set_saved_alarm_ret

set_saved_alarm_four:
	push	r17
	lds		temp, Alarm_Storage_Four_Hour
	lds		r17, Alarm_Current_Hour
	sts		Alarm_Storage_Four_Hour, r17
	sts		Alarm_Current_Hour, temp
	lds		temp, Alarm_Storage_Four_Min
	lds		r17, Alarm_Current_Min
	sts		Alarm_Storage_Four_Min, r17
	sts		Alarm_Current_Min, temp
	pop		r17
	jmp		set_saved_alarm_ret

set_saved_alarm_ret:
	call	button_wait
	ret

; --------------------------------------------------------------------------
; Name: temp_time_create
; Purpose: Create a set of temp times

;	Wait for button relese for slow increase
temp_time_create_slow:
	sbis	PBL_pin, PBL_bit
	rjmp	temp_time_create

	rjmp	temp_time_create_slow

temp_time_create:
	push	temp

	lds		temp, Temp_Time_One_Min			; Load in Temp_Time_One_Min from memory
	cpi		temp, $09						; Compare
	breq	temp_time_increase_ten_min		; If == then branch
	inc		temp							; If != then inc
	sts		Temp_Time_One_Min, temp			; Store increased temp in memory
	call	temp_time_increase_display
	jmp		temp_time_create_ret

temp_time_increase_ten_min:
	clr		temp							; Clear temp
	sts		Temp_Time_One_Min, temp			; Reset Time_One_Sec to 0
	lds		temp, Temp_Time_Ten_Min			; Load in Time_Ten_Sec from memory
	cpi		temp, $05						; Compare
	breq	temp_time_increase_special		; If == then branch
	inc		temp							; If != then inc
	sts		Temp_Time_Ten_Min, temp			; Store increased temp in memory
	call	temp_time_increase_display
	jmp		temp_time_create_ret

;	Special case for hours at 23:59
temp_time_increase_special:
	clr		temp
	sts		Temp_Time_Ten_Min, temp			; Reset Time_Ten_Min to 0
	
	lds		temp, Temp_Time_Ten_Hour			; Load in Time_Ten_Hour from memory
	cpi		temp, $02						; Compare
	brne	temp_time_increase_one_hour		; If != then branch

	lds		temp, Temp_Time_One_Hour		; Load in Time_One_Hour from memory
	cpi		temp, $03						; Compare
	brne	temp_time_increase_one_hour		; If != then branch

	clr		temp							; Clear temp
	sts		Temp_Time_One_Hour, temp		; Set Time_One_Hour to 0
	sts		Temp_Time_Ten_Hour, temp		; Set Time_Ten_Hour to 0

	call	temp_time_increase_display
	jmp		temp_time_create_ret

;	For first digit hours
temp_time_increase_one_hour:
	clr		temp
	sts		Temp_Time_Ten_Min, temp			; Reset Time_Ten_Min to 0
	lds		temp, Temp_Time_One_Hour		; Load in Time_One_Hour from memory
	cpi		temp, $09						; Compare
	breq	temp_time_increase_Ten_Hour		; If == then branch
	inc		temp							; If != then inc
	sts		Temp_Time_One_Hour, temp		; Store increased temp in memory
	call	temp_time_increase_display
	jmp		temp_time_create_ret

;	For second digit hours
temp_time_increase_Ten_Hour:
	clr		temp
	sts		Temp_Time_One_Hour, temp		; Reset Time_One_Hour to 0
	lds		temp, Temp_Time_Ten_Hour		; Load in Time_One_Hour from memory
	inc		temp
	sts		Temp_Time_Ten_Hour, temp
	call	temp_time_increase_display
	jmp		temp_time_create_ret

;	Return from the temp time
temp_time_create_ret:
	pop		temp
	ret

;	Display the temp time
temp_time_increase_display:
;	Print out 4 empty spaces before the time
	push	ZH
	push	ZL
	ldi		ZH,	high(Four_Empty)
	ldi		ZL,	low(Four_Empty)
	ldi		temp, lcd_LineOne
	call    lcd_write_string
	pop		ZL
	pop		ZH

;	Print out Time_Ten_Hour
	lds		temp, Temp_Time_Ten_Hour
	call    time_increase_number

;	Print out Time_One_Hour
	lds		temp, Temp_Time_One_Hour
	call    time_increase_number

;	Print :
	ldi		temp, $3A
	out		PORTA, temp 
	call	lcd_write_character

;	Print out Time_Ten_Min
	lds		temp, Temp_Time_Ten_Min
	call    time_increase_number

;	Print out Time_One_Min
	lds		temp, Temp_Time_One_Min
	call    time_increase_number

;	Return from displaying
	ret
	


; --------------------------------------------------------------------------
; Name: backlight_on
; Purpose: Turns on the backlight when left or right button is clicked 
;		   outside of the menu system

backlight_on_left:
	sbi		lcd_BL_port, lcd_BL_bit
	sbic	PBL_pin, PBL_bit
	rjmp	backlight_on_left
	ret


backlight_on_right:
	sbi		lcd_BL_port, lcd_BL_bit
	sbic	PBR_pin, PBR_bit
	rjmp	backlight_on_right
	ret

; --------------------------------------------------------------------------
; Name: button_wait
; Purpose: Wait for the button to be released

button_wait:
	sbic	PBR_pin, PBR_bit
	rjmp	button_wait
	sbic	PBE_pin, PBE_bit
	rjmp	button_wait
	sbic	PBL_pin, PBL_bit
	rjmp	button_wait

	ret


; ============================== END OF MENU SUBROUTINES ===================




; ============================== STRING WRITING SUBROUTINES ================
; Name: lcd_write_string
; Purpose: Display the wanted string from memory

lcd_write_string:
;	Preserve the pointers
	push	ZH
	push	ZL

; fix up the pointers for use with the 'lpm' instruction 
	lsl		ZL								; shift the pointer one bit left for the lpm instruction 
	rol		ZH							
	
; set up the initial DDRAM address 
	ori		temp, lcd_SetCursor				; convert the plain address to a set cursor instruction
	out		PORTA, temp
	call	lcd_write_instruction			; set up the first DDRAM address 
	ldi		temp, 80						; 40 uS delay (min) 
	call	delayTx1uS						
	
; write the string of characters 	
lcd_write_string_8d_01: 
	lpm		temp, Z+						; get a character 
	cpi		temp, 0							; check for end of string 
	breq	lcd_write_string_8d_02			; done 
	
; arrive here if this is a valid character
	out		PORTA,temp 
	call	lcd_write_character				; display the character 
	ldi		temp, 80						; 40 uS delay (min) 
	call	delayTx1uS 
	rjmp	lcd_write_string_8d_01			; not done, send another character 
	
; arrive here when all characters in the message have been sent to the LCD module 
lcd_write_string_8d_02: 
	pop		ZL								; restore pointer registers 
	pop		ZH 
	ret


; ****************************** LCD INIT ***********************************

LCD_INIT:

;	Power-up delay
    ldi     temp, 100                       ; initial 40 mSec delay (min), temp sets to the amount of ms the delay lasts for
    call    delayTx1mS						; It's set to 100 for safety, as 40 is abolute minimum
	
;	Function reset 1/3
	ldi		temp, lcd_FunctionReset			; Load in the designated instruction into temp(r16)
	out		PORTA,temp						; Set the ports to the designated instruction
	call	lcd_write_instruction			; Call lcd_write_instruction to write an instruction to the lcd

;	Second delay for 10ms
	ldi     temp, 10                        ; 4.1 mS delay (min)
    call    delayTx1mS

;	Function reset 2/3
	ldi		temp, lcd_FunctionReset
	out		PORTA,temp
	call	lcd_write_instruction

;	Third delay for 10ms
	ldi     temp, 10                        ; 4.1 mS delay (min)
    call    delayTx1mS

;	Function reset 3/3
	ldi		temp, lcd_FunctionReset
	out		PORTA,temp
	call	lcd_write_instruction

;	Delay before ending inital reset
	ldi     temp, 200                       ; this delay is omitted in the data sheet
    call    delayTx1uS

;	Initial Reset finished
;	Following 4 instructions are designated init instructions

;	Function Set instruction
	ldi		temp, lcd_FunctionSet8bit
	out		PORTA,temp
	call	lcd_write_instruction
	ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

;	Display OFF instruction
	ldi		temp, lcd_DisplayOFF
	out		PORTA,temp
	call	lcd_write_instruction
	ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

;	Clear Display Instruction
	ldi		temp, lcd_Clear
	out		PORTA,temp
	call	lcd_write_instruction
	ldi     temp, 4                         ; 1.64 mS delay (min)
    call    delayTx1mS

;	Entry Mode Set instruction
	ldi		temp, lcd_EntryMode
	out		PORTA,temp
	call	lcd_write_instruction
	ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

;	Display ON instruction
	ldi		temp, lcd_DisplayON
	out		PORTA,temp
	call	lcd_write_instruction
	ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS

	ret

;******************************* LCD INIT FINISHED **************************

	


; ============================== LCD WRITE SUBROUTINES ======================
; Name:		lcd_write_instruction
; Purpose:	writes instructions to the LCD

lcd_write_instruction:
	cbi		lcd_RS_port, lcd_RS_bit			; Set RS to 0 to write instructions
	sbi		lcd_E_port, lcd_E_bit			; Set E to 1 to enable LCD read
	call	delay1uS						; Delay to let the LCD read
	cbi		lcd_E_port, lcd_E_bit			; Reset E to 0
	call	delay1uS						; Delay before going back
	ret

; ---------------------------------------------------------------------------

; Name:		lcd_write_character
; Purpose:	writes letters to the LCD

lcd_write_character:
	sbi		lcd_RS_port, lcd_RS_bit			; Set RS to 1 to write letters
	sbi		lcd_E_port, lcd_E_bit			; Set E to 1 to enable LCD read
	call	delay1uS						; Delay to let the LCD read
	cbi		lcd_E_port, lcd_E_bit			; Reset E to 0
	call	delay1uS						; Delay before going back
	ldi     temp, 80                        ; 40 uS delay (min)
    call    delayTx1uS
	ret

; ---------------------------------------------------------------------------

; Name:		lcd_clear_instruction
; Purpose:	Clears the LCD before more text can be written on it

lcd_clear_instruction:
	ldi		temp, lcd_Clear
	out		PORTA,temp
	call	lcd_write_instruction
	ldi     temp, 4                         ; 1.64 mS delay (min)
    call    delayTx1mS
	ret

;============================== END OF LCD WRITE SUBROUTINES ================




; ============================== Time Delay Subroutines =====================
; Name:     delayYx1mS
; Purpose:  provide a delay of (YH:YL) x 1 mS
; Entry:    (YH:YL) = delay data
; Exit:     no parameters
; Notes:    the 16-bit register provides for a delay of up to 65.535 Seconds
;           requires delay1mS

delayYx1mS:
    call    delay1mS                        ; delay for 1 mS
    sbiw    YH:YL, 1                        ; update the the delay counter
    brne    delayYx1mS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delayTx1mS
; Purpose:  provide a delay of (temp) x 1 mS
; Entry:    (temp) = delay data
; Exit:     no parameters
; Notes:    the 8-bit register provides for a delay of up to 255 mS
;           requires delay1mS

delayTx1mS:
    call    delay1mS                        ; delay for 1 mS
    dec     temp                            ; update the delay counter
    brne    delayTx1mS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delay1mS
; Purpose:  provide a delay of 1 mS
; Entry:    no parameters
; Exit:     no parameters
; Notes:    chews up fclk/1000 clock cycles (including the 'call')

delay1mS:
    push    YL                              ; [2] preserve registers
    push    YH                              ; [2]
    ldi     YL, low (((fclk/1000)-18)/4)    ; [1] delay counter
    ldi     YH, high(((fclk/1000)-18)/4)    ; [1]

delay1mS_01:
    sbiw    YH:YL, 1                        ; [2] update the the delay counter
    brne    delay1mS_01                     ; [2] delay counter is not zero

; arrive here when delay counter is zero
    pop     YH                              ; [2] restore registers
    pop     YL                              ; [2]
    ret                                     ; [4]

; ---------------------------------------------------------------------------
; Name:     delayTx1uS
; Purpose:  provide a delay of (temp) x 1 uS with a 16 MHz clock frequency
; Entry:    (temp) = delay data
; Exit:     no parameters
; Notes:    the 8-bit register provides for a delay of up to 255 uS
;           requires delay1uS

delayTx1uS:
    call    delay1uS                        ; delay for 1 uS
    dec     temp                            ; decrement the delay counter
    brne    delayTx1uS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delay1uS
; Purpose:  provide a delay of 1 uS with a 16 MHz clock frequency
; Entry:    no parameters
; Exit:     no parameters
; Notes:    add another push/pop for 20 MHz clock frequency

delay1uS:
    push    r4			                  ; [2] these instructions do nothing except consume clock cycles
    pop     r4		                      ; [2]
    push    r4	                          ; [2]
    pop     r4	                            ; [2]
    ret                                     ; [4]

; ============================== End of Time Delay Subroutines ==============



; ============================== Interrupts =================================

; Name: time_increase
; Purpose: Increase time by 1 second every second and update the display unless
;		   you are in the menu system
;
; Below this point is hell itself. Get a friend before going in,
; it's dangerous to go alone
time_increase:
	
;	Preserve registers
	cli
	push	temp
	push	ZH
	push	ZL

;	Check if the alarm is active, and ring the bells
	sbrc	alarm_active, 0
	call	time_increase_alarm
	
;	For first digit seconds
	lds		temp, Time_One_Sec				; Load in Time_One_Sec from memory
	cpi		temp, 9							; Compare
	breq	time_increase_ten_sec			; If == then branch
	inc		temp							; If != then inc
	sts		Time_One_Sec, temp				; Store increased temp in memory
	rjmp	time_increase_display			; If != then jmp

;	For second digit seconds
time_increase_ten_sec:
	clr		temp							; Clear temp
	sts		Time_One_Sec, temp				; Reset Time_One_Sec to 0
	lds		temp, Time_Ten_Sec				; Load in Time_Ten_Sec from memory
	cpi		temp, 5							; Compare
	breq	time_increase_one_min			; If == then branch
	inc		temp							; If != then inc
	sts		Time_Ten_Sec, temp				; Store increased temp in memory
	rjmp	time_increase_display			; If != then jmp

;	For first digit minutes
time_increase_one_min:
	clr		temp
	sts		Time_Ten_Sec, temp				; Reset Time_Ten_Sec to 0
	lds		temp, Time_One_Min				; Load in Time_One_Min from memory
	cpi		temp, 9							; Compare
	breq	time_increase_ten_min			; If == then branch
	inc		temp							; If != then inc
	sts		Time_One_Min, temp				; Store increased temp in memory
	rjmp	time_increase_display			; If != then jmp

;	For second digit minutes
time_increase_ten_min:
	clr		temp
	sts		Time_One_Min, temp				; Reset Time_One_Min to 0
	lds		temp, Time_Ten_Min				; Load in Time_Ten_Min from memory
	cpi		temp, 5							; Compare
	breq	time_increase_special			; If == then branch
	inc		temp							; If != then inc
	sts		Time_Ten_Min, temp				; Store increased temp in memory
	rjmp	time_increase_display			; If != then jmp

;	Special case for hours at 23:59
time_increase_special:
	clr		temp
	sts		Time_Ten_Min, temp				; Reset Time_Ten_Min to 0
	
	lds		temp, Time_Ten_Hour				; Load in Time_Ten_Hour from memory
	cpi		temp, 2							; Compare
	brne	time_increase_one_hour			; If != then branch

	lds		temp, Time_One_Hour				; Load in Time_One_Hour from memory
	cpi		temp, 3							; Compare
	brne	time_increase_one_hour			; If != then branch

	clr		temp							; Clear temp
	sts		Time_One_Hour, temp				; Set Time_One_Hour to 0
	sts		Time_Ten_Hour, temp				; Set Time_Ten_Hour to 0

	rjmp	time_increase_display

;	For first digit hours
time_increase_one_hour:
	clr		temp
	sts		Time_Ten_Min, temp				; Reset Time_Ten_Min to 0
	lds		temp, Time_One_Hour				; Load in Time_One_Hour from memory
	cpi		temp, 9							; Compare
	breq	time_increase_Ten_Hour			; If == then branch
	inc		temp							; If != then inc
	sts		Time_One_Hour, temp				; Store increased temp in memory
	rjmp	time_increase_display			; If != then jmp

;	For second digit hours
time_increase_Ten_Hour:
	clr		temp
	sts		Time_One_Hour, temp				; Reset Time_One_Hour to 0
	lds		temp, Time_Ten_Hour				; Load in Time_One_Hour from memory
	inc		temp
	sts		Time_Ten_Hour, temp

;	Display the updated time on the lcd
time_increase_display:

;	Check if you are currently in the menu
	sbrc	in_menu, $00
	jmp		time_increase_return_interrupt

;	Check if it's time for the alarm
	sbrs	alarm_active, 0
	call	time_increase_current_alarm

;	Clear the display
	call	lcd_clear_instruction

;	Print out 4 empty spaces before the time
	ldi		ZH,	high(Four_Empty)
	ldi		ZL,	low(Four_Empty)
	ldi		temp, lcd_LineOne
	call    lcd_write_string

;	Print out Time_Ten_Hour
	lds		temp, Time_Ten_Hour
	call    time_increase_number

;	Print out Time_One_Hour
	lds		temp, Time_One_Hour
	call    time_increase_number

;	Print :
	ldi		temp, $3A
	out		PORTA, temp 
	call	lcd_write_character

;	Print out Time_Ten_Min
	lds		temp, Time_Ten_Min
	call    time_increase_number

;	Print out Time_One_Min
	lds		temp, Time_One_Min
	call    time_increase_number

;	Print ":"
	ldi		temp, $3A
	out		PORTA, temp
	call	lcd_write_character

;	Print out Time_Ten_Sec
	lds		temp, Time_Ten_Sec
	call    time_increase_number

;	Print out Time_One_Sec
	lds		temp, Time_One_Sec
	call    time_increase_number

;	Print out the current alarm
;	Print out 4 empty spaces before the alarm
	ldi		ZH,	high(Four_Empty)
	ldi		ZL,	low(Four_Empty)
	ldi		temp, lcd_LineTwo
	call    lcd_write_string

;	Print out Alarm_Current_Hour
	push	r17

	lds		temp, Alarm_Current_Hour
	ldi		r17, $F0						; Get the First number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Current_Hour
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the first number

	;	Print ":"
	ldi		temp, $3A
	out		PORTA, temp
	call	lcd_write_character

;	Print out Alarm_Current_Min
	lds		temp, Alarm_Current_Min
	ldi		r17, $F0						; Get the First number
	and		temp, r17
	lsr		temp
	lsr		temp
	lsr		temp
	lsr		temp
	call    time_increase_number			; Print out the first number

	lds		temp, Alarm_Current_Min
	ldi		r17, $0F						; Get the second number
	and		temp, r17
	call    time_increase_number			; Print out the second number
	pop		r17


;	Return from the interrupt
time_increase_return_interrupt:
	pop		ZL
	pop		ZH
	pop		temp
	sei
	reti

;	Manualy decide what number to print and how to print it
time_increase_number:
	cpi		temp, $00
	breq	time_increase_number_zero

	cpi		temp, $01
	breq	time_increase_number_one

	cpi		temp, $02
	breq	time_increase_number_two

	cpi		temp, $03
	breq	time_increase_number_three

	cpi		temp, $04
	breq	time_increase_number_four

	cpi		temp, $05
	breq	time_increase_number_five

	cpi		temp, $06
	breq	time_increase_number_six

	cpi		temp, $07
	breq	time_increase_number_seven

	cpi		temp, $08
	breq	time_increase_number_eight

	cpi		temp, $09
	breq	time_increase_number_nine
	
;	Print out a 0
time_increase_number_zero:
	ldi		temp, $30
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 1
time_increase_number_one:
	ldi		temp, $31
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 2
time_increase_number_two:
	ldi		temp, $32
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 3
time_increase_number_three:
	ldi		temp, $33
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 4
time_increase_number_four:
	ldi		temp, $34
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 5
time_increase_number_five:
	ldi		temp, $35
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 6
time_increase_number_six:
	ldi		temp, $36
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 7
time_increase_number_seven:
	ldi		temp, $37
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 8
time_increase_number_eight:
	ldi		temp, $38
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret

;	Print out a 9
time_increase_number_nine:
	ldi		temp, $39
	out		PORTA, temp
	call	lcd_write_character
	jmp		time_increase_number_ret


;	Return from displaying number
time_increase_number_ret:
	ret


;	Compare the current time with the current alarm
time_increase_current_alarm:
	push	r0
	push	r17
	ldi		r17, 16

;	Compare the current hour with the current Alarm
	lds		temp, Time_Ten_Hour				; Load in the current time, hour
	muls	temp, r17
	lds		temp, Time_One_Hour
	add		temp, r0
	
	lds		r17, Alarm_Current_Hour			; Load in the current alarm, hour
	cp		temp, r17						; Compare
	breq	time_increase_current_alarm_min	; Branch if ==
	rjmp	time_increase_current_alarm_done; Return if !=

;	Compare the current hour with the current Alarm
time_increase_current_alarm_min:
	ldi		r17, 16
	lds		temp, Time_Ten_Min				; Load in the current time, min
	muls	temp, r17
	lds		temp, Time_One_Min
	add		temp, r0
	
	lds		r17, Alarm_Current_Min			; Load in the current alarm, min
	cp		temp, r17						; Compare
	breq	time_increase_current_alarm_sec	; Branch if ==
	rjmp	time_increase_current_alarm_done; Return if !=

;	Compare the current min with the current Alarm
time_increase_current_alarm_sec:
	ldi		r17, 16
	lds		temp, Time_Ten_Sec				; Load in the current time, sec
	muls	temp, r17
	lds		temp, Time_One_Sec
	add		temp, r0

	ldi		r17, $01						; Load in the current alarm, min
	cp		temp, r17						; Compare
	breq	time_increase_current_alarm_ring; Branch if ==
	rjmp	time_increase_current_alarm_done; Return if !=

;	Activate the alarm
time_increase_current_alarm_ring:
	ser		alarm_active						; Set to activate alarm

	ldi		temp, $A5
	out		UDR, temp

;	Pop and return
time_increase_current_alarm_done:
	pop		r17
	pop		r0
	ret

	
;	Ring the bells
time_increase_alarm:
	push	r17
	push	r18

	ldi		r18, 10

time_increase_alarm_outer_loop:
	ldi		r17, Beep_Lenght				; Load in the sounds lenght
	
time_increase_alarm_loop:
	sbi		SPEAKER_port, SPEAKER_bit		; Activate the speaker
	ldi		temp, Beep_Pitch				; Load in the pitch
	rcall	time_increase_alarm_delay		; Wait
	cbi		SPEAKER_port, SPEAKER_bit		; Deactivate the speaker
	ldi		temp, Beep_Pitch				; Load in the pitch
	rcall	time_increase_alarm_delay		; Wait
	dec		r17
	cpi		r17, $00
	brne	time_increase_alarm_loop		; Branch if sound is not finished

	dec		r18
	cpi		r18, $00
	brne	time_increase_alarm_outer_loop
	pop		r18
	pop		r17
	ret

time_increase_alarm_delay:
	dec		temp
	cpi		temp, $00
	brne	time_increase_alarm_delay
	ret