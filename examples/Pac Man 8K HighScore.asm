;Pac-Man 8k
ColorDots = 1 ;change to 0 if no gaps in maze wanted (but lose seperate dot color)
EQUALPTS = 1
CHEAT = 0
INTEST = 0
TEST2 = 0
TEST3 = 0
NO_DOTS_AROUND_BOX = 1
DISABLE_INTERMISSIONS = 0


      processor 6502

;hardware register equates
VSYNC   =  $00 ;Vertical Sync Set-Clear
VBLANK  =  $01 ;Vertical Blank Set-Clear
WSYNC   =  $02 ;Wait for Horizontal Blank
RSYNC   =  $03 ;Reset Horizontal Sync Counter
NUSIZ0  =  $04 ;Number-Size player/missle 0
NUSIZ1  =  $05 ;Number-Size player/missle 1
COLUP0  =  $06 ;Color-Luminance Player 0
COLUP1  =  $07 ;Color-Luminance Player 1
COLUPF  =  $08 ;Color-Luminance Playfield
COLUBK  =  $09 ;Color-Luminance Background
CTRLPF  =  $0A ;Control Playfield, Ball, Collisions
REFP0   =  $0B ;Reflection Player 0
REFP1   =  $0C ;Reflection Player 1
PF0     =  $0D ;Playfield Register Byte 0 (upper nybble used only)
PF1     =  $0E ;Playfield Register Byte 1
PF2     =  $0F ;Playfield Register Byte 2
RESP0   =  $10 ;Reset Player 0
RESP1   =  $11 ;Reset Player 1
RESM0   =  $12 ;Reset Missle 0
RESM1   =  $13 ;Reset Missle 1
RESBL   =  $14 ;Reset Ball
;Audio registers
AUDC0   =  $15 ;Audio Control - Voice 0 (distortion)
AUDC1   =  $16 ;Audio Control - Voice 1 (distortion)
AUDF0   =  $17 ;Audio Frequency - Voice 0
AUDF1   =  $18 ;Audio Frequency - Voice 1
AUDV0   =  $19 ;Audio Volume - Voice 0
AUDV1   =  $1A ;Audio Volume - Voice 1
;Sprite registers
GRP0    =  $1B ;Graphics Register Player 0
GRP1    =  $1C ;Graphics Register Player 1
ENAM0   =  $1D ;Graphics Enable Missle 0
ENAM1   =  $1E ;Graphics Enable Missle 1
ENABL   =  $1F ;Graphics Enable Ball
HMP0    =  $20 ;Horizontal Motion Player 0
HMP1    =  $21 ;Horizontal Motion Player 1
HMM0    =  $22 ;Horizontal Motion Missle 0
HMM1    =  $23 ;Horizontal Motion Missle 1
HMBL    =  $24 ;Horizontal Motion Ball
VDELP0  =  $25 ;Vertical Delay Player 0
VDELP1  =  $26 ;Vertical Delay Player 1
VDELBL  =  $27 ;Vertical Delay Ball
RESMP0  =  $28 ;Reset Missle 0 to Player 0
RESMP1  =  $29 ;Reset Missle 1 to Player 1
HMOVE   =  $2A ;Apply Horizontal Motion
HMCLR   =  $2B ;Clear Horizontal Move Registers
CXCLR   =  $2C ;Clear Collision Latches
Waste1  =  $2D ;Unused
Waste2  =  $2E ;Unused
Waste3  =  $2F ;Unused
;collisions                     (bit 7) (bit 6)
CXM0P   =  $30 ;Read Collision - M0-P1   M0-P0
CXM1P   =  $31 ;Read Collision - M1-P0   M1-P1
CXP0FB  =  $32 ;Read Collision - P0-PF   P0-BL
CXP1FB  =  $33 ;Read Collision - P1-PF   P1-BL
CXM0FB  =  $34 ;Read Collision - M0-PF   M0-BL
CXM1FB  =  $35 ;Read Collision - M1-PF   M1-BL
CXBLPF  =  $36 ;Read Collision - BL-PF   -----
CXPPMM  =  $37 ;Read Collision - P0-P1   M0-M1
INPT0   =  $38 ;Read Pot Port 0
INPT1   =  $39 ;Read Pot Port 1
INPT2   =  $3A ;Read Pot Port 2
INPT3   =  $3B ;Read Pot Port 3
INPT4   =  $3C ;Read Input - Trigger 0 (bit 7)
INPT5   =  $3D ;Read Input - Trigger 1 (bit 7)
;RIOT registers
SWCHA  = $0280 ;Port A data register for joysticks (High nybble:      player0,low nybble:      player1)
SWACNT = $0281 ;Port A data direction register (DDR)
SWCHB  = $0282 ;Port B data (console switches) bit pattern LR--B-SR
SWBCNT = $0283 ;Port B data direction register (DDR)
INTIM  = $0284 ;Timer output
TIMINT = $0285 ;
WasteA = $0286 ;Unused/undefined
WasteB = $0287 ;Unused/undefined
WasteC = $0288 ;Unused/undefined
WasteD = $0289 ;Unused/undefined
WasteE = $028A ;Unused/undefined
WasteF = $028B ;Unused/undefined
WasteG = $028C ;Unused/undefined
WasteH = $028D ;Unused/undefined
WasteI = $028E ;Unused/undefined
WasteJ = $028F ;Unused/undefined
WasteK = $0290 ;Unused/undefined
WasteL = $0291 ;Unused/undefined
WasteM = $0292 ;Unused/undefined
WasteN = $0293 ;Unused/undefined
TIM1T  = $0294 ;set 1 clock interval
TIM8T  = $0295 ;set 8 clock interval
TIM64T = $0296 ;set 64 clock interval
T1024T = $0297 ;set 1024 clock interval



frameCount              = $80
gameTimer               = $81       ; $81 - $82
selectDebounce          = $83
gameSelection           = $84 ;84-86?

waferIndex              = $87
currentPlayerVars       = $88       ; $88 - $9B
;mazeDots                = currentPlayerVars  ; $88 - $97
remainingLives          = currentPlayerVars+16

temporaryPlayerVars     = $9C       ; $9C - $AF
;tempMazeDots            = temporaryPlayerVars
tempRemainingLives      = temporaryPlayerVars+16

currentGhostX    = $B0
objectX          = $B1       ; $B1 - $B5
pacmanX          = objectX
;FruitX           = objectX

ghost0X          = objectX+1
ghost1X          = objectX+2
ghost2X          = objectX+3
ghost3X          = objectX+4

objectY           = $B6       ; $B6 - $BA
pacmanY           = objectY
ghost0Y           = objectY+1
ghost1Y           = objectY+2
ghost2Y           = objectY+3
ghost3Y           = objectY+4

objectDirections        = $BB       ; $BB - $BF
pacmanDirection         = objectDirections
ghostDirections         = objectDirections+1
ghost0Direction         = ghostDirections
ghost1Direction         = ghostDirections+1
ghost2Direction         = ghostDirections+2
ghost3Direction         = ghostDirections+3


SwapP0                  = $C0 ;C0-C3
SwapP1                  = $C4 ;C4-C7


kernelSection           = $C9
mazeIndex               = $CA ;+CB?

playerScore             = $CC       ; $CC - $D1
playerScoreL0           = playerScore
playerScoreL1           = playerScore+1
playerScoreM0           = playerScore+2
playerScoreM1           = playerScore+3
playerScoreH0           = playerScore+4
playerScoreH1           = playerScore+5






kernelPFValues          = $D2       ; $D2 - $D7
kernelLeftPFValues      = kernelPFValues
kernelRightPFValues     = kernelPFValues+3
;--------------------------------------
leftPF0Value            = kernelLeftPFValues
leftPF1Value            = kernelLeftPFValues+1
leftPF2Value            = kernelLeftPFValues+2
rightPF0Value           = kernelRightPFValues
rightPF1Value           = kernelRightPFValues+1
rightPF2Value           = kernelRightPFValues+2
;--------------------------------------
digitPointers           = kernelRightPFValues ; $D5 - $DE

ghostOffset             = $D8
pacmanOffset            = $D9


ghostIndex              = $DB
pacmanIndex             = $DC
ghostPointer            = $DD       ; $DD - $DE
pacmanPointer           = $DF       ; $DF - $E0

kernelEnableVitamin     = $E1
;--------------------------------------
loopCount               = kernelEnableVitamin
digitPointerOffset      = $E2
;--------------------------------------
;tempCharHolder          = digitPointerOffset
kernelPF2Value          = $E3

EnergizerTime           = $E4

ghostEatingDelay        = $E5
playerState             = $E6       ; ct------
                                    ; c = current player (1 = player1 0 = player0)
                                    ; t = game type (0 = 1player 1 = 2player)
gameState               = $E7 ;E7-EB?

vitaminTimer            = $EC
joystickValue           = $ED ;ED-EE?

CopySWCHB               = $EF
backgroundColor         = $F0
playfieldColor          = $F1
ghostColorPtr           = $F2
pacmanColorPtr          = $F3
tempColorPtr            = $F4 ;F4-F5



;f6-ff unassigned



;T1 = $4B
;T2 = $29
T1 = $4B
T2 = $29

Time = $80
Time2 = $00

FrameCounter = frameCount
TM1 = $10
TM2 = $20
TM3 = $20
FruitTimer = vitaminTimer
;IntermissionLines = 62
IntermissionLines = 70


SoundDur = digitPointers
Temp = digitPointers+1
Temp2 = joystickValue
C1 = digitPointers+2
C2 = digitPointers+3
C3 = digitPointers+4
C4 = digitPointers+5
C5 = digitPointers+6

TimeSave = digitPointers+2

WriteToBuffer     equ $1ff0
WriteSendBuffer   equ $1ff1
ReceiveBuffer     equ $1ff2
ReceiveBufferSize equ $1ff3


       ORG $1000
       RORG $D000

	.byte "api.php", #0
	.byte "highscore.firmaplus.de", #0

START1:
       STA    $1FF9                   ;4 switch to bank 2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2


Bootscreen_Bankswitch1:
       STA    $1FF9                   ;4 call bank 2
       JMP    Bootscreen              ;3


Intermission_Bankswitch1:
LD48E:
       STA    $1FF9                   ;4 switch to bank 2

       LDA    playerState             ;3
       AND    #$20                    ;2
       BEQ    No_Intermission         ;2
       JMP    Intermission            ;2
No_Intermission:



;save color pointer
       LDA    #>ColorTbl              ;2
       STA    kernelPFValues+1        ;3
       LDA    #<ColorTbl              ;2
       STA    kernelPFValues          ;3
       LDX    #$05                    ;2
       LDA    CopySWCHB               ;3 $EF = SWCHB
       BMI    LF992                   ;2
       LDA    #<BwTbl                 ;2
       STA    kernelPFValues          ;3
LF992: LDY    backgroundColor,X       ;4
       LDA    (kernelPFValues),Y      ;5 load color
       EOR    gameTimer+1             ;3
;       AND    CopySWCHB               ;3
       STA    backgroundColor,X       ;4
       DEX                            ;2
       BPL    LF992                   ;2


       BIT    vitaminTimer            ;3
       BPL    NoFlashing              ;2
       LDA    frameCount              ;3
       AND    #$10                    ;2
       EOR    #$10                    ;2
       LSR                            ;2
       ORA    playfieldColor          ;3
       STA    playfieldColor          ;3
NoFlashing:





       LDA    pacmanColorPtr          ;3
       STA    COLUP1                  ;3
       LDA    ghostColorPtr           ;3
       STA    COLUP0                  ;3

       STA    WSYNC                   ;3
       LDA    #$20                    ;2
       STA    NUSIZ0                  ;3
       LDX    #$01                    ;2
       TAY                            ;2
       LDA    frameCount              ;3
       AND    #$08                    ;2
       BNE    LD091                   ;2
       LDX    #$0A                    ;2
       NOP                            ;2
LD091: DEX                            ;2
       BNE    LD091                   ;2
       STA    RESM1                   ;3
       STY    HMM1                    ;3
       STY    NUSIZ1                  ;3
;       LDX    #$01                    ;2
       INX                            ;2

LD09C:
       LDY    currentGhostX+1         ;3 load playerX

       LDA    gameState               ;3
       AND    #$02                    ;2
       BEQ    UsePacSprite3           ;2 branch if vitamin not onscreen

       LDA    frameCount              ;3
       AND    #$01                    ;2
       BEQ    UsePacSprite3           ;2 ...and only use alternate frames

       BIT    ghostEatingDelay        ;3
       BMI    UsePacSprite3           ;2 ...also skip displaying fruit if points on-screen

       LDY    #76                     ;2 <-fruit X offset instead
UsePacSprite3:
       INY                            ;2
       TYA                            ;2

;horizontally position Pac-Man (or fruit)
       LDY    #$02                    ;2
       SEC                            ;2
LX0A4: INY                            ;2
       SBC    #$0F                    ;2
       BCS    LX0A4                   ;2
       EOR    #$FF                    ;2
       SBC    #$06                    ;2
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       STA    WSYNC                   ;3
LX0B3: DEY                            ;2
       BPL    LX0B3                   ;2
       STA    RESP0,X                 ;4
       STA    HMP0,X                  ;4


       DEX                            ;2


       LDY    currentGhostX           ;3
       INY                            ;2
       TYA                            ;2

;horizontally position current ghost
       LDY    #$02                    ;2
       SEC                            ;2
LD0A4: INY                            ;2
       SBC    #$0F                    ;2
       BCS    LD0A4                   ;2
       EOR    #$FF                    ;2
       SBC    #$06                    ;2
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       STA    WSYNC                   ;3

;       STA    HMOVE                   ;3
;       NOP                            ;2

LD0B3: DEY                            ;2
       BPL    LD0B3                   ;2

       STA    RESP0,X                 ;4
       STA    HMP0,X                  ;4


       STA    WSYNC                   ;3
       STA    HMOVE                   ;3
       LDY    #$01                    ;2
       LDX    #$07                    ;2

;wait for top of screen
LD0C5: LDA    INTIM                   ;4
       BNE    LD0C5                   ;2
       STA    WSYNC                   ;3
       STY    VBLANK                  ;3
       STA    HMCLR                   ;3
       LDA    backgroundColor         ;3
       STA    COLUBK                  ;3
       STY    mazeIndex               ;3
       DEY                            ;2
       STY    waferIndex              ;3
       STX    kernelSection           ;3
       INX                            ;2
       LDA    #$31                    ;2
       STA    CTRLPF                  ;3
       LDA    playfieldColor          ;3
       STA    COLUPF                  ;3
       JSR    LD06A                   ;6
       LDY    #$FF                    ;2
       STY    PF0                     ;3
       STY    PF1                     ;3
       LDA    #$7F                    ;2
       STA    PF2                     ;3
       JMP    LD313                   ;3
LD0F4:



       LDA    #$00                    ;2
       CPX    pacmanOffset            ;3
       BMI    LD103                   ;2
       LDY    pacmanIndex             ;3
       BMI    LD103                   ;2
       LDA    (pacmanPointer),Y       ;5
       DEY                            ;2
       STY    pacmanIndex             ;3


;       LDA    frameCount              ;3
;       AND    #$01                    ;2
;       BNE    DisplayFruit1           ;2
;       CPX    pacmanOffset            ;3
;       BMI    LD103                   ;2
;       LDY    pacmanIndex             ;3
;       BMI    LD103                   ;2
;       LDA    (pacmanPointer),Y       ;5
;       DEY                            ;2
;       STY    pacmanIndex             ;3
;       JMP    LD103                   ;3
;DisplayFruit1:






LD103: STA    WSYNC                   ;3
       STA    GRP1                    ;3
       LDY    mazeIndex               ;3
       DEY                            ;2
       BEQ    LD176                   ;2
       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars,Y     ;4
       AND    #$0F                    ;2
       TAY                            ;2
       LDA    LDD47,Y                 ;4
       STA    kernelPFValues+2        ;3
       JSR    LD06A                   ;6
       LDA    #$00                    ;2
       STA    ENAM1                   ;3
       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars,Y     ;4
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LDD3F,Y                 ;4
       STA    kernelPFValues+1        ;3
       JSR    LD053                   ;6
       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars,Y     ;4
       BPL    LD13F                   ;2

  IF ColorDots
       LDA    #$40                    ;2
  ELSE
       LDA    #$50                    ;2
  ENDIF
       BNE    LD141                   ;2

  IF ColorDots
LD13F: LDA    #$00                    ;2
  ELSE
LD13F: LDA    #$10                    ;2
  ENDIF

LD141: STA    kernelPFValues          ;3
       LDA.wy currentPlayerVars+4,Y   ;4
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LDD63,Y                 ;4
       STA    kernelPFValues+5        ;3
       JSR    LD06A                   ;6
       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars+4,Y   ;4
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       STA    kernelPFValues+3        ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LDD5B,Y                 ;4
       STA    kernelPFValues+4        ;3
       JSR    LD053                   ;6
       LDA    kernelPFValues+3        ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       AND    #$03                    ;2
       TAY                            ;2
       LDA    LDD57,Y                 ;4
       STA    kernelPFValues+3        ;3
       JMP    LD1F4                   ;3
LD176: LDY    waferIndex              ;3
       LDA.wy currentPlayerVars+8,Y   ;4
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LDD7B,Y                 ;4
       STA    kernelPFValues+2        ;3
       JSR    LD06A                   ;6
;;       LDA    #$00                    ;2
;;       STA    ENAM1                   ;3


;       LDA    kernelEnableVitamin     ;3
;       STA    ENABL                   ;3

       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars+8,Y   ;4
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       AND    #$0F                    ;2
       TAY                            ;2
       LDA    LDD6B,Y                 ;4
       STA    kernelPFValues+1        ;3
       JSR    LD053                   ;6
       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars+8,Y   ;4
       BPL    LD1AC                   ;2

  IF ColorDots
       LDA    #$40                    ;2
  ELSE
       LDA    #$50                    ;2
  ENDIF

       BNE    LD1AE                   ;2

  IF ColorDots
LD1AC: LDA    #$00                    ;2
  ELSE
LD1AC: LDA    #$10                    ;2
  ENDIF

LD1AE: STA    kernelPFValues          ;3
       LDA.wy currentPlayerVars+12,Y  ;4
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LDD63,Y                 ;4
       STA    kernelPFValues+5        ;3
       JSR    LD06A                   ;6
       LDY    waferIndex              ;3
       LDA.wy currentPlayerVars+12,Y  ;4
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       STA    kernelPFValues+3        ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LDD83,Y                 ;4
       STA    kernelPFValues+4        ;3
       JSR    LD053                   ;6
       LDA    kernelEnableVitamin     ;3

;here
;       STA    ENAM0                   ;3
       LDA    kernelPFValues+3        ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       TAY                            ;2
       LDA    LDD47,Y                 ;4
       STA    kernelPFValues+3        ;3
       JMP    LD1F4                   ;3
LD1E5: LDA    kernelPFValues+4        ;3
       STA    PF1                     ;3
       NOP                            ;2
       NOP                            ;2
LD1EB: LDA    kernelPFValues+5        ;3
       STA    PF2                     ;3
       LDA    #$00                    ;2
       JMP    LD246                   ;3
LD1F4: JSR    LD06A                   ;6
       LDA    kernelSection           ;3
       CMP    #$04                    ;2
       BNE    LD209                   ;2

;box pixels
  IF ColorDots
       LDA    #$00                    ;2
  ELSE
       LDA    #$40                    ;2
  ENDIF

       ORA    kernelPFValues+2        ;3
       STA    kernelPFValues+2        ;3

  IF ColorDots
       LDA    #$00                    ;2
  ELSE
       LDA    #$20                    ;2
  ENDIF

       ORA    kernelPFValues+3        ;3
       STA    kernelPFValues+3        ;3
LD209: LDA    #$00                    ;2
       CPX    pacmanOffset            ;3
       BMI    LD218                   ;2
       LDY    pacmanIndex             ;3
       BMI    LD218                   ;2
       LDA    (pacmanPointer),Y       ;5
       DEY                            ;2
       STY    pacmanIndex             ;3
LD218: STA    WSYNC                   ;3
;top line of dots
       STA    GRP1                    ;3

  IF ColorDots
       LDA    #$0E                    ;2
       STA    COLUPF                  ;3
  ENDIF

       LDA    kernelPFValues          ;3
       STA    PF0                     ;3
       LDY    #$30                    ;2
       STY    CTRLPF                  ;3
       LDA    kernelPFValues+1        ;3
       STA    PF1                     ;3
       LDA    kernelPFValues+2        ;3
       STA    PF2                     ;3
       INX                            ;2
       LDA    kernelPFValues+3        ;3
       STA    PF0                     ;3
       CPX    ghostOffset             ;3
       BMI    LD1E5                   ;2
       LDA    kernelPFValues+4        ;3
       STA    PF1                     ;3
       LDY    ghostIndex              ;3
       BMI    LD1EB                   ;2
       LDA    kernelPFValues+5        ;3
       STA    PF2                     ;3
       LDA    (ghostPointer),Y        ;5
       DEY                            ;2
       STY    ghostIndex              ;3
LD246: STA    WSYNC                   ;3
;bottom line of dots
       STA    GRP0                    ;3

  IF ColorDots
       LDA    #$0E                    ;2
       STA    COLUPF                  ;3
  ENDIF

       LDA    kernelPFValues          ;3
       STA    PF0                     ;3
       LDA    kernelPFValues+1        ;3
       STA    PF1                     ;3
       LDA    kernelPFValues+2        ;3
       STA    PF2                     ;3
       NOP                            ;2
       NOP                            ;2
       LDA    kernelPFValues+3        ;3
       STA    PF0                     ;3
       CPX    pacmanOffset            ;3
       BMI    LD278                   ;2
       LDA    kernelPFValues+4        ;3
       STA    PF1                     ;3
       LDY    pacmanIndex             ;3
       BMI    LD27E                   ;2
       LDA    kernelPFValues+5        ;3
       STA    PF2                     ;3
       LDA    (pacmanPointer),Y       ;5
       DEY                            ;2
       STY    pacmanIndex             ;3
LD271:
       LDY    mazeIndex               ;3
       STA    WSYNC                   ;3
       STA    GRP1                    ;3
       LDA    playfieldColor          ;3
       STA    COLUPF                  ;3
       LDA    LDE0A,Y                 ;4
       STA    PF0                     ;3
       LDA    LDE0C,Y                 ;4
       STA    PF1                     ;3
       LDA    #$31                    ;2
       STA    CTRLPF                  ;3
       LDA    kernelPF2Value          ;3
       STA    PF2                     ;3
       LDA    kernelSection           ;3
       CLC                            ;2
       ADC    #$FF                    ;2
       BPL    LD2A5                   ;2
       JMP    LD360                   ;3

LD278: LDA    kernelPFValues+4        ;3
       STA    PF1                     ;3
       NOP                            ;2
       NOP                            ;2

LD27E: LDA    kernelPFValues+5        ;3
       STA    PF2                     ;3
       LDA    #$00                    ;2
       JMP    LD271                   ;3

LD2A5: STA    kernelSection           ;3
       LDA    #$00                    ;2
       INX                            ;2
       CPX    ghostOffset             ;3
       BMI    LD2B7                   ;2
       LDY    ghostIndex              ;3
       BMI    LD2B7                   ;2
       LDA    (ghostPointer),Y        ;5
       DEY                            ;2
       STY    ghostIndex              ;3
LD2B7: STA    WSYNC                   ;3
       STA    GRP0                    ;3
       LDY    #$00                    ;2

;here
;       STY    ENAM0                   ;3
       STY    digitPointerOffset      ;3
       LDA    kernelSection           ;3
       TAY                            ;2
       AND    #$01                    ;2
       STA    mazeIndex               ;3
       INY                            ;2
       TYA                            ;2
       LSR                            ;2
       STA    waferIndex              ;3
       JSR    LD067                   ;6
       LDY    #$01                    ;2
       LDA    frameCount              ;3
       AND    #$08                    ;2
       BNE    LD2DA                   ;2
       LDY    #$03                    ;2
LD2DA: LDA    kernelSection           ;3
       BEQ    LD2E3                   ;2
       CMP    #$06                    ;2
       BNE    LD2EE                   ;2
       DEY                            ;2
LD2E3: LDA    currentPlayerVars+18    ;3
       AND    LDE6C,Y                 ;4
       BEQ    LD2EE                   ;2
       LDA    #$02                    ;2
       STA    digitPointerOffset      ;3
LD2EE: JSR    LD053                   ;6
       LDA    #$00                    ;2
       STA    ENABL                   ;3
       JSR    LD06A                   ;6
       LDA    digitPointerOffset      ;3
       STA    ENAM1                   ;3
       JSR    LD053                   ;6
       JSR    LD06A                   ;6
       LDY    mazeIndex               ;3
       LDA    LDF41,Y                 ;4
       STA    PF0                     ;3
       LDA    LDE0F,Y                 ;4
       STA    PF1                     ;3
       LDA    LDE11,Y                 ;4
       STA    PF2                     ;3
LD313: JSR    LD053                   ;6
       LDA    gameState               ;3
       LDY    kernelSection           ;3
       CPY    #$03                    ;2
       BEQ    LD320                   ;2
       LDA    #$00                    ;2
LD320: STA    loopCount               ;3
       JSR    LD06A                   ;6
       LDY    mazeIndex               ;3
       LDA    LDE0D,Y                 ;4
       LDY    kernelSection           ;3
       CPY    #$04                    ;2
       BNE    LD332                   ;2
       LDA    #$40                    ;2
LD332: STA    kernelPF2Value          ;3
       JSR    LD053                   ;6
       LDA    #$00                    ;2
       INX                            ;2
       CPX    ghostOffset             ;3
       BMI    LD347                   ;2
       LDY    ghostIndex              ;3
       BMI    LD347                   ;2
       LDA    (ghostPointer),Y        ;5
       DEY                            ;2
       STY    ghostIndex              ;3
LD347: STA    WSYNC                   ;3
       STA    GRP0                    ;3
       LDY    mazeIndex               ;3
       STA    GRP0                    ;3
       LDA    LDE0A,Y                 ;4
       STA    PF0                     ;3
       LDA    LDE0C,Y                 ;4
       STA    PF1                     ;3
       LDA    kernelPF2Value          ;3
       STA    PF2                     ;3
       JMP    LD0F4                   ;3
LD360: LDA    #$00                    ;2
       INX                            ;2
       CPX    ghostOffset             ;3
       BMI    LD370                   ;2
       LDY    ghostIndex              ;3
       BMI    LD370                   ;2
       LDA    (ghostPointer),Y        ;5
       DEY                            ;2
       STY    ghostIndex              ;3

;;       STA    HMM0                    ;3
;;       STA    ENAM0                   ;3
;;       STA    RESM0                   ;3

