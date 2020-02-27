; ***  A S T E R O I D S ***
; Copyright 1979 Atari
; Designer: Brad Stewart

; Analyzed, labeled and commented
;  by Thomas Jentzsch (JTZ)
; Last Update: 05.08.2003 (v0.5)

; Modified for PlusROM functions
;  by Wolfgang Stubig (Al_Nafuur)
; Last Update: 29.12.2019 (v0.1.0)
;  Bugfixes by Thomas Jentzsch (JTZ)
; Last Update: 25.02.2020 (v0.1.1)

; PAL conversion notes:
; The conversion is only minimal, but (unlike Activision) Atari at least
; adjusted the screenheight. Except for the asteroids trajectories the game
; speed is completely unadjusted. When converting the copyrighted version to
; PAL again they "forgot" to adjust a few parameters. The colors for the
; flickering objects in NTSC are much brighter than for PAL

; Misc:
; - After disassmbling great games and codes like Pitfall! this code doesn't
;   look too good. It wastes a lot of ROM (e.g. the two HMOVE tables, the over-
;   complex collision detection and, last not least, the extremely ineffective
;   repositioning routines right at the start of the code) and the RAM is
;   sometimes also used not very effective. E.g. the asteroids list: it has
;   space for 8 asteroids (one wrapped at the horizontal screen borders) but it
;   wastes one whole slot (all three lists!) just to store a marker for the end
;   of the list. That is 6 bytes wasted for just two (unnecessary) markers!
;   With a little bit more clever coding the code (without copyright) might
;   have fitted into 4K.
; - The number of asteroids depends on the score:
;   <1,000 points -> 4, <15,000 points -> 6, >=15,000 point -> 8
; - As stated above, the game only supports 2x7 asteroids. So if you destroy
;   all four large asteroids moving in one y-direction, the last one only
;   creates one single medium sized one.
; - The collision routines are not only complex but also not very reliable.
;   The collisions aren't checked every frame (up to every 12th!).
; - There are two kernels, which are displayed alternating (asteroids, other
;   objects). Therefore everything - except for the score display - flickers at
;   30/25Hz.
; - Originally it was planned to display the remaining ships instead of a
;   simple number! The whole source code is still there and can be easily
;   reenabled again. Because the color of the displayed ships was not converted
;   I am sure disabling this code was done before converting the game to PAL.
; - Though the manual says that UFOs start at 7,500 points they actually start
;   at 7,000 points.
; - The version without the copyright notice is no hack. The notice was added
;   later, causing a lot of code to be moved at a slightly different address.
; - Maybe the children modes where added later or game #33 was originally
;   planned to be game #65.
; - The number of random x-positions after hyperspace is limited to only a few
;   values



    processor 6502
    include vcs.h


;===============================================================================
; A S S E M B L E R - S W I T C H E S
;===============================================================================

ORIGINAL        = 1             ; original or DC version
NTSC            = 0             ; compiling for NTSC or PAL mode
COPYRIGHT       = 1             ; compiling version with copyright screen
FAST_COPYRIGHT  = 1
GARBAGE         = 0             ; unused code in copyrighted version has garbage
                                ; (slightly different in PAL version)
SADISTROIDS     = 0             ; enable for ultra fast asteroids

PLUSROM         = 1             ; PlusROM functions for high score saving


;===============================================================================
; 2600 - C O N S T A N T S
;===============================================================================

; value REFPx:
REFLECT             = %1000

; values for NUSIZx:
ONE_COPY            = %000
TWO_COPIES          = %001
TWO_COPIES_WIDE     = %010
THREE_COPIES        = %011
DOUBLE_SIZE         = %101
THREE_COPIES_MED    = %110
QUAD_SIZE           = %111
MS_SIZE1            = %000000
MS_SIZE2            = %010000
MS_SIZE4            = %100000
MS_SIZE8            = %110000

; values for bankswitching:
BANK0               = $fff8
BANK1               = $fff9

; color values:
BLACK           = $00
WHITE           = $0e
  IF NTSC
YELLOW          = $10
BROWN           = $20
RED             = $40
MAGENTA         = $50
BLUE1           = $70
BLUE2           = $90
CYAN            = $a0
GREEN2          = $d0
OCHRE_GREEN     = $e0
  ELSE
BROWN           = $40
RED             = $60
MAGENTA         = $80
MAGENTA2        = $a0
BLUE1           = $b0
BLUE2           = $d0
CYAN            = $90
GREEN2          = $30+2
OCHRE_GREEN     = $20
  ENDIF


;===============================================================================
; G A M E - C O N S T A N T S
;===============================================================================

 IF SADISTROIDS = 0
  IF NTSC
SPEED_SLOW      = $70   ; horizontal delay of slow asteroids (1/7)
SPEED_MEDIUM    = $03   ; horizontal delay of medium asteroids (1/3)
                        ; fast ones move always
  ELSE
SPEED_SLOW      = $50   ; 1/5
SPEED_MEDIUM    = $02   ; 1/2
  ENDIF
 ELSE
SPEED_SLOW      = $30   ; 1/3
SPEED_MEDIUM    = $02   ; 1/2
 ENDIF

  IF NTSC
H_KERNEL        = 89
  ELSE
H_KERNEL        = 107
  ENDIF

PLAYER1_COL     = RED+4
PLAYER2_COL     = GREEN2+6
  IF NTSC
; for NTSC they choose brighter colors for the
; flickering objects, which makes sense
SHIP1_COL       = PLAYER1_COL+8
SHIP2_COL       = PLAYER2_COL+6
SATTELITE_COL   = BLUE2+$c
UFO_COL         = OCHRE_GREEN+$c
  ELSE
; but why didn't they for PAL too?
SHIP1_COL       = PLAYER1_COL
SHIP2_COL       = PLAYER2_COL
SATTELITE_COL   = BLUE2+$2
UFO_COL         = SHIP2_COL         ; !!!
  ENDIF

ID_SHIP         = 4
ID_UFO          = 5
ID_SATTELITE    = 6
ID_SHOT1        = 7
ID_SHOT2        = 8
ID_SHOT_UFO     = 9

;flagLst constants:
MEDIUM_SIZE     = $20
SMALL_SIZE      = $30
HIT_FLAG        = $40
FAST_SPEED      = $80       ; fast speed
SIZE_BITS       = MEDIUM_SIZE|SMALL_SIZE
TYPE_BITS       = SIZE_BITS|HIT_FLAG

;flags constants:
UFO_LEFT        = %00000001
UFO_DIR_FLAGS   = %00000110
COLLISION_FLAG  = %00001000
FIRE_FLAG       = %00010000
UFO_FLAG        = %00100000
SELECT_FLAG     = %01000000
PLAYER2_FLAG    = %10000000

;flags2 constants:
GAME_OVER       = %00000001
KILL_FLAG       = %00000010
HYPERSPACE_FLAG = %00000100
SHIELD_FLAG     = %01000000
FLIP_FLAG       = %10000000

;game constants:
BONUS_BITS      = %110
FEATURE_BITS    = %11000
TWO_PLAYERS     = $20

;soundBits constants:
SOUND_KILL      = $01
SOUND_THRUST    = $02

SOUND_UFO       = $08
SOUND_ENEMY     = $10

;lifesDir constants:
DIR_MASK        = %1111
LIFES_MASK      = %11110000


