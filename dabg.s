; Double Action Blaster Guys
;
; Copyright 2012-2014 NovaSquirrel
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;
;playchoice = 1 ; if set, do some changes for Four Score
fourscore = 1   ; if 1, enable four player mode

;.setcpu "6502X"
.include "ns_nes.s" ; handy macros and defines
.include "common.s" ; handy routines
.include "memory.s"
.include "main.s"
.include "player.s"
.include "newgame.s"
.include "meta.s"
.include "bullets.s"
.include "object.s"
.include "screens.s"
.include "levels.s"
.include "misc.s"
.include "unpkb.s"
.include "edit.s"
.include "explosion.s"
.include "powerups.s"
.include "math.s"
.include "unpb53.s"
.include "attract.s"

.include "musicseq.h"
.include "sound.s"
.include "music.s"
.include "musicseq.s"

.segment "INESHDR"
  .byt "NES", $1A
  .byt 2     ; PRG in 16kb units
  .byt 0     ; CHR in 8kb units
  .byt 1     ; vertical mirroring
  .byt %1000 ; NES 2.0
  .byt 0     ; extra mapper bits
  .byt 0     ; extra PRG/CHR bits
  .byt $00   ; no PRG RAM
  .byt $07   ; 8 kb of CHR RAM
  .byt 0     ; NTSC (PAL works but no speed adjustments are made)
  .byt 0     ; regular PPU

.segment "VECTORS"
VectorAddrs:
  .addr nmi, reset, irq
.segment "CODE"

.proc reset
  lda #0		; Turn off PPU
  sta PPUCTRL
  sta PPUMASK
  sei
  ldx #$FF	; Set up stack pointer
  txs		; Wait for PPU to stabilize

: lda PPUSTATUS
  bpl :-
: lda PPUSTATUS
  bpl :-

  lda #0
  sta SND_CHN

; write a palette
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR

  ldx #0
: lda #$31
  sta PPUDATA
  lda #$0f
  sta PPUDATA
  lda MainColors,x
  sta PPUDATA
  lda #$30
  sta PPUDATA
  inx
  cpx #8
  bne :-
  ; put brown in the green palette
  lda #$3f
  sta PPUADDR
  lda #$07
  sta PPUADDR
  lda #$17
  sta PPUDATA

  jsr DecompressCHR

  ldx #0
  txa
: sta $000,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne :-

  .ifdef fourscore
  ldx #1
  stx JOY1
  dex
  stx JOY1
  jsr ReadJoyOnce
  jsr ReadJoyOnce
  jsr ReadJoyOnce
  lda keydown+2
  cmp #$10
  bne NotFourScore
    lda keydown+3
    cmp #$20
    bne NotFourScore
      inc FourScorePluggedIn
NotFourScore:
  .endif

  lda #$21
  sta FlashColor

  ; init randomizer
  lda #$69
  sta r_seed
  lda #$5a
  sta random1+0
  lda #$a5
  sta random1+1
  lda #$53
  sta random2+0
  lda #$76
  sta random2+1

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL

  jmp StartMainMenu
.endproc


.proc DecompressCHR
  DecCount = 15
  Ignore = 14
; write graphics
  lda #64 ;8192/128
  sta DecCount

  lda #0
  sta PPUADDR
  sta PPUADDR
  lda #<CHR
  sta ciSrc+0
  lda #>CHR
  sta ciSrc+1
  lda #0
  sta ciBufStart
  lda #128
  sta ciBufEnd
DecLoop:
  jsr unpb53_some
  ldx #0
: lda PB53_outbuf,x
  sta PPUDATA
  inx
  cpx #128
  bne :-
  dec DecCount
  bne DecLoop
  rts
.endproc

.proc nmi
  pha
  inc retraces
  lda #0
  sta OAMADDR
  sta OamPtr
  lda #2
  sta OAM_DMA

  lda EnableNMIDraw
  bne :+
    pla
    rti
: dec EnableNMIDraw

  lda #$3f
  sta PPUADDR
  lda #$1e
  sta PPUADDR
  lda FlashColor
  sta PPUDATA
  lda retraces
  and #1
  beq :+
  lda FlashColor
  add #1
  sta FlashColor
  cmp #$2c
  bne :+
    lda #$21
    sta FlashColor
  :

 .repeat 5, I ; change if the max number of tile changes per frame is changed
    lda TileUpdateA1+I
    beq :+
      sta PPUADDR
      ldx TileUpdateA2+I
      stx PPUADDR
      ldy TileUpdateT+I
      sty PPUDATA

      ora #4
      sta PPUADDR
      stx PPUADDR
      sty PPUDATA

      lda #0
      sta TileUpdateA1+I
    :
 .endrep
 .repeat 4, I ; change if the max number of metatile changes per frame is changed
    lda BlockUpdateA1+I
    beq :+
      sta PPUADDR
      ldx BlockUpdateA2+I
      stx PPUADDR
      ldy BlockUpdateT1+I
      sty PPUDATA
      ldy BlockUpdateT2+I
      sty PPUDATA
      ora #4
      sta PPUADDR
      stx PPUADDR
      lda BlockUpdateT1+I
      sta PPUDATA
      sty PPUDATA

      lda BlockUpdateB1+I
      sta PPUADDR
      ldx BlockUpdateB2+I
      stx PPUADDR
      ldy BlockUpdateT3+I
      sty PPUDATA
      ldy BlockUpdateT4+I
      sty PPUDATA
      ora #4
      sta PPUADDR
      stx PPUADDR
      lda BlockUpdateT3+I
      sta PPUDATA
      sty PPUDATA

      lda #0
      sta BlockUpdateA1+I
    :
  .endrep

  lda ScrollMode
  jne NoDraw
  lda FourScorePluggedIn
  jne NoDraw
.if 0
  beq :+
;    lda ScrollGameMode
;    jeq NoDraw
    lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
    sta PPUCTRL
    lda Update28Address+0
    sta PPUADDR
    lda Update28Address+1
    sta PPUADDR
    jsr Draw28
    jmp NoDraw
  :
.endif
  PositionXY 0, 2,2
  jsr Draw28

  PositionXY 0, 2,3
  .repeat 11, I
    lda StatusRow2 + I
    sta PPUDATA
  .endrep

NoDraw:
  bit PPUSTATUS
  lda ScrollX+1
  sta PPUSCROLL
  lda #0
  sta PPUSCROLL

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL
  pla
  rti

Draw28:
  .repeat 28, I
    lda StatusRow1 + I
    sta PPUDATA
  .endrep
  rts
.endproc

.proc ClearStatusRows
  lda #' '
  ldx #0
: sta StatusRow1,x
  inx
  cpx #28
  bne :-
  ldx #0
: sta StatusRow2,x
  inx
  cpx #12
  bne :-
  rts
.endproc

.proc MainColors
  .byt $16, $29, $03, $28
  .byt $01, $16, $27, $21
.endproc
.proc BackgroundColors
  .byt $31, $36, $38, $23
.endproc

CHR:
.incbin "ascii.pb53"

.proc irq
	rti
.endproc