LD370: STA    WSYNC                   ;3
       STA    GRP0                    ;3
       JSR    LD067                   ;6
       JSR    LD067                   ;6
       JSR    LD067                   ;6
       LDA    #$FF                    ;2
       STA    PF0                     ;3
       STA    PF1                     ;3
       LDA    #$7F                    ;2
       STA    PF2                     ;3
;;;       LDA    #$4C                    ;2


       LDA    #T1                     ;2
       STA    TIM64T                  ;4




;draw bottom line of maze
       JSR    LD053                   ;6
       JSR    LD06A                   ;6
       JSR    LD053                   ;6
       LDA    #$03                    ;2
       LDY    #$00                    ;2



       STA    WSYNC                   ;3
       STY    PF0                     ;3
       STY    PF1                     ;3
       STY    PF2                     ;3
       STA    NUSIZ0                  ;3
       STA    NUSIZ1                  ;3
       STA    VDELP0                  ;3
       STA    VDELP1                  ;3
       STY    GRP0                    ;3
       STY    GRP1                    ;3
;colhere
       LDA    gameTimer+1             ;3
       STA    COLUP1                  ;3
       STA    COLUP0                  ;3 @ 36


;       LDX    #$07                    ;2
;       STA    WSYNC                   ;3
;waste 36 cycles
;LD3B8: DEX                            ;2
;       BNE    LD3B8                   ;2
;       NOP                            ;2 @ 36




       STA    RESP0                   ;3
       STA    RESP1                   ;3
       LDA    #$F0                    ;2
       STA    HMP0                    ;3
       STA    WSYNC                   ;3
       STA    HMOVE                   ;3
       STY    COLUBK                  ;3



;colhere
;       LDA    gameTimer+1             ;3
;       BNE    uselogo                 ;2
;       LDA    frameCount              ;3
;       AND    #$08                    ;2
;       BIT    playerState             ;3
;       BPL    uselogo                 ;2
;       LDA    #$00                    ;2
;uselogo:
;       STA    COLUP1                  ;3
;       STA    COLUP0                  ;3


       LDY    #$04                    ;2
       LDA    tempColorPtr+1          ;3
       STA    $DE                     ;3
       JSR    LD3EE                   ;6

       BIT    playerState             ;3
       BVC    LD3E1                   ;2

       STY    WSYNC                   ;3
       STY    COLUBK                  ;3

       LDY    #$05                    ;2
       LDA    tempColorPtr            ;3
;       STA    kernelPFValues          ;3
       STA    $DE                     ;3
       JSR    LD3EE                   ;6

LD3E1:
       STY    WSYNC                   ;3
       STY    COLUBK                  ;3

;;       LDA    #$00                    ;2
;;       STA    VDELP0                  ;3
;;       STA    VDELP1                  ;3




       STA    WSYNC                   ;3
       LDX    remainingLives          ;3
       LDY    tempRemainingLives      ;3
       BIT    playerState             ;3
       BPL    NoSwap                  ;2
       LDY    remainingLives          ;3
       LDX    tempRemainingLives      ;3
NoSwap:
       STX    kernelPFValues          ;3
       STY    kernelPFValues+1        ;3



       LDX    #$09                    ;2
       BIT    CopySWCHB               ;3 $EF = SWCHB
       BMI    Ucolor                  ;2
       LDX    #$24                    ;2
Ucolor:
       LDA    ColorTbl,X              ;4
       STA    COLUP1                  ;3
       INX                            ;2
       LDA    ColorTbl,X              ;4
       STA    COLUP0                  ;3

       LDA    kernelPFValues          ;3
       AND    #$03                    ;2
       BNE    DrawPlayer1             ;2
       STA    COLUP0                  ;3
DrawPlayer1:
       TAX                            ;2
       LDA    Sizes,X                 ;4

       sta NUSIZ0                 ; 3         set the size of both players to



       ldx    #$00                    ;2  
       lda    #$F0                    ;2  
       tay                            ;2  

       STA    WSYNC                   ;3

       STX.w  COLUBK                  ;4
       and    #$0F                    ;2  
       tax                            ;2  
       inx                            ;2  
       sty.w  HMP0                    ;4  
delay_p0:
       dex                            ;2  
       bne    delay_p0                ;2³ 
       stx    RESP0                   ;3  



       STA    WSYNC                   ;3


       LDA    kernelPFValues+1        ;3

       AND    #$03                    ;2
       BNE    DrawPlayer2             ;2
       STA    COLUP1                  ;3
DrawPlayer2:
       TAX                            ;2
       LDA    Sizes,X                 ;4

       sta NUSIZ1                 ; 3         set the size of both players to




       LDA    Xval,X                  ;4


       STA    WSYNC                   ;3

;       lda    #$08                    ;2  
       NOP                            ;2  
       tay                            ;2  
       and    #$0F                    ;2  
       tax                            ;2  
       inx                            ;2  
       sty.w  HMP1                    ;4  
delay_p1:
       dex                            ;2  
       bne    delay_p1                ;2³ 
       stx    RESP1                   ;3  



       STA    WSYNC                   ;3
       STA    HMOVE                   ;3


       LDA    #$05                    ;2
       STA    loopCount               ;3

       lda    FrameCounter            ;3  
       AND    #$08                    ;2
       TAY                            ;2  
       LDX    #$00                    ;2

       BIT    playerState             ;3
       BPL    Playerup                ;2

       TAX                            ;2  
       LDY    #$00                    ;2

Playerup:
LF4B7:
       LDA    LivesBitmap,X           ;3
       STX    WSYNC                   ;3
       STA    GRP1                    ;3
       LDA    LivesBitmap,Y           ;3
       STA    GRP0                    ;3
       INX                            ;2
       INY                            ;2
       DEC    loopCount               ;2
       BPL    LF4B7                   ;2
       LDY    #$00                    ;2

       STY    WSYNC                   ;3
       sty VDELP0                 ; 3         turn off vertical delay for both
       sty VDELP1                 ; 3         player graphics
       sty NUSIZ0                 ; 3         set the size of both players to
       sty NUSIZ1                 ; 3         on copy of each
;       STY    GRP0                    ;3
;       STY    GRP1                    ;3




;extra lives drawn
;       STA    WSYNC                   ;3
;       STY    CTRLPF                  ;3
       JMP    LD48E                   ;3 <- exit (switch banks)





















LD3EE:
       LDX    #$0A                    ;2

LD3F6:
       STX    digitPointerOffset      ;3
       LDA.wy playerScore,Y           ;4
       AND    #$0F                    ;2
       TAX                            ;2
       LDA    LDEF6,X                 ;4
       LDX    digitPointerOffset      ;3
       STA    kernelPFValues,X        ;4

       LDA    #>DGFX                  ;2
       STA    kernelPFValues+1,X      ;3
       STA    kernelPFValues-1,X      ;3

       LDA.wy playerScore,Y           ;4
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       TAX                            ;2
       LDA    LDEF6,X                 ;4
       LDX    digitPointerOffset      ;3
       STA    kernelPFValues-2,X      ;4
       DEX                            ;2
       DEX                            ;2
       DEX                            ;2
       DEX                            ;2
       DEY                            ;2
       DEY                            ;2
       BPL    LD3F6                   ;2
;       LDA    kernelPFValues          ;3
       LDA    $DE                     ;3
       STA    WSYNC                   ;3
       STA    COLUBK                  ;3
       LDY    #$06                    ;2
       STY    loopCount               ;3
LD459: LDY    loopCount               ;3
       LDA    (kernelPFValues+8),Y    ;5 (6/100k spot)
       STA    GRP0                    ;4
       STA    WSYNC                   ;3
       LDA    (kernelPFValues+10),Y   ;5 (6/10k spot)
       STA    GRP1                    ;3
       LDA    (kernelPFValues+4),Y    ;5 (6/1k spot)
       STA    GRP0                    ;3
       LDA    (kernelPFValues+6),Y    ;5 (6/100 spot)
       STA    digitPointerOffset      ;3
       LDA    (kernelPFValues),Y      ;5 (6/10 spot)
       TAX                            ;2
       LDA    (kernelPFValues+2),Y    ;5 (6/0 spot)
       TAY                            ;2
       LDA    digitPointerOffset      ;3
       STA    GRP1                    ;3
       STX    GRP0                    ;3
       STY    GRP1                    ;3

;       LDY    loopCount               ;3
;       LDA    Digit0gfx,Y             ;4
;       STA    GRP0                    ;3

       STY    GRP0                    ;3
       DEC    loopCount               ;5
       BPL    LD459                   ;2
       LDY    #$00                    ;2
       STY    GRP0                    ;3
       STY    GRP1                    ;3
       STY    GRP0                    ;3
       STY    GRP1                    ;3
       RTS                            ;6








LD053: LDA    #$00                    ;2
       CPX    pacmanOffset            ;3
       BMI    LD062                   ;2
       LDY    pacmanIndex             ;3
       BMI    LD062                   ;2
       LDA    (pacmanPointer),Y       ;5
       DEY                            ;2
       STY    pacmanIndex             ;3
LD062: STA    WSYNC                   ;3
       STA    GRP1                    ;3
       RTS                            ;6





LD067: JSR    LD053                   ;6
LD06A: LDA    #$00                    ;2
       INX                            ;2
       CPX    ghostOffset             ;3
       BMI    LD07A                   ;2
       LDY    ghostIndex              ;3
       BMI    LD07A                   ;2
       LDA    (ghostPointer),Y        ;5
       DEY                            ;2
       STY    ghostIndex              ;3
LD07A: STA    WSYNC                   ;3
       STA    GRP0                    ;3
       RTS                            ;6




;       ORG $1512
;       RORG $D512



















Intermission:
       lda    #$00                    ;2  
       sta    FrameCounter            ;3  
       sta    FruitTimer              ;3  
       sta    SoundDur                ;3  
       sta    Temp                    ;3  



       LDA    SWCHB                   ;3 $EF = SWCHB
       and    #$08                    ;2  
       LSR                            ;2  
       TAY                            ;2  
       LDX    #$03                    ;2  
movecolors:
       lda    IntColors,y             ;4  
       sta    C1,X                    ;4  
       INY                            ;2  
       DEX                            ;2  
       bpl    movecolors              ;2³ 


New_Display_Start:
       lda    FruitTimer              ;3  
       tax                            ;2  
       and    #$02                    ;2  
       lsr                            ;2  
       tay                            ;2  
;       lda    Level                   ;3  
;       and    #$1F                    ;2  
;       sta    Temp                    ;3  


       LDA    remainingLives          ;3
       and    #$C0                    ;2  

       BEQ    Intermission1           ;3
       cmp    #$40                    ;2  

       BEQ    Intermission2           ;3
       BNE    Intermission3           ;2³ 

Intermission1:
       txa                            ;2  
       bpl    Intermission1_3         ;2³ 
Part1_2:
       txa                            ;2  
       and    #$06                    ;2  
       lsr                            ;2  
       tax                            ;2  
       lda    LargePacAnim,x          ;4  
       sta    pacmanPointer           ;3  

       lda    FruitTimer              ;3  
       ldx    C1                      ;3  
       stx    Temp                    ;3  
       jsr    Inter_Sub2              ;6  
       clc                            ;2  
       adc    #$10                    ;2  
       cmp    #$84                    ;2  
       bcc    NoErasemonst            ;2³ 
       ldx    #$00                    ;2  
NoErasemonst:
;       sta    ghostIndex              ;3  save to monster
       sta    pacmanIndex             ;3  save to monster

       lda    VulnerableAnim,y        ;4  
       sta    ghostPointer            ;3  
       lda    #$05                    ;2  
       sta    NUSIZ0                  ;3  
       ldy    C4                      ;3  
       txa                            ;2  
       jmp    Move_Intermission       ;3  
Intermission3:
       txa                            ;2  
       bmi    Part3_2                 ;2³ 
Intermission1_3:
       jsr    Inter_Sub               ;6  
       clc                            ;2  
       adc    #$0D                    ;2  
       sta    pacmanIndex             ;3  
       lda    SmallPacAnim,y          ;4  
       sta    pacmanPointer           ;3  
       lda    LethalAnim,y            ;2  
       sta    ghostPointer            ;3  

       ldy    C4                      ;3  
       lda    C2                      ;3  
;       JMP    Move_Intermission       ;3
       BNE    Move_Intermission       ;2

Part3_2:
       txa                            ;2  
       jsr    Inter_Sub2              ;6  
       sta    pacmanIndex             ;3  
       lda    NakedEyesAnim,y         ;4  
       sta    pacmanPointer           ;3  
       lda    NakedAnim,y             ;2  
       sta    ghostPointer            ;3  
       ldy    #$0C                    ;2  

       lda    C3                      ;3  
       bne    Move_Intermission       ;2³ always branch
Intermission2:
       txa                            ;2  
       bmi    Part2_2                 ;2³ 
       lda    SmallPacAnim,y          ;4  
       sta    pacmanPointer           ;3  
       txa                            ;2  
       jsr    Inter_Sub               ;6  
;       cmp    #$31                    ;2  
;       cmp    #$2C                    ;2  
       cmp    #$2C                    ;2  
       bcs    LF9AE                   ;2³ 
       lda    #<Torn                  ;2  
       sta    ghostPointer            ;3  
;       lda    #$38                    ;2  
       lda    #$36                    ;2  
       sta    pacmanIndex             ;3  
       bne    LF9C1                   ;2³ 
LF9AE:
       clc                            ;2  
       adc    #$0D                    ;2  
       sta    pacmanIndex             ;3  
       lda    LethalAnim,y            ;2  
       sta    ghostPointer            ;3  
LF9C1:

       ldy    C4                      ;3  
       lda    C2                      ;3  
       bne    Move_Intermission       ;2³ always branch
Part2_2:
       lda    #$10                    ;2  
       sta    CTRLPF                  ;3  
       lda    FrameCounter            ;3  
       lsr                            ;2  
       lsr                            ;2  
       tay                            ;2  
       bcc    Part22a                 ;2  
       inc    FruitTimer              ;5  
Part22a:
;       lda    #$38                    ;2  
       lda    #$35                    ;2  
       sta    pacmanIndex             ;3  
       sta    ghostIndex              ;3  
       tya                            ;2  
       clc                            ;2  
       adc    #$16                    ;2  
       and    #$10                    ;2  
       lsr                            ;2  
       lsr                            ;2  
       lsr                            ;2  
       lsr                            ;2  
       tay                            ;2  

       lda    TornAnim,y              ;2  
;       lda    #<Torn2                 ;2  
       sta    ghostPointer            ;3  

       lda    FootAnim,y              ;2  
       sta    pacmanPointer           ;3  

       LDY    C4                      ;3  
       lda    C2                      ;3  

Move_Intermission:
       sty    COLUP0                  ;3  
       sta    COLUP1                  ;3  
;;       sta    Temp                    ;3  
       lda    #>IGFX                  ;2  
       sta    pacmanPointer+1         ;3  
       sta    ghostPointer+1          ;3  

       lda    pacmanIndex             ;3  
       tay                            ;2  
       lda    XposTbl2,y               ;4  fetch Xpos value
;added
       bne    PacColorOK              ;2³ 
       sta    COLUP1                  ;3  
       lda    #$06                    ;2  
PacColorOK:
       sta    pacmanIndex             ;3  
       lda    ghostIndex              ;3  
       tay                            ;2  
       bit    FruitTimer              ;3  
       bmi    SameTbl                 ;3
       lda    XposTbl,y               ;4  fetch Xpos value
       JMP    TblLoaded               ;3
SameTbl:
       lda    XposTbl2,y              ;4  fetch Xpos value
TblLoaded:
;added
       bne    MonsterColorOK          ;2³ 
       sta    COLUP0                  ;3  
       lda    #$06                    ;2  
MonsterColorOK:
       sta    ghostIndex              ;3  
;       ldx    #$53                    ;2  50 Scanlines
       ldx    #$49                    ;2  50 Scanlines
       LDA    playerState             ;3
       AND    #$20                    ;2
       beq    InterRetrace_Wait2      ;2³ 
       LDA    playerState             ;3
       AND    #$DF                    ;2
       STA    playerState             ;3
;fudge
       txa                            ;2  
       sec                            ;2  
       sbc    #$0A                    ;2  
       tax                            ;2  
InterRetrace_Wait2:
       inc    FrameCounter            ;5  
       lda    #$02                    ;2  
InterRetrace_Wait:
       ldy    INTIM                   ;4  
       bne    InterRetrace_Wait       ;2³ 
       sty    WSYNC                   ;3  
       sty    VBLANK                  ;3  
       sty    WSYNC                   ;3  
;       ldy    #$25                    ;2  
;       jsr    Boot_Screen_Sub         ;6  
       jsr    Boot_Screen_Top         ;6  

       sty    NUSIZ1                  ;3  
       sty    GRP0                    ;3  
       sty    GRP1                    ;3  
       sty    PF0                     ;3  
       sty    PF1                     ;3  
       sty    PF2                     ;3  
       sty    COLUBK                  ;3  
       jsr    Wait12_2                ;6  
       sta    RESBL                   ;3  

       ldy    #TM3                    ;2  HERE....
       sty    TIM64T                  ;4  



       sty    WSYNC                   ;3  
       lda    pacmanIndex             ;3  
       tay                            ;2  
       and    #$0F                    ;2  
       tax                            ;2  
       inx                            ;2  
       sty    HMP1                    ;3  
Intermission_set_p1:
       dex                            ;2  
       bne    Intermission_set_p1     ;2³ 
       stx    RESP1                   ;3  
       stx    WSYNC                   ;3  
       lda    ghostIndex              ;3  
       tay                            ;2  
       and    #$0F                    ;2  
       tax                            ;2  
       inx                            ;2  
       sty    HMP0                    ;3  
Intermission_set_p0:
       dex                            ;2  
       bne    Intermission_set_p0     ;2³ 
       stx    RESP0                   ;3  

;       stx    RESM0                   ;3  

       stx    WSYNC                   ;3  
       stx    HMOVE                   ;3  

;       lda    Level                   ;3  
;       and    #$1F                    ;2  
       LDA    remainingLives          ;3
       and    #$C0                    ;2  


       sta    WSYNC                   ;3  
       cmp    #$40                    ;2  
       bne    Intermission_add_nail   ;2³ 
       ldy    #$0F                    ;2  
       ldx    #$02                    ;2  
       lda    FruitTimer              ;3  
       cmp    #$54                    ;2  
       BCC    Intermission_add_nail   ;2³ 
       ldy    C2                      ;3  
Intermission_add_nail:
       sty    COLUPF                  ;3  
       lda    #$00                    ;2  
       tay                            ;2  
Intermission_char_loop:
       stx    WSYNC                   ;3  
       stx    WSYNC                   ;3  
       bit    Temp                    ;3  
       bpl    NoGFX                   ;2³ 
       lda    (pacmanPointer),y       ;5  
       sta    GRP0                    ;3  
NoGFX:
       iny                            ;2  
       cpy    #$08                    ;2  
       bne    Intermission_char_loop  ;2³ 
       dey                            ;2  
Intermission_char_loop2:
       stx    WSYNC                   ;3  
       stx    WSYNC                   ;3  
       lda    (pacmanPointer),y       ;5  
       sta    GRP0                    ;3  
       lda    (ghostPointer),y        ;5  
       sta    GRP1                    ;3  
       dey                            ;2  
       bpl    Intermission_char_loop2 ;2³ 
       stx    ENABL                   ;3  
;       ldy    #IntermissionLines      ;2  75 Scanlines
       ldx    #$00                    ;2  
       stx    WSYNC                   ;3  
       stx    WSYNC                   ;3  
       stx    GRP0                    ;3  
       stx    GRP1                    ;3  
       stx    COLUP0                  ;3  
       stx    COLUP1                  ;3  
       stx    WSYNC                   ;3  
       lda    #$0F                    ;2  
       stx    CTRLPF                  ;3  
       sta    COLUPF                  ;3  
       sta    WSYNC                   ;3  
       stx    COLUPF                  ;3  
       stx    ENABL                   ;3  










       ldy    #IntermissionLines      ;2  75 Scanlines
       jsr    Boot_Screen_Bottom       ;6  
       lda    #$02                    ;2  
Retrace_wait_bank2:
       ldx    INTIM                   ;4  Any time left from bank1's share?
       bne    Retrace_wait_bank2      ;2³ loop if so
       sta    WSYNC                   ;3  
       sta    VSYNC                   ;3  
       sta    WSYNC                   ;3  
       ldx    #TM2                    ;2  
       stx    TIM64T                  ;4  reset countdown timer for bank2
       lsr                            ;2  
       sta    WSYNC                   ;3  
       sta    VSYNC                   ;3  turn off TIA





       lda    FrameCounter            ;3  
       and    #$01                    ;2  
       bne    IntermissionMusic_start ;2³ 
       inc    FruitTimer              ;5  
       bne    IntermissionMusic_start ;2³ 
;intermission done
       STA    AUDV0                   ;3
       STA    AUDV1                   ;3
;       STA    AUDF0                   ;3
;       STA    AUDF1                   ;3
;       STA    AUDC0                   ;3
;       STA    AUDC1                   ;3
       lda    #$07                    ;2  
       sta    FruitTimer              ;3  
;       ldx    #TM1                    ;2  HERE....
;       stx    TIM64T                   ;4  
       jmp    Intermission_Bankswitch1 ;3  exit
IntermissionMusic_start:



       ldy    #$05                    ;2  
       inc    SoundDur                ;5  
       lda    SoundDur                ;3  
       lsr                            ;2  
       lsr                            ;2  
       lsr                            ;2  
       tax                            ;2  
       lda    InterMusic0,x           ;4  
       bne    Inter_Play_ch0          ;2³ 
Beat0:
       tay                            ;2  
Inter_Play_ch0:
       sta    AUDF0                   ;3  
       sty    AUDC0                   ;3  
       cpy    #$00                    ;2  
       beq    Inter_NoNote_ch0        ;2³ 
       ldy    #$05                    ;2  
Inter_NoNote_ch0:
       sty    AUDV0                   ;3  
       ldy    #$01                    ;2  
       lda    InterMusic1,x           ;4  
       bne    Inter_Play_ch1          ;2³ 
Beat1:
       tay                            ;2  
Inter_Play_ch1:
       sta    AUDF1                   ;3  
       sty    AUDC1                   ;3  
       cpy    #$00                    ;2  
       beq    Inter_NoNote_ch1        ;2³ 
       ldy    #$05                    ;2  
Inter_NoNote_ch1:
       sty    AUDV1                   ;3  
Inter_Exit:
;       ldx    #TM1                    ;2  HERE....
;       stx    TIM64T                  ;4  


       jmp    New_Display_Start       ;3  exit



Inter_Sub:
       eor    #$7F                    ;2  
Inter_Sub2:
       and    #$7F                    ;2  
       sta    ghostIndex              ;3  
Wait12_2:
       rts                            ;6  






Bootscreen:
       ldy    #$1C                    ;2  
       lda    SWCHB                   ;4
       and    #$08                    ;2  
       bne    NoPal                   ;2³ 
       ldy    #$2C                    ;2  
NoPal:
       sty    COLUPF                  ;3  
;       lda    #$21                    ;2  
;       sta    CTRLPF                  ;3  
Boot_Screen:
       ldy    #$27                    ;2  

       ldx    #$39                    ;2  

       lda    #$02                    ;2  
       sta    WSYNC                   ;3  
       sta    VSYNC                   ;3  
       sta    WSYNC                   ;3  
       lsr                            ;2  
       sta    VSYNC                   ;3  
       jsr    Boot_Screen_Sub         ;6  

       lda    #$FF                    ;2  
       sta    WSYNC                   ;3  
       sta    RESP0                   ;3  
       sta    WSYNC                   ;3  


;show title
       lda    Temp                    ;3  
       sta    COLUP0                  ;3
       and    #$08                    ;2  
       sta    Temp+2                  ;3  
       ldx    #$05                    ;2  

;       jsr    Wait12_2                ;6
;        NOP
;        NOP

Title_Screen_Init:
       ldy    #$09                    ;2  
;       sty    Temp2                   ;3  

		LDA PacMan8K-1,X
		STA GRP0

Title_Screen_Start:
		STA WSYNC

		LDA Screen_PF0-1,X
		STA PF0
		LDA Screen_PF1-1,X
		STA PF1

       bit    Temp+2                  ;3  
       beq    UseA                    ;2³ 
       LDA    Screen_PF2b-1,X         ;4
       jmp    UseB                    ;2³ 
UseA:
       LDA    Screen_PF2a-1,X         ;4
       nop                            ;2  
UseB:
		STA PF2


;       sty    $2E                     ;3  waste
;        NOP
;        NOP
;        NOP
;        NOP


		LDA Screen_PF3-1,X
		STA PF0
		LDA Screen_PF4-1,X
		STA PF1
		LDA Screen_PF5-1,X
		STA PF2


;       DEC    Temp2                   ;5  
       dey                            ;2  
       bne    Title_Screen_Start      ;23 
       dex                            ;2  
       bne    Title_Screen_Init       ;23 






       sta    WSYNC                   ;3  
       stx    GRP0                    ;3  
       stx    PF0                     ;3  X=0
       stx    PF1                     ;3  
       stx    PF2                     ;3  
       sta    WSYNC                   ;3  
;show "2004"
       lda    #$09                    ;2  
       sta    REFP1                   ;3  
       tax                            ;2  
Waste44:
       dex                            ;2  
       bne    Waste44                 ;2³ 
       sty    RESP0                   ;3  
;       ldy    #$88                    ;2  
       ldy    #$88                    ;2  
       sty    RESP1                   ;3  
       sty    HMP0                    ;3  
       sta    HMP1                    ;3  
       sty    WSYNC                   ;3  new scanline
       sty    HMOVE                   ;3  
       lda    #$86                    ;2  fetch the score color
       sta    COLUP0                  ;3  save to both sprites
       sta    COLUP1                  ;3  


       ldy    #$06                    ;2  set year size
Display_Year_loop:
       lda    Year1-1,y               ;4  
       sta    GRP0                    ;3  
       sta    GRP1                    ;3  
       sta    WSYNC                   ;3  new scanline
       dey                            ;2  
       bne    Display_Year_loop       ;2³ loop until all lines done

       sty    REFP1                   ;3  

       ldy    #$56-8                  ;2  
       jsr    Boot_Screen_Bottom       ;6  

       inc    Temp                    ;5  
       lda    Temp                    ;3  
       and    SWCHA                   ;4  
       beq    Boot_Screen_Exit        ;2³ 
       jmp    Boot_Screen             ;3  

Boot_Screen_Exit:
       sta    WSYNC                   ;3  
;       ldx    #TM1-5                  ;2  HERE....
       ldx    #TM1+16                 ;2  HERE....
       stx    TIM64T                  ;4  
       jmp    Bootscreen_Bankswitch1  ;3  








Boot_Screen_Sub:
       lda    #$00                    ;2  
Boot_Screen_Vsync:
       sta    WSYNC                   ;3  
       dey                            ;2  
       bne    Boot_Screen_Vsync       ;2³ 
       sta    VBLANK                  ;3  
