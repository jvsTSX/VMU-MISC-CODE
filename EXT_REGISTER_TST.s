	.org 0 ; entry point
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
	mov #$6, HaltCounterHigh
	mov #$FF, HaltCounterLow
	clr1 P3INT, 1
  reti

 	.org $1F0 ; exit app mode
goodbye:	
	not1 EXT, 0
  jmpf goodbye

	.org $200
	.byte "EXT REGISTER TST" ; ................... 16-byte Title
	.byte "by https://github.com/jvsTSX    " ; ... 32-byte Description
	.org $240 ; >>> ICON HEADER
	.org $260 ; >>> PALETTE TABLE
	.org $280 ; >>> ICON DATA

;    /////////////////////////////////////////////////////////////
;   ///                   RAM DEFINITIONS                     ///
;  /////////////////////////////////////////////////////////////
temp1 =           $4
temp2 =           $5
temp3 =           $6
chptr =           $10
AddressHigh =     $11
AddressLow =      $12
UpdateFlags =     $13
cursor =          $14
lastinputs =      $15
HaltCounterLow =  $16
HaltCounterHigh = $17
String0 =         $18
String1 =         $19
String2 =         $1A
String3 =         $1B
String4 =         $1C
String5 =         $1D
String6 =         $1E
String7 =         $1F
CursorExtBit =    $20
CursorExtInt =    $21
ExtShadow =       $22



;    /////////////////////////////////////////////////////////////
;   ///                      SETUP CODE                       ///
;  /////////////////////////////////////////////////////////////
	.include "sfr.i"

Start:
	; initialize registers
	mov #%10000001, OCR ; select RC clock /6
	mov #0, T1CNT ; turn off timer 1
	mov #%00000101, P3INT ; joypad interrupts on
	set1 VSEL, 4 ; work RAM auto increment on
	clr1 $154, 0 ; select flash bank 0 in FPR
	clr1 BTCR, 6 ; disable base timer to not mess with the halt counter

	; initialize RAM
	mov #$12, HaltCounterHigh
	mov #$80, CursorExtBit
	mov #1, ExtShadow
	mov #0, CursorExtInt
	mov #0, cursor
	mov #$FF, lastinputs
	mov #0, HaltCounterLow
	mov #<TestData, AddressLow
	mov #>TestData, AddressHigh
	mov #%00001111, UpdateFlags

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
	set1 2, 7
  br .Loop
.LoopDone:

	; print Address label
	mov #0, XBNK
	mov #$B6, 2
	mov #$00, 3
	mov #4, temp1
	mov #<FlashStringAddr, temp2
	mov #>FlashStringAddr, temp3
  call PrintStringFlash

	; print EXT label
	mov #1, XBNK
	mov #$D0, 2
	mov #$00, 3
	mov #3, temp1
	mov #<FlashStringEXT, temp2
	mov #>FlashStringEXT, temp3
  call PrintStringFlash



;    /////////////////////////////////////////////////////////////
;   ///                      MAIN LOOP                        ///
;  /////////////////////////////////////////////////////////////
MainLoop:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; get inputs
	ld P3
  be lastinputs, NoKeys
	st lastinputs

; common block between increment and decrement nibble
	ld cursor
	clr1 PSW, 7
	rorc
	add #$11
	st 1

  bp lastinputs, 0, .NoUp ; increment selected address nibble
	set1 UpdateFlags, 0
  bn cursor, 0, .IncHighNib
	inc @r1
  br .NoUp
.IncHighNib:
	ld @r1
	add #$10
	st @r1
.NoUp:

  bp lastinputs, 1, .NoDown ; decrement selected address nibble
	set1 UpdateFlags, 0
  bn cursor, 0, .DecHighNib
	dec @r1
  br .NoDown
.DecHighNib:
	ld @r1
	sub #$10
	st @r1
