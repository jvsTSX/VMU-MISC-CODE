	.org 0   ; entry point
  jmpf Start
	.org $03 ; External int. (INT0)                 - I01CR
  reti
	.org $0B ; External int. (INT1)                 - I01CR
  reti
	.org $13 ; External int. (INT2) and Timer 0 low - I23CR and T0CNT
  reti
	.org $1B ; External int. (INT3) and base timer  - I23CR and BTCR
  reti
	.org $23 ; Timer 0 high                         - T0CNT
  reti
	.org $2B ; Timer 1 Low and High                 - T1CNT
  reti
	.org $33 ; Serial IO 1                          - SCON0
  reti
	.org $3B ; Serial IO 2                          - SCON1
  reti
	.org $43 ; Maple                                - 160 and 161
  reti
	.org $4B ; Port 3 interrupt                     - P3INT
  reti


 	.org	$1F0 ; exit app mode
goodbye:	
	not1	EXT, 0
	jmpf	goodbye
  
  
	.org $200
	.byte "T1 MODE 3 TEST  " ; ................... 16-byte Title
	.byte "by https://github.com/jvsTSX    " ; ... 32-byte Description
	.org $240 ; >>> ICON HEADER
	.org $260 ; >>> PALETTE TABLE
	.org $280 ; >>> ICON DATA

;    /////////////////////////////////////////////////////////////
;   ///                       GAME CODE                       ///
;  /////////////////////////////////////////////////////////////

	.include "sfr.i"
	
LastKeys =        $4
RegSel =          $5
KeyRepCntLow =    $6
KeyRepCntHigh =   $7
TimerRelHigh =    $8
TimerComHigh =    $9
TimerRelLow =     $A
TimerComLow =     $B
Timer1Enables =   $C

Start: ; setup
	mov #0, IE
	mov #%00000000, OCR
	
	; setup RAM variables
	mov #$FF, LastKeys
	mov #0, RegSel
	mov #$10, KeyRepCntLow
	mov #$08, KeyRepCntHigh
	mov #0, TimerRelHigh
	mov #$80, TimerComHigh
	mov #0, TimerRelLow
	mov #$80, TimerComLow
	mov #%11000000, Timer1Enables
	mov #<Numbers, TRL
	mov #>Numbers, TRH
	
	; enable port 1 to output to buzzer
	mov #$80, P1FCR
	clr1 P1, 7
	mov #$80, P1DDR
	
	; initialize screen
	mov #$80, 2
	mov #0, XBNK
.Loop:
	mov #0, @r2 ; line 1
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2 ; line 2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	inc 2
	mov #0, @r2
	ld 2
	add #5
	st 2
  bnz .Loop
  bp XBNK, 0, .LoopDone
	inc XBNK
	mov #80, 2
  br .Loop
.LoopDone:



Main: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld P3
	st C
  be LastKeys, NoButtonKeys ; check SMBA keys
	st LastKeys
	
  bp C, 4, .NoAkey   ; increment register selector
	inc RegSel
	ld RegSel
	and #%00000011
	st RegSel
.NoAkey:
	
  bp C, 5, .NoBkey   ; apply register data
	; disable T1 output
	ld Timer1Enables 
	or #%00100000
	st T1CNT
	; update registers
	ld TimerComHigh
	st T1HC
	ld TimerRelHigh
	st T1HR
	ld TimerComLow
	st T1LC
	ld TimerRelLow
	st T1LR
	; re-enable T1 output
	ld Timer1Enables
	or #%00110000
	st T1CNT
.NoBkey:
	
  bp C, 6, .NoMode  ; go back to BIOS
  jmpf goodbye
.NoMode:
	
  bp C, 7, .NoSleep ; cycle timer speed
	ld Timer1Enables
	add #%01000000
	st Timer1Enables
.NoSleep:
NoButtonKeys:
	
	ld C ; check DPAD keys
	or #%11110000
  be #$FF, .NoDPADKeys
	; repeat counter
	dec KeyRepCntLow
	ld KeyRepCntLow
  bnz .NoDPADKeys
	mov #$10, KeyRepCntLow
	; configure indirect pointer
	ld RegSel
	add #8
	st 0
	
  bp C, 0, .NoUp   ; increment high nibble
	ld @r0
	add #$10
	st @r0
.NoUp:
	
  bp C, 1, .NoDown  ; decrement high nibble
	ld @r0
	sub #$10
	st @r0
.NoDown:
	
  bp C, 2, .NoLeft  ; decrement low nibble
	dec @r0
.NoLeft:
	
  bp C, 3, .NoRight ; increment low nibble
	inc @r0
