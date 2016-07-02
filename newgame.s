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

ResetPlayerX:
  lda #3
  sta PlayerLives,x
  ldy PlayerScoreIndex,x
  lda #'0'
  sta ScoreDigits,y
  sta ScoreDigits+1,y
  sta ScoreDigits+2,y
  sta ScoreDigits+3,y
  sta ScoreDigits+4,y
ResetPlayerLifeX:
  lda #$8
  sta PlayerHeld,x
  lda #0
  sta PlayerDead,x
ResetPlayerHealthX:
  lda #4
  sta PlayerHealth,x
  lda GameDifficulty
  cmp #DIFFICULTY_HARDER
  bcc :+
    dec PlayerHealth,x
: rts

.proc NewGame
  ldx #0
  jsr ResetPlayerX
  inx
  jsr ResetPlayerX
.ifdef fourscore
  inx
  jsr ResetPlayerX
  inx
  jsr ResetPlayerX
.endif
  lda #6
  sta PlayerHead
  asl
  sta PlayerHead+1
  lda #0
  sta PlayerBody
  sta PlayerBody+1
.ifdef fourscore
  lda #7
  sta PlayerBody+2
  sta PlayerBody+3
  lda #7
  sta PlayerHead+2
  lda #4
  sta PlayerHead+3
.endif
;  jmp NewLevel
.endproc
.proc NewLevel
  lda JustPickedFromMenu
  bne :+
  lda IsScoreMode
  jne VersusScoreWinScreen

  lda LevelNumber
  cmp #52 ;64
  jeq StartMainMenu
:
  ; hack to make game reset after beating a level with the demo
  lda AttractMode
  beq :+
  lda LevelNumber
  cmp #3
  jeq reset
:

  jsr init_sound
  jsr ClearStatusRows
  jsr ClearOAM

  ldx #0 ; clear the entire page
  txa    ; nothing is persistent from level to level here and some needs clearing
: sta $600,x
  inx
  bne :-
  sta TileCycleIndex

  ldx #0
InitPlayerLoop:
  lda #0
  sta PlayerVYH,x
  sta PlayerVYL,x
  sta PlayerJumpCancelLock,x
  sta PlayerPYL,x
  sta PlayerVYH,x
  sta PlayerVYL,x
  sta PlayerInvincible,x
  sta PlayerTeleportCooldown,x
  sta PlayerPowerType,x
  sta PlayerPowerTime,x
  lda #4
  ldy GameDifficulty
  cpy #DIFFICULTY_HARDER
  bcc NormalHealth
     lda #3
NormalHealth:
  sta PlayerHealth,x
  inx
  cpx #MaxNumPlayers
  bne InitPlayerLoop

  lda #0
  sta BothDeadTimer
  sta IsMappedLevel
  sta ScreenEnemiesCount
  sta LevelWon
  sta Timer60
  sta PlayerDir
.ifdef fourscore
  sta PlayerDir+2
.endif
  sta JustPickedFromMenu
  sta ScrollX
  sta ScrollX+1
  sta NoLevelCycle

  tax
: sta ObjectPYH,x
  sta ObjectPYL,x
  sta ObjectVYH,x
  sta ObjectVYL,x
  sta ObjectTimer,x
  sta ObjectF1,x
  sta ObjectF2,x
  sta ObjectF3,x
  inx
  cpx #ObjectLen
  bne :-

  tax
: sta BulletF,x
  inx
  cpx #BulletLen
  bne :-

  tax
: sta ExplosionSize,x
  inx
  cpx #MaxExplosions
  bne :-

  tax
: sta DelayedMetaEditTime,x
  sta DelayedMetaEditType,x
  inx
  cpx #MaxDelayedMetaEdits
  bne :-
  tax
: sta AttribMap,x
  inx
  cpx #64
  bne :-

;  lda ScrollGameMode
  lda #0
  sta ScrollMode

  lda #32
  sta PlayerPX+1
  lda #32+8
  sta PlayerPX
  lda #240-32
  sta PlayerPYH
  sta PlayerPYH+1
.ifdef fourscore
  sta PlayerPYH+2
  sta PlayerPYH+3
  lda #32+2
  sta PlayerPX+2
  lda #32+6
  sta PlayerPX+3
.endif

  lda #1
  sta PlayerDir+1
.ifdef fouscore
  sta PlayerDir+3
.endif

  lda #0
  sta PPUMASK

  lda LevelNumber
  jsr LoadLevelParams

  jsr GenerateLevel

  lda LevelEditMode
  ora IsMappedLevel
  beq :+
    lda LevelEditStartX
    asl
    asl
    asl
    asl
    sta PlayerPX+1
    add #8
    sta PlayerPX
.ifdef fourscore
    sub #4
    sta PlayerPX+2
    add #2
    sta PlayerPX+3
.endif
    lda LevelEditStartY
    asl
    asl
    asl
    asl
    sta PlayerPYH
    sta PlayerPYH+1
.ifdef fourscore
    sta PlayerPYH+2
    sta PlayerPYH+3
.endif
  :

  jsr wait_vblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  inc LevelNumber

; count coins that need to be collected
  lda LevelGoalType
  cmp #3
  bne NotCollect
  ldx #0
  stx LevelGoalParam
: lda LevelBuf,x
  cmp #METATILE_MONEY
  bne :+
    inc LevelGoalParam
: inx
  bne :--
NotCollect:

  lda PlayerPX
  sta PlayerStartPX
  lda PlayerPYH
  sta PlayerStartPY

; init moving platforms
  ldy #0
: lda LevelBuf,y
  cmp #METATILE_HMOVING_PLAT
  bcc NotMoving
  cmp #METATILE_VMOVING_HARM+1
  bcs NotMoving
    pha
    jsr FindFreeObjectX
    pla
    bcc NotMoving
    sub #METATILE_HMOVING_PLAT
    add #EXTOBJ_HPLAT
    sta ObjectF3,x

    tya
    and #$0f
    asl
    asl
    asl
    asl
    sta ObjectPX,x
    tya
    and #$f0
    sta ObjectPYH,x

    lda #OBJECT_BOMB*2
    sta ObjectF1,x
NotMoving:
  iny
  cpy #240
  bne :-

; ready to go
  jsr init_sound
  lda #0
  jsr init_music

  jmp MainLoop
.endproc