.NoDown:

  bp lastinputs, 2, .NoLeft ; move address cursor to the left
	ld cursor
	dec ACC
	and #%00000011
	st cursor
	set1 UpdateFlags, 2
.NoLeft:


  bp lastinputs, 3, .NoRight ; move address cursor to the right
	ld cursor
	inc ACC
	and #%00000011
	st cursor
	set1 UpdateFlags, 2
.NoRight:

  bp lastinputs, 4, .NoA ; move EXT cursor to the left
	ld CursorExtBit
	rol
	st CursorExtBit
	ld CursorExtInt
	dec ACC
	and #%00000111
	st CursorExtInt
	set1 UpdateFlags, 1
.NoA:

  bp lastinputs, 5, .NoB ; move EXT cursor to the right
	ld CursorExtBit
	ror
	st CursorExtBit
	ld CursorExtInt
	inc ACC
	and #%00000111
	st CursorExtInt
	set1 UpdateFlags, 1
.NoB:

  bp lastinputs, 6, .NoMode ; go back to BIOS
	set1 BTCR, 6
	jmp goodbye
.NoMode:

  bp lastinputs, 7, .NoSleep ; flip EXT bit
	ld ExtShadow
	xor CursorExtBit
	st ExtShadow
	st EXT
	set1 UpdateFlags, 3
  jmpf .NoSleep
.NoSleep:
NoKeys:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; print address cursor
  bn UpdateFlags, 2, NoAddrCursor
	mov #0, XBNK
	mov #0, $1F4
	mov #0, $1F5
	mov #0, $1FA
	mov #0, $1FB
	
	ld cursor
	rorc 
	clr1 ACC, 7
	add #$F4
	st 2
  bp cursor, 0, .left
	mov #%01000000, ACC
	mov #%11100000, B
	br .right
.left:
	mov #%00000100, ACC
	mov #%00001110, B
.right:
	st @r2
	ld 2
	add #6
	st 2
	ld B
	st @r2

	clr1 UpdateFlags, 2
NoAddrCursor:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; print EXT bit cursor
  bn UpdateFlags, 1, NoExtCursor
	mov #1, XBNK
	mov #0, $1C2
	mov #0, $1C3
	mov #0, $1C4
	mov #0, $1C5
	mov #0, $1B8
	mov #0, $1B9
	mov #0, $1BA
	mov #0, $1BB

	ld CursorExtInt
	rorc
	clr1 ACC, 7
	add #$B8
	st 2
  bp CursorExtInt, 0, .left
	mov #%11100000, ACC
	mov #%01000000, B
  br .right
.left:
	mov #%00001110, ACC
	mov #%00000100, B
.right:
	st @r2
	ld 2
	add #$A
	st 2
	ld B
	st @r2

	clr1 UpdateFlags, 1
NoExtCursor:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; print EXT shadow reg
  bn UpdateFlags, 3, NoExtShadowRef
	mov #8, 1
	mov #$18, 0
	ld ExtShadow
	st B
.ASCIIloop: ; convert EXT bits into a string
  bp ACC, 7, .One
	mov #$30, @r0
  br .Zero
.One:
	mov #$31, @r0
.Zero:
	inc 0
	rol
  dbnz 1, .ASCIIloop
	mov #8, 3
	mov #$18, temp2
	mov #1, XBNK
	mov #$D2, temp1
  call PrintStringRAM

	clr1 UpdateFlags, 3
NoExtShadowRef:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; print text and address
  bn UpdateFlags, 0, NoText
 
	; clear WRAM buffer
	mov #0, chptr
	mov #6, 1
  call ClearCharCellsWRAMnoDiv

	; print text into WRAM
	mov #12, 3
	mov #0, 1
