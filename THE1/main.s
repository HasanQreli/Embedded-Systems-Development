PROCESSOR 18F8722

#include <xc.inc>

; CONFIGURATION (DO NOT EDIT)
; CONFIG1H
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = OFF       ; Power-up Timer Enable bit (PWRT disabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
CONFIG DEBUG = OFF      ; Disable In-Circuit Debugger


GLOBAL var1
GLOBAL var2
GLOBAL var3
GLOBAL result
GLOBAL flag
GLOBAL counter
GLOBAL re

; Define space for the variables in RAM
PSECT udata_acs
var1:
    DS 1 ; Allocate 1 byte for var1
var2:
    DS 1 
var3:
    DS 1    
temp_result:
    DS 1   
result: 
    DS 1
flag: 
    DS 1
counter:
    DS 1
re:
    DS 1


PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE
main:
    clrf var1	; var1 = 0
    clrf var2
    clrf var3
    clrf result ; result = 0
    setf flag
    clrf re ; 2: re0 triggered, 3: re1 triggered``
    movlw 362
    movwf counter
    
    call init_io
    
    
    call busy_wait
    
    clrf PORTB
    clrf LATC
    clrf LATD
main_loop:
    call check_buttons
    call update_display
    goto main_loop
    

re0_released:
    btfsc PORTE, 0 ; skip if 0
    return
    bcf re, 0 ; RE0 is released
    btg re, 2 ; to indicate input is given in this iteration for re0 toggle
    return
re1_released:
    btfsc PORTE, 1 ; skip if 0
    return
    bcf re, 1 ; RE0 is released
    btg re, 3 ; to indicate input is given in this iteration for re0 toggle
    return
re0_pressed:
    bsf re, 0 ; RE0 is pressed
    return
re1_pressed:
    bsf re, 1 ; RE1 is pressed
    return
check_buttons:
    btfsc PORTE, 0 ; skip if 0
    rcall re0_pressed
    btfsc PORTE, 1 ; skip if 0
    rcall re1_pressed
    btfsc re, 0 ; check if RE0 was pressed before so now check if it is released
    call re0_released
    btfsc re, 1 ; check if RE0 was pressed before so now check if it is released
    call re1_released
    return 
    
update_display:
    incfsz counter
    return 
    movlw 419
    movwf counter
    incfsz var1
    return
    counter_overflowed:
	call d_control
	call c_control
	call b_control
	return

b_control:
    btfss re, 3 ; skip if 1 meaning do the light thing
    goto clean_b
    btfsc LATB, 7 ; skip if 0 check left bit if it is on clear
    goto clean_b
    rlncf LATB ; shift right
    bsf LATB, 0 ; make right bit 1
    return
    clean_b:
	clrf LATB
	return
	
c_control:
    btfss re, 2 ; skip if 1 meaning do the light thing
    goto clean_c
    btfsc LATC, 0 ; skip if 0 check right bit if it is on clear
    goto clean_c
    rrncf LATC ; shift right
    bsf LATC, 7 ; make left bit 1
    return
    clean_c:
	clrf LATC
	return
	
d_control:
    movlw 11111111B
    andwf flag
    bnz on
    off:
	clrf LATD
	setf flag
	return
    on:
	bsf LATD, 0
	clrf flag
	return
    
    
    
busy_wait:
    movlw 6
    movwf var3
    loop3:
	movlw 218
	movwf var2
	loop2:
	    setf var1
	    loop1:
		decf var1
		bnz loop1
	    decf var2
	    bnz loop2
	decf var3
	bnz loop3
    return

init_io:
    clrf TRISB
    clrf TRISC
    clrf TRISD
    setf TRISE
    
    setf PORTB
    setf LATC
    setf LATD
    return
    
end resetVec