Boot_Screen_Top:
       sta    WSYNC                   ;3  
       dex                            ;2  
       bne    Boot_Screen_Top         ;2³ 
       rts                            ;6  






Boot_Screen_Bottom:
       sta    WSYNC                   ;3  
       dey                            ;2  
       bne    Boot_Screen_Bottom      ;2³ 
       lda    #$02                    ;2  
       sta    VBLANK                  ;3  
       ldx    #$1D                    ;2  
Boot_Screen_Overscan:
       sta    WSYNC                   ;3  
       dex                            ;2  
       bpl    Boot_Screen_Overscan    ;2³ 
       rts                            ;6  







;       ORG $1754
;       RORG $D754




























;       ORG $19B8
;       RORG $D9B8

  IF ColorDots
;section 4
LDD83: .byte $00 ; |X       | $FD83
       .byte $01 ; |X      X| $FD84
       .byte $04 ; |X    X  | $FD85
       .byte $05 ; |X    X X| $FD86
       .byte $10 ; |X  X    | $FD87
       .byte $11 ; |X  X   X| $FD88
       .byte $14 ; |X  X X  | $FD89
       .byte $15 ; |X  X X X| $FD8A
  ELSE
;section 4
LDD83: .byte $80 ; |X       | $FD83
       .byte $81 ; |X      X| $FD84
       .byte $84 ; |X    X  | $FD85
       .byte $85 ; |X    X X| $FD86
       .byte $90 ; |X  X    | $FD87
       .byte $91 ; |X  X   X| $FD88
       .byte $94 ; |X  X X  | $FD89
       .byte $95 ; |X  X X X| $FD8A
  ENDIF


LivesBitmap:
       .byte $70 ; | XXX    | $FDE8
       .byte $E0 ; |XXX     | $FDE9
       .byte $C0 ; |XX      | $FDEA
       .byte $E0 ; |XXX     | $FDEB
       .byte $70 ; | XXX    | $FDEC
       .byte $00 ; |        | $FDEC
       .byte $00 ; |        | $FDEC
       .byte $00 ; |        | $FDEC
       .byte $70 ; | XXX    | $FDE8
       .byte $F8 ; |XXXXX   | $FDE9
       .byte $F8 ; |XXXXX   | $FDEA
       .byte $F8 ; |XXXXX   | $FDEB
       .byte $70 ; | XXX    | $FDEC
       .byte $00 ; |        | $FDEC
       .byte $00 ; |        | $FDEC
Year1:
       .byte $00 ; |        | $FC8E shared
       .byte $EE ; |XXX XXX | $FC95
       .byte $8A ; |X   X X | $FC96
       .byte $EA ; |XXX X X | $FC97
       .byte $2A ; |  X X X | $FC98
       .byte $EE ; |XXX XXX | $FC99



PacMan8K:
       .byte $65 ; | XX  X X| $FC8F
       .byte $95 ; |X  X X X| $FC90
       .byte $66 ; | XX  XX | $FC91
       .byte $95 ; |X  X X X| $FC92
Xval:
      .byte $65 ;(shared)
      .byte $EA
      .byte $F9
      .byte $08


IntColors:
       .byte $2C ; |        | $FC8E
       .byte $48 ; |        | $FC8E
       .byte $66 ; |        | $FC8E
       .byte $D3 ; |        | $FC8E

       .byte $1C ; |        | $FC8E
       .byte $28 ; |        | $FC8E
       .byte $36 ; |        | $FC8E
       .byte $83 ; |        | $FC8E

Screen_PF2a
	.byte #%00000111	; Scanline 36
	.byte #%00001111	; Scanline 27
	.byte #%01100001	; Scanline 18
	.byte #%00001111	; Scanline 9
Screen_PF2b
	.byte #%00000111	; Scanline 36 (shared)
	.byte #%00000001	; Scanline 27
	.byte #%01100000	; Scanline 18
	.byte #%00000001	; Scanline 9
	.byte #%00000111	; Scanline 0



Screen_PF0
	.byte #%00110000	; Scanline 36
	.byte #%11110000	; Scanline 27
	.byte #%10110000	; Scanline 18
Screen_PF3
	.byte #%11110000	; Scanline 36 (shared)
	.byte #%11110000	; Scanline 27 (shared)
	.byte #%01110000	; Scanline 18
	.byte #%00110000	; Scanline 9
	.byte #%00010000	; Scanline 0

Screen_PF4
	.byte #%11101111	; Scanline 36
	.byte #%11100101	; Scanline 27
	.byte #%11100011	; Scanline 18
	.byte #%01100001	; Scanline 9
	.byte #%00100000	; Scanline 0

Screen_PF5
	.byte #%01111101	; Scanline 36
	.byte #%01111101	; Scanline 27
	.byte #%01011101	; Scanline 18
	.byte #%01001101	; Scanline 9
	.byte #%01000101	; Scanline 0

       ORG $1900
       RORG $D900


;intermission GFX
IGFX:
Lethal1:
       .byte $11 ; |   X   X| $FDA3
       .byte $BB ; |X XXX XX| $FDA4
       .byte $FF ; |XXXXXXXX| $FDA5
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FDA9
       .byte $3C ; |  XXXX  | $FDAA

Lethal2:
       .byte $88 ; |X   X   | $FD8B
       .byte $DD ; |XX XXX X| $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FD91
       .byte $3C ; |  XXXX  | $FD92


Foot2:
       .byte $03 ; |      XX| $FD02
       .byte $02 ; |      X | $FD03
       .byte $00 ; |        | $FD04
       .byte $00 ; |        | $FD05
       .byte $24 ; |  X  X  | $FD08
NakedEyes1:
       .byte $00 ; |        | $FDC4 (shared)
       .byte $00 ; |        | $FDC5 (shared)
       .byte $00 ; |        | $FDC6 (shared)
       .byte $00 ; |        | $FDC8
       .byte $00 ; |        | $FDCE
       .byte $24 ; |  X  X  | $FDC9
       .byte $36 ; |  XX XX | $FDCA
       .byte $00 ; |        | $FDCE







Vulnerable1:
       .byte $11 ; |   X   X| $FD20
       .byte $BB ; |X XXX XX| $FD21
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $F3 ; |XXXX  XX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $ED ; |XXX XX X| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F

Vulnerable2:
       .byte $88 ; |X   X   | $FD08
       .byte $DD ; |XX XXX X| $FD09
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $F3 ; |XXXX  XX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $ED ; |XXX XX X| $FD0D
       .byte $7E ; | XXXXXX | $FD0E
       .byte $3C ; |  XXXX  | $FD0F




Torn:
       .byte $8B ; |X   X XX| $FD8B
       .byte $DF ; |XX XXXXX| $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FD91
       .byte $3C ; |  XXXX  | $FD92


Torn2:
       .byte $8B ; |X   X XX| $FD8B
       .byte $DC ; |XX XXX  | $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FD91
       .byte $3C ; |  XXXX  | $FD92



Torn3:
       .byte $8B ; |X   X XX| $FD8B
       .byte $DC ; |XX XXX  | $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $DB ; |XX XX XX| $FDA6
       .byte $DB ; |XX XX XX| $FD97
       .byte $FF ; |XXXXXXXX| $FD90
       .byte $7E ; | XXXXXX | $FD91
Spac1:
       .byte $3C ; |  XXXX  | $FDB5 shared
       .byte $7E ; | XXXXXX | $FDB6
       .byte $FF ; |XXXXXXXX| $FDB7
       .byte $FF ; |XXXXXXXX| $FDB8
       .byte $FF ; |XXXXXXXX| $FDB8
       .byte $FF ; |XXXXXXXX| $FDB9
       .byte $7E ; | XXXXXX | $FDBA
Spac2:
       .byte $3C ; |  XXXX  | $FDBB shared
       .byte $7E ; | XXXXXX | $FDBC
       .byte $1F ; |   XXXXX| $FDBD
       .byte $07 ; |     XXX| $FDBE
       .byte $07 ; |     XXX| $FDBE
       .byte $1F ; |   XXXXX| $FDBF
       .byte $7E ; | XXXXXX | $FDC0
       .byte $3C ; |  XXXX  | $FDCE







Naked1:
       .byte $6F ; | XX XXXX| $FD8E
       .byte $3E ; |  XXXXX | $FD8F
       .byte $7C ; | XXXXX  | $FD90
       .byte $7E ; | XXXXXX | $FD91
       .byte $64 ; | XX  X  | $FD92
       .byte $36 ; |  XX XX | $FD93
NakedEyes2:
       .byte $00 ; |        | $FDDA (shared)
       .byte $00 ; |        | $FDDB (shared)
       .byte $00 ; |        | $FDDC
       .byte $00 ; |        | $FDDD
       .byte $00 ; |        | $FDDE
       .byte $00 ; |        | $FDDF
       .byte $12 ; |   X  X | $FDE0
       .byte $1B ; |   XX XX| $FDE1





Lpac1:
       .byte $18 ; |   XX   | $FD63
       .byte $3C ; |  XXXX  | $FD64
       .byte $7E ; | XXXXXX | $FD65
       .byte $7E ; | XXXXXX | $FD66
       .byte $FF ; |XXXXXXXX| $FD67
       .byte $FF ; |XXXXXXXX| $FD68
       .byte $FF ; |XXXXXXXX| $FD69
       .byte $FF ; |XXXXXXXX| $FD6B

Lpac2:
       .byte $18 ; |   XX   | $FD71
       .byte $3C ; |  XXXX  | $FD72
       .byte $7E ; | XXXXXX | $FD73
       .byte $7E ; | XXXXXX | $FD74
       .byte $FF ; |XXXXXXXX| $FD75
       .byte $FC ; |XXXXXX  | $FD76
       .byte $F0 ; |XXXX    | $FD77
       .byte $F0 ; |XXXX    | $FD79

Lpac3:
       .byte $18 ; |   XX   | $FD7F
       .byte $3C ; |  XXXX  | $FD80
       .byte $7E ; | XXXXXX | $FD81
       .byte $7C ; | XXXXX  | $FD82
       .byte $F8 ; |XXXXX   | $FD83
       .byte $F0 ; |XXXX    | $FD84
       .byte $E0 ; |XXX     | $FD85
Naked2:
       .byte $C0 ; |XX      | $FD87 shared
       .byte $7C ; | XXXXX  | $FD1E
       .byte $38 ; |  XXX   | $FD1F
       .byte $3C ; |  XXXX  | $FD20
       .byte $1F ; |   XXXXX| $FD21
       .byte $12 ; |   X  X | $FD22
       .byte $1B ; |   XX XX| $FD23
       .byte $00 ; |        | $FDC8



Foot1:
       .byte $03 ; |      XX| $FDD8
       .byte $02 ; |      X | $FDD9
XposTbl2:
       .byte $00 ; |        | $FDDF (shared)
       .byte $00 ; |        | $FDDF (shared)
       .byte $00 ; |        | $FDDF (shared)
       .byte $00 ; |        | $FDDF (shared)
       .byte $00 ; |        | $FDDF (shared)
       .byte $00 ; |        | $DC84
       .byte $00 ; |        | $DC84
       .byte $F1 ; |XXXX   X| $DC00
       .byte $E1 ; |XXX    X| $DC01
       .byte $D1 ; |XX X   X| $DC02
       .byte $C1 ; |XX     X| $DC03
       .byte $B1 ; |X XX   X| $DC04
       .byte $A1 ; |X X    X| $DC05
       .byte $91 ; |X  X   X| $DC06
       .byte $81 ; |X      X| $DC07
       .byte $52 ; | X X  X | $DC09
       .byte $42 ; | X    X | $DC0A
       .byte $32 ; |  XX  X | $DC0B
       .byte $22 ; |  X   X | $DC0C
       .byte $12 ; |   X  X | $DC0D
       .byte $02 ; |      X | $DC0E
       .byte $F2 ; |XXXX  X | $DC0F
       .byte $E2 ; |XXX   X | $DC10
       .byte $D2 ; |XX X  X | $DC11
       .byte $C2 ; |XX    X | $DC12
       .byte $B2 ; |X XX  X | $DC13
       .byte $A2 ; |X X   X | $DC14
       .byte $92 ; |X  X  X | $DC15
       .byte $82 ; |X     X | $DC16
       .byte $53 ; | X X  XX| $DC18
       .byte $43 ; | X    XX| $DC19
       .byte $33 ; |  XX  XX| $DC1A
       .byte $23 ; |  X   XX| $DC1B
       .byte $13 ; |   X  XX| $DC1C
       .byte $03 ; |      XX| $DC1D
       .byte $F3 ; |XXXX  XX| $DC1E
       .byte $E3 ; |XXX   XX| $DC1F
       .byte $D3 ; |XX X  XX| $DC20
       .byte $C3 ; |XX    XX| $DC21
       .byte $B3 ; |X XX  XX| $DC22
       .byte $A3 ; |X X   XX| $DC23
       .byte $93 ; |X  X  XX| $DC24
       .byte $83 ; |X     XX| $DC25
       .byte $54 ; | X X X  | $DC27
       .byte $44 ; | X   X  | $DC28
       .byte $34 ; |  XX X  | $DC29
       .byte $24 ; |  X  X  | $DC2A
       .byte $14 ; |   X X  | $DC2B
       .byte $04 ; |     X  | $DC2C
       .byte $F4 ; |XXXX X  | $DC2D
       .byte $E4 ; |XXX  X  | $DC2E
       .byte $D4 ; |XX X X  | $DC2F
       .byte $C4 ; |XX   X  | $DC30
       .byte $B4 ; |X XX X  | $DC31
       .byte $A4 ; |X X  X  | $DC32
       .byte $94 ; |X  X X  | $DC33
       .byte $84 ; |X    X  | $DC34
       .byte $55 ; | X X X X| $DC36
       .byte $45 ; | X   X X| $DC37
       .byte $35 ; |  XX X X| $DC38
       .byte $25 ; |  X  X X| $DC39
       .byte $15 ; |   X X X| $DC3A
       .byte $05 ; |     X X| $DC3B
       .byte $F5 ; |XXXX X X| $DC3C
       .byte $E5 ; |XXX  X X| $DC3D
       .byte $D5 ; |XX X X X| $DC3E
       .byte $C5 ; |XX   X X| $DC3F
       .byte $B5 ; |X XX X X| $DC40
       .byte $A5 ; |X X  X X| $DC41
       .byte $95 ; |X  X X X| $DC42
       .byte $85 ; |X    X X| $DC43
       .byte $56 ; | X X XX | $DC45
       .byte $46 ; | X   XX | $DC46
       .byte $36 ; |  XX XX | $DC47
       .byte $26 ; |  X  XX | $DC48
       .byte $16 ; |   X XX | $DC49
       .byte $06 ; |     XX | $DC4A
       .byte $F6 ; |XXXX XX | $DC4B
       .byte $E6 ; |XXX  XX | $DC4C
       .byte $D6 ; |XX X XX | $DC4D
       .byte $C6 ; |XX   XX | $DC4E
       .byte $B6 ; |X XX XX | $DC4F
       .byte $A6 ; |X X  XX | $DC50
       .byte $96 ; |X  X XX | $DC51
       .byte $86 ; |X    XX | $DC52
       .byte $57 ; | X X XXX| $DC54
       .byte $47 ; | X   XXX| $DC55
       .byte $37 ; |  XX XXX| $DC56
       .byte $27 ; |  X  XXX| $DC57
       .byte $17 ; |   X XXX| $DC58
       .byte $07 ; |     XXX| $DC59
       .byte $F7 ; |XXXX XXX| $DC5A
       .byte $E7 ; |XXX  XXX| $DC5B
       .byte $D7 ; |XX X XXX| $DC5C
       .byte $C7 ; |XX   XXX| $DC5D
       .byte $B7 ; |X XX XXX| $DC5E
       .byte $A7 ; |X X  XXX| $DC5F
       .byte $97 ; |X  X XXX| $DC60
       .byte $87 ; |X    XXX| $DC61
       .byte $58 ; | X XX   | $DC63
       .byte $48 ; | X  X   | $DC64
       .byte $38 ; |  XXX   | $DC65
       .byte $28 ; |  X X   | $DC66
       .byte $18 ; |   XX   | $DC67
       .byte $08 ; |    X   | $DC68
       .byte $F8 ; |XXXXX   | $DC69
       .byte $E8 ; |XXX X   | $DC6A
       .byte $D8 ; |XX XX   | $DC6B
       .byte $C8 ; |XX  X   | $DC6C
       .byte $B8 ; |X XXX   | $DC6D
       .byte $A8 ; |X X X   | $DC6E
       .byte $98 ; |X  XX   | $DC6F
       .byte $88 ; |X   X   | $DC70
       .byte $59 ; | X XX  X| $DC72
       .byte $49 ; | X  X  X| $DC73
       .byte $39 ; |  XXX  X| $DC74
       .byte $29 ; |  X X  X| $DC75
       .byte $19 ; |   XX  X| $DC76
       .byte $09 ; |    X  X| $DC77
       .byte $F9 ; |XXXXX  X| $DC78
       .byte $E9 ; |XXX X  X| $DC79
       .byte $D9 ; |XX XX  X| $DC7A
       .byte $C9 ; |XX  X  X| $DC7B
       .byte $B9 ; |X XXX  X| $DC7C
       .byte $A9 ; |X X X  X| $DC7D
       .byte $99 ; |X  XX  X| $DC7E
       .byte $89 ; |X   X  X| $DC7F
       .byte $5A ; | X XX X | $DC81
       .byte $4A ; | X  X X | $DC82
       .byte $3A ; |  XXX X | $DC83
       .byte $2A ; |  X X X | $DC84
       .byte $1A ; |  X X X | $DC84
       .byte $0A ; |  X X X | $DC84
       .byte $FA ; |  X X X | $DC84


;       ORG $1B00
;       RORG $DB00


XposTbl:
       .byte $00 ; |  X X X | $DC84 shared
       .byte $00 ; |  X X X | $DC84 shared
       .byte $00 ; |  X X X | $DC84 shared
       .byte $00 ; |  X X X | $DC84 shared
       .byte $00 ; |  X X X | $DC84 shared
       .byte $00 ; |  X X X | $DC84 shared
       .byte $00 ; |  X X X | $DC84 shared
       .byte $81 ; |X      X| $DC07
       .byte $62 ; | XX   X | $DC08
       .byte $52 ; | X X  X | $DC09
       .byte $42 ; | X    X | $DC0A
       .byte $32 ; |  XX  X | $DC0B
       .byte $22 ; |  X   X | $DC0C
       .byte $12 ; |   X  X | $DC0D
       .byte $02 ; |      X | $DC0E
       .byte $F2 ; |XXXX  X | $DC0F
       .byte $E2 ; |XXX   X | $DC10
       .byte $D2 ; |XX X  X | $DC11
       .byte $C2 ; |XX    X | $DC12
       .byte $B2 ; |X XX  X | $DC13
       .byte $A2 ; |X X   X | $DC14
       .byte $92 ; |X  X  X | $DC15
       .byte $82 ; |X     X | $DC16
       .byte $63 ; | XX   XX| $DC17
       .byte $53 ; | X X  XX| $DC18
       .byte $43 ; | X    XX| $DC19
       .byte $33 ; |  XX  XX| $DC1A
       .byte $23 ; |  X   XX| $DC1B
       .byte $13 ; |   X  XX| $DC1C
       .byte $03 ; |      XX| $DC1D
       .byte $F3 ; |XXXX  XX| $DC1E
       .byte $E3 ; |XXX   XX| $DC1F
       .byte $D3 ; |XX X  XX| $DC20
       .byte $C3 ; |XX    XX| $DC21
       .byte $B3 ; |X XX  XX| $DC22
       .byte $A3 ; |X X   XX| $DC23
       .byte $93 ; |X  X  XX| $DC24
       .byte $83 ; |X     XX| $DC25
       .byte $64 ; | XX  X  | $DC26
       .byte $54 ; | X X X  | $DC27
       .byte $44 ; | X   X  | $DC28
       .byte $34 ; |  XX X  | $DC29
       .byte $24 ; |  X  X  | $DC2A
       .byte $14 ; |   X X  | $DC2B
       .byte $04 ; |     X  | $DC2C
       .byte $F4 ; |XXXX X  | $DC2D
       .byte $E4 ; |XXX  X  | $DC2E
       .byte $D4 ; |XX X X  | $DC2F
       .byte $C4 ; |XX   X  | $DC30
       .byte $B4 ; |X XX X  | $DC31
       .byte $A4 ; |X X  X  | $DC32
       .byte $94 ; |X  X X  | $DC33
       .byte $84 ; |X    X  | $DC34
       .byte $65 ; | XX  X X| $DC35
       .byte $55 ; | X X X X| $DC36
       .byte $45 ; | X   X X| $DC37
       .byte $35 ; |  XX X X| $DC38
       .byte $25 ; |  X  X X| $DC39
       .byte $15 ; |   X X X| $DC3A
       .byte $05 ; |     X X| $DC3B
       .byte $F5 ; |XXXX X X| $DC3C
       .byte $E5 ; |XXX  X X| $DC3D
       .byte $D5 ; |XX X X X| $DC3E
       .byte $C5 ; |XX   X X| $DC3F
       .byte $B5 ; |X XX X X| $DC40
       .byte $A5 ; |X X  X X| $DC41
       .byte $95 ; |X  X X X| $DC42
       .byte $85 ; |X    X X| $DC43
       .byte $66 ; | XX  XX | $DC44
       .byte $56 ; | X X XX | $DC45
       .byte $46 ; | X   XX | $DC46
       .byte $36 ; |  XX XX | $DC47
       .byte $26 ; |  X  XX | $DC48
       .byte $16 ; |   X XX | $DC49
       .byte $06 ; |     XX | $DC4A
       .byte $F6 ; |XXXX XX | $DC4B
       .byte $E6 ; |XXX  XX | $DC4C
       .byte $D6 ; |XX X XX | $DC4D
       .byte $C6 ; |XX   XX | $DC4E
       .byte $B6 ; |X XX XX | $DC4F
       .byte $A6 ; |X X  XX | $DC50
       .byte $96 ; |X  X XX | $DC51
       .byte $86 ; |X    XX | $DC52
       .byte $67 ; | XX  XXX| $DC53
       .byte $57 ; | X X XXX| $DC54
       .byte $47 ; | X   XXX| $DC55
       .byte $37 ; |  XX XXX| $DC56
       .byte $27 ; |  X  XXX| $DC57
       .byte $17 ; |   X XXX| $DC58
       .byte $07 ; |     XXX| $DC59
       .byte $F7 ; |XXXX XXX| $DC5A
       .byte $E7 ; |XXX  XXX| $DC5B
       .byte $D7 ; |XX X XXX| $DC5C
       .byte $C7 ; |XX   XXX| $DC5D
       .byte $B7 ; |X XX XXX| $DC5E
       .byte $A7 ; |X X  XXX| $DC5F
       .byte $97 ; |X  X XXX| $DC60
       .byte $87 ; |X    XXX| $DC61
       .byte $68 ; | XX X   | $DC62
       .byte $58 ; | X XX   | $DC63
       .byte $48 ; | X  X   | $DC64
       .byte $38 ; |  XXX   | $DC65
       .byte $28 ; |  X X   | $DC66
       .byte $18 ; |   XX   | $DC67
       .byte $08 ; |    X   | $DC68
       .byte $F8 ; |XXXXX   | $DC69
       .byte $E8 ; |XXX X   | $DC6A
       .byte $D8 ; |XX XX   | $DC6B
       .byte $C8 ; |XX  X   | $DC6C
       .byte $B8 ; |X XXX   | $DC6D
       .byte $A8 ; |X X X   | $DC6E
       .byte $98 ; |X  XX   | $DC6F
       .byte $88 ; |X   X   | $DC70
       .byte $69 ; | XX X  X| $DC71
       .byte $59 ; | X XX  X| $DC72
       .byte $49 ; | X  X  X| $DC73
       .byte $39 ; |  XXX  X| $DC74
       .byte $29 ; |  X X  X| $DC75
       .byte $19 ; |   XX  X| $DC76
       .byte $09 ; |    X  X| $DC77
       .byte $F9 ; |XXXXX  X| $DC78
       .byte $E9 ; |XXX X  X| $DC79
       .byte $D9 ; |XX XX  X| $DC7A
       .byte $C9 ; |XX  X  X| $DC7B
       .byte $B9 ; |X XXX  X| $DC7C
       .byte $A9 ; |X X X  X| $DC7D
       .byte $99 ; |X  XX  X| $DC7E
       .byte $89 ; |X   X  X| $DC7F
       .byte $6A ; | XX X X | $DC80
       .byte $5A ; | X XX X | $DC81
       .byte $4A ; | X  X X | $DC82
       .byte $3A ; |  XXX X | $DC83
       .byte $00 ; |  X X X | $DC84
       .byte $00 ; |  X X X | $DC84
       .byte $00 ; |  X X X | $DC84
       .byte $00 ; |  X X X | $DC84
       .byte $00 ; |  X X X | $DC84
       .byte $00 ; |  X X X | $DC84
       .byte $00 ; |  X X X | $DC84










InterMusic0:
       .byte $14 ; |   X X  | $FCA6
       .byte $14 ; |   X X  | $FCA7
       .byte $14 ; |   X X  | $FCA8
       .byte $15 ; |   X X X| $FCA9
       .byte $14 ; |   X X  | $FCAA
       .byte $14 ; |   X X  | $FCAB
       .byte $13 ; |   X  XX| $FCAC
       .byte $13 ; |   X  XX| $FCAD
       .byte $14 ; |   X X  | $FCAE
       .byte $14 ; |   X X  | $FCAF
       .byte $14 ; |   X X  | $FCB0
       .byte $15 ; |   X X X| $FCB1
       .byte $14 ; |   X X  | $FCB2
       .byte $14 ; |   X X  | $FCB3
       .byte $16 ; |   X XX | $FCB4
       .byte $16 ; |   X XX | $FCB5
       .byte $14 ; |   X X  | $FCB6
       .byte $14 ; |   X X  | $FCB7
       .byte $14 ; |   X X  | $FCB8
       .byte $15 ; |   X X X| $FCB9
       .byte $14 ; |   X X  | $FCBA
       .byte $14 ; |   X X  | $FCBB
       .byte $13 ; |   X  XX| $FCBC
       .byte $12 ; |   X  X | $FCBD
       .byte $11 ; |   X   X| $FCBE
       .byte $14 ; |   X X  | $FCBF
       .byte $15 ; |   X X X| $FCC0
       .byte $16 ; |   X XX | $FCC1
       .byte $14 ; |   X X  | $FCC2
       .byte $14 ; |   X X  | $FCC3
       .byte $16 ; |   X X  | $FCC4