.TextLoop:
	ld AddressLow
	st TRL
	ld AddressHigh
	st TRH
	ld 1
	inc 1
	ldc
  call DrawChar
  dbnz 3, .TextLoop

	; send result to screen
	mov #$80, 2
	mov #6, 1
	mov #0, XBNK
  call PrintCharCellsNoCellDiv

	; render address indicator
	ld AddressHigh
	ror
	ror
	ror
	ror
  call Hex2ASCII
	st String0
	ld AddressHigh
  call Hex2ASCII
	st String1

	ld AddressLow
	ror
	ror
	ror
	ror
  call Hex2ASCII
	st String2
	ld AddressLow
  call Hex2ASCII
	st String3

	mov #4, 3
	mov #$18, temp2
	mov #0, XBNK
	mov #$BA, temp1
  call PrintStringRAM

	clr1 UpdateFlags, 0
NoText:
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; halt counter
; - stops CPU untill joypad press if nothing have been pressed for a while
  dbnz HaltCounterLow, .Continue
	mov #$FF, HaltCounterLow
  dbnz HaltCounterHigh, .Continue
	mov #$6, HaltCounterHigh
	
	set1 OCR, 5 ; select quartz ot use less power
	set1 PCON, 0 ; halt
	clr1 OCR, 5 ; select RC clock back
.Continue:
  jmp MainLoop



;    /////////////////////////////////////////////////////////////
;   ///                      SUBROUTINES                      ///
;  /////////////////////////////////////////////////////////////
Hex2ASCII:
	and #%00001111
  be #$A, .here
.here:
  bp PSW, 7, .ConvertToNumber
	; or else uppercase letter
	add #$37
  ret

.ConvertToNumber:
	add #$30
  ret



PrintStringFlash: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; r2 and XBNK = XRAM location
	; temp1 = char count
	; temp2 = flash address low
	; temp3 = flash address high

	ld temp1 ; initialize WRAM
  call ClearCharCellsWRAM

	; render text
	ld temp1
	st 1
	mov #0, chptr
.StringLoop:
	ld temp2
	st TRL
	ld temp3
	st TRH
	ldf
  call DrawChar
	inc temp2
	ld temp2
  bnz .NoCarry
	inc temp3
.NoCarry:
  dbnz 1, .StringLoop

	; copy result
	ld temp1
  call PrintCharCells
  ret



PrintStringRAM: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; r3 = char count
	; temp1 and XBNK = XRAM location
	; temp2 = RAM location
	ld 3
  call ClearCharCellsWRAM

	mov #0, chptr
	ld temp2
	st 1
	ld 3 ; char cnt
	st 2
.StringLoop
	ld @r1
  call DrawChar
	inc 1
  dbnz 2, .StringLoop

	ld temp1
	st 2
	ld 3
  call PrintCharCells
  ret



ClearCharCellsWRAM: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initializes work RAM char cells because the rendering process involves OR masking
	; r1 = char count
	clr1 PSW, 7
	rorc
	addc #0 ; adjust cell count to char count (1 cell = 2 char)
	st 1
ClearCharCellsWRAMnoDiv:
	mov #0, VRMAD1
	set1 VRMAD2, 0
.CleanLoop:
	xor ACC
	st VTRBF
	st VTRBF
	st VTRBF
	st VTRBF
	st VTRBF
	st VTRBF
  dbnz 1, .CleanLoop
  ret



PrintCharCells: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; renders char cells from WRAM into XRAM
	; XBNK and r2 = position
	; 1 = char count
	clr1 PSW, 7
	rorc
	addc #0 ; adjust cell count to char count (1 cell = 2 char)
	st 1
PrintCharCellsNoCellDiv:
 ; check line parity, if greater than 5 then it's an odd line
	mov #0, C
	ld 2
	and #%00001111
	be #6, .here
.here
  bn PSW, 7, .evenline
	inc C
.evenline:

	mov #0, VRMAD1
	set1 VRMAD2, 0
.CopyLoop: ; copy amount of chars
	mov #6, B
.SubLoop: ; copy one char
	ld VTRBF
	st @r2
	ld 2
  bp C, 0, .even
	add #4
