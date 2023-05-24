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
	.byte "VMU SPEED TEST  " ; ................... 16-byte Title
	.byte "by https://github.com/jvsTSX    " ; ... 32-byte Description
	.org $240 ; >>> ICON HEADER
	.org $260 ; >>> PALETTE TABLE
	.org $280 ; >>> ICON DATA

;    /////////////////////////////////////////////////////////////
;   ///                       GAME CODE                       ///
;  /////////////////////////////////////////////////////////////

	.include "sfr.i"
CounterLow = $4
CounterHigh = $5
SpeedSel = $6
LastKeys = $7

Start:	
	mov #0, IE ; this program is a never-halting loop

	; initialize RAM variables
	mov #$FF, CounterLow
	mov #$08, CounterHigh
	mov #$00, SpeedSel
	mov #$FF, LastKeys
	
	; initialize Timer 1
	mov #$80, P1FCR ; output sound via P1 bit 7
	clr1 P1, 7
	mov #$80, P1DDR
	mov #%11010000, T1CNT ; Timer 1 Mode 1
	mov #$FE, T1LR ; highest possible pitch
	mov #$FF, T1LC

	; initialize screen
	mov #$80, 2
	mov #0, XBNK          ; this looks stupid but it's the fastest i can go
.Loop:                    ; while avoiding the weirdass stride pattern
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
	add #5 ; offset stride and increment (4+1)
	st 2
  bnz .Loop
  bp XBNK, 0, .LoopDone ; this will quit the loop if it reaches down here twice
	inc XBNK
	mov #80, 2
  br .Loop
.LoopDone:
	mov #0, XBNK
	mov #1, $181 ; init rolling bits
	mov #1, $187

	mov #<Numbers, TRL ; this program only use TR for one thing
	mov #>Numbers, TRH

MainLoop: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ld P3
	mov #10, B ; at CF speeds the inputs start getting bouncy
.Debounce:
  dbnz B, .Debounce
	ld P3
  be LastKeys, NoKeys
	st C
	st LastKeys
	
  bp C, 2, .NoLeft  ; decrement speed select
	dec SpeedSel
	ld SpeedSel
  bne #$FF, .NoLeft
	inc SpeedSel
.NoLeft:
	
  bp C, 3, .NoRight ; increment speed select
	inc SpeedSel
	ld SpeedSel
  bne #$06, .NoRight
	dec SpeedSel
.NoRight:
	
  bp C, 4, .NoAkey  ; apply speed
  bp SpeedSel, 2, .Ceramic
  bp SpeedSel, 1, .RCnetwork

; Quartz
	mov #$FE, T1LR
	mov #$FF, T1LC
  bp SpeedSel, 0, .QuartzFast
	; or else slow
	mov #%00100000, OCR
  br .NoAkey
.QuartzFast:
	mov #%10100000, OCR
  br .NoAkey

.RCnetwork:
	mov #$40, T1LR
	mov #$A0, T1LC
  bp SpeedSel, 0, .RCnetworkFast
	; or else slow
	mov #%00000000, OCR
  br .NoAkey
.RCnetworkFast:
	mov #%10000000, OCR
  br .NoAkey

.Ceramic:
	mov #$00, T1LR
	mov #$80, T1LC
  bp SpeedSel, 0, .CFfast
	; or else slow
	mov #%00010000, OCR
  br .NoAkey
.CFfast:
	mov #%10010000, OCR
.NoAkey:
	
  bp C, 6, .NoMode
  jmpf goodbye
.NoMode:
NoKeys:

	; Update speed indicator
	ld SpeedSel
	rol
	rol
	st B
	ldc
	st $180
	inc B
	ld B
	ldc
	st $186
	inc B
	ld B
	ldc
	st $190
	inc B
	ld B
	ldc
	st $196
	
	; Update rolling bits
; to show how fast the CPU is going, this program rolls two bits
; one rolls faster (bottom) and one rolls slower (top) because the faster bit
; should become invisible at CF speed (it does on the hw test video by colton)
; faster bit rolls every 255 main loops
; slower bit rolls every 2040 main loops
	dec CounterLow
	ld CounterLow
  bnz .Exit
	mov #$FF, CounterLow
	ld $187
	ror
	st $187
	
	dec CounterHigh
	ld CounterHigh	
  bnz .Exit
	mov #$08, CounterHigh
	ld $181
	ror
	st $181
.Exit

  jmp MainLoop
	


Numbers: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.byte %01111100 ; 0
.byte %10001010
.byte %10100010
.byte %01111100

.byte %00010000 ; 1
.byte %00110000
.byte %00010000
.byte %01111100

.byte %01111100 ; 2
.byte %10000110
.byte %00111000
.byte %11111110

.byte %11111100 ; 3
.byte %00111110
.byte %00000010
.byte %11111100

.byte %01001000 ; 4
.byte %10001000
.byte %11111110
.byte %00001000

.byte %11111110 ; 5
.byte %11111100
.byte %00000010
.byte %11111100

.cnop 0, $200 