LFF1B:
       .byte $00 ; |        | $FF1B (shared)
       .byte $00 ; |        | $FF1C
       .byte $80 ; |X       | $FF1D
       .byte $A0 ; |X X     | $FF1E
       .byte $A8 ; |X X X   | $FF1F
       .byte $AA ; |X X X X | $FF20
       .byte $AA ; |X X X X | $FF21
       .byte $AA ; |X X X X | $FF22
       .byte $AA ; |X X X X | $FF23
       .byte $AA ; |X X X X | $FF24





  IF ColorDots
;section 2
LDD3F: .byte $00 ; |    X   | $FD3F
       .byte $02 ; |    X X | $FD40
       .byte $20 ; |  X X   | $FD41
       .byte $22 ; |  X X X | $FD42
       .byte $80 ; |X   X   | $FD43
       .byte $82 ; |X   X X | $FD44
       .byte $A0 ; |X X X   | $FD45
       .byte $A2 ; |X X X X | $FD46

LDD47: .byte $00 ; |        | $FD47
       .byte $40 ; | X      | $FD48
       .byte $10 ; |   X    | $FD49
       .byte $50 ; | X X    | $FD4A
       .byte $04 ; |     X  | $FD4B
       .byte $44 ; | X   X  | $FD4C
       .byte $14 ; |   X X  | $FD4D
       .byte $54 ; | X X X  | $FD4E
       .byte $01 ; |       X| $FD4F
       .byte $41 ; | X     X| $FD50
       .byte $11 ; |   X   X| $FD51
       .byte $51 ; | X X   X| $FD52
       .byte $05 ; |     X X| $FD53
       .byte $45 ; | X   X X| $FD54
       .byte $15 ; |   X X X| $FD55
       .byte $55 ; | X X X X| $FD56

LDD57: .byte $00 ; |        | $FD57
       .byte $80 ; |X       | $FD58
       .byte $20 ; |  X     | $FD59
       .byte $A0 ; |X X     | $FD5A

;section 5
LDD5B: .byte $00 ; |       X| $FD5B
       .byte $04 ; |     X X| $FD5C
       .byte $10 ; |   X   X| $FD5D
       .byte $14 ; |   X X X| $FD5E
       .byte $40 ; | X     X| $FD5F
       .byte $44 ; | X   X X| $FD60
       .byte $50 ; | X X   X| $FD61
       .byte $54 ; | X X X X| $FD62

;section 6
LDD63: .byte $00 ; |X       | $FD63
       .byte $20 ; |X X     | $FD64
       .byte $08 ; |X   X   | $FD65
       .byte $28 ; |X X X   | $FD66
       .byte $02 ; |X     X | $FD67
       .byte $22 ; |X X   X | $FD68
       .byte $0A ; |X   X X | $FD69
       .byte $2A ; |X X X X | $FD6A

LDD6B: .byte $00 ; |        | $FD6B
       .byte $02 ; |      X | $FD6C
       .byte $08 ; |    X   | $FD6D
       .byte $0A ; |    X X | $FD6E
       .byte $20 ; |  X     | $FD6F
       .byte $22 ; |  X   X | $FD70
       .byte $28 ; |  X X   | $FD71
       .byte $2A ; |  X X X | $FD72
       .byte $80 ; |X       | $FD73
       .byte $82 ; |X     X | $FD74
       .byte $88 ; |X   X   | $FD75
       .byte $8A ; |X   X X | $FD76
       .byte $A0 ; |X X     | $FD77
       .byte $A2 ; |X X   X | $FD78
       .byte $A8 ; |X X X   | $FD79
       .byte $AA ; |X X X X | $FD7A

;section 3
LDD7B: .byte $00 ; |    X   | $FD7B
       .byte $80 ; |X   X   | $FD7C
       .byte $20 ; |  X X   | $FD7D
       .byte $A0 ; |X X X   | $FD7E
       .byte $01 ; |    X  X| $FD7F
       .byte $81 ; |X   X  X| $FD80
       .byte $21 ; |  X X  X| $FD81
       .byte $A1 ; |X X X  X| $FD82

  ELSE

;section 2
LDD3F: .byte $08 ; |    X   | $FD3F
       .byte $0A ; |    X X | $FD40
       .byte $28 ; |  X X   | $FD41
       .byte $2A ; |  X X X | $FD42
       .byte $88 ; |X   X   | $FD43
       .byte $8A ; |X   X X | $FD44
       .byte $A8 ; |X X X   | $FD45
       .byte $AA ; |X X X X | $FD46

LDD47: .byte $00 ; |        | $FD47
       .byte $40 ; | X      | $FD48
       .byte $10 ; |   X    | $FD49
       .byte $50 ; | X X    | $FD4A
       .byte $04 ; |     X  | $FD4B
       .byte $44 ; | X   X  | $FD4C
       .byte $14 ; |   X X  | $FD4D
       .byte $54 ; | X X X  | $FD4E
       .byte $01 ; |       X| $FD4F
       .byte $41 ; | X     X| $FD50
       .byte $11 ; |   X   X| $FD51
       .byte $51 ; | X X   X| $FD52
       .byte $05 ; |     X X| $FD53
       .byte $45 ; | X   X X| $FD54
       .byte $15 ; |   X X X| $FD55
       .byte $55 ; | X X X X| $FD56

LDD57: .byte $00 ; |        | $FD57
       .byte $80 ; |X       | $FD58
       .byte $20 ; |  X     | $FD59
       .byte $A0 ; |X X     | $FD5A

;section 5
LDD5B: .byte $01 ; |       X| $FD5B
       .byte $05 ; |     X X| $FD5C
       .byte $11 ; |   X   X| $FD5D
       .byte $15 ; |   X X X| $FD5E
       .byte $41 ; | X     X| $FD5F
       .byte $45 ; | X   X X| $FD60
       .byte $51 ; | X X   X| $FD61
       .byte $55 ; | X X X X| $FD62

;section 6
LDD63: .byte $80 ; |X       | $FD63
       .byte $A0 ; |X X     | $FD64
       .byte $88 ; |X   X   | $FD65
       .byte $A8 ; |X X X   | $FD66
       .byte $82 ; |X     X | $FD67
       .byte $A2 ; |X X   X | $FD68
       .byte $8A ; |X   X X | $FD69
       .byte $AA ; |X X X X | $FD6A

LDD6B: .byte $00 ; |        | $FD6B
       .byte $02 ; |      X | $FD6C
       .byte $08 ; |    X   | $FD6D
       .byte $0A ; |    X X | $FD6E
       .byte $20 ; |  X     | $FD6F
       .byte $22 ; |  X   X | $FD70
       .byte $28 ; |  X X   | $FD71
       .byte $2A ; |  X X X | $FD72
       .byte $80 ; |X       | $FD73
       .byte $82 ; |X     X | $FD74
       .byte $88 ; |X   X   | $FD75
       .byte $8A ; |X   X X | $FD76
       .byte $A0 ; |X X     | $FD77
       .byte $A2 ; |X X   X | $FD78
       .byte $A8 ; |X X X   | $FD79
       .byte $AA ; |X X X X | $FD7A

;section 3
LDD7B: .byte $08 ; |    X   | $FD7B
       .byte $88 ; |X   X   | $FD7C
       .byte $28 ; |  X X   | $FD7D
       .byte $A8 ; |X X X   | $FD7E
       .byte $09 ; |    X  X| $FD7F
       .byte $89 ; |X   X  X| $FD80
       .byte $29 ; |  X X  X| $FD81
       .byte $A9 ; |X X X  X| $FD82

  ENDIF


       ORG $1b00
       RORG $Db00

FruitGFX:
Fruit0:
       .byte $00 ; |        | $DEF8
       .byte $06 ; |     XX | $DEEA
       .byte $6F ; | XX XXXX| $DEE9
       .byte $F6 ; |XXXX XX | $DEE8
       .byte $64 ; | XX  X  | $DEE7
       .byte $18 ; |   XX   | $DEE6
       .byte $10 ; |   X    | $DEE5
       .byte $00 ; |        | $DEEB


Fruit1:
       .byte $18 ; |   XX   | $DE8B
       .byte $3C ; |  XXXX  | $DE8A
       .byte $7A ; | XXXX X | $DE89
       .byte $6E ; | XX XXX | $DE88
       .byte $7A ; | XXXX X | $DE87
       .byte $6E ; | XX XXX | $DE86
       .byte $3C ; |  XXXX  | $DE85
       .byte $00 ; |        | $DEEB

Fruit2:
Fruit3:
       .byte $3C ; |  XXXX  | $DE91
       .byte $7E ; | XXXXXX | $DE96
       .byte $FF ; |XXXXXXXX| $DE93
       .byte $FF ; |XXXXXXXX| $DE94
       .byte $FF ; |XXXXXXXX| $DE95
       .byte $72 ; | XXX  X | $DE92
       .byte $3C ; |  XXXX  | $DE97
       .byte $00 ; |        | $DEEB

Fruit4:
Fruit5:
       .byte $36 ; |  XX XX | $DEA3
       .byte $7E ; | XXXXXX | $DEA2
       .byte $FF ; |XXXXXXXX| $DEA0
       .byte $FF ; |XXXXXXXX| $DEA0
       .byte $76 ; | XXX XX | $DE9F
       .byte $08 ; |    X   | $DE9E
       .byte $0C ; |    XX  | $DE9D
       .byte $00 ; |        | $DEEB

Fruit6:
Fruit7:
       .byte $1C ; |   XXX  | $DEAA
       .byte $3E ; |  XXXXX | $DEAB
       .byte $3E ; |  XXXXX | $DEAC
       .byte $3E ; |  XXXXX | $DEAD
       .byte $3E ; |  XXXXX | $DEAE
       .byte $1C ; |   XXX  | $DEAF
       .byte $08 ; |    X   | $DEA9
       .byte $00 ; |        | $DEEB

Fruit8:
Fruit9:
       .byte $08 ; |    X   | $DEB9
       .byte $08 ; |    X   | $DEBA
       .byte $08 ; |    X   | $DEBB
       .byte $1C ; |   XXX  | $DEB8
       .byte $3E ; |  XXXXX | $DEB7
       .byte $6B ; | XX X XX| $DEB6
       .byte $41 ; | X     X| $DEB5
       .byte $00 ; |        | $DEEB

FruitA:
FruitB:
       .byte $36 ; |  XX XX | $DEC7
       .byte $6B ; | XX X XX| $DEC6
       .byte $7F ; | XXXXXXX| $DEC5
       .byte $3E ; |  XXXXX | $DEC3
       .byte $3E ; |  XXXXX | $DEC4
       .byte $1C ; |   XXX  | $DEC2
       .byte $08 ; |    X   | $DEC1
       .byte $00 ; |        | $DEEB

FruitC:
FruitD:
FruitE:
FruitF:
       .byte $18 ; |   XX   | $DECF
       .byte $1C ; |   XXX  | $DED0
       .byte $18 ; |   XX   | $DED1
       .byte $1C ; |   XXX  | $DED2
       .byte $18 ; |   XX   | $DED3
       .byte $24 ; |  X  X  | $DECE
       .byte $3C ; |  XXXX  | $DECD
       .byte $00 ; |        | $DEEB



;free
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB



       ORG $1b80
       RORG $Db80

       .byte $07 ; |     XXX| $FDB5
       .byte $05 ; |     X X| $FDB6
       .byte $1F ; |   XXXXX| $FDB7
       .byte $54 ; | X X X  | $FDB8
       .byte $5C ; | X XXX  | $FDB9
       .byte $40 ; | X      | $FDBA
       .byte $40 ; | X      | $FDAF
       .byte $00 ; |        | $DEEB

       .byte $07 ; |     XXX| $FDB5
       .byte $05 ; |     X X| $FDB6
       .byte $DF ; |XX XXXXX| $FDB7
       .byte $54 ; | X X X  | $FDB8
       .byte $DC ; |XX XXX  | $FDB9
       .byte $40 ; | X      | $FDBA
       .byte $C0 ; |XX      | $FDAF
       .byte $00 ; |        | $DEEB

       .byte $07 ; |     XXX| $FDB5
       .byte $05 ; |     X X| $FDB6
       .byte $DF ; |XX XXXXX| $FDB7
       .byte $54 ; | X X X  | $FDB8
       .byte $DC ; |XX XXX  | $FDB9
       .byte $80 ; |X       | $FDBA
       .byte $C0 ; |XX      | $FDAF
       .byte $00 ; |        | $DEEB

       .byte $07 ; |     XXX| $FDB5
       .byte $05 ; |     X X| $FDB6
       .byte $1F ; |   XXXXX| $FDB7
       .byte $54 ; | X X X  | $FDB8
       .byte $5C ; | X XXX  | $FDB9
       .byte $20 ; |  X     | $FDBA
       .byte $E0 ; |XXX     | $FDAF
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $4A ; | X  X X | $DEEB
       .byte $4C ; | X  XX  | $DEEB
       .byte $CA ; |XX  X X | $DEEB
       .byte $49 ; | X  X  X| $DEEB
       .byte $00 ; |        | $DEEB
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $8A ; |X   X X | $DEEB
       .byte $EC ; |XXX XX  | $DEEB
       .byte $2A ; |  X X X | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $00 ; |        | $DEEB
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $2A ; |  X X X | $DEEB
       .byte $6C ; | XX XX  | $DEEB
       .byte $2A ; |  X X X | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $00 ; |        | $DEEB
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $2A ; |  X X X | $DEEB
       .byte $EC ; |XXX XX  | $DEEB
       .byte $8A ; |X   X X | $DEEB
       .byte $E9 ; |XXX X  X| $DEEB
       .byte $00 ; |        | $DEEB
       .byte $00 ; |        | $DEEB







;free
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB

       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $DEEB




       ORG $1c00
       RORG $Dc00

       .byte $00 ; |        | $FD00
       .byte $00 ; |        | $FD01
       .byte $00 ; |        | $FD02
       .byte $E7 ; |XXX  XXX| $FD03
       .byte $C6 ; |XX   XX | $FD04
       .byte $E7 ; |XXX  XXX| $FD05
       .byte $00 ; |        | $FD06
       .byte $00 ; |        | $FD07

PGFX:
RPac1gfx:
       .byte $38 ; |  XXX   | $FDAF (08)
       .byte $7C ; | XXXXX  | $FDB0
       .byte $FE ; |XXXXXXX | $FDB1
       .byte $FE ; |XXXXXXX | $FDB2
       .byte $FE ; |XXXXXXX | $FDB3
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDAF

PT200:
  IF EQUALPTS
       .byte $07 ; |     XXX| $FDB5 (0F)
       .byte $05 ; |     X X| $FDB6
       .byte $1F ; |   XXXXX| $FDB7
       .byte $F4 ; |XXXX X  | $FDB8
       .byte $5C ; | X XXX  | $FDB9
       .byte $20 ; |  X     | $FDBA
       .byte $E0 ; |XXX     | $FDAF
  ELSE
       .byte $00 ; |        | $FDB5
       .byte $EE ; |XXX XXX | $FDB6
       .byte $8A ; |X   X X | $FDB7
       .byte $EA ; |XXX X X | $FDB8
       .byte $2A ; |  X X X | $FDB9
       .byte $EE ; |XXX XXX | $FDBA
       .byte $00 ; |        | $FDAF
  ENDIF

RPac2gfx:
       .byte $38 ; |  XXX   | $FDB5 ;(16)
       .byte $7C ; | XXXXX  | $FDB6
       .byte $FE ; |XXXXXXX | $FDB7
       .byte $E0 ; |XXX     | $FDB8
       .byte $FE ; |XXXXXXX | $FDB9
       .byte $7C ; | XXXXX  | $FDBA
       .byte $38 ; |  XXX   | $FDAF

RPac3gfx:
       .byte $38 ; |  XXX   | $FDBB
       .byte $7C ; | XXXXX  | $FDBC
       .byte $F0 ; |XXXX    | $FDBD
       .byte $E0 ; |XXX     | $FDBE
       .byte $F0 ; |XXXX    | $FDBF
       .byte $7C ; | XXXXX  | $FDC0
       .byte $38 ; |  XXX   | $FDCE

RPac4gfx:
RPac5gfx:
       .byte $3C ; |  XXXX  | $FDBB
       .byte $78 ; | XXXX   | $FDBC
       .byte $E0 ; |XXX     | $FDBD
       .byte $C0 ; |XX      | $FDBE
       .byte $E0 ; |XXX     | $FDBF
       .byte $78 ; | XXXX   | $FDC0
       .byte $3C ; |  XXXX  | $FDCE

Death4gfx:
       .byte $38 ; |  XXX   | $FDCE
       .byte $7C ; | XXXXX  | $FDCF
       .byte $FE ; |XXXXXXX | $FDD0
       .byte $FE ; |XXXXXXX | $FDD1
       .byte $EE ; |XXX XXX | $FDD2
       .byte $C6 ; |XX   XX | $FDD3
       .byte $44 ; | X   X  | $FDD4
Death6gfx:
       .byte $38 ; |  XXX   | $FDCE
       .byte $7C ; | XXXXX  | $FDCF
       .byte $FE ; |XXXXXXX | $FDD0
       .byte $EE ; |XXX XXX | $FDD1
       .byte $C6 ; |XX   XX | $FDD2
       .byte $82 ; |X     X | $FDD3
;       .byte $00 ; |        | $FDD4
Sizes:
       .byte $00 ;shared
       .byte $00
       .byte $01
       .byte $03

SmallPacAnim:
       .byte <Spac1 ; $F00B
       .byte <Spac2 ; $F00C

;2 free

       ORG $1c40
       RORG $Dc40

       .byte $00 ; |        | $FDC7
       .byte $00 ; |        | $FDC8
       .byte $00 ; |        | $FDC9
       .byte $E7 ; |XXX  XXX| $FDCA
       .byte $63 ; | XX   XX| $FDCB
       .byte $E7 ; |XXX  XXX| $FDCC
       .byte $00 ; |        | $FDCD
       .byte $00 ; |        | $FDC6

       .byte $38 ; |  XXX   | $FDAF
       .byte $7C ; | XXXXX  | $FDB0
       .byte $FE ; |XXXXXXX | $FDB1
       .byte $FE ; |XXXXXXX | $FDB2
       .byte $FE ; |XXXXXXX | $FDB3
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDAF

PT400:
  IF EQUALPTS
       .byte $07 ; |     XXX| $FDB5 (4F)
       .byte $05 ; |     X X| $FDB6
       .byte $1F ; |   XXXXX| $FDB7
       .byte $34 ; |  XX X  | $FDB8
       .byte $3C ; |  XXXX  | $FDB9
       .byte $E0 ; |XXX     | $FDBA
       .byte $A0 ; |X X     | $FDAF
  ELSE
       .byte $00 ; |        | $FDB5
       .byte $17 ; |   X XXX| $FDB6
       .byte $F5 ; |XXXX X X| $FDB7
       .byte $55 ; | X X X X| $FDB8
       .byte $35 ; |  XX X X| $FDB9
       .byte $17 ; |   X XXX| $FDBA
       .byte $00 ; |        | $FDAF
  ENDIF



       .byte $38 ; |  XXX   | $FDB5
       .byte $7C ; | XXXXX  | $FDB6
       .byte $FE ; |XXXXXXX | $FDB7
       .byte $0E ; |    XXX | $FDB8
       .byte $FE ; |XXXXXXX | $FDB9
       .byte $7C ; | XXXXX  | $FDBA
       .byte $38 ; |  XXX   | $FDAF

       .byte $38 ; |  XXX   | $FDBB
       .byte $7C ; | XXXXX  | $FDBC
       .byte $1E ; |   XXXX | $FDBD
       .byte $0E ; |    XXX | $FDBE
       .byte $1E ; |   XXXX | $FDBF
       .byte $7C ; | XXXXX  | $FDC0
       .byte $38 ; |  XXX   | $FDCE

       .byte $78 ; | XXXX   | $FDBB
       .byte $3C ; |  XXXX  | $FDBC
       .byte $0E ; |    XXX | $FDBD
       .byte $06 ; |     XX | $FDBE
       .byte $0E ; |    XXX | $FDBF
       .byte $3C ; |  XXXX  | $FDC0
       .byte $78 ; | XXXX   | $FDCE


;       .byte $38 ; |  XXX   | $FDB5
;       .byte $7C ; | XXXXX  | $FDB6
;       .byte $FE ; |XXXXXXX | $FDB7
;       .byte $E0 ; |XXX     | $FDB8
;       .byte $FE ; |XXXXXXX | $FDB9
;       .byte $7C ; | XXXXX  | $FDBA
;       .byte $38 ; |  XXX   | $FDAF

;       .byte $38 ; |  XXX   | $FDBB
;       .byte $7C ; | XXXXX  | $FDBC
;       .byte $F0 ; |XXXX    | $FDBD
;       .byte $E0 ; |XXX     | $FDBE
;       .byte $F0 ; |XXXX    | $FDBF
;       .byte $7C ; | XXXXX  | $FDC0
;       .byte $38 ; |  XXX   | $FDCE

;       .byte $3C ; |  XXXX  | $FDBB
;       .byte $78 ; | XXXX   | $FDBC
;       .byte $E0 ; |XXX     | $FDBD
;       .byte $C0 ; |XX      | $FDBE
;       .byte $E0 ; |XXX     | $FDBF
;       .byte $78 ; | XXXX   | $FDC0
;       .byte $3C ; |  XXXX  | $FDCE



Death8gfx:
       .byte $38 ; |  XXX   | $FDCE
       .byte $7C ; | XXXXX  | $FDCF
       .byte $C6 ; |XX   XX | $FDD0
       .byte $82 ; |X     X | $FDD1
       .byte $00 ; |        | $FDD2
       .byte $00 ; |        | $FDD3
       .byte $00 ; |        | $FDD4
Death9gfx:
       .byte $10 ; |   X    | $FDCE
       .byte $38 ; |  XXX   | $FDCF
       .byte $44 ; | X   X  | $FDD0
       .byte $00 ; |        | $FDD1
       .byte $00 ; |        | $FDD2
       .byte $00 ; |        | $FDD3
       .byte $00 ; |        | $FDD3



;free
       .byte $00 ; |        | $FDF8


TornAnim:
       .byte <Torn2 ; $FC78
       .byte <Torn3 ; $FC79

LargePacAnim:
       .byte <Lpac1 ; $FC78
       .byte <Lpac2 ; $FC79
       .byte <Lpac3 ; $FC7A
       .byte <Lpac2 ; $FC7B



       ORG $1c80
       RORG $Dc80

       .byte $00 ; |        | $FDC7
       .byte $00 ; |        | $FDC8
       .byte $00 ; |        | $FDC9
       .byte $A5 ; |X X  X X| $FDCA
       .byte $E7 ; |XXX  XXX| $FDCB
       .byte $E7 ; |XXX  XXX| $FDCC
       .byte $00 ; |        | $FDCD
       .byte $00 ; |        | $FDC6

       .byte $38 ; |  XXX   | $FDAF
       .byte $7C ; | XXXXX  | $FDB0
       .byte $FE ; |XXXXXXX | $FDB1
       .byte $FE ; |XXXXXXX | $FDB2
       .byte $FE ; |XXXXXXX | $FDB3
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDCE

PT800:
  IF EQUALPTS
       .byte $07 ; |     XXX| $FDB5 (8F)
       .byte $05 ; |     X X| $FDB6
       .byte $5F ; | X XXXXX| $FDB7
       .byte $B4 ; |X XX X  | $FDB8
       .byte $5C ; | X XXX  | $FDB9
       .byte $A0 ; |X X     | $FDBA
       .byte $40 ; | X      | $FDAF
  ELSE
       .byte $00 ; |        | $FDB5
       .byte $77 ; | XXX XXX| $FDB6
       .byte $55 ; | X X X X| $FDB7
       .byte $75 ; | XXX X X| $FDB8
       .byte $55 ; | X X X X| $FDB9
       .byte $77 ; | XXX XXX| $FDBA
       .byte $00 ; |        | $FDAF
  ENDIF



       .byte $28 ; |  X X   | $FDD4
       .byte $6C ; | XX XX  | $FDD3
       .byte $EE ; |XXX XXX | $FDD1
       .byte $EE ; |XXX XXX | $FDD2
       .byte $FE ; |XXXXXXX | $FDD2
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDCE

       .byte $44 ; | X   X  | $FDD4
       .byte $C6 ; |XX   XX | $FDD3
       .byte $EE ; |XXX XXX | $FDD1
       .byte $EE ; |XXX XXX | $FDD2
       .byte $FE ; |XXXXXXX | $FDB3
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDCE

       .byte $00 ; |        | $FDD4
       .byte $82 ; |X     X | $FDD3
       .byte $82 ; |X     X | $FDD1
       .byte $C6 ; |XX   XX | $FDD2
       .byte $EE ; |XXX XXX | $FDB3
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDCE

Death10gfx:
       .byte $00 ; |        | $FDCE
       .byte $38 ; |  XXX   | $FDCF
Death11gfx:
       .byte $00 ; |        | $FDE8
       .byte $00 ; |        | $FDE9
       .byte $00 ; |        | $FDEA
       .byte $00 ; |        | $FDEB
       .byte $00 ; |        | $FDEC
Death12gfx:
       .byte $00 ; |        | $FDE8
       .byte $00 ; |        | $FDE9
       .byte $28 ; |  X X   | $FDEA
       .byte $10 ; |   X    | $FDEB
       .byte $28 ; |  X X   | $FDEC
       .byte $00 ; |        | $FDED
       .byte $00 ; |        | $FDD3



;free
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8



       ORG $1cC0
       RORG $DcC0

       .byte $00 ; |        | $FDC7
       .byte $00 ; |        | $FDC8
       .byte $00 ; |        | $FDC9
       .byte $E7 ; |XXX  XXX| $FDCC
       .byte $E7 ; |XXX  XXX| $FDCA
       .byte $A5 ; |X X  X X| $FDCB
       .byte $00 ; |        | $FDCD
       .byte $00 ; |        | $FDC6

Death1gfx:
       .byte $38 ; |  XXX   | $FDAF
       .byte $7C ; | XXXXX  | $FDB0
       .byte $FE ; |XXXXXXX | $FDB1
       .byte $FE ; |XXXXXXX | $FDB2
       .byte $FE ; |XXXXXXX | $FDB3
       .byte $7C ; | XXXXX  | $FDB4
       .byte $38 ; |  XXX   | $FDCE

PT1600:
  IF EQUALPTS
       .byte $1F ; |   XXXXX| $FDB5
       .byte $15 ; |   X X X| $FDB6
       .byte $1F ; |   XXXXX| $FDB7
       .byte $B8 ; |X XXX   | $FDB8
       .byte $A8 ; |X X X   | $FDB9
       .byte $B8 ; |X XXX   | $FDBA
       .byte $A0 ; |X X     | $FDAF
  ELSE
       .byte $07 ; |     XXX| $FDB5
       .byte $3D ; |  XXXX X| $FDB6
       .byte $AD ; |X X XX X| $FDB7
       .byte $BF ; |X XXXXXX| $FDB8
       .byte $A0 ; |X X     | $FDB9
       .byte $B8 ; |X XXX   | $FDBA
       .byte $80 ; |X       | $FDAF
  ENDIF



