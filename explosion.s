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

; todo: fix explosions
.proc RunExplosions
  ldx #0
Loop:
  lda ExplosionSize,x
  jeq NoExplosion
  sta 0
  lsr
  sta 1

  ldy OamPtr
  lda retraces
  and #1
  beq NotCorners
  lda ExplosionPosY,x
  sta OAM_YPOS+(4*0),y
  lda #3
  sta OAM_ATTR+(4*0),y
  lda #$60
  sta OAM_TILE+(4*0),y
  lda ExplosionPosX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y

  lda ExplosionPosY,x
  add 0
  sta OAM_YPOS+(4*1),y
  lda #3
  sta OAM_ATTR+(4*1),y
  lda #$60
  sta OAM_TILE+(4*1),y
  lda ExplosionPosX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*1),y

  lda ExplosionPosY,x
  sta OAM_YPOS+(4*2),y
  lda #3
  sta OAM_ATTR+(4*2),y
  lda #$60
  sta OAM_TILE+(4*2),y
  lda ExplosionPosX,x
  add 0
  sub ScrollX+1
  sta OAM_XPOS+(4*2),y

  lda ExplosionPosY,x
  add 0
  sta OAM_YPOS+(4*3),y
  lda #3
  sta OAM_ATTR+(4*3),y
  lda #$60
  sta OAM_TILE+(4*3),y
  lda ExplosionPosX,x
  add 0
  sub ScrollX+1
  sta OAM_XPOS+(4*3),y
  jmp NotSides
NotCorners:
  lda ExplosionPosY,x
  add 1
  sta OAM_YPOS+(4*0),y
  lda #3
  sta OAM_ATTR+(4*0),y
  lda #$60
  sta OAM_TILE+(4*0),y
  lda ExplosionPosX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y

  lda ExplosionPosY,x
  sta OAM_YPOS+(4*1),y
  lda #3
  sta OAM_ATTR+(4*1),y
  lda #$60
  sta OAM_TILE+(4*1),y
  lda ExplosionPosX,x
  add 1
  sub ScrollX+1
  sta OAM_XPOS+(4*1),y

  lda ExplosionPosY,x
  add 1
  sta OAM_YPOS+(4*2),y
  lda #3
  sta OAM_ATTR+(4*2),y
  lda #$60
  sta OAM_TILE+(4*2),y
  lda ExplosionPosX,x
  add 0
  sub ScrollX+1
  sta OAM_XPOS+(4*2),y

  lda ExplosionPosY,x
  add 0
  sta OAM_YPOS+(4*3),y
  lda #3
  sta OAM_ATTR+(4*3),y
  lda #$60
  sta OAM_TILE+(4*3),y
  lda ExplosionPosX,x
  add 1
  sub ScrollX+1
  sta OAM_XPOS+(4*3),y
NotSides:

  tya
  add #32
  tay
  sty OamPtr

  jsr ExplosionPlayerTouch

  inc ExplosionSize,x
  inc ExplosionSize,x
  dec ExplosionPosX,x
  dec ExplosionPosY,x

  dec ExplosionTime,x
  lda ExplosionTime,x
  bne :+
    lda #0
    sta ExplosionSize,x
  :

NoExplosion:
  inx
  cpx #MaxExplosions
  jne Loop
  rts
.endproc

.proc FindFreeExplosion ; puts index in Y
  pha
  ldy #0
Loop:
  lda ExplosionSize,y
  beq Found
  iny
  cpy #MaxExplosions
  bne Loop
  pla
  clc
  rts
Found:
  pla
  sec
  rts
.endproc

.proc CreateExplosion ; A = size, 0,1 = X,Y
  jsr FindFreeExplosion
  bcc :+
  sta ExplosionTime,y
  lda 0
  sta ExplosionPosX,y
  lda 1
  sta ExplosionPosY,y
  lda #1
  sta ExplosionSize,y
  lda #SOUND_EXPLODE1
  jsr start_sound
  lda #SOUND_EXPLODE2
  jsr start_sound
: rts
.endproc

.proc ExplosionPlayerTouch
  ldy #0
PlayerLoop:
  lda PlayerPX,y
  sta TouchLeftA
  lda PlayerPYH,y
  sta TouchTopA

  lda ExplosionPosX,x
  sta TouchLeftB
  lda ExplosionPosY,x
  sta TouchTopB

  lda #8
  sta TouchWidthA
  asl
  sta TouchHeightA
  lda ExplosionSize,x
  sta TouchWidthB
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcc NotTouched
  jsr PlayerHurt
NotTouched:
  iny
  cpy #MaxNumPlayers
  bne PlayerLoop
  rts
.endproc