.NoRight:
.NoDPADKeys:
	
	; update register values
	mov #0, XBNK
	mov #$80, 2
	ld TimerRelHigh
  call DrawNumbers
	mov #$C0, 2
	ld TimerComHigh
  call DrawNumbers
	inc XBNK
	mov #$80, 2
	ld TimerRelLow
  call DrawNumbers
	mov #$C0, 2
	ld TimerComLow
  call DrawNumbers
	
	; draw timer 1 enable states (tiny numbers)
	mov #0, XBNK
	ld Timer1Enables
	ror
	ror
	ror
	ror
	add #$80 ; skip the big numbers, this way i don't need to reload TR
	st C
	ldc
	st $185
	inc C
	ld C
	ldc
	st $18B
	inc C
	ld C
	ldc
	st $195
	inc C
	ld C
	ldc
	st $19B
	
	; update cursor
	clr1 $182, 7   ; clear all other cursor states
	clr1 $1C2, 7
	inc XBNK
	clr1 $182, 7
	clr1 $1C2, 7
	dec XBNK

	ld RegSel      ; draw current cursor position
  bne #0, .Not0    ; this looks stupid but it's faster
	set1 $182, 7   ; for this case in specific
.Not0:
  bne #1, .Not1
	set1 $1C2, 7
.Not1:
	inc XBNK
  bne #2, .Not2
	set1 $182, 7
.Not2:
  bne #3, .Not3
	set1 $1C2, 7
.Not3:

  jmp Main



DrawNumbers: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; r0 = number rows to copy
	; r1 = loop watch number (will exit when it hits 2)
	; r2 = loop TR lookup index
	; B  = Number to display
	; C  = Nibble being displayed
	mov #0, 1
	mov #3, 0
	st B
	ror
	ror
	ror
	ror
.NextNum:
	rol
	rol
	rol
	and #%01111000
	st C
	
.Loop:
	ld C
	ldc 
	st @r2
	inc C
	ld 2
	add #$6
	st 2
	
	ld C
	ldc 
	st @r2
	inc C
	ld 2
	add #$A
	st 2
  dbnz 0, .Loop
	
	mov #3, 0
	sub #$2F ; back to first line + next row
	st 2
	inc 1
	ld 1
  be #2, .Exit ; this will only allow the loop to run once again
	ld B
  br .NextNum
.Exit:
  ret



Numbers: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.byte %01111100 ; 0
.byte %10001010
.byte %10010010
.byte %10010010
.byte %10100010
.byte %01111100
.byte $00
.byte $00
.byte %00010000 ; 1
.byte %00110000
.byte %01010000
.byte %00010000
.byte %00010000
.byte %11111110
.byte $00
.byte $00
.byte %01111100 ; 2
.byte %10000010
.byte %00000010
.byte %00011100
.byte %01100000
.byte %11111110
.byte $00
.byte $00
.byte %01111100 ; 3
.byte %10000010
.byte %00011100
.byte %00000010
.byte %10000010
.byte %01111100
.byte $00
.byte $00
.byte %00100100 ; 4
.byte %01000100
.byte %10000100
.byte %11111110
.byte %00000100
.byte %00000100
.byte $00
.byte $00
.byte %11111110 ; 5
.byte %10000000
.byte %11111100
.byte %00000010
.byte %10000010
.byte %01111100
.byte $00
.byte $00
.byte %00111100 ; 6
.byte %01000000
.byte %10000000
.byte %11111100
.byte %10000010
.byte %01111100
.byte $00
.byte $00
.byte %11111110 ; 7
.byte %00000010
.byte %00000100
.byte %00001000
.byte %00010000
.byte %00100000
.byte $00
.byte $00
.byte %00111100 ; 8
.byte %01000010
.byte %00111100
.byte %11000010
.byte %10000010
.byte %01111100
.byte $00
.byte $00
.byte %01111100 ; 9
.byte %10000010
.byte %01111110
.byte %00000010
.byte %00000100
.byte %01111000
.byte $00
.byte $00
.byte %00000110 ; A
.byte %00001010
.byte %00010010
.byte %00111110
.byte %01000010
.byte %10000010
.byte $00
.byte $00
.byte %11111100 ; B
.byte %10000010
.byte %11111100
.byte %10000010
.byte %10000010
.byte %11111100
.byte $00
.byte $00
.byte %01111100 ; C
.byte %10000010
.byte %10000000
.byte %10000000
.byte %10000010
.byte %01111100
.byte $00
.byte $00
.byte %11111000 ; D
.byte %10000110
.byte %10000010
.byte %10000010
.byte %10000110
.byte %11111000
.byte $00
.byte $00
.byte %11111110 ; E
.byte %10000000
.byte %11111000
.byte %10000000
.byte %10000000
.byte %11111110
.byte $00
.byte $00
.byte %11111110 ; F
.byte %10000000
.byte %11111000
.byte %10000000
.byte %10000000
.byte %10000000
.byte $00
.byte $00

NumbersTiny:
.byte %00000010 ; 1
.byte %00000110
.byte %00000010
.byte %00001111

.byte %00001110 ; 2
.byte %00000001
.byte %00000110
.byte %00001111

.byte %00001111 ; 3
.byte %00000111
.byte %00000001
.byte %00001111

.byte %00001010 ; 4
.byte %00001010
.byte %00001111
.byte %00000010

.cnop 0, $200 