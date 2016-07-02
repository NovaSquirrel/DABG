; Double Action Blaster Guys
;
; Copyright (C) 2012-2014 NovaSquirrel
;
; This program is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 3 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

.zeropage
r_seed: .res 1
.code

.proc ReadJoy
.ifdef fourscore
  lda keydown
  sta keylast
  lda keydown+1
  sta keylast+1
  lda keydown+2
  sta keylast+2
  lda keydown+3
  sta keylast+3

  ; Reset controllers
  ldx #1
  stx JOY1
  dex
  stx JOY1

  jsr ReadJoyOnce
  lda keydown+2
  sta keydown+0
  lda keydown+3
  sta keydown+1
  lda #0
  sta keydown+2
  sta keydown+3
  lda FourScorePluggedIn
  beq :+
  jsr ReadJoyOnce
:

  lda AttractMode
  bne Attract
  rts
.else
  lda keydown
  sta keylast
  lda keydown+1
  sta keylast+1
  lda #1
  sta keydown+1
  sta JOY1
  lda #0
  sta JOY1
: lda JOY1
  and #$03
  cmp #1
  rol keydown+0
  lda JOY2
  and #$03
  cmp #1
  rol keydown+1
  bcc :-
  lda AttractMode
  bne Attract
  rts
.endif

Attract:
  lda keydown
  and #KEY_START
  jne reset
  lda #0
  sta keydown

  ; Dumb little AI
  ldx #0
Loop:
  lda ObjectF1,x
  beq No
  lda ObjectPYH,x
  cmp PlayerPYH
  bne No
  lda ObjectF2,x
  bne No
  lda retraces
  and #8
  asl ; 16
  asl ; 32
  asl ; 64
  sta keydown

  lda PlayerPX
  cmp ObjectPX,x
  lda #0
  adc #0
  sta PlayerDir
  rts
No:
  inx
  cpx #ObjectLen
  bne Loop

  lda PlayerPX
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda PlayerPYH
  add #16
  and #$f0
  ora 0
  tay
  lda LevelBuf,y
  bne :+
    lda PlayerDir
    eor #1
    sta PlayerDir
  :

  ldx PlayerDir
  lda Directions,x
  sta keydown


  rts

Directions:
;  .byt KEY_B|KEY_RIGHT, KEY_B|KEY_LEFT
  .byt KEY_RIGHT, KEY_LEFT

.endproc

.ifdef fourscore
.proc ReadJoyOnce
  lda #1
  sta keydown+3
: lda JOY1
  and #$03
  cmp #1
  rol keydown+2
  lda JOY2
  and #$03
  cmp #1
  rol keydown+3
  bcc :-
  rts
.endproc
.endif

.proc wait_vblank
  lda retraces
  loop:
    cmp retraces
    beq loop
  rts
.endproc

.proc PutHex
	pha
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda hexdigits,x
	sta PPUDATA
	pla
	and #$0f
	tax
	lda hexdigits,x
	sta PPUDATA
	pla
	rts
hexdigits:	.byt "0123456789ABCDEF"
.endproc

.proc PutDecimal ; Prints with anywhere from 1 to 3 digits
   cmp #10 ; only one char
   bcs :+
     add #'0'    ; char is number+'0'
     sta PPUDATA
     rts
   :

   ; the hundreds digit if necessary
   cmp #200
   bcc LessThan200
   ldx #'2'
   stx PPUDATA
   sub #200
   jmp :+
LessThan200:
   cmp #100
   bcc :+
   ldx #'1'
   stx PPUDATA
   sub #100
:
   ldx #'0'    ; now calculate the tens digit
:  cmp #10
   bcc Finish
   sbc #10     ; carry will be set if this runs anyway
   inx
   jmp :-
Finish:
   stx PPUDATA ; display tens digit
   add #'0'
   sta PPUDATA ; display ones digit
   rts
.endproc
.proc ClearName
;Clear the nametable
  ldx #$20
  ldy #$00
  stx PPUADDR
  sty PPUADDR
  ldx #64
  ldy #4
  lda #' '
: sta PPUDATA
  inx
  bne :-
  dey
  bne :-
;Clear the attributes
  ldy #64
  lda #0
