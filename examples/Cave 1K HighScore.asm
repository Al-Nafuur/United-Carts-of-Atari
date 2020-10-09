; Cave 1K
; Copyright 2003/2004, Thomas Jentzsch
; Version 1.13

; PlusROM functions for High Score sending added
;  by Wolfgang Stubig (09.10.2020)

; free: 6/4 bytes (NTSC/PAL)


;TODOs
; + High-Score (color change?)
; + walls
; + two height variables
; + change score color when new high score
; + show version number as initial highscore
; x different scoring (lose points when colliding)
; + competition mode (non random), P0 = pro
; + more compact score display code
; + PAL colors assembler switch
; o constant scanline count at reset (TODO: 262/268)
; + PAL timing assembler switch
; + better helicopter explosion (blinking)
; + moving walls?
; + different score coloring (moving walls!)?
; + helicopter sound at start of game (v1.10)

; Difficulties:
; + faster scrolling cave
; + taller walls
; + moving walls
; x helicopter further right
; ? cave moving up and down
; ? cave getting tighter


; Suggestions for 4K version:
; Power-Ups:
;  - Slow the game down
;  - Reduce length of obstacles
;  - Reduce spacing between obstacles
;  - Give you immunity from next 'x' obstacles
; ? helicopter left/right [~32 pixel)

; Switches:
; - RESET           : unused
; - LEFT DIFFICULTY : B = random walls; A = non-random walls
; - RIGHT DIFFICULTY: B = static walls; A = moving walls

TIA_BASE_READ_ADDRESS = $30

    processor 6502
    include vcs.h


;===============================================================================
; A S S E M B L E R - S W I T C H E S
;===============================================================================

MULTI_GAME      = 0

PLUSROM         = 1

VERSION         = $113

  IF MULTI_GAME
BASE_ADR        = $f800
    IF PLUSROM
      ECHO "PlusROM functions and Multi Game can't be used together!"
    ENDIF
  ELSE
BASE_ADR        = $f800
  ENDIF

DEBUG           = 0         ; [0] (+ 1)
TEST            = 0         ; [0] (  0) for testing parameters at maximum difficulty
RANDOM          = 1         ; [1] (- 2) 0 used for debugging
ILLEGAL         = 1         ; [?] (- 3) allow illegal opcodes
EASY_GAME       = 0         ; [0] (+-0) use EASY_GAME = 1 for contest

NTSC_TIM        = 1         ; [1] (+-0) 0 = PAL-50
NTSC_COL        = 1         ; [1] (+ 2) 0 = PAL colors

; features:
Y_MOVE_CAVE     = 0         ; [0] (+36) move cave up and down (needs more ROM!)
X_MOVE_HELI     = 0         ; [0] (+??) allow horizontal helicopter movement
SINGLE_BLADE    = 1         ; [1] (  0) alternative helicopter rotorblades
SCORE_COLOR     = 1         ; [1] (+ 8) different color fur current and high score
FRICTION        = 1         ; [1] (+24) enable friction (damn hard if disabled!)
SHOW_VERSION    = 1         ; [1] (+ 3) show version number as initial high score
COMP_MODE       = 1         ; [1] (+15) add non random variation (P0 difficulty)
FRICTION_MODE   = 0         ; [0] (+ 5) disable friction (P1 difficulty)
RAM_COPTER      = 0         ; [0] (-21) draw helicopter from RAM (allows explosions)
RAM_COLOR       = 1         ; [1] (- 9) store black color in RAM (allows explosions)
MOVE_WALLS      = 1         ; [1] (-25) up and down moving walls
PADDLE          = 0         ; [?] (- 4) support left paddle and right joystick button

;===============================================================================
; C O N S T A N T S
;===============================================================================

SCREEN_W    = 160

BORDER_H    = 8
  IF Y_MOVE_CAVE
CENTER_H    = 133
  ELSE
   IF NTSC_TIM
CENTER_H    = 140
   ELSE
CENTER_H    = 140           ; >143 causes trouble !!!
   ENDIF
  ENDIF
KERNEL_H    = CENTER_H + BORDER_H*2
HELI_H      = 16

RAND_EOR_8  = $b2

  IF NTSC_COL
SCORE_COL           = $0c               ; white
SCORE_RND_COL       = $c9               ; green
SCORE_MOV_COL       = $68               ; magenta
SCORE_RM_COL        = $96               ; blue
HISCORE_COL         = $46               ; red
  ELSE
SCORE_COL           = $0e               ; white
SCORE_RND_COL       = $59               ; green
SCORE_MOV_COL       = $89               ; magenta -> blue ($d4)
HISCORE_COL         = $66               ; red
  ENDIF

; difficulty parameters:
HELI_MAX_X  = 62-9                      ; not used
HELI_X      = 8                         ; x-position of helicopter
HELI_Y      = KERNEL_H/2+HELI_H/2       ; initial y-position of helicopter

 IF NTSC_TIM
  IF EASY_GAME
SPEED_ADD   = $0220
SPEED_MIN   = $2800                     ; 38/980; 40/940, 42/900, 48/760, 50/705
SPEED_MAX   = $5500                     ; maximum cave scrolling speed

THRUST      = 24-3                      ;
GRAVITY     = THRUST*4/3                ;

WALL_MIN_X  = SCREEN_W-HELI_MAX_X-24    ; used for minimum distance between two walls
WALL_MAX_X  = HELI_X+40                 ; no further delay after that distance

WALL_MIN_Y  = 40                        ; starting wall height
WALL_MAX_Y  = CENTER_H-HELI_H*7/2       ; maximum height of wall
  ELSE
SPEED_ADD   = $0238
SPEED_MIN   = $3000                     ; 38/980; 40/940, 42/900, 48/760, 50/705
SPEED_MAX   = $6000                     ; maximum cave scrolling speed

THRUST      = 27+3                      ; 27+3 (+3?)
GRAVITY     = THRUST*4/3-2              ; *4/3(*5/4?)

WALL_MIN_X  = SCREEN_W-HELI_MAX_X-24    ; used for minimum distance between two walls
WALL_MAX_X  = HELI_X+40                 ; no further delay after that distance

WALL_MIN_Y  = 50                        ; starting wall height
WALL_MAX_Y  = CENTER_H-HELI_H*6/2       ; maximum height of wall
  ENDIF
 ELSE ; PAL-50
  IF EASY_GAME
