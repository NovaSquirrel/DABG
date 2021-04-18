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

.proc ClearOAM
  lda #<-16
  ldx #0
: sta OAM_YPOS,x
  inx
  inx
  inx
  inx
  bne :-
  rts
.endproc

;http://codebase64.org/doku.php?id=base:two_very_fast_16bit_pseudo_random_generators_as_lfsr
.proc huge_rand
  jsr rand64k       ;Factors of 65535: 3 5 17 257
  jsr rand32k       ;Factors of 32767: 7 31 151 are independent and can be combined
;  lda random1+1        ;can be left out 
;  eor random2+1        ;if you dont use
;  tay                  ;y as suggested
  lda random1           ;mix up lowbytes of random1
  eor random2           ;and random2 to combine both 
  rts
.endproc
 
;periode with 65535
;10+12+13+15
.proc rand64k
  lda random1+1
  asl
  asl
  eor random1+1
  asl
  eor random1+1
  asl
  asl
  eor random1+1
  asl
  rol random1         ;shift this left, "random" bit comes from low
  rol random1+1
  rts
.endproc
 
;periode with 32767
;13+14
.proc rand32k
  lda random2+1
  asl
  eor random2+1
  asl
  asl
  ror random2         ;shift this right, random bit comes from high - nicer when eor with random1
  rol random2+1
  rts
.endproc

.if 0
.proc CopyFromCHR ; A: <address, X: >address - outputs to $500
  stx PPUADDR
  sta PPUADDR
  lda PPUDATA ; dummy read

  ldy #0      ; prepare destination address (always $500)
  sty 0
  lda #5
  sta 1

  ldx PPUDATA ; read size low
  lda PPUDATA ; read size high
  sta 2
  inc 2

Loop:
  lda PPUDATA
  sta (0),y
  iny
  bne :+      ; fix destination address if we roll over
    inc 1
  :
  dex
  cpx #-1     ; fix size if we roll over
  bne :+
    lda 2
    beq Exit
    dec 2
    bmi Exit
  :
  bne Loop
Exit:
  rts
.endproc
.endif