Death2gfx:
Death3gfx:
       .byte $38 ; |  XXX   | $FDCE
       .byte $7C ; | XXXXX  | $FDCF
       .byte $FE ; |XXXXXXX | $FDD0
       .byte $EE ; |XXX XXX | $FDD1
       .byte $EE ; |XXX XXX | $FDD2
       .byte $6C ; | XX XX  | $FDD3
       .byte $28 ; |  X X   | $FDD4

Death5gfx:
       .byte $38 ; |  XXX   | $FDCE
       .byte $7C ; | XXXXX  | $FDCF
       .byte $FE ; |XXXXXXX | $FDD0
       .byte $EE ; |XXX XXX | $FDD1
       .byte $EE ; |XXX XXX | $FDD2
       .byte $C6 ; |XX   XX | $FDD3
       .byte $44 ; | X   X  | $FDD4
Death7gfx:
       .byte $38 ; |  XXX   | $FDCE
       .byte $7C ; | XXXXX  | $FDCF
       .byte $EE ; |XXX XXX | $FDB3
       .byte $C6 ; |XX   XX | $FDD2
       .byte $82 ; |X     X | $FDD3
       .byte $82 ; |X     X | $FDD1
       .byte $00 ; |        | $FDD4



Death13gfx:
       .byte $00 ; |        | $FDEE
       .byte $44 ; | X   X  | $FDEF
       .byte $28 ; |  X X   | $FDF0
       .byte $00 ; |        | $FDF1
       .byte $28 ; |  X X   | $FDF2
       .byte $44 ; | X   X  | $FDF3
       .byte $00 ; |        | $FDF4
Death14gfx:
       .byte $44 ; | X   X  | $FDF3 (F2)
       .byte $00 ; |        | $FDF4
       .byte $82 ; |X     X | $FDF5
       .byte $00 ; |        | $FDF6
       .byte $82 ; |X     X | $FDF7
       .byte $00 ; |        | $FDF8
       .byte $44 ; | X   X  | $FDF9



;free
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8
       .byte $00 ; |        | $FDF8

       ORG $1d00
       RORG $Dd00

MGFX:
Monster1gfx:
       .byte $88 ; |X   X   | $FD08
       .byte $DD ; |XX XXX X| $FD09
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $FF ; |XXXXXXXX| $FD0B
       .byte $ED ; |XXX XX X| $FD0C
       .byte $ED ; |XXX XX X| $FD0D
       .byte $7E ; | XXXXXX | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

Monster2gfx:
       .byte $44 ; | X   X  | $FD10
       .byte $EE ; |XXX XXX | $FD11
       .byte $FF ; |XXXXXXXX| $FD12
       .byte $FF ; |XXXXXXXX| $FD13
       .byte $ED ; |XXX XX X| $FD14
       .byte $ED ; |XXX XX X| $FD15
       .byte $7E ; | XXXXXX | $FD16
       .byte $3C ; |  XXXX  | $FD17

Monster3gfx:
       .byte $22 ; |  X   X | $FD18
       .byte $77 ; | XXX XXX| $FD19
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $FF ; |XXXXXXXX| $FD1B
       .byte $ED ; |XXX XX X| $FD1C
       .byte $ED ; |XXX XX X| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F

Monster4gfx:
       .byte $11 ; |   X   X| $FD20
       .byte $BB ; |X XXX XX| $FD21
       .byte $FF ; |XXXXXXXX| $FD22
       .byte $FF ; |XXXXXXXX| $FD23
       .byte $ED ; |XXX XX X| $FD24
       .byte $ED ; |XXX XX X| $FD25
       .byte $7E ; | XXXXXX | $FD26
       .byte $3C ; |  XXXX  | $FD27

       .byte $88 ; |X   X   | $FD08
       .byte $DD ; |XX XXX X| $FD09
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $F3 ; |XXXX  XX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $ED ; |XXX XX X| $FD0D
       .byte $7E ; | XXXXXX | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

       .byte $44 ; | X   X  | $FD10
       .byte $EE ; |XXX XXX | $FD11
       .byte $FF ; |XXXXXXXX| $FD12
       .byte $F3 ; |XXXX  XX| $FD13
       .byte $FF ; |XXXXXXXX| $FD14
       .byte $ED ; |XXX XX X| $FD15
       .byte $7E ; | XXXXXX | $FD16
       .byte $3C ; |  XXXX  | $FD17

       .byte $22 ; |  X   X | $FD18
       .byte $77 ; | XXX XXX| $FD19
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $F3 ; |XXXX  XX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $ED ; |XXX XX X| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F

       .byte $11 ; |   X   X| $FD20
       .byte $BB ; |X XXX XX| $FD21
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $F3 ; |XXXX  XX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $ED ; |XXX XX X| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F


       ORG $1d40
       RORG $Dd40

       .byte $88 ; |X   X   | $FD8B
       .byte $DD ; |XX XXX X| $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FD91
       .byte $3C ; |  XXXX  | $FD92

       .byte $44 ; | X   X  | $FD93
       .byte $EE ; |XXX XXX | $FD94
       .byte $FF ; |XXXXXXXX| $FD95
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FD99
       .byte $3C ; |  XXXX  | $FD9A

       .byte $22 ; |  X   X | $FD9B
       .byte $77 ; | XXX XXX| $FD9C
       .byte $FF ; |XXXXXXXX| $FD9D
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FDA1
       .byte $3C ; |  XXXX  | $FDA2

       .byte $11 ; |   X   X| $FDA3
       .byte $BB ; |X XXX XX| $FDA4
       .byte $FF ; |XXXXXXXX| $FDA5
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $B7 ; |X XX XXX| $FD97
       .byte $B7 ; |X XX XXX| $FD90
       .byte $7E ; | XXXXXX | $FDA9
       .byte $3C ; |  XXXX  | $FDAA

       .byte $88 ; |X   X   | $FD08
       .byte $DD ; |XX XXX X| $FD09
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $CF ; |XX  XXXX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $B7 ; |X XX XXX| $FD0D
       .byte $7E ; | XXXXXX | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

       .byte $44 ; | X   X  | $FD10
       .byte $EE ; |XXX XXX | $FD11
       .byte $FF ; |XXXXXXXX| $FD12
       .byte $CF ; |XX  XXXX| $FD13
       .byte $FF ; |XXXXXXXX| $FD14
       .byte $B7 ; |X XX XXX| $FD15
       .byte $7E ; | XXXXXX | $FD16
       .byte $3C ; |  XXXX  | $FD17

       .byte $22 ; |  X   X | $FD18
       .byte $77 ; | XXX XXX| $FD19
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $CF ; |XX  XXXX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $B7 ; |X XX XXX| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F

       .byte $11 ; |   X   X| $FD20
       .byte $BB ; |X XXX XX| $FD21
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $CF ; |XX  XXXX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $B7 ; |X XX XXX| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F

       ORG $1d80
       RORG $Dd80

       .byte $88 ; |X   X   | $FD8B
       .byte $DD ; |XX XXX X| $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $DB ; |XX XX XX| $FDA6
       .byte $DB ; |XX XX XX| $FD97
       .byte $FF ; |XXXXXXXX| $FD90
       .byte $7E ; | XXXXXX | $FD91
       .byte $3C ; |  XXXX  | $FD92

       .byte $44 ; | X   X  | $FD93
       .byte $EE ; |XXX XXX | $FD94
       .byte $FF ; |XXXXXXXX| $FD95
       .byte $DB ; |XX XX XX| $FDA6
       .byte $DB ; |XX XX XX| $FD97
       .byte $FF ; |XXXXXXXX| $FD90
       .byte $7E ; | XXXXXX | $FD99
       .byte $3C ; |  XXXX  | $FD9A

       .byte $22 ; |  X   X | $FD9B
       .byte $77 ; | XXX XXX| $FD9C
       .byte $FF ; |XXXXXXXX| $FD9D
       .byte $DB ; |XX XX XX| $FDA6
       .byte $DB ; |XX XX XX| $FD97
       .byte $FF ; |XXXXXXXX| $FD90
       .byte $7E ; | XXXXXX | $FDA1
       .byte $3C ; |  XXXX  | $FDA2

       .byte $11 ; |   X   X| $FDA3
       .byte $BB ; |X XXX XX| $FDA4
       .byte $FF ; |XXXXXXXX| $FDA5
       .byte $DB ; |XX XX XX| $FDA6
       .byte $DB ; |XX XX XX| $FD97
       .byte $FF ; |XXXXXXXX| $FD90
       .byte $7E ; | XXXXXX | $FDA9
       .byte $3C ; |  XXXX  | $FDAA

       .byte $88 ; |X   X   | $FD08
       .byte $DD ; |XX XXX X| $FD09
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $E7 ; |XXX  XXX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $DB ; |XX XX XX| $FD0D
       .byte $7E ; | XXXXXX | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

       .byte $44 ; | X   X  | $FD10
       .byte $EE ; |XXX XXX | $FD11
       .byte $FF ; |XXXXXXXX| $FD12
       .byte $E7 ; |XXX  XXX| $FD13
       .byte $FF ; |XXXXXXXX| $FD14
       .byte $DB ; |XX XX XX| $FD15
       .byte $7E ; | XXXXXX | $FD16
       .byte $3C ; |  XXXX  | $FD17

       .byte $22 ; |  X   X | $FD18
       .byte $77 ; | XXX XXX| $FD19
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $E7 ; |XXX  XXX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $DB ; |XX XX XX| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F

       .byte $11 ; |   X   X| $FD20
       .byte $BB ; |X XXX XX| $FD21
       .byte $FF ; |XXXXXXXX| $FD1A
       .byte $E7 ; |XXX  XXX| $FD1B
       .byte $FF ; |XXXXXXXX| $FD1C
       .byte $DB ; |XX XX XX| $FD1D
       .byte $7E ; | XXXXXX | $FD1E
       .byte $3C ; |  XXXX  | $FD1F


       ORG $1dC0
       RORG $DdC0

       .byte $88 ; |X   X   | $FD8B
       .byte $DD ; |XX XXX X| $FD8C
       .byte $FF ; |XXXXXXXX| $FD8D
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $FF ; |XXXXXXXX| $FD97
       .byte $DB ; |XX XX XX| $FD90
       .byte $5A ; | X XX X | $FD91
       .byte $3C ; |  XXXX  | $FD92

       .byte $44 ; | X   X  | $FD93
       .byte $EE ; |XXX XXX | $FD94
       .byte $FF ; |XXXXXXXX| $FD95
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $FF ; |XXXXXXXX| $FD97
       .byte $DB ; |XX XX XX| $FD90
       .byte $5A ; | X XX X | $FD99
       .byte $3C ; |  XXXX  | $FD9A

       .byte $22 ; |  X   X | $FD9B
       .byte $77 ; | XXX XXX| $FD9C
       .byte $FF ; |XXXXXXXX| $FD95
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $FF ; |XXXXXXXX| $FD97
       .byte $DB ; |XX XX XX| $FD90
       .byte $5A ; | X XX X | $FD99
       .byte $3C ; |  XXXX  | $FD9A

       .byte $11 ; |   X   X| $FDA3
       .byte $BB ; |X XXX XX| $FDA4
       .byte $FF ; |XXXXXXXX| $FD95
       .byte $FF ; |XXXXXXXX| $FDA6
       .byte $FF ; |XXXXXXXX| $FD97
       .byte $DB ; |XX XX XX| $FD90
       .byte $5A ; | X XX X | $FD99
       .byte $3C ; |  XXXX  | $FD9A


       .byte $88 ; |X   X   | $FD08
       .byte $DD ; |XX XXX X| $FD09
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $E7 ; |XXX  XXX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $FF ; |XXXXXXXX| $FD0D
       .byte $5A ; | X XX X | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

       .byte $44 ; | X   X  | $FD10
       .byte $EE ; |XXX XXX | $FD11
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $E7 ; |XXX  XXX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $FF ; |XXXXXXXX| $FD0D
       .byte $5A ; | X XX X | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

       .byte $22 ; |  X   X | $FD18
       .byte $77 ; | XXX XXX| $FD19
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $E7 ; |XXX  XXX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $FF ; |XXXXXXXX| $FD0D
       .byte $5A ; | X XX X | $FD0E
       .byte $3C ; |  XXXX  | $FD0F

       .byte $11 ; |   X   X| $FD20
       .byte $BB ; |X XXX XX| $FD21
       .byte $FF ; |XXXXXXXX| $FD0A
       .byte $E7 ; |XXX  XXX| $FD0B
       .byte $FF ; |XXXXXXXX| $FD0C
       .byte $FF ; |XXXXXXXX| $FD0D
       .byte $5A ; | X XX X | $FD0E
       .byte $3C ; |  XXXX  | $FD0F






       ORG $1e00
       RORG $De00




NakedEyesAnim:
       .byte <NakedEyes1  ; $FD00
       .byte <NakedEyes2  ; $FD01

VulnerableAnim:
       .byte <Vulnerable1 ; $FFF0
       .byte <Vulnerable2 ; $FFF1

LethalAnim:
       .byte <Lethal1     ; $FFF4
       .byte <Lethal2     ; $FFF5

NakedAnim:
       .byte <Naked1      ; $FFF6
       .byte <Naked2      ; $FFF7




ColorTbl: ;NTSC
       .byte $28 ; |XXXXXX  | $FF2B Clyde
       .byte $38 ; |XXX XX  | $FF2C Blinky
       .byte $A8 ; |XX XXX  | $FF2D Inky
       .byte $58 ; |XX  XX  | $FF2E Pinky
       .byte $84 ; | XXXX X | $FF2F blue color
       .byte $0E ; | X XX X | $FF30 flash color
       .byte $1A ; |XXXXX XX| $FF31 pacman color
       .byte $00 ; |X    X  | $FF32 background
       .byte $80 ; |XXXX XXX| $FF33 maze color
       .byte $44 ; | X   X  | $FF34 score1
       .byte $C6 ; |XX   X  | $FF35 score2
;FruitcolorTbl:
       .byte $32 ;cherries
       .byte $3A ;Strawberry
       .byte $2A ;Orange1
       .byte $2A ;Orange2
       .byte $32 ;Apple1
       .byte $32 ;Apple2
       .byte $C4 ;Grapes1
       .byte $C4 ;Grapes2
       .byte $54 ;Galaxian1
       .byte $54 ;Galaxian2
       .byte $1C ;Bell1
       .byte $1C ;Bell2
       .byte $22 ;Key1
       .byte $22 ;Key2
       .byte $22 ;Key3
       .byte $22 ;Key4
BwTbl: ;;PAL
       .byte $28 ; |   X X  | $FFF5
       .byte $68 ; |   XX   | $FFF6
       .byte $9A ; |   X X  | $FFF7
       .byte $86 ; |   XX   | $FFF8
       .byte $D2 ; |    X  X| $FF3A
       .byte $0E ; |     X  | $FF3B
       .byte $2C ; |    XXXX| $FF3C
       .byte $00 ; |        | $FF3D
       .byte $B0 ; |     XXX| $FF3E
       .byte $64 ; |     X  | $FF3F
       .byte $56 ; |    X X | $FF40
;FruitcolorTbl:
       .byte $62 ;cherries
       .byte $6A ;Strawberry
       .byte $4A ;Orange1
       .byte $4A ;Orange2
       .byte $62 ;Apple1
       .byte $62 ;Apple2
       .byte $54 ;Grapes1
       .byte $54 ;Grapes2
       .byte $84 ;Galaxian1
       .byte $84 ;Galaxian2
       .byte $2C ;Bell1
       .byte $2C ;Bell2
       .byte $42 ;Key1
       .byte $42 ;Key2
       .byte $42 ;Key3
       .byte $42 ;Key4



InterMusic1:
       .byte $16 ; |   X X  | $FCC4
       .byte $00 ; |        | $FCC5
       .byte $14 ; |   X X  | $FCC6
       .byte $15 ; |   X X X| $FCC7
       .byte $14 ; |   X X  | $FCC8
       .byte $00 ; |        | $FCC9
       .byte $13 ; |   X  XX| $FCCA
       .byte $13 ; |   X  XX| $FCCB
       .byte $14 ; |   X X  | $FCCC
       .byte $00 ; |        | $FCCD
       .byte $14 ; |   X X  | $FCCE
       .byte $15 ; |   X X X| $FCCF
       .byte $14 ; |   X X  | $FCD0
       .byte $00 ; |        | $FCD1
       .byte $16 ; |   X XX | $FCD2
       .byte $16 ; |   X XX | $FCD3
       .byte $14 ; |   X X  | $FCD4
       .byte $00 ; |        | $FCD5
       .byte $14 ; |   X X  | $FCD6
       .byte $15 ; |   X X X| $FCD7
       .byte $14 ; |   X X  | $FCD8
       .byte $00 ; |        | $FCD9
       .byte $13 ; |   X  XX| $FCDA
       .byte $12 ; |   X  X | $FCDB
       .byte $11 ; |   X   X| $FCDC
       .byte $14 ; |   X X  | $FCDD
       .byte $15 ; |   X X X| $FCDE
       .byte $16 ; |   X XX | $FCDF
       .byte $14 ; |   X X  | $FCE0
       .byte $14 ; |   X X  | $FCE1
       .byte $14 ; |   X X  | $FCE1
LFEEC:
       .byte $00 ; |        | $FEEC (shared)
       .byte $00 ; |        | $FEED
       .byte $00 ; |        | $FEEE
       .byte $00 ; |        | $FEEF
       .byte $00 ; |        | $FEF0
       .byte $00 ; |        | $FEF1
       .byte $01 ; |       X| $FEF2
       .byte $05 ; |     X X| $FEF3
       .byte $15 ; |   X X X| $FEF4
       .byte $55 ; | X X X X| $FEF5



FootAnim:
       .byte <Foot1       ; $FFF2
       .byte <Foot2       ; $FFF3



DGFX:
Logo1gfx:
       .byte $DF ; |XX XXXXX| $FE89
       .byte $CE ; |XX  XXX | $FE8A
       .byte $F7 ; |XXXX XXX| $FE8B
       .byte $DB ; |XX XX XX| $FE8C
       .byte $F9 ; |XXXXX  X| $FE8D
       .byte $F8 ; |XXXXX   | $FE8E
       .byte $F0 ; |XXXX    | $FE8F

Logo2gfx:
       .byte $C7 ; |XX   XXX| $FE90
       .byte $CF ; |XX  XXXX| $FE91
       .byte $DE ; |XX XXXX | $FE92
       .byte $D8 ; |XX XX   | $FE93
       .byte $DE ; |XX XXXX | $FE94
       .byte $CF ; |XX  XXXX| $FE95
       .byte $47 ; | X   XXX| $FE96

Logo3gfx:
       .byte $1F ; |   XXXXX| $FE97
       .byte $9F ; |X  XXXXX| $FE98
       .byte $1F ; |   XXXXX| $FE99
       .byte $DF ; |XX XXXXX| $FE9A
       .byte $1D ; |   XXX X| $FE9B
       .byte $98 ; |X  XX   | $FE9C
       .byte $10 ; |   X    | $FE9D

Logo4gfx:
       .byte $DF ; |XX XXXXX| $FE9E
       .byte $CE ; |XX  XXX | $FE9F
       .byte $C7 ; |XX   XXX| $FEA0
       .byte $C3 ; |XX    XX| $FEA1
       .byte $C1 ; |XX     X| $FEA2
       .byte $C0 ; |XX      | $FEA3
       .byte $40 ; | X      | $FEA4

Logo5gfx:
       .byte $DF ; |XX XXXXX| $FEA5
       .byte $DF ; |XX XXXXX| $FEA6
       .byte $DF ; |XX XXXXX| $FEA7
       .byte $DF ; |XX XXXXX| $FEA8
       .byte $DD ; |XX XXX X| $FEA9
       .byte $D9 ; |XX XX  X| $FEAA
       .byte $51 ; | X X   X| $FEAB

Logo6gfx:
       .byte $05 ; |     X X| $FEA5
       .byte $05 ; |     X X| $FEA6
       .byte $36 ; | XXX XX | $FEA7
       .byte $4D ; | X X X X| $FEA8
       .byte $35 ; | XXX X X| $FEA9
       .byte $48 ; | X X    | $FEAA
       .byte $30 ; | XXX    | $FEAB

Digit0gfx:
       .byte $3C ; |  XXXX  | $FEAC
       .byte $66 ; | XX  XX | $FEAD
       .byte $66 ; | XX  XX | $FEAE
       .byte $66 ; | XX  XX | $FEAF
       .byte $66 ; | XX  XX | $FEB0
       .byte $66 ; | XX  XX | $FEB1
Digit6gfx:
       .byte $3C ; |  XXXX  | $FEB2
       .byte $66 ; | XX  XX | $FEB3
       .byte $66 ; | XX  XX | $FEB4
       .byte $7C ; | XXXXX  | $FEB5
       .byte $60 ; | XX     | $FEB6
       .byte $62 ; | XX   X | $FEB7
Digit8gfx:
       .byte $3C ; |  XXXX  | $FEB8
       .byte $66 ; | XX  XX | $FEB9
       .byte $66 ; | XX  XX | $FEBA
       .byte $3C ; |  XXXX  | $FEBB
       .byte $66 ; | XX  XX | $FEBC
       .byte $66 ; | XX  XX | $FEBD
Digit9gfx:
       .byte $3C ; |  XXXX  | $FEBE
       .byte $46 ; | X   XX | $FEBF
       .byte $06 ; |     XX | $FEC0
       .byte $3E ; |  XXXXX | $FEC1
       .byte $66 ; | XX  XX | $FEC2
       .byte $66 ; | XX  XX | $FEC3
Digit3gfx:
       .byte $3C ; |  XXXX  | $FEC4
       .byte $46 ; | X   XX | $FEC5
       .byte $06 ; |     XX | $FEC6
       .byte $0C ; |    XX  | $FEC7
       .byte $06 ; |     XX | $FEC8
       .byte $46 ; | X   XX | $FEC9
       .byte $3C ; |  XXXX  | $FECA

Digit4gfx:
       .byte $0C ; |    XX  | $FECB
       .byte $0C ; |    XX  | $FECC
       .byte $7E ; | XXXXXX | $FECD
       .byte $4C ; | X  XX  | $FECE
       .byte $2C ; |  X XX  | $FECF
       .byte $1C ; |   XXX  | $FED0
       .byte $0C ; |    XX  | $FED1

Digit7gfx:
       .byte $18 ; |   XX   | $FED2
       .byte $18 ; |   XX   | $FED3
       .byte $08 ; |    X   | $FED4
       .byte $04 ; |     X  | $FED5
       .byte $02 ; |      X | $FED6
       .byte $62 ; | XX   X | $FED7
Digit2gfx:
       .byte $7E ; | XXXXXX | $FED8
       .byte $60 ; | XX     | $FED9
       .byte $60 ; | XX     | $FEDA
       .byte $3C ; |  XXXX  | $FEDB
       .byte $06 ; |     XX | $FEDC
       .byte $46 ; | X   XX | $FEDD

Digit5gfx:
       .byte $7C ; | XXXXX  | $FEDE
       .byte $46 ; | X   XX | $FEDF
       .byte $06 ; |     XX | $FEE0
       .byte $7C ; | XXXXX  | $FEE1
       .byte $60 ; | XX     | $FEE2
       .byte $60 ; | XX     | $FEE3
Digit1gfx:
       .byte $7E ; | XXXXXX | $FEE4
       .byte $18 ; |   XX   | $FEE5
       .byte $18 ; |   XX   | $FEE6
       .byte $18 ; |   XX   | $FEE7
       .byte $18 ; |   XX   | $FEE8
       .byte $78 ; | XXXX   | $FEE9
       .byte $38 ; |  XXX   | $FEEA

;SPACEgfx:
;       .byte $00 ; |        | $FEEB
;       .byte $00 ; |        | $FEEC
;       .byte $00 ; |        | $FEED
;       .byte $00 ; |        | $FEEE
;       .byte $00 ; |        | $FEEF
;       .byte $00 ; |        | $FEF0
;       .byte $00 ; |        | $FEF1

Screen_PF1
	.byte #%01111100	; Scanline 36
	.byte #%00101101	; Scanline 27
	.byte #%10011101	; Scanline 18
	.byte #%10001101	; Scanline 9
	.byte #%00000100	; Scanline 0
;free
       .byte $00 ; |        | $FEF0
       .byte $00 ; |        | $FEF1



LDE6C: .byte $20 ; |  X     | $FE6C
       .byte $10 ; |   X    | $FE6D
LDE6E: .byte $08 ; |    X   | $FE6E
LDE6F: .byte $04 ; |     X  | $FE6F

;digit lookup
LDEF6: .byte <Digit0gfx
       .byte <Digit1gfx
       .byte <Digit2gfx
       .byte <Digit3gfx
       .byte <Digit4gfx
       .byte <Digit5gfx
       .byte <Digit6gfx
       .byte <Digit7gfx
       .byte <Digit8gfx
       .byte <Digit9gfx
;       .byte <SPACEgfx
       .byte <Logo6gfx
       .byte <Logo5gfx
       .byte <Logo4gfx
       .byte <Logo3gfx
       .byte <Logo2gfx
       .byte <Logo1gfx

LDF41: .byte $90 ; |X  X    | $FF41
       .byte $F0 ; |XXXX    | $FF42
LDE0A: .byte $10 ; |   X    | $FE0A
       .byte $10 ; |   X    | $FE0B
LDE0C: .byte $08 ; |    X   | $FE0C
LDE0D: .byte $00 ; |        | $FE0D
       .byte $08 ; |    X   | $FE0E
LDE0F: .byte $C9 ; |XX  X  X| $FE0F
       .byte $39 ; |  XXX  X| $FE10
LDE11: .byte $C9 ; |XX  X  X| $FE11
       .byte $CF ; |XX  XXXX| $FE12

       ORG $1FF0
       RORG $DFF0
       .byte $00	; WriteToBuffer
       .byte $00	; WriteSendBuffer
       .byte $00	; ReceiveBuffer
       .byte $ff	; ReceiveBufferSize

       ORG $1FF8
       RORG $DFF8

       .word 0,0,START1,0



















       ORG $2000
       RORG $F000
	.byte "api.php", #0
	.byte "highscore.firmaplus.de", #0
        
START2:
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       JMP    START                   ;3


Bootscreen_Bankswitch2:
       STA    $1FF8                   ;4 call bank 1
       JMP    Bootscreen_Done         ;3



LF07F:
       STA    $1FF8                   ;4 call bank 1