SPEED_ADD   = $0303                     ; = $0220 * (312/262)^2
SPEED_MIN   = $2fa2                     ; = $2800 * (312/262)
SPEED_MAX   = $6538                     ; = $5500 * (312/262)

THRUST      = 30                        ; = 21 * (312/262)^2
GRAVITY     = THRUST*4/3                ;

WALL_MIN_X  = SCREEN_W-HELI_MAX_X-24    ; ==
WALL_MAX_X  = HELI_X+40                 ; ==

WALL_MIN_Y  = 40                        ; ==
WALL_MAX_Y  = CENTER_H-HELI_H*7/2       ; ==
  ELSE
SPEED_ADD   = $032c                     ; = $0238 * (312/262)^2
SPEED_MIN   = $3929                     ; = $3000 * (312/262)
SPEED_MAX   = $7200                     ; = $6000 * (312/262)

THRUST      = 42                        ; = 30 * (312/262)^2
GRAVITY     = THRUST*4/3-3              ;

WALL_MIN_X  = SCREEN_W-HELI_MAX_X-24    ; ==
WALL_MAX_X  = HELI_X+40                 ; ==

WALL_MIN_Y  = 50                        ; ==
WALL_MAX_Y  = CENTER_H-HELI_H*6/2       ; ==
  ENDIF
 ENDIF

HEIGHT_INC  = 2                         ; wall height increasement

   IF PLUSROM
WriteToBuffer     equ $1ff0
WriteSendBuffer   equ $1ff1
ReceiveBuffer     equ $1ff2
ReceiveBufferSize equ $1ff3
   ENDIF


;===============================================================================
; Z P - V A R I A B L E S
;===============================================================================

    SEG.U   variables
    ORG     $98

frameCnt    .byte

xPosCave    .byte
  IF Y_MOVE_CAVE ;{
yPosCave    .byte
  ENDIF ;}
colCave     .byte

; helicopter:
ySpeed      ds 2
ySpeedHi    = ySpeed
ySpeedLo    = ySpeed+1

; scores:
;  IF SCORE_COL
;colScore    .byte
;  ENDIF
score       ds 2
scoreHi     = score
scoreLo     = score+1

  IF RAM_COPTER ;{
ptrHeli0    ds 2
ptrHeli1    ds 2
  ENDIF ;}

  IF RAM_COLOR
ptrHeliCol  ds 2-1
blackCol    ds HELI_H
  ENDIF

;---------------------------------------
; initialized variables start here:
initVars    = .+6

; cave graphics:
PF0Lst      ds BORDER_H
PF1Lst      ds BORDER_H
PF2Lst      ds BORDER_H

random      .byte               ;       random initialization
yHeli       ds 2
yHeliHi     = yHeli
yHeliLo     = yHeli+1           ;       random initialization

speedLst    ds 2
speedCaveHi = speedLst
speedCaveLo = speedLst+1
  IF X_MOVE_HELI ;{
xHeli       .byte
  ELSE ;}
xObjects    ds 5
xHeli0      = xObjects
xHeli1      = xObjects+1
  ENDIF
  IF SHOW_VERSION = 0 ;{
NUM_INITS   = . - initVars - 3
;---------------------------------------
  ENDIF ;}
tmpVar      = xObjects+2        ;       missile 0 is not used!
; walls:
xWall0      = xObjects+3
xWall1      = xObjects+4
xWallLst    = xWall0
yWallLst    ds 2
yWall0      = yWallLst
yWall1      = yWallLst+1
hWallLst    ds 2
hWall0      = hWallLst
hWall1      = hWallLst+1
  IF MOVE_WALLS
dirWallLst    ds 2
dirWall0    = dirWallLst
dirWall1    = dirWallLst+1
  ENDIF
wallLst     = xWallLst
WALL_SIZE   = . - wallLst

; only initialized on START:
mode        .byte
scoreMax    ds 2
scoreMaxHi  = scoreMax
scoreMaxLo  = scoreMax+1
  IF SHOW_VERSION
NUM_INITS   = . - initVars
;---------------------------------------
  ENDIF

; not resetted variables:
;---------------------------------------
; initialized pointers
scorePtr    ds 8
  IF RAM_COLOR = 0
ptrHeliCol  ds 2
  ENDIF
  IF RAM_COPTER = 0
ptrHeli0    ds 2
ptrHeli1    ds 2
  ENDIF
initPtrs    = scorePtr

NUM_PTRS    = . - initPtrs
;---------------------------------------

compMode    .byte

  IF SCORE_COLOR
colScore    .byte
  ENDIF

  IF RAM_COPTER ;{
heliPat     ds HELI_H*2
heliPat0    = heliPat
heliPat1    = heliPat+HELI_H
  ENDIF ;}

  ECHO "*** RAM: ", ., " ***"


;===============================================================================
; M A C R O S
;===============================================================================

  MAC DEBUG_BRK
    IF DEBUG
      brk                         ;
    ENDIF
  ENDM

  MAC BIT_B
    .byte   $24
  ENDM

  MAC BIT_W
    .byte   $2c
  ENDM

  MAC NOP_W
   IF ILLEGAL
    .byte   $0c
   ELSE
    jmp     .label+2
.label:
   ENDIF
  ENDM


  MAC SLEEP
    IF {1} = 1
      ECHO "ERROR: SLEEP 1 not allowed !"
      END
    ENDIF
    IF {1} & 1
     IF ILLEGAL
      nop $00
     ELSE
      bit $00
     ENDIF
      REPEAT ({1}-3)/2
        nop
      REPEND
    ELSE
      REPEAT ({1})/2
        nop
      REPEND
    ENDIF
  ENDM

  MAC CHECKPAGE
    IF >. != >{1}
      ECHO ""
      ECHO "ERROR: different pages! (", {1}, ",", ., ")"
      ECHO ""
      ERR
    ENDIF
  ENDM


;===============================================================================
; R O M - C O D E
;===============================================================================
    SEG     Bank0

  IF MULTI_GAME
    ORG     BASE_ADR-25+4+10+4-23-1+1, 0
  ELSE
    ORG     BASE_ADR, 0
  ENDIF


;***************************************************************
Start SUBROUTINE
;***************************************************************
  IF MULTI_GAME = 0
    cld
  ENDIF
  IF SHOW_VERSION
    ldy     #NUM_INITS
Restart:
    ldx     #mode
  ELSE ;{
    ldy     #-1
    ldx     #0 -1
Restart:
  ENDIF ;}
    lda     #0
    txs