.even:
	add #6
	st 2
	not1 C, 0
  dbnz B, .SubLoop
	ld 2
	sub #$2F
	st 2
  dbnz 1, .CopyLoop
  ret

; you won't believe how many headaches this fucker can create



DrawChar: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; renders one char to Work RAM
	; ACC = char to draw

;            shift-jis layout
;     0 1 2 3 4 5 6 7 8 9 A B C D E F
;      _____________________________
; 0   |    control chars (blank)    |
; 1   |____________________________/|
; 2   |                             |
; 3   |                             |
; 4   |        english chars        |
; 5   |                             |
; 6   |                             |
; 7   |____________________________/|
; 8   |         blank chars         |
; 9   |____________________________/|
; A   |                             |
; B   |        japanese chars       |
; C   |                             |
; D   |____________________________/|
; E   |         blank chars         |
; F   |____________________________/

  be #$20, .here0
.here0:
  bp PSW, 7, .BlankChar
	
  be #$80, .here1
.here1:
  bp PSW, 7, .EnglishChar
	
  be #$A0, .here2
.here2:
  bp PSW, 7, .BlankChar
	
  be #$E0, .here3
.here3:
  bp PSW, 7, .JapaneseChar

	; fail condition = blank char
.BlankChar: ; don't render anything
	inc chptr
  ret
	
.EnglishChar:
	mov #<En_Chars, TRL
	mov #>En_Chars, TRH
	sub #$20
  br .Continue	
	
.JapaneseChar:
	mov #<Jp_Chars, TRL
	mov #>Jp_Chars, TRH
	sub #$A0
	
.Continue: ; multiply index by 6 and add char table offset to TR
	st C
	mov #6, B
	xor ACC
	mul
	st B
	ld C
	add TRL
	st TRL
	ld B
	addc TRH
	st TRH

	set1 VRMAD2, 0 ; get current cell
	ld chptr
	clr1 PSW, 7
	rorc
	st C
	xor ACC
	mov #6, B

; mask new char data into the cell and store new result
	mov #6, 0
  bp PSW, 7, MaskRight ; check odd/even
MaskLeft: ; mask regular
	mul
	ld C
	st VRMAD1
.MaskLoop:
	ldf
	or VTRBF
	dec VRMAD1
	st VTRBF
	inc TRL
	ld TRL
  bnz .NoCarry
	inc TRH
.NoCarry
  dbnz 0, .MaskLoop
	inc chptr
  ret

MaskRight: ; mask with ROR
    mul
    ld C
    st VRMAD1
.MaskLoop:
	ldf
	ror
	ror
	ror
	ror
	or VTRBF
	dec VRMAD1
	st VTRBF
	inc TRL
	ld TRL
  bnz .NoCarry
	inc TRH
.NoCarry
  dbnz 0, .MaskLoop
	inc chptr
  ret





;    /////////////////////////////////////////////////////////////
;   ///                       DATA AREA                       ///
;  /////////////////////////////////////////////////////////////
En_Chars:
	.include sprite "JIS_EN.png"  header="no"
	.include sprite "JIS_EN2.png" header="no"
	.include sprite "JIS_EN3.png" header="no"

Jp_Chars:
	.include sprite "JIS_JP.png"  header="no"
	.include sprite "JIS_JP2.png" header="no"

FlashStringAddr:
.byte "Addr"
FlashStringEXT:
.byte "EXT"

TestData:
;.byte ">FAIL fail < --- hello there, you're not supposed to see this on real hardware! ---" ; well turns out you can so uhhh just leaving it here for later
.byte "THIS' FLASH --- try poking around with EXT! --- beware with bit 0 ---"

; testing JIS english chars
;.byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F
;.byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F
;.byte $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F
;.byte $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F
;.byte $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
;.byte $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E, $7F


; testing JIS japanese chars
;.byte $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF
;.byte $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF
;.byte $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF
;.byte $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
.cnop $200, 0 