: dey
  bne :-
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

.proc WaitForKey
: jsr ReadJoy
  lda keydown
  ora keydown+1
.ifdef fourscore
  ora keydown+2
  ora keydown+3
.endif
  beq :-
  lda keylast
  ora keylast+1
.ifdef fourscore
  ora keylast+2
  ora keylast+3
.endif
  bne :-
  rts
.endproc
.proc PutStringImmediate
	DPL = $02
	DPH = $03
	pla					; Get the low part of "return" address
                        ; (data start address)
	sta     DPL     
	pla 
	sta     DPH         ; Get the high part of "return" address
                        ; (data start address)
						; Note: actually we're pointing one short
PSINB:	ldy #1
	lda (DPL),y         ; Get the next string character
	inc DPL             ; update the pointer
	bne PSICHO          ; if not, we're pointing to next character
	inc DPH             ; account for page crossing
PSICHO:	ora #0          ; Set flags according to contents of 
                        ;    Accumulator
	beq     PSIX1       ; don't print the final NULL 
	sta PPUDATA         ; write it out
	jmp     PSINB       ; back around
PSIX1:	inc     DPL     ; 
	bne     PSIX2       ;
	inc     DPH         ; account for page crossing
PSIX2:	jmp     (DPL)   ; return to byte following final NULL
.endproc
.macro LoadPalette Addr
    lda #0
    sta PPUMASK
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldy #0
:	lda Addr,y
	sta PPUDATA
	iny
	cpy #16
	bne :-

	ldy #0
:	lda Addr,y
	sta PPUDATA
	iny
	cpy #16
	bne :-
.endmacro
.macro LoadNametable Addr
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	lda #<Addr
	sta 0
	lda #>Addr
	sta 1
	ldx #4
	ldy #0
:	lda ($0), y
	sta PPUDATA
	iny
	bne :-
	inc 1
	dex
	bne :-
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
.endmacro
.proc rand_8    ; From some site
  lda   r_seed  ; get seed
  and   #$B8    ; mask non feedback bits
                ; for maximal length run with 8 bits we need
                ; taps at b7, b5, b4 and b3
  ldx   #$05    ; bit count (shift top 5 bits)
  ldy   #$00    ; clear feedback count
F_loop:
  asl   A       ; shift bit into carry
  bcc   bit_clr ; branch if bit = 0

  iny           ; increment feedback count (b0 is XOR all the	
                ; shifted bits from A)
bit_clr:
  dex           ; decrement count
  bne   F_loop  ; loop if not all done
no_clr:
  tya           ; copy feedback count
  lsr   A       ; bit 0 into Cb
  lda   r_seed  ; get seed back
  rol   A       ; rotate carry into byte
  sta   r_seed  ; save number as next seed
  rts           ; done
.endproc

.proc BitSelect
 .byt %00000001
 .byt %00000010
 .byt %00000100
 .byt %00001000
 .byt %00010000
 .byt %00100000
 .byt %01000000
 .byt %10000000
.endproc
.proc BitCancel
 .byt %11111110
 .byt %11111101
 .byt %11111011
 .byt %11110111
 .byt %11101111
 .byt %11011111
 .byt %10111111
 .byt %01111111
.endproc

.macro neg16 val
  sec             ;Ensure carry is set
  lda #0          ;Load constant zero
  sbc val+0       ;... subtract the least significant byte
  sta val+0       ;... and store the result
  lda #0          ;Load constant zero again
  sbc val+1       ;... subtract the most significant byte
  sta val+1       ;... and store the result
.endmacro

; added stuff
.proc SpeedAngle2Offset ; A = speed, Y = angle -> 0,1(X) 2,3(Y)
Angle = 4
Speed = 5
  sty Angle
  sta Speed

  lda CosineTable,y
  php
  bpl :+
  eor #255
  add #1
: ldy Speed
  jsr mul8
  sty 0
  sta 1

  plp
  bpl :+
  neg16 0
:

  ldy Angle
  lda SineTable,y
  php
  bpl :+
  eor #255
  add #1
: ldy Speed
  jsr mul8
  sty 2
  sta 3
  plp
  bpl :+
  neg16 2
:
  rts
.endproc