.clearLoop:
    tsx
    pha
    bne     .clearLoop

  IF MULTI_GAME
    ldx     #$ff-7
    txs
  ENDIF

  IF SHOW_VERSION = 0 ;{
    sty     mode
  ENDIF ;}

  IF COMP_MODE
    lda     SWCHB
    sta     compMode
  ENDIF

;---------------------------------------------------------------
GameInit SUBROUTINE
;---------------------------------------------------------------
  IF SHOW_VERSION
.loopInit:
    lda     InitTbl-1,y
    sta     initVars-1,y
    dey
  ELSE ;{
    ldx     #NUM_INITS
.loopInit:
    lda     InitTbl-1,x
    sta     initVars-1,x
    dex
  ENDIF ;}
    bne     .loopInit

    ldx     #NUM_PTRS-1
    lda     #>Zero
.loopPtr:
    sta     initPtrs,x
    dex
    bne     .loopPtr

;---------------------------------------------------------------
MainLoop:
;---------------------------------------------------------------
  IF NTSC_TIM = 0
.waitTim:
    ldy     INTIM
    bne     .waitTim
  ENDIF

;---------------------------------------------------------------
VerticalBlank SUBROUTINE
;---------------------------------------------------------------
  IF NTSC_TIM
    ldx     #44-1-4-2+1
  ELSE
    ldx     #51+1
  ENDIF
    lda     #%00010000          ;       define number/width of
    sta     NUSIZ1              ;        player/missile 1 (used for right wall)
    sta     NUSIZ0              ;        player 0
    lda     #%00011100          ;       define PF priority and width of
    sta     CTRLPF              ;        ball (used for left wall)
    lsr
.waitSync:
    sta     WSYNC
    sta     VSYNC
    lsr
    bne     .waitSync
    stx     TIM64T

;    lda     #%00010100          ;       define PF priority and width of
;    sta     CTRLPF              ;        ball (used for left wall)
;    lsr
;    sta     VSYNC
;.waitSync:
;    ldx     #%00010000          ;       define number/width of
;    stx     NUSIZ1              ;        player/missile 1 (used for right wall)
;    stx     NUSIZ0              ;        player 0
;  IF NTSC_TIM
;    ldx     #44-1-4-2
;  ELSE
;    ldx     #51
;  ENDIF
;    asl
;    sta     WSYNC
;    bcc     .waitSync
;    sta     VSYNC
;    stx     TIM64T

;---------------------------------------------------------------
GameCalc SUBROUTINE
;---------------------------------------------------------------
; still a lot of free time here

; position all objects:
    ldx     #5              ; 2
.loopObjects:
    sta     WSYNC
    lda     xObjects-1,x    ; 4         C=1!
WaitObject:
    sbc     #$0f            ; 2
    bcs     WaitObject      ; 2³

  CHECKPAGE WaitObject

    eor     #$07            ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    sta.wx  RESP0-1,x       ; 5     @23!
    sta     HMP0-1,x        ; 4
    dex                     ; 2
    bne     .loopObjects    ; 2³

; setup helicopter pointers:
  IF RAM_COPTER ;{
    lda     mode
;    beq     .normal
    cmp     #$40
    bcc     .modeOk
    lda     #$10
    BIT_W
.modeOk:
    and     #$0f
;    lsr
    lsr
.normal:
    tax
    lda     ExplosionPat,x
    sta     tmpVar
;    cmp     #$ff
    ldy     #HELI_H*2
.loopCopyHeli:
    lda     Heli0a-1,y
    ldx     mode
    beq     .skipAnd
    and     tmpVar
    rol     tmpVar
.skipAnd:
    sta     heliPat-1,y
    dey
    bne     .loopCopyHeli

    lda     frameCnt
    bit     INPT4
    bpl     .doubleSpeed
    lsr
.doubleSpeed:
    lsr
    lsr
    bcc     .heliA

    sty     heliPat1+HELI_H-2
    lda     #%01111111
    and     tmpVar
    sta     heliPat1+HELI_H-1
    lda     #%11000000
    and     tmpVar
    sta     heliPat0+HELI_H-1
    sta     heliPat0+HELI_H-2
.heliA:

    lda     #<heliPat+HELI_H
    sec
    sbc     yHeliHi
    sta     ptrHeli0
    adc     #HELI_H-1
    sta     ptrHeli1

    lda     #<HeliCol+HELI_H+1
;    sec
    sbc     yHeliHi
    sta     ptrHeliCol
  ELSE ;}
; setup helicopter pointers:
  IF PADDLE
    lda     SWCHA
   IF MULTI_GAME
    asl                         ; right paddle
    asl
    asl
    asl
    and     INPT4               ; left joystick
   ELSE
    and     INPT5
   ENDIF
    asl
    php
    lda     frameCnt
    bcc     .doubleSpeed
  ELSE
    lda     frameCnt
    bit     INPT4
    bpl     .doubleSpeed
  ENDIF
    lsr
.doubleSpeed:
    lsr
    lsr
    lda     #<Heli1a+HELI_H+1
    bcc     .heli0
    lda     #<Heli0a+HELI_H
.heli0:
;    sec
    sbc     yHeliHi
    sta     ptrHeli0
    adc     #HELI_H-1
    sta     ptrHeli1

    ldx     mode
    inx
    txa

   IF RAM_COLOR
    ldx     #<blackCol+HELI_H+1
;    ldy     #>blackCol      ;           = 0!
    and     #$c8
    bne     .blackColor
    ldx     #<(HeliCol+HELI_H+1)
    ldy     #>HeliCol
.blackColor:
    txa
    sty     ptrHeliCol+1
    ldy     #0
   ELSE ;{
    and     #$c8
    bne     .blackColor
    lda     #<HeliCol+HELI_H+1
    BIT_W
.blackColor:
    lda     #<BlackCol+HELI_H+1
   ENDIF ;}
    sbc     yHeliHi
    sta     ptrHeliCol
  ENDIF

; setup score pointers:

  IF SCORE_COLOR
    jsr     CheckHigh       ;           y=0!
    lda     #HISCORE_COL    ;           red
  ENDIF
    ldx     mode
    beq     .currentScore   ;           running
    ldx     frameCnt        ;           stopped
    bpl     .hiScore
    clc
.currentScore:
    bcs     .currentScoreHi
  IF SCORE_COLOR
    lda     #SCORE_COL      ;           white
    bit     compMode
    bpl     .skipWalls
    lda     #SCORE_MOV_COL  ;