;flash maze?

       BIT    vitaminTimer            ;3
       BPL    NoClear                 ;2

       BIT    frameCount              ;3
       BMI    FlashDone               ;2


       LDA    #$00                    ;2
       STA    AUDV0                   ;3
       STA    AUDV1                   ;3
       STA    AUDF0                   ;3
       STA    AUDF1                   ;3
       STA    AUDC0                   ;3
       STA    AUDC1                   ;3
       STA    gameState+1             ;3
       STA    gameState+2             ;3

       JMP    LF7D1                   ;3
;moved game refill
FlashDone:
       LDA    #Time2                  ;2 reset timer
       STA    frameCount              ;3

       LDA    remainingLives          ;3
       AND    #$F0                    ;2
       BEQ    No_Intermission2        ;2
       CMP    #$10                    ;2
       BEQ    SetInt                  ;2
       AND    #$30                    ;2
       BNE    No_Intermission2        ;2
SetInt:
       LDA    playerState             ;3
       ORA    #$20                    ;2
       STA    playerState             ;3
No_Intermission2:
       LDA    gameState               ;3
       AND    #$FD                    ;2
       STA    gameState               ;3
       LDA    remainingLives          ;3
       AND    #$F7                    ;2 clear off fruit flag
       CMP    #$EF                    ;2
       BCS    LF6BF                   ;2
       CLC                            ;2
       ADC    #$10                    ;2
LF6BF:
       STA    remainingLives          ;3

LF6C0: LDA    currentPlayerVars+17    ;3
       CMP    #$0E                    ;2
       BEQ    LF6C8                   ;2
       INC    currentPlayerVars+17    ;5
LF6C8: JSR    LFC0C                   ;6 refill all the dots

       LDA    frameCount              ;3
       AND    #$03                    ;2
       STA    frameCount              ;3

       LDA    #$07                    ;2 reset the timer
       STA    vitaminTimer            ;3

       JMP    LF7BA                   ;3











;int check done
NoClear:
       LDX    gameTimer+1             ;3
;       BNE    LF4F4                   ;2
       BEQ    inprogress              ;2


;game inactive
       LDA    remainingLives          ;3
       AND    #$F7                    ;2 clear off fruit flag
       STA    remainingLives          ;3
       JMP    LF7C3                   ;3
inprogress:


       LDY    #$00                    ;2
       LDA    objectY,X               ;4
       BEQ    LFBBB                   ;2
LFBB3: INY                            ;2
       SEC                            ;2
       SBC    #$0A                    ;2
       BEQ    LFBBB                   ;2
       BPL    LFBB3                   ;2
LFBBB: STY    kernelSection           ;3
       STA    gameSelection+1         ;3
       LDA    objectX,X               ;4
       AND    #$03                    ;2
       STA    gameSelection+2         ;3
       LDA    kernelSection           ;3
       LSR                            ;2
       PHP                            ;3
       LDA    objectX,X               ;4
       LSR                            ;2
       LSR                            ;2
       PLP                            ;4
       BCC    LFBD3                   ;2
       CLC                            ;2
       ADC    #$28                    ;2
LFBD3: STA    waferIndex              ;3
       ASL                            ;2
       ASL                            ;2
       ROR    kernelSection           ;5
       ORA    kernelSection           ;3
       ROL    kernelSection           ;5
       STA    joystickValue+1         ;3




       LDA    ghostEatingDelay        ;3
       BPL    LF4F7                   ;2
       DEC    ghostEatingDelay        ;5
LF4F4: JMP    LF7C3                   ;3

LF4F7: LDA    EnergizerTime           ;3
       BEQ    LF55B                   ;2

       LDA    frameCount              ;3
       ROR                            ;2
       BCC    LF55B                   ;2
;       LDA    #$01                    ;2
;       BIT    gameState               ;3
;       BVS    Notune1                 ;2
;       LDA    #$03                    ;2
;Notune1:
;       AND    frameCount              ;3
;       BNE    LF55B                   ;2


       DEC    EnergizerTime           ;5 XXXXXXXXXXXXXX
       BNE    LF55B                   ;2
       BIT    currentPlayerVars+18    ;3
       LDA    currentPlayerVars+18    ;3
       BPL    LF51A                   ;2
       BVC    LF516                   ;2
       AND    #$BF                    ;2
       STA    currentPlayerVars+18    ;3



;flash time
;       LDA    #$20                    ;2
       LDA    remainingLives          ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       TAY                            ;2
       LDA    EnergizerTimeTab,Y      ;4
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       STA    EnergizerTime           ;3 XXXXXXXXXXXXXXX
       JMP    LF55B                   ;2

LF516: AND    #$7C                    ;2
       STA    currentPlayerVars+18    ;3



;newb
       LDX    #$03                    ;2
RemoveBflagloop:
       LDA    ghostDirections,X       ;4
       AND    #$FB                    ;2 remove blue flags
       STA    ghostDirections,X       ;4
       DEX                            ;2
       BPL    RemoveBflagloop         ;2




LF51A: LDA    gameState               ;3
       AND    #$40                    ;2
       BEQ    LF553                   ;2
       EOR    gameState               ;3
       STA    gameState               ;3
       JSR    LFC21                   ;6
       BIT    playerState             ;3
       BVC    LF538                   ;2
       LDA    tempRemainingLives      ;3

       AND    #$03                    ;2

       BEQ    LF538                   ;2
       JSR    LFB9F                   ;6
       LDA    playerState             ;3
       EOR    #$80                    ;2
       STA    playerState             ;3
LF538: LDA    remainingLives          ;3
       ORA    tempRemainingLives      ;3

       AND    #$03                    ;2

       BEQ    LF548                   ;2
       DEC    remainingLives          ;5
       LDA    #$08                    ;2
       ORA    gameState               ;3
       STA    gameState               ;3
       BNE    LF55B                   ;2

;game over
LF548:
       JSR    SendScore
       STA    gameState               ;3
       LDA    #$5F                    ;2
       STA    gameTimer+1             ;3
       STA    pacmanY                 ;3
       JMP    LF7C3                   ;3
LF553: LDA    gameState               ;3
       BPL    LF55B                   ;2
       AND    #$7F                    ;2
       STA    gameState               ;3
LF55B: LDA    gameState               ;3
       BPL    LF573                   ;2
       LDA    currentPlayerVars+17    ;3
       TAY                            ;2
       DEY                            ;2
       LDX    #$04                    ;2
LF565: STA    SwapP0,X                ;4
       STY    SwapP1,X                ;4
       DEX                            ;2
       STY    SwapP1,X                ;4
       STY    SwapP0,X                ;4
       DEX                            ;2
       BNE    LF565                   ;2
;       BEQ    LF4F4                   ;2
;       JMP    LF4F4                   ;3
       JMP    LF7C3                   ;3
  
LF573:
;       LDA    CXP1FB                  ;3
;       AND    #$40                    ;2
;       BEQ    LF591                   ;2

;       LDA    frameCount              ;3
;       AND    #$01                    ;2
;       BNE    LF591                   ;2



       LDA    remainingLives          ;3
       AND    #$08                    ;2
       BNE    LF591                   ;2 branch if vitamin already flagged
       LDA    gameState               ;3
       AND    #$02                    ;2
       BEQ    LF591                   ;2 branch if vitamin not onscreen
       LDA    pacmanY                 ;3
       CMP    #$28                    ;2
       BNE    LF591                   ;2 branch if not below the box
       LDA    pacmanX                 ;3
       CMP    #$4B                    ;2
       BNE    LF591                   ;2 branch if not in the center of the screen
  
;eat vitamin


       LDA    remainingLives          ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       CLC                            ;2
       ADC    #$06                    ;2
       TAY                            ;2
       JSR    LFC45                   ;6
       LDY    #$01                    ;2
;       JSR    LFF43                   ;6
;LFF43:
       LDA    LFFE9,Y                 ;4
       AND    gameState+1             ;3
       BNE    LFF54b                  ;2
       LDA    LFE6E,Y                 ;4
       STA    gameState+1             ;3
       LDA    LFFED,Y                 ;4
       STA    gameState+2             ;3
LFF54b:




       LDA    remainingLives          ;3
       ORA    #$08                    ;2
       STA    remainingLives          ;3

       LDA    frameCount              ;3
       AND    #$03                    ;2
       ORA    #$80                    ;2
       STA    frameCount              ;3

       LDA    #$01                    ;2
       STA    vitaminTimer            ;3


       BNE    LF5D3                   ;2


LF591:
;       TAX                            ;2
       LDX    #$00                    ;2


       LDA    pacmanY                 ;3
       CMP    #$05                    ;2
       BEQ    LF59D                   ;2
       CMP    #$41                    ;2
       BNE    LF5D3                   ;2
       INX                            ;2
LF59D: LDA    pacmanX                 ;3
       CMP    #$04                    ;2
       BEQ    LF5A9                   ;2
       CMP    #$94                    ;2
       BNE    LF5D3                   ;2
       INX                            ;2
       INX                            ;2
LF5A9: LDA    LFE6C,X                 ;4
       TAY                            ;2
       AND    currentPlayerVars+18    ;3
       BEQ    LF5D3                   ;2





       TYA                            ;2
       EOR    #$FF                    ;2
       AND    currentPlayerVars+18    ;3
       ORA    #$C0                    ;2

       AND    #$FC                    ;2 bugfix...remove current monster count

       STA    currentPlayerVars+18    ;3

;       LDY    #$A0                    ;2 high bluetime
;       LDA    gameState               ;3
;       AND    #$20                    ;2
;       STA    EnergizerTime           ;3
;       BEQ    LF5C4                   ;2
;       LDY    #$50                    ;2 low bluetime
;LF5C4: STY    EnergizerTime           ;3 XXXXXXXXXXXXXXXX





;moved
       LDY    #$05                    ;2
       JSR    LFC45                   ;6



;newb
;ok
       LDX    #$03                    ;2
AddBflagloop:
       LDA    ghostDirections,X       ;4
       TAY                            ;2
       AND    #$08                    ;2
       BNE    Eyes1                   ;2
       TYA                            ;2
       ORA    #$04                    ;2 set blue flag
       STA    ghostDirections,X       ;4
Eyes1:
       DEX                            ;2
       BPL    AddBflagloop            ;2



       LDY    #$02                    ;2
;       JSR    LFF43                   ;6
;LFF43:
       LDA    LFFE9,Y                 ;4
       AND    gameState+1             ;3
       BNE    LFF54a                  ;2
       LDA    LFE6E,Y                 ;4
       STA    gameState+1             ;3
       LDA    LFFED,Y                 ;4
       STA    gameState+2             ;3
LFF54a:



       LDA    remainingLives          ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       TAY                            ;2
       LDA    EnergizerTimeTab,Y      ;4
       BNE    LF5D2                   ;2


;       BIT    currentPlayerVars+18    ;3
       LDA    currentPlayerVars+18    ;3
;       BPL    LF51A                   ;2
;       BVC    LF516                   ;2
       AND    #$BF                    ;2
       STA    currentPlayerVars+18    ;3
       LDA    #$01                    ;2
       STA    EnergizerTime           ;3 XXXXXXXXXXXXXXX
       BPL    LF5D3                   ;2




LF5D2:
       TAX                            ;2

       LDA    gameState               ;3
       AND    #$20                    ;2
       BEQ    LF5C4                   ;2

       TXA                            ;2
       LSR                            ;2
       .byte $24
LF5C4:
       TXA                            ;2
       STA    EnergizerTime           ;3
       JMP    LF6AA                   ;3




























LF5D3:
;       LDA    frameCount              ;3
;       AND    #$03                    ;2
;       TAX                            ;2
       LDX    #$03                    ;2
LF5D4:
;check for player being killed
;tunnel check
       LDA    pacmanDirection         ;3
       AND    #$20                    ;2 in the tunnel?
       BNE    Eyejump                 ;2
       LDA    ghostDirections,X       ;4
       AND    #$20                    ;2 in the tunnel?
       BNE    Eyejump                 ;2

       LDA    ghostDirections,X       ;4
       AND    #$08                    ;2
       BNE    Eyejump                 ;2 branch if eyes

       LDA    ghost0X,X               ;4
       SEC                            ;2
       SBC    pacmanX                 ;3
       TAY                            ;2
       SEC                            ;2
       SBC    #$04                    ;3
       CMP    #$FC-4-1                ;2
       BCC    Close1                  ;2 branch if not close
       LDA    ghost0Y,X               ;4
       SEC                            ;2
       SBC    #$04                    ;3
       SEC                            ;2
       SBC    pacmanY                 ;3
       CMP    #$FC-4-1                ;2

Close1:
       BCC    LF61E                   ;2 branch if not close
       TYA                            ;2
       BEQ    Playerhit               ;2 branch if equal
       LDA    ghost0Y,X               ;4
       CMP    pacmanY                 ;3
Eyejump:
       BNE    LF61E                   ;2 branch if not equal


Playerhit:
       LDA    ghostDirections,X       ;4
       TAY                            ;2
       AND    #$04                    ;2 check for blue flag

  IF CHEAT
       BEQ    LF61E                   ;2 branch if not equal
  ELSE
       BEQ    LF60B                   ;2 branch if no bluetime
  ENDIF
       TYA                            ;2
       EOR    #$0C                    ;2 set bit to indicate that monster eaten
       STA    ghostDirections,X       ;4


;check for any still blue
       LDA    ghostDirections         ;3
       ORA    ghostDirections+1       ;3
       ORA    ghostDirections+2       ;3
       ORA    ghostDirections+3       ;3
       AND    #$04                    ;2
       BNE    StillBlue               ;2

       LDA    #$01                    ;2
       STA    EnergizerTime           ;3 kill energizer
       LDA    currentPlayerVars+18    ;3
       AND    #$BF                    ;2
       STA    currentPlayerVars+18    ;3
StillBlue:
       LDA    currentPlayerVars+18    ;3
       AND    #$03                    ;2
       TAY                            ;2
;here
       LDA    PTGFX,Y                 ;4
       STA    pacmanPointer           ;3

       JSR    LFC45                   ;6
       CPY    #$03                    ;2
       BEQ    LF600                   ;2
       INC    currentPlayerVars+18    ;5
LF600: LDY    #$03                    ;2
       LDA    LFFE9,Y                 ;4
       AND    gameState+1             ;3
       BNE    LFF54c                  ;2
       LDA    LFE6E,Y                 ;4
       STA    gameState+1             ;3
       LDA    LFFED,Y                 ;4
       STA    gameState+2             ;3
LFF54c:


       LDA    #$9F                    ;2
       STA    ghostEatingDelay        ;3
;       BNE    LF61E                   ;2
       BNE    LF61F                   ;2 drop out of the loop

LF60B:
Ldeath:
;set death sequence
;added
       LDA    #$00                    ;2
       STA    AUDV1                   ;3
       LDA    #$07                    ;2 reset timer
       STA    vitaminTimer            ;3
       LDA    gameState               ;3
       AND    #$02                    ;2
       BEQ    LF60C                   ;2
       LDA    remainingLives          ;3
       ORA    #$08                    ;2 set fruit flag
       STA    remainingLives          ;3
LF60C:
       LDA    #$C0                    ;2
       ORA    gameState               ;3
       AND    #$FD                    ;2
       STA    gameState               ;3
       LDA    #$3F                    ;2
       STA    EnergizerTime           ;3 XXXXXXXXXXXXXXX
       JMP    LF7BA                   ;3
LF61E:
       DEX                            ;2
       BMI    LF61F                   ;2
       JMP    LF5D4                   ;3


















LF61F:
       LDA    SWCHA                   ;4
       BIT    playerState             ;3
       BMI    LF629                   ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
LF629: EOR    #$FF                    ;2
       AND    #$0F                    ;2
       STA    joystickValue           ;3
       BEQ    LF635                   ;2
       LDA    #$00                    ;2
       STA    gameTimer               ;3
LF635: LDA    pacmanDirection         ;3
       AND    #$20                    ;2
       BEQ    LF666                   ;2
       LDA    joystickValue           ;3
       LSR                            ;2
       BCC    LF65D                   ;2
       LDA    pacmanDirection         ;3
       BMI    LF656                   ;2
LF644: AND    #$10                    ;2
       BNE    LF659                   ;2
       LDA    #$3F                    ;2
       EOR    pacmanY                 ;3
       AND    #$3F                    ;2
       STA    pacmanY                 ;3
       LDA    #$C0                    ;2
LF652: EOR    pacmanDirection         ;3
       STA    pacmanDirection         ;3
LF656: JMP    LF7BA                   ;3
LF659: LDA    #$80                    ;2
       BNE    LF652                   ;2
LF65D: LSR                            ;2
       BCC    LF656                   ;2
       LDA    pacmanDirection         ;3
       BMI    LF644                   ;2
       BPL    LF656                   ;2
LF666: LDA    gameSelection+1         ;3
       BNE    LF6AA                   ;2
       LDY    waferIndex              ;3
       LDA    LFE13,Y                 ;4
       LDX    pacmanX                 ;3
       CPX    #$4C                    ;2
       BEQ    LF67D                   ;2
       LDX    pacmanDirection         ;3
       BPL    LF67D                   ;2
       INY                            ;2
       ORA    LFE13,Y                 ;4
LF67D: LSR                            ;2
       BCC    LF6AA                   ;2
       LSR                            ;2
       TAX                            ;2
       LDA    kernelSection           ;3
       ROL                            ;2
       TAY                            ;2
       LDA    LFE79,Y                 ;4
       TAY                            ;2
       TXA                            ;2
       AND    #$07                    ;2
       TAX                            ;2
       LDA    LFE6A,X                 ;4
       TAX                            ;2
       AND.wy currentPlayerVars,Y     ;4
       BEQ    LF6AA                   ;2
       TXA                            ;2
       EOR    #$FF                    ;2
       AND.wy currentPlayerVars,Y     ;4
       STA.wy currentPlayerVars,Y     ;5
       LDY    #$04                    ;2
       JSR    LFC45                   ;6
       LDY    #$00                    ;2
;       JSR    LFF43                   ;6
;LFF43:
       LDA    LFFE9,Y                 ;4
       AND    gameState+1             ;3
       BNE    LFF54d                  ;2
       LDA    LFE6E,Y                 ;4
       STA    gameState+1             ;3
       LDA    LFFED,Y                 ;4
       STA    gameState+2             ;3
LFF54d:


LF6AA: LDX    #$0F                    ;2
       LDA    currentPlayerVars+18    ;3
       AND    #$3C                    ;2
LF6B0: ORA    currentPlayerVars,X     ;4
       DEX                            ;2
       BPL    LF6B0                   ;2
       TAX                            ;2
       BNE    LF6CE                   ;2 branch if any dots left


;added
;       LDA    #$07                    ;2 reset timer
       STX    frameCount              ;3 @ $00
       DEX                            ;2
       STX    vitaminTimer            ;3 @ $FF


;moved game refill
       JMP    LF7BA                   ;3




LF6CE: LDX    #$00                    ;2
       LDA    joystickValue           ;3
       STA    kernelPFValues          ;3
       BNE    LF6D9                   ;2
       JMP    LF78A                   ;3
LF6D9: LDY    pacmanDirection         ;3
       BPL    LF72D                   ;2
LF6DD: LSR                            ;2
       LSR                            ;2
       AND    #$03                    ;2
       BEQ    LF725                   ;2
       LSR                            ;2
       LDA    gameSelection+1         ;3
       BNE    LF725                   ;2
       LDA    gameSelection+2         ;3
       BEQ    LF6F0                   ;2
       BCC    LF71B                   ;2
       BCS    LF700                   ;2
LF6F0: LDY    waferIndex              ;3
       BCC    LF70A                   ;2
       LDA    joystickValue+1         ;3
       CMP    #$F9                    ;2
       BEQ    LF725                   ;2
       DEY                            ;2
       LDA    LFE13,Y                 ;4
       BMI    LF725                   ;2
LF700: LDA    #$01                    ;2
       ORA    pacmanDirection         ;3
       STA    pacmanDirection         ;3
       LDY    #$01                    ;2
       BNE    LF77B                   ;2
LF70A: LDA    kernelSection           ;3
       CMP    #$03                    ;2
       BNE    LF714                   ;2
       CPY    #$38                    ;2
       BEQ    LF725                   ;2
LF714: INY                            ;2
       INY                            ;2
       LDA    LFE13,Y                 ;4
       BMI    LF725                   ;2
LF71B: LDA    #$FE                    ;2
       AND    pacmanDirection         ;3
       STA    pacmanDirection         ;3
       LDY    #$00                    ;2
       BEQ    LF77B                   ;2
LF725: LDA    kernelPFValues          ;3
       AND    #$F3                    ;2
       BEQ    LF78A                   ;2
       STA    kernelPFValues          ;3
LF72D: LDA    kernelPFValues          ;3
       AND    #$03                    ;2
       BEQ    LF781                   ;2
       LSR                            ;2
       LDA    gameSelection+2         ;3
       BNE    LF781                   ;2
       LDA    pacmanX                 ;3
       CMP    #$4C                    ;2
       BNE    LF75B                   ;2
       LDA    pacmanY                 ;3
       BEQ    LF751                   ;2
       CMP    #$46                    ;2
       BNE    LF75B                   ;2
       LDA    kernelPFValues          ;3
       LSR                            ;2
       LSR                            ;2
       BCC    LF75B                   ;2
       JSR    LFD26                   ;6
       BNE    LF7BA                   ;2
LF751: LDA    kernelPFValues          ;3
       LSR                            ;2
       BCC    LF75B                   ;2
       JSR    LFD32                   ;6
       BNE    LF7BA                   ;2
LF75B: LDA    kernelPFValues          ;3
       LSR                            ;2
       LDA    gameSelection+1         ;3
       BEQ    LF766                   ;2
       BCC    LF779                   ;2
       BCS    LF770                   ;2
LF766: LDY    waferIndex              ;3
       LDA    LFE13,Y                 ;4
       BCC    LF775                   ;2
       ROL                            ;2
       BPL    LF781                   ;2
LF770: LDY    #$03                    ;2
       JMP    LF77B                   ;3
LF775: ROL                            ;2
       ROL                            ;2
       BPL    LF781                   ;2
LF779: LDY    #$02                    ;2
LF77B: JSR    LF9E5                   ;6
       JMP    LF7BA                   ;3
LF781: LDA    kernelPFValues          ;3
       AND    #$FC                    ;2
       STA    kernelPFValues          ;3
       JMP    LF6DD                   ;3
LF78A: JSR    LF793                   ;6
       JSR    LF9EE                   ;6
       JMP    LF7BA                   ;3
LF793: LDA    gameSelection+1         ;3
       ORA    gameSelection+2         ;3
       BEQ    LF79A                   ;2
       RTS                            ;6

LF79A: LDA    objectDirections,X      ;4
       ROL                            ;2
       BCS    LF7AD                   ;2
       BPL    LF7A7                   ;2
       JSR    LFB70                   ;6
       JMP    LF7B8                   ;3
LF7A7: JSR    LFB87                   ;6
       JMP    LF7B8                   ;3
LF7AD: BPL    LF7B5                   ;2
       JSR    LFB36                   ;6
       JMP    LF7B8                   ;3
LF7B5: JSR    LFB5C                   ;6
LF7B8: PLA                            ;4
       PLA                            ;4
LF7BA:

;reflect
;       LDA    pacmanDirection         ;3
;       ROR                            ;2
;       BCC    LF7C3                   ;2
;       LDA    #$08                    ;2
;       STA    REFP1                   ;3




LF7C3:
       LDX    #$00                    ;2
       STX    AUDV0                   ;3

       JSR    LFF55                   ;6
       LDX    #$01                    ;2
       JSR    LFF94                   ;6















;wait
LF7D1: LDA    INTIM                   ;4
       BNE    LF7D1                   ;2
LF7D6: LDA    #$03                    ;2
       STA    WSYNC                   ;3
       STA    VBLANK                  ;3
       STA    VSYNC                   ;3
       STA    CXCLR                   ;3
       LDA    frameCount              ;3 load fast timer

;       TAY                            ;2
;       AND    #$03                    ;2
;       TAX                            ;2
;       LDA    EyeMov,X                ;4 load the current monster #
;       TAX                            ;2
;newb
       AND    #$03                    ;2
       TAY                            ;2
       LDX    EyeMov,Y                ;4 load the current monster #
;       TAX                            ;2

       LDA    ghostDirections,X       ;4
       AND    #$04                    ;2
       STA    Temp                    ;3


       LDA    frameCount              ;3 load fast timer

       LSR                            ;2
       TAY                            ;2 save for pac animation
       ASL                            ;2

       AND    #$18                    ;2 keep only values 0-3
       STA    ghostPointer            ;3 save as the frame offset
;       LDA    frameCount              ;3 load fast timer
;animations
;       LSR                            ;2
;       LSR                            ;2
;       TAY                            ;2 save for pac animation


       LDA    ghostDirections,X       ;4
       AND    #$C0                    ;2 fetch current monster direction
       CLC                            ;2
       ADC    ghostPointer            ;3 ...and add in the offset

;newb
;added
       BIT    Temp                    ;3
       BEQ    Lnoblue                 ;2 branch if no bluetime
;removed
;       BIT    currentPlayerVars+18    ;3
;       BPL    Lnoblue                 ;2 branch if no bluetime
       ADC    #$20                    ;2 skip 4 frames & grab blue monster GFX
Lnoblue:
       STA    ghostPointer            ;3


       LDA    gameState               ;3
       AND    #$02                    ;2
       BEQ    UsePacSprite2           ;2 branch if vitamin not onscreen

       LDA    frameCount              ;3
       AND    #$01                    ;2
       BNE    UsePacSprite2           ;2

       BIT    ghostEatingDelay        ;3
       BMI    UsePacSprite2           ;2

       LDA    remainingLives          ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2

       TAY                            ;2
       LDA    FruitTypeTbl,Y          ;4
       STA    pacmanPointer           ;3




;added to display fruit points
       LDA    remainingLives          ;3
       AND    #$08                    ;2
       BEQ    KeepFruitColor          ;2

       LDA    pacmanPointer           ;3
       ORA    #$80                    ;2
       STA    pacmanPointer           ;3

       LDY    #$05                    ;2
       BNE    DisplayWhitePts         ;2

KeepFruitColor:
       TYA                            ;2
       CLC                            ;2
       ADC    #$0B                    ;2
       TAY                            ;2

DisplayWhitePts:
       STY    pacmanColorPtr          ;3

;use fruit
       LDA    #>FruitGFX              ;2<- hibyte GFX
       STA    pacmanPointer+1         ;3
       LDA    #$33                    ;2

       STA    pacmanOffset            ;3

       JMP    PacSpriteDone           ;3



UsePacSprite2:
       LDA    gameState               ;3
       ROL                            ;2
       BPL    LF800                   ;2
       LDA    EnergizerTime           ;3
       LSR                            ;2
       LSR                            ;2
       AND    #$0F                    ;2
       TAX                            ;2
       LDA    LFDFA,X                 ;4
       BNE    LF80F                   ;2

