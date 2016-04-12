StartAttract:
  lda #69
  sta r_seed
  sta random1+0
  sta random1+1
  sta random2+0
  sta random2+1

  lda #0
  sta LevelNumber
  sta PlayerEnabled+1
  lda #1
  sta PlayerEnabled
  sta AttractMode
  sta JustPickedFromMenu
  jmp NewGame