.skipWalls:
    bvc     .skipRandom
  IF NTSC_COL
    lda     #SCORE_RND_COL
    bit     compMode
    bpl     .skipRandom
    lda     #SCORE_RM_COL
  ELSE
    adc     #SCORE_RND_COL-SCORE_COL
  ENDIF
  ENDIF
.skipRandom:
    BIT_W
.hiScore:
    ldy     #<(scoreMax-score)
.currentScoreHi:
  IF SCORE_COLOR
    sta     colScore
  ENDIF


;    jsr     CheckHigh       ;           y=0!
;  IF SCORE_COLOR
;    ldx     #HISCORE_COLOR
;   IF COMP_MODE
;    bit     compMode
;    bvc     .skipCompHi
;    ldx     #HISCORE_COMP_COLOR
;.skipCompHi:
;   ENDIF
;  ENDIF
;    lda     mode
;    beq     .currentScore   ;           running
;    lda     frameCnt        ;           stopped
;    bpl     .hiScore
;    clc
;.currentScore:
;    bcs     .currentScoreHi
;  IF SCORE_COLOR
;    ldx     #SCORE_COLOR
;   IF COMP_MODE
;    bvc     .skipComp
;    ldx     #SCORE_COMP_COLOR
;.skipComp:
;   ENDIF
;  ENDIF
;    BIT_W
;.hiScore:
;    ldy     #<(scoreMax-score)
;.currentScoreHi:
;  IF SCORE_COLOR
;    stx     colScore
;  ENDIF
    ldx     #2+1
.loopScore:
    dex
    sty     tmpVar
    lda     score,y
    pha
    lsr
    lsr
    lsr
    lsr
    tay
    lda     DigitTbl,y
    sta     scorePtr,x
    pla
    and     #$0f
    tay
    lda     DigitTbl,y
    sta     scorePtr+4,x
    ldy     tmpVar
    iny
    dex
    bpl     .loopScore

; make explosion sound:
    lda     mode
    beq     .gameRunning
    cmp     #-1
    beq     .heliNoise
;    sta     COLUBK
    cmp     #$20
    bcc     .explosion
    inx
    bcs     .silence

.gameRunning:
; ***** speed-up the cave *****
    lda     frameCnt
    asl
    bne     .skipAccel
    bcs     .skipAddColor
    lda     colCave
;    clc
  IF NTSC_COL
    adc     #$10
  ELSE
    adc     #$20
    bcc     .contCol
    adc     #$0f
.contCol:
  ENDIF
    sta     colCave
.skipAddColor:

; accelerate scrolling by ~4.7%
    ldx     #<speedLst
    lda     #<SPEED_ADD
    ldy     #>SPEED_ADD
    jsr     Add16
    cmp     #>SPEED_MAX
    bcc     .speedOk
    sta     speedCaveHi
.speedOk:
.skipAccel:

; make helicopter noise:
.heliNoise:
    lda     frameCnt        ; 3
    and     #$07            ; 2
  IF PADDLE
    plp                     ; 4
    php                     ; 3
    bcs     .lowNoise       ; 2³
  ELSE
    bit     INPT4           ; 3
    bmi     .lowNoise       ; 2³
  ENDIF
    ora     #$04            ; 2
.lowNoise:
    asl
    adc     #$14            ; 2
    ldx     #$08            ; 2         $02/$08
.explosion:
    sta     AUDF1           ; 3
    stx     AUDC1           ; 3
.silence:
    stx     AUDV1           ; 3
;GameCalc


;***************************************************************
Kernel SUBROUTINE
;***************************************************************
; make sure that the C-flag is always set!

DrawScreen:
.waitTim:
    ldy     INTIM
    bne     .waitTim
    sta     WSYNC
    sta     HMOVE
    sty     VBLANK
;---------------------------------------------------------------
  IF Y_MOVE_CAVE ;{
    lda     yPosCave
    lsr
    ora     #$10
    tax
  ENDIF ;}
    jsr     DrawBorder      ;           @35

    ldy     #KERNEL_H       ; 2
    sta     WSYNC
;---------------------------------------
    ldx     #BORDER_H       ; 2
TopKernel:
.loopTopKernel:             ;           @02
    lda     COLUPFTbl+7,x   ; 4
    ora     colCave         ; 3
    sta     COLUPF          ; 3         @12
    lda     PF0Lst-1,x      ; 4
    sta     PF0             ; 3         @19
    lda     PF1Lst-1,x      ; 4
    sta     PF1             ; 3         @26
    lda     PF2Lst-1,x      ; 4
    sta     PF2             ; 3 = 31    @33

    tya                     ; 2
    sbc     yHeliHi         ; 3
    adc     #HELI_H         ; 2
    bcs     .drawHeliTop    ; 2³

    jsr     .skipDraw       ;23
    beq     .contDrawTop    ; 3

.drawHeliTop:
    lda     (ptrHeli1),y    ; 5
    sta     GRP1            ; 3
    lda     (ptrHeli0),y    ; 5
    sta     GRP0            ; 3
    lda     (ptrHeliCol),y  ; 5
    sta.w   COLUP0          ; 4
.contDrawTop:
    sta     COLUP1          ; 3 = 38    @71

    dey                     ; 2
    dex                     ; 2
;---------------------------------------
    bne     .loopTopKernel  ; 2³=  7

    stx     PF0             ; 3
    stx     PF1             ; 3
    stx     PF2             ; 3         @10

    jsr     Wait14          ;18
    lda     (ptrHeli0,x)    ; 6             x = 0!

    lda     colCave         ; 3
  IF NTSC_COL
    eor     #$8a            ; 2             brightness of walls (bit 1 MUST be set!)
  ELSE
    eor     #$3a            ; 2             brightness of walls (bit 1 MUST be set!)
  ENDIF
    sta     COLUPF          ; 3              (bit 1 must be set, else change code!)
    tax                     ; 2 = 10

; *** center kernel loop ***
.loopCtrKernel:             ;           @40
    stx     COLUP1          ; 3 =  3    @43 je später desto weiter rechts kann der Heli fliegen
                            ;                aber desto größer wird der Mauer-Mindestabstand (@40..46)
    tya                     ; 2
    sbc     yHeliHi         ; 3
    adc     #HELI_H         ; 2
    bcc     .skipDrawCtr    ; 2³
    lda     (ptrHeli1),y    ; 5
    sta     GRP1            ; 3
    lda     (ptrHeli0),y    ; 5
    sta     GRP0            ; 3
    lda     (ptrHeliCol),y  ; 5
    sta     COLUP0          ; 3 = 33    @00
