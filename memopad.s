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
	mov #$FF, HaltCnt
	clr1 P3INT, 1
  reti

 	.org $1F0 ; exit app mode
goodbye:	
	not1 EXT, 0
  jmpf goodbye

	.org $200
	.byte "MEMO PAD        " ; ................... 16-byte Title
	.byte "by https://github.com/jvsTSX    " ; ... 32-byte Description
	.org $240 ; >>> ICON HEADER
	.org $260 ; >>> PALETTE TABLE
	.org $280 ; >>> ICON DATA

;    /////////////////////////////////////////////////////////////
;   ///                       SETUP CODE                      ///
;  /////////////////////////////////////////////////////////////

	.include "sfr.i"

KeyRepCnt =      $4
Flags =          $5
Xpos =           $6
Ypos =           $7
Xroll =          $8
LastKeys =       $9
HaltCnt =        $A

Start: ; setup
;	mov #0, IE
	mov #%10100001, OCR
	mov #%10000000, Xroll
	mov #$01, VRMAD2
	mov #1, KeyRepCnt
	clr1 VSEL, 4
	mov #0, T1CNT
	clr1 BTCR, 6
	mov #%00000101, P3INT
	mov #$FF, HaltCnt

; clear screen
	; initialize screen
	mov #$80, 2
	mov #0, XBNK
.Loop:
	xor ACC
	st @r2 ; line 1
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2 ; line 2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	inc 2
	st @r2
	ld 2
	add #5
	st 2
  bnz .Loop
  bp XBNK, 0, .LoopDone
	inc XBNK
	mov #80, 2
  br .Loop
.LoopDone:


; copy initial screen shit
	mov #<TextImg, TRL
	mov #>TextImg, TRH
	mov #0, XBNK
	mov #$80, 2
	mov #6, 1
	mov #0, C
.CopyLoop:
	ld C
	ldc
	inc C
	st @r2
	inc 2
	ld C
	ldc
	inc C
	st @r2
	ld 2
	add #5
	st 2
	
	ld C
	ldc
	inc C
	st @r2
	inc 2
	ld C
	ldc
	inc C
	st @r2
	ld 2
	add #9
	st 2
  dbnz 1, .CopyLoop

	mov #%00000010, 3


InitialScreen:
	ld P3
	be LastKeys, .NoKeys
	st LastKeys
  bp LastKeys, 0, .NoUp
	not1 3, 0
	set1 3, 1
.NoUp:

  bp LastKeys, 1, .NoDown
	not1 3, 0
	set1 3, 1
.NoDown:

  bp LastKeys, 4, .NoA
	bp 3, 0, Clear
	br Keep
.NoA:

  bp LastKeys, 6, .NoMode
	set1 BTCR, 6
  jmp goodbye
.NoMode:
.NoKeys:

; draw cursor
  bn 3, 1, .NoCursorUpdate
	mov #0, $188
	mov #0, $192
	mov #0, $198

	mov #0, $1C8
	mov #0, $1D2
	mov #0, $1D8

	clr1 3, 1
	ld 3
	ror
	ror
	add #$88
	st 2
	mov #%00100000, @r2
	add #$A
	st 2
	mov #%01100000, @r2
	add #$6
	st 2
	mov #%00100000, @r2
.NoCursorUpdate:

  dbnz HaltCnt, .Continue
	set1 PCON, 0
.Continue:
  br InitialScreen

Clear:
	set1 VSEL, 4
	mov #$40, VRMAD1
	set1 VRMAD2, 0
	mov #$C0, 1
.ClearLoop:
	mov #0, VTRBF
  dbnz 1, .ClearLoop
	clr1 VSEL, 4
Keep:
	mov #0, P3INT
	mov #%10000100, T1CNT
	mov #$FF, T1HR

;    /////////////////////////////////////////////////////////////
;   ///                        MAIN LOOP                      ///
;  /////////////////////////////////////////////////////////////
Main:
	ld P3
	st C
  be LastKeys, NoButtonKeys ; check SMBA keys
	st LastKeys


  bp C, 6, .NoMode ; go back to BIOS
	set1 BTCR, 6
	jmpf goodbye
.NoMode:

  bp C, 7, .NoSleep ; uhhh i'll look at this later
.NoSleep:

NoButtonKeys:
  bp C, 4, .NoA ; paint black pixel
  call GetDotVRAM
	ld VTRBF
	or Xroll
	st VTRBF
	set1 Flags, 0
.NoA
	
  bp C, 5, .NoB ; erase pixel	
  call GetDotVRAM
	ld VTRBF
	st B
	ld Xroll
	xor #$FF
	and B
	st VTRBF
	set1 Flags, 0
.NoB:

  bp C, 0, .NoUp
 	set1 Flags, 0
	ld Ypos
	sub #%00001000
	st Ypos
.NoUp:

  bp C, 1, .NoDown
	set1 Flags, 0
	ld Ypos
	add #%00001000
	st Ypos
.NoDown:

  bp C, 2, .NoLeft
	set1 Flags, 0
	dec Xpos
	ld Xroll
	rol
	st Xroll
.NoLeft:

  bp C, 3, .NoRight
	set1 Flags, 0
	inc Xpos
	ld Xroll
	ror
	st Xroll
.NoRight:

; wrap cursor
	ld Xpos
  be #48, .here
.here:
  bp PSW, 7, .NoDpadKeys
  be #152, .here2
.here2:
  bp PSW, 7, .WrapTo0
	mov #47, Xpos
  br .NoDpadKeys
.WrapTo0:
	mov #0, Xpos

.NoDpadKeys:

; refresh XRAM
  bn Flags, 0, .Done
	clr1 Flags, 0
	mov #0, XBNK
	mov #$80, 2
	mov #$01, VRMAD2
	mov #$40, VRMAD1
	set1 VSEL, 4
	clr1 OCR, 5
.loop: ; 648 + 12 cycles (oof.mp3)
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2

	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	inc 2
	ld VTRBF
	st @r2
	
	ld 2
	add #5
	st 2

  bnz .loop
  bp XBNK, 0, .Done
	set1 2, 7
	inc XBNK
  br .loop
.Done:
	set1 OCR, 5
	clr1 VSEL, 4
	mov #$01, VRMAD2

; draw cursor
	mov #0, XBNK
	ld Ypos
	clr1 ACC, 3
	set1 ACC, 7
  bn Ypos, 3, .Even
	add #6
.Even:
  bn Ypos, 7, .XBNKlow
	inc XBNK
.XBNKlow:
	st B
	
	ld Xpos
	ror
	ror
	ror
	and #%00000111
	add B
	st 2
	ld @r2
	xor Xroll
	st @r2

	set1 PCON, 0
  jmp Main




GetDotVRAM:
	push C

	ld Ypos
	ror
	ror
	ror
	st C
	xor ACC
	mov #6, B
	mul
	
	ld Xpos
	ror
	ror
	ror
	and #%00000111
	add C
	add #$40
	st VRMAD1
	
	pop C
  ret



TextImg:
.byte %10010000, %00000000 ; Keep
.byte %10100011, %00110110
.byte %11000111, %01110111
.byte %10100100, %01000100
.byte %10010011, %00110100
.byte 0, 0
.byte 0, 0
.byte %01101000, %00000000 ; Clear
.byte %10001001, %10110001
.byte %10001011, %10001010
.byte %10001010, %00111010
.byte %01100101, %10111010

	.cnop 0, $200 ;