NUM_ASTEROIDS_2 = 9         ; size for 9 asteroids in up and down list each,
                            ;  but only 7 are allowed (one is used for wrapping
                            ;  asteroids and one is wasted for marking the end
                            ;  of the list
Y_ILLEGAL       = $e0       ; marks an empty slot in asteroid list


;===============================================================================
; Z P - V A R I A B L E S
;===============================================================================

game        = $80           ;           currently selected game
randomLo    = $81
randomHi    = $82
;---------------------------------------
; all three lists are divided into two equally sized parts,
; one for up and one for down moving asteroids
yPosLst     = $83           ;..$94      $e0 means end of list
xPosLst     = $95           ;..$a6      stored as hmove/delay/LR (mmmmdddl)
flagLst     = $a7           ;..$b8      asteroids flags
;---------------------------------------
frameCnt    = $b9
frameCntHi  = $ba
gameSpeed   = $bb           ;           contains two counters, which determine
                            ;            horizontal asteroid speed
;---------------------------------------
player1     = $bc           ;..$be
lifesDir    = player1       ;           lllldddd
scoreHigh   = player1+1
scoreLow    = player1+2
player2     = $bf           ;..$c1
lifesDir2   = player2       ;           lllldddd
;---------------------------------------
asteroidHit = $c2           ;           remember that an asteroid has been hit (!=0)
;---------------------------------------
soundTimer0 = $c3
soundTimer1 = $c4
soundBits   = $c5
;---------------------------------------
ofsExpl     = $c6
flags       = $c7           ;
flags2      = $c8
;---------------------------------------
xShip       = $c9           ;           stored as HMove/Delay
yShip       = $ca
;---------------------------------------
speedLst    = $cb           ;..$d0
speedHiLst  = speedLst
speedHiX    = speedHiLst
speedHiY    = speedHiLst+1
speedMidLst = speedLst+2
speedMidX   = speedMidLst
speedMidY   = speedMidLst+1
speedLoLst  = speedLst+4
speedLoX    = speedLoLst
speedLoY    = speedLoLst+1
;---------------------------------------
xUFO        = $d1
yUFO        = $d2
;---------------------------------------
xShotLst    = $d3           ;..$d5
xShot1      = xShotLst
xShot2      = xShotLst+1
xShotUfo    = xShotLst+2
yShotLst    = $d6           ;..$d8
yShot1      = yShotLst
yShot2      = yShotLst+1
yShotUfo    = yShotLst+2
dirShotLst  = $d9           ;..$db
dirShot1    = dirShotLst
dirShot2    = dirShotLst+1
dirShotUfo  = dirShotLst+2
;---------------------------------------
lwrBound    = $dc
uprBound    = $dd
;---------------------------------------
ftrTimer    = $de           ;           used for feature timing
yShipNew    = $df
ssColor     = $e0
cxTimer     = $e1           ;           shedules collison detections
;$e1    %UUxxxxUU
lastDir     = cxTimer       ;           using bits 3 and 4 for last direction

jmpVec1     = $e3           ; ..$e4
;---------------------------------------
; shared variables for asteroids kernel:
jmpVec2     = $e5           ; ..$e6
coarseMove0 = $e7
coarseMove1 = $e8
fineMove0   = $e9
fineMove1   = $ea
ptr1        = $eb           ; ..$ec
ptr2        = $ed           ; ..$ee
ptr3        = $ef           ; ..$f0
ptr4        = $f1           ; ..$f2
tmpVarA     = $f3
tmpVarB     = $f4

astType0    = $f8
astType1    = $f9
;-------------------
; shared variables for objects kernel:
ptrEnemy    = $e6           ; ..$e7
ballCol     = $e8           ;
shipCol     = $e9           ;
enemyCol    = $ea           ;
vDelP0Krnl  = $eb
vDelP1Krnl  = $ec           ;           vertical delay for UFO/sattelite
                            ;            (never set, always enabled!)
moveBits    = vDelP1Krnl
ptrShip     = $ed           ; ..$ee
yShipKrnl   = $ef

ptrShipHlp  = $f1
ptrEnemyHlp = $f2
tmpVar      = $f2
;---------------------------------------

bswVec      = $f7               ;           jmp vector used for bankswitching

  IF PLUSROM
WriteToBuffer     equ $1ff0
WriteSendBuffer   equ $1ff1
ReceiveBuffer     equ $1ff2
ReceiveBufferSize equ $1ff3
  ENDIF

;===============================================================================
; R O M - C O D E (Bank 0)
;===============================================================================

    ORG $d000
  IF PLUSROM
    .byte "api.php", #0
    .byte "highscore.firmaplus.de", #0
  ENDIF

Ld000:
    jmp    START1           ; 3

EndXPosP1:
    sta    WSYNC            ; 3
EndXPosP1a:
    sta    HMOVE            ; 3
    sta    GRP1             ; 3
    stx    NUSIZ1           ; 3
    jmp    (jmpVec1)        ; 5     XPosP0_r/l

; the positioning routines are really "using" a *lot* of ROM!
XPosP0_r SUBROUTINE         ;       @14
    nop                     ; 2
    php                     ; 3
    plp                     ; 4
    nop                     ; 2
    nop                     ; 2
    lda    fineMove0        ; 3
    sta    HMCLR            ; 3
    sta    HMP0             ; 3     @36
    lda    #<Ld083          ; 2
    sta    jmpVec1          ; 3
    ldx    coarseMove0      ; 3
    lda    #$00             ; 2
    dex                     ; 2
    bne    .xPos1_r         ; 2³
    sta    RESP0            ; 3     @53
.contXPos_r:
    jmp    EndXPosP0        ; 3

.xPos1_r:
    dex                     ; 2
    bne    .xPos2_r         ; 2³
    sta    RESP0            ; 3     @58
    beq    .contXPos_r      ; 3

.xPos2_r:
    dex                     ; 2
    bne    .xPos3_r         ; 2³
    sta    RESP0            ; 3     @63
    beq    .contXPos_r      ; 3

.xPos3_r:
    dex                     ; 2
    bne    .xPos4_r         ; 2³
    sta    RESP0            ; 3     @68
    jmp    EndXPosP0        ; 3

.xPos4_r:
    dex                     ; 2
    nop                     ; 2
    sta    RESP0            ; 3     @73 <- is this the reason why the made
                            ;            they made the code so huge?
    jmp    EndXPosP0a       ; 3


XPosP0_l SUBROUTINE         ;       @14
; making this routine sooo huge makes no sense...
    ldx    coarseMove0      ; 3
    dex                     ; 2
    bne    .xPos1_l         ; 2³
    sta    RESP0            ; 3     @22
    nop                     ; 2
    beq    .contXPos0       ; 3

.xPos1_l:
    dex                     ; 2
    bne    .xPos2_l         ; 2³
    sta    RESP0            ; 3     @27
.contXPos0:
    nop                     ; 2
    beq    .contXPos1       ; 3

.xPos2_l:
    dex                     ; 2
    bne    .xPos3_l         ; 2³
    sta    RESP0            ; 3     @32
.contXPos1:
    nop                     ; 2
    beq    .contXPos2       ; 3

.xPos3_l:
    dex                     ; 2
    bne    .xPos4_l         ; 2³
    sta    RESP0            ; 3     @37
.contXPos2:
    nop                     ; 2
    beq    .contXPos3       ; 3

.xPos4_l:
    dex                     ; 2
    bne    .xPos5_l         ; 2³
    sta    RESP0            ; 3     @42
.contXPos3:
    nop                     ; 2
    beq    .contXPos4       ; 3

.xPos5_l:
    dex                     ; 2
    nop                     ; 2
    sta    RESP0            ; 3     @47
.contXPos4:
    sta    HMCLR            ; 3
    lda    fineMove0        ; 3
    sta    HMP0             ; 3     @55
    lda    #<Ld083          ; 2
    sta    jmpVec1          ; 3
    lda    #$00             ; 2
    jmp    EndXPosP0        ; 3

Ld083 SUBROUTINE
    ldx    #0               ; 2
    lda    (ptr3,x)         ; 6         HMSizeTbl,x
    bne    .contAsteroid    ; 2³
; next asteroid:
    inc    lwrBound         ; 5
    ldx    lwrBound         ; 3
    lda    xPosLst,x        ; 4
    sta    HMCLR            ; 3
    sta    fineMove0        ; 3
    lsr                     ; 2
    and    #$07             ; 2
    sta    coarseMove0      ; 3
    lda    #<Ld0c0          ; 2
    sta    jmpVec1          ; 3
    lda    #$00             ; 2
    tax                     ; 2
    jmp    EndXPosP0        ; 3

.contAsteroid:
    sta    HMCLR            ; 3
    sta    HMP0             ; 3
    sta    tmpVarA          ; 3
    ldx    astType0         ; 3
    lda    ColTbl,x         ; 4
    sta    COLUP0           ; 3
    ldx    #0               ; 2
    lda    (ptr1,x)         ; 6         Asteroids,x
    inc    ptr1             ; 5
    inc    ptr3             ; 5
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    ldx    tmpVarA          ; 3
    nop                     ; 2
    jmp    EndXPosP0a       ; 3

Ld0c0:
    ldx    lwrBound         ; 3
    lda    flagLst,x        ; 4
    and    #TYPE_BITS       ; 2
    sta    ptr1             ; 3
    sta    ptr3             ; 3
    sta    HMCLR            ; 3
    lda    flagLst,x        ; 4
    and    #$07             ; 2
    sta    astType0         ; 3
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    tya                     ; 2
    cmp    yPosLst,x        ; 4
    bne    .contWait        ; 2³
    lda    fineMove0        ; 3
    ror                     ; 2
    ldx    #<XPosP0_l       ; 2
    bcs    .moveLeft        ; 2³
    ldx    #<XPosP0_r       ; 2
    stx    jmpVec1          ; 3
    lda    #$00             ; 2
    tax                     ; 2
    jmp    EndXPosP0a       ; 3

.moveLeft:
    stx.w  jmpVec1          ; 4
    lda    #$00             ; 2
    tax                     ; 2
    jmp    EndXPosP0a       ; 3

.contWait:                  ;           continue waiting for next asteroid
    lda    #$00             ; 2
    tax                     ; 2
    jmp    EndXPosP0        ; 3

exitKernelW1:
    jmp    ExitKernelW      ; 3

  IF PLUSROM = 0
    align 256, 0            ;           3 unused bytes
  ENDIF

EndXPosP0 SUBROUTINE
    sta    WSYNC            ; 3
EndXPosP0a:
    sta    HMOVE            ; 3
    sta    GRP0             ; 3
    stx    NUSIZ0           ; 3
    jmp    (jmpVec2)        ; 5

XPosP1_r:
    iny                     ; 2
    php                     ; 3
    plp                     ; 4
    cpy    #H_KERNEL        ; 2
    beq    exitKernelW1     ; 2³+1
    lda    enemyCol         ; 3
    sta    HMCLR            ; 3
    sta    HMP1             ; 3
    lda    #<Ld188          ; 2
    sta    jmpVec2          ; 3
    ldx    coarseMove1      ; 3
    lda    #$00             ; 2
    dex                     ; 2
    bne    .xPos1_r         ; 2³
    sta    RESP1            ; 3
.contXPos_r:
    jmp    EndXPosP1        ; 3

.xPos1_r:
    dex                     ; 2
    bne    .xPos2_r         ; 2³
    sta    RESP1            ; 3
    beq    .contXPos_r      ; 2³
.xPos2_r:
    dex                     ; 2
    bne    .xPos3_r         ; 2³
    sta    RESP1            ; 3
    beq    .contXPos_r      ; 2³
.xPos3_r:
    dex                     ; 2
    bne    .xPos4_r         ; 2³
    sta    RESP1            ; 3
    jmp    EndXPosP1        ; 3

.xPos4_r:
    dex                     ; 2
    nop                     ; 2
    sta    RESP1            ; 3
    jmp    EndXPosP1a       ; 3


XPosP1_l SUBROUTINE
    ldx    coarseMove1      ; 3
    dex                     ; 2
    bne    .xPos1_r         ; 2³
    sta    RESP1            ; 3
    nop                     ; 2
    beq    .contXPos0       ; 3

.xPos1_r:
    dex                     ; 2
    bne    .xPos2_r         ; 2³
    sta    RESP1            ; 3
.contXPos0:
    nop                     ; 2
    beq    .contXPos1       ; 3

.xPos2_r:
    dex                     ; 2
    bne    .xPos3_r         ; 2³
    sta    RESP1            ; 3
.contXPos1:
    nop                     ; 2
    beq    .contXPos2       ; 3

.xPos3_r:
    dex                     ; 2
    bne    .xPos4_r         ; 2³
    sta    RESP1            ; 3
.contXPos2:
    nop                     ; 2
    beq    .contXPos3       ; 3

.xPos4_r:
    dex                     ; 2
    bne    .xPos5_r         ; 2³
    sta    RESP1            ; 3
.contXPos3:
    nop                     ; 2
    beq    .contXPos4       ; 3

.xPos5_r:
    dex                     ; 2
    nop                     ; 2
    sta    RESP1            ; 3
.contXPos4:
    sta    HMCLR            ; 3
    lda    fineMove1        ; 3
    sta    HMP1             ; 3
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    beq    .exitKernelW2    ; 2³
    lda    #<Ld188          ; 2
    sta    jmpVec2          ; 3
    lda    #$00             ; 2
    nop                     ; 2
    jmp    EndXPosP1a       ; 3

Ld188:
    ldx    #0               ; 2
    lda    (ptr4,x)         ; 6         HMSizeTbl,x
    bne    Ld1ac            ; 2³
    inc    uprBound         ; 5
    ldx    uprBound         ; 3
    lda    xPosLst,x        ; 4
    sta    HMCLR            ; 3
    sta    fineMove1        ; 3
    lsr                     ; 2
    and    #$07             ; 2
    sta    coarseMove1      ; 3
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    beq    .exitKernelW2    ; 2³
    lda    #<Ld1cf          ; 2
    sta    jmpVec2          ; 3
    lda    #$00             ; 2
    tax                     ; 2
    jmp    EndXPosP1        ; 3

Ld1ac:
    sta    HMCLR            ; 3
    sta    HMP1             ; 3         huh?
    sta    tmpVarA          ; 3
    ldx    astType1         ; 3
    lda    ColTbl,x         ; 4
    sta    COLUP1           ; 3
    ldx    #0               ; 2
    lda    (ptr2,x)         ; 6         Asteroids,x
    inc    ptr2             ; 5
    inc    ptr4             ; 5
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    beq    .exitKernelW2    ; 2³
    ldx    tmpVarA          ; 3
    nop                     ; 2
    jmp    EndXPosP1a       ; 3

.exitKernelW2:
    jmp    ExitKernelW      ; 3

Ld1cf:
    ldx    uprBound         ; 3
    lda    flagLst,x        ; 4
    and    #TYPE_BITS       ; 2
    sta    ptr2             ; 3
    sta    ptr4             ; 3
    sta    HMCLR            ; 3
    lda    flagLst,x        ; 4
    and    #$07             ; 2
    sta    astType1         ; 3
    tya                     ; 2
    cmp    yPosLst,x        ; 4
    bne    .skipNext        ; 2³+1
    lda    fineMove1        ; 3
    ror                     ; 2
    ldx    #<XPosP1_l       ; 2
    bcs    .posLeft         ; 2³
    ldx    #<XPosP1_r       ; 2
    stx    jmpVec2          ; 3
    lda    #$00             ; 2
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    beq    .exitKernel2     ; 2³+1
    tax                     ; 2
    jmp    EndXPosP1a       ; 3

.exitKernel1:
    jmp    ExitKernel       ; 3

  IF PLUSROM = 0
    align  256, 0
  ENDIF

.posLeft:
  IF PLUSROM = 0
    stx    jmpVec2          ; 3
  ELSE
    stx.w  jmpVec2          ; 3
  ENDIF
    lda    #$00             ; 2
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    beq    .exitKernel1     ; 2³+1
    tax                     ; 2
    jmp    EndXPosP1a       ; 3

.skipNext:
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    beq    .exitKernelW2    ; 2³+1
    lda    #$00             ; 2
    tax                     ; 2
    jmp    EndXPosP1        ; 3

.exitKernel2:
    jmp    ExitKernel       ; 3


; ********** D R A W   S C O R E (start) **********
DrawScore SUBROUTINE
.lifesOfs   = $f3
.ptrDigits  = $f4   ; ..$f5
.scores     = $f6   ; ..$fb
.pf0_l      = $fc
.pf1_l      = $fd
.pf2_l      = $fe
.pf2_r      = $ff

    ldx    .lifesOfs        ; 3
    lda    .pf0_l           ; 3
    sta    WSYNC            ; 3
    sta    WSYNC            ; 3
.loopScore:
    sta    PF0              ; 3     @03
    lda    .pf1_l           ; 3
    sta    PF1              ; 3     @09
    lda    .pf2_l           ; 3
    sta    PF2              ; 3     @15
    lda    LifesTbl1,x      ; 4
    sta    GRP0             ; 3     @22
    lda    LifesTbl2,x      ; 4
    sta    GRP1             ; 3     @29
    dex                     ; 2
    lda    #$00             ; 2
    sta    PF0              ; 3     @36
    ldy    .scores+1        ; 3
    sta    PF1              ; 3     @42
    lda    (.ptrDigits),y   ; 5
    ldy    .pf2_r           ; 3
    sty    PF2              ; 3     @53
    ldy    .pf0_l           ; 3
    sty    PF0              ; 3     @59
    ldy    .pf1_l           ; 3
    nop                     ; 2
    sty    PF1              ; 3     @67
    ldy    .scores+2        ; 3
    ora    (.ptrDigits),y   ; 5
    sta    .pf1_l           ; 3
    lda    .pf2_l           ; 3
    sta    PF2              ; 3     @08
    ldy    .scores+3        ; 3
    lda    (.ptrDigits),y   ; 5
    ldy    .scores+4        ; 3
    ora    (.ptrDigits),y   ; 5
    sta    .pf2_l           ; 3
    ldy    .scores+5        ; 3
    lda    (.ptrDigits),y   ; 5
    ldy    .scores+5        ; 3             waste 3 cycles
    ldy    #$00             ; 2
    sty    PF0              ; 3     @43
    sty    PF1              ; 3     @46
    ldy    .pf2_r           ; 3
    sty    PF2              ; 3     @52
    sta    .pf2_r           ; 3
    ldy    .scores          ; 3
    lda    (.ptrDigits),y   ; 5
    sta    .pf0_l           ; 3
    nop                     ; 2
    dec    .ptrDigits       ; 5
    bpl    .loopScore       ; 2³

; end of score drawing:
    sta    PF0              ; 3
    lda    .pf1_l           ; 3
    sta    PF1              ; 3
    lda    .pf2_l           ; 3
    sta    PF2              ; 3
    lda    LifesTbl1,x      ; 4
    sta    GRP0             ; 3
    lda    LifesTbl2,x      ; 4
    sta    GRP1             ; 3
; ********** D R A W   S C O R E (end) **********

; prepare main kernel:
    lda    frameCnt         ; 3     even or odd frame?
    ror                     ; 2
    lda    #$00             ; 2
    sta    PF0              ; 3
    sta    PF1              ; 3
    bcs    OddKernel        ; 2³
  IF PLUSROM = 0
    bcc    EvenKernel       ; 3
  ELSE
    jmp    EvenKernel       ; 3     bcc takes 4 cycles!
  ENDIF
; ********** O D D   K E R N E L (part 2/2) **********
OddKernel:
; this kernel displays the asteroids

; *** draw last line of score display and prepare main kernel: ***
    lda    .pf2_r           ; 3
    sta    PF2              ; 3
    ldx    #NUM_ASTEROIDS_2 ; 2
    lda    flagLst,x        ; 4
    and    #$07             ; 2
    sta    astType1         ; 3
    tax                     ; 2
    lda    ColTbl,x         ; 4
    sta    $f6              ; 3
    lda    .pf0_l           ; 3
    sta    PF0              ; 3
    lda    .pf1_l           ; 3
    sta    PF1              ; 3
    lda    .pf2_l           ; 3
    sta    PF2              ; 3
    ldx    #0               ; 2
    lda    flagLst,x        ; 4
    and    #$07             ; 2
    sta    astType0         ; 3
    tax                     ; 2
    lda    ColTbl,x         ; 4
    tax                     ; 2
    lda    #$00             ; 2
    ldy    #$ff             ; 2
    sta    PF0              ; 3
    sta    PF1              ; 3
    nop                     ; 2
    lda    .pf2_r           ; 3
    sta    PF2              ; 3
    lda    #$00             ; 2
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    stx    COLUP0           ; 3
    sta    GRP0             ; 3
    sta    GRP1             ; 3
    sta    PF2              ; 3
    ldx    $f6              ; 3
    sta    HMOVE            ; 3
    stx    COLUP1           ; 3
    sta    NUSIZ1           ; 3
    jmp    (jmpVec1)        ; 5
; ********** O D D   K E R N E L (end) **********


; ********** E V E N   K E R N E L (start) **********
EvenKernel:
; this kernel displays the ship, UFO/sattelite and shots

; *** draw last line of score display and prepare main kernel: ***
    lda    .pf2_r           ; 3
    sta    PF2              ; 3
    lda    ($83,x)          ; 6
    lda    ($83,x)          ; 6
    lda    .pf0_l           ; 3
    sta    PF0              ; 3
    lda    .pf1_l           ; 3
    sta    PF1              ; 3
    lda    .pf2_l           ; 3
    sta    PF2              ; 3
    lda    ($83,x)          ; 6
    lda    ($83,x)          ; 6
    lda    ($83,x)          ; 6
    lda    ($83,x)          ; 6
    lda    ($83,x)          ; 6
    ldx    #ENABL           ; 2
    txs                     ; 2
    lda    #$00             ; 2
    sta    PF0              ; 3
    sta    PF1              ; 3
    lda    .pf2_r           ; 3
    sta    PF2              ; 3
    lda    #$00             ; 2
    tay                     ; 2
    ldx    ballCol          ; 3         this is always identical to the ship color!
    sta    GRP0             ; 3
    sta    GRP1             ; 3
    sta    GRP0             ; 3
    sta    PF2              ; 3
    stx    COLUPF           ; 3
;---------------------------------------
    sta    HMOVE            ; 3     @03

; *** x-position ship: ***
    lda    xShip            ; 3
    ror                     ; 2         ship on left or right part of the screen?
    and    #$07             ; 2
    tax                     ; 2
    bcs    .xPosShip_l      ; 2³        left!
    lda    shipCol          ; 3
    sta    COLUP0           ; 3     @20
    lda    vDelP0Krnl       ; 3
    sta    VDELP0           ; 3
    sta    REFP0            ; 3     @29
    lda    xShip            ; 3
    sta    HMP0             ; 3     @35
    lda    #$00             ; 2
    sta    NUSIZ0           ; 3     @40
    lda    ($83,x)          ; 6         waste 6 cycles
    dex                     ; 2
    bne    .xPosShip1_r     ; 2³
    sta    RESP0            ; 3     @53
    beq    .moveShipW       ; 3

.xPosShip1_r:
    dex                     ; 2
    bne    .xPosShip2_r     ; 2³
    sta    RESP0            ; 3     @58
    beq    .moveShipW       ; 3

.xPosShip2_r:
    dex                     ; 2
    bne    .xPosShip3_r     ; 2³
    sta    RESP0            ; 3     @63
    beq    .moveShipW       ; 2³
.xPosShip3_r:
    dex                     ; 2
    bne    .xPosShip4_r     ; 2³
    sta    RESP0            ; 3     @68
    beq    .moveShipW       ; 3

.xPosShip4_r:
    dex                     ; 2
    nop                     ; 2
    sta    RESP0            ; 3     @73
    beq    .moveShip        ; 3

.xPosShip_l:
    nop                     ; 2
.waitShip:
    dex                     ; 2
    bne    .waitShip        ; 2³
    sta    RESP0            ; 3
    lda    xShip            ; 3
    sta    HMP0             ; 3
    lda    shipCol          ; 3
    sta    COLUP0           ; 3
    lda    vDelP0Krnl       ; 3
    sta    VDELP0           ; 3
    sta    REFP0            ; 3
    stx    NUSIZ0           ; 3
.moveShipW:
    sta    WSYNC            ; 3
;---------------------------------------
.moveShip:
    sta    HMOVE            ; 3

; *** x-position UFO: ***
    lda    xUFO             ; 3
    ror                     ; 2
    and    #$07             ; 2
    tax                     ; 2
    bcs    .xPosUFO_l       ; 2³
    lda    enemyCol         ; 3
    sta    COLUP1           ; 3
    lda    vDelP1Krnl       ; 3
    sta    VDELP1           ; 3
    sta    HMCLR            ; 3
    lda    xUFO             ; 3
    sta    HMP1             ; 3
    lda    ($83,x)          ; 6
    lda    #$00             ; 2
    sta    NUSIZ1           ; 3
    dex                     ; 2
    bne    .xPosUfo1_r      ; 2³
    sta    RESP1            ; 3     @53
    beq    .loopKernel      ; 3

.xPosUfo1_r:
    dex                     ; 2
    bne    .xPosUfo2_r      ; 2³
    sta    RESP1            ; 3     @58
    beq    .loopKernel      ; 2³
.xPosUfo2_r:
    dex                     ; 2
    bne    .xPosUfo3_r      ; 2³
    sta    RESP1            ; 3     @63
    beq    .loopKernel      ; 2³
.xPosUfo3_r:
    dex                     ; 2
    bne    .xPosUfo4_r      ; 2³
    sta    RESP1            ; 3     @68
    beq    .loopKernel      ; 2³
.xPosUfo4_r:
    dex                     ; 2
    nop                     ; 2
    sta    RESP1            ; 3     @73
    beq    .moveUFO         ; 3

.xPosUFO_l:
    nop                     ; 2
.waitUFO:
    dex                     ; 2
    bne    .waitUFO         ; 2³
    sta    RESP1            ; 3
    sta    HMCLR            ; 3
    lda    xUFO             ; 3
    sta    HMP1             ; 3
    lda    enemyCol         ; 3         UFO or sattelite color
    sta    COLUP1           ; 3
    lda    vDelP1Krnl       ; 3         bit one is *always* 1!
    sta    VDELP1           ; 3
    stx    NUSIZ1           ; 3

.loopKernel:
    sta    WSYNC            ; 3
.moveUFO:
    sta    HMOVE            ; 3

; *** draw UFO/sattelite: (part 3/3) ***
    stx    GRP1             ; 3

; *** draw shots: (part 2/2) ***
    cpy    yShotUfo         ; 3         ENABL?
    php                     ; 3
    cpy    yShot2           ; 3         ENAM1?
    php                     ; 3
    cpy    yShot1           ; 3         ENAM0?
    php                     ; 3

; *** draw ship: (part 1/2) ***
    ldx    #0               ; 2
.drawShip:
    lda    (ptrShip,x)      ; 6         Ship,x
    cmp    #$ff             ; 2         end of graphics?
    beq    .checkStartShip  ; 2³         yes, skip drawing
    inc    ptrShip          ; 5         next
    bne    .contShip        ; 3+1

.checkStartShip:
    cpy    yShipKrnl        ; 3         start drawing ship?
    bne    .skipDrawShip    ; 2³+1       no
    lda    ptrShipHlp       ; 3         copy pointer to start drawing
    sta    ptrShip          ; 3
    jmp    .drawShip        ; 3         bcs

.skipDrawShip:
    txa                     ; 2         a = 0
.contShip:

    sta    HMCLR            ; 3
    sta    WSYNC            ; 3
    sta    HMOVE            ; 3

; *** draw ship: (part 2/2) ***
    sta    GRP0             ; 3

; *** draw UFO/sattelite: (part 1/3) ***
    ldx    #0               ; 2         superfluous code
.drawUFO:
    lda    (ptrEnemy,x)     ; 6         UFO/sattelite
    cmp    #$ff             ; 2         end of graphics?
    beq    .checkStartUFO   ; 3          yes, skip drawing
    inc    ptrEnemy         ; 5
    bne    .contUFO         ; 3

.checkStartUFO:
    cpy    yUFO             ; 3         start drawing UFO/sattelite?
    bne    skipDrawUFO      ; 2³
    lda    ptrEnemyHlp      ; 3
    sta    ptrEnemy         ; 3
    jmp    .drawUFO         ; 3

skipDrawUFO:
    txa                     ; 2
.contUFO:

; *** draw shots: (part 1/2) ***
    ldx    #ENABL           ; 2
    txs                     ; 2

; *** draw UFO/sattelite: (part 2/3) ***
    tax                     ; 2

; *** loop: ***
    iny                     ; 2
    cpy    #H_KERNEL        ; 2
    bne    .loopKernel      ; 2³+1
; ********** E V E N   K E R N E L (end) **********

ExitKernelW:
    sta    WSYNC            ; 3
ExitKernel:
    lda    #$00             ; 2
    sta    GRP0             ; 3
    sta    GRP1             ; 3
    sta    ENABL            ; 3
    sta    ENAM0            ; 3
    sta    ENAM1            ; 3
    jmp    BS_OverScan      ; 3         continue with overscan


; ********** S E T U P   S C C O R E (start) **********
SetupScore SUBROUTINE
.lifesOfs   = $f3
.ptrDigits  = $f4
.scores     = $f6   ; ..$fb
.pf0_l      = $fc
.pf1_l      = $fd
.pf2_l      = $fe
.pf2_r      = $ff
.tmpVar     = .scores

    bit    flags            ; 3         game running?
    bvc    .showScore       ; 2³         yes

; *** show game number ***
; convert internal game number into displayed number:
    lda    game             ; 3
    and    #$bf             ; 2         child game
    bpl    .normalGame      ; 2³         no
    cmp    #$80             ; 2         single player?
    bne    .child66         ; 2³         no
    lda    #33              ; 2         child game 33
    bne    .endConvert      ; 3

.child66:
    lda    #66              ; 2         child game 66
    bne    .endConvert      ; 3

.normalGame:
    tax                     ; 2
    inx                     ; 2         show game number +1
    and    #TWO_PLAYERS     ; 2
    beq    .skipCorrection  ; 2³
    inx                     ; 2         child game 33 correction
.skipCorrection:
    txa                     ; 2
.endConvert:

; split digits of game number:
    ldx    #0               ; 2
.div10Loop:
    cmp    #10              ; 2
    bcc    Ld466            ; 2³
    inx                     ; 2
    sec                     ; 2
    sbc    #10              ; 2
    bcs    .div10Loop       ; 2³
Ld466:
    sta    tmpVarB          ; 3
    txa                     ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    ora    tmpVarB          ; 3
    sta    scoreLow         ; 3
    lda    #$00             ; 2
    sta    scoreHigh        ; 3
    lda    #<Blank          ; 2
    sta    .scores+4        ; 3
    ldx    #<One1           ; 2
    lda    game             ; 3
    and    #TWO_PLAYERS     ; 2
    beq    .singlePlayer    ; 2³
    ldx    #<Two1           ; 2
.singlePlayer:
    stx    .scores+5        ; 3
    jmp    .endPrepare      ; 3

.showScore:
    lda    flags2           ; 3         switches between player number and lifes
    ror                     ; 2         game over?
  IF ORIGINAL
    bcc    .showLifes       ; 2³         no, show lifes
  ELSE
    nop                     ; 2         disabled to always show player number
    nop                     ; 2
  ENDIF
    lda    #<One1           ; 2          yes, show player number
    bit    flags            ; 3         player 1
    bpl    .contScore       ; 2³         yes
    lda    #<Two1           ; 2          no, player 2
    bne    .contScore       ; 3

.showLifes:
    lda    lifesDir         ; 3
    and    #LIFES_MASK      ; 2
    lsr                     ; 2
    lsr                     ; 2
    sta    .tmpVar          ; 3
    lsr                     ; 2
    lsr                     ; 2
    adc    .tmpVar          ; 3         = lifes * 5
    adc    #<Zero1          ; 2
.contScore:
    sta    .scores+5        ; 3
    lda    #<Zero0          ; 2
    sta    .scores+4        ; 3
.endPrepare:

  IF ORIGINAL
    lda    #$00             ; 2
  ELSE
    lda    lifesDir         ; 3         why did they remove this???
  ENDIF
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    cmp    #8               ; 2         maximum lifes?
    bcc    .skipLimit       ; 2³
    lda    #7               ; 2
.skipLimit:
    tax                     ; 2
    lda    LifesOfsTbl,x    ; 4
    sta    WSYNC            ; 3
    sta    .lifesOfs        ; 3
    lda    LifesHMoveTbl,x  ; 4
    sta    HMP0             ; 3
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    sta    HMP1             ; 3
    lda    LifesNusizTbl,x  ; 4
    sta    NUSIZ0           ; 3
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    sta    NUSIZ1           ; 3
    ldy    LifesDelayTbl,x  ; 4
Ld4d8:
    dey                     ; 2
    bpl    Ld4d8            ; 2³
    sta    RESP0            ; 3
    sta    RESP1            ; 3
    sta    WSYNC            ; 3
    sta    HMOVE            ; 3

; prepeare score display:
    lda    #>Zero0          ; 2
    sta    .ptrDigits+1     ; 3
    lda    #<Zero0+4        ; 2
    sta    .ptrDigits       ; 3
    lda    scoreLow         ; 3
    and    #$0f             ; 2
    sta    .tmpVar          ; 3
    asl                     ; 2
    asl                     ; 2
    adc    .tmpVar          ; 3     *5
    adc    #<Zero1          ; 2
    sta    .scores+3        ; 3
    lda    scoreLow         ; 3
    and    #$f0             ; 2
    lsr                     ; 2
    lsr                     ; 2
    sta    .tmpVar          ; 3
    lsr                     ; 2
    lsr                     ; 2
    adc    .tmpVar          ; 3     *5
    adc    #<Zero3          ; 2
    sta    .scores+2        ; 3
    lda    scoreHigh        ; 3
    and    #$0f             ; 2
    sta    .tmpVar          ; 3
    asl                     ; 2
    asl                     ; 2
    adc    .tmpVar          ; 3     *5
    adc    #<Zero2          ; 2
    sta    .scores+1        ; 3
    lda    scoreHigh        ; 3
    and    #$f0             ; 2
    lsr                     ; 2
    lsr                     ; 2
    sta    .tmpVar          ; 3
    lsr                     ; 2
    lsr                     ; 2
    adc    .tmpVar          ; 3     *5
    sta    .scores          ; 3

; remove leading zeroes:
    ldx    #0               ; 2
    ldy    #<Blank          ; 2
.loopZero:
    lda    .scores,x        ; 4
    beq    .setBlank        ; 2³
    cmp    #<Zero1          ; 2
    beq    .setBlank        ; 2³
    cmp    #<Zero2          ; 2
    beq    .setBlank        ; 2³
    cmp    #<Zero3          ; 2
    bne    .exitZero        ; 2³
.setBlank:
    sty    .scores,x        ; 4
    inx                     ; 2
    cpx    #4               ; 2
    bne    .loopZero        ; 2³
.exitZero:
    sta    HMCLR            ; 3

; prepare first line of score display:
    ldy    .scores          ; 3
    lda    (.ptrDigits),y   ; 5
    sta    .pf0_l           ; 3
    ldy    .scores+1        ; 3
    lda    (.ptrDigits),y   ; 5
    ldy    .scores+2        ; 3
    ora    (.ptrDigits),y   ; 5
    sta    .pf1_l           ; 3
    ldy    .scores+3        ; 3
    lda    (.ptrDigits),y   ; 5
    ldy    .scores+4        ; 3
    ora    (.ptrDigits),y   ; 5
    sta    .pf2_l           ; 3
    ldy    .scores+5        ; 3
    lda    (.ptrDigits),y   ; 5
    sta    .pf2_r           ; 3
    dec    .ptrDigits       ; 5
  IF ORIGINAL
    lda    #$74             ; 2         not converted for PAL!
  ELSE
    lda    #BLUE1+4         ; 2
  ENDIF
    sta    COLUP0           ; 3
    sta    COLUP1           ; 3
    lda    #PLAYER1_COL     ; 2
    bit    flags            ; 3         player 1?
    bpl    Ld572            ; 2³         yes
    lda    #PLAYER2_COL     ; 2
Ld572:
    eor    ssColor          ; 3
    sta    COLUPF           ; 3
    lda    #$00             ; 2
    sta    VDELP0           ; 3
    sta    VDELP1           ; 3
    sta    REFP0            ; 3
Ld57e:
    lda    INTIM            ; 4
    bne    Ld57e            ; 2³
    jmp    DrawScore        ; 3
; ********** S E T U P   S C C O R E (end) **********


BS_OverScan:
    lda    #<OverScan       ; 2
    sta    bswVec           ; 3
    lda    #>OverScan       ; 2
    sta    bswVec+1         ; 3
    jmp    SwitchBank1      ; 3

START0:
    lda    #<START1         ; 2
    sta    bswVec           ; 3
    lda    #>START1         ; 2
    sta    bswVec+1         ; 3
    jmp    SwitchBank1      ; 3


    align   256, 0

XMoveObj  SUBROUTINE
; a = number of pixel to move
; x = object-idx
.tmpId  = $f4

    ldy    xPosLst,x        ; 4
    stx    .tmpId           ; 3
    tax                     ; 2
    bcs    .loopLeft        ; 2³
.loopRight:
    lda    XMoveRightTbl,y  ; 4
    tay                     ; 2
    dex                     ; 2
    bne    .loopRight       ; 2³
    beq    .exitRight       ; 3

.loopLeft:
    lda    XMoveLeftTbl,y   ; 4
    tay                     ; 2
    dex                     ; 2
    bne    .loopLeft        ; 2³
.exitRight:
    ldx    .tmpId           ; 3
    sta    xPosLst,x        ; 4
    ldy    #>XMoveObjRTS    ; 2
    sty    bswVec+1         ; 3
    ldy    #<XMoveObjRTS    ; 2
    sty    bswVec           ; 3
    jmp    SwitchBank1      ; 3


  IF ORIGINAL = 0
   IF SADISTROIDS = 0
    .byte " Asteroids DC+ - (C) Copyright 2002 Atari, Thomas Jentzsch "
   ELSE
    .byte " Sadistroids (C) Copyright 2003 Atari, Thomas Jentzsch "
   ENDIF
  ENDIF

    align   256, 0

XMoveRightTbl:
    .byte $f0, $f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8, $f9, $fa, $fb, $fc, $fd, $fe, $ff
    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
    .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
    .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
    .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
    .byte $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
    .byte $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $5f
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $62, $63, $64, $65, $66, $67, $68, $69, $6a, $6b, $63, $6d, $6e, $32, $00, $00
    .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
    .byte $90, $91, $92, $65, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $a0, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $aa, $ab, $ac, $ad, $ae, $af
    .byte $b0, $b1, $b2, $b3, $b4, $b5, $b6, $b7, $b8, $b9, $ba, $bb, $bc, $bd, $be, $bf
    .byte $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf
    .byte $d0, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $da, $db, $dc, $dd, $de, $df
    .byte $e0, $e1, $e2, $e3, $e4, $e5, $e6, $e7, $e8, $e9, $ea, $eb, $ec, $ed, $ee, $ef
XMoveLeftTbl:
    .byte $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
    .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
    .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
    .byte $40, $41, $8d, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
    .byte $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $5f
    .byte $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6a, $6b, $6c, $6d, $6e, $6f
    .byte $00, $00, $00, $8a, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
    .byte $a0, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $aa, $ab, $ac, $ad, $ae, $af
    .byte $b0, $b1, $b2, $b3, $b4, $b5, $b6, $b7, $b8, $b9, $ba, $bb, $bc, $bd, $be, $bf
    .byte $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf
    .byte $d0, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $da, $db, $dc, $dd, $de, $df
    .byte $e0, $e1, $e2, $e3, $e4, $e5, $e6, $e7, $e8, $e9, $ea, $eb, $ec, $ed, $ee, $ef
    .byte $f0, $f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8, $f9, $fa, $fb, $fc, $fd, $fe, $ff
    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f

GetHMSizeTbl0:
    ldy    #0               ; 2
    lda    ($ef),y          ; 5         HMSizeTbl
    ldy    #>RetHMSizeTbl0  ; 2
    sty    bswVec+1         ; 3
    ldy    #<RetHMSizeTbl0  ; 2
    sty    bswVec           ; 3
    jmp    SwitchBank1      ; 3

GetHMSizeTbl1:
    ldy    #0               ; 2
    lda    ($f1),y          ; 5         HMSizeTbl
    ldy    #>RetHMSizeTbl1  ; 2
    sty    bswVec+1         ; 3
    ldy    #<RetHMSizeTbl1  ; 2
    sty    bswVec           ; 3
    jmp    SwitchBank1      ; 3

  IF GARBAGE
   IF NTSC
    .byte $45, $b9, $b4, $4b, $b5, $4b, $bc, $4b
    .byte $b4, $4b, $f4, $4b, $b4, $5b, $34, $3b
    .byte $b4, $fb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b0, $4a, $b4, $4b, $bb, $4d, $bd
    .byte $45, $bb, $a4, $0b, $f4, $4b, $f4, $0b
    .byte $a4, $bb, $94, $9b, $44, $bb, $44, $bb
    .byte $44, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4b, $b4, $49, $b4, $43, $bd
    .byte $41, $bc, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $6b, $d4, $9b, $a4, $0b, $74, $bb
    .byte $64, $3b, $4b, $b4, $4b, $b0, $4f, $b4
    .byte $4b, $b4, $4f, $b1, $46, $bf, $44, $bb
    .byte $44, $bb, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $94, $5b, $34, $bb, $24, $9b
    .byte $54, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $94, $ab, $34, $fb, $54, $db
    .byte $e4, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4a, $b4, $42, $b5, $4c, $bb
    .byte $4c, $ba, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $5b, $b4, $5b, $94, $0b
    .byte $b4, $eb, $4b, $b4, $4b, $b4, $4b, $b0
    .byte $4c, $b5, $4b, $b1, $46, $bf, $4a, $bb
    .byte $44, $ba, $b4, $4b, $94, $6b, $f4, $1b
    .byte $d4, $1b, $74, $2b, $44, $bb, $44, $bb
    .byte $44, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4f, $b2, $4e, $b0, $43, $ba
    .byte $41, $b8
   ELSE
    .byte $45, $b9, $b4, $4b, $b5, $4b, $bc, $4b
    .byte $b4, $4b, $f4, $4b, $b4, $5b, $34, $3b
    .byte $b4, $fb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b0, $4a, $b4, $4b, $bb, $4d, $bd
    .byte $45, $bb, $a4, $0b, $f4, $4b, $f4, $0b
    .byte $a4, $bb, $94, $9b, $44, $bb, $44, $bb
    .byte $44, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4a, $b4, $49, $b4, $43, $bd
    .byte $41, $bc, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $6b, $d4, $9b, $a4, $0b, $74, $bb
    .byte $64, $3b, $4b, $b4, $4b, $b0, $4f, $b4
    .byte $4b, $b0, $4f, $b1, $46, $bf, $44, $bb
    .byte $44, $bb, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $94, $5b, $34, $bb, $24, $9b
    .byte $54, $9b, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4b, $b4, $4b, $b0, $4b, $b4
    .byte $4b, $b4, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $94, $ab, $74, $fb, $54, $db
    .byte $e4, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4a, $b4, $42, $b5, $4c, $bb
    .byte $4c, $ba, $b4, $4b, $b4, $49, $b4, $4b
    .byte $b4, $4b, $b4, $5b, $a4, $5b, $94, $0b
    .byte $b4, $eb, $4b, $b4, $4b, $b4, $4b, $b0
    .byte $4c, $b5, $4b, $b1, $46, $bf, $4a, $bb
    .byte $44, $ba, $b4, $4b, $94, $6b, $f4, $1b
    .byte $d4, $1b, $74, $2b, $44, $bb, $44, $bb
    .byte $44, $bb, $4b, $b4, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4f, $b2, $4e, $b0, $43, $ba
    .byte $41, $b8
   ENDIF
  ELSE
    align 256, 0
  ENDIF

  IF COPYRIGHT
   IF SADISTROIDS = 0
Col0:
    .byte %00000000 ; |        | $da00
    .byte %01111000 ; | XXXX   | $da01
    .byte %00110000 ; |  XX    | $da02
    .byte %00110000 ; |  XX    | $da03
    .byte %00110000 ; |  XX    | $da04
    .byte %00110000 ; |  XX    | $da05
    .byte %00110000 ; |  XX    | $da06
    .byte %01111000 ; | XXXX   | $da07
    .byte %00000000 ; |        | $da08
    .byte %00000000 ; |        | $da09
    .byte %11000110 ; |XX   XX | $da0a
    .byte %11000110 ; |XX   XX | $da0b
    .byte %11111110 ; |XXXXXXX | $da0c
    .byte %11000110 ; |XX   XX | $da0d
    .byte %11000110 ; |XX   XX | $da0e
    .byte %01101100 ; | XX XX  | $da0f
    .byte %00111000 ; |  XXX   | $da10
    .byte %00000000 ; |        | $da11
    .byte %00000000 ; |        | $da12
    .byte %01111000 ; | XXXX   | $da13
    .byte %10000100 ; |X    X  | $da14
    .byte %10110100 ; |X XX X  | $da15
    .byte %10100100 ; |X X  X  | $da16
    .byte %10110100 ; |X XX X  | $da17
    .byte %10000100 ; |X    X  | $da18
    .byte %01111000 ; | XXXX   | $da19
Col1:
    .byte %00000000 ; |        | $da1a
    .byte %11000110 ; |XX   XX | $da1b
    .byte %11001110 ; |XX  XXX | $da1c
    .byte %11011110 ; |XX XXXX | $da1d
    .byte %11111110 ; |XXXXXXX | $da1e
    .byte %11110110 ; |XXXX XX | $da1f
    .byte %11100110 ; |XXX  XX | $da20
    .byte %11000110 ; |XX   XX | $da21
    .byte %00000000 ; |        | $da22
    .byte %00000000 ; |        | $da23
    .byte %00110000 ; |  XX    | $da24
    .byte %00110000 ; |  XX    | $da25
    .byte %00110000 ; |  XX    | $da26
    .byte %00110000 ; |  XX    | $da27
    .byte %00110000 ; |  XX    | $da28
    .byte %00110000 ; |  XX    | $da29
    .byte %11111100 ; |XXXXXX  | $da2a
    .byte %00000000 ; |        | $da2b
    .byte %00000000 ; |        | $da2c
    .byte %00000000 ; |        | $da2d
    .byte %00000000 ; |        | $da2e
    .byte %00000000 ; |        | $da2f
    .byte %00000000 ; |        | $da30
    .byte %00000000 ; |        | $da31
    .byte %00000000 ; |        | $da32
    .byte %00000000 ; |        | $da33
Col2:
    .byte %00000000 ; |        | $da34
    .byte %00111100 ; |  XXXX  | $da35
    .byte %01100110 ; | XX  XX | $da36
    .byte %11000000 ; |XX      | $da37
    .byte %11000000 ; |XX      | $da38
    .byte %11000000 ; |XX      | $da39
    .byte %01100110 ; | XX  XX | $da3a
    .byte %00111100 ; |  XXXX  | $da3b
    .byte %00000000 ; |        | $da3c
    .byte %00000000 ; |        | $da3d
    .byte %11000110 ; |XX   XX | $da3e
    .byte %11000110 ; |XX   XX | $da3f
    .byte %11111110 ; |XXXXXXX | $da40
    .byte %11000110 ; |XX   XX | $da41
    .byte %11000110 ; |XX   XX | $da42
    .byte %11000110 ; |XX   XX | $da43
    .byte %00111000 ; |  XXX   | $da44
    .byte %00000000 ; |        | $da45
    .byte %00000000 ; |        | $da46
  IF ORIGINAL
    .byte %11111100 ; |XXXXXX  | $da47
    .byte %00110000 ; |  XX    | $da48
    .byte %00110000 ; |  XX    | $da49
    .byte %00110000 ; |  XX    | $da4a
    .byte %00110000 ; |  XX    | $da4b
    .byte %01110000 ; | XXX    | $da4c
    .byte %00110000 ; |  XX    | $da4d
  ELSE
    .byte %11111110 ; |XXXXXXX | $da47
    .byte %11000000 ; |XX      | $da48
    .byte %11000000 ; |XX      | $da49
    .byte %01111100 ; | XXXXX  | $da4a
    .byte %00000110 ; |     XX | $da4b
    .byte %11000110 ; |XX   XX | $da4c
    .byte %01111100 ; | XXXXX  | $da4d
  ENDIF
Col3:
    .byte %00000000 ; |        | $da4e
    .byte %00110000 ; |  XX    | $da4f
    .byte %00110000 ; |  XX    | $da50
    .byte %00000000 ; |        | $da51
    .byte %00000000 ; |        | $da52
    .byte %00000000 ; |        | $da53
    .byte %00000000 ; |        | $da54
    .byte %00000000 ; |        | $da55
    .byte %00000000 ; |        | $da56
    .byte %00000000 ; |        | $da57
    .byte %11001110 ; |XX  XXX | $da58
    .byte %11011100 ; |XX XXX  | $da59
    .byte %11111000 ; |XXXXX   | $da5a
    .byte %11001110 ; |XX  XXX | $da5b
    .byte %11000110 ; |XX   XX | $da5c
    .byte %11000110 ; |XX   XX | $da5d
    .byte %11111100 ; |XXXXXX  | $da5e
    .byte %00000000 ; |        | $da5f
    .byte %00000000 ; |        | $da60
  IF ORIGINAL
    .byte %01111000 ; | XXXX   | $da61
    .byte %00001100 ; |    XX  | $da62
    .byte %00000110 ; |     XX | $da63
    .byte %01111110 ; | XXXXXX | $da64
    .byte %11000110 ; |XX   XX | $da65
    .byte %11000110 ; |XX   XX | $da66
    .byte %01111100 ; | XXXXX  | $da67
  ELSE
    .byte %01111100 ; | XXXXX  | $da61
    .byte %11000110 ; |XX   XX | $da62
    .byte %11000110 ; |XX   XX | $da63
    .byte %11000110 ; |XX   XX | $da64
    .byte %11000110 ; |XX   XX | $da65
    .byte %11000110 ; |XX   XX | $da66
    .byte %01111100 ; | XXXXX  | $da67
  ENDIF
Col4:
    .byte %00000000 ; |        | $da68
    .byte %00000000 ; |        | $da69
    .byte %00000000 ; |        | $da6a
    .byte %00000000 ; |        | $da6b
    .byte %00000000 ; |        | $da6c
    .byte %00000000 ; |        | $da6d
    .byte %00000000 ; |        | $da6e
    .byte %00000000 ; |        | $da6f
    .byte %00000000 ; |        | $da70
    .byte %00000000 ; |        | $da71
    .byte %01111000 ; | XXXX   | $da72
    .byte %00110000 ; |  XX    | $da73
    .byte %00110000 ; |  XX    | $da74
    .byte %00110000 ; |  XX    | $da75
    .byte %00110000 ; |  XX    | $da76
    .byte %00110000 ; |  XX    | $da77
    .byte %01111000 ; | XXXX   | $da78
    .byte %00000000 ; |        | $da79
    .byte %00000000 ; |        | $da7a
  IF ORIGINAL
    .byte %01111100 ; | XXXXX  | $da7b
    .byte %11000110 ; |XX   XX | $da7c
    .byte %11000110 ; |XX   XX | $da7d
    .byte %01111100 ; | XXXXX  | $da7e
    .byte %11000110 ; |XX   XX | $da7f
    .byte %11000110 ; |XX   XX | $da80
    .byte %01111100 ; | XXXXX  | $da81
  ELSE
    .byte %01111100 ; | XXXXX  | $da61
    .byte %11000110 ; |XX   XX | $da62
    .byte %11000110 ; |XX   XX | $da63
    .byte %11000110 ; |XX   XX | $da64
    .byte %11000110 ; |XX   XX | $da65
    .byte %11000110 ; |XX   XX | $da66
    .byte %01111100 ; | XXXXX  | $da67
  ENDIF
Col5:
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00000000 ; |        | $da85
    .byte %00000000 ; |        | $da86
    .byte %00000000 ; |        | $da87
    .byte %00000000 ; |        | $da88
    .byte %00000000 ; |        | $da89
    .byte %00000000 ; |        | $da8a
    .byte %00000000 ; |        | $da8b
    .byte %00110000 ; |  XX    | $da8c
    .byte %00011000 ; |   XX   | $da8d
    .byte %00111000 ; |  XXX   | $da8e
    .byte %00111000 ; |  XXX   | $da8f
    .byte %00000000 ; |        | $da90
    .byte %00000000 ; |        | $da91
    .byte %00000000 ; |        | $da92
    .byte %00000000 ; |        | $da93
    .byte %00000000 ; |        | $da94
  IF ORIGINAL
    .byte %11111100 ; |XXXXXX  | $da95
    .byte %00110000 ; |  XX    | $da96
    .byte %00110000 ; |  XX    | $da97
    .byte %00110000 ; |  XX    | $da98
    .byte %00110000 ; |  XX    | $da99
    .byte %01110000 ; | XXX    | $da9a
    .byte %00110000 ; |  XX    | $da9b
  ELSE
   IF SADISTROIDS = 0
    .byte %11111110 ; |XXXXXXX | $da47
    .byte %11000000 ; |XX      | $da48
    .byte %11000000 ; |XX      | $da49
    .byte %01111100 ; | XXXXX  | $da4a
    .byte %00000110 ; |     XX | $da4b
    .byte %11000110 ; |XX   XX | $da4c
    .byte %01111100 ; | XXXXX  | $da4d
   ELSE
    .byte %01111100 ; | XXXXX  | $da47
    .byte %11000110 ; |XX   XX | $da48
    .byte %00000110 ; |     XX | $da49
    .byte %00011100 ; |   XXX  | $da4a
    .byte %00000110 ; |     XX | $da4b
    .byte %11000110 ; |XX   XX | $da4c
    .byte %01111100 ; | XXXXX  | $da4d
   ENDIF
    ENDIF
   ELSE
Col0:
    .byte %00000000 ; |        | $da01
    .byte %01111001 ; |        | $da82
    .byte %10000101 ; |        | $da83
    .byte %10110100 ; |        | $da82
    .byte %10100100 ; |        | $da83
    .byte %10110100 ; |        | $da84
    .byte %10000101 ; |        | $da85
    .byte %01111000 ; |        | $da00
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da03
    .byte %00000000 ; |        | $da04
    .byte %00000000 ; |        | $da05
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00000000 ; |        | $da85
    .byte %00000000 ; |        | $da00
    .byte %00000000 ; |        | $da01
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da03
    .byte %00000000 ; |        | $da04
    .byte %00000000 ; |        | $da05
    .byte %01111000 ; | XXXX   | $da06
    .byte %01111100 ; | XXXXX  | $da07
    .byte %00001100 ; |    XX  | $da08
    .byte %00001100 ; |    XX  | $da09
    .byte %00001100 ; |    XX  | $da0a
    .byte %00001100 ; |    XX  | $da0b
    .byte %00001100 ; |    XX  | $da0c
    .byte %00011100 ; |   XXX  | $da0d
    .byte %00011100 ; |   XXX  | $da0e
    .byte %00111000 ; |  XXX   | $da0f
    .byte %01110000 ; | XXX    | $da10
    .byte %01110000 ; | XXX    | $da11
    .byte %01110000 ; | XXX    | $da12
    .byte %01110000 ; | XXX    | $da13
    .byte %01110000 ; | XXX    | $da14
    .byte %00111000 ; |  XXX   | $da15
    .byte %00111111 ; |  XXXXXX| $da16
    .byte %00111111 ; |  XXXXXX| $da17
    .byte %00011111 ; |   XXXXX| $da18
    .byte %00000111 ; |     XXX| $da19
    .byte %00000000 ; |        | $da1a
Col1:
    .byte %00000000 ; |        | $da01
    .byte %11100110 ; |        | $da82
    .byte %00001001 ; |        | $da83
    .byte %10001001 ; |        | $da82
    .byte %01001001 ; |        | $da83
    .byte %00101001 ; |        | $da84
    .byte %00101001 ; |        | $da85
    .byte %11000110 ; |        | $da00
    .byte %00000000 ; |        | $da01
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da03
    .byte %00000000 ; |        | $da04
    .byte %00000000 ; |        | $da05
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00000000 ; |        | $da1b
    .byte %00000000 ; |        | $da1c
    .byte %00000000 ; |        | $da1d
    .byte %00000000 ; |        | $da1e
    .byte %00110100 ; |  XX X  | $da1f
    .byte %01110110 ; | XXX XX | $da20
    .byte %11110110 ; |XXXX XX | $da21
    .byte %11110111 ; |XXXX XXX| $da22
    .byte %11110111 ; |XXXX XXX| $da23
    .byte %10110111 ; |X XX XXX| $da24
    .byte %10110101 ; |X XX X X| $da25
    .byte %10110101 ; |X XX X X| $da26
    .byte %11110101 ; |XXXX X X| $da27
    .byte %11110101 ; |XXXX X X| $da28
    .byte %11110111 ; |XXXX XXX| $da29
    .byte %01110111 ; | XXX XXX| $da2a
    .byte %00010110 ; |   X XX | $da2b
    .byte %10010100 ; |X  X X  | $da2c
    .byte %11010000 ; |XX X    | $da2d
    .byte %01110000 ; | XXX    | $da2e
    .byte %00110000 ; |  XX    | $da2f
    .byte %00000000 ; |        | $da30
    .byte %00000000 ; |        | $da31
    .byte %00000000 ; |        | $da32
    .byte %00000000 ; |        | $da33
Col2:
    .byte %00000000 ; |        | $da01
    .byte %00110001 ; |        | $da82
    .byte %01001010 ; |        | $da83
    .byte %01001000 ; |        | $da82
    .byte %01001000 ; |        | $da83
    .byte %01001000 ; |        | $da84
    .byte %01001010 ; |        | $da85
    .byte %00110001 ; |        | $da00
    .byte %00000000 ; |        | $da01
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da04
    .byte %00000000 ; |        | $da05
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00010001 ; |        | $da85
    .byte %00101001 ; |        | $da34
    .byte %00101001 ; |        | $da35
    .byte %00101011 ; |        | $da36
    .byte %00101001 ; |        | $da37
    .byte %00000000 ; |        | $da38
    .byte %00000000 ; |        | $da38
    .byte %00000000 ; |        | $da39
    .byte %01000000 ; | X      | $da3a
    .byte %01000000 ; | X      | $da3b
    .byte %01000000 ; | X      | $da3c
    .byte %01011000 ; | X XX   | $da3d
    .byte %01011100 ; | X XXX  | $da3e
    .byte %01000100 ; | X   X  | $da3f
    .byte %01001100 ; | X  XX  | $da40
    .byte %01011101 ; | X XXX X| $da41
    .byte %01011001 ; | X XX  X| $da42
    .byte %01011000 ; | X XX   | $da43
    .byte %00011100 ; |   XXX  | $da44
    .byte %01011100 ; | X XXX  | $da45
    .byte %11101110 ; |XXX XXX | $da46
    .byte %10101110 ; |X X XXX | $da47
    .byte %11100110 ; |XXX  XX | $da48
    .byte %11000110 ; |XX   XX | $da49
    .byte %00000000 ; |        | $da4a
    .byte %00000000 ; |        | $da4b
    .byte %00000000 ; |        | $da4c
    .byte %00000000 ; |        | $da4d
Col3:
    .byte %00000000 ; |        | $da04
    .byte %10001001 ; |        | $da82
    .byte %01001001 ; |        | $da83
    .byte %01001001 ; |        | $da82
    .byte %10001111 ; |        | $da83
    .byte %01001001 ; |        | $da84
    .byte %01001001 ; |        | $da85
    .byte %10000110 ; |        | $da00
    .byte %00000000 ; |        | $da01
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da03
    .byte %00000000 ; |        | $da05
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %01011100 ; |        | $da84
    .byte %00010000 ; |        | $da85
    .byte %00001000 ; |        | $da4e
    .byte %00000100 ; |        | $da4f
    .byte %00011000 ; |        | $da50
    .byte %00000000 ; |        | $da51
    .byte %00000000 ; |        | $da52
    .byte %00000000 ; |        | $da53
    .byte %01000001 ; | X     X| $da54
    .byte %11001001 ; |XX  X  X| $da55
    .byte %11001001 ; |XX  X  X| $da56
    .byte %11001011 ; |XX  X XX| $da57
    .byte %11001011 ; |XX  X XX| $da58
    .byte %11001111 ; |XX  XXXX| $da59
    .byte %11001110 ; |XX  XXX | $da5a
    .byte %11101110 ; |XXX XXX | $da5b
    .byte %11111111 ; |XXXXXXXX| $da5c
    .byte %11111011 ; |XXXXX XX| $da5d
    .byte %11001011 ; |XX  X XX| $da5e
    .byte %11001111 ; |XX  XXXX| $da5f
    .byte %11000111 ; |XX   XXX| $da60
    .byte %11000000 ; |XX      | $da61
    .byte %11000000 ; |XX      | $da62
    .byte %11000000 ; |XX      | $da63
    .byte %11000000 ; |XX      | $da64
    .byte %00000000 ; |        | $da65
    .byte %00000000 ; |        | $da66
    .byte %00000000 ; |        | $da67
Col4:
    .byte %00000000 ; |        | $da82
    .byte %00100100 ; |        | $da83
    .byte %00100100 ; |        | $da82
    .byte %00100100 ; |        | $da83
    .byte %00100111 ; |        | $da84
    .byte %00100100 ; |        | $da85
    .byte %00100100 ; |        | $da00
    .byte %01110011 ; |        | $da01
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da03
    .byte %00000000 ; |        | $da04
    .byte %00000000 ; |        | $da05
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00000000 ; |        | $da85
    .byte %00000000 ; |        | $da68
    .byte %00000000 ; |        | $da69
    .byte %00000000 ; |        | $da6a
    .byte %00000000 ; |        | $da6b
    .byte %00000000 ; |        | $da6c
    .byte %00000100 ; |     X  | $da6d
    .byte %10000100 ; |X    X  | $da6e
    .byte %10000100 ; |X    X  | $da6f
    .byte %10100100 ; |X X  X  | $da70
    .byte %01110100 ; | XXX X  | $da71
    .byte %01110100 ; | XXX X  | $da72
    .byte %01010100 ; | X X X  | $da73
    .byte %01010100 ; | X X X  | $da74
    .byte %01010100 ; | X X X  | $da75
    .byte %01110100 ; | XXX X  | $da76
    .byte %01110000 ; | XXX    | $da77
    .byte %00110100 ; |  XX X  | $da78
    .byte %00001110 ; |    XXX | $da79
    .byte %00001010 ; |    X X | $da7a
    .byte %00001110 ; |    XXX | $da7b
    .byte %00001100 ; |    XX  | $da7c
    .byte %00000000 ; |        | $da7d
    .byte %00000000 ; |        | $da7e
    .byte %00000000 ; |        | $da7f
    .byte %00000000 ; |        | $da80
    .byte %00000000 ; |        | $da81
Col5:
    .byte %00000000 ; |        | $da01
    .byte %10100101 ; |        | $da82
    .byte %10101001 ; |        | $da83
    .byte %10110001 ; |        | $da82
    .byte %10111001 ; |        | $da83
    .byte %10100101 ; |        | $da84
    .byte %10100101 ; |        | $da85
    .byte %00111001 ; |        | $da00
    .byte %00000000 ; |        | $da02
    .byte %00000000 ; |        | $da03
    .byte %00000000 ; |        | $da04
    .byte %00000000 ; |        | $da05
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00000000 ; |        | $da85
    .byte %00000000 ; |        | $da82
    .byte %00000000 ; |        | $da83
    .byte %00000000 ; |        | $da84
    .byte %00000000 ; |        | $da85
    .byte %00000000 ; |        | $da86
    .byte %10000000 ; |X       | $da87
    .byte %11000000 ; |XX      | $da88
    .byte %11000000 ; |XX      | $da89
    .byte %11101100 ; |XXX XX  | $da8a
    .byte %11101110 ; |XXX XXX | $da8b
    .byte %11100010 ; |XXX   X | $da8c
    .byte %10100110 ; |X X  XX | $da8d
    .byte %10101110 ; |X X XXX | $da8e
    .byte %10101100 ; |X X XX  | $da8f
    .byte %10101100 ; |X X XX  | $da90
    .byte %11101110 ; |XXX XXX | $da91
    .byte %11101110 ; |XXX XXX | $da92
    .byte %11000111 ; |XX   XXX| $da93
    .byte %10000111 ; |X    XXX| $da94
    .byte %00000011 ; |      XX| $da95
    .byte %00000011 ; |      XX| $da96
    .byte %00000000 ; |        | $da97
    .byte %00000000 ; |        | $da98
    .byte %00000000 ; |        | $da99
    .byte %00000000 ; |        | $da9a
    .byte %00000000 ; |        | $da9b
  ENDIF

  IF GARBAGE
   IF NTSC
    .byte $4c, $ba, $44, $ba, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $4b, $34, $0b, $b4, $6b
    .byte $34, $3b, $54, $7b, $4b, $b4, $4f, $b6
    .byte $4b, $b8, $4b, $b0, $4c, $b1, $4f, $bf
    .byte $44, $bb, $44, $bb, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $34, $4b, $b4, $0b, $94, $db
    .byte $e4, $ab, $c4, $bb, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4b, $b4, $4b, $bc, $4f, $bc
    .byte $42, $ba, $46, $bf, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $4b, $34, $0b, $b4, $0b
    .byte $24, $6b, $64, $bb, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4b, $b4, $4b, $be, $4d, $b3
    .byte $4d, $bb, $42, $bb
   ELSE
    .byte $4c, $ba, $44, $ba, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $4b, $34, $0b, $b4, $6b
    .byte $34, $3b, $54, $7b, $4b, $b4, $4f, $b6
    .byte $4b, $b8, $4b, $b0, $4c, $b1, $4f, $bf
    .byte $44, $bb, $44, $bb, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $34, $4b, $b4, $0b, $94, $fb
    .byte $e4, $ab, $c4, $bb, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4f, $b4, $4b, $bc, $4f, $bc
    .byte $42, $ba, $46, $bf, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $4b, $34, $0b, $b4, $0b
    .byte $24, $6b, $64, $bb, $4b, $b4, $4b, $b4
    .byte $4b, $b4, $4b, $b4, $4b, $be, $4d, $b3
    .byte $4d, $bb, $42, $bb
   ENDIF
  ELSE
    align 256, 0
  ENDIF

ShowCopyright SUBROUTINE
.lineCnt    = $f3
.loopCnt    = $c6

    lda    #THREE_COPIES    ; 2
    sta    VDELP0           ; 3
    sta    VDELP1           ; 3
    sta    NUSIZ0           ; 3
    sta    NUSIZ1           ; 3
    lda    #RED+4           ; 2
    sta    COLUP0           ; 3
    sta    COLUP1           ; 3
    ldx    #6               ; 2
    sta    WSYNC            ; 3
    nop                     ; 2
.wait:
    dex                     ; 2
    bpl    .wait            ; 2³
    sta    RESP0            ; 3
    sta    RESP1            ; 3
    lda    #$10             ; 2
    sta    HMP1             ; 3
    sta    WSYNC            ; 3
    sta    HMOVE            ; 3

.loopCopyright:
    lda    #>Col0           ; 2
    sta    $f5              ; 3
    sta    $f7              ; 3
    sta    $f9              ; 3
    sta    $fb              ; 3
    sta    $fd              ; 3
    sta    $ff              ; 3
    lda    #<Col0           ; 2
    sta    $f4              ; 3
    lda    #<Col1           ; 2
    sta    $f6              ; 3
    lda    #<Col2           ; 2
    sta    $f8              ; 3
    lda    #<Col3           ; 2
    sta    $fa              ; 3
    lda    #<Col4           ; 2
    sta    $fc              ; 3
    lda    #<Col5           ; 2
    sta    $fe              ; 3
    ldx    #Col2-Col1-1     ; 2
    stx    .lineCnt         ; 3
    ldx    #$ff             ; 2
.waitOverscan:
    lda    INTIM            ; 4
    bne    .waitOverscan    ; 2³
    stx    VBLANK           ; 3
    stx    VSYNC            ; 3
    sta    WSYNC            ; 3
    sta    WSYNC            ; 3
    sta    WSYNC            ; 3
    sta    VSYNC            ; 3
  IF NTSC
   IF SADISTROIDS = 0
    lda    #45              ; 2
   ELSE
    lda    #33              ; 2
   ENDIF
  ELSE
    lda    #54              ; 2
  ENDIF
    sta    TIM64T           ; 4
.waitVBlank:
    lda    INTIM            ; 4
    bne    .waitVBlank      ; 2³

  IF NTSC
    ldx    #84              ; 2
  ELSE
    ldx    #100             ; 2
  ENDIF
.waitTop:
    sta    WSYNC            ; 3
    dex                     ; 2
    bpl    .waitTop         ; 2³
    lda    #$00             ; 2
    sta    VBLANK           ; 3

.loop:
    ldy    .lineCnt         ; 3
    lda    ($f4),y          ; 5
    sta    GRP0             ; 3
    sta    WSYNC            ; 3
    nop                     ; 2
    lda    ($f6),y          ; 5
    sta    GRP1             ; 3
    lda    ($f8),y          ; 5
    sta    GRP0             ; 3
    lda    ($fa),y          ; 5
    tax                     ; 2
    lda    ($fc),y          ; 5
    sta    tmpVar           ; 3
    lda    ($fe),y          ; 5
    ldy    tmpVar           ; 3
    stx    GRP1             ; 3
    sty    GRP0             ; 3
    sta    GRP1             ; 3
    sta    GRP0             ; 3
    dec    .lineCnt         ; 5
    bpl    .loop            ; 2³

  IF NTSC
    ldx    #84              ; 2
  ELSE
    ldx    #100             ; 2
  ENDIF
.waitBtm:
    sta    WSYNC            ; 3
    dex                     ; 2
    bpl    .waitBtm         ; 2³
  IF NTSC
   IF SADISTROIDS = 0
    lda    #36              ; 2
   ELSE
    lda    #26
   ENDIF
  ELSE
    lda    #45              ; 2
  ENDIF
    sta    TIM64T           ; 4
    inc    .loopCnt         ; 5
    beq   .exitLoop         ; 2³        beq !!!
  IF FAST_COPYRIGHT
    bit    INPT4
    bpl    .exitLoop
  ENDIF
    jmp    .loopCopyright   ; 3

.exitLoop:
    lda    #$00             ; 2
    sta    VDELP0           ; 3
    sta    VDELP1           ; 3
    sta    NUSIZ0           ; 3
    sta    NUSIZ1           ; 3
    lda    #<StartMain      ; 2
    sta    bswVec           ; 3
    lda    #>StartMain      ; 2
    sta    bswVec+1         ; 3
    jmp    SwitchBank1      ; 3

  IF GARBAGE
   IF NTSC
    .byte $b4, $5b, $74, $3b, $34, $bb, $44, $bb
    .byte $04, $bb, $4b, $b4, $4b, $be, $4b, $bc
    .byte $4f, $b5, $45, $ba, $44, $bb, $46, $bb
    .byte $44, $b9, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $5b, $b4, $db, $f4, $7b
    .byte $b4, $ab, $4f, $ba, $4a, $b5, $44, $b3
    .byte $4c, $bb, $4c, $b9, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $45, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $49, $ba, $43, $bc, $0b
    .byte $f0, $4b, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $45, $bb, $05, $ba, $57
    .byte $b5, $43, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $45, $b9, $47, $b9, $47, $f9, $42
    .byte $b8, $4b, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $ba, $47
    .byte $ba, $47, $bf, $47, $b8, $4b, $b4, $43
    .byte $b4, $43, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $46, $b1, $47, $ba, $47
    .byte $be, $44, $44, $bb, $44, $3b, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $ba, $47, $be, $47
    .byte $bf, $4e, $ba, $43, $90, $43, $b4, $1b
    .byte $6c, $89, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $45
    .byte $ba, $47, $b5, $0b, $bc, $4f, $bc, $4b
    .byte $b4, $4b, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $45, $ba, $45
    .byte $bb, $40, $be, $4f, $b9, $47, $b4, $43
    .byte $9c, $5b, $cc, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb
   ELSE
    .byte $b4, $5b, $74, $3b, $34, $bb, $44, $3b
    .byte $04, $bb, $4b, $b4, $4b, $be, $4b, $bc
    .byte $4f, $b5, $45, $ba, $44, $bb, $44, $bb
    .byte $44, $b9, $b4, $4b, $b4, $4b, $b4, $4b
    .byte $b4, $4b, $b4, $5b, $b4, $db, $f4, $7b
    .byte $b4, $ab, $4f, $ba, $4a, $b5, $44, $b3
    .byte $4c, $bb, $4c, $b9, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $45, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $09, $ba, $43, $bc, $0b
    .byte $f0, $4b, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $45, $bb, $05, $ba, $57
    .byte $b5, $43, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $ba, $44, $bb, $44, $bb, $44
    .byte $bb, $45, $b9, $47, $b9, $47, $f9, $42
    .byte $b8, $4b, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $ba, $47
    .byte $ba, $47, $bf, $47, $b8, $4b, $b4, $43
    .byte $b4, $43, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $46, $b1, $47, $ba, $47
    .byte $be, $44, $44, $bb, $44, $3b, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $45, $b8, $47, $be, $47
    .byte $be, $4e, $ba, $43, $90, $43, $b4, $1b
    .byte $6c, $89, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $44, $bb, $45
    .byte $ba, $47, $b5, $0b, $bc, $4f, $bc, $4b
    .byte $b4, $4b, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $bb, $44, $bb, $45, $ba, $45
    .byte $bb, $40, $be, $4f, $b9, $47, $b4, $43
    .byte $9c, $5b, $cc, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb
   ENDIF
  ELSE
  align 256, 0
    .byte 0
  align 256, 0
  ENDIF

  ELSE
    ORG $dd00, 0
  ENDIF

Zero0:
    .byte %11100000 ; |XXX     | $dd00
    .byte %10100000 ; |X X     |
    .byte %10100000 ; |X X     |
    .byte %10100000 ; |X X     |
    .byte %11100000 ; |XXX     |
    .byte %11100000 ; |XXX     |
    .byte %01000000 ; | X      |
    .byte %01000000 ; | X      |
    .byte %01100000 ; | XX     |
    .byte %01000000 ; | X      |
    .byte %11100000 ; |XXX     |
    .byte %00100000 ; |  X     |
    .byte %11100000 ; |XXX     |
    .byte %10000000 ; |X       |
    .byte %11100000 ; |XXX     |
    .byte %11100000 ; |XXX     |
    .byte %10000000 ; |X       |
    .byte %11000000 ; |XX      |
    .byte %10000000 ; |X       |
    .byte %11100000 ; |XXX     |
    .byte %10000000 ; |X       |
    .byte %10000000 ; |X       |
    .byte %11100000 ; |XXX     |
    .byte %10100000 ; |X X     |
    .byte %10100000 ; |X X     |
    .byte %11100000 ; |XXX     |
    .byte %10000000 ; |X       |
    .byte %11100000 ; |XXX     |
    .byte %00100000 ; |  X     |
    .byte %11100000 ; |XXX     |
    .byte %11100000 ; |XXX     |
    .byte %10100000 ; |X X     |
    .byte %11100000 ; |XXX     |
    .byte %00100000 ; |  X     |
    .byte %00100000 ; |  X     |
    .byte %10000000 ; |X       |
    .byte %10000000 ; |X       |
    .byte %10000000 ; |X       |
    .byte %10000000 ; |X       |
    .byte %11100000 ; |XXX     |
    .byte %11100000 ; |XXX     |
    .byte %10100000 ; |X X     |
    .byte %11100000 ; |XXX     |
    .byte %10100000 ; |X X     |
    .byte %11100000 ; |XXX     |
    .byte %10000000 ; |X       |
    .byte %10000000 ; |X       |
    .byte %11100000 ; |XXX     |
    .byte %10100000 ; |X X     |
    .byte %11100000 ; |XXX     |
Zero1:
    .byte %00001110 ; |    XXX | $dd32
    .byte %00001010 ; |    X X |
    .byte %00001010 ; |    X X |
    .byte %00001010 ; |    X X |
    .byte %00001110 ; |    XXX |
One1:
    .byte %00001110 ; |    XXX |
    .byte %00000100 ; |     X  |
    .byte %00000100 ; |     X  |
    .byte %00000110 ; |     XX |
    .byte %00000100 ; |     X  |
Two1:
    .byte %00001110 ; |    XXX |
    .byte %00000010 ; |      X |
    .byte %00001110 ; |    XXX |
    .byte %00001000 ; |    X   |
    .byte %00001110 ; |    XXX |
    .byte %00001110 ; |    XXX |
    .byte %00001000 ; |    X   |
    .byte %00001100 ; |    XX  |
    .byte %00001000 ; |    X   |
    .byte %00001110 ; |    XXX |
    .byte %00001000 ; |    X   |
    .byte %00001000 ; |    X   |
    .byte %00001110 ; |    XXX |
    .byte %00001010 ; |    X X |
    .byte %00001010 ; |    X X |
    .byte %00001110 ; |    XXX |
    .byte %00001000 ; |    X   |
    .byte %00001110 ; |    XXX |
    .byte %00000010 ; |      X |
    .byte %00001110 ; |    XXX |
    .byte %00001110 ; |    XXX |
    .byte %00001010 ; |    X X |
    .byte %00001110 ; |    XXX |
    .byte %00000010 ; |      X |
    .byte %00000010 ; |      X |
    .byte %00001000 ; |    X   |
    .byte %00001000 ; |    X   |
    .byte %00001000 ; |    X   |
    .byte %00001000 ; |    X   |
    .byte %00001110 ; |    XXX |
    .byte %00001110 ; |    XXX |
    .byte %00001010 ; |    X X |
    .byte %00001110 ; |    XXX |
    .byte %00001010 ; |    X X |
    .byte %00001110 ; |    XXX |
    .byte %00001000 ; |    X   |
    .byte %00001000 ; |    X   |
    .byte %00001110 ; |    XXX |
    .byte %00001010 ; |    X X |
    .byte %00001110 ; |    XXX |
Zero2:
    .byte %01110000 ; | XXX    | $dd64
    .byte %01010000 ; | X X    |
    .byte %01010000 ; | X X    |
    .byte %01010000 ; | X X    |
    .byte %01110000 ; | XXX    |
    .byte %01110000 ; | XXX    |
    .byte %00100000 ; |  X     |
    .byte %00100000 ; |  X     |
    .byte %01100000 ; | XX     |
    .byte %00100000 ; |  X     |
    .byte %01110000 ; | XXX    |
    .byte %01000000 ; | X      |
    .byte %01110000 ; | XXX    |
    .byte %00010000 ; |   X    |
    .byte %01110000 ; | XXX    |
    .byte %01110000 ; | XXX    |
    .byte %00010000 ; |   X    |
    .byte %00110000 ; |  XX    |
    .byte %00010000 ; |   X    |
    .byte %01110000 ; | XXX    |
    .byte %00010000 ; |   X    |
    .byte %00010000 ; |   X    |
    .byte %01110000 ; | XXX    |
    .byte %01010000 ; | X X    |
    .byte %01010000 ; | X X    |
    .byte %01110000 ; | XXX    |
    .byte %00010000 ; |   X    |
    .byte %01110000 ; | XXX    |
    .byte %01000000 ; | X      |
    .byte %01110000 ; | XXX    |
    .byte %01110000 ; | XXX    |
    .byte %01010000 ; | X X    |
    .byte %01110000 ; | XXX    |
    .byte %01000000 ; | X      |
    .byte %01000000 ; | X      |
    .byte %00010000 ; |   X    |
    .byte %00010000 ; |   X    |
    .byte %00010000 ; |   X    |
    .byte %00010000 ; |   X    |
    .byte %01110000 ; | XXX    |
    .byte %01110000 ; | XXX    |
    .byte %01010000 ; | X X    |
    .byte %01110000 ; | XXX    |
    .byte %01010000 ; | X X    |
    .byte %01110000 ; | XXX    |
    .byte %00010000 ; |   X    |
    .byte %00010000 ; |   X    |
    .byte %01110000 ; | XXX    |
    .byte %01010000 ; | X X    |
    .byte %01110000 ; | XXX    |
Zero3:
    .byte %00000111 ; |     XXX| $dd96
    .byte %00000101 ; |     X X|
    .byte %00000101 ; |     X X|
    .byte %00000101 ; |     X X|
    .byte %00000111 ; |     XXX|
    .byte %00000111 ; |     XXX|
    .byte %00000010 ; |      X |
    .byte %00000010 ; |      X |
    .byte %00000110 ; |     XX |
    .byte %00000010 ; |      X |
    .byte %00000111 ; |     XXX|
    .byte %00000100 ; |     X  |
    .byte %00000111 ; |     XXX|
    .byte %00000001 ; |       X|
    .byte %00000111 ; |     XXX|
    .byte %00000111 ; |     XXX|
    .byte %00000001 ; |       X|
    .byte %00000011 ; |      XX|
    .byte %00000001 ; |       X|
    .byte %00000111 ; |     XXX|
    .byte %00000001 ; |       X|
    .byte %00000001 ; |       X|
    .byte %00000111 ; |     XXX|
    .byte %00000101 ; |     X X|
    .byte %00000101 ; |     X X|
    .byte %00000111 ; |     XXX|
    .byte %00000001 ; |       X|
    .byte %00000111 ; |     XXX|
    .byte %00000100 ; |     X  |
    .byte %00000111 ; |     XXX|
    .byte %00000111 ; |     XXX|
    .byte %00000101 ; |     X X|
    .byte %00000111 ; |     XXX|
    .byte %00000100 ; |     X  |
    .byte %00000100 ; |     X  |
    .byte %00000001 ; |       X|
    .byte %00000001 ; |       X|
    .byte %00000001 ; |       X|
    .byte %00000001 ; |       X|
    .byte %00000111 ; |     XXX|
    .byte %00000111 ; |     XXX|
    .byte %00000101 ; |     X X|
    .byte %00000111 ; |     XXX|
    .byte %00000101 ; |     X X|
    .byte %00000111 ; |     XXX|
    .byte %00000001 ; |       X|
    .byte %00000001 ; |       X|
    .byte %00000111 ; |     XXX|
    .byte %00000101 ; |     X X|
    .byte %00000111 ; |     XXX|

Blank:
LifesTbl1:
    .byte %00000000 ; |        | $ddc8
    .byte %00000000 ; |        | $ddc9
    .byte %00000000 ; |        | $ddca
    .byte %00000000 ; |        | $ddcb
    .byte %00000000 ; |        | $ddcc
  IF ORIGINAL
    .byte %01111100 ; | XXXXX  | $ddcd
    .byte %00111000 ; |  XXX   | $ddce
    .byte %00111000 ; |  XXX   | $ddcf
    .byte %00010000 ; |   X    | $ddd0
    .byte %00010000 ; |   X    | $ddd1
    .byte %01111100 ; | XXXXX  | $ddd2
    .byte %00111000 ; |  XXX   | $ddd3
    .byte %00111000 ; |  XXX   | $ddd4
    .byte %00010000 ; |   X    | $ddd5
    .byte %00010000 ; |   X    | $ddd6
  ELSE
    .byte %01101100 ; | XX XX  | $ddcd
    .byte %00111000 ; |  XXX   | $ddce
    .byte %00101000 ; |  X X   | $ddcf
    .byte %00010000 ; |   X    | $ddd0
    .byte %00010000 ; |   X    | $ddd1
    .byte %01101100 ; | XX XX  | $ddd2
    .byte %00111000 ; |  XXX   | $ddd3
    .byte %00101000 ; |  X X   | $ddd4
    .byte %00010000 ; |   X    | $ddd5
    .byte %00010000 ; |   X    | $ddd6
  ENDIF
LifesTbl2:
    .byte %00000000 ; |        | $ddd7
    .byte %00000000 ; |        | $ddd8
    .byte %00000000 ; |        | $ddd9
    .byte %00000000 ; |        | $ddda
    .byte %00000000 ; |        | $dddb
    .byte %00000000 ; |        | $dddc
    .byte %00000000 ; |        | $dddd
    .byte %00000000 ; |        | $ddde
    .byte %00000000 ; |        | $dddf
    .byte %00000000 ; |        | $dde0
  IF ORIGINAL
    .byte %01111100 ; | XXXXX  | $dde1
    .byte %00111000 ; |  XXX   | $dde2
    .byte %00111000 ; |  XXX   | $dde3
    .byte %00010000 ; |   X    | $dde4
    .byte %00010000 ; |   X    | $dde5
  ELSE
    .byte %01101100 ; | XX XX  | $dde1
    .byte %00111000 ; |  XXX   | $dde2
    .byte %00101000 ; |  X X   | $dde3
    .byte %00010000 ; |   X    | $dde4
    .byte %00010000 ; |   X    | $dde5
  ENDIF

  IF GARBAGE
    .byte $b8, $4b, $be, $03, $bc, $0b, $fc, $cb
    .byte $54, $0b, $44, $bb, $54, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb
  ELSE
    align 256, 0
  ENDIF

HMSizeTbl:
; 8 ist used as corect flag for wrapping asteroids;
   IF ORIGINAL
    .byte $00|$8|DOUBLE_SIZE    ; $de00 large asteroid #1
    .byte $00|$8|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00
  ELSE
    .byte $00|$8|DOUBLE_SIZE    ; $de00
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
;    .byte $10|$8|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $00
  ENDIF

    .byte $00|$8|DOUBLE_SIZE    ; $de10 large asteroid #2
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $10|$8|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $00|$0|DOUBLE_SIZE
    .byte $f0|$0|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00|$8|DOUBLE_SIZE
    .byte $00

    .byte $08                   ; $de20 medium asteroid
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $00
  IF GARBAGE
   IF NTSC
    .byte $bc, $43, $fc, $4b, $bc, $4b, $f4, $0b
   ELSE
    .byte $bc, $43, $fc, $4b, $bc, $0b, $b4, $0b
   ENDIF
  ELSE
     ds 8, 0
  ENDIF

    .byte $08                   ; $de30 small asteroid
    .byte $08
    .byte $08
    .byte $08
    .byte $00
  IF GARBAGE
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb
  ELSE
     ds 11, 0
  ENDIF

    .byte $08                   ; $de40 large explosion
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $00
  IF GARBAGE
    .byte $3c, $4b, $b4, $0b
  ELSE
     ds 4, 0
  ENDIF

    .byte $08 ; $de50
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $00
  IF GARBAGE
    .byte $44, $bb, $44, $bb
  ELSE
     ds 4, 0
  ENDIF

    .byte $08 ; $de60
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $08
    .byte $00
  IF GARBAGE
   IF NTSC
    .byte $45, $ba, $43, $be, $4b, $b2, $4b
   ELSE
    .byte $45, $ba, $43, $be, $4a, $be, $4b
   ENDIF
  ELSE
     ds 7, 0
  ENDIF

    .byte $08 ; $de70
    .byte $08
    .byte $08
    .byte $08
    .byte $00

ColTbl:
; asteroid colors:
  IF NTSC
    .byte WHITE-2
    .byte RED+4
    .byte BLUE2+$c
    .byte YELLOW+8
    .byte BROWN+6
    .byte MAGENTA+6
    .byte BLUE1+6
    .byte OCHRE_GREEN+6
  ELSE
    .byte BLUE2+2
    .byte MAGENTA+4
    .byte BROWN+6
    .byte MAGENTA2+6
    .byte CYAN+8
    .byte BROWN+$a
    .byte RED+$c
    .byte WHITE
  ENDIF

; tables for displaying the remaining ships:
LifesOfsTbl:
    .byte $04, $04, $09, $0e, $0e, $0e, $0e, $0e
LifesHMoveTbl:
    .byte $55, $55, $25, $bc, $34, $cd, $45, $45
LifesNusizTbl:
    .byte ONE_COPY    <<4|ONE_COPY
    .byte ONE_COPY    <<4|ONE_COPY
    .byte ONE_COPY    <<4|ONE_COPY
    .byte ONE_COPY    <<4|ONE_COPY
    .byte ONE_COPY    <<4|TWO_COPIES
    .byte TWO_COPIES  <<4|TWO_COPIES
    .byte TWO_COPIES  <<4|THREE_COPIES
    .byte THREE_COPIES<<4|THREE_COPIES
LifesDelayTbl:
    .byte 0, 0, 2, 1, 1, 0, 0, 0

  IF GARBAGE
   IF NTSC
    .byte $bb, $44, $bb, $bb, $44, $bb, $45, $bb
    .byte $44, $ba, $41, $bf, $01, $b0, $43, $bc
    .byte $4b, $fc, $c3, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $bb, $44, $bb, $44, $bb
    .byte $45, $ba, $45, $ba, $45, $be, $23, $f4
    .byte $4b, $bc, $4b, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $bb, $44, $bb, $44, $bb
    .byte $45, $bb, $45, $be, $43, $be, $43, $bc
    .byte $0b, $b4, $4b, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb
   ELSE
    .byte $bb, $44, $bb, $bb, $44, $bb, $45, $bb
    .byte $44, $ba, $41, $bf, $01, $b8, $43, $bc
    .byte $4b, $fc, $c3, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $bb, $44, $bb, $44, $bb
    .byte $45, $ba, $45, $ba, $45, $be, $23, $f4
    .byte $4b, $bc, $4b, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $bb, $44, $bb, $44, $bb
    .byte $45, $bb, $45, $be, $43, $be, $43, $bc
    .byte $0b, $b4, $4b, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $44, $bb, $44, $bb, $44
    .byte $bb, $44, $bb
   ENDIF
  ELSE
    align 256, 0
  ENDIF

Asteroids:
  IF ORIGINAL
    .byte %00000000 ; |        | $df00
    .byte %00010000 ; |   X    |
    .byte %00011100 ; |   XXX  |
    .byte %00011110 ; |   XXXX |
    .byte %00111110 ; |  XXXXX |
    .byte %00111111 ; |  XXXXXX|
    .byte %01111111 ; | XXXXXXX|
    .byte %11111111 ; |XXXXXXXX|
    .byte %01111111 ; | XXXXXXX|
    .byte %11111111 ; |XXXXXXXX|
    .byte %01111111 ; | XXXXXXX|
    .byte %00111110 ; |  XXXXX |
    .byte %00111110 ; |  XXXXX |
    .byte %00011100 ; |   XXX  |
    .byte %00001100 ; |    XX  |
  IF GARBAGE
    .byte $43
  ELSE
    .byte 0
  ENDIF
    .byte %00000000 ; |        | $df10
    .byte %00111100 ; |  XXXX  |
    .byte %01111110 ; | XXXXXX |
    .byte %01111111 ; | XXXXXXX|
    .byte %00111111 ; |  XXXXXX|
    .byte %01111111 ; | XXXXXXX|
    .byte %11111111 ; |XXXXXXXX|
    .byte %11111110 ; |XXXXXXX |
    .byte %11111110 ; |XXXXXXX |
    .byte %01111111 ; | XXXXXXX|
    .byte %01111111 ; | XXXXXXX|
    .byte %00111111 ; |  XXXXXX|
    .byte %00111110 ; |  XXXXX |
    .byte %00111110 ; |  XXXXX |
    .byte %00011100 ; |   XXX  |
  IF GARBAGE
    .byte $bb
  ELSE
    .byte 0
  ENDIF
    .byte %00011000 ; |   XX   | $df20
    .byte %00111100 ; |  XXXX  |
    .byte %01111110 ; | XXXXXX |
    .byte %11111111 ; |XXXXXXXX|
    .byte %11111111 ; |XXXXXXXX|
    .byte %01111110 ; | XXXXXX |
    .byte %00001100 ; |    XX  |
  ELSE
    .byte %00000000 ; |        | $df00
    .byte %00001000 ; |    X   |
    .byte %00010100 ; |   X X  |
    .byte %00010010 ; |   X  X |
    .byte %00100010 ; |  X   X |
    .byte %00100001 ; |  X    X|
    .byte %01000001 ; | X     X|
    .byte %10000001 ; |X      X|
    .byte %01000001 ; | X     X|
    .byte %10000001 ; |X      X|
    .byte %01100001 ; | XX    X|
    .byte %00100010 ; |  X   X |
    .byte %00100010 ; |  X   X |
    .byte %00010100 ; |   X X  |
    .byte %00001100 ; |    XX  |
  IF GARBAGE
    .byte $43
  ELSE
    .byte 0
  ENDIF
    .byte %00000000 ; |        | $df10
    .byte %00111000 ; |  XXX   |
    .byte %01000110 ; | X   XX |
    .byte %01000001 ; | X     X|
    .byte %00100001 ; |  X    X|
    .byte %01000001 ; | X     X|
    .byte %10000010 ; |X     X |
    .byte %10000100 ; |X    X  |
    .byte %10000010 ; |X     X |
    .byte %01000010 ; | X    X |
    .byte %01000001 ; | X     X|
    .byte %00100001 ; |  X    X|
    .byte %00100010 ; |  X   X |
    .byte %00100010 ; |  X   X |
    .byte %00011100 ; |   XXX  |
  IF GARBAGE
    .byte $bb
  ELSE
    .byte 0
  ENDIF
    .byte %00111000 ; |  XXX   | $df20
    .byte %01000100 ; | X   X  |
    .byte %01000010 ; | X    X |
    .byte %10000001 ; |X      X|
    .byte %10000001 ; |X      X|
    .byte %01110010 ; | XXX  X |
    .byte %00001100 ; |    XX  |
  ENDIF

  IF GARBAGE
    .byte $43, $be, $4b, $bc, $4b, $b4, $5b, $b4
    .byte $5b
  ELSE
    ORG $df30
  ENDIF

  IF ORIGINAL
    .byte %01100000 ; | XX     | $df30
    .byte %11110000 ; |XXXX    |
    .byte %11110000 ; |XXXX    |
    .byte %00100000 ; |  X     |
  ELSE
    .byte %01100000 ; | XX     | $df30
    .byte %10010000 ; |X  X    |
    .byte %11010000 ; |XX X    |
    .byte %00100000 ; |  X     |
  ENDIF

  IF GARBAGE
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb
  ELSE
    ORG $df40
  ENDIF

; exploding asteroids:
    .byte %10100000 ; |X X     | $df40
    .byte %00000100 ; |     X  |
    .byte %01000000 ; | X      |
    .byte %00001001 ; |    X  X|
    .byte %00100000 ; |  X     |
    .byte %00000000 ; |        |
    .byte %10001000 ; |X   X   |
    .byte %00000001 ; |       X|
    .byte %00010000 ; |   X    |
    .byte %01000000 ; | X      |
    .byte %00010001 ; |   X   X|
  IF GARBAGE
    .byte $43, $b4, $4b, $b4, $4b
  ELSE
    ds 5, 0
  ENDIF
    .byte %01001000 ; | X  X   | $df50
    .byte %00000010 ; |      X |
    .byte %00100000 ; |  X     |
    .byte %10001000 ; |X   X   |
    .byte %00000001 ; |       X|
    .byte %01000000 ; | X      |
    .byte %00010100 ; |   X X  |
    .byte %01000000 ; | X      |
    .byte %00000000 ; |        |
    .byte %00100001 ; |  X    X|
    .byte %10000100 ; |X    X  |
  IF GARBAGE
    .byte $bb, $44, $bb, $44, $bb
  ELSE
    ds 5, 0
  ENDIF
    .byte %01010000 ; | X X    | $df60
    .byte %00000010 ; |      X |
    .byte %00100000 ; |  X     |
    .byte %10000001 ; |X      X|
    .byte %00000100 ; |     X  |
    .byte %01000000 ; | X      |
    .byte %00010000 ; |   X    |
    .byte %01000001 ; | X     X|
  IF GARBAGE
    .byte $bc, $41, $b4, $43, $b6, $49, $b0, $5b
  ELSE
    ds 8, 0
  ENDIF
    .byte %01000000 ; | X      | $df70
    .byte %00010000 ; |   X    | $df71
    .byte %10000000 ; |X       | $df72
    .byte %00100000 ; |  X     | $df73
Ship:
  IF ORIGINAL
    .byte %00010000 ; |   X    | $df74
    .byte %00010000 ; |   X    | $df75
    .byte %00111000 ; |  XXX   | $df76
    .byte %00111000 ; |  XXX   | $df77
    .byte %01111100 ; | XXXXX  | $df78
Ldf79:
    .byte %11111111 ; |XXXXXXXX| $df79
    .byte %00100000 ; |  X     | $df7a
    .byte %00110000 ; |  XX    | $df7b
    .byte %00111000 ; |  XXX   | $df7c
    .byte %00111100 ; |  XXXX  | $df7d
    .byte %00110000 ; |  XX    | $df7e
    .byte %11111111 ; |XXXXXXXX| $df7f
    .byte %01000000 ; | X      | $df80
    .byte %00110000 ; |  XX    | $df81
    .byte %00111100 ; |  XXXX  | $df82
    .byte %00011000 ; |   XX   | $df83
    .byte %00010000 ; |   X    | $df84
    .byte %11111111 ; |XXXXXXXX| $df85
    .byte %00000000 ; |        | $df86
    .byte %01000000 ; | X      | $df87
    .byte %00111110 ; |  XXXXX | $df88
    .byte %00011100 ; |   XXX  | $df89
    .byte %00001100 ; |    XX  | $df8a
    .byte %11111111 ; |XXXXXXXX| $df8b
    .byte %00000100 ; |     X  | $df8c
    .byte %00011100 ; |   XXX  | $df8d
    .byte %11111100 ; |XXXXXX  | $df8e
    .byte %00011100 ; |   XXX  | $df8f
    .byte %00000100 ; |     X  | $df90
    .byte %11111111 ; |XXXXXXXX| $df91
    .byte %00001100 ; |    XX  | $df92
    .byte %00011100 ; |   XXX  | $df93
    .byte %00111110 ; |  XXXXX | $df94
    .byte %01000000 ; | X      | $df95
    .byte %00000000 ; |        | $df96
    .byte %11111111 ; |XXXXXXXX| $df97
    .byte %00010000 ; |   X    | $df98
    .byte %00011000 ; |   XX   | $df99
    .byte %00111100 ; |  XXXX  | $df9a
    .byte %00110000 ; |  XX    | $df9b
    .byte %01000000 ; | X      | $df9c
    .byte %11111111 ; |XXXXXXXX| $df9d
    .byte %00110000 ; |  XX    | $df9e
    .byte %00111100 ; |  XXXX  | $df9f
    .byte %00111000 ; |  XXX   | $dfa0
    .byte %00110000 ; |  XX    | $dfa1
    .byte %00100000 ; |  X     | $dfa2
    .byte %11111111 ; |XXXXXXXX| $dfa3
    .byte %01111100 ; | XXXXX  | $dfa4
    .byte %00111000 ; |  XXX   | $dfa5
    .byte %00111000 ; |  XXX   | $dfa6
    .byte %00010000 ; |   X    | $dfa7
    .byte %00010000 ; |   X    | $dfa8
  ELSE
    .byte %00010000 ; |   X    | $df74
    .byte %00010000 ; |   X    | $df75
    .byte %00101000 ; |  XXX   | $df76
    .byte %00111000 ; |  XXX   | $df77
    .byte %01101100 ; | XXXXX  | $df78
Ldf79:
    .byte %11111111 ; |XXXXXXXX| $df79
    .byte %00100000 ; |  X     | $df7a
    .byte %00110000 ; |  XX    | $df7b
    .byte %00101000 ; |  XXX   | $df7c
    .byte %00101100 ; |  XXXX  | $df7d
    .byte %00110000 ; |  XX    | $df7e
    .byte %11111111 ; |XXXXXXXX| $df7f
    .byte %01000000 ; | X      | $df80
    .byte %00110000 ; |  XX    | $df81
    .byte %00101100 ; |  XXXX  | $df82
    .byte %00011000 ; |   XX   | $df83
    .byte %00010000 ; |   X    | $df84
    .byte %11111111 ; |XXXXXXXX| $df85
    .byte %00000000 ; |        | $df86
    .byte %01000000 ; | X      | $df87
    .byte %00111110 ; |  XXXXX | $df88
    .byte %00010100 ; |   XXX  | $df89
    .byte %00001100 ; |    XX  | $df8a
    .byte %11111111 ; |XXXXXXXX| $df8b
    .byte %00000100 ; |     X  | $df8c
    .byte %00011100 ; |   XXX  | $df8d
    .byte %11101000 ; |XXXXXX  | $df8e
    .byte %00011100 ; |   XXX  | $df8f
    .byte %00000100 ; |     X  | $df90
    .byte %11111111 ; |XXXXXXXX| $df91
    .byte %00001100 ; |    XX  | $df92
    .byte %00010100 ; |   XXX  | $df93
    .byte %00111110 ; |  XXXXX | $df94
    .byte %01000000 ; | X      | $df95
    .byte %00000000 ; |        | $df96
    .byte %11111111 ; |XXXXXXXX| $df97
    .byte %00010000 ; |   X    | $df98
    .byte %00011000 ; |   XX   | $df99
    .byte %00101100 ; |  XXXX  | $df9a
    .byte %00110000 ; |  XX    | $df9b
    .byte %01000000 ; | X      | $df9c
    .byte %11111111 ; |XXXXXXXX| $df9d
    .byte %00110000 ; |  XX    | $df9e
    .byte %00101100 ; |  XXXX  | $df9f
    .byte %00101000 ; |  XXX   | $dfa0
    .byte %00110000 ; |  XX    | $dfa1
    .byte %00100000 ; |  X     | $dfa2
    .byte %11111111 ; |XXXXXXXX| $dfa3
    .byte %01101100 ; | XXXXX  | $dfa4
    .byte %00111000 ; |  XXX   | $dfa5
    .byte %00101000 ; |  XXX   | $dfa6
    .byte %00010000 ; |   X    | $dfa7
    .byte %00010000 ; |   X    | $dfa8
  ENDIF
    .byte %11111111 ; |XXXXXXXX| $dfa9
Explosion:
    .byte %00010000 ; |   X    | $dfaa
    .byte %00000010 ; |      X | $dfab
    .byte %00001000 ; |    X   | $dfac
    .byte %00100010 ; |  X   X | $dfad
    .byte %00001000 ; |    X   | $dfae
    .byte %11111111 ; |XXXXXXXX| $dfaf
    .byte %00001000 ; |    X   | $dfb0
    .byte %00010000 ; |   X    | $dfb1
    .byte %10000000 ; |X       | $dfb2
    .byte %00000100 ; |     X  | $dfb3
    .byte %10100010 ; |X X   X | $dfb4
    .byte %11111111 ; |XXXXXXXX| $dfb5
    .byte %00100000 ; |  X     | $dfb6
    .byte %10000001 ; |X      X| $dfb7
    .byte %00100010 ; |  X   X | $dfb8
    .byte %00010000 ; |   X    | $dfb9
    .byte %00000100 ; |     X  | $dfba
    .byte %11111111 ; |XXXXXXXX| $dfbb
Shield:
    .byte %00111000 ; |  XXX   | $dfbc
    .byte %01000100 ; | X   X  | $dfbd
    .byte %01010100 ; | X X X  | $dfbe
    .byte %01000100 ; | X   X  | $dfbf
    .byte %00111000 ; |  XXX   | $dfc0
    .byte %11111111 ; |XXXXXXXX| $dfc1
UFO:
  IF ORIGINAL
    .byte %00010000 ; |   X    | $dfc2
    .byte %01111100 ; | XXXXX  | $dfc3
    .byte %00111000 ; |  XXX   | $dfc4
    .byte %11111111 ; |XXXXXXXX| $dfc5
Sattelite:
    .byte %00010000 ; |   X    | $dfc6
    .byte %00111000 ; |  XXX   | $dfc7
    .byte %11111110 ; |XXXXXXX | $dfc8
    .byte %01111100 ; | XXXXX  | $dfc9
    .byte %00111000 ; |  XXX   | $dfca
    .byte %11111111 ; |XXXXXXXX| $dfcb
  ELSE
    .byte %00010000 ; |   X    | $dfc2
    .byte %01101100 ; | XX XX  | $dfc3
    .byte %00111000 ; |  XXX   | $dfc4
    .byte %11111111 ; |XXXXXXXX| $dfc5
Sattelite:
    .byte %00010000 ; |   X    | $dfc6
    .byte %00101000 ; |  X X   | $dfc7
    .byte %11000110 ; |XX   XX | $dfc8
    .byte %01000100 ; | X   X  | $dfc9
    .byte %00111000 ; |  XXX   | $dfca
    .byte %11111111 ; |XXXXXXXX| $dfcb
  ENDIF

  IF GARBAGE
   IF NTSC
    .byte $b4, $cb, $74, $8b, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $4c, $be, $43, $be, $40
    .byte $b4, $49, $b6, $0b
   ELSE
    .byte $b4, $cb, $74, $8b, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $44, $bb, $44, $bb
    .byte $44, $bb, $44, $bb, $bb, $44, $bb, $44
    .byte $bb, $44, $bb, $4c, $be, $43, $be, $41
    .byte $b4, $49, $b6, $0b
   ENDIF
  ELSE
    ORG $dff0
  ENDIF

    ORG     $dfe0

SwitchBank1:
    sta    BANK1            ; 4
    jmp    (bswVec)         ; 5

  IF GARBAGE
   IF NTSC
    .byte $44, $bb, $44, $b9
   ELSE
    .byte $44, $bb, $44, $ff
   ENDIF
  ELSE
    ORG $dffa, 0
  ENDIF
    .word START0, START0, START0


;===============================================================================
; R O M - C O D E (Bank 1)
;===============================================================================

    ORG     $e000
    RORG    $f000
    .byte "api.php", #0
    .byte "highscore.firmaplus.de", #0

Lf100 = $f100

OverScan:
    ldx    #$ff             ; 2
    txs                     ; 2
  IF NTSC
    lda    #$24             ; 2
    sta    TIM64T           ; 4
    lda    SWCHB            ; 4
    ror                     ; 2
    ror                     ; 2
  ELSE
   IF ORIGINAL && !PLUSROM
    lda    #$2c             ; 2
    sta    TIM64T           ; 4
    lda    SWCHB            ; 4
    ror                     ; 2
    ror                     ; 2
   ELSE
    lda    SWCHB            ; 4     fixes scanline problems
    ror                     ; 2
    ror                     ; 2
    lda    #$2c             ; 2
    sta    TIM64T           ; 4
   ENDIF
  ENDIF
    bcs    .skipSelect      ; 2³
    bit    game             ; 3
    bvs    Lf035            ; 2³
    lda    game             ; 3
    ora    #$40             ; 2
    sta    game             ; 3
    lda    flags            ; 3
    ora    #SELECT_FLAG     ; 2
    sta    flags            ; 3
    lda    flags2           ; 3
    ora    #GAME_OVER       ; 2
    sta    flags2           ; 3
    lda    #Y_ILLEGAL       ; 2
    sta    yShip            ; 3
    sta    yUFO             ; 3
    lda    #$00             ; 2
    sta    frameCnt         ; 3
    sta    frameCntHi       ; 3
    sta    lifesDir         ; 3
    sta    lifesDir2        ; 3
Lf035:
    lda    SWCHB            ; 4
    ror                     ; 2
    lda    frameCnt         ; 3
    and    #$3f             ; 2
    bcs    Lf041            ; 2³
    and    #$0f             ; 2
Lf041:
    bne    .noAdjust        ; 2³

; convert game number (extra values for child games!)
    inc    game             ; 5
    lda    game             ; 3
    ldx    #4               ; 2
.loopAdjust:
    dex                     ; 2
    bmi    .noAdjust        ; 2³
    cmp    AdjustFromTbl,x  ; 4
    bne    .loopAdjust      ; 2³
    lda    AdjustToTbl,x    ; 4
    sta    game             ; 3
.noAdjust:
    jmp    .skipReset       ; 3

.skipSelect:
    lda    game             ; 3
    and    #$bf             ; 2
    sta    game             ; 3
    lda    SWCHB            ; 4
    ror                     ; 2
    bcs    .skipReset       ; 2³

; start new game:
    lda    #$00             ; 2
    sta    COLUBK           ; 3
    ldx    #yPosLst         ; 2
.loopClear:
    sta    $00,x            ; 4
    inx                     ; 2
    bne    .loopClear       ; 2³
    lda    #$40             ; 2         4 lifes
    sta    lifesDir         ; 3
    sta    lifesDir2        ; 3
  IF NTSC
    lda    #H_KERNEL/2-3    ; 2
  ELSE
    lda    #H_KERNEL/2-5    ; 2
  ENDIF
    sta    yShip            ; 3
    jmp    StartNewGame     ; 3

.skipReset:
; find first lower empty object-slot:
    ldx    #0               ; 2
.loopLower:
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    .exitLower       ; 2³
    inx                     ; 2
    bpl    .loopLower       ; 3

.exitLower:
    cpx    #0               ; 2
    beq    .zero            ; 2³
    dex                     ; 2
.zero:
    stx    lwrBound         ; 3

; find first upper empty object-slot:
    ldx    #NUM_ASTEROIDS_2 ; 2
.loopUpper:
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    .exitUpper       ; 2³
    inx                     ; 2
    bpl    .loopUpper       ; 3

.exitUpper:
    cpx    #NUM_ASTEROIDS_2 ; 2
    beq    .max             ; 2³
    dex                     ; 2
.max:
    stx    uprBound         ; 3

; check if lower or upper object-slots are used:
    ldx    #0               ; 2
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    bne    .contLevel       ; 2³
    ldx    #NUM_ASTEROIDS_2 ; 2
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    bne    .contLevel       ; 2³
; no more asteroids, start new level:
    jsr    SetupAsteroids   ; 6
    jmp    .endCollisions   ; 3

.contLevel:
    lda    asteroidHit      ; 3
    bne    .cxAsteroids     ; 2³+1
    bit    flags2           ; 3         shield enabled?
    bvs    Lf0ce            ; 2³         yes
    lda    flags2           ; 3
    ror                     ; 2         game over?
    bcs    .endCollisionsJmp; 2³+1       yes
    lda    yShip            ; 3
    cmp    #Y_ILLEGAL       ; 2
    bne    .checkCollisions ; 2³+1
    lda    ftrTimer         ; 3
    beq    Lf0df            ; 2³
Lf0ce:
    lda    yUFO             ; 3
    cmp    #Y_ILLEGAL       ; 2
    bne    .checkCollisions ; 2³+1
    lda    dirShot1         ; 3         any shots?
    ora    dirShot2         ; 3
    ora    dirShotUfo       ; 3
    bne    .checkCollisions ; 2³+1       yes,
    jmp    .endCollisions   ; 3

Lf0df:
    lda    flags2           ; 3
    and    #KILL_FLAG       ; 2         ship killed?
    beq    Lf0fd            ; 2³         no
    lda    yUFO             ; 3
    cmp    #Y_ILLEGAL       ; 2
    bne    .checkCollisions ; 2³+1
    lda    dirShotUfo       ; 3
    bne    .checkCollisions ; 2³+1
    ldx    #0               ; 2
    jsr    CheckSpace       ; 6
    bne    .endCollisionsJmp; 2³+1
    ldx    #NUM_ASTEROIDS_2 ; 2
    jsr    CheckSpace       ; 6
    bne    .endCollisionsJmp; 2³+1
Lf0fd:
    lda    yShipNew         ; 3
    sta    yShip            ; 3

; stop ship:
    lda    #0               ; 2
    ldx    #5               ; 2
.loopStop:
    sta    speedLst,x       ; 4
    dex                     ; 2
    bpl    .loopStop        ; 2³
    lda    game             ; 3
    and    #TWO_PLAYERS     ; 2
    bne    .twoPlayer       ; 2³
    sta    lifesDir2        ; 3         no 2nd player, no lifes
    beq    .endCollisionsJmp; 3

.twoPlayer:
    lda    lifesDir2        ; 3         other player still alive?
    beq    .endCollisionsJmp; 2³         no, skip swapping players
    lda    flags2           ; 3
    and    #KILL_FLAG       ; 2         ship killed?
    beq    .endCollisionsJmp; 2³         no, skip swapping
    jsr    SwapPlayers      ; 6
    lda    #Y_ILLEGAL       ; 2         disable first
    sta    yPosLst          ; 3          up and low moving
    sta    yPosLst+NUM_ASTEROIDS_2; 3      asteroids
    lda    #0               ; 2
    sta    lwrBound         ; 3
    lda    #NUM_ASTEROIDS_2 ; 2
    sta    uprBound         ; 3
.endCollisionsJmp:
    jmp    .endCollisions   ; 3

; ******************** C O L L I S I O N S (start) ********************
.checkCollisions:
    lda    asteroidHit      ; 3
    beq    .cxObjects       ; 2³
.cxAsteroids:
; check down moving asteroids:
    ldx    lwrBound         ; 3
    stx    $f5              ; 3
    ldx    #0               ; 2
    jsr    AsteroidHit      ; 6
    stx    lwrBound         ; 3
; check up moving asteroids:
    ldx    uprBound         ; 3
    stx    $f5              ; 3
    ldx    #NUM_ASTEROIDS_2 ; 2
    jsr    AsteroidHit      ; 6
    stx    uprBound         ; 3

    lda    #0               ; 2
    sta    asteroidHit      ; 3         no asteroid hit
    beq    .endCollisionsJmp; 3

.cxObjects:                 ;           every 2nd frame
    lda    cxTimer          ; 3
    bit    cxTimer          ; 3
    bpl    .cxOther         ; 2³        branch every 4th frame
    eor    #$c0             ; 2
    sta    cxTimer          ; 3
    bvc    .cxShot2         ; 2³        branch every 8th frame
; check for shot 1 with asteroids/UFO collisions:
    lda    dirShot1         ; 3         shot enabled?
    beq    .cxObjects       ; 2³         no, try other objects
    lda    yShot1           ; 3
    ldy    xShot1           ; 3
    ldx    #ID_SHOT1        ; 2
    jsr    CXAsteroids      ; 6

    ldy    yUFO             ; 3
    cpy    #Y_ILLEGAL       ; 2
    beq    .skipUfo1        ; 2³
    jsr    CheckUFO         ; 6
    ldy    xUFO             ; 3
    jsr    Lfba9            ; 6
.skipUfo1:
    jmp    .endCollisions   ; 3

.cxShot2:
; check for shot 2 with asteroids/UFO collisions:
    lda    dirShot2         ; 3         shot enabled?
    beq    .cxObjects       ; 2³         no, try other objects
    lda    yShot2           ; 3
    ldy    xShot2           ; 3
    ldx    #ID_SHOT2        ; 2
    jsr    CXAsteroids      ; 6

    ldy    yUFO             ; 3
    cpy    #Y_ILLEGAL       ; 2
    beq    .skipUfo2        ; 2³
    jsr    CheckUFO         ; 6
    ldy    xUFO             ; 3
    jsr    Lfba9            ; 6
.skipUfo2:
    jmp    .endCollisions   ; 3

.cxOther:                   ;           every 4th frame
    and    #$03             ; 2         a = cxTimer
    tax                     ; 2
    inc    cxTimer          ; 5
    lda    cxTimer          ; 3
    ora    #$80             ; 2         other branch next time
    tay                     ; 2
    and    #$03             ; 2
    cmp    #$03             ; 2
    bne    .reset3          ; 2³
    tya                     ; 2
    and    #~$03            ; 2
    tay                     ; 2
.reset3:
    sty    cxTimer          ; 3
    dex                     ; 2
    bmi    .cxUFOShot       ; 2³        check UFOShot
    dex                     ; 2
    bmi    .cxUFO           ; 2³        check UFO
    bit    flags2           ; 3         shield enabled?
    bvc    cxShip           ; 2³         no, check ship
.cxObjectsJmp:
    jmp    .cxObjects       ; 3          yes, try player shots instead!

cxShip:                     ;           every 12 frame
; check for ship with asteroids/UFO collisions:
    lda    ftrTimer         ; 3
    bmi    .skipUfoShip     ; 2³
    ldy    xShip            ; 3
    ldx    #ID_SHIP         ; 2
    lda    yShip            ; 3
    jsr    CXAsteroids      ; 6

    ldy    yUFO             ; 3
    cpy    #Y_ILLEGAL       ; 2
    beq    .skipUfoShip     ; 2³
    jsr    CheckUFO         ; 6
    ldy    xUFO             ; 3
    jsr    Lfba9            ; 6
.skipUfoShip:
    jmp    .endCollisions   ; 3

.cxUFO:                     ;           every 12 frame
; check for UFO with asteroids collisions:
    ldy    yUFO             ; 3
    cpy    #Y_ILLEGAL       ; 2         UFO enabled?
    beq    .cxObjectsJmp    ; 2³         no, try player shots instead!
    jsr    CheckUFO         ; 6
    ldy    xUFO             ; 3
    jsr    CXAsteroids      ; 6
    jmp    .endCollisions   ; 3

.cxUFOShot:                 ;           every 12 frame
; check for UFO shot with asteroids/ship collisions:
    lda    dirShotUfo       ; 3         UFO shot enabled?
    beq    .cxObjectsJmp    ; 2³         no, try player shots instead!
    lda    yShotUfo         ; 3
    ldy    xShotUfo         ; 3
    ldx    #ID_SHOT_UFO     ; 2
    jsr    CXAsteroids      ; 6

    ldy    yShip            ; 3
    cpy    #Y_ILLEGAL       ; 2
    beq    .endCollisions   ; 2³+1
    bit    flags2           ; 3         shield enabled?
    bvs    .endCollisions   ; 2³         yes
    lda    ftrTimer         ; 3
    bmi    .endCollisions   ; 2³
    ldx    #ID_SHIP         ; 2
    tya                     ; 2
    ldy    xShip            ; 3
    jsr    Lfba9            ; 6
.endCollisions:
; ******************** C O L L I S I O N S (end) ********************

; ******************** S O U N D (start) ********************
  SUBROUTINE
.tmpSound   = $f4

    lda    flags2           ; 3
    ror                     ; 2         game over?
    bcc    .doSounds        ; 2³         no,
    lda    #$00             ; 2
    sta    AUDV0            ; 3
    sta    AUDV1            ; 3
    jmp    EndSound         ; 3

.doSounds:
    lda    soundBits        ; 3
    sta    .tmpSound        ; 3
; set audio channel 0:
    ldy    #$08             ; 2
    ror    .tmpSound        ; 5         (bit 0)
    bcc    Lf240            ; 2³
    lda    frameCnt         ; 3
    ror                     ; 2
    bcs    Lf238            ; 2³
    dec    soundTimer0      ; 5
    bne    Lf238            ; 2³
    lda    soundBits        ; 3
    and    #~SOUND_KILL     ; 2
    sta    soundBits        ; 3
    bcc    Lf240            ; 3

Lf238:
    ror    .tmpSound        ; 5         thrust sound?
    ldx    #$1f             ; 2
    lda    soundTimer0      ; 3
    bpl    .setSound0       ; 3

Lf240:                      ;
    ror    .tmpSound        ; 5         thrust sound? (bit 1)
    bcc    .noSound0        ; 2³         no
    ldx    #$08             ; 2
    lda    #$06             ; 2
    bpl    .setSound0       ; 3

.noSound0:
    lda    #$00             ; 2
.setSound0:
    sty    AUDC0            ; 3
    stx    AUDF0            ; 3
    sta    AUDV0            ; 3

; set audio channel 1:
    ror    .tmpSound        ; 5         (bit 2)
    bcc    Lf274            ; 2³
    ldx    #$04             ; 2
    ldy    #$0f             ; 2
    lda    soundTimer1      ; 3
    and    #$10             ; 2
    beq    Lf262            ; 2³
    ldy    #$00             ; 2
Lf262:
    tya                     ; 2
    ldy    #$04             ; 2
    dec    soundTimer1      ; 5
    bne    .setSound1       ; 2³
    lda    soundBits        ; 3
    and    #$eb             ; 2
    sta    soundBits        ; 3
    inc    soundTimer1      ; 5
    jmp    Lf2a4            ; 3

Lf274:
    ror    .tmpSound        ; 5         UFO active? (bit 3)
    bcc    Lf290            ; 2³         no,
    ldx    #$08             ; 2
    lda    flags            ; 3
    and    #UFO_FLAG        ; 2         UFO sound?
    bne    Lf282            ; 2³         yes
    ldx    #$10             ; 2          no, Sattelite sound
Lf282:
    lda    frameCnt         ; 3
    and    #$02             ; 2
    beq    Lf28a            ; 2³
    dex                     ; 2
    dex                     ; 2
Lf28a:
    ldy    #$0c             ; 2
    lda    #$08             ; 2
    bpl    .setSound1       ; 3

Lf290:
    ror    .tmpSound        ; 5         (bit 4)
    bcc    Lf2ca            ; 2³
    dec    soundTimer1      ; 5
    bne    Lf2ab            ; 2³
    lda    soundBits        ; 3
    and    #~[SOUND_ENEMY]  ; 2
    ora    #$60             ; 2
    sta    soundBits        ; 3
    lda    #$08             ; 2
    sta    soundTimer1      ; 3
Lf2a4:
    lda    #$00             ; 2
    sta    AUDV1            ; 3
    jmp    EndSound         ; 3

Lf2ab:
    ldy    #$0c             ; 2
    lda    soundTimer1      ; 3
    cmp    #$08             ; 2
    bcc    Lf2ba            ; 2³
    lda    frameCnt         ; 3
    ror                     ; 2
    bcc    Lf2ba            ; 2³
    ldy    #$08             ; 2
Lf2ba:
    lda    #$0f             ; 2
    sec                     ; 2
    sbc    soundTimer1      ; 3
    tax                     ; 2
    lda    #$0d             ; 2
.setSound1:
    sty    AUDC1            ; 3
    stx    AUDF1            ; 3
    sta    AUDV1            ; 3
    bpl    EndSound         ; 3+1

Lf2ca:
    ldy    #$06             ; 2
    dec    soundTimer1      ; 5
    bne    Lf2f5            ; 2³
    lda    soundBits        ; 3
    and    #$9f             ; 2
    ror    .tmpSound        ; 5         (bit 5)
    bcs    Lf308            ; 2³+1
    ora    #$20             ; 2
    ror    .tmpSound        ; 5
    bcc    Lf2e0            ; 2³        (bit 6)
    ora    #$40             ; 2
Lf2e0:
    sta    soundBits        ; 3
    lda    frameCntHi       ; 3
    bmi    Lf2f1            ; 2³
  IF NTSC
    lda    #14              ; 2
  ELSE
    lda    #12              ; 2
  ENDIF
    sec                     ; 2
    sbc    frameCntHi       ; 3
    bmi    Lf2f1            ; 2³
  IF NTSC
    cmp    #6               ; 2
  ELSE
    cmp    #4               ; 2
  ENDIF
    bcs    Lf2f3            ; 2³
Lf2f1:
  IF NTSC
    lda    #6               ; 2
  ELSE
    lda    #4               ; 2
  ENDIF
Lf2f3:
    sta    soundTimer1      ; 3
Lf2f5:
    lda    soundBits        ; 3
    rol                     ; 2
    rol                     ; 2
    bmi    Lf2ff            ; 2³
    lda    #$00             ; 2
    beq    .setSound1       ; 3

Lf2ff:
    ldx    #$13             ; 2
    bcc    Lf304            ; 2³
    inx                     ; 2
Lf304:
    lda    #$0c             ; 2
    bpl    .setSound1       ; 3+1

Lf308:
    ror    .tmpSound        ; 5         (bit 7)
    bcs    Lf30e            ; 2³
    ora    #$40             ; 2
Lf30e:
    sta    soundBits        ; 3
  IF NTSC
    lda    #$08             ; 2
  ELSE
    lda    #$06             ; 2
  ENDIF
    sta    soundTimer1      ; 3
    bpl    Lf2f5            ; 2³+1
EndSound:
; ******************** S O U N D (end) ********************

; ******************** V S Y N C (start) ********************
    ldx    #$ff             ; 2
Lf318:
    lda    INTIM            ; 4
    bne    Lf318            ; 2³
  IF ORIGINAL
    stx    VBLANK           ; 3
    stx    VSYNC            ; 3
  ELSE
    stx    VSYNC            ; 3
    stx    VBLANK           ; 3
  ENDIF
    sta    WSYNC            ; 3
    sta    WSYNC            ; 3
    sta    WSYNC            ; 3
    sta    VSYNC            ; 3
    sta    VBLANK           ; 3
; ******************** V S Y N C (end) ********************

  IF NTSC
    lda    #$2d             ; 2
  ELSE
    lda    #$35             ; 2
  ENDIF
    sta    TIM64T           ; 4
    inc    frameCnt         ; 5
    bne    .skipSwap        ; 2³
    inc    frameCntHi       ; 5
    bit    flags            ; 3         select mode?
    bvs    .skipSwap        ; 2³         yes,
    lda    flags2           ; 3
    ror                     ; 2         game over?
    bcc    .skipSwap        ; 2³         yes,
    lda    frameCntHi       ; 3
    bpl    Lf349            ; 2³
    lda    flags            ; 3
    ora    #SELECT_FLAG     ; 2
    sta    flags            ; 3
Lf349:
    lda    game             ; 3
    and    #TWO_PLAYERS     ; 2         two player game?
    beq    .skipSwap        ; 2³         no
    jsr    SwapPlayers      ; 6

.skipSwap:
    jsr    NextRandom       ; 6
  IF ORIGINAL
    lda    frameCnt         ; 3
    ror                     ; 2
  ELSE
    jsr    CheckDriving
  ENDIF
    bcs    .oddFrame        ; 2³
    jmp    .evenFrame       ; 3

; ******************** A S T E R O I D S (start) ********************
.oddFrame:
; *** countdown timers ***
    ldy    #0               ; 2
    lda    gameSpeed        ; 3
    sec                     ; 2
    sbc    #$11             ; 2
    cmp    #$10             ; 2
    bcs    .skipResetHi     ; 2³
    ora    #SPEED_SLOW      ; 2         $70..$00/$50..$00
    iny                     ; 2
    iny                     ; 2
.skipResetHi:
    tax                     ; 2
    and    #$0f             ; 2
    bne    skipResetLo      ; 2³
    txa                     ; 2
    ora    #SPEED_MEDIUM    ; 2         $03..$00/$02..$00
    tax                     ; 2
    iny                     ; 2
skipResetLo:
    stx    gameSpeed        ; 3
    tya                     ; 2         a = 0..3
    ror                     ; 2
    ror                     ; 2
    ror                     ; 2
    sta    moveBits         ; 3         = $00, $40, $80, $c0

    lda    #<Ld0c0          ; 2
    sta    jmpVec1          ; 3
    lda    #<Ld1cf          ; 2
    sta    jmpVec2          ; 3
    lda    #>HMSizeTbl      ; 2
    sta    ptr4+1           ; 3

; *** move up-moving asteroids ***
    ldx    #NUM_ASTEROIDS_2 ; 2
.loopUpr:
; loop until illegal y-position:
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    .exitLoopUpr     ; 2³
    inc    yPosLst,x        ; 6         move asteroid up
    jsr    XMoveAsteroids   ; 6         move asteroid left or right
    inx                     ; 2
    bne    .loopUpr         ; 2³

.exitLoopUpr:
    ldx    uprBound         ; 3
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    .setupMove1      ; 2³+1
    cmp    #H_KERNEL        ; 2
    bcc    .checkWrapYUpr   ; 2³
    lda    #Y_ILLEGAL       ; 2
    sta    yPosLst,x        ; 4
    dec    uprBound         ; 5
    bne    .exitLoopUpr     ; 3

.checkWrapYUpr:
; check if asteroid reached upper screen border:
    lda    flagLst,x        ; 4
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    and    #[SIZE_BITS>>4]  ; 2
    tay                     ; 2         y = asteroids size id
    lda    yPosLst,x        ; 4
    cmp    UprBoundTbl,y    ; 4         at upper border?
    bne    .skipInsert      ; 2³         no, skip
    stx    $f5              ; 3          yes, save id
    lda    #NUM_ASTEROIDS_2 ; 2         set bound
    sta    $f4              ; 3
    jsr    InsertIntoLst    ; 6         insert into list
    lda    yPosLst,y        ; 4
    sec                     ; 2
    sbc    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4         correct y-position
.skipInsert:

    ldx    #NUM_ASTEROIDS_2 ; 2
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    .setupMove1      ; 2³+1
    lda    xPosLst,x        ; 4
    sta    fineMove1        ; 3
    lsr                     ; 2
    and    #$07             ; 2
    sta    coarseMove1      ; 3         store delay
    lda    yPosLst,x        ; 4
    bpl    .setupMove1      ; 2³+1
    cmp    #$ff             ; 2
    beq    .setupMove1      ; 2³+1
    lda    xPosLst,x        ; 4
    ror                     ; 2
    ldy    #<XPosP1_l       ; 2
    bcs    Lf3f1            ; 2³
    ldy    #<XPosP1_r       ; 2
Lf3f1:
    sty    jmpVec2          ; 3
    lda    flagLst,x        ; 4
    and    #TYPE_BITS       ; 2
    sec                     ; 2
    sbc    #$02             ; 2
    sec                     ; 2
    sbc    yPosLst,x        ; 4
    sta    ptr2             ; 3
    sta    ptr4             ; 3
    ldy    #>GetHMSizeTbl1  ; 2
    sty    bswVec+1         ; 3
    ldy    #<GetHMSizeTbl1  ; 2
    sty    bswVec           ; 3
    jmp    SwitchBank0      ; 3

RetHMSizeTbl1:
    and    #$08             ; 2         correction flags set?
    bne    .setupMove1      ; 2³         no, skip
    lda    fineMove1        ; 3          yes
    clc                     ; 2
    adc    #$10             ; 2
    sta    fineMove1        ; 3         move one pixel left
.setupMove1:
    lda    xPosLst          ; 3
    sta    fineMove0        ; 3
    lsr                     ; 2
    and    #$07             ; 2
    sta    coarseMove0      ; 3

; *** move down-moving asteroids ***
    ldx    #0               ; 2
    beq    Lf42a            ; 3

.loopLwr:
    dec    yPosLst,x        ; 6         move asteroid down
.loopLwrB:
    jsr    XMoveAsteroids   ; 6         move asteroid left or right
    inx                     ; 2
Lf42a:
    lda    yPosLst,x        ; 4
    beq    Lf436            ; 2³
    bpl    .loopLwr         ; 2³
    cmp    #Y_ILLEGAL       ; 2
    beq    .hasUFOs         ; 2³
    bne    .yWrapTopLwr     ; 3

Lf436:
    ldx    lwrBound         ; 3
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    Lf43f            ; 2³
    inx                     ; 2
Lf43f:
    lda    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4
    lda    xPosLst          ; 3
    sta    xPosLst,x        ; 4
    lda    flagLst          ; 3
    sta    flagLst,x        ; 4
    lda    #Y_ILLEGAL       ; 2
    sta    yPosLst+1,x      ; 4
    inc    lwrBound         ; 5
    ldx    #0               ; 2
    beq    .loopLwr         ; 3

.yWrapTopLwr:
; y-wrap top down-moving asteroid:
    dec    yPosLst          ; 5
    lda    flagLst          ; 3
    ror                     ; 2
    ror                     ; 2
    ror                     ; 2
    ror                     ; 2
    and    #[SIZE_BITS>>4]  ; 2
    tay                     ; 2
    lda    yPosLst          ; 3
    cmp    LwrBoundTbl,y    ; 4
    beq    Lf498            ; 2³
    lda    flagLst          ; 3
    and    #TYPE_BITS       ; 2
    sec                     ; 2
    sbc    yPosLst          ; 3
    sec                     ; 2
    sbc    #$02             ; 2
    sta    ptr1             ; 3
    sta    ptr3             ; 3
    ldy    #>GetHMSizeTbl0  ; 2
    sty    bswVec+1         ; 3
    ldy    #<GetHMSizeTbl0  ; 2
    sty    bswVec           ; 3
    jmp    SwitchBank0      ; 3

RetHMSizeTbl0:
    and    #$08             ; 2         correction flag set?
    bne    Lf48b            ; 2³
    lda    fineMove0        ; 3
    clc                     ; 2
    adc    #$10             ; 2         move 1 pixel left
    sta    fineMove0        ; 3
Lf48b:
    ldy    #<XPosP0_l       ; 2
    lda    xPosLst          ; 3
    ror                     ; 2
    bcs    Lf494            ; 2³
    ldy    #<XPosP0_r       ; 2
Lf494:
    sty    jmpVec1          ; 3
    bne    .loopLwrB        ; 3

Lf498:
    jsr    RemoveFromLst    ; 6
    jmp    .setupMove1      ; 3

.hasUFOs:
; check if enemies (UFO/sattelite) allowed:
    lda    SWCHB            ; 4         UFO game?
    bit    flags            ; 3         player 2?
    bmi    .player2UFO      ; 2³         yes
    asl                     ; 2
.player2UFO:
    asl                     ; 2
    bcs    .doUFOs          ; 2³
    lda    soundBits        ; 3
    and    #~SOUND_UFO      ; 2
    jmp    Lf560            ; 3

.doUFOs:
    lda    yUFO             ; 3
    cmp    #Y_ILLEGAL       ; 2         UFO active?
    bne    .moveUFO         ; 2³+1       yes, skip
    lda    yShip            ; 3
    cmp    #Y_ILLEGAL       ; 2         ship inactive?
    beq    .endMakeUFO      ; 2³+1       yes, skip
    lda    #$03             ; 2
    cmp    frameCntHi       ; 3
    bcs    .endMakeUFO      ; 2³+1
    dec    $c6              ; 5
    bne    .endMakeUFO      ; 2³+1
    lda    soundBits        ; 3         enable UFO sound
    ora    #SOUND_UFO       ; 2
    sta    soundBits        ; 3

; create new UFO (position/drection):
    jsr    NextRandom       ; 6
    lsr                     ; 2
    tax                     ; 2
    and    #UFO_DIR_FLAGS   ; 2
    sta    $f4              ; 3
    lda    flags            ; 3
    and    #~[UFO_DIR_FLAGS|UFO_LEFT]; 2
    ora    $f4              ; 3
    bcc    .rightUFO        ; 2³
    ora    #UFO_LEFT        ; 2
.rightUFO:
    sta    flags            ; 3
    lda    #186             ; 2
    sta    xUFO             ; 3
    txa                     ; 2
    cmp    #H_KERNEL-10     ; 2
    beq    .yUFOok          ; 2³
    bcc    .yUFOok          ; 2³
    sbc    #H_KERNEL-10     ; 2
.yUFOok:
    sta    yUFO             ; 3

; check for new UFO type:
    lda    scoreHigh        ; 3
    cmp    #$15             ; 2         15,000?
    bcs    .makeUFO         ; 2³+1
    cmp    #$07             ; 2          7,000?
    bcc    .makeSattelite   ; 2³
    jsr    NextRandom       ; 6
    ror                     ; 2
    bcc    .makeUFO         ; 2³+1
.makeSattelite:
    lda    flags            ; 3
    and    #~UFO_FLAG       ; 2
    sta    flags            ; 3
.endMakeUFO:
    jmp    Lf5b8            ; 3

.makeUFO:
    lda    flags            ; 3
    ora    #UFO_FLAG        ; 2
    sta    flags            ; 3
    bne    .endMakeUFO      ; 3

.moveUFO:
    lda    flags            ; 3
    and    #UFO_DIR_FLAGS   ; 2
    beq    .horzUFO         ; 2³        horizontal
    cmp    #UFO_DIR_FLAGS   ; 2
    beq    .horzUFO         ; 2³
    cmp    #$02             ; 2         down (2)
    beq    .downUFO         ; 2³
    inc    yUFO             ; 5         up (4)
    lda    yUFO             ; 3
    cmp    #H_KERNEL-10     ; 2
    bne    Lf536            ; 2³
    beq    .invertUFOdir    ; 3

.downUFO:
    dec    yUFO             ; 5
    bne    Lf536            ; 2³
.invertUFOdir:
    lda    flags            ; 3
    eor    #UFO_DIR_FLAGS   ; 2
    sta    flags            ; 3
    jmp    .horzUFO         ; 3

Lf536:
    lda    frameCnt         ; 3
    asl                     ; 2
    bne    .horzUFO         ; 2³
    jsr    NextRandom       ; 6
    and    #UFO_DIR_FLAGS   ; 2
    sta    $f4              ; 3
    lda    flags            ; 3
    and    #~UFO_DIR_FLAGS  ; 2
    ora    $f4              ; 3
    sta    flags            ; 3
.horzUFO:
    ldx    #xUFO-xPosLst    ; 2
    lda    flags            ; 3
    ror                     ; 2
    jsr    DoXMove          ; 6         move UFO/Sattelite
    lda    xUFO             ; 3
    cmp    #186             ; 2
    bne    Lf568            ; 2³
    lda    #$00             ; 2
    sta    $c6              ; 3
    lda    soundBits        ; 3
    and    #~[SOUND_ENEMY|SOUND_UFO]; 2
Lf560:
    sta    soundBits        ; 3
    lda    #Y_ILLEGAL       ; 2
    sta    yUFO             ; 3
    bne    .endMakeUFO      ; 3

Lf568:
    lda    dirShotUfo       ; 3
    bne    .endMakeUFO      ; 2³
    jsr    NextRandom       ; 6
    and    #$0f             ; 2
    tax                     ; 2
    lda    flags            ; 3
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2         UFO allowed?
    txa                     ; 2
    bcc    Lf5a7            ; 2³
    and    #$03             ; 2          yes
    sta    $f4              ; 3
    lda    xUFO             ; 3
    jsr    Convert2X        ; 6
    sta    $f5              ; 3
    lda    xShip            ; 3
    jsr    Convert2X        ; 6
    ldy    #$00             ; 2
    sec                     ; 2
    sbc    $f5              ; 3
    bcc    Lf593            ; 2³
    ldy    #$08             ; 2
Lf593:
    lda    yShip            ; 3
    sec                     ; 2
    sbc    yUFO             ; 3
    tya                     ; 2
    bcc    Lf5a2            ; 2³
    bne    Lf5a4            ; 2³
Lf59d:
    clc                     ; 2
    adc    #$04             ; 2
    bpl    Lf5a4            ; 2³
Lf5a2:
    bne    Lf59d            ; 2³
Lf5a4:
    clc                     ; 2
    adc    $f4              ; 3
Lf5a7:
    tax                     ; 2
    ora    ShotRangeTbl,x   ; 4
    sta    dirShotUfo       ; 3
    lda    xUFO             ; 3
    sta    xShotUfo         ; 3
    lda    yUFO             ; 3
    clc                     ; 2
    adc    #$03             ; 2
    sta    yShotUfo         ; 3
Lf5b8:
    lda    #>Asteroids      ; 2
    sta    ptr1+1           ; 3
    sta    ptr2+1           ; 3
    lda    #>HMSizeTbl      ; 2
    sta    ptr3+1           ; 3
    sta    ptr4+1           ; 3
    lda    #>Ld083          ; 2
    sta    jmpVec1+1        ; 3
    lda    #>EndXPosP0      ; 2
    sta    jmpVec2+1        ; 3
    lda    #0               ; 2
    sta    lwrBound         ; 3
    lda    #NUM_ASTEROIDS_2 ; 2
    sta    uprBound         ; 3
    jmp    SetupScoreJmp    ; 3
; ******************** A S T E R O I D S  (end) ********************

; ******************** O B J E C T S (start) ********************
.evenFrame:
; *** set the ships colors: ***
    lda    #SHIP1_COL       ; 2
    bit    flags            ; 3         player 2
    bpl    .player1         ; 2³         no,
    lda    #SHIP2_COL       ; 2
.player1:
    sta    shipCol          ; 3
    sta    ballCol          ; 3
    ldx    #SATTELITE_COL   ; 2
    lda    flags            ; 3
    and    #UFO_FLAG        ; 2
    beq    Lf5ed            ; 2³
    ldx    #UFO_COL         ; 2
Lf5ed:
    stx    enemyCol         ; 3
    lda    #$00             ; 2
    sta    ssColor          ; 3
    lda    lifesDir         ; 3         any player still alive?
    ora    lifesDir2        ; 3
    and    #LIFES_MASK      ; 2
    bne    CheckJoystick    ; 2³+1
    sta    AUDV1            ; 3
    lda    flags2           ; 3
    ror                     ; 2         game over?
    bcs    .screensaver     ; 2³         yes,
    ldx    #$01             ; 2
    stx    frameCntHi       ; 3
    dex                     ; 2
    stx    frameCnt         ; 3
    lda    flags2           ; 3
    ora    #GAME_OVER       ; 2
    sta    flags2           ; 3
.screensaver:
    lda    frameCntHi       ; 3
    rol                     ; 2
    adc    #$00             ; 2
    rol                     ; 2
    adc    #$00             ; 2
    rol                     ; 2
    adc    #$00             ; 2
    rol                     ; 2
    adc    #$00             ; 2
    and    #$f7             ; 2
    sta    COLUBK           ; 3
    sta    ssColor          ; 3
    jmp    SetupKernel      ; 3

CheckJoystick SUBROUTINE
.joystick   = $f3
    lda     SWCHA
  IF ORIGINAL
    bit    flags            ; 3         player 2
    bpl    .player1         ; 2³         no,
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
.player1:
    and    #$f0
    sta    .joystick        ; 3
  ELSE
    and    #$f0
    sta    .joystick        ; 3        -> joystick 1
    bit    $f3
    bit    $f3
    bit    $f3
    bit    $f3
  ENDIF
    bit    flags2           ; 3         shield enabled?
    bvc    Lf669            ; 2³         no
    and    #$20             ; 2         joystick down?
    beq    .checkFeatures   ; 2³         yes
    lda    flags2           ; 3
    and    #~SHIELD_FLAG    ; 2
    sta    flags2           ; 3
    jmp    Lf669            ; 3

.checkFeatures:
    inc    ftrTimer         ; 5         increase shield timer
    lda    ftrTimer         ; 3
    and    #$1f             ; 2         shield time up?
    bne    Lf666            ; 2³         no,
    lda    flags2           ; 3
    and    #~SHIELD_FLAG    ; 2         disable shield and...
    ora    #KILL_FLAG       ; 2          ...enable kill flag
    sta    flags2           ; 3
    lda    #$80             ; 2         reset timer
    sta    ftrTimer         ; 3
    lda    soundBits        ; 3         start explosion sound
    ora    #SOUND_KILL      ; 2
    and    #~SOUND_THRUST   ; 2
    sta    soundBits        ; 3
    lda    #$0f             ; 2
    sta    soundTimer0      ; 3
Lf666:
    jmp    .noThrust        ; 3

Lf669:
    lda    yShip            ; 3
    cmp    #Y_ILLEGAL       ; 2         ship visible`?
    beq    Lf679            ; 2³         no,
    lda    ftrTimer         ; 3         timer?
    beq    Lf682            ; 2³         clear,
    bmi    Lf67f            ; 2³         negative,
    dec    ftrTimer         ; 5         no, decrease
    bpl    Lf682            ; 3

Lf679:
    lda    ftrTimer         ; 3
    beq    Lf67f            ; 2³
    dec    ftrTimer         ; 5
Lf67f:
    jmp    SetupKernel      ; 3

Lf682:
    lda    .joystick        ; 3
    cmp    #$d0             ; 2         only joystick down pressed?
    bne    .notDown         ; 2³         no
    lda    game             ; 3         which feature?
    and    #FEATURE_BITS    ; 2         Hyperspace
    beq    .hyperspace      ; 2³         yes!
    cmp    #FEATURE_BITS    ; 2         none?
    beq    .notDown         ; 2³         yes!
    and    #$08             ; 2         Shield?
    bne    .shield          ; 2³         yes!
    bit    flags2           ; 3         just flipped? (FLIP_FLAG)
    bmi    .endFeatures     ; 2³         yes, not again!
; Flip!
    lda    lifesDir         ; 3
    eor    #$08             ; 2         flip direction!
    sta    lifesDir         ; 3
    lda    flags2           ; 3
    ora    #FLIP_FLAG       ; 2
    sta    flags2           ; 3
    bne    .endFeatures     ; 3

.shield:
    lda    flags2           ; 3
    ora    #SHIELD_FLAG     ; 2
    sta    flags2           ; 3
    inc    ftrTimer         ; 5
    bne    .endFeatures     ; 3

.hyperspace:
    lda    flags2           ; 3
    and    #HYPERSPACE_FLAG ; 2
    bne    .newShipPos      ; 2³
    lda    flags2           ; 3
    ora    #HYPERSPACE_FLAG ; 2
    sta    flags2           ; 3
    bne    .endFeatures     ; 3

.newShipPos:
; calculate new ship position:
    lda    yShip            ; 3
    cmp    #Y_ILLEGAL       ; 2         already caclulated?
    beq    .endFeatures     ; 2³         yes, skip
    lda    #Y_ILLEGAL       ; 2
    sta    yShip            ; 3
    lda    flags2           ; 3
    and    #~[KILL_FLAG|HYPERSPACE_FLAG]; 2
    sta    flags2           ; 3
    jsr    GetRandomX       ; 6
    sta    xShip            ; 3
    lda    randomLo         ; 3
    lsr                     ; 2
    cmp    #H_KERNEL-10     ; 2
    bcc    .yPosOk          ; 2³
    sbc    #H_KERNEL-10     ; 2
.yPosOk:
    sta    yShipNew         ; 3

    lda    #0               ; 2         stop ship
    ldx    #5               ; 2
.loopStop:
    sta    speedLst,x       ; 4
    dex                     ; 2
    bpl    .loopStop        ; 2³
    lda    #$1f             ; 2         init timer
    sta    ftrTimer         ; 3
    jmp    SetupKernel      ; 3

.notDown:
; disable all features:
    lda    flags2           ; 3
    and    #~[FLIP_FLAG|SHIELD_FLAG|HYPERSPACE_FLAG] ; 2
    sta    flags2           ; 3
.endFeatures:

; *** turn ship: ***
    lda    frameCnt         ; 3
    ror                     ; 2
    ror                     ; 2
    bcc    .skipTurn        ; 2³+1
    lda    lifesDir         ; 3
    and    #LIFES_MASK      ; 2
    sta    $f4              ; 3
    asl    .joystick        ; 5         joystick right?
    bcs    .skipRight       ; 2³         no, skip
    dec    lifesDir         ; 5          yes, turn right
.skipRight:
    asl    .joystick        ; 5         joystick left?
    bcs    .skipLeft        ; 2³         no, skip
    inc    lifesDir         ; 5          yes, turn left
.skipLeft:
    lda    lifesDir         ; 3
    and    #DIR_MASK        ; 2
    ora    $f4              ; 3
    sta    lifesDir         ; 3
    jmp    .endTurn         ; 3

.skipTurn:
    asl    .joystick        ; 5         superflous code now
    asl    .joystick        ; 5
.endTurn:
    asl    .joystick        ; 5

; *** fire shots: ***
    ldy    #1               ; 2
    bit    flags            ; 3         player 2?
    bmi    .player2         ; 2³         yes,
    ldy    #0               ; 2
.player2:
  IF ORIGINAL
    lda    INPT4,y          ; 4         check fire button of current player
  ELSE
    lda    INPT4            ; 4         check both buttons in hack
    and    INPT5            ; 4
  ENDIF
    bmi    .noFire          ; 2³
    lda    flags            ; 3
    and    #FIRE_FLAG       ; 2         fire button was up?
    bne    .skipNewShot     ; 2³         no
    lda    flags            ; 3
    ora    #FIRE_FLAG       ; 2         mark fire button as down
    sta    flags            ; 3
; new player shot possible?
    ldy    #$01             ; 2
    lda    dirShot2         ; 3
    beq    .shot2           ; 2³
    dey                     ; 2
    lda    dirShot1         ; 3
    bne    .skipNewShot     ; 2³
.shot2:
    lda    yShip            ; 3
    clc                     ; 2
    adc    #$03             ; 2
    sta    yShotLst,y       ; 5
  IF ORIGINAL
    lda    xShip            ; 3
    sta    xShotLst,y       ; 5
  ELSE
    ldx    xShip            ; 3         save two bytes
    stx    xShotLst,y       ; 5
  ENDIF
    lda    soundBits        ; 3
    and    #$04             ; 2
    bne    .skipShotSound   ; 2³
    lda    soundBits        ; 3         start fireing sound
    ora    #SOUND_ENEMY     ; 2
    sta    soundBits        ; 3
    lda    #15              ; 2
    sta    soundTimer1      ; 3
.skipShotSound:
    lda    lifesDir         ; 3
    and    #DIR_MASK/2      ; 2
    tax                     ; 2
    lda    lifesDir         ; 3
    and    #DIR_MASK        ; 2
    ora    ShotRangeTbl,x   ; 4
    sta    dirShotLst,y     ; 5
    jmp    .skipNewShot     ; 3

.noFire:
    lda    flags            ; 3
    and    #~FIRE_FLAG      ; 2
    sta    flags            ; 3
.skipNewShot:

; *** thrust: ***
  IF SADISTROIDS = 0
    asl    .joystick        ; 5         thrust?
    bcs    .noThrust        ; 2³         no
    lda    soundBits        ; 3
    ora    #SOUND_THRUST    ; 2
    sta    soundBits        ; 3
    lda    lifesDir         ; 3
    and    #DIR_MASK        ; 2
    tay                     ; 2
    lda    ThrustTbl,y      ; 4
    bpl    Lf78e            ; 2³
    dec    speedMidY        ; 5
Lf78e:
    clc                     ; 2
    adc    speedLoY         ; 3
    sta    speedLoY         ; 3
    bcc    Lf797            ; 2³
    inc    speedMidY        ; 5
Lf797:
    tya                     ; 2
    clc                     ; 2
    adc    #$04             ; 2
    and    #$0f             ; 2
    tay                     ; 2
    lda    ThrustTbl,y      ; 4
    bpl    Lf7a5            ; 2³
    dec    speedMidX        ; 5
Lf7a5:
    clc                     ; 2
    adc    speedLoX         ; 3
    sta    speedLoX         ; 3
    bcc    Lf7ae            ; 2³
    inc    speedMidX        ; 5
Lf7ae:
    jmp    .skipFriction    ; 3

.noThrust:
    lda    soundBits        ; 3
    and    #~SOUND_THRUST   ; 2
    sta    soundBits        ; 3
  ELSE
; double thrust!
    asl    .joystick        ; 5         thrust?
    lda    soundBits        ; 3
    bcs    .noThrust        ; 2³         no
    ora    #SOUND_THRUST    ; 2
    sta    soundBits        ; 3
    lda    lifesDir         ; 3
    ldx    #1               ; 2
.loopThrust:
    and    #DIR_MASK        ; 2
    tay                     ; 2
    lda    ThrustTbl,y      ; 4
    bpl    Lf78e            ; 2³
    dec    speedMidX,x      ; 5
    dec    speedMidX,x      ; 5
Lf78e:
    clc                     ; 2
    adc    speedLoX,x       ; 3
    bcc    Lf797            ; 2³
    inc    speedMidX,x      ; 5
Lf797:
    clc
    adc    ThrustTbl,y      ; 4
    bcc    Lf797a           ; 2³
    inc    speedMidX,x      ; 5
Lf797a:
    sta    speedLoX,x       ; 3
    tya                     ; 2
    clc                     ; 2
    adc    #$04             ; 2
    dex                     ; 2
    bpl    .loopThrust      ; 2³
    bmi    .skipFriction    ; 3
    ds 7, 0

.noThrust:
    and    #~SOUND_THRUST   ; 2
    sta    soundBits        ; 3
  ENDIF

; *** friction: ***
    ldx    #1               ; 2
.loopFriction:
    lda    speedMidLst,x    ; 4         ship moving at this axis?
    ora    speedLoLst,x     ; 4
    beq    .nextAxis        ; 2³         no, skip
    lda    speedMidLst,x    ; 4         more speed, more friction
  IF ORIGINAL
    asl                     ; 2
  ELSE
    nop                     ; 2         less friction
  ENDIF
    ldy    #$ff             ; 2
    clc                     ; 2
    eor    #$ff             ; 2         friction works in opposite direction
    bmi    .posSpeed        ; 2³
    iny                     ; 2
    sec                     ; 2
.posSpeed:
    adc    speedLoLst,x     ; 4
    sta    speedLoLst,x     ; 4
    tya                     ; 2
    adc    speedMidLst,x    ; 4
    sta    speedMidLst,x    ; 4
.nextAxis:
    dex                     ; 2
    bpl    .loopFriction    ; 2³
.skipFriction:

; *** move ship: ***
    ldx    #1               ; 2
.loopMoveShip:
    lda    speedMidLst,x    ; 4
    tay                     ; 2
    rol                     ; 2
    eor    speedMidLst,x    ; 4
    rol                     ; 2
    tya                     ; 2
    bcc    Lf7e7            ; 2³        bit 7 == bit 6 !
    eor    #$7f             ; 2
    sta    speedMidLst,x    ; 4
Lf7e7:
    ror                     ; 2         JTZ: how about using lsr instead?
    ror                     ; 2
    ror                     ; 2
    ror                     ; 2
    and    #$0f             ; 2
    cpy    #0               ; 2         pos/neg speed?
    bpl    Lf7f3            ; 2³         positive
    ora    #$f0             ; 2
Lf7f3:
    sta    $f4              ; 3         = speedMid high nibble
    tya                     ; 2
    rol                     ; 2         JTZ: how about using asl instead?
    rol                     ; 2
    rol                     ; 2
    rol                     ; 2
    and    #$f0             ; 2
    sta    $f5              ; 3
    lda    speedLoLst,x     ; 4
    ror                     ; 2         JTZ: how about using lsr instead?
    ror                     ; 2
    ror                     ; 2
    ror                     ; 2
    and    #$0f             ; 2
    ora    $f5              ; 3         $f5 = (MMMM)mmmmLLLL(llll)
    clc                     ; 2
    adc    speedHiLst,x     ; 4
    sta    speedHiLst,x     ; 4
    lda    $f4              ; 3
    php                     ; 3
    cpx    #0               ; 2         looping for x-speed?
    beq    .exitMoveShip    ; 2³         yes, exit loop
    plp                     ; 4
    adc    yShip            ; 3
    sta    yShip            ; 3
    dex                     ; 2
    bpl    .loopMoveShip    ; 3+1

.exitMoveShip:
    plp                     ; 4
    bmi    Lf823            ; 2³
    adc    #$00             ; 2
    bpl    Lf825            ; 2³
Lf823:
    sbc    #$00             ; 2
Lf825:
    sec                     ; 2
    cmp    #$00             ; 2
    bpl    Lf82d            ; 2³
    eor    #$ff             ; 2
    clc                     ; 2
Lf82d:
    beq    SetupKernel      ; 2³
    ldx    #xShip-xPosLst   ; 2
    jsr    XMoveObjJSR      ; 6     -> move xShip

; *** setup kernel variables: ***
SetupKernel:
    lda    #>Ship           ; 2
    sta    ptrShip+1        ; 3
    sta    ptrEnemy+1       ; 3
    lda    flags            ; 3
    and    #COLLISION_FLAG  ; 2
    beq    .noCollision     ; 2³
    lda    #<Explosion      ; 2
    clc                     ; 2
    adc    ofsExpl          ; 3
    sta    tmpVar           ; 3
    lda    ofsExpl          ; 3
    clc                     ; 2
    adc    #6               ; 2
    sta    ofsExpl          ; 3
    cmp    #6*3             ; 2         explosion over?
    bne    Lf872            ; 2³         no, continue
    lda    flags            ; 3
    and    #~COLLISION_FLAG ; 2
    sta    flags            ; 3
    lda    soundBits        ; 3
    and    #~[SOUND_ENEMY|SOUND_UFO]; 2
    sta    soundBits        ; 3
    lda    #$00             ; 2
    sta    ofsExpl          ; 3
    lda    #Y_ILLEGAL       ; 2
    sta    yUFO             ; 3
.noCollision:
    ldx    #<UFO            ; 2
    lda    flags            ; 3
    and    #UFO_FLAG        ; 2
    bne    .showUFO         ; 2³
    ldx    #<Sattelite      ; 2
.showUFO:
    stx    ptrEnemyHlp      ; 3
Lf872:
    lda    #<Ldf79          ; 2         points at $ff
    sta    ptrEnemy         ; 3
    ldx    #$00             ; 2         no reflection
    lda    ftrTimer         ; 3
    bpl    Lf8ad            ; 2³
    inc    ftrTimer         ; 5
    lda    ftrTimer         ; 3
    ror                     ; 2
    and    #$07             ; 2
    clc                     ; 2
    adc    #$09             ; 2
    cmp    #$0c             ; 2
    bne    .posDir          ; 2³
    lda    #Y_ILLEGAL       ; 2
    sta    yShip            ; 3
    lda    #$3f             ; 2
    sta    ftrTimer         ; 3
    lda    #29              ; 2
    sta    xShip            ; 3
  IF NTSC
    lda    #H_KERNEL/2-3    ; 2
  ELSE
    lda    #H_KERNEL/2-5    ; 2
  ENDIF
    sta    yShipNew         ; 3
; *** decrease lifes ***
    lda    lifesDir         ; 3
    and    #LIFES_MASK      ; 2
    sec                     ; 2
    sbc    #$10             ; 2
    tay                     ; 2
    and    #LIFES_MASK      ; 2
    bne    .hasLifes        ; 2³
    tay                     ; 2

; *** send score ***
  IF PLUSROM
    lda game
    sta WriteToBuffer
    lda scoreHigh
    sta WriteToBuffer
    lda scoreLow
    sta WriteToBuffer
   IF SADISTROIDS
    lda #4                  ; Sadisteroids game id in Highscore DB
   ELSE
    lda #1                  ; Asteroids game id in Highscore DB
   ENDIF
    sta WriteSendBuffer     ; send request to backend..
  ENDIF

.hasLifes:
    sty    lifesDir         ; 3
    lda    #$0c             ; 2         -> ptr at $dfc1 (=$ff)
    bpl    .posDir          ; 3

Lf8ad:
    bit    flags2           ; 3         shield?
    bvc    .noShield        ; 2³         no, show ship
    lda    #$00             ; 2          yes,
    sta    $f4              ; 3         disable reflection...
    lda    #<Shield         ; 2         ...and show shield
    bne    .contShield      ; 3

.noShield:
    lda    lifesDir         ; 3
    and    #DIR_MASK        ; 2
    cmp    #$08             ; 2         negative direction?
    bcc    .posDir          ; 2³         no
    ldx    #REFLECT         ; 2
    and    #DIR_MASK/2      ; 2         isolate low bits
    eor    #$ff             ; 2
    adc    #$08             ; 2
.posDir:
    stx    $f4              ; 3         0/8/12
    sta    $f5              ; 3
    asl                     ; 2
    adc    $f5              ; 3         a = dir*6
    asl                     ; 2
    adc    #<Ship           ; 2
.contShield:
    sta    ptrShipHlp       ; 3
Lf8d5:
    lda    yShip            ; 3
    cmp    #Y_ILLEGAL       ; 2
    bne    Lf8e3            ; 2³
    sta    yShipKrnl        ; 3
    lda    #<Ship+5         ; 2
    sta    ptrShip          ; 3
    bne    Lf921            ; 3+1

Lf8e3:
    lda    yShip            ; 3
    bmi    Lf8fc            ; 2³
Lf8e7:
    sta    yShipKrnl        ; 3
    sec                     ; 2
    sbc    #H_KERNEL-5      ; 2
    bcc    Lf8f6            ; 2³
    clc                     ; 2
    adc    #-5              ; 2
    sta    yShip            ; 3
    jmp    Lf8d5            ; 3

Lf8f6:
    lda    #<Ship+5         ; 2
    sta    ptrShip          ; 3
    bne    Lf917            ; 3+1

Lf8fc:
    cmp    #-5              ; 2
    bcs    Lf909            ; 2³+1
    lda    #H_KERNEL        ; 2
    clc                     ; 2
    adc    yShip            ; 3
    sta    yShip            ; 3
    bne    Lf8e7            ; 3+1

Lf909:
    eor    #$ff             ; 2
    sec                     ; 2
    adc    ptrShipHlp       ; 3
    sta    ptrShip          ; 3
    lda    #H_KERNEL        ; 2
    clc                     ; 2
    adc    yShip            ; 3
    sta    yShipKrnl        ; 3
Lf917:
    lda    speedHiY         ; 3
    rol                     ; 2
    rol                     ; 2
    and    #$01             ; 2
    ora    $f4              ; 3
    sta    vDelP0Krnl       ; 3
Lf921:
    ldx    #xShotUfo-xPosLst; 2
    stx    $f6              ; 3

; ********** S H O T S (start) **********
    ldx    #2               ; 2
.loopShots:
    lda    dirShotLst,x     ; 4         disabled shot
    bne    .contShot        ; 2³
.killShot:
    ldy    #Y_ILLEGAL       ; 2
    lda    xShip            ; 3
    cpx    #2               ; 2         UFO-shot?
    bne    .skipUfo         ; 2³         no
    lda    xUFO             ; 3
.skipUfo:
    sty    yShotLst,x       ; 4
    sta    xShotLst,x       ; 4
    stx    $f5              ; 3         save x
    ldx    $f6              ; 3         load shot offset
    clc                     ; 2
    lda    #2               ; 2
    jsr    XMoveObjJSR      ; 6         move shot at ship/UFO + 2
    jmp    .xPosShot        ; 3

.contShot:
    lda    frameCnt         ; 3
    ror                     ; 2
    ror                     ; 2
    bcs    .skipKill        ; 2³
; *** decrease shot range: ***
    lda    dirShotLst,x     ; 4
    sec                     ; 2
    sbc    #$10             ; 2
    sta    dirShotLst,x     ; 4
    and    #$f0             ; 2         shot out of range?
    bne    .skipKill        ; 2³         no, continue
    sta    dirShotLst,x     ; 4          yes, disable!
    beq    .killShot        ; 3

.skipKill:
    lda    dirShotLst,x     ; 4
    and    #$0f             ; 2
    tay                     ; 2
    lda    speedMidY        ; 3
    php                     ; 3
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    plp                     ; 4
    bpl    Lf96f            ; 2³
    ora    #$f0             ; 2
    clc                     ; 2
    adc    #$01             ; 2
Lf96f:
    clc                     ; 2
    adc    YShotTbl,y       ; 4
    clc                     ; 2
    adc    yShotLst,x       ; 4
    sta    yShotLst,x       ; 4
    bpl    Lf97f            ; 2³
    clc                     ; 2
    adc    #H_KERNEL        ; 2
    bpl    Lf984            ; 2³
Lf97f:
    sec                     ; 2
    sbc    #H_KERNEL        ; 2
    bcc    Lf986            ; 2³
Lf984:
    sta    yShotLst,x       ; 4
Lf986:
    lda    speedMidX        ; 3
    php                     ; 3
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    plp                     ; 4
    bpl    Lf995            ; 2³
    ora    #$f0             ; 2
    clc                     ; 2
    adc    #$01             ; 2
Lf995:
    stx    $f5              ; 3
    ldx    $f6              ; 3
    clc                     ; 2
    adc    XShotTbl,y       ; 4
    sec                     ; 2
    bpl    Lf9a5            ; 2³
    eor    #$ff             ; 2
    adc    #$01             ; 2
    clc                     ; 2
Lf9a5:
    beq    .xPosShot        ; 2³
    jsr    XMoveObjJSR      ; 6
.xPosShot:
    txa                     ; 2
    sec                     ; 2
    sbc    #$3e             ; 2
    tay                     ; 2
    lda    xPosLst,x        ; 4
    sta    WSYNC            ; 3
    sta.wy HMM0,y           ; 5
    ror                     ; 2
    and    #$07             ; 2
    bcs    .left            ; 2³
    ldx    #6               ; 2
.wait1:
    dex                     ; 2
    bne    .wait1           ; 2³
    nop                     ; 2
    tax                     ; 2
.wait2:
    dex                     ; 2
    bne    .wait2           ; 2³
    stx    RESM0,y          ; 4
    beq    Lf9cc            ; 3

.left:
    tax                     ; 2
    bcs    .wait2           ; 3

Lf9cc:
    dec    $f6              ; 5
    dec    $f5              ; 5
    ldx    $f5              ; 3
    bmi    .exitShots       ; 2³
    jmp    .loopShots       ; 3

.exitShots:
    jmp    SetupScoreJmp    ; 3
; ********** S H O T S (end) **********
; ******************** O B J E C T S (end) ********************


START1:
    sei                     ; 2             disable interrupts, if there are any.
    cld                     ; 2             clear BCD math bit.
    ldx    #$ff             ; 2
    txs                     ; 2
    inx                     ; 2
    txa                     ; 2
Lf9e1:
    sta    $00,x            ; 4
    inx                     ; 2
    bne    Lf9e1            ; 2³

    lda    #Y_ILLEGAL       ; 2
    sta    yShip            ; 3         disable ship
    lda    #$34             ; 2
    sta    randomHi         ; 3
    sta    randomLo         ; 3
    lda    #SELECT_FLAG     ; 2
    sta    flags            ; 3
    lda    #GAME_OVER       ; 2
    sta    flags2           ; 3
  IF COPYRIGHT
    lda    #<ShowCopyright  ; 2
    sta    bswVec           ; 3
    lda    #>ShowCopyright  ; 2
    sta    bswVec+1         ; 3
    jmp    SwitchBank0      ; 3
  ELSE
    bne    StartMain        ; 3
  ENDIF

StartNewGame:
    lda    #COLLISION_FLAG  ; 2
    sta    flags            ; 3
StartMain:
    sta    soundTimer1      ; 3
    lda    #$fe             ; 2
    sta    ptr3+1           ; 3
    sta    ptr4+1           ; 3
    lda    #$ff             ; 2
    sta    ptr1+1           ; 3
    sta    ptr2+1           ; 3
    lda    #>OverScan       ; 2
    sta    jmpVec1+1        ; 3
    lda    #>Lf100          ; 2
    sta    jmpVec2+1        ; 3
    jsr    SetupAsteroids   ; 6
    lda    #SPEED_SLOW|SPEED_MEDIUM; 2
    sta    gameSpeed        ; 3
    lda    #<Ld1cf          ; 2
    sta    jmpVec2          ; 3
    lda    #Y_ILLEGAL       ; 2
    sta    yShotUfo         ; 3         disable UFO
    sta    yUFO             ; 3
    lda    #29              ; 2
    sta    xShip            ; 3
    lda    #198             ; 2
    sta    xUFO             ; 3
    sta    asteroidHit      ; 3         asteroid hit
    jmp    EndSound         ; 3


XMoveAsteroids SUBROUTINE
    lda    flagLst,x        ; 4     asteroids type
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    sta    $f5              ; 3
    lda    game             ; 3     childrens mode?
    bmi    .childMode       ; 2³     yes!
    and    #$01             ; 2     fast or slow asteroids?
    bne    .fastMode        ; 2³
    lda    $f5              ; 3
    and    #[TYPE_BITS>>4]  ; 2     slow!
    bpl    .contSlow        ; 3

.fastMode:
    lda    $f5              ; 3
.contSlow:
    tay                     ; 2
    lda    XSpeedTbl,y      ; 4     $00, $40, $80
    beq    DoXMove          ; 2³    move always!
.contChild:
    bit    moveBits         ; 3
    bne    DoXMove          ; 2³
    rts                     ; 6

.childMode:                 ;       in childrens mode, all asteroids
    lda    #$80             ; 2      are moving slowly
    bne    .contChild       ; 3
;XMoveAsteroids


DoXMove SUBROUTINE
; moves object one pixel left or right
    bcs    .moveLeft        ; 2³
;*** move object right: ***
    lda    #$f0             ; 2
    adc    xPosLst,x        ; 4
    cmp    #$93             ; 2
    bne    Lfa70            ; 2³
    lda    #$65             ; 2
    bne    .ok              ; 3

Lfa70:
    cmp    #$70             ; 2
    bcc    .ok              ; 2³
    cmp    #$80             ; 2
    bcs    .ok              ; 2³
    and    #$0f             ; 2
    tay                     ; 2
    lda    RightWrapTbl,y   ; 4
    bne    .ok              ; 2³

;*** move object left: ***
.moveLeft:
    lda    #$0f             ; 2
    adc    xPosLst,x        ; 4     +#$10 (C=1!)
    cmp    #$42             ; 2
    bne    Lfa8c            ; 2³
    lda    #$8d             ; 2
    bne    .ok              ; 3

Lfa8c:
    cmp    #$70             ; 2
    bcc    .ok              ; 2³
    cmp    #$80             ; 2
    bcs    .ok              ; 2³
    and    #$0f             ; 2
    tay                     ; 2
    lda    LeftWrapTbl,y    ; 4
.ok:
    sta    xPosLst,x        ; 4
    rts                     ; 6


GetRandomX SUBROUTINE
    lda    randomHi         ; 3
    and    #$07             ; 2
    tay                     ; 2
    lda    randomHi         ; 3
    and    #$f0             ; 2
    cmp    #$70             ; 2         $70 <= a < $80?
    bcc    Lfab0            ; 2³
    cmp    #$80             ; 2
    bcs    Lfab0            ; 2³
    lda    #$80             ; 2          ja, -> a = $80
Lfab0:
    ora    RandomXTbl,y     ; 4
    cmp    #$42             ; 2         useless code!!!
    bne    Lfac1            ; 2³           "
    cmp    #$52             ; 2            "
    bne    Lfac1            ; 2³           "
    cmp    #$62             ; 2            "
    bne    Lfac1            ; 2³           "
    lda    #$8d             ; 2            "
Lfac1:
    rts                     ; 6


XMoveObjJSR SUBROUTINE
    ldy    #>XMoveObj       ; 2
    sty    bswVec+1         ; 3
    ldy    #<XMoveObj       ; 2
    sty    bswVec           ; 3
    jmp    SwitchBank0      ; 3

XMoveObjRTS:
    rts                     ; 6


SwapPlayers SUBROUTINE
    ldx    #2               ; 2
.loop:
    ldy    player1,x        ; 4
    lda    player2,x        ; 4
    sty    player2,x        ; 4
    sta    player1,x        ; 4
    dex                     ; 2
    bpl    .loop            ; 2³
    lda    flags            ; 3
    eor    #PLAYER2_FLAG    ; 2
    sta    flags            ; 3
    rts                     ; 6


NextRandom SUBROUTINE
    lda    randomLo         ; 3
    asl                     ; 2
    eor    randomLo         ; 3
    asl                     ; 2
    asl                     ; 2
    rol    randomHi         ; 5
    rol    randomLo         ; 5
    lda    randomHi         ; 3
    rts                     ; 6


CXAsteroids SUBROUTINE
; *** checks object/asteroid collision ***
; y = x-Pos
; a = y-Pos
; x = ID
.top        = $e2
.objIdHit   = $f1
.objId2     = $f3
.xPos1      = $f4
.bottom     = $f5
.objId1     = $f6
.xPos2      = $f7
.tmpXPos    = $f8

    stx    .objId1          ; 3
    clc                     ; 2
    adc    #$11             ; 2
    sta    .bottom          ; 3
    clc                     ; 2
    adc    YSizeTbl,x       ; 4
    sta    .top             ; 3
    tya                     ; 2
    jsr    Convert2X        ; 6
    sta    .xPos1           ; 3

    ldx    #0               ; 2
Lfb05:
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    Lfb53            ; 2³
    tay                     ; 2
    clc                     ; 2
    adc    #17              ; 2
    bmi    Lfb1b            ; 2³
    cmp    .top             ; 3
    bcs    .nextAsteroid    ; 2³
    adc    #15              ; 2
    cmp    .bottom          ; 3
    bcc    .nextAsteroid    ; 2³
Lfb1b:
    lda    flagLst,x        ; 4
    rol                     ; 2
    rol                     ; 2         Asteroid already hit?
    bcs    .nextAsteroid    ; 2³         yes, skip
    rol                     ; 2
    rol                     ; 2
    rol                     ; 2
    and    #[TYPE_BITS>>4]  ; 2
    sta    tmpVar           ; 3
    tya                     ; 2
    clc                     ; 2
    adc    #3               ; 2
    ldy    xPosLst,x        ; 4
    stx    .objIdHit        ; 3
    ldx    tmpVar           ; 3
    jsr    Lfba9            ; 6
    bcs    Lfb3c            ; 2³
    ldx    .objIdHit        ; 3
.nextAsteroid:
    inx                     ; 2
    bne    Lfb05            ; 3

Lfb3c:
    lda    yPosLst          ; 3
    bpl    Lfb52            ; 2³
    ldx    lwrBound         ; 3
    lda    flagLst          ; 3
    ora    flagLst,x        ; 4
    and    #HIT_FLAG        ; 2         Asteroid hit?
    beq    Lfb52            ; 2³         no
    lda    flagLst          ; 3
    ora    #[HIT_FLAG|$4]   ; 2
    sta    flagLst          ; 3
    sta    flagLst,x        ; 4
Lfb52:
    rts                     ; 6

Lfb53:
    ldx    #NUM_ASTEROIDS_2 ; 2
Lfb55:
    lda    yPosLst,x        ; 4
    cmp    #Y_ILLEGAL       ; 2
    beq    Lfb8c            ; 2³
    tay                     ; 2
    clc                     ; 2
    adc    #17              ; 2
    bmi    Lfb6b            ; 2³
    cmp    .top             ; 3
    bcs    Lfb89            ; 2³
    adc    #15              ; 2
    cmp    .bottom          ; 3
    bcc    Lfb89            ; 2³
Lfb6b:
    lda    flagLst,x        ; 4
    rol                     ; 2
    rol                     ; 2         Asteroid already hit?
    bcs    Lfb89            ; 2³         yes
    rol                     ; 2
    rol                     ; 2
    rol                     ; 2
    and    #[TYPE_BITS>>4]  ; 2
    sta    tmpVar           ; 3
    tya                     ; 2
    clc                     ; 2
    adc    #3               ; 2
    ldy    xPosLst,x        ; 4
    stx    .objIdHit        ; 3
    ldx    tmpVar           ; 3
    jsr    Lfba9            ; 6
    bcs    Lfb8c            ; 2³
    ldx    .objIdHit        ; 3
Lfb89:
    inx                     ; 2
    bne    Lfb55            ; 3

Lfb8c:
    ldy    #NUM_ASTEROIDS_2 ; 2
    lda    yPosLst,y        ; 4
    bpl    Lfba8            ; 2³
    ldx    uprBound         ; 3
    lda    flagLst,x        ; 4
    ora    flagLst,y        ; 4
    and    #HIT_FLAG        ; 2
    beq    Lfba8            ; 2³
    lda    flagLst,y        ; 4
    ora    #[HIT_FLAG|$4]   ; 2
    sta    flagLst,x        ; 4
    sta    flagLst,y        ; 5
Lfba8:
    rts                     ; 6

Lfba9:
; y = xPos
; a = yPos
; x = ID
    stx    .objId2          ; 3
    sty    .xPos2           ; 3
    clc                     ; 2
    adc    #17              ; 2
    sta    .tmpXPos         ; 3
    cmp    .bottom          ; 3
    bcc    .checkBelow      ; 2³
    lda    .bottom          ; 3
    ldx    .objId1          ; 3
    adc    YSizeTbl,x       ; 4
    sec                     ; 2
    sbc    .tmpXPos         ; 3
    bcs    .checkX          ; 2³
.noCollision:
    rts                     ; 6

.checkBelow:
    clc                     ; 2
    adc    YSizeTbl,x       ; 4
    sec                     ; 2
    sbc    .bottom          ; 3
    bcc    .noCollision     ; 2³
.checkX:
    lda    .xPos2           ; 3
    jsr    Convert2X        ; 6
    sta    .xPos2           ; 3
    ldx    .objId2          ; 3
    cmp    .xPos1           ; 3
    bcc    .checkLeft       ; 2³
    lda    .xPos1           ; 3
    ldx    .objId1          ; 3
    adc    XSizeTbl,x       ; 4
    sec                     ; 2
    sbc    .xPos2           ; 3
    bcs    .collision       ; 2³
    rts                     ; 6

.checkLeft:
    clc                     ; 2
    adc    XSizeTbl,x       ; 4
    sec                     ; 2
    sbc    .xPos1           ; 3
    bcc    .noCollision     ; 2³
.collision:
    ldx    .objId1          ; 3
    cpx    #NUM_ASTEROIDS_2+1;2
    bne    Lfbf8            ; 2³
    jmp    .breakLoop       ; 3

Lfbf8:
    cpx    #ID_UFO          ; 2
    beq    Lfc0a            ; 2³+1
    cpx    #ID_SATTELITE    ; 2
    beq    Lfc0a            ; 2³+1
    ldy    .objId2          ; 3
    cpy    #ID_UFO          ; 2
    beq    Lfc0a            ; 2³
    cpy    #ID_SATTELITE    ; 2
    bne    Lfc1b            ; 2³
Lfc0a:
    lda    flags            ; 3
    and    #COLLISION_FLAG  ; 2
    beq    Lfc11            ; 2³
.noKill:
    rts                     ; 6

Lfc11:
    lda    flags            ; 3
    ora    #COLLISION_FLAG  ; 2
    sta    flags            ; 3
    lda    #0               ; 2
    sta    ofsExpl          ; 3
Lfc1b:
    cpx    #ID_SHIP         ; 2
    beq    .checkKill       ; 2³
    cpx    #NUM_ASTEROIDS_2 ; 2
    bne    .killObject      ; 2³
    lda    .objId2          ; 3
    cmp    #ID_SHIP         ; 2
    bne    .killObject      ; 2³
.checkKill:
    lda    ftrTimer         ; 3         timer negative?
    bmi    .noKill          ; 2³         yes
    lda    flags2           ; 3          no, enable kill flag...
    ora    #KILL_FLAG       ; 2
    sta    flags2           ; 3
    lda    #$80             ; 2         ...and make timer negative
    sta    ftrTimer         ; 3
.killObject:
    lda    soundBits        ; 3
    ora    #SOUND_KILL      ; 2
    and    #~SOUND_THRUST   ; 2
    sta    soundBits        ; 3
    lda    #15              ; 2
    sta    soundTimer0      ; 3
    ldy    .objId2          ; 3
    cpy    #ID_SHIP         ; 2         asteroid?
    bcs    .noAsteroid      ; 2³         no, skip
    ldy    .objIdHit        ; 3
    lda    flagLst,y        ; 4
    ora    #[HIT_FLAG|$4]   ; 2
    sta    flagLst,y        ; 5         mark asteroid as hit
    sta    asteroidHit      ; 3         and remember to check in next frame
.noAsteroid:
    cpx    #ID_SHOT1        ; 2         shot collision?
    bpl    Lfc61            ; 2³         no
    ldy    .objId2          ; 3
    cpy    #ID_SHOT_UFO     ; 2         collided with UFO-shot?
    bne    Lfc65            ; 2³
    ldx    #ID_SHOT_UFO     ; 2          yes, hack
Lfc61:
    lda    #$00             ; 2
    sta    xShotLst-1,x     ; 4
Lfc65:
; who collided?
    cpx    #ID_SHOT_UFO     ; 2
    beq    .noBonus         ; 2³
    cpx    #ID_UFO          ; 2
    beq    .noBonus         ; 2³
    cpx    #ID_SATTELITE    ; 2
    beq    .noBonus         ; 2³
    ldy    .objId2          ; 3
    clc                     ; 2
    sed                     ; 2
    lda    scoreLow         ; 3
    adc    ScoreLoTbl,y     ; 4
    sta    scoreLow         ; 3
    lda    ScoreHiTbl,y     ; 4
    bcs    .checkBonus      ; 2³
    beq    .noBonus         ; 2³
.checkBonus:
    adc    scoreHigh        ; 3
    sta    scoreHigh        ; 3
    cld                     ; 2
    tay                     ; 2
    lda    game             ; 3
    and    #BONUS_BITS      ; 2
    beq    .bonus5k         ; 2³
    cmp    #BONUS_BITS      ; 2
    beq    .noBonus         ; 2³
    ror                     ; 2
    ror                     ; 2
    tya                     ; 2
    and    #$1f             ; 2         20,000?
    bcc    .bonus20k        ; 2³         yes
    and    #$0f             ; 2         10,000?
.bonus20k:
    bne    .noBonus         ; 2³         no
    beq    .incLifes        ; 3          yes

.bonus5k:
    tya                     ; 2
    and    #$0f             ; 2         10,000?
    beq    .incLifes        ; 2³         yes
    cmp    #$05             ; 2         5,000?
    bne    .noBonus         ; 2³         no
.incLifes:
    lda    lifesDir         ; 3
    clc                     ; 2
    adc    #$10             ; 2
    tay                     ; 2
    and    #LIFES_MASK      ; 2
    cmp    #$a0             ; 2         max lifes?
    beq    .noBonus         ; 2³         yes, skip bonus
    sty    lifesDir         ; 3
    lda    soundBits        ; 3
    ora    #$04             ; 2
    sta    soundBits        ; 3
    lda    #$7f             ; 2
    sta    soundTimer1      ; 3
.noBonus:
    cld                     ; 2
    sec                     ; 2
    rts                     ; 6

.breakLoop:
    stx    asteroidHit      ; 3         remember to check asteroids in next frame
    pla                     ; 4
    pla                     ; 4
    sec                     ; 2
    rts                     ; 6
;CXAsteroids


Convert2X SUBROUTINE
; converts HMOVE/Delay into x-Pos
    tax                     ; 2
    and    #$0f             ; 2
    tay                     ; 2
    txa                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    lsr                     ; 2
    tax                     ; 2
    lda    ConvertLoTbl,x   ; 4
    clc                     ; 2
    adc    ConvertHiTbl,y   ; 4
    rts                     ; 6


CheckUFO SUBROUTINE
    ldx    #ID_SATTELITE    ; 2
    lda    flags            ; 3
    and    #UFO_FLAG        ; 2
    beq    .sattelite       ; 2³
    dex                     ; 2         x = ID_UFO
.sattelite:
    tya                     ; 2
    rts                     ; 6


AsteroidHit SUBROUTINE
; check all asteroids in list for being hit
.btmId      = $f4
.bound      = $f5
.tmpId      = $f6
.tmpVar     = $f7

    stx    .btmId           ; 3
; loop until inactive asteroid is found:
.loop:
    lda    yPosLst,x        ; 4
    bpl    .active          ; 2³
    cmp    #Y_ILLEGAL       ; 2         loop until empty slot found
    bne    .active          ; 2³
    ldx    .bound           ; 3
    rts                     ; 6

.active:
    lda    flagLst,x        ; 4
    tay                     ; 2
    and    #HIT_FLAG        ; 2         Asteroid marked as hit?
    bne    .isHit           ; 2³+1       yes, destroy
.contLoop:
    inx                     ; 2
    bpl    .loop            ; 3

.kill:
    stx    .tmpId           ; 3         save current id
    jsr    RemoveFromLst    ; 6         remove object from list
    dec    .bound           ; 5
    ldx    .tmpId           ; 3         restore current id
    bpl    .loop            ; 3+1       branch is always taken!

.isHit:
    lda    yPosLst,x        ; 4
    bmi    .kill            ; 2³+1
    tya                     ; 2
    and    #SIZE_BITS       ; 2         medium or small
    beq    .large2Medium    ; 2³         no,
    cmp    #MEDIUM_SIZE     ; 2         medium?
    bne    .checkSmall      ; 2³         no
    jmp    Medium2Small     ; 3

.checkSmall:
    cmp    #SMALL_SIZE      ; 2         a small one?
    beq    .kill            ; 3+1       yes

.large2Medium:
    jsr    NextRandom       ; 6
    and    #[FAST_SPEED|$f] ; 2
    ora    #MEDIUM_SIZE     ; 2         make it medium size
    sta    flagLst,x        ; 4
    lda    yPosLst,x        ; 4
    cmp    #H_KERNEL-6      ; 2         asteroid near upper border?
    bcc    .skipInsert      ; 2³         no, skip
    jsr    InsertIntoLst    ; 6          yes, insert into list...
    lda    yPosLst,y        ; 4
    sec                     ; 2
    sbc    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4         ...and move new asteroid down
    inc    .bound           ; 5
.skipInsert:
    bit    game             ; 3         children mode?
    bmi    .contLoop        ; 2³+1       yes, skip second asteroid
    jsr    CheckMem         ; 6         memory for 2nd asteroid?
    bcs    .contLoop        ; 2³+1       no, skip second asteroid
    lda    yPosLst,x        ; 4         asteroid near upper border?
    bmi    .medAsteroid     ; 2³         no
    cmp    #H_KERNEL-10     ; 2
    bcc    .medAsteroid     ; 2³         no

; the old asteroid was near the upper border:
    jsr    InsertIntoLst    ; 6          yes, insert into list
    lda    flagLst,x        ; 4
    and    #$08             ; 2         save direction of other asteroid
    sta    .tmpVar          ; 3
    jsr    NextRandom       ; 6
    and    #[FAST_SPEED|$7] ; 2
    ora    #MEDIUM_SIZE     ; 2         make it medium size
    ora    .tmpVar          ; 3
    eor    #$08             ; 2         use opposite direction here
    sta    flagLst,x        ; 4
    lda    xPosLst,y        ; 4         copy x-position and...
    sta    xPosLst,x        ; 4
    lda    yPosLst,y        ; 4         ...space new y-position by 10 pixel
    clc                     ; 2
    adc    #10              ; 2
    sec                     ; 2
    sbc    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4
    inc    .bound           ; 5         increase boundary
    jmp    .contLoop        ; 3

.medAsteroid:
    lda    .btmId           ; 3         save bottom id (0,9)
    sta    .tmpVar          ; 3
    stx    .btmId           ; 3         and replace with current id
    ldx    .bound           ; 3
    jsr    MoveUpLst        ; 6         make space for new asteroid
    ldx    .btmId           ; 3         increase current id
    inx                     ; 2
    lda    .tmpVar          ; 3         restore bottom id
    sta    .btmId           ; 3
    inc    .bound           ; 5         increase boundary
    lda    flagLst,x        ; 4         save x-direction
    and    #$08             ; 2
    sta    .tmpVar          ; 3
    jsr    NextRandom       ; 6         create new asteroid
    and    #[FAST_SPEED|$7] ; 2
    ora    #MEDIUM_SIZE     ; 2         make it medium size
    ora    .tmpVar          ; 3
    eor    #$08             ; 2         use opposite x-direction here
    sta    flagLst,x        ; 4
    lda    xPosLst-1,x      ; 4         copy x-position and...
    sta    xPosLst,x        ; 4
    lda    yPosLst-1,x      ; 4         ...space new y-position by 10 pixel
    clc                     ; 2
    adc    #10              ; 2
    cmp    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4
    bcs    .insert          ; 2³
    cmp    #H_KERNEL-6      ; 2
    bcs    .insert          ; 2³
    jmp    .contLoop        ; 3

.insert:
    jsr    InsertIntoLst    ; 6
    lda    yPosLst,y        ; 4
    sec                     ; 2
    sbc    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4
    inc    .bound           ; 5         increase boundary
    jmp    .contLoop        ; 3

Medium2Small:
    jsr    NextRandom       ; 6
    and    #[FAST_SPEED|$f] ; 2
    ora    #SMALL_SIZE      ; 2         make it small
    sta    flagLst,x        ; 4
    lda    yPosLst,x        ; 4
    cmp    #H_KERNEL-3      ; 2
    bcc    .contLoopJmp     ; 2³
    jsr    InsertIntoLst    ; 6
    lda    yPosLst,y        ; 4
    sec                     ; 2
    sbc    #H_KERNEL        ; 2
    sta    yPosLst,x        ; 4
    inc    .bound           ; 5         increase boundary
.contLoopJmp:
    jmp    .contLoop        ; 3
;AsteroidHit


RemoveFromLst SUBROUTINE
; moves asteroid-data down one slot
    lda    xPosLst+1,x      ; 4
    sta    xPosLst,x        ; 4
    lda    flagLst+1,x      ; 4
    sta    flagLst,x        ; 4
    lda    yPosLst+1,x      ; 4
    sta    yPosLst,x        ; 4
    inx                     ; 2
    cmp    #Y_ILLEGAL       ; 2
    bne    RemoveFromLst    ; 2³
    rts                     ; 6


SetupAsteroids SUBROUTINE
; creates 4..8 asteroids for new level
.numAsteroids   = $f4

; determine number of asteroids:
    lda    #$00             ; 2         $c0
    bit    game             ; 3         child mode?
    bmi    .setNum          ; 2³+1       yes, make 2 asteroids
    ldx    scoreHigh        ; 3         < 1,000?
    beq    .setNum          ; 2³+1       yes, make 2 asteroids
    ora    #$40             ; 2
    cpx    #$15             ; 2         <15,000?
    bcc    .setNum          ; 2³         yes, make 3 asteroids
    ora    #$80             ; 2          no, make 4 asteroids
.setNum:
    sta    .numAsteroids    ; 3

    ldx    #0               ; 2
    jsr    .make2_4         ; 6
    stx    lwrBound         ; 3
    ldx    #NUM_ASTEROIDS_2 ; 2
    jsr    .make2_4         ; 6
    stx    uprBound         ; 3
    rts                     ; 6

.make2_4:
; this subroutine creates 2..4 asteroids
    lda    #1               ; 2
    sta    yPosLst,x        ; 4
    jsr    GetRandomX       ; 6
    sta    xPosLst,x        ; 4
    jsr    NextRandom       ; 6
    and    #$1f             ; 2         make large asteroid
    sta    flagLst,x        ; 4
    inx                     ; 2

    bit    .numAsteroids    ; 3         how many asteroids?
    bvc    .make1           ; 2³         only one more
    bmi    .make3           ; 2³         three more!
    lda    #21              ; 2
    cpx    #NUM_ASTEROIDS_2 ; 2
    bcs    .make2Low        ; 2³
    bcc    .make2High       ; 3

.make3:
    lda    #21              ; 2
    sta    yPosLst,x        ; 4
    jsr    NextRandom       ; 6
    and    #$e0             ; 2
    ora    #$0a             ; 2
    sta    xPosLst,x        ; 4
    jsr    NextRandom       ; 6
    and    #$1f             ; 2         make large asteroid
    sta    flagLst,x        ; 4
    inx                     ; 2

.make2High:
    lda    #42              ; 2
.make2Low:
    sta    yPosLst,x        ; 4
    jsr    NextRandom       ; 6
    and    #$e0             ; 2
    ora    #$0a             ; 2
    sta    xPosLst,x        ; 4
    jsr    NextRandom       ; 6
    and    #$1f             ; 2         make large asteroid
    sta    flagLst,x        ; 4
    inx                     ; 2

.make1:
    lda    #63              ; 2
    sta    yPosLst,x        ; 4
    jsr    GetRandomX       ; 6
    sta    xPosLst,x        ; 4
    jsr    NextRandom       ; 6
    and    #$1f             ; 2         make large asteroid
    sta    flagLst,x        ; 4
    lda    #Y_ILLEGAL       ; 2
    sta    yPosLst+1,x      ; 4
    rts                     ; 6
;SetupAsteroids


InsertIntoLst SUBROUTINE          ;
; inserts new asteroid into list
.start      = $f5
.moveId     = $f6

    stx    .moveId          ; 3
    ldx    .start           ; 3
    jsr    MoveUpLst        ; 6
; fill now empty slot with new data:
    ldy    .moveId          ; 3
    iny                     ; 2
    lda    xPosLst,y        ; 4
    sta    xPosLst,x        ; 4
    lda    flagLst,y        ; 4
    sta    flagLst,x        ; 4
    rts                     ; 6

MoveUpLst SUBROUTINE
; moves asteroid-data up one slot
.bound      = $f4

    inx                     ; 2
.loop:
    lda    yPosLst,x        ; 4
    sta    yPosLst+1,x      ; 4
    lda    xPosLst,x        ; 4
    sta    xPosLst+1,x      ; 4
    lda    flagLst,x        ; 4
    sta    flagLst+1,x      ; 4
    dex                     ; 2
    cpx    .bound           ; 3
    bpl    .loop            ; 2³
    inx                     ; 2
    rts                     ; 6


CheckMem SUBROUTINE
    lda    $f5              ; 3
    cmp    #NUM_ASTEROIDS_2 ; 2     lwr/upr asteroid?
    bcs    .checkUpr        ; 2³     upr!
    cmp    #6               ; 2
    rts                     ; 6

.checkUpr:
    cmp    #NUM_ASTEROIDS_2+6;2
    rts                     ; 6


CheckSpace SUBROUTINE
; safe space around ship's starting position?
    lda    yPosLst,x        ; 4
    tay                     ; 2
    cmp    #Y_ILLEGAL       ; 2
    bne    .active          ; 2³
    rts                     ; 6         all ok, Z flag set

.active:
; asteroid at horizontal center?
    lda    xPosLst,x        ; 4
    and    #$0f             ; 2
    cmp    #13              ; 2         center column
    beq    .checkCenter     ; 2³
    cmp    #11              ; 2         left of center column
    beq    .checkLR         ; 2³
    cmp    #2               ; 2         right of center column
    beq    .checkLR         ; 2³
.contLoop:
    inx                     ; 2
    bpl    CheckSpace       ; 2³

; The marked four absolute values where forgotten to adjust when converting the
; copyrighted version to PAL. This caused the safe zone to become asymmetric
; in the copyrighted PAL version.
; The values on the right are from the original PAL release.
.checkCenter:
    tya                     ; 2
    bmi    .contLoop        ; 2³
    cmp    #8               ; 2         15 *!*
    bcc    .contLoop        ; 2³
    cmp    #64              ; 2         71 *!*
    bcs    .contLoop        ; 2³
    cmp    #0               ; 2         no safe space, Z flag cleared
    rts                     ; 6

.checkLR:
    tya                     ; 2
    cmp    #24              ; 2         31 *!*
    bcc    .contLoop        ; 2³
    cmp    #56              ; 2         63 *!*
    bcs    .contLoop        ; 2³
    cmp    #0               ; 2         no safe space, Z flag cleared
    rts                     ; 6


ShotRangeTbl:
; up, up/left, left, left/down
    .byte $60, $70, $70, $b0, $90, $b0, $70, $70

XSpeedTbl:                  ; $80 = slow (1/7), $40 = med (1/3), $00 = fast (1)
  IF ORIGINAL
    .byte $80 ; large       1/7
    .byte $80 ; large       1/7
    .byte $80 ; medium      1/7
    .byte $80 ; small       1/7
    .byte $80 ; ???
    .byte $80 ; ???
    .byte $80 ; ???
    .byte $40 ; ???
    .byte $80 ; ???
    .byte $80 ; ???
    .byte $40 ; medium      1/3
    .byte $00 ; small       1/1
    .byte $80 ; ???
    .byte $80 ; ???
  ELSE
    .byte $40 ; large       1/3
    .byte $80 ; large       1/7
    .byte $40 ; medium      1/3
    .byte $40 ; small       1/3
    .byte $80 ; ???
    .byte $80 ; ???
    .byte $80 ; ???
    .byte $40 ; ???          ___
    .byte $80 ; ???
    .byte $80 ; ???
    .byte $00 ; medium      1/1
    .byte $00 ; small       1/1
    .byte $80 ; ???
    .byte $80 ; ???
  ENDIF

RightWrapTbl:
    .byte $40, $00, $64, $00, $66, $67, $68, $69
    .byte $6a, $6b, $63
LeftWrapTbl:
    .byte $6d, $00, $32, $8a, $82, $a3, $84, $85
    .byte $86, $87, $88, $89, $00, $8b

RandomXTbl:
    .byte 6, 4, 5, 6, 7, 9, 7, 5

; tables used to convert hmove/delay into x-pos:
ConvertLoTbl:
    .byte $06, $05, $04, $03, $02, $01, $00, $00
    .byte $0e, $0d, $0c, $0b, $0a, $09, $08, $07
ConvertHiTbl:
; stored interleaved!
    .byte $00, $00
    .byte $55, $00
    .byte $64, $0d
    .byte $73, $1c
    .byte $82, $2b
    .byte $91, $3a
    .byte $00, $49

YSizeTbl:
    .byte 14    ; large asteroid #1
    .byte 14    ; large asteroid #2
    .byte  6    ; medium asteroid
    .byte  3    ; small asteroid
    .byte  4    ; Ship
    .byte  4    ; UFO
    .byte  6    ; Sattelite
    .byte  2    ; Missile
    .byte  2    ; Missile
    .byte  2    ; Missile
    .byte 36    ; ???
XSizeTbl:
    .byte 15    ; large asteroid #1
    .byte 15    ; large asteroid #2
    .byte  7    ; medium asteroid
    .byte  3    ; small asteroid
    .byte  4    ; Ship
    .byte  4    ; UFO
    .byte  6    ; Sattelite
    .byte  2    ; Missile
    .byte  2    ; Missile
    .byte  2    ; Missile
    .byte 36    ; ???

ScoreLoTbl:
    .byte $02 ; + 20 Large Asteroid
    .byte $02 ; + 20   "      "
    .byte $05 ; + 50 Medium   "
    .byte $10 ; +100 Small    "
    .byte $00
    .byte $00
    .byte $20 ; +200 Sattelite
ScoreHiTbl:
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $01 ; +1000 UFO
    .byte $00

LwrBoundTbl:    ; boundaries for asteroids
    .byte -15
    .byte -15
    .byte  -7
    .byte  -4
UprBoundTbl:
    .byte H_KERNEL-14
    .byte H_KERNEL-14
    .byte H_KERNEL-6
    .byte H_KERNEL-3

; tables for adjusting game number:
AdjustFromTbl:
    .byte $60, $c1, $80, $e1
AdjustToTbl:
    .byte $c0, $60, $e0, $40

ThrustTbl:
    .byte -127,-117, -90, -49,  0,  49,  90, 117
    .byte  127, 117,  90,  49,  0, -49, -90,-117

YShotTbl:
    .byte -4, -3, -3, -1,  0,  1,  3,  3
    .byte  4,  3,  3,  1,  0, -1, -3, -3
XShotTbl:
    .byte  0,  1,  3,  3,  4,  3,  3,  1
    .byte  0, -1, -3, -3, -4, -3, -3, -1

SetupScoreJmp:
    lda    #<SetupScore     ; 2
    sta    bswVec           ; 3
    lda    #>SetupScore     ; 2
    sta    bswVec+1         ; 3
    jmp    SwitchBank0      ; 3

;---------------------------------------------------------------
  IF ORIGINAL = 0
CheckDriving SUBROUTINE
    lda    lifesDir         ; 3
    and    #LIFES_MASK      ; 2
    sta    $f4              ; 3

    lda     lastDir
    and     #%11100111
    tay
    eor     lastDir
    sty     lastDir
    lsr
    lsr
    lsr
    tay
    lda     SWCHA
    and     #%11
    asl
    asl
    asl
    ora     lastDir
    sta     lastDir
    lda     SWCHA
    and     #%11
    eor     NextLeftTab,y   ;       works like cmp for beq
    beq     .leftTurn
    eor     #%11
    beq     .rightTurn
;TODO: check for double turn
    bne     .noTurn

.leftTurn:
    inc     lifesDir        ; 5
    .byte   $2c             ;-1     BIT_W
.rightTurn:
    dec    lifesDir         ; 5
.noTurn:
    lda    lifesDir         ; 3
    and    #DIR_MASK        ; 2
    ora    $f4              ; 3
    sta    lifesDir         ; 3

; and finally the original code:
    lda    frameCnt         ; 3
    ror                     ; 2
    rts


NextLeftTab:
    .byte   %01
    .byte   %11
    .byte   %00
    .byte   %10
  ENDIF

    ORG     $efe0, 0
    RORG    $ffe0

SwitchBank0:
    sta    BANK0            ; 4
    jmp    (bswVec)         ; 5

    ORG     $eff6, 0
    RORG    $fff6
  IF NTSC
    .byte $00, $00, $44, $00
  ELSE
    .byte $00, $00, $ff, $00
  ENDIF

    .word START1, START1, START1