LF800:
       LDA    #$02                    ;2 <-Pts color offset
       BIT    ghostEatingDelay        ;3
       BMI    SkipAnimation           ;2

       TYA                            ;2 pull pac animation speed
       AND    #$07                    ;2 keep values 0-7
       TAX                            ;2
       LDA    LFDC2,X                 ;4 load pac frame
;       LDX    gameState               ;3 ???
;       BPL    LF80E                   ;2
;       LDA    LFDC2                   ;4
;;       LDA    #<RPac1gfx              ;2
;LF80E:
       STA    pacmanPointer           ;3
       LDA    pacmanDirection         ;3
       AND    #$C0                    ;2
       CLC                            ;2
       ADC    pacmanPointer           ;3
LF80F: STA    pacmanPointer           ;3

       LDA    #$06                    ;2 <-Pac color offset
SkipAnimation:
       STA    pacmanColorPtr          ;3


       LDA    #>PGFX                  ;2<- hibyte GFX
       STA    pacmanPointer+1         ;3
       LDA    pacmanY                 ;3
       CLC                            ;2
       ADC    #$0B                    ;2
       STA    pacmanOffset            ;3


PacSpriteDone:
       STA    WSYNC                   ;3




;from PacSpriteDone
       INC    frameCount              ;5
       BNE    LF83D                   ;2
       INC    gameTimer               ;5
       BEQ    LF839                   ;2
;       DEC    vitaminTimer            ;5
;       BNE    LF835                   ;2

       LDX    vitaminTimer            ;3
       BEQ    LF835                   ;2
       DEX                            ;2
       STX    vitaminTimer            ;3
       BNE    LF835                   ;2


       LDY    #$07                    ;2
       LDA    gameState               ;3
       EOR    #$02                    ;2
       STA    gameState               ;3
       AND    #$02                    ;2
       BNE    LF831                   ;2
       LDA    remainingLives          ;3
       ORA    #$08                    ;2
       STA    remainingLives          ;3
       BNE    LF833                   ;2
LF831:
;skip if flag already set
       LDA    remainingLives          ;3
       AND    #$08                    ;2
       BEQ    LF832                   ;2
       LDA    gameState               ;3
       AND    #$FD                    ;2
       STA    gameState               ;3
       JMP    LF833                   ;3
LF832:
       LDY    #$03                    ;2
       LDA    gameState               ;3
       AND    #$20                    ;2
       BEQ    LF833                   ;2
       DEY                            ;2
LF833: STY    vitaminTimer            ;3
LF835: LDA    gameTimer+1             ;3
       BEQ    LF83D                   ;2
LF839: INC    gameTimer+1             ;5
       BEQ    LF839                   ;2
LF83D:






       STA    WSYNC                   ;3
       LDA    #>MGFX                  ;2<- hibyte GFX
       STA    ghostPointer+1          ;3





       LDX    #$07                    ;2
       STX    ghostIndex              ;3
       DEX                            ;2
       STX    pacmanIndex             ;3
       LDX    #$FF                    ;2
       LDA    #$08                    ;2
       AND    SWCHB                   ;4
       BNE    LF85E                   ;2
       LDX    #$0F                    ;2
LF85E: TXA                            ;2
       LDX    gameTimer+1             ;3
       BEQ    LF865                   ;2
       EOR    #$08                    ;2
LF865: STA    CopySWCHB               ;3
       LDA    #$07                    ;2
       STA    backgroundColor         ;3
       LDA    #$08                    ;2
       STA    playfieldColor          ;3

;       LDA    temporaryPlayerVars+19  ;3
       LDA    #$09                    ;2
       STA    tempColorPtr            ;3

       LDA    #T2                     ;2
       STA    TIM64T                  ;4
       STA    WSYNC                   ;3
       LDX    #$00                    ;2
       STX    VSYNC                   ;3

;       LDA    currentPlayerVars+19    ;3
       LDA    #$0A                    ;2
       STA    tempColorPtr+1          ;3

       LDA    gameTimer+1             ;3
       BEQ    LF88A                   ;2
       LDA    INPT4                   ;3
       BPL    LF890                   ;2
LF88A: LDA    SWCHB                   ;4
       ROR                            ;2
       BCS    LF8C1                   ;2
LF890: LDA    #$FF                    ;2
       STA    mazeIndex+1             ;3
       JSR    LFC7D                   ;6
       STA    tempRemainingLives      ;3 was $FF
       STA    gameTimer+1             ;3
       LDA    #$08                    ;2
       STA    gameState               ;3


       LDA    #$0B                    ;2
       LDX    gameSelection           ;3
;higher games
;       LDA    gameSelection           ;3
;       SEC                            ;2
;       SBC    #$02                    ;2
;       AND    #$0F                    ;2
;       CLC                            ;2
;       ADC    #$02                    ;2
;       TAX                            ;2
;       LDA    #$0B                    ;2




       CPX    #$08                    ;2
       BPL    LF8A9                   ;2
       LDA    #$09                    ;2
LF8A9: STA    SwapP0                  ;3
       JSR    LFBF4                   ;6
       LDA    playerState             ;3
       AND    #$7F                    ;2
       STA    playerState             ;3
       ASL                            ;2
       BPL    LF909                   ;2
       JSR    LFB9F                   ;6
       JSR    LFBF4                   ;6
       INC    tempRemainingLives      ;5
       BNE    LF909                   ;2
LF8C1: ROR                            ;2
       BCS    LF909                   ;2
       LDA    selectDebounce          ;3
       BNE    LF8FF                   ;2
LF8C8: INC    gameSelection           ;5
       LDA    #$60                    ;2
       STA    pacmanY                 ;3
       LDA    #$10                    ;2
       STA    gameState               ;3
       LDA    playerState             ;3
       EOR    #$40                    ;2
       STA    playerState             ;3
       JSR    LFC7D                   ;6
       STA    AUDV0                   ;3
       STA    AUDV1                   ;3
       STA    gameState+1             ;3
       LDA    #$01                    ;2
       STA    gameTimer+1             ;3


       LDA    #Time                   ;2
       STA    frameCount              ;3


       LDA    gameSelection           ;3
;higher games
       CMP    #$12                    ;2
       BNE    LF8EF                   ;2
       LDA    #$02                    ;2
LF8EF: STA    gameSelection           ;3
       LSR                            ;2
       SEC                            ;2
       SBC    #$02                    ;2
       AND    #$07                    ;2
       BNE    LF8FB                   ;2
       LDA    #$08                    ;2
LF8FB: STA    playerScoreL0           ;3
       STA    playerScoreL1           ;3
LF8FF: INC    selectDebounce          ;5
       LDA    selectDebounce          ;3
       AND    #$1F                    ;2
       BNE    LF90D                   ;2
       BEQ    LF8C8                   ;2
LF909: LDY    #$00                    ;2
       STY    selectDebounce          ;3
LF90D: LDA    #$DF                    ;2
       AND    gameState               ;3
       STA    gameState               ;3
       LDA    #$80                    ;2
       BIT    playerState             ;3
       BMI    LF91A                   ;2
       LSR                            ;2
LF91A: LDX    #$20                    ;2
       AND    SWCHB                   ;4
       BNE    LF923                   ;2
       LDX    #$00                    ;2
LF923: TXA                            ;2
       ORA    gameState               ;3
       STA    gameState               ;3
       LDA    frameCount              ;3
       AND    #$03                    ;2
       TAX                            ;2
       TAY                            ;2

;newb
;ok
       LDA    ghostDirections,X       ;4
       AND    #$04                    ;2
       BEQ    LF93D                   ;2 branch if no bluetime


       LDA    currentPlayerVars+18    ;3

;ok
;removed
;       BPL    LF93D                   ;2 branch if no bluetime
       LDY    #$04                    ;2 load blue color pointer
       AND    #$40                    ;2
       BNE    LF93D                   ;2

       LDA    frameCount              ;3 bugfix for flash
       AND    #$08                    ;2
       BNE    LF93D                   ;2

       INY                            ;2 change to white pointer
LF93D: STY    ghostColorPtr           ;3 set monster color pointer
       INX                            ;2

;80 = moving vertical
;08 = eyes

       LDA    objectDirections,X      ;4
       AND    #$08                    ;2
       BEQ    LF94C                   ;2 <- branch if not eyes
       DEC    ghostPointer+1          ;5 flip to lower GFX page (holding eye bitmap)

       LDA    #$05                    ;2 save pointer to "white"
       STA    ghostColorPtr           ;3

       LDA    ghostPointer            ;3
       AND    #$C0                    ;2 ...and drop off the lower nybble from bitmap pointer
       STA    ghostPointer            ;3
       JMP    LF950                   ;2

LF94C: LDA    ghostEatingDelay        ;3
       BMI    LF95D                   ;2 skip if ghost being eaten (points displayed)



LF950:
       BIT    vitaminTimer            ;3
       BMI    LF95D                   ;2 skip if board flashing

       LDA    gameState               ;3
       BMI    LF95D                   ;2 skip if player dying
       JSR    LF9AA                   ;6 ...otherwise, move ghost
       JSR    LF9AA                   ;6
       JSR    LF9AA                   ;6
LF95D: LDA    objectX,X               ;4
       STA    currentGhostX           ;3
       LDA    objectY,X               ;4
       CLC                            ;2
       ADC    #$0B                    ;2
       STA    ghostOffset             ;3
       LDA    objectDirections,X      ;4
       AND    #$20                    ;2
       BEQ    LF973                   ;2
       LDY    #$00                    ;2
       JSR    LFC8B                   ;6
LF973: LDA    pacmanDirection         ;3
       AND    #$20                    ;2
       BEQ    LF980                   ;2
       LDY    #$01                    ;2
       LDX    #$00                    ;2
       JSR    LFC8B                   ;6

LF980:
       JMP    LF07F                   ;3 jump to bank 1


















LF9AA:
       LDA    objectX,X               ;4
       CMP    #$4C                    ;2
       BNE    LF9D2                   ;2
       LDA    objectY,X               ;4 check if eyes reached box...
       CMP    #$14                    ;2
       BNE    LF9C0                   ;2

       LDA    objectDirections,X      ;4
       AND    #$08                    ;2
       BNE    LF9E5b                  ;2


       LDA    frameCount              ;3
       AND    #$01                    ;2
       TAY                            ;2
       BPL    LF9E5                   ;2


LF9C0: CMP    #$1E                    ;2
       BNE    LF9D2                   ;2


;removed...die twice??
;       LDA    currentPlayerVars+18    ;3
;       BMI    LF9E4                   ;2

;attempt, no luck
       LDA    gameState               ;3
       BMI    LF9E4                   ;2



Cleareye:
       LDA    objectDirections,X      ;4
       AND    #$F3                    ;2 clear eye & blue flag
       STA    objectDirections,X      ;4


;release timer

;       BIT    gameState               ;3
;       BNE    LF9E4                   ;2

       LDA    frameCount              ;3
;       AND    #$7F                    ;2
       CMP    ReleaseTime,X           ;4
       BCC    LF9E4                   ;2



       LDY    #$03                    ;2 set to move up
       BNE    LF9E5                   ;2
LF9D2: LDA    objectDirections,X      ;4
       AND    #$20                    ;2
       BNE    LF9E4                   ;2
       LDY    #$00                    ;2
       LDA    objectY,X               ;4
       BEQ    LFBBC                   ;2
LFBB4: INY                            ;2
       SEC                            ;2
       SBC    #$0A                    ;2
       BEQ    LFBBC                   ;2
       BPL    LFBB4                   ;2
LFBBC: STY    kernelSection           ;3
       STA    gameSelection+1         ;3
       LDA    objectX,X               ;4
       AND    #$03                    ;2
       STA    gameSelection+2         ;3
       LDA    kernelSection           ;3
       LSR                            ;2
       PHP                            ;3
       LDA    objectX,X               ;4
       LSR                            ;2
       LSR                            ;2
       PLP                            ;4
       BCC    LFBD4                   ;2
       CLC                            ;2
       ADC    #$28                    ;2
LFBD4: STA    waferIndex              ;3
       ASL                            ;2
       ASL                            ;2
       ROR    kernelSection           ;5
       ORA    kernelSection           ;3
       ROL    kernelSection           ;5
       STA    joystickValue+1         ;3



       JSR    LFA26                   ;6
       LDA    objectDirections,X      ;4
       AND    #$20                    ;2
       BEQ    LF9EE                   ;2
LF9E4: RTS                            ;6

LF9E5b:
       LDY    #$02                    ;2 move down
LF9E5: LDA    objectDirections,X      ;4
       AND    #$3F                    ;2
       ORA    LFE63,Y                 ;4
       STA    objectDirections,X      ;4
LF9EE: LDA    SwapP0,X                ;4
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       ASL                            ;2
       CLC                            ;2
       ADC    SwapP0,X                ;4
       STA    SwapP0,X                ;4
       BCC    LF9E4                   ;2
       LDY    #$00                    ;2
       LDA    objectDirections,X      ;4
       AND    #$EF                    ;2
       STA    objectDirections,X      ;4
       ROL                            ;2
       BPL    LFA09                   ;2
       DEY                            ;2
       BMI    LFA0A                   ;2
LFA09: INY                            ;2
LFA0A: TYA                            ;2
       BCS    LFA1A                   ;2
       ADC    objectX,X               ;4
       CMP    #$02                    ;2
       BEQ    LFA19                   ;2
       CMP    #$96                    ;2
       BEQ    LFA19                   ;2
       STA    objectX,X               ;4
LFA19: RTS                            ;6

LFA1A: CLC                            ;2
       ADC    objectY,X               ;4
       BMI    LFA25                   ;2
       CMP    #$47                    ;2
       BEQ    LFA25                   ;2
       STA    objectY,X               ;4
LFA25: RTS                            ;6

LFA26: LDA    gameSelection+2         ;3
       ORA    gameSelection+1         ;3
       BNE    LF9E4                   ;2
       LDA    objectDirections,X      ;4
       AND    #$10                    ;2
       BNE    LF9E4                   ;2
       LDA    gameTimer+1             ;3
       BEQ    LFA39                   ;2
       JMP    LFAB9                   ;3
LFA39: LDA    objectDirections,X      ;4
       AND    #$08                    ;2
       BEQ    LFA49                   ;2
;       LDA    #$58                    ;2
;       STA    kernelPFValues+1        ;3
;       LDA    #$1F                    ;2

       LDA    #$4C                    ;2
       STA    kernelPFValues+1        ;3
       LDA    #$14                    ;2

       STA    kernelPFValues          ;3
       BNE    LFA99                   ;2
LFA49: LDA    objectX,X               ;4
       CMP    #$4C                    ;2
       BNE    LFA63                   ;2
       LDA    mazeIndex+1             ;3
       AND    #$0F                    ;2
       BNE    LFA63                   ;2
       LDA    objectY,X               ;4
       BNE    LFA5C                   ;2
       JMP    LFD32                   ;3
LFA5C: CMP    #$46                    ;2
       BNE    LFA63                   ;2
       JMP    LFD26                   ;3
LFA63:
       LDA    pacmanX                 ;3 copy player location to temps
       STA    kernelPFValues+1        ;3
       LDA    pacmanY                 ;3
       STA    kernelPFValues          ;3

;original
       LDA    currentPlayerVars+18    ;3 energizer active?
       BPL    LFA82                   ;2 branch if not

;changed...allow ghosts to run away seperately
       LDA    objectDirections,X      ;4
       AND    #$04                    ;2 check for blue flag
       BEQ    LFA82                   ;2 branch if not blue

       LDA    pacmanX                 ;3 use inverse locations instead
       CLC                            ;2 (i.e. run away)
       ADC    #$60                    ;2
       EOR    #$FF                    ;2
       STA    kernelPFValues+1        ;3
       LDA    pacmanY                 ;3
       CLC                            ;2
       ADC    #$B1                    ;2
       EOR    #$FF                    ;2 ...not saved??

;added (missed in original??)
       STA    kernelPFValues          ;3


       JMP    LFA99                   ;3
LFA82: DEC    SwapP1,X                ;6
       BNE    LFA99                   ;2
       LDA    currentPlayerVars+17    ;3
       LSR                            ;2
       TAY                            ;2
       LDA    LFE6F,Y                 ;4
       STA    SwapP1,X                ;4
       TXA                            ;2
       LSR                            ;2
       LSR                            ;2
       BCC    LFAB9                   ;2
       INC    SwapP1,X                ;6
       JMP    LFAB9                   ;3
LFA99: LDA    objectX,X               ;4
       CMP    kernelPFValues+1        ;3
       BEQ    LFAAA                   ;2
       BCC    LFAA7                   ;2
       JSR    LFB70                   ;6
       JMP    LFAAA                   ;3
LFAA7: JSR    LFB87                   ;6
LFAAA: LDA    objectY,X               ;4
       CMP    kernelPFValues          ;3
       BCC    LFAB6                   ;2
       JSR    LFB36                   ;6
       JMP    LFAB9                   ;3
LFAB6: JSR    LFB5C                   ;6
LFAB9: LDA    objectDirections,X      ;4
       ROL                            ;2
       BCS    LFAC2                   ;2
       BMI    LFAE0                   ;2
       BPL    LFAD2                   ;2
LFAC2: BPL    LFAEE                   ;2
;       JSR    LFBE0                   ;6
       LDA    mazeIndex+1             ;3
       ASL                            ;2
       EOR    mazeIndex+1             ;3
       ASL                            ;2
       ASL                            ;2
       ROL    mazeIndex+1             ;5
       LDA    mazeIndex+1             ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LFE6A,Y                 ;4
       AND    mazeIndex+1             ;3

       BNE    LFACC                   ;2
       JSR    LFB36                   ;6
LFACC: JSR    LFB19                   ;6
       JSR    LFB36                   ;6
LFAD2:
;       JSR    LFBE0                   ;6
       LDA    mazeIndex+1             ;3
       ASL                            ;2
       EOR    mazeIndex+1             ;3
       ASL                            ;2
       ASL                            ;2
       ROL    mazeIndex+1             ;5
       LDA    mazeIndex+1             ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LFE6A,Y                 ;4
       AND    mazeIndex+1             ;3

       BNE    LFADA                   ;2
       JSR    LFB87                   ;6
LFADA: JSR    LFAFC                   ;6
       JSR    LFB87                   ;6
LFAE0:
;       JSR    LFBE0                   ;6
       LDA    mazeIndex+1             ;3
       ASL                            ;2
       EOR    mazeIndex+1             ;3
       ASL                            ;2
       ASL                            ;2
       ROL    mazeIndex+1             ;5
       LDA    mazeIndex+1             ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LFE6A,Y                 ;4
       AND    mazeIndex+1             ;3

       BNE    LFAE8                   ;2
       JSR    LFB70                   ;6
LFAE8: JSR    LFAFC                   ;6
       JSR    LFB70                   ;6
LFAEE:
;       JSR    LFBE0                   ;6
       LDA    mazeIndex+1             ;3
       ASL                            ;2
       EOR    mazeIndex+1             ;3
       ASL                            ;2
       ASL                            ;2
       ROL    mazeIndex+1             ;5
       LDA    mazeIndex+1             ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LFE6A,Y                 ;4
       AND    mazeIndex+1             ;3


       BNE    LFAF6                   ;2
       JSR    LFB5C                   ;6
LFAF6: JSR    LFB19                   ;6
       JSR    LFB5C                   ;6
LFAFC:
;       JSR    LFBE0                   ;6
       LDA    mazeIndex+1             ;3
       ASL                            ;2
       EOR    mazeIndex+1             ;3
       ASL                            ;2
       ASL                            ;2
       ROL    mazeIndex+1             ;5
       LDA    mazeIndex+1             ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LFE6A,Y                 ;4
       AND    mazeIndex+1             ;3

       JSR    LFB05                   ;6
       PLA                            ;4
       PLA                            ;4
       RTS                            ;6

LFB05: BNE    LFB10                   ;2
       JSR    LFB36                   ;6
       JSR    LFB5C                   ;6
       PLA                            ;4
       PLA                            ;4
       RTS                            ;6

LFB10: JSR    LFB5C                   ;6
       JSR    LFB36                   ;6
       PLA                            ;4
       PLA                            ;4
       RTS                            ;6

LFB19:
;       JSR    LFBE0                   ;6
       LDA    mazeIndex+1             ;3
       ASL                            ;2
       EOR    mazeIndex+1             ;3
       ASL                            ;2
       ASL                            ;2
       ROL    mazeIndex+1             ;5
       LDA    mazeIndex+1             ;3
       AND    #$07                    ;2
       TAY                            ;2
       LDA    LFE6A,Y                 ;4
       AND    mazeIndex+1             ;3

       JSR    LFB22                   ;6
       PLA                            ;4
       PLA                            ;4
       RTS                            ;6

LFB22: BNE    LFB2D                   ;2
       JSR    LFB70                   ;6
       JSR    LFB87                   ;6
       PLA                            ;4
       PLA                            ;4
       RTS                            ;6

LFB2D: JSR    LFB87                   ;6
       JSR    LFB70                   ;6
       PLA                            ;4
       PLA                            ;4
       RTS                            ;6

LFB36: LDA    kernelSection           ;3
       BEQ    LFB5B                   ;2
       LDY    waferIndex              ;3
       LDA    LFE13,Y                 ;4
       ROL                            ;2
       BPL    LFB5B                   ;2
       LDY    #$03                    ;2
LFB44: TXA                            ;2
       BEQ    LFB50                   ;2
       LDA    objectDirections,X      ;4
       AND    #$C0                    ;2
       CMP    LFE67,Y                 ;4
       BEQ    LFB5B                   ;2
LFB50: LDA    objectDirections,X      ;4
       AND    #$3F                    ;2
       ORA    LFE63,Y                 ;4
       STA    objectDirections,X      ;4
       PLA                            ;4
       PLA                            ;4
LFB5B: RTS                            ;6

LFB5C: LDA    kernelSection           ;3
       CMP    #$07                    ;2
       BEQ    LFB5B                   ;2
       LDY    waferIndex              ;3
       LDA    LFE13,Y                 ;4
       ROL                            ;2
       ROL                            ;2
       BPL    LFB5B                   ;2
       LDY    #$02                    ;2
       JMP    LFB44                   ;3
LFB70: LDY    waferIndex              ;3
       LDA    kernelSection           ;3
       CMP    #$03                    ;2
       BNE    LFB7C                   ;2
       CPY    #$3E                    ;2
       BEQ    LFB5B                   ;2
LFB7C: DEY                            ;2
       LDA    LFE13,Y                 ;4
       BMI    LFB5B                   ;2
       LDY    #$01                    ;2
       JMP    LFB44                   ;3
LFB87: LDY    waferIndex              ;3
       LDA    kernelSection           ;3
       CMP    #$03                    ;2
       BNE    LFB93                   ;2
       CPY    #$38                    ;2
       BEQ    LFB5B                   ;2
LFB93: INY                            ;2
       INY                            ;2
       LDA    LFE13,Y                 ;4
       BMI    LFB5B                   ;2
       LDY    #$00                    ;2
       JMP    LFB44                   ;3
LFB9F: LDX    #$13                    ;2
LFBA1: LDA    currentPlayerVars,X     ;4
       LDY    temporaryPlayerVars,X   ;4
       STA    temporaryPlayerVars,X   ;4
       STY    currentPlayerVars,X     ;4
       DEX                            ;2
       BPL    LFBA1                   ;2
       RTS                            ;6




















LFBF4: LDA    #$09                    ;2
       STA    temporaryPlayerVars+19  ;3
       LDA    #$0A                    ;2
       STA    currentPlayerVars+19    ;3
;       LDA    #$03                    ;2
       LDA    #$02                    ;2
       STA    remainingLives          ;3

       LDA    gameSelection           ;3
       SEC                            ;2
       SBC    #$02                    ;2
       AND    #$06                    ;2
       CLC                            ;2
       ADC    #$04                    ;2
       STA    currentPlayerVars+17    ;3

  IF INTEST

LFC0C:
       LDA    #$C0                    ;2
       STA    currentPlayerVars+13    ;3
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2
       NOP                            ;2

  ELSE

LFC0C: LDX    #$0F                    ;2
       LDA    #$FF                    ;2
LFC10: STA    currentPlayerVars,X     ;4
       DEX                            ;2
       BPL    LFC10                   ;2
       LDA    #$7F                    ;2
       STA    currentPlayerVars+6     ;3
       LDA    #$FE                    ;2
       STA    currentPlayerVars+2     ;3
       LDA    #$3C                    ;2
       STA    currentPlayerVars+18    ;3

    IF NO_DOTS_AROUND_BOX
       LDA    #$FC                    ;2
       STA    currentPlayerVars+11    ;3
       STA    currentPlayerVars+2     ;3
       STA    currentPlayerVars+10    ;3

       LDA    #$3F                    ;2
       STA    currentPlayerVars+15    ;3
       STA    currentPlayerVars+6     ;3
       STA    currentPlayerVars+14    ;3
    ENDIF

  ENDIF

LFC21: LDA    gameState               ;3
       ORA    #$80                    ;2
       STA    gameState               ;3
;       LDX    #$3C                    ;2 time (new life)
       LDX    #$20                    ;2 time (new life)

       LDA    playerScoreL0           ;3
       ORA    playerScoreM0           ;3
       ORA    playerScoreH0           ;3
       BNE    LFC28                   ;2
       LDX    #$78                    ;2 time (new life w/tune)


LFC28:
       STX    EnergizerTime           ;3 XXXXXXXXXXXXX

       LDX    #$04                    ;2
       LDA    #$4C                    ;2

;reset sprites
LFC2F: STA    objectX,X               ;4
       LDY    #$1E                    ;2

       STY    objectY,X               ;4

       LDY    #$03                    ;2

       STY    objectDirections,X      ;4 set all moving up
       DEX                            ;2
       BPL    LFC2F                   ;2
;       LDA    #$3C                    ;2
       LDA    #$32                    ;2
       STA    pacmanY                 ;3

;added
;       LDA    #$07                    ;2 reset timer
;       STA    vitaminTimer            ;3
;       LDA    remainingLives          ;3
;       AND    #$F7                    ;2 clear off fruit flag
;       STA    remainingLives          ;3
;       LDA    gameState               ;3
;       AND    #$FD                    ;2
;       STA    gameState               ;3


;       LDA    #$80                    ;2
       LDA    #$40                    ;2
       STA    pacmanDirection         ;3
;       LDA    #$80                    ;2
       RTS                            ;6











LFC45: STX    loopCount               ;3
       LDX    #$00                    ;2
       BIT    playerState             ;3
       BPL    LFC4E                   ;2
       INX                            ;2
LFC4E: SED                            ;2
       CLC                            ;2
       LDA    playerScore,X           ;4
       ADC    LFF06,Y                 ;4
       STA    playerScore,X           ;4
       LDA    playerScoreM0,X         ;4
       ADC    LFF0C,Y                 ;4
       STA    playerScoreM0,X         ;4
       BCC    NoAddPlayer             ;2
       LDA    playerScoreH0,X         ;4
       ADC    #$00                    ;2
       STA    playerScoreH0,X         ;4

       LDA    remainingLives          ;3
       TAX                            ;2
       AND    #$04                    ;2
       BNE    NoAddPlayer             ;2
       INX                            ;2
       TXA                            ;2
       ORA    #$04                    ;2
       STA    remainingLives          ;3