;---------------------------------------
    sta     COLUP1          ; 3 =  3    @03
.contDrawCtr:               ;

    tya                     ; 2
    sbc     yWall1          ; 3
    adc     hWall1          ; 3
    txa                     ; 2             bit 1 set!
    adc     #$ff            ; 2
    sta     ENABL           ; 3 = 15    @18

    tya                     ; 2
    sbc     yWall0          ; 3
    adc     hWall0          ; 3
    txa                     ; 2             bit 1 set!
    adc     #$ff            ; 2
    sta     ENAM1           ; 3 = 15    @33

    dey                     ; 2
    cpy     #BORDER_H       ; 2
    bne     .loopCtrKernel  ; 2³=  6/7

    ldx     #0              ; 2
.loopBtmKernel:             ;           @41
    tya                     ; 2
    sbc     yHeliHi         ; 3
    adc     #HELI_H         ; 2
    bcs     .drawHeliBtm    ; 2³
    jsr     .skipDraw       ;23
    beq     .contDrawBtm    ; 3         @00

;---------------------------------------------------------------
.skipDraw:
    lda     #0              ; 2
    sta.w   GRP1            ; 4
    sta     GRP0            ; 3
Wait14:
    sec                     ; 2
Wait12:
    rts                     ; 6 = 17

.skipDrawCtr:               ;10         @53
    jsr     .skipDraw       ;23
    beq     .contDrawCtr    ; 3         @03
;---------------------------------------------------------------

.drawHeliBtm:
    lda     (ptrHeli1),y    ; 5
    sta     GRP1            ; 3
    lda     (ptrHeli0),y    ; 5
    sta     GRP0            ; 3
    lda     (ptrHeliCol),y  ; 5
    sta.w   COLUP0          ; 4         @00
.contDrawBtm:
;---------------------------------------
    sta     COLUP1          ; 3 = 38    @03

    lda     COLUPFTbl-1,y   ; 4
    ora     colCave         ; 3
    sta     COLUPF          ; 3         @13
    lda     PF0Lst,x        ; 4
    sta     PF0             ; 3         @20
    lda     PF1Lst,x        ; 4
    sta     PF1             ; 3         @27
    lda     PF2Lst,x        ; 4
    sta     PF2             ; 3 = 31    @34

    inx                     ; 2
    dey                     ; 2
    bne     .loopBtmKernel  ; 2³= 6/7

  CHECKPAGE TopKernel

    sty     GRP0
    sty     GRP1

  IF Y_MOVE_CAVE ;{
    ldx     #BORDER_H*4
    lda     yPosCave
    adc     #BORDER_H*2+1
    lsr
    tay
  ENDIF ;}
    jsr     DrawBorder
    sta     WSYNC
;---------------------------------------
  IF Y_MOVE_CAVE ;{
    iny
  ENDIF ;}
    sty     PF0
    sty     PF1
    sty     PF2
    iny                         ;           #%00000001 (two copies close)
    sty     NUSIZ0              ;
    sty     NUSIZ1              ;

    ldy     #DIGIT_HEIGHT
  IF SCORE_COLOR
    lda     colScore
    sta     COLUP0
    sta     COLUP1
  ELSE ;{
    sty     COLUP0
    sty     COLUP1
  ENDIF ;}

; some very tricky coding here :-)
.blockHeight    = ptrHeli0

    lda     #%10011001
    sta     .blockHeight
.nextBlock:
    dey
.contBlock:
  IF ILLEGAL ;{
    sta     WSYNC
;---------------------------------------
    lda     (scorePtr+2),y  ; 5
    sta     GRP1            ; 3         @08
    lda     (scorePtr+6),y  ; 5
    sta     GRP0            ; 3         @16
    lax     (scorePtr+4),y  ; 5
    lda     (scorePtr+0),y  ; 5
    sta     GRP1            ; 3         @29
    stx     GRP0            ; 3         @32
  ELSE ;}
    lda     (scorePtr+2),y  ; 5
    sta     WSYNC
;---------------------------------------
    sta     GRP1            ; 3         @03
    lda     (scorePtr+6),y  ; 5
    sta     GRP0            ; 3         @11
    lda     (scorePtr+4),y  ; 5
    tax                     ; 2
    lda     (scorePtr+0),y  ; 5
    sta.w   GRP1            ; 4         @27
    stx     GRP0            ; 3         @30
  ENDIF
    lsr     .blockHeight    ; 5
    bcs     .nextBlock      ; 2³
    bne     .contBlock      ; 2³

    sty     GRP1
    sty     GRP0
; DrawSceen

;---------------------------------------------------------------
OverScan SUBROUTINE
;---------------------------------------------------------------
  IF NTSC_TIM
    lda     #36-5+1
  ELSE
    lda     #40
  ENDIF
    sta     TIM64T

  IF MULTI_GAME
Select  = $fcb6+1
option  = $fc

    lda     SWCHB
    and     #$02
    bne     .skipMenu
    jmp     Select
.skipMenu:
  ENDIF

  IF PADDLE
    plp
  ELSE
    asl     INPT4
  ENDIF
    ldx     mode
    beq     .gameRunning
    bpl     .contExplosion
;    bcs     .stopExplosion
    bcs     .skipRunning
  IF MULTI_GAME
    inx
    beq     .doReset
    bit     option
    bmi     .skipRunning
.doReset
  ENDIF
  IF SHOW_VERSION
    ldy     #NUM_INITS-3
  ELSE ;{
    ldx     #scoreMaxLo     ; 2         number of resetted values+1
  ENDIF ;}
    brk                     ;           y=0!

.gameRunning:
; ***** collisions: *****
    lda     CXP0FB
    ora     CXP1FB
    and     #$c0
    beq     .skipCollisions

   IF PLUSROM
    jsr     SendPlusROMScore
   ENDIF
    jsr     CheckHigh
    bcc     .skipHigh
    lda     scoreHi
    stx     scoreMaxLo
    sta     scoreMaxHi
.skipHigh:
  IF RAM_COPTER = 0
;    dec     ptrHeliCol+1
;    dec     ptrHeli0+1
;    dec     ptrHeli1+1
  ENDIF
.contExplosion:
    inc     mode
.stopExplosion:
    bne     .skipRunning
    DEBUG_BRK

.skipCollisions:

; ***** vertical helicopter movement: *****
; throttle:
    ldx     #<ySpeed
    lda     #THRUST         ;
    bcc     .doButton
    lda     #-GRAVITY       ;       negative gravity 33% larger!
    dey                     ;       y = 0!
.doButton:
    jsr     Add16

  IF FRICTION
    bmi     .negSpeed
    dey                     ;       y = 0!
.negSpeed:
   IF FRICTION_MODE ;{
    bit     SWCHB
    bmi     .skipFriction
   ENDIF ;}
; friction (the faster, the more):
; (factor = ySpeed / 8)
    lda     ySpeedLo
    and     #%11100000
    asl
    eor     ySpeedHi
    and     #%11100000
    eor     ySpeedHi
;    and     #%00011111
;    sta     tmpVar
;    lda     ySpeedLo
;    and     #%11100000
;    asl
;    ora     tmpVar
    rol
    rol
    rol
    eor     #$ff
    jsr     Add16
   IF FRICTION_MODE ;{
.skipFriction:
   ENDIF ;}
  ENDIF

    tay
    ldx     #<yHeli
    lda     ySpeedLo
    jsr     Add16

; ***** x-move cave *****
    lda     xPosCave
    clc
    adc     speedCaveHi
    sta     xPosCave
    bcs     .moveCave
.skipRunning:
    jmp     .skipMove

.moveCave:
; ***** increase score: *****
    tya                     ;           y = 0!
    ldx     #<score
    sed
    jsr     Add16NC         ;           C = 1!
    cld
; y = 0; C = 0

    ldx     #BORDER_H
.loop:
    lda     PF0Lst-1,x
    and     #$10
    cmp     #$10
    ror     PF2Lst-1,x
    rol     PF1Lst-1,x
    ror     PF0Lst-1,x
    dex
    bne     .loop

; ***** handle walls *****
    inx                     ; 2         x = 1!
.loopMove:
; move wall:
    lda     xWallLst,x
    sec
    sbc     #4
    bcs     .okWall
    tya                     ;           a = 0!
    sta     yWallLst,x
.okWall:
    sta     xWallLst,x

  IF MOVE_WALLS
; handle moving walls
    bit     compMode
    bpl     .skipMoveWall
    lda     yWallLst,x
    beq     .skipMoveWall
    asl     dirWallLst,x
    bcc     .moveUp
    dec     yWallLst,x
    sbc     hWallLst,x
    adc     #CENTER_H-5     ;           C = 1!
    BIT_W
.moveUp:
    inc     yWallLst,x
    cmp     #CENTER_H+BORDER_H
.checkDir:
    ror     dirWallLst,x
.skipMoveWall:
  ENDIF
    dex
    bpl     .loopMove