NoAddPlayer:
       CLD                            ;2
       LDX    loopCount               ;3
       RTS                            ;6















LFC7D: LDA    #$00                    ;2
       LDX    #$05                    ;2
LFC81: STA    playerScore,X           ;4
       DEX                            ;2
       BPL    LFC81                   ;2
       STA    remainingLives          ;3
       STA    tempRemainingLives      ;3
       RTS                            ;6

LFC8B: LDA    objectDirections,X      ;4
       AND    #$10                    ;2
       BNE    LFCA9                   ;2
       DEC    objectY,X               ;6
       BNE    LFCFC                   ;2
       LDA    objectDirections,X      ;4
       BMI    LFC9D                   ;2
       LDA    #$00                    ;2
       BEQ    LFC9F                   ;2
LFC9D: LDA    #$5B                    ;2
LFC9F: STA    objectY,X               ;4
       LDA    objectDirections,X      ;4
       ORA    #$10                    ;2
       STA    objectDirections,X      ;4
       BNE    LFCFC                   ;2
LFCA9: LDA    objectDirections,X      ;4
       ROL                            ;2
       BCS    LFD00                   ;2
       BPL    LFCE7                   ;2
       INC    objectY,X               ;6
LFCB2: LDA    objectY,X               ;4
       CMP    #$0B                    ;2
       BNE    LFCCA                   ;2
       LDA    #$00                    ;2
       STA    objectY,X               ;4
       LDA    #$0B                    ;2
       STA.wy ghostOffset,Y           ;5
       LDA    objectDirections,X      ;4
       AND    #$0F                    ;2
       ORA    #$80                    ;2
       STA    objectDirections,X      ;4
       RTS                            ;6

LFCCA: CMP    #$06                    ;2
       BPL    LFCE1                   ;2
       STA.wy ghostIndex,Y            ;5
       TAX                            ;2
       CLC                            ;2
       LDA    LFF0D,X                 ;4
       LDX    LFF19,Y                 ;4
       ADC    ghostPointer,X          ;4
       STA    ghostPointer,X          ;4
       LDA    #$08                    ;2
       BNE    LFCE3                   ;2
LFCE1: LDA    objectY,X               ;4
LFCE3: STA.wy ghostOffset,Y           ;5
       RTS                            ;6

LFCE7: INC    objectY,X               ;6
       LDA    #$5B                    ;2
       CMP    objectY,X               ;4
       BNE    LFCE1                   ;2
       LDA    objectDirections,X      ;4
       AND    #$0F                    ;2
       ORA    #$60                    ;2
       STA    objectDirections,X      ;4
LFCF7: LDA    LFF25,Y                 ;4
       STA    objectY,X               ;4
LFCFC: LDA    #$70                    ;2
       BNE    LFCE3                   ;2
LFD00: BMI    LFD18                   ;2
       DEC    objectY,X               ;6
       LDA    #$51                    ;2
       CMP    objectY,X               ;4
       BNE    LFCE1                   ;2
       LDA    #$46                    ;2
       STA    objectY,X               ;4
       LDA    objectDirections,X      ;4
       AND    #$0F                    ;2
       ORA    #$C0                    ;2
       STA    objectDirections,X      ;4
       BNE    LFCFC                   ;2
LFD18: DEC    objectY,X               ;6
       BPL    LFCB2                   ;2
       LDA    objectDirections,X      ;4
       AND    #$0F                    ;2
       ORA    #$A0                    ;2
       STA    objectDirections,X      ;4
       BNE    LFCF7                   ;2
LFD26: LDA    objectDirections,X      ;4
       AND    #$0F                    ;2
       ORA    #$30                    ;2
       STA    objectDirections,X      ;4
       LDA    #$51                    ;2
       BNE    LFD3C                   ;2
LFD32: LDA    objectDirections,X      ;4
       AND    #$0F                    ;2
       ORA    #$F0                    ;2
       STA    objectDirections,X      ;4
       LDA    #$0B                    ;2
LFD3C: STA    objectY,X               ;4
       RTS                            ;6





START:
       CLD                            ;2
       SEI                            ;2
       LDX    #$FF                    ;2
       TXS                            ;2
       INX                            ;2
       TXA                            ;2
LF007: STA    VSYNC,X                 ;4
       INX                            ;2
       BNE    LF007                   ;2
       JMP    Bootscreen_Bankswitch2  ;3
;Bootscreen_Done:

;wait
bwait: LDX    INTIM                   ;4
       BNE    bwait                   ;2

Bootscreen_Done:

;       LDX    #$00                    ;2
       LDA    #$06                    ;2
       STA    gameSelection           ;3
       LDA    #$07                    ;2
       STA    vitaminTimer            ;3
       DEX                            ;2
       STX    gameTimer+1             ;3
       STX    mazeIndex+1             ;3
       JSR    LFBF4                   ;6
;       LDA    #$CB                    ;2
;       STA    playerScoreL0           ;3
;       LSR                            ;2
;       STA    pacmanY                 ;3
;       LDA    #$ED                    ;2
;       STA    playerScoreM0           ;3
;       LDA    #$AF                    ;2

       LDA    #$BA                    ;2
       STA    playerScoreL0           ;3
       LSR                            ;2
       STA    pacmanY                 ;3
       LDA    #$DC                    ;2
       STA    playerScoreM0           ;3
       LDA    #$FE                    ;2

       STA    playerScoreH0           ;3
       LDX    #$04                    ;2
LF02C: STA    SwapP0,X                ;4
       DEX                            ;2
       BNE    LF02C                   ;2
;       STA    WSYNC                   ;3
;       LDA    #$F0                    ;2
;       STA    HMM0                    ;3 <-missile 1 used for fruit
;       LDA    #$80                    ;2
;       STA    HMBL                    ;3
;       LDX    #$06                    ;2
;LF03D: DEX                            ;2
;       BNE    LF03D                   ;2
;       STA    RESBL                   ;3
;       STA    RESM0                   ;3
;       STA    WSYNC                   ;3
;       STA    HMOVE                   ;3
       STA    WSYNC                   ;3
       STA    HMCLR                   ;3
       STX    gameState               ;3
       STX    remainingLives          ;3
       JMP    LF7D6                   ;3














LFF55: LDA    gameState+1             ;3
       LSR                            ;2
       BCC    LFF67                   ;2
       LDA    #$04                    ;2
       STA    kernelPFValues+1        ;3
       LDA    gameState+2             ;3
       AND    #$1F                    ;2
       TAY                            ;2
       EOR    #$0F                    ;2
       BCS    LFF82                   ;2
LFF67: LSR                            ;2
       BCC    LFF6E                   ;2
LFF6A: LDA    #$0D                    ;2
       BNE    LFF7F                   ;2
LFF6E: LSR                            ;2
       BCC    LFF74                   ;2
       JMP    LFF6A                   ;3
LFF74: LSR                            ;2
       BCC    LFF93                   ;2
       LDY    #$09                    ;2
       STY    kernelPFValues+1        ;3
       LDA    gameState+2             ;3
       BNE    LFF82                   ;2
LFF7F: TAY                            ;2
       STA    kernelPFValues+1        ;3
LFF82: DEC    gameState+2,X           ;6
       BNE    LFF8B                   ;2 ;energizer boop
       LDA    #$00                    ;2
       STA    gameState+1             ;3
       RTS                            ;6



LFF8B: STA    AUDV0                   ;3 save sound effect (global)
       LDA    kernelPFValues+1        ;3
       STA    AUDC0                   ;3
       STY    AUDF0                   ;3
LFF93: RTS                            ;6




LFF94: LDA    #$08                    ;2
       BIT    gameState               ;3
       BVC    LFFA6                   ;2
;death sound
       LDA    EnergizerTime           ;3
       STA    AUDV0                   ;3
       LSR                            ;2
       STA    AUDF0                   ;3
       LDA    #$04                    ;2
       STA    AUDC0                   ;3
       RTS                            ;6

LFFA6: BEQ    LFFD3                   ;2
       LDA    EnergizerTime           ;3
       BNE    LFFB2                   ;2
       LDA    #$F7                    ;2
       AND    gameState               ;3
       STA    gameState               ;3
LFFB2:
;music
       TAX                            ;2
       LDA    playerScoreL0           ;3
       ORA    playerScoreM0           ;3
       ORA    playerScoreH0           ;3
       BNE    LFFD3                   ;2 skip if any points exist
;PlayTune:
       TXA                            ;2
       AND    #$7F                    ;2
       EOR    #$7F                    ;2
       TAX                            ;2
;       BEQ    LFFE7                   ;2
       BNE    LFFE7                   ;2



;LFFE7:
       LDA    frameCount              ;3
       AND    #$03                    ;2
       STA    frameCount              ;3

       LDA    #$07                    ;2
       STA    vitaminTimer            ;3
       LDA    #$F7                    ;2
       AND    gameState               ;3
       STA    gameState               ;3
       RTS                            ;6



LFFE7:

;       LDA    CH0,X                   ;4
;       BEQ    Chn0                    ;2
;       STA    AUDF0                   ;3
;       LDA    #$04                    ;2
;       STA    AUDC0                   ;3
;       ASL                            ;2
;       STA    AUDV0                   ;3
;Chn0:
;       LDA    CH1,X                   ;4
;       BEQ    Chn1                    ;2
;       STA    AUDF1                   ;3
;       LDA    #$04                    ;2
;       STA    AUDC1                   ;3
;       ASL                            ;2
;       STA    AUDV1                   ;3
;Chn1:
;       RTS                            ;6


       LDA    #$04                    ;2
       LDY    CH0,X                   ;4
       BNE    Chn0                    ;2
       LDA    #$00                    ;2
Chn0:
       STY    AUDF0                   ;3
       STA    AUDC0                   ;3
       ASL                            ;2
       STA    AUDV0                   ;3


       LDA    #$04                    ;2
       LDY    CH1,X                   ;4
       BNE    Chn1                    ;2
       LDA    #$00                    ;2
Chn1:
       STY    AUDF1                   ;3
       STA    AUDC1                   ;3
       ASL                            ;2
       STA    AUDV1                   ;3
       RTS                            ;6














LFFD3:

;higher
       LDA    remainingLives          ;3
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       STA    Temp                    ;3



       LDA    frameCount              ;3
       AND    #$1F                    ;3
;       TAY                            ;2
       STA    kernelPFValues+1        ;3

       LSR                            ;2
       LSR                            ;2
       TAY                            ;2

       LDA    SirenData,Y             ;4
       TAY                            ;2
       LDA    currentPlayerVars+18    ;3
       BMI    bluetime                ;2
       LDA    EnergizerTime           ;3
       BNE    LFF9X                   ;2

;higher
       TYA                            ;2
       SEC                            ;2
       SBC    Temp                    ;3
       TAY                            ;2
;siren sound
LFF8C:
       LDA    #$05                    ;3
       STA    AUDV1                   ;3
       STA    AUDC1                   ;3
       STY    AUDF1                   ;3
LFF9X: RTS                            ;6
bluetime:
;       TYA                            ;2


       LDA    EnergizerTime           ;2 energizer time
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       LSR                            ;2
       STA    Temp                    ;3


       LDA    frameCount              ;3
       AND    #$07                    ;3


       ADC    Temp                    ;3
       ORA    #$10                    ;3


       TAY                            ;2

       LDA    ghost0Direction         ;3
       ORA    ghost1Direction         ;3
       ORA    ghost2Direction         ;3
       ORA    ghost3Direction         ;3
       AND    #$08                    ;2
       BEQ    LFF8C                   ;2 branch if any are not eyes

       LDA    frameCount              ;3
       AND    #$0F                    ;3
       ASL                            ;2

;       TYA                            ;2
;       AND    #$07                    ;3
       ADC    Temp                    ;3

       TAY                            ;2
       INY                            ;2

       BPL    LFF8C                   ;2 always branch




SendScore:
       LDX    #4                ;2
SendScoreLoop:
       LDA    playerScore,X     ;4
       STA    WriteToBuffer 	;4
       DEX                      ;2
       DEX                      ;2
       BPL    SendScoreLoop     ;2
       LDA    #3                ; Pac Man game id in Highscore DB
       STA    WriteSendBuffer   ; send request to backend..
       RTS



















































;       ORG $2B9F
;       RORG $FB9F
;       .byte $00


       ORG $2cFC
       RORG $FcFC

ReleaseTime:
;       .byte $23 ; |        | $FE16
;       .byte $61 ; | X   X X| $FE17
;       .byte $18 ; |        | $FE18
;       .byte $35 ; |  X X  X| $FE19

       .byte $53 ; |        | $FE16
       .byte $C1 ; | X   X X| $FE17
       .byte $28 ; |        | $FE18
       .byte $A5 ; |  X X  X| $FE19

       ORG $2d00
       RORG $Fd00



CH1:
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00

       .byte $00

       .byte $00
       .byte $00

       .byte $1F
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $14
       .byte $14
       .byte $14
       .byte $14
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
;       .byte $00

;       .byte $14
       .byte $14
       .byte $14
       .byte $14
       .byte $1E
       .byte $1E
       .byte $1E
       .byte $1E
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $1E
       .byte $1E
       .byte $1E
       .byte $1E
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
;       .byte $00

;       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $14
       .byte $14
       .byte $14
       .byte $14
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $1F
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00

;       .byte $14
       .byte $14
       .byte $14
       .byte $14
       .byte $15
       .byte $15
       .byte $15
       .byte $15
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $12
       .byte $12
       .byte $12
       .byte $12
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $10
       .byte $10
       .byte $10
       .byte $10
       .byte $00
       .byte $00
       .byte $00
       .byte $00
;       .byte $0F
;       .byte $0F
;       .byte $0F
;       .byte $0F

PTGFX: ;(all shared)
       .byte <PT200 ;0108 |    XXX | (0F)
       .byte <PT400 ;0109 |      XX| (4F)
       .byte <PT800 ;010a |      XX| (8F)
       .byte <PT1600 ;010b |    XXXX| (CF)




CH0:
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $00

       .byte $00

       .byte $00
       .byte $00

       .byte $1D
       .byte $1D
       .byte $1D
       .byte $1D
       .byte $0E

;ReleaseTime:
       .byte $0E
       .byte $2E
       .byte $0E
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $17
       .byte $17
       .byte $17
       .byte $17
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $17
       .byte $17
       .byte $17
;       .byte $17

;       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $1C
       .byte $1C
       .byte $1C
       .byte $1C
       .byte $0D
       .byte $0D
       .byte $0D
       .byte $0D
       .byte $12
       .byte $12
       .byte $12
       .byte $12
       .byte $16
       .byte $16
       .byte $16
       .byte $16
       .byte $0D
       .byte $0D
       .byte $0D
       .byte $0D
       .byte $12
       .byte $12
       .byte $12
       .byte $12
       .byte $16
       .byte $16
       .byte $16
;       .byte $16

;       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $1D
       .byte $1D
       .byte $1D
       .byte $1D
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $17
       .byte $17
       .byte $17
       .byte $17
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $17
       .byte $17
       .byte $17
       .byte $17

;       .byte $00
       .byte $00
       .byte $00
       .byte $00
       .byte $17
       .byte $17
       .byte $17
       .byte $17
       .byte $15
       .byte $15
       .byte $15
       .byte $15
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $15
       .byte $15
       .byte $15
       .byte $15
       .byte $13
       .byte $13
       .byte $13
       .byte $13
       .byte $11
       .byte $11
       .byte $11
       .byte $11
       .byte $0E
       .byte $0E
       .byte $0E
       .byte $0E



       ORG $2e00
       RORG $Fe00


       .byte $00

LFFE9: .byte $07 ; |     XXX| $FFE9
       .byte $03 ; |      XX| $FFEA
       .byte $01 ; |       X| $FFEB
;       .byte $00 ; |        | $FFEC
FruitTypeTbl:
       .byte <Fruit0 ;(00) (shared)
       .byte <Fruit1 ;(08)
       .byte <Fruit2
       .byte <Fruit3
       .byte <Fruit4
       .byte <Fruit5
       .byte <Fruit6
       .byte <Fruit7
       .byte <Fruit8
       .byte <Fruit9
       .byte <FruitA
       .byte <FruitB
       .byte <FruitC
       .byte <FruitD
       .byte <FruitE
       .byte <FruitF


;sound duration
LFFED:
       .byte $09 ; |    X  X| $FFED
       .byte $18 ; |   XX   | $FFEE
       .byte $10 ; |   X    | $FFEF
       .byte $30 ; |  XX    | $FFF0

EnergizerTimeTab:
       .byte $A8 ;010b |    XXXX|cherry
       .byte $88 ;010f |     XXX|strawberry
       .byte $68 ;0113 |    XX X|orange
       .byte $68 ;0117 |    X  X|orange
       .byte $64 ;011b |    XX  |apple
       .byte $A4 ;011f |     XXX|apple
       .byte $64 ;011b |    XX  |grapes
       .byte $64 ;011f |    X X |grapes
       .byte $44 ;010b |    XXXX|Galaxian
       .byte $84 ;010f |     XXX|Galaxian
       .byte $44 ;0113 |    XX X|bell
       .byte $42 ;0117 |    X  X|bell
       .byte $21 ;011b |    XX  |key
       .byte $64 ;011f |     XXX|key
       .byte $41 ;011b |    XX  |key
;       .byte $00 ;011f |    X X |key
;POINTS (low)
LFF06: .byte $00 ; |  X     | $FF06 (shared)
       .byte $00 ; | X      | $FF07
       .byte $00 ; |X       | $FF08
       .byte $00 ; | XX     | $FF09
       .byte $10 ; |       X| $FF0A
       .byte $50 ; |     X X| $FF0B
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09
       .byte $00 ; | XX     | $FF09


LFF19: .byte $00 ; |        | $FF19 (shared)
LFF0C: .byte $02 ; |        | $FF0C (shared)
LFF0D: .byte $04 ; |        | $FF0D
       .byte $08 ; |        | $FF0E
       .byte $16 ; |       X| $FF0F
       .byte $00 ; |        | $FF10
       .byte $00 ; |        | $FF11
       .byte $01 ; |       X| $FF12

       .byte $03 ; |        | $FF10
       .byte $05 ; |        | $FF11
       .byte $05 ; |        | $FF10
       .byte $07 ; |        | $FF11
       .byte $07 ; |        | $FF10
       .byte $10 ; |        | $FF11
       .byte $10 ; |        | $FF10
       .byte $20 ; |        | $FF11
       .byte $20 ; |        | $FF10
       .byte $30 ; |        | $FF11
       .byte $30 ; |        | $FF11
       .byte $50 ; |        | $FF11
       .byte $50 ; |        | $FF11
       .byte $50 ; |        | $FF11
       .byte $50 ; |        | $FF11




LFF25: .byte $10 ; |   X    | $FF25
       .byte $40 ; | X      | $FF26
       .byte $08 ; |    X   | $FF27
       .byte $0A ; |    X X | $FF28
       .byte $0C ; |    XX  | $FF29
       .byte $0E ; |    XXX | $FF2A

;death animation
LFDFA: .byte <Death14gfx
       .byte <Death13gfx
       .byte <Death12gfx
       .byte <Death11gfx
       .byte <Death11gfx
       .byte <Death10gfx
       .byte <Death9gfx
       .byte <Death8gfx
       .byte <Death7gfx
       .byte <Death6gfx
       .byte <Death5gfx
       .byte <Death4gfx
       .byte <Death3gfx
       .byte <Death2gfx
       .byte <Death1gfx
       .byte <Death1gfx

LFE13: .byte $80 ; |X       | $FE13
       .byte $20 ; |  X     | $FE14
       .byte $01 ; |       X| $FE15

;ReleaseTime:
       .byte $00 ; |        | $FE16
       .byte $45 ; | X   X X| $FE17
       .byte $00 ; |        | $FE18
       .byte $29 ; |  X X  X| $FE19
       .byte $00 ; |        | $FE1A
       .byte $0D ; |    XX X| $FE1B
       .byte $60 ; | XX     | $FE1C
       .byte $11 ; |   X   X| $FE1D
       .byte $00 ; |        | $FE1E
       .byte $15 ; |   X X X| $FE1F
       .byte $20 ; |  X     | $FE20
       .byte $00 ; |        | $FE21
       .byte $80 ; |X       | $FE22
       .byte $60 ; | XX     | $FE23
       .byte $19 ; |   XX  X| $FE24
       .byte $00 ; |        | $FE25
       .byte $1D ; |   XXX X| $FE26
       .byte $03 ; |      XX| $FE27
       .byte $00 ; |        | $FE28
       .byte $67 ; | XX  XXX| $FE29
       .byte $00 ; |        | $FE2A
       .byte $80 ; |X       | $FE2B
       .byte $20 ; |  X     | $FE2C
       .byte $0B ; |    X XX| $FE2D
       .byte $00 ; |        | $FE2E
       .byte $00 ; |        | $FE2F
       .byte $6F ; | XX XXXX| $FE30
       .byte $00 ; |        | $FE31
       .byte $13 ; |   X  XX| $FE32
       .byte $20 ; |  X     | $FE33
       .byte $17 ; |   X XXX| $FE34
       .byte $40 ; | X      | $FE35
       .byte $1B ; |   XX XX| $FE36
       .byte $00 ; |        | $FE37
       .byte $3F ; |  XXXXXX| $FE38
       .byte $00 ; |        | $FE39
       .byte $80 ; |X       | $FE3A
       .byte $80 ; |X       | $FE3B
       .byte $40 ; | X      | $FE3C
       .byte $01 ; |       X| $FE3D
       .byte $00 ; |        | $FE3E
       .byte $25 ; |  X  X X| $FE3F
       .byte $00 ; |        | $FE40
       .byte $49 ; | X  X  X| $FE41
       .byte $00 ; |        | $FE42
       .byte $80 ; |X       | $FE43
       .byte $60 ; | XX     | $FE44
       .byte $0D ; |    XX X| $FE45
       .byte $00 ; |        | $FE46
       .byte $11 ; |   X   X| $FE47
       .byte $40 ; | X      | $FE48
       .byte $15 ; |   X X X| $FE49


       .byte $00 ; |        | $FE4A
       .byte $79 ; | XXXX  X| $FE4B
       .byte $00 ; |        | $FE4C
       .byte $1D ; |   XXX X| $FE4D
       .byte $00 ; |        | $FE4E
       .byte $00 ; |        | $FE4F
       .byte $03 ; |      XX| $FE50
       .byte $60 ; | XX     | $FE51
       .byte $07 ; |     XXX| $FE52
       .byte $00 ; |        | $FE53
       .byte $4B ; | X  X XX| $FE54
       .byte $00 ; |        | $FE55
       .byte $0F ; |    XXXX| $FE56
       .byte $00 ; |        | $FE57
       .byte $73 ; | XXX  XX| $FE58
       .byte $00 ; |        | $FE59
       .byte $80 ; |X       | $FE5A
       .byte $40 ; | X      | $FE5B
       .byte $17 ; |   X XXX| $FE5C
       .byte $20 ; |  X     | $FE5D
       .byte $1B ; |   XX XX| $FE5E
       .byte $00 ; |        | $FE5F
       .byte $5F ; | X XXXXX| $FE60
       .byte $00 ; |        | $FE61
       .byte $80 ; |X       | $FE62

LFE63: .byte $10 ; |   X    | $FE63
       .byte $50 ; | X X    | $FE64
       .byte $90 ; |X  X    | $FE65
       .byte $D0 ; |XX X    | $FE66

LFE67:
       .byte $40 ; | X      | $FE67
       .byte $00 ; |        | $FE68
       .byte $C0 ; |XX      | $FE69
LFE6A: .byte $80 ; |X       | $FE6A(shared)
       .byte $40 ; | X      | $FE6B
LFE6C: .byte $20 ; |  X     | $FE6C
       .byte $10 ; |   X    | $FE6D
LFE6E: .byte $08 ; |    X   | $FE6E
LFE6F: .byte $04 ; |     X  | $FE6F
       .byte $02 ; |      X | $FE70
       .byte $01 ; |       X| $FE71
       .byte $02 ; |      X | $FE72
       .byte $03 ; |      XX| $FE73
       .byte $05 ; |     X X| $FE74
       .byte $07 ; |     XXX| $FE75
       .byte $08 ; |    X   | $FE76
       .byte $0A ; |    X X | $FE77
       .byte $0C ; |    XX  | $FE78
LFE79: .byte $08 ; |    X   | $FE79
       .byte $0C ; |    XX  | $FE7A
       .byte $03 ; |      XX| $FE7B
       .byte $07 ; |     XXX| $FE7C
       .byte $0B ; |    X XX| $FE7D
       .byte $0F ; |    XXXX| $FE7E
       .byte $02 ; |      X | $FE7F
       .byte $06 ; |     XX | $FE80
       .byte $0A ; |    X X | $FE81
       .byte $0E ; |    XXX | $FE82
       .byte $01 ; |       X| $FE83
       .byte $05 ; |     X X| $FE84
       .byte $09 ; |    X  X| $FE85
       .byte $0D ; |    XX X| $FE86
       .byte $00 ; |        | $FE87
       .byte $04 ; |     X  | $FE88

       .byte $06 ; |     XX | $FF13
       .byte $05 ; |     X X| $FF14
       .byte $04 ; |     X  | $FF15
       .byte $03 ; |      XX| $FF16
       .byte $02 ; |      X | $FF17
;       .byte $01 ; |       X| $FF18
EyeMov:
       .byte $01 ; |   X X  | $FFF5
       .byte $02 ; |   XX   | $FFF6
       .byte $03 ; |   X X  | $FFF7
       .byte $00




;pacman GFX addresses
LFDC2: .byte <RPac1gfx ;(08)
       .byte <RPac2gfx ;(16)
       .byte <RPac3gfx
       .byte <RPac4gfx
       .byte <RPac5gfx
       .byte <RPac4gfx
       .byte <RPac3gfx
       .byte <RPac2gfx ;(16)

SirenData:
       .byte $1B ;010b |    XXXX|
       .byte $1C ;010f |     XXX|
       .byte $1D ;0113 |    XX X|
       .byte $1E ;0117 |    X  X|
       .byte $1F ;011b |    XX  |
       .byte $1E ;011f |     XXX|
       .byte $1D ;011b |    XX  |
       .byte $1C ;011f |    X X |

       ORG $2FF0
       RORG $FFF0
       .byte $00	; WriteToBuffer
       .byte $00	; WriteSendBuffer
       .byte $00	; ReceiveBuffer
       .byte $ff	; ReceiveBufferSize


       ORG $2FF8
       RORG $FFF8

       .word 0,0,START2,0