; sort walls:
; (wall #1 is always *left* of wall #0)

    ldy     xWall1          ; 3
    beq     .doSwap
    lda     xWall0
    beq     .skipSwap
    cmp     xWall1
    bcs     .skipSwap
;    ldy     xWall1          ; 3
;    lda     xWall0
;    beq     .skipSwap
;    tya
;    beq     .doSwap
;    cmp     xWall0
;    bcc     .skipSwap
.doSwap:
; works only if stored consecutive!
    ldx     #WALL_SIZE
.loopSwap:
    lda     wallLst-1,x
    ldy     wallLst-2,x
    sta     wallLst-2,x
    sty     wallLst-1,x
    dex
    dex
    bne     .loopSwap
.skipSwap:

; ***** create new walls: *****
    lda     yWall0
    bne     .skipNewWall
;    ldy     xWall1
    cpy     #WALL_MIN_X             ;       too early for 2nd wall? y = xWall1!
    bcs     .skipNewWall            ;        yes, skip

; NextRandom (was SUBROUTINE)
.nextRandom:
  IF COMP_MODE
    bit     compMode                ; 3
  ENDIF
    lda     random                  ; 3
    lsr                             ; 2
    bcc     .skipEor                ; 2³
    eor     #RAND_EOR_8             ; 2
.skipEor:                           ;
    sta     random                  ; 3

    cpy     #WALL_MAX_X             ; 2     maximum delay for a new wall?

  IF RANDOM
   IF COMP_MODE
    bvc     .skipRandom             ; 2³
   ENDIF
    eor     yHeliLo                 ; 3     ySpeedLo
.skipRandom;
  ENDIF

    bcc     .contNew                ; 2³     yes, don't wait any longer
    bmi     .skipNewWall            ; 2³     no, 50% wait
.contNew:
; minimum: hWall + BORDER_H + 3 (+1)
; maximum: CENTER_H + BORDER_H + 1
    asl                             ; 2     remove high bit and clear carry
    lsr                             ; 2
;    and     #$7f
  IF MOVE_WALLS
    adc     #BORDER_H+HEIGHT_INC+3  ; 2
  ELSE
    adc     #BORDER_H+HEIGHT_INC+2  ; 2
  ENDIF
    adc     hWall0                  ; 3
    cmp     #CENTER_H+BORDER_H+2    ; 2
    bcs     .nextRandom             ; 2³= ..40      .skipNewWall

; create minimum vertical distance between walls:
;  |y_new - y_old|*2 + h_old > HEIGHT
    tay
    sbc     yWall1
  IF MOVE_WALLS
    sta     dirWall0                ; 3
  ENDIF
    bcs     .posDiff
    eor     #$ff
.posDiff:
    asl
    bcs     .createNew
    adc     hWall1
    cmp     #CENTER_H
    bcc     .skipNewWall
.createNew

; finally, create new wall:
    sty     yWall0
    lda     #SCREEN_W-2
    sta     xWall0

; increase wall height:
;    lda     hWall0
;    cmp     #WALL_MAX_Y
;    bcs     .skipNewWall
;    adc     #HEIGHT_INC
;    sta     hWall0
    ldy     hWall1
    cpy     #WALL_MAX_Y
    bcs     .skipNewHeight
    iny
.skipNewHeight:
    sty     hWall0
.skipNewWall:

  IF Y_MOVE_CAVE ;{
; move the cave up and down:
    lda     yPosCave
    lsr
    bcc     .moveUp
    bne     .moveDown
.moveUp:
    cmp     #7
    bcs     .moveDown
    adc     #2
.moveDown:
    rol
    sbc     #1
    sta     yPosCave
; 18 bytes
  ENDIF ;}

; ***** end of cave movement *****
.skipMove:


;.skipRunning:
  IF NTSC_TIM
.waitTim:
    ldy     INTIM
    bne     .waitTim
  ENDIF

    inc     frameCnt

    jmp     MainLoop
; Overscan


;***************************************************************
DrawBorder SUBROUTINE
;***************************************************************
  IF Y_MOVE_CAVE ;{
.min  = tmpVar

    sty     .min
.loop:
    dex                     ; 2
    sta     WSYNC
;---------------------------------------
    txa                     ; 2
    and     #$0f
    tay
    lda     COLUPFTbl,y     ; 4
    ora     colCave         ; 3
    sta     COLUPF          ; 3
    ldy     #$ff            ; 2
    sty     PF0             ; 3     @17
    sty     PF1             ; 3
    sty     PF2             ; 3
    cpx     .min
    bne     .loop           ; 2³
  ELSE ;}
  IF NTSC_TIM
    ldx     #BORDER_H*2-1
  ELSE
    ldx     #BORDER_H*4-1
  ENDIF
.loop:
    sta     WSYNC
;---------------------------------------
  IF NTSC_COL
    lda     COLUPFTbl,x     ; 4
  ELSE
    txa
    and     #$0f
    tay
    lda     COLUPFTbl,y     ; 4
  ENDIF
    ora     colCave         ; 3
    sta     COLUPF          ; 3
    lda     #$ff            ; 2
    sta     PF0             ; 3     @17
    sta     PF1             ; 3
    sta     PF2             ; 3
    dex                     ; 2
    bpl     .loop           ; 2³
    sec                     ; 2
  ENDIF
    rts                     ; 6     @35
; y = 0, C=1
; DrawBorder


;***************************************************************
CheckHigh SUBROUTINE
;***************************************************************
; carry doesn't matter!
  IF ILLEGAL ;{
    lax     scoreLo
  ELSE ;}
    lda     scoreLo
    tax
  ENDIF
    sbc     scoreMaxLo
    lda     scoreHi
    sbc     scoreMaxHi
    rts


;***************************************************************
Add16 SUBROUTINE
;***************************************************************
    clc
Add16NC:
    adc     $01,x
    sta     $01,x
    tya
  IF FRICTION
    ldy     #0
  ENDIF
    adc     $00,x
    sta     $00,x
    rts

CodeEnd:


;===============================================================================
; R O M - T A B L E S
;===============================================================================

  IF >. != >(BASE_ADR + $300)
    align 256
  ENDIF

Y SET . - CodeEnd

  IF MULTI_GAME
   IF NTSC_COL
    ds  2, 0
   ENDIF
  ENDIF

DigitTbl:
    .byte   <Zero,  <One,   <Two,   <Three, <Four
    .byte   <Five,  <Six,   <Seven, <Eight, <Nine

DIGIT_HEIGHT = 9-4

COLUPFTbl = .
    .byte   $00
    .byte        $02, $04, $06, $08, $0a, $0c, $0e
    .byte   $0e, $0c, $0a, $08, $06, $04, $02;, $00

One:
    .byte   %00000000
    .byte   %00001100
Seven:
    .byte   %00000000
    .byte   %00001100
Four:
    .byte   %00000000
    .byte   %00001100
Zero:
    .byte   %01111000
    .byte   %11001100
    .byte   %00000000
    .byte   %11001100
Three:
    .byte   %01111000
    .byte   %00001100
Nine:
    .byte   %01111000
    .byte   %00001100
Eight:
    .byte   %01111000
    .byte   %11001100
Six:
    .byte   %01111000
    .byte   %11001100
Two:
    .byte   %01111000
    .byte   %11000000
Five:
    .byte   %01111000
    .byte   %00001100
    .byte   %01111000
    .byte   %11000000
    .byte   %01111000

  CHECKPAGE One

  IF RAM_COPTER ;{
ExplosionPat:
    .byte   %11111111
;    .byte   %11011111
    .byte   %11111101
;    .byte   %01110111
    .byte   %11011101
;    .byte   %11011101
    .byte   %11010101
;    .byte   %10101101
    .byte   %00101101
;    .byte   %11010010
    .byte   %00101001
;    .byte   %01010010
    .byte   %10000100
;    .byte   %00010010
    .byte   %01000000
;    .byte   %00000100
    .byte   %00000000
  ENDIF ;}

;    .byte   "(C)2004 T.Jentzsch"

DigitEnd:

  IF RAM_COPTER ;{
    ORG     BASE_ADR + $3fc - NUM_INITS - BORDER_H*0 - HELI_H*3 + 1, $68
  ELSE ;}
   IF RAM_COLOR
    IF MULTI_GAME
;     ORG     BASE_ADR + $400 - NUM_INITS - BORDER_H*0 - HELI_H*5    , $68
    ELSE
     ORG     BASE_ADR + $3fc - NUM_INITS - BORDER_H*0 - HELI_H*5    , $68
    ENDIF
   ELSE ;{
    ORG     BASE_ADR + $3fc - NUM_INITS - BORDER_H*0 - HELI_H*6 + 1, $68
   ENDIF ;}
  ENDIF

Y SET Y + . - DigitEnd

InitTbl:
; cave border graphics, copied into PFxLst:
;    .byte   %00000000               ; PF0
;    .byte   %00000000
;    .byte   %00000000
;    .byte   %00000000
;    .byte   %00000000
;    .byte   %00000000
    .byte   %00010000
    .byte   %10110000

    .byte   %00000000               ; PF1
    .byte   %00000000
    .byte   %00000000
    .byte   %00000001
    .byte   %00100011
    .byte   %01110111
    .byte   %11111111
    .byte   %11111111

    .byte   %00000100               ; PF2
    .byte   %00001110
    .byte   %00011111
    .byte   %00111111
    .byte   %01111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111

    .byte   $68                     ; random
    .byte   HELI_Y                  ; yHeliHi
    .byte   0                       ; yHeliLo

  IF TEST ;{
    .byte   >SPEED_MAX              ; speedCaveHi
    .byte   <SPEED_MAX              ; speedCaveLo
  ELSE ;}
    .byte   >(SPEED_MIN-SPEED_ADD)  ; speedCaveHi
    .byte   <(SPEED_MIN-SPEED_ADD)  ; speedCaveLo (is increased at start of game)
  ENDIF
;  IF X_MOVE_HELI
;    .byte   HELI_X                 ; xHeli
;  ELSE
    .byte   HELI_X+8                ; xHeli0
    .byte   HELI_X                  ; xHeli1
;  ENDIF
  IF SHOW_VERSION
    .byte   0                       ; dummy
    .byte   0                       ; xWall0
    .byte   0                       ; xWall1
    .byte   0                       ; yWall0
    .byte   0                       ; yWall1
   IF TEST ;{
    .byte   WALL_MAX_Y              ; hWall0
    .byte   WALL_MAX_Y              ; hWall1
   ELSE ;}
    .byte   WALL_MIN_Y-HEIGHT_INC   ; hWall0
    .byte   WALL_MIN_Y-HEIGHT_INC/2 ; hWall1
   ENDIF
   IF MOVE_WALLS
    .byte   0                       ; dirWall0
    .byte   $80                     ; dirWall1
   ENDIF
    .byte   -1                      ; mode
    .byte   >VERSION                ; scoreHiMax
    .byte   <VERSION                ; scoreLoMax
  ENDIF

  IF <. < KERNEL_H-1
    ORG (. & (BASE_ADR + $300)) + KERNEL_H-1
  ENDIF

  IF SINGLE_BLADE
   IF RAM_COPTER = 0
Heli1a:
    .byte   %11111000
    .byte   %10010100
    .byte   %10010000
    .byte   %11111000
    .byte   %11111110
    .byte   %11111111
    .byte   %11001111
    .byte   %10000111
    .byte   %00000110
    .byte   %00001000
    .byte   %10010000
    .byte   %11100000
    .byte   %11000000
    .byte   %10000000
    .byte   %11000000
    .byte   %11000000
Heli1b:
    .byte   %00000011
    .byte   %00000000
    .byte   %00000000
    .byte   %00000001
    .byte   %00000011
    .byte   %00000011
    .byte   %00000111
    .byte   %00000111
    .byte   %11001111
    .byte   %11111011
    .byte   %11111111
    .byte   %11000011
    .byte   %10000001
    .byte   %00000000
    .byte   %00000000
    .byte   %01111111
   ENDIF
Heli0a:
    .byte   %11111000
    .byte   %10010100
    .byte   %10010000
    .byte   %11111000
    .byte   %11111110
    .byte   %11111111
    .byte   %11001111
    .byte   %10000111
    .byte   %00000110
    .byte   %00001000
    .byte   %10010000
    .byte   %11100000
    .byte   %11000000
    .byte   %10000000
    .byte   %11111111
    .byte   %10000000
Heli0b:
    .byte   %00000011
    .byte   %00000000
    .byte   %00000000
    .byte   %00000001
    .byte   %00000011
    .byte   %00000011
    .byte   %00000111
    .byte   %00000111
    .byte   %10001111
    .byte   %11111011
    .byte   %11111111
    .byte   %11000011
    .byte   %10000001
    .byte   %00000000
    .byte   %00000001
    .byte   %00000001

  ELSE ;{
Heli1a:
    .byte   %11111000
    .byte   %10010100
    .byte   %10010000
    .byte   %11111000
    .byte   %11111110
    .byte   %11111111
    .byte   %11001111
    .byte   %10000111
    .byte   %00000110
    .byte   %00001000
    .byte   %10010000
    .byte   %11100000
    .byte   %11000000
    .byte   %10000000
    .byte   %11111111
    .byte   %10000000
Heli1b:
    .byte   %00000011
    .byte   %00000000
    .byte   %00000000
    .byte   %00000001
    .byte   %00000011
    .byte   %00000011
    .byte   %00000111
    .byte   %00000111
    .byte   %11001111
    .byte   %11111011
    .byte   %11111111
    .byte   %11000011
    .byte   %10000001
    .byte   %00000000
    .byte   %00000000
    .byte   %01111111
Heli0a:
    .byte   %11111000
    .byte   %10010100
    .byte   %10010000
    .byte   %11111000
    .byte   %11111110
    .byte   %11111111
    .byte   %11001111
    .byte   %10000111
    .byte   %00000110
    .byte   %00001000
    .byte   %10010000
    .byte   %11100000
    .byte   %11000000
    .byte   %10000000
    .byte   %10000000
    .byte   %11111111
Heli0b:
    .byte   %00000011
    .byte   %00000000
    .byte   %00000000
    .byte   %00000001
    .byte   %00000011
    .byte   %00000011
    .byte   %00000111
    .byte   %00000111
    .byte   %10001111
    .byte   %11111011
    .byte   %11111111
    .byte   %11000011
    .byte   %10000001
    .byte   %00000000
    .byte   %01111111
    .byte   %00000000
  ENDIF ;}

  IF RAM_COLOR = 0 ;{
BlackCol = . -1
     ds     HELI_H-1, 0
  ENDIF ;}

HeliCol:
  IF NTSC_COL
    .byte   $2c
    .byte   $2a
    .byte   $26
    .byte   $82
    .byte   $84
    .byte   $86
    .byte   $2c
    .byte   $42
    .byte   $44
    .byte   $46
    .byte   $48
    .byte   $44
    .byte   $40
    .byte   $26
    .byte   $08
    .byte   $08
  ELSE
    .byte   $4c
    .byte   $4a
    .byte   $46
    .byte   $b4
    .byte   $b6
    .byte   $b8
    .byte   $4c
    .byte   $62
    .byte   $64
    .byte   $66
    .byte   $68
    .byte   $64
    .byte   $60
    .byte   $46
    .byte   $08
    .byte   $08
  ENDIF

  IF (. != $fbfc) && (MULTI_GAME = 0)
    ECHO "endaddress <> $fbfc!"
  ENDIF

;Y SET $3fc - Y - . + InitTbl
  ECHO "*** Free ", Y, " bytes ***"

  IF MULTI_GAME
    ECHO "DigitTbl =  ", DigitTbl
    ECHO "Zero =      ", Zero
    ECHO "Start =     ", Start
    ECHO "Reset =     ", Restart
  ELSE
   IF PLUSROM
PlusROM_API:
    .byte "a", 0, "h.firmaplus.de", 0
SendPlusROMScore:
    lda SWCHB
    sta WriteToBuffer
    lda scoreHi
    sta WriteToBuffer
    lda scoreLo
    sta WriteToBuffer
    lda #12                  	    ; Cave 1k game id in Highscore DB
    sta WriteSendBuffer              ; send request to backend..
    rts

     org BASE_ADR + $7fa, 0
    .word PlusROM_API - BASE_ADR + $1000
   ELSE
    org BASE_ADR + $7fc, 0
   ENDIF
    .word   Start
    .word   Restart
  ENDIF
