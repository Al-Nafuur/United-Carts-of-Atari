; Disassembly of H.E.R.O.
; By Omegamatrix
;
; PAL and PlusROM High Score added
; By Al_Nafuur
;
; hero1.cfg contents:
;
;      ORG D000
;      CODE D000 D009
;      GFX D00A D00B
;      CODE D00C D029
;      GFX D02A D078
;      CODE D079 D9E1
;      GFX D9E2 D9F0
;      CODE D9F1 DA03
;      GFX DA04 DBB1
;      CODE DBB2 DBFB
;      GFX DBFC DBFF
;      CODE DC00 DC35
;      GFX DC36 DC55
;      CODE DC56 DC5D
;      GFX DC5E DDFF
;      CODE DE00 DE71
;      GFX DE72 DFEB
;      CODE DFEC DFFB
;      GFX DFFC DFFF
;
; hero2.cfg contents:
;
;      ORG F000
;      CODE F000 F6D1
;      GFX F6D2 FFEB
;      CODE FFEC FFFB
;      GFX FFFC FFFF

      processor 6502

VSYNC   =  $00
VBLANK  =  $01
WSYNC   =  $02
NUSIZ0  =  $04
NUSIZ1  =  $05
COLUP0  =  $06
COLUP1  =  $07
COLUPF  =  $08
COLUBK  =  $09
CTRLPF  =  $0A
REFP0   =  $0B
REFP1   =  $0C
PF0     =  $0D
PF1     =  $0E
PF2     =  $0F
RESP0   =  $10
RESP1   =  $11
RESBL   =  $14
AUDC0   =  $15
AUDC1   =  $16
AUDF0   =  $17
AUDF1   =  $18
AUDV0   =  $19
AUDV1   =  $1A
GRP0    =  $1B
GRP1    =  $1C
ENAM1   =  $1E
ENABL   =  $1F
HMP0    =  $20
HMP1    =  $21
HMBL    =  $24
VDELP0  =  $25
VDELP1  =  $26
HMOVE   =  $2A
HMCLR   =  $2B
CXCLR   =  $2C

;read TIA base line = $00
CXM1P   =  $01
CXP1FB  =  $03
CXM1FB  =  $05
CXPPMM  =  $07
INPT4   =  $0C

SWCHA   =  $0280
SWCHB   =  $0282
INTIM   =  $0284
TIM64T  =  $0296

BANK_0       = $FFF8
BANK_1       = $FFF9

DO_RANDOM_LEVELS  = 5-1 ; 5th game variation
LEVEL_10          =  9
LEVEL_13          = 12
LEVEL_17          = 16
LEVEL_20          = 19


FIRST_CEILING_PF1     = $C0
FIRST_CEILING_PF2     = $00
CEILING_12_TO_16_PF1  = $FF  ; PF1, PF2 level 12 and up
CEILING_12_TO_16_PF2  = $FF
ROOM_12               = 11


NTSC = 1                     ; 1 = NTSC version, 0 = PAL version
PLUSROM = 1

 IF NTSC
RED               = $40
BROWN             = $42
COLOR01 = $84
COLOR02 = $54
COLOR03 = $24
COLOR04 = $C4
COLOR05 = $1C
COLOR06 = $2A
COLOR07 = $26
COLOR08 = $20
COLOR09 = $C0
COLOR10 = $90
COLOR11 = $C6
COLOR12 = $C8
COLOR13 = $CA
COLOR14 = $4A
COLOR15 = $1E
COLOR16 = $28
COLOR17 = $2C
COLOR18 = $44
COLOR19 = $99
COLOR20 = $45
COLOR21 = $47
COLOR22 = $1D
COLOR23 = $94
COLOR24 = $46
COLOR25 = $AA
 ELSE
RED               = $60
BROWN             = $62
COLOR01 = $B4
COLOR02 = $C4
COLOR03 = $44
COLOR04 = $54
COLOR05 = $2C
COLOR06 = $4A
COLOR07 = $46
COLOR08 = $40
COLOR09 = $50
COLOR10 = $D0
COLOR11 = $56
COLOR12 = $58
COLOR13 = $5A
COLOR14 = $6A
COLOR15 = $2E
COLOR16 = $48
COLOR17 = $4C
COLOR18 = $64
COLOR19 = $D9
COLOR20 = $65
COLOR21 = $67
COLOR22 = $2D
COLOR23 = $D4
COLOR24 = $66
COLOR25 = $5A
 ENDIF

 IF PLUSROM
WriteToBuffer     equ $1ff0
WriteSendBuffer   equ $1ff1
ReceiveBuffer     equ $1ff2
ReceiveBufferSize equ $1ff3
 ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      RIOT RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

       SEG.U RIOT_RAM
       ORG $80

gameSelect         ds 1  ;$80   bit7 (1 = last level passed), bits 0-2 game variation, bits 3-6 unused
frameCounter       ds 1  ;$81
randomizer         ds 1  ;$82
ram_83             ds 1  ; x3
ram_84             ds 1  ; x8
ram_85             ds 1  ; x9
ram_86             ds 1  ; x1
ram_87             ds 1  ; x4
ram_88             ds 1  ; x1
ram_89             ds 1  ; x3
ram_8A             ds 1  ; x1
ram_8B             ds 1  ; x2
ram_8C             ds 1  ; x1
ram_8D             ds 2  ; x2
ram_8F             ds 2  ; x2
ram_91             ds 1  ; x13
ram_92             ds 1  ; x5
ram_93             ds 1  ; x2
ram_94             ds 1  ; x1
ram_95             ds 1  ; x15
ram_96             ds 1  ; x2
ram_97             ds 1  ; x5
ram_98             ds 1  ; x1
ram_99             ds 1  ; x2
ram_9A             ds 1  ; x1

hPosHERO           ds 1  ; x27  $9B
roomNum            ds 1  ; x30  $9C
ram_9D             ds 1  ; x2
ram_9E             ds 1  ; x5
ram_9F             ds 1  ; x22
ram_A0             ds 1  ; x15
ram_A1             ds 1  ; x8
ram_A2             ds 1  ; x1
ram_A3             ds 1  ; x1
ram_A4             ds 1  ; x11  ; lights

ram_A5             ds 1  ; x9   ; LF700
ram_A6             ds 1  ; x1   ; LF800
ram_A7             ds 1  ; x1   ; LF900
ram_A8             ds 1  ; x17
ram_A9             ds 1  ; x4
ram_AA             ds 1  ; x1

ram_AB             ds 1  ; x9
ram_AC             ds 1  ; x12
ram_AD             ds 1  ; x22
ram_AE             ds 1  ; x4
ram_AF             ds 1  ; x6
ram_B0             ds 1  ; x10
ram_B1             ds 1  ; x5
ram_B2             ds 1  ; x5
ram_B3             ds 1  ; x5
ram_B4             ds 1  ; x7
ram_B5             ds 1  ; x7
ram_B6             ds 1  ; x16
scoreBCD           ds 3  ; x13  $B7-$B9
ram_BA             ds 1  ; x10
ram_BB             ds 1  ; x55
ram_BC             ds 1  ; x13
ram_BD             ds 1  ; x11
ram_BE             ds 1  ; x3
ram_BF             ds 1  ; x5   PF1 bottom
ram_C0             ds 1  ; x2   PF1 middle
ram_C1             ds 1  ; x2   PF1 top
ram_C2             ds 1  ; x5   PF2 bottom
ram_C3             ds 1  ; x3   PF2 middle
ram_C4             ds 1  ; x2   PF2 top
sectionColors      ds 3  ;$C5-$C7    $C5 top, $C6 middle, $C7 bottom, and top line stripe
ram_C8             ds 1  ; x2
ram_C9             ds 1  ; x1
ram_CA             ds 1  ; x1
ram_CB             ds 2  ; x7
ram_CD             ds 1  ; x1
ram_CE             ds 2  ; x4
ram_D0             ds 1  ; x1
ram_D1             ds 1  ; x6
ram_D2             ds 2  ; x1
ram_D4             ds 1  ; x1
ram_D5             ds 2  ; x3
ram_D7             ds 1  ; x2
ram_D8             ds 1  ; x8
ram_D9             ds 2  ; x3
ram_DB             ds 1  ; x4
ram_DC             ds 2  ; x2
ram_DE             ds 1  ; x8
ram_DF             ds 1  ; x5
ram_E0             ds 1  ; x2
ram_E1             ds 1  ; x6
ram_E2             ds 1  ; x3
ram_E3             ds 3  ; x1
ram_E6             ds 1  ; x14
ram_E7             ds 1  ; x5
ram_E8             ds 1  ; x4
ram_E9             ds 1  ; x6
ram_EA             ds 1  ; x8
ram_EB             ds 1  ; x2
ram_EC             ds 1  ; x4
ram_ED             ds 5  ; x3
ram_F2             ds 1  ; x12
ram_F3             ds 1  ; x10
ram_F4             ds 1  ; x6
levelNum           ds 1  ; x26  $F5
ram_F6             ds 1  ; x5
ram_F7             ds 1  ; x12
ram_F8             ds 2  ; x2
ram_FA             ds 1  ; x4
ram_FB             ds 1  ; x4
ram_FC             ds 1  ; x3
ram_FD             ds 3  ; x6


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      BANK 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

       SEG CODE
       ORG $0000
      RORG $D000

START_0:
    sei                          ;
    bit    BANK_1                ;     bankswitch to clear loop
 IF PLUSROM
markGameOver
    lda gameSelect               ; mark gameSelect that game is over
    ora #16                      ; Set bit 4
    sta gameSelect               ; 
    dey                          ; 2
    rts

      org $000C
      RORG $D00C
 ELSE
    ldx    #$FF                  ;     is this ever reached?
    txs                          ; 
    jsr    $F000                 ; 

    .byte $00 ; |        | $D00A   free bytes
    .byte $00 ; |        | $D00B
 ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HorizPositioning SUBROUTINE ;x3
    cmp    #0                    ; 2
    bne    LD012                 ; 2³
    lda    #1                    ; 2
LD012:
    sec                          ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    bcs    LD017                 ; 3   always branch, waste 3 cycles!
LD017:
    sbc    #15                   ; 2
    bcs    LD017                 ; 2³
    eor    #$0F                  ; 2
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    adc    #$80                  ; 2
    sta    RESP0,X               ; 4
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMP0,X                ; 4
Waste12Cycles SUBROUTINE ;x3
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LD02A:
    .byte (<BlankDigit <<1) | (<One >>3)   ;  1   level numbers
    .byte (<BlankDigit <<1) | (<Two >>3)   ;  2
    .byte (<BlankDigit <<1) | (<Three >>3) ;  3
    .byte (<BlankDigit <<1) | (<Four >>3)  ;  4
    .byte (<BlankDigit <<1) | (<Five >>3)  ;  5
    .byte (<BlankDigit <<1) | (<Six >>3)   ;  6
    .byte (<BlankDigit <<1) | (<Seven >>3) ;  7
    .byte (<BlankDigit <<1) | (<Eight >>3) ;  8
    .byte (<BlankDigit <<1) | (<Nine >>3)  ;  9
    .byte        (<One <<1) | (<Zero >>3)  ; 10
    .byte        (<One <<1) | (<One >>3)   ; 11
    .byte        (<One <<1) | (<Two >>3)   ; 12
    .byte        (<One <<1) | (<Three >>3) ; 13
    .byte        (<One <<1) | (<Four >>3)  ; 14
    .byte        (<One <<1) | (<Five >>3)  ; 15
    .byte        (<One <<1) | (<Six >>3)   ; 16
    .byte        (<One <<1) | (<Seven >>3) ; 17
    .byte        (<One <<1) | (<Eight >>3) ; 18
    .byte        (<One <<1) | (<Nine >>3)  ; 19   is $20 shared below??


;           1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20
LD03D:
    .byte $20,$40,$60,$80,$90,$00,$20,$60,$00,$40,$80,$20,$60,$00,$20,$40,$00,$40,$00,$99  ; added to score as power left is tallied
LD051:
    .byte $00,$00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06,$09  ; added to score at end of level
LD065:
    .byte $01,$03,$05,$07,$07,$09,$0B,$0D,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F  ; last room in level (that surivior is in)

LD079:
    lda    ram_B5                ; 3
    bmi    LD0B0                 ; 2³
    lda    ram_BA                ; 3
    bne    LD087                 ; 2³
    lda    ram_AF                ; 3
    bne    LD0B0                 ; 2³
    beq    LD099                 ; 3   always branch

LD087:
    lda    ram_B3                ; 3
    bne    LD0B0                 ; 2³
    lda    scoreBCD              ; 3
    cmp    #$AA                  ; 2
    beq    LD0B0                 ; 2³
    lda    ram_B6                ; 3
    and    #$1F                  ; 2
    cmp    #$14                  ; 2
    bcc    LD0B0                 ; 2³
LD099:
    lda    gameSelect            ; 3
    and    #$7F                  ; 2
    cmp    #DO_RANDOM_LEVELS     ; 2
    beq    LD0B0                 ; 2³
    lda    #$CD                  ; 2
    sta    ram_BB                ; 3
    lda    #$EF                  ; 2
    sta    ram_BC                ; 3
    ldx    levelNum              ; 3
    lda    LD02A,X               ; 4
    sta    ram_BD                ; 3
LD0B0:
    ldx    #$02                  ; 2
LD0B2:
    txa                          ; 2
    asl                          ; 2
    asl                          ; 2
    tay                          ; 2
    lda    ram_BB,X              ; 4
    and    #$F0                  ; 2
    lsr                          ; 2
    sta.wy ram_85,Y              ; 5
    lda    ram_BB,X              ; 4
    and    #$0F                  ; 2
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    sta.wy ram_87,Y              ; 5
    dex                          ; 2
    bpl    LD0B2                 ; 2³
    lda    ram_BB                ; 3
    cmp    #$CD                  ; 2
    bne    LD0DD                 ; 2³
    bit    gameSelect            ; 3   display "PRO"?
    bpl    LD0DD                 ; 2³  - no
    lda    #<ProGfxOne           ; 2   - yes
    sta    ram_8D                ; 3
    lda    #<ProGfxTwo           ; 2
    sta    ram_8F                ; 3
LD0DD:
    inx                          ; 2
    ldy    #$50                  ; 2
LD0E0:
    lda    ram_85,X              ; 4
    bne    LD0EC                 ; 2³
    sty    ram_85,X              ; 4
    inx                          ; 2
    inx                          ; 2
    cpx    #$0A                  ; 2
    bcc    LD0E0                 ; 2³
LD0EC:
    ldx    #$0B                  ; 2
    lda    #$DF                  ; 2
LD0F0:
    sta    ram_85,X              ; 4
    dex                          ; 2
    dex                          ; 2
    bpl    LD0F0                 ; 2³
    bmi    LD0FB                 ; 3   always branch

LD0F8:
    jmp    LD17A                 ; 3

LD0FB:
    lda    INTIM                 ; 4
    bne    LD0FB                 ; 2³+1
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    bit    ram_B4                ; 3
    bpl    LD10A                 ; 2³
    lda    #$02                  ; 2
LD10A:
    sta    VBLANK                ; 3
    ldx    #$02                  ; 2
    stx    ram_E6                ; 3
    dex                          ; 2
    lda    hPosHERO              ; 3
    sta    HMCLR                 ; 3
    jsr    HorizPositioning      ; 6
    ldx    #4                    ; 2
    lda    ram_A0                ; 3
    jsr    HorizPositioning      ; 6
    sta    WSYNC                 ; 3
;--------------------------------------------------------------------------------------------------
;Start dawing screen
;--------------------------------------------------------------------------------------------------
    sta    HMOVE                 ; 3
    lda    ram_E1                ; 3
    sta    COLUBK                ; 3
    lda    #$FF                  ; 2
    sta    ram_BD                ; 3
    dex                          ; 2   X=3

.loopDrawCeilingRipple:
    lda    ColHighlightTab,X     ; 4   make the colors brighter each line
    ora    ram_A4                ; 3
    sta    HMCLR                 ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    sta    COLUPF                ; 3
    lda    CeilingRippleGfx1,X   ; 4
    sta    PF0                   ; 3
    lda    CeilingRippleGfx2,X   ; 4
    and    ram_C1                ; 3
    sta    PF1                   ; 3
    lda    CeilingRippleGfx2,X   ; 4
    and    ram_C4                ; 3
    sta    PF2                   ; 3
    dex                          ; 2
    bpl    .loopDrawCeilingRipple; 2³

    stx    ENABL                 ; 3   the ball is used to make the breakable small walls
    inx                          ; 2   X=0
    stx    NUSIZ0                ; 3
    lda    #$61                  ; 2   could use INX, STX
    sta    VDELP0                ; 3
    lda    ram_B0                ; 3
    sta    REFP1                 ; 3
    ldy    #$74                  ; 2
    lda    (ram_95),Y            ; 5
    ldx    sectionColors+2       ; 3   top stripe color!
    nop                          ; 2
    sta    CXCLR                 ; 3
    nop                          ; 2
    stx    COLUPF                ; 3   @76  shows up on the line before, fix later...
;---------------------------------------
    sta    HMOVE                 ; 3
    jmp    LD172                 ; 3

LD16D:
    sta.w  GRP1                  ; 4
    beq    LD1AC                 ; 3   always branch

LD172:
    sta    COLUP1                ; 3
    and    #$01                  ; 2   time to draw enemy?
    beq    LD0F8                 ; 2³  - no
    lda    (ram_91),Y            ; 5
LD17A:
    sta    GRP1                  ; 3
    ldx    ram_E6                ; 3
    lda    ram_A1,X              ; 4
    sta    ram_BC                ; 3
    lda    CXM1FB                ; 3
    ora    ram_F4                ; 3
    sta    ram_F4                ; 3
    lda    ram_CE,X              ; 4
    sta    ram_97                ; 3
    lda    ram_CB,X              ; 4
    sta    ram_93                ; 3
    dey                          ; 2
    lda    ram_BF,X              ; 4
    tax                          ; 2
    lda    (ram_95),Y            ; 5
    stx    PF1                   ; 3
    ldx    ram_BD                ; 3
    sta    COLUP1                ; 3   @76
;---------------------------------------
    sta    HMOVE                 ; 3
    stx    PF0                   ; 3
    ldx    CXP1FB                ; 3
    stx    CXCLR                 ; 3
    and    #$01                  ; 2
    beq    LD16D                 ; 2³
    lda    (ram_91),Y            ; 5
    sta    GRP1                  ; 3
LD1AC:
    stx    ram_BB                ; 3
    ldx    ram_E6                ; 3
    lda    ram_C2,X              ; 4
    sta    PF2                   ; 3
    lda    ram_C8,X              ; 4
    sta    CTRLPF                ; 3
    lda    ram_BB                ; 3
    sta    ram_E3,X              ; 4
    dey                          ; 2
    lda    sectionColors,X       ; 4
    tax                          ; 2
    lda    (ram_95),Y            ; 5
    lda    (ram_95),Y            ; 5
    nop                          ; 2
    sta    COLUP1                ; 3   @74
;---------------------------------------
    sta    HMOVE                 ; 3   early!!
    stx    COLUPF                ; 3
    sta    ENAM1                 ; 3
    and    #$01                  ; 2
    bne    LD1D5                 ; 2³
    sta    ENAM1                 ; 3
    beq    LD1D7                 ; 3   always branch

LD1D5:
    lda    (ram_91),Y            ; 5
LD1D7:
    sta    GRP1                  ; 3
    dey                          ; 2
    ldx    ram_E6                ; 3
    lda    ram_D1,X              ; 4
    sta    ram_BB                ; 3
    and    #$0F                  ; 2
    tax                          ; 2
    lda    (ram_95),Y            ; 5
    jsr    Waste12Cycles         ; 12
    jsr    Waste12Cycles         ; 12
    dec    ram_E6                ; 5
    sta.w  COLUP1                ; 4   @74
;---------------------------------------
    sta    HMOVE                 ; 3   early!!
    sta    ENAM1                 ; 3
    and    #$01                  ; 2
    bne    LD1FC                 ; 2³
    sta    ENAM1                 ; 3
    beq    LD1FE                 ; 3   always branch

LD1FC:
    lda    (ram_91),Y            ; 5
LD1FE:
    sta.w  GRP1                  ; 4
    lda    ram_BB                ; 3
LD203:
    dex                          ; 2   top level enemy??
    bne    LD203                 ; 2³
    sta    RESP0                 ; 3
    sta    HMP0                  ; 3
    dey                          ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    (ram_95),Y            ; 5
    sta    COLUP1                ; 3
    sta    ENAM1                 ; 3
    lsr                          ; 2
    bcc    LD234                 ; 2³
    lda    (ram_91),Y            ; 5
    sta    GRP1                  ; 3
    nop                          ; 2
LD21D:
    ldx    #$12                  ; 2
    sta    HMCLR                 ; 3
LD221:
    dey                          ; 2
    sty    ram_BB                ; 3   scanline count??
    txa                          ; 2
    sec                          ; 2
    sbc    ram_BC                ; 3   manVpos??
    tay                          ; 2
    cmp    #$0D                  ; 2   HEIGHT_OF_MAN+1??
    bcc    LD23A                 ; 2³
    ldy    #$00                  ; 2
    nop                          ; 2
    nop                          ; 2
    jmp    LD23E                 ; 3

LD234:
    stx    ENAM1                 ; 3
    stx    GRP1                  ; 3
    bcc    LD21D                 ; 3   always branch

LD23A:
    lda    (ram_93),Y            ; 5
    sta    GRP0                  ; 3
LD23E:
    lda    (ram_97),Y            ; 5
    ldy    ram_BB                ; 3
    sta    COLUP0                ; 3
    lda    (ram_95),Y            ; 5
;---------------------------------------
    sta    HMOVE                 ; 3
    sta    COLUP1                ; 3
    lsr                          ; 2
    bcs    LD255                 ; 2³
    lda    #$00                  ; 2
    sta    ENAM1                 ; 3
    sta    GRP1                  ; 3
    beq    LD25A                 ; 3   always branch

LD255:
    asl                          ; 2
    sta    ENAM1                 ; 3
    lda    (ram_91),Y            ; 5
LD25A:
    sta.w  GRP1                  ; 4
    sta    GRP1                  ; 3
    dex                          ; 2
    bpl    LD221                 ; 2³
    dey                          ; 2
    lda    CXPPMM                ; 3
    ldx    ram_E6                ; 3
    sta    ram_D2,X              ; 4
    lda    ram_D9,X              ; 4
    sta    ram_99                ; 3
    lda    ram_DC,X              ; 4
    sta    ram_97                ; 3
    lda    ram_D5,X              ; 4
    and    #$0F                  ; 2
    tax                          ; 2
    lda    (ram_95),Y            ; 5
    sta    COLUP1                ; 3
    lsr                          ; 2
    sta    HMOVE                 ; 3
    bcs    LD287                 ; 2³
    lda    #$00                  ; 2
    sta    ENAM1                 ; 3
    sta    GRP1                  ; 3
    beq    LD28C                 ; 3   always branch

LD287:
    asl                          ; 2
    sta    ENAM1                 ; 3
    lda    (ram_91),Y            ; 5
LD28C:
    sta    GRP1                  ; 3
    dey                          ; 2
LD28F:
    dex                          ; 2
    bne    LD28F                 ; 2³
    sta    RESP0                 ; 3
    lda    (ram_95),Y            ; 5
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    sta    COLUP1                ; 3
    sta    ENAM1                 ; 3
    and    #$01                  ; 2
    bne    LD2A6                 ; 2³
    sta    ENAM1                 ; 3
    beq    LD2A8                 ; 3   always branch

LD2A6:
    lda    (ram_91),Y            ; 5
LD2A8:
    sta    GRP1                  ; 3
    ldx    ram_E6                ; 3
    lda    ram_D5,X              ; 4
    sta    HMP0                  ; 3
    lda    CXM1P                 ; 3
    sta    ram_D5,X              ; 4
    ldx    #$0C                  ; 2
    dey                          ; 2
    sty    ram_BB                ; 3
    ldy    #$0C                  ; 2
    jsr    Waste12Cycles         ; 12
LD2BE:
    lda    (ram_97),Y            ; 5
    ldy    ram_BB                ; 3
    sta    COLUP0                ; 3
    lda    (ram_95),Y            ; 5
    sta    HMOVE                 ; 3
    sta    COLUP1                ; 3
    sta    ENAM1                 ; 3
    and    #$01                  ; 2
    bne    LD2D4                 ; 2³
    sta    ENAM1                 ; 3
    beq    LD2D6                 ; 3   always branch

LD2D4:
    lda    (ram_91),Y            ; 5
LD2D6:
    sta    GRP1                  ; 3
    nop                          ; 2
    dey                          ; 2
    bmi    LD30C                 ; 2³+1
    sty    ram_BB                ; 3
    txa                          ; 2
    tay                          ; 2
    dex                          ; 2
    bmi    LD2EF                 ; 2³
    sta    HMCLR                 ; 3
    lda    (ram_99),Y            ; 5
    sta    GRP0                  ; 3
    lda    (ram_97),Y            ; 5
    nop                          ; 2
    jmp    LD2BE                 ; 3

LD2EF:
    ldx    ram_E6                ; 3
    lda    ram_BE                ; 3
    ora    LD9E2,X               ; 4
    sta    ram_BD                ; 3
    lda    #$00                  ; 2
    sta    GRP0                  ; 3
    ldy    ram_BB                ; 3
    ldx    ram_A4                ; 3
    lda    (ram_95),Y            ; 5
    stx    ENAM1                 ; 3
    stx.w  COLUPF                ; 4
    sta    HMOVE                 ; 3
    jmp    LD172                 ; 3

LD30C:
    ldx    levelNum              ; 3
    lda    LD065,X               ; 4
    cmp    roomNum               ; 3
    beq    LD31D                 ; 2³
    lda    ram_E1                ; 3
    ldx    roomNum               ; 3
    cpx    #$0A                  ; 2
    bcc    LD325                 ; 2³
LD31D:
    lda    levelNum              ; 3
    and    #$03                  ; 2
    tax                          ; 2
    lda    LDD01,X               ; 4
LD325:
    stx    WSYNC                 ; 3
;---------------------------------------
    stx    HMOVE                 ; 3
    sta    COLUBK                ; 3
    ldy    #$00                  ; 2
    sty    ENAM1                 ; 3
    sty    ENABL                 ; 3
    sty    VDELP0                ; 3
    sty    GRP1                  ; 3
    lda    CXP1FB                ; 3
    sta    ram_E2                ; 3
    lda    CXM1FB                ; 3
    ora    ram_F4                ; 3
    sta    ram_F4                ; 3
    ldx    ram_FB                ; 3
    lda    LDA1D,X               ; 4
    sta    ram_BB                ; 3
    lda    #>LDC36               ; 2
    sta    ram_BC                ; 3
    ldx    #$00                  ; 2
    cmp    (ram_BB,X)            ; 6   waste time
    lda    ram_BB                ; 3
    nop                          ; 2
LD351:
    lda    LDD0A,Y               ; 4   water highlights
    ora    ram_A4                ; 3
    stx    GRP0                  ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    sta    COLUPF                ; 3
    lda    (ram_BB),Y            ; 5
    sta    PF0                   ; 3
    lda    (ram_BB),Y            ; 5
    and    ram_BF                ; 3
    sta    PF1                   ; 3
    lda    (ram_BB),Y            ; 5
    and    ram_C2                ; 3
    sta    PF2                   ; 3
    iny                          ; 2
    cpy    #$04                  ; 2
    bcc    LD351                 ; 2³
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    sty    COLUPF                ; 3
    ldy    #$FF                  ; 2
    sty    PF0                   ; 3
    sty    PF1                   ; 3
    sty    PF2                   ; 3
    lda    #BROWN                ; 2
    sta    COLUBK                ; 3
    lda    #$0C                  ; 2
    ldx    #$30                  ; 2
    sta    RESP0                 ; 3
    sta    RESP1                 ; 3
    stx    CTRLPF                ; 3
    stx    VDELP0                ; 3
    stx    NUSIZ1                ; 3
    stx    REFP1                 ; 3
    stx    REFP0                 ; 3
    inx                          ; 2
    stx    NUSIZ0                ; 3
    sta    COLUP0                ; 3
    sta    COLUP1                ; 3
    sta    VDELP1                ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    ram_AB                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tax                          ; 2
    lda    LDC6B,X               ; 4
    sta    ram_BD                ; 3
    lda    LDC76,X               ; 4
    sta    ram_BC                ; 3
    lda    LDC69,X               ; 4
    sta    ram_BB                ; 3
    sty    ENABL                 ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    ram_D7                ; 3
    and    #$0F                  ; 2
    tax                          ; 2
    lda    ram_D7                ; 3
LD3C6:
    dex                          ; 2
    bpl    LD3C6                 ; 2³
    sta.w  RESBL                 ; 4
    sta    HMBL                  ; 3
    lda    #$10                  ; 2
    sta    HMP1                  ; 3
    ldx    #$04                  ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
LD3D6:
    sta    HMOVE                 ; 3
    sty    PF1                   ; 3
    lda    PowerOne,X            ; 4
    sta    GRP0                  ; 3
    lda    PowerTwo,X            ; 4
    sta    GRP1                  ; 3
    lda    PowerThree,X          ; 4
    ldy    ram_BD                ; 3
    sty    PF2                   ; 3
    sta    GRP0                  ; 3
    lda    #COLOR05              ; 2
    sta.w  COLUPF                ; 4
    lda    ram_BB                ; 3
    sta    PF0                   ; 3
    lda    ram_BC                ; 3
    sta    PF1                   ; 3
    ldy    #$FF                  ; 2
    sty    PF2                   ; 3
    sty    PF0                   ; 3
    lda    #$04                  ; 2
    sta.w  COLUPF                ; 4
    sta    HMCLR                 ; 3
    dex                          ; 2
    nop                          ; 2  @72
    bpl    LD3D6                 ; 2³+1
    nop                          ; 2
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    #$04                  ; 2
    sta    COLUBK                ; 3
    inx                          ; 2
    stx    GRP0                  ; 3
    stx    GRP1                  ; 3
    stx    GRP0                  ; 3
    ldy    #$0C                  ; 2
    lda    ram_B3                ; 3
    eor    #$07                  ; 2
    tax                          ; 2
    lda    #$83                  ; 2
    sta    HMP0                  ; 3
    sta.w  RESP0                 ; 4
    sta    RESP1                 ; 3
    sta    NUSIZ0                ; 3
    sta    NUSIZ1                ; 3
    lda    #$90                  ; 2
    sta    ENABL                 ; 3
    sta    HMP1                  ; 3
    lda    #$34                  ; 2
    sta    CTRLPF                ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    #>LivesGfx            ; 2  #$DD
    sta    ram_92                ; 3
    sta    ram_96                ; 3
    lda    #<LivesGfx            ; 2
    sta    ram_91                ; 3
    lda    #<LivesColTab         ; 2
    sta    ram_95                ; 3
    sta    HMCLR                 ; 3
    jsr    DrawLivesDynamite     ; 6
    lda    #<DynamiteB+1         ; 2
    sta    ram_91                ; 3
    lda    #<DynamiteDispColTab  ; 2
    sta    ram_95                ; 3
    lda    #>DynamiteB           ; 2  #$DA
    sta    ram_92                ; 3
    ldx    ram_B2                ; 3
    inx                          ; 2
    txa                          ; 2
    eor    #$07                  ; 2
    tax                          ; 2
    ldy    #10                   ; 2
    jsr    DrawLivesDynamite     ; 6
    lda    #$0C                  ; 2
    ldx    ram_85                ; 3
    cpx    #$60                  ; 2
    bne    LD470                 ; 2³
    lda    #COLOR05              ; 2
LD470:
    sta    COLUP1                ; 3
    sta    COLUP0                ; 3
    jsr    DrawScore             ; 6
    lda    #$0C                  ; 2
    sta    COLUP1                ; 3
    sta    COLUP0                ; 3
    sta    HMCLR                 ; 3
    ldy    #$07                  ; 2
    lda    ram_B6                ; 3
    and    #$1F                  ; 2
    cmp    #$14                  ; 2
    bcs    LD492                 ; 2³
    ldy    #$00                  ; 2
    cmp    #$0C                  ; 2
    bcc    LD492                 ; 2³
    sbc    #$0C                  ; 2
    tay                          ; 2
LD492:
    tya                          ; 2
    eor    #$07                  ; 2
    sta    ram_BD                ; 3
    lda    #<CopyrightSix        ; 2
    ldx    #$08                  ; 2
    sec                          ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
LD4A0:
    sta    ram_87,X              ; 4
    sbc    #$08                  ; 2
    sta    ram_85,X              ; 4
    sbc    #$08                  ; 2
    dex                          ; 2
    dex                          ; 2
    dex                          ; 2
    dex                          ; 2
    bpl    LD4A0                 ; 2³
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    #$00                  ; 2
    sta    COLUBK                ; 3
    sta    COLUPF                ; 3
    lda    #$30                  ; 2
    sta    CTRLPF                ; 3
    tya                          ; 2
    jsr    DrawLogo              ; 6
    lda    #$1C                  ; 2
    sta    PF2                   ; 3
    lda    #$11                  ; 2
    sta    NUSIZ1                ; 3
    ldy    #$07                  ; 2
    sty    ENABL                 ; 3
    sta    HMCLR                 ; 3
    sta    HMBL                  ; 3
LD4D0:
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    ldx    LogoFive,Y            ; 4
    lda    LogoOne,Y             ; 4
    sta    GRP0                  ; 3
    lda    LDDEC,Y               ; 4
    sta    COLUPF                ; 3
    lda    LogoTwo,Y             ; 4
    sta    GRP1                  ; 3
    lda    LogoThree,Y           ; 4
    sta    GRP0                  ; 3
    nop                          ; 2
    nop                          ; 2
    lda    LogoFour,Y            ; 4
    dey                          ; 2
    sta    GRP1                  ; 3
    stx    GRP0                  ; 3
    sta    GRP1                  ; 3
    lda    #$00                  ; 2
    sta    COLUPF                ; 3
    dec    ram_BD                ; 5
    bpl    LD4D0                 ; 2³
 IF NTSC
    lda    #$1D                  ; 2
 ELSE
    lda    #$3B                  ; 2
 ENDIF
    ldx    #$82                  ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    TIM64T                ; 4
    stx    VBLANK                ; 3
    lda    #$00                  ; 2
    sta    VDELP0                ; 3
    sta    VDELP1                ; 3
    sta    GRP0                  ; 3
    sta    GRP1                  ; 3
    sta    GRP0                  ; 3
    sta    PF2                   ; 3
    sta    ENABL                 ; 3
    ldx    #$02                  ; 2
    bit    ram_AC                ; 3
    bvc    LD561                 ; 2³
    lda    ram_9F                ; 3
    cmp    #$17                  ; 2
    bne    LD561                 ; 2³
    beq    LD546                 ; 3   always branch

LD528:
    lda    ram_AD                ; 3
    ora    ram_F2                ; 3
    ora    ram_F7                ; 3
    ora    ram_F8                ; 3
    bne    LD561                 ; 2³
    lda    #$03                  ; 2
    ldy    levelNum              ; 3
    cpy    #$09                  ; 2
    bcc    LD542                 ; 2³
    lda    #$01                  ; 2
    cpy    #$11                  ; 2
    bcc    LD542                 ; 2³
    lda    #$00                  ; 2
LD542:
    and    ram_F6                ; 3
    bne    LD561                 ; 2³
LD546:
    lda    ram_EA,X              ; 4
    bpl    LD559                 ; 2³
    inc    ram_EA,X              ; 6
    lda    LDC5E,X               ; 4
    cmp    ram_EA,X              ; 4
    bcs    LD561                 ; 2³
    and    #$7F                  ; 2
    sta    ram_EA,X              ; 4
    bpl    LD561                 ; 3   always branch

LD559:
    dec    ram_EA,X              ; 6
    bpl    LD561                 ; 2³
    lda    #$80                  ; 2
    sta    ram_EA,X              ; 4
LD561:
    dex                          ; 2
    bpl    LD528                 ; 2³
    ldx    #$03                  ; 2
    ldy    #$00                  ; 2
    lda    ram_F2                ; 3
    bne    LD586                 ; 2³
    ldx    ram_E8                ; 3
    ldy    ram_E7                ; 3
    lda    frameCounter          ; 3
    lsr                          ; 2
    lsr                          ; 2
    bcc    LD57B                 ; 2³
    dey                          ; 2
    bpl    LD57B                 ; 2³
    ldy    #$02                  ; 2
LD57B:
    lda    frameCounter          ; 3
    and    #$03                  ; 2
    bne    LD586
    dex                          ; 2
    bpl    LD586                 ; 2³
    ldx    #$04                  ; 2
LD586:
    stx    ram_E8                ; 3
    sty    ram_E7                ; 3
    nop                          ; 2
    nop                          ; 2
    ldx    #0                    ; 2
    ldy    #0                    ; 2
    lda    ram_B6                ; 3
    beq    LD59F                 ; 2³
    stx    AUDV0                 ; 3
    stx    AUDC0                 ; 3
    stx    AUDF0                 ; 3
    stx    AUDC1                 ; 3
    jmp    LD634                 ; 3

LD59F:
    lda    #$05                  ; 2
    sta    AUDV0                 ; 3
    lda    ram_AD                ; 3
    beq    LD5C0                 ; 2³
    cmp    #$96                  ; 2
    bcc    LD5EC                 ; 2³
    sbc    #$60                  ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    sta    AUDV0                 ; 3
    lda    frameCounter          ; 3
    lsr                          ; 2
    and    #$01                  ; 2
    tay                          ; 2
    ldx    LDBA0,Y               ; 4
    ldy    #$0F                  ; 2
    bne    LD5EC                 ; 3   always branch

LD5C0:
    lda    ram_F2                ; 3
    beq    LD5D8                 ; 2³
    lda    ram_AB                ; 3
    beq    LD5EC                 ; 2³
    lda    frameCounter          ; 3
    lsr                          ; 2
    and    #$03                  ; 2
    tay                          ; 2
    ldx    LDBA7,Y               ; 4
    lda    LDBAB,Y               ; 4
    tay                          ; 2
    jmp    LD5EC                 ; 3

LD5D8:
    bit    INPT4                 ; 3
    bmi    LD5EC                 ; 2³
    bit    ram_F3                ; 3
    bmi    LD5EC                 ; 2³
    lda    frameCounter          ; 3
    and    #$03                  ; 2
    tay                          ; 2
    ldx    LDB9F,Y               ; 4
    lda    LDBA3,Y               ; 4
    tay                          ; 2
LD5EC:
    stx    AUDC0                 ; 3
    sty    AUDF0                 ; 3
    lda    #$08                  ; 2
    sta    AUDC1                 ; 3
    lda    ram_DF                ; 3
    ora    ram_E0                ; 3
    beq    LD613                 ; 2³+1
    ldx    #$00                  ; 2
LD5FC:
    inx                          ; 2
    lda    ram_DE,X              ; 4
    beq    LD5FC                 ; 2³+1
    cmp    #$20                  ; 2
    bcc    LD60D                 ; 2³
    lda    randomizer            ; 3
    and    #$03                  ; 2
    tax                          ; 2
    tay                          ; 2
    bcs    LD634                 ; 3   always branch

LD60D:
    lsr                          ; 2
    tay                          ; 2
    ldx    #$10                  ; 2
    bne    LD634                 ; 3   always branch

LD613:
    lda    ram_AB                ; 3
    beq    LD622                 ; 2³
    lsr                          ; 2
    lsr                          ; 2
    eor    #$FF                  ; 2
    tax                          ; 2
    ldy    #$04                  ; 2
    bit    ram_AF                ; 3
    bpl    LD634                 ; 2³
LD622:
    ldx    #$00                  ; 2
    ldy    #$00                  ; 2
    lda    ram_AC                ; 3
    ora    ram_AD                ; 3
    ora    ram_F2                ; 3
    bne    LD634                 ; 2³
    ldy    ram_E7                ; 3
    ldx    LDBAF,Y               ; 4
    iny                          ; 2
LD634:
    sty    AUDV1                 ; 3
    stx    AUDF1                 ; 3
    lda    ram_AD                ; 3
    beq    LD646                 ; 2³
    cmp    #$E0                  ; 2
    bcs    LD65C                 ; 2³
    lda    #$80                  ; 2
    ora    ram_FD                ; 3
    sta    ram_FD                ; 3
LD646:
    lda    ram_FD                ; 3
    bmi    LD651                 ; 2³
    clc                          ; 2
    adc    #$01                  ; 2
    and    #$3F                  ; 2
    bpl    LD65A                 ; 3   always branch

LD651:
    and    #$F8                  ; 2
    cmp    #$80                  ; 2
    beq    LD65C                 ; 2³
    sec                          ; 2
    sbc    #$01                  ; 2
LD65A:
    sta    ram_FD                ; 3
LD65C:
    ldx    #$03                  ; 2
    lda    ram_BA                ; 3
    ora    ram_AD                ; 3
    ora    ram_F2                ; 3
    bne    LD6E2                 ; 2³
    lda    ram_B6                ; 3
    bne    LD66E                 ; 2³
    bit    INPT4                 ; 3
    bmi    LD6E2                 ; 2³
LD66E:
    ldy    #$03                  ; 2
LD670:
    lda    #$80                  ; 2
    ora    ram_F3                ; 3
    sta    ram_F3                ; 3
    lda    LD9E5,Y               ; 4
    sec                          ; 2
    sbc    ram_9F                ; 3
    cmp    #$02                  ; 2
    bcc    LD6E2                 ; 2³
    dey                          ; 2
    bpl    LD670                 ; 2³
    bit    ram_F4                ; 3
    bmi    LD6AE                 ; 2³
    bvc    LD6B6                 ; 2³
    lda    ram_A0                ; 3
    cmp    #$0A                  ; 2
    bcc    LD6AE                 ; 2³
    cmp    #$99                  ; 2
    bcs    LD6AE                 ; 2³
    lda    frameCounter          ; 3
    lsr                          ; 2
    bcs    LD6AE                 ; 2³
    inc    ram_B1                ; 5
    lda    ram_B1                ; 3
    bne    LD6A0                 ; 2³
    sta    ram_A0                ; 3
LD6A0:
    cmp    #$80                  ; 2
    bne    LD6AE                 ; 2³
    lda    ram_A0                ; 3
    cmp    hPosHERO              ; 3
    bcc    LD6AE                 ; 2³
    adc    #$03                  ; 2
    sta    ram_A0                ; 3
LD6AE:
    lda    #$00                  ; 2
    sta    ram_F4                ; 3
    sta    ram_F3                ; 3
    beq    LD6BF                 ; 3   always branch

LD6B6:
    lda    ram_F3                ; 3
    clc                          ; 2
    adc    #$03                  ; 2
    and    #$0F                  ; 2
    sta    ram_F3                ; 3
LD6BF:
    lda    ram_B0                ; 3
    bne    LD6CC                 ; 2³
    lda    #$07                  ; 2
    clc                          ; 2
    adc    hPosHERO              ; 3
    adc    ram_F3                ; 3
    bne    LD6DC                 ; 2³
LD6CC:
    lda    hPosHERO              ; 3
    sec                          ; 2
    sbc    #$05                  ; 2
    ldy    ram_B1                ; 3
    cpy    #$80                  ; 2
    bcc    LD6D9                 ; 2³
    adc    #$03                  ; 2
LD6D9:
    sec                          ; 2
    sbc    ram_F3                ; 3
LD6DC:
    cmp    #159                  ; 2
    bcc    LD6E8                 ; 2³
    bcs    .alignToLeftEdge      ; 3   always branch

LD6E2:
    lda    #$FD                  ; 2
    sta    ram_F3                ; 3
.alignToLeftEdge:
    lda    #0                    ; 2
LD6E8:
    jsr    HorizPositioning      ; 6
LD6EB:
    sta    WSYNC                 ; 3
;---------------------------------------
    lda    INTIM                 ; 4
    bne    LD6EB                 ; 2³
    ldy    #$82                  ; 2
    sty    WSYNC                 ; 3
;---------------------------------------
    sty    VSYNC                 ; 3
    sty    WSYNC                 ; 3
    sty    WSYNC                 ; 3
    sty    WSYNC                 ; 3
;---------------------------------------
    sta    VSYNC                 ; 3
    inc    frameCounter          ; 5
    bne    LD717                 ; 2³
    inc    ram_B5                ; 5
    lda    ram_B5                ; 3
    and    #$C7                  ; 2
    sta    ram_B5                ; 3
    and    #$07                  ; 2
    bne    LD717                 ; 2³
    inc    ram_B4                ; 5
    bne    LD717                 ; 2³
    sec                          ; 2
    ror    ram_B4                ; 5
LD717:
 IF NTSC
    lda    #$33                  ; 2
 ELSE
    lda    #$50                  ; 2
 ENDIF
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    TIM64T                ; 4
    lda    SWCHB                 ; 4
    sta    ram_FB                ; 3
    lsr                          ; 2
    bcc    LD774                 ; 2³
    bit    ram_B4                ; 3
    bmi    LD774                 ; 2³
    lda    ram_BA                ; 3
    bne    LD774                 ; 2³
    lda    ram_F2                ; 3
    bne    LD735                 ; 2³
    jmp    LD7B6                 ; 3

LD735:
    lda    ram_AC                ; 3
    beq    LD73D                 ; 2³
    lda    #$40                  ; 2
    sta    ram_AC                ; 3
LD73D:
    lda    ram_AB                ; 3
    beq    LD761                 ; 2³
    ldy    levelNum              ; 3
    lda    #$03                  ; 2
    cpy    #$06                  ; 2
    bcs    LD74B                 ; 2³
    lda    #$02                  ; 2
LD74B:
    and    frameCounter          ; 3
    bne    LD7B3                 ; 2³
    lda    LD03D,Y               ; 4
    jsr    LDBBA                 ; 6
    ldy    levelNum              ; 3
    lda    LD051,Y               ; 4
    jsr    AddScore              ; 6
    dec    ram_AB                ; 5
    bne    LD7B3                 ; 2³
LD761:
    lda    ram_DF                ; 3
    bne    LD7B3                 ; 2³
    lda    ram_B2                ; 3
    beq    LD777                 ; 2³
    dec    ram_B2                ; 5
    lda    #$50                  ; 2
    jsr    LDBBA                 ; 6
    lda    #$10                  ; 2
    sta    ram_DF                ; 3
LD774:
    jmp    LD7B3                 ; 3

LD777:
    inc    ram_F2                ; 5
    lda    ram_B6                ; 3
    bne    LD792                 ; 2³
    lda    gameSelect            ; 3
    and    #$7F                  ; 2
    cmp    #DO_RANDOM_LEVELS     ; 2
    bne    LD792                 ; 2³
;choose a random level 0-20
    lda    randomizer            ; 3
    and    #$1F                  ; 2
    cmp    #LEVEL_20+1           ; 2
    bcc    LD7AC                 ; 2³  branch if random level is at 20 or less,
    sbc    #12                   ; 2   otherwise make it so
    jmp    LD7AC                 ; 3

LD792:
    inc    levelNum              ; 5
    lda    ram_B6                ; 3
    beq    LD79E                 ; 2³
    lda    levelNum              ; 3
    and    #$03                  ; 2
    sta    levelNum              ; 3
LD79E:
    lda    #LEVEL_20             ; 2
    cmp    levelNum              ; 3
    bcs    LD7AE                 ; 2³  we have finished the last level!
    lda    #$80                  ; 2   set a flag to display "PRO"
    ora    gameSelect            ; 3
    sta    gameSelect            ; 3
    lda    #LEVEL_13             ; 2
LD7AC:
    sta    levelNum              ; 3
LD7AE:
    ldx    #23                   ; 2
    jsr    LD9F1                 ; 6
LD7B3:
    jmp    LD9DF                 ; 3

LD7B6:
    lda    ram_AD                ; 3
    beq    LD817                 ; 2³+1
    ldx    ram_AE                ; 3
    cmp    #$96                  ; 2
    bcc    LD7F5                 ; 2³
    beq    LD7DC                 ; 2³
    lda    roomNum               ; 3
    cmp    #$0A                  ; 2
    bcc    LD7FE                 ; 2³
    lda    ram_9F                ; 3
    cmp    #$16                  ; 2
    bcs    LD7FE                 ; 2³
    lda    frameCounter          ; 3
    and    #$07                  ; 2
    bne    LD7FE                 ; 2³
    dec    ram_9F                ; 5
    bpl    LD7FE                 ; 2³
    inc    ram_9F                ; 5
    beq    LD7FE                 ; 2³
LD7DC:
    lda    #$8C                  ; 2
    sta    ram_9F                ; 3
    lda    #$32                  ; 2
    sta    ram_A1,X              ; 4
    ldy    #$00                  ; 2
    sty    ram_AC                ; 3
    lda    ram_B6                ; 3
    bne    LD7F5                 ; 2³
    dec    ram_B3                ; 5
    bne    LD7F5                 ; 2³
 IF PLUSROM
    jsr    markGameOver          ; 6
    sty    ram_B6                ; 3
 ELSE
    dey                          ; 2
    sty    ram_B6                ; 3
    sty    ram_BA                ; 3
 ENDIF

LD7F5:
    lda    ram_9F                ; 3
    cmp    LDAFC,X               ; 4
    beq    LD802                 ; 2³+1
    dec    ram_9F                ; 5
LD7FE:
    dec    ram_AD                ; 5
    bne    LD814                 ; 2³
LD802:
    lda    ram_84                ; 3
    cmp    #$F0                  ; 2
    beq    LD814                 ; 2³
    lda    ram_AF                ; 3
    beq    LD814                 ; 2³
    lda    #$00                  ; 2
    sta    ram_AD                ; 3
    lda    #$1F                  ; 2
    sta    ram_E9                ; 3
LD814:
    jmp    LD949                 ; 3

LD817:
    lda    ram_E1                ; 3
    bne    LD889                 ; 2³
    ldy    #$00                  ; 2
    sty    ram_BB                ; 3
    sty    ram_E6                ; 3
    ldx    #$02                  ; 2
LD823:
    lda    ram_E2,X              ; 4
    bmi    LD830                 ; 2³
    asl                          ; 2
    bpl    LD884                 ; 2³
    lda    ram_A0                ; 3
    beq    LD884                 ; 2³
    bne    LD872                 ; 3   always branch

LD830:
    lda    LD9E9,X               ; 4
    cmp    ram_9F                ; 3
    beq    LD83E                 ; 2³
    sec                          ; 2
    sbc    #$01                  ; 2
    cmp    ram_9F                ; 3
    bne    LD859                 ; 2³
LD83E:
    lda    LD9E9,X               ; 4
    sta    ram_9F                ; 3
    ldy    #$40                  ; 2
    sty    ram_E6                ; 3
    bit    ram_84                ; 3
    bpl    LD84D                 ; 2³
    bvs    LD884                 ; 2³
LD84D:
    bit    ram_AC                ; 3
    bmi    LD855                 ; 2³
    lda    #$02                  ; 2
    sta    ram_E8                ; 3
LD855:
    ldy    #$80                  ; 2
    bne    LD884                 ; 3   always branch

LD859:
    lda    LD9EC,X               ; 4
    cmp    ram_9F                ; 3
    beq    LD867                 ; 2³
    clc                          ; 2
    adc    #$01                  ; 2
    cmp    ram_9F                ; 3
    bne    LD872                 ; 2³
LD867:
    lda    LD9EC,X               ; 4
    sta    ram_9F                ; 3
    lda    #$80                  ; 2
    sta    ram_E6                ; 3
    bne    LD884                 ; 3   always branch

LD872:
    bit    ram_BB                ; 3
    bmi    LD884                 ; 2³
    dec    ram_BB                ; 5
    lda    #$08                  ; 2
    and    ram_B0                ; 3
    bne    LD882                 ; 2³
    dec    hPosHERO              ; 5
    dec    hPosHERO              ; 5
LD882:
    inc    hPosHERO              ; 5
LD884:
    dex                          ; 2
    bpl    LD823                 ; 2³
    sty    ram_AC                ; 3
LD889:
    ldx    #$02                  ; 2
LD88B:
    lda    ram_F7,X              ; 4
    bne    LD8A6                 ; 2³
    lda    ram_D4,X              ; 4
    bpl    LD8A6                 ; 2³
    cpx    #$02                  ; 2
    bne    LD89D                 ; 2³
    lda    #$01                  ; 2
    sta    ram_A4                ; 3
    bne    LD8A6                 ; 3   always branch

LD89D:
    lda    #$50                  ; 2
    jsr    LDBBA                 ; 6
    lda    #$13                  ; 2
    sta    ram_F7,X              ; 4
LD8A6:
    lda    ram_D1,X              ; 4
    bpl    LD8BB                 ; 2³
    lda    ram_F7,X              ; 4
    bne    LD8BB                 ; 2³
    cpx    #$02                  ; 2
    bne    LD8B8                 ; 2³
    lda    #$01                  ; 2
    sta    ram_A4                ; 3
    bne    LD8BB                 ; 3   always branch

LD8B8:
    jsr    LDE6B                 ; 6
LD8BB:
    lda    ram_E2,X              ; 4
    and    #$C0                  ; 2
    beq    LD8DC                 ; 2³
    lda    sectionColors,X       ; 4
    and    #$F0                  ; 2
 IF NTSC
    cmp    #$40                  ; 2
 ELSE
    cmp    #$60                  ; 2
 ENDIF
    bne    LD8DC                 ; 2³
    stx    ram_BB                ; 3
    lda    ram_9F                ; 3
    cmp    #$63                  ; 2
    bcc    LD8D2                 ; 2³
    inx                          ; 2
LD8D2:
    cmp    #$25                  ; 2
    bcs    LD8D7                 ; 2³
    dex                          ; 2
LD8D7:
    jsr    LDE6B                 ; 6
    ldx    ram_BB                ; 3
LD8DC:
    dex                          ; 2
    bpl    LD88B                 ; 2³
    lda    ram_AC                ; 3
    beq    LD912                 ; 2³+1
    lda    ram_B2                ; 3
    beq    LD912                 ; 2³+1
    ldx    #$02                  ; 2
    lda    ram_9F                ; 3
    cmp    #$62                  ; 2
    bcs    LD8F0                 ; 2³
    dex                          ; 2
LD8F0:
    lda    ram_A8,X              ; 4
    cmp    #$93                  ; 2
    bne    LD912                 ; 2³+1
    lda    ram_DE,X              ; 4
    bne    LD912                 ; 2³+1
    lda    ram_84                ; 3
    cmp    #$D0                  ; 2
    bne    LD912                 ; 2³
    lda    hPosHERO              ; 3
    and    #$03                  ; 2
    bne    LD912                 ; 2³
    lda    hPosHERO              ; 3
    cmp    #$0D                  ; 2
    bcc    LD912                 ; 2³
    sta    ram_A8,X              ; 4
    lda    #$40                  ; 2
    sta    ram_DE,X              ; 4
LD912:
    lda    ram_AD                ; 3
    bne    LD932                 ; 2³
    jsr    LDC56                 ; 6
    bne    LD932                 ; 2³
    lda    ram_A9                ; 3
    sec                          ; 2
    sbc    #$07                  ; 2
    sta    ram_BB                ; 3
    lda    hPosHERO              ; 3
    sec                          ; 2
    sbc    ram_BB                ; 3
    cmp    #$0F                  ; 2
    bcs    LD932                 ; 2³
    lda    #$10                  ; 2
    jsr    AddScore              ; 6
    dec    ram_F2                ; 5
LD932:
    bit    ram_AF                ; 3
    bpl    LD949                 ; 2³
    lda    #$3F                  ; 2
    and    frameCounter          ; 3
    bne    LD949                 ; 2³
    dec    ram_AB                ; 5
    bne    LD949                 ; 2³
    ldx    #23                   ; 2
    jsr    LD9F1                 ; 6
    lda    #$FF                  ; 2
    sta    ram_AD                ; 3
LD949:
    ldx    #$02                  ; 2
LD94B:
    lda    ram_DE,X              ; 4
    cmp    #$1F                  ; 2
    beq    LD956                 ; 2³
    dex                          ; 2
    bpl    LD94B                 ; 2³
    bmi    LD9C7                 ; 3   always branch

LD956:
    dec    ram_B2                ; 5
    lda    ram_A1,X              ; 4
    cmp    #$32                  ; 2
    beq    LD97E                 ; 2³
    lda    ram_A5,X              ; 4
    sec                          ; 2
    sbc    #$13                  ; 2
    cmp    ram_A8,X              ; 4
    bcs    LD97E                 ; 2³
    adc    #$23                  ; 2
    cmp    ram_A8,X              ; 4
    bcc    LD97E                 ; 2³
    lda    ram_F7,X              ; 4
    bne    LD97E                 ; 2³
    cpx    #$02                  ; 2
    beq    LD97E                 ; 2³
    lda    #$13                  ; 2
    sta    ram_F7,X              ; 4
    lda    #$50                  ; 2
    jsr    LDBBA                 ; 6
LD97E:
    lda    ram_A0                ; 3
    cmp    #$99                  ; 2
    bcs    LD99B                 ; 2³
    sbc    #$0E                  ; 2
    cmp    ram_A8,X              ; 4
    bcs    LD99B                 ; 2³
    adc    #$1B                  ; 2
    cmp    ram_A8,X              ; 4
    bcc    LD99B                 ; 2³
    lda    #$00                  ; 2
    sta    ram_A0                ; 3
    lda    #$75                  ; 2
    sta    ram_FA                ; 3
    jsr    LDBBA                 ; 6
LD99B:
    lda    ram_9F                ; 3
    cmp    LDBFC,X               ; 4
    bcc    LD9C7                 ; 2³
    cmp    LDAFF,X               ; 4
    bcs    LD9C7                 ; 2³
    lda    ram_A8,X              ; 4
    cmp    #$93                  ; 2
    bcs    LD9C7                 ; 2³
    sbc    #$07                  ; 2
    sta    ram_BB                ; 3
    lda    hPosHERO              ; 3
    sec                          ; 2
    sbc    ram_BB                ; 3
    cmp    #$11                  ; 2
    bcs    LD9C7                 ; 2³
    dec    hPosHERO              ; 5
    lda    ram_B0                ; 3
    beq    LD9C4                 ; 2³
    inc    hPosHERO              ; 5
    inc    hPosHERO              ; 5
LD9C4:
    jsr    LDE6B                 ; 6
LD9C7:
    lda    ram_BA                ; 3
    ora    ram_AF                ; 3
    bmi    LD9DF                 ; 2³
    lda    ram_AD                ; 3
    cmp    #$77                  ; 2
    bcs    LD9DF                 ; 2³
    inc    ram_AB                ; 5
    lda    #$51                  ; 2
    cmp    ram_AB                ; 3
    bcs    LD9DF                 ; 2³
    sta    ram_AB                ; 3
    dec    ram_AF                ; 5
LD9DF:
    jmp    LDFF2                 ; 3
    
LD9E2:
    .byte $FF ; |XXXXXXXX| $D9E2
    .byte $00 ; |        | $D9E3
    .byte $FF ; |XXXXXXXX| $D9E4
LD9E5:
    .byte $76 ; | XXX XX | $D9E5
    .byte $50 ; | X X    | $D9E6
    .byte $29 ; |  X X  X| $D9E7
    .byte $77 ; | XXX XXX| $D9E8
LD9E9:
    .byte $3C ; |  XXXX  | $D9E9
    .byte $63 ; | XX   XX| $D9EA
    .byte $EF ; |XXX XXXX| $D9EB
LD9EC:
    .byte $EF ; |XXX XXXX| $D9EC
    .byte $24 ; |  X  X  | $D9ED
    .byte $4B ; | X  X XX| $D9EE
    .byte $A2 ; |X X   X | $D9EF
    .byte $18 ; |   XX   | $D9F0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LD9F1 SUBROUTINE ;x2
    lda    LDA04,X               ; 4
    sta    hPosHERO,X            ; 4
    dex                          ; 2
    bpl    LD9F1                 ; 2³
    lda    levelNum              ; 3
    and    #$03                  ; 2
    tax                          ; 2
    lda    LDD13,X               ; 4
    sta    ram_A4                ; 3
    rts                          ; 6

LDA04:
    .byte $20 ; |  X     | $DA04 0  9B
    .byte $00 ; |        | $DA05 1
    .byte $00 ; |        | $DA06 2
    .byte $00 ; |        | $DA07 3
    .byte $8B ; |X   X XX| $DA08 4
    .byte $3D ; |  XXXX X| $DA09 5
    .byte $32 ; |  XX  X | $DA0A 6
    .byte $32 ; |  XX  X | $DA0B 7
    .byte $32 ; |  XX  X | $DA0C 8
 IF NTSC
    .byte $20 ; |  X     | $DA0D 9   ora level 1
 ELSE
    .byte $40 ; |  X     | $DA0D 9   ora level 1
 ENDIF
    .byte $93 ; |X  X  XX| $DA0E 10
    .byte $93 ; |X  X  XX| $DA0F 11
    .byte $93 ; |X  X  XX| $DA10 12
    .byte $93 ; |X  X  XX| $DA11 13
    .byte $93 ; |X  X  XX| $DA12 14
    .byte $93 ; |X  X  XX| $DA13 15
    .byte $00 ; |        | $DA14 16
    .byte $00 ; |        | $DA15 17
    .byte $95 ; |X  X X X| $DA16 18
    .byte $01 ; |       X| $DA17 19
    .byte $00 ; |        | $DA18 20
    .byte $00 ; |        | $DA19 21
    .byte $00 ; |        | $DA1A 22
    .byte $06 ; |     XX | $DA1B 23
    .byte $04 ; |     X  | $DA1C 24  not used
    
LDA1D:
    .byte <LDC36         ; $DA1D
    .byte <LDC3A         ; $DA1E
    .byte <LDC3E         ; $DA1F
    .byte <LDC42         ; $DA20
    .byte <LDC46         ; $DA21
    .byte <LDC4A         ; $DA22
    .byte <LDC4E         ; $DA23
    .byte <LDC52         ; $DA24

    .byte $00 ; |        | $DA25
DynamiteA:
    .byte $00 ; |        | $DA26
    .byte $1C ; |   XXX  | $DA27
    .byte $1C ; |   XXX  | $DA28
    .byte $1C ; |   XXX  | $DA29
    .byte $1C ; |   XXX  | $DA2A
    .byte $1C ; |   XXX  | $DA2B
    .byte $1C ; |   XXX  | $DA2C
    .byte $08 ; |    X   | $DA2D
    .byte $08 ; |    X   | $DA2E
    .byte $18 ; |   XX   | $DA2F
    .byte $10 ; |   X    | $DA30
    .byte $04 ; |     X  | $DA31
    .byte $00 ; |        | $DA32
DynamiteB:
    .byte $00 ; |        | $DA33
    .byte $1C ; |   XXX  | $DA34
    .byte $1C ; |   XXX  | $DA35
    .byte $1C ; |   XXX  | $DA36
    .byte $1C ; |   XXX  | $DA37
    .byte $1C ; |   XXX  | $DA38
    .byte $1C ; |   XXX  | $DA39
    .byte $08 ; |    X   | $DA3A
    .byte $08 ; |    X   | $DA3B
    .byte $0C ; |    XX  | $DA3C
    .byte $18 ; |   XX   | $DA3D
    .byte $08 ; |    X   | $DA3E
    .byte $00 ; |        | $DA3F
DynamiteC:
    .byte $00 ; |        | $DA40
    .byte $1C ; |   XXX  | $DA41
    .byte $1C ; |   XXX  | $DA42
    .byte $1C ; |   XXX  | $DA43
    .byte $1C ; |   XXX  | $DA44
    .byte $1C ; |   XXX  | $DA45
    .byte $1C ; |   XXX  | $DA46
    .byte $08 ; |    X   | $DA47
    .byte $08 ; |    X   | $DA48
    .byte $0C ; |    XX  | $DA49
    .byte $04 ; |     X  | $DA4A
    .byte $10 ; |   X    | $DA4B
    .byte $00 ; |        | $DA4C
ExplosionA:
    .byte $00 ; |        | $DA4D
    .byte $00 ; |        | $DA4E
    .byte $18 ; |   XX   | $DA4F
    .byte $3C ; |  XXXX  | $DA50
    .byte $3C ; |  XXXX  | $DA51
    .byte $18 ; |   XX   | $DA52
    .byte $3C ; |  XXXX  | $DA53
    .byte $3C ; |  XXXX  | $DA54
    .byte $18 ; |   XX   | $DA55
    .byte $00 ; |        | $DA56
    .byte $00 ; |        | $DA57
ExplosionB:
    .byte $00 ; |        | $DA58
    .byte $45 ; | X   X X| $DA59
    .byte $1C ; |   XXX  | $DA5A
    .byte $18 ; |   XX   | $DA5B
    .byte $3E ; |  XXXXX | $DA5C
    .byte $7C ; | XXXXX  | $DA5D
    .byte $38 ; |  XXX   | $DA5E
    .byte $9D ; |X  XXX X| $DA5F
    .byte $3C ; |  XXXX  | $DA60
    .byte $3C ; |  XXXX  | $DA61
    .byte $18 ; |   XX   | $DA62
    .byte $52 ; | X X  X | $DA63
    .byte $00 ; |        | $DA64
ExplosionC:
    .byte $22 ; |  X   X | $DA65
    .byte $88 ; |X   X   | $DA66
    .byte $59 ; | X XX  X| $DA67
    .byte $7E ; | XXXXXX | $DA68
    .byte $3C ; |  XXXX  | $DA69
    .byte $B8 ; |X XXX   | $DA6A
    .byte $1D ; |   XXX X| $DA6B
    .byte $3C ; |  XXXX  | $DA6C
    .byte $7E ; | XXXXXX | $DA6D
    .byte $5A ; | X XX X | $DA6E
    .byte $91 ; |X  X   X| $DA6F
    .byte $04 ; |     X  | $DA70

    .byte $00 ; |        | $DA71
    .byte $CC ; |XX  XX  | $DA72
    .byte $5E ; | X XXXX | $DA73
    .byte $76 ; | XXX XX | $DA74
    .byte $2A ; |  X X X | $DA75
    .byte $0A ; |    X X | $DA76
    .byte $0A ; |    X X | $DA77
    .byte $0E ; |    XXX | $DA78
    .byte $04 ; |     X  | $DA79
    .byte $0C ; |    XX  | $DA7A
    .byte $0C ; |    XX  | $DA7B
    .byte $1C ; |   XXX  | $DA7C
    .byte $08 ; |    X   | $DA7D

    .byte $00 ; |        | $DA7E
    .byte $CC ; |XX  XX  | $DA7F
    .byte $56 ; | X X XX | $DA80
    .byte $7A ; | XXXX X | $DA81
    .byte $2A ; |  X X X | $DA82
    .byte $0A ; |    X X | $DA83
    .byte $3A ; |  XXX X | $DA84
    .byte $2E ; |  X XXX | $DA85
    .byte $24 ; |  X  X  | $DA86
    .byte $2C ; |  X XX  | $DA87
    .byte $0C ; |    XX  | $DA88
    .byte $1C ; |   XXX  | $DA89
    .byte $08 ; |    X   | $DA8A
SeventyFive:
    .byte $00 ; |        | $DA8B
    .byte $00 ; |        | $DA8C
    .byte $00 ; |        | $DA8D
    .byte $00 ; |        | $DA8E
    .byte $2E ; |  X XXX | $DA8F
    .byte $22 ; |  X   X | $DA90
    .byte $2E ; |  X XXX | $DA91
    .byte $28 ; |  X X   | $DA92
    .byte $EE ; |XXX XXX | $DA93
    .byte $00 ; |        | $DA94
    .byte $00 ; |        | $DA95
    .byte $00 ; |        | $DA96
Raft:
    .byte $00 ; |        | $DA97
    .byte $FF ; |XXXXXXXX| $DA98
BlankGfx:
    .byte $00 ; |        | $DA99
    .byte $00 ; |        | $DA9A
    .byte $00 ; |        | $DA9B
    .byte $00 ; |        | $DA9C
    .byte $00 ; |        | $DA9D
    .byte $00 ; |        | $DA9E
    .byte $00 ; |        | $DA9F
    .byte $00 ; |        | $DAA0
    .byte $00 ; |        | $DAA1
    .byte $00 ; |        | $DAA2
    .byte $00 ; |        | $DAA3
    .byte $00 ; |        | $DAA4
    .byte $00 ; |        | $DAA5
    
    .byte $00 ; |        | $DAA6   here
    .byte $62 ; | XX   X | $DAA7
    .byte $34 ; |  XX X  | $DAA8
    .byte $18 ; |   XX   | $DAA9
    .byte $00 ; |        | $DAAA
    .byte $00 ; |        | $DAAB
    .byte $00 ; |        | $DAAC
    .byte $00 ; |        | $DAAD
    .byte $00 ; |        | $DAAE
    .byte $00 ; |        | $DAAF
    .byte $00 ; |        | $DAB0
    .byte $00 ; |        | $DAB1
    
    .byte $00 ; |        | $DAB2
    .byte $62 ; | XX   X | $DAB3
    .byte $41 ; | X     X| $DAB4
    .byte $63 ; | XX   XX| $DAB5
    .byte $36 ; |  XX XX | $DAB6
    .byte $1C ; |   XXX  | $DAB7
    .byte $00 ; |        | $DAB8
    .byte $00 ; |        | $DAB9
    .byte $00 ; |        | $DABA
    .byte $00 ; |        | $DABB
    .byte $00 ; |        | $DABC
    .byte $00 ; |        | $DABD
    
    .byte $00 ; |        | $DABE
    .byte $20 ; |  X     | $DABF
    .byte $66 ; | XX  XX | $DAC0
    .byte $4B ; | X  X XX| $DAC1
    .byte $41 ; | X     X| $DAC2
    .byte $63 ; | XX   XX| $DAC3
    .byte $22 ; |  X   X | $DAC4
    .byte $36 ; |  XX XX | $DAC5
    .byte $1C ; |   XXX  | $DAC6
    .byte $00 ; |        | $DAC7
    .byte $00 ; |        | $DAC8
    .byte $00 ; |        | $DAC9
    
    .byte $00 ; |        | $DACA
    .byte $36 ; |  XX XX | $DACB
    .byte $60 ; | XX     | $DACC
    .byte $4C ; | X  XX  | $DACD
    .byte $52 ; | X X  X | $DACE
    .byte $53 ; | X X  XX| $DACF
    .byte $49 ; | X  X  X| $DAD0
    .byte $63 ; | XX   XX| $DAD1
    .byte $36 ; |  XX XX | $DAD2
    .byte $1C ; |   XXX  | $DAD3
    .byte $00 ; |        | $DAD4
    .byte $00 ; |        | $DAD5
    
    .byte $00 ; |        | $DAD6
    .byte $2F ; |  X XXXX| $DAD7
    .byte $26 ; |  X  XX | $DAD8
    .byte $26 ; |  X  XX | $DAD9
    .byte $60 ; | XX     | $DADA
    .byte $4C ; | X  XX  | $DADB
    .byte $52 ; | X X  X | $DADC
    .byte $51 ; | X X   X| $DADD
    .byte $55 ; | X X X X| $DADE
    .byte $69 ; | XX X  X| $DADF
    .byte $22 ; |  X   X | $DAE0
    .byte $1C ; |   XXX  | $DAE1
    .byte $00 ; |        | $DAE2
    .byte $6C ; | XX XX  | $DAE3
    .byte $28 ; |  X X   | $DAE4
    .byte $28 ; |  X X   | $DAE5
    .byte $28 ; |  X X   | $DAE6
    .byte $28 ; |  X X   | $DAE7
    .byte $28 ; |  X X   | $DAE8
    .byte $28 ; |  X X   | $DAE9
    .byte $28 ; |  X X   | $DAEA
    .byte $38 ; |  XXX   | $DAEB
    .byte $BA ; |X XXX X | $DAEC
    .byte $BA ; |X XXX X | $DAED
    .byte $B6 ; |X XX XX | $DAEE
    .byte $B4 ; |X XX X  | $DAEF
    .byte $7C ; | XXXXX  | $DAF0
    .byte $4A ; | X  X X | $DAF1
    .byte $36 ; |  XX XX | $DAF2
    .byte $32 ; |  XX  X | $DAF3
    .byte $7A ; | XXXX X | $DAF4
    .byte $4A ; | X  X X | $DAF5
    .byte $4A ; | X  X X | $DAF6
    .byte $36 ; |  XX XX | $DAF7
    .byte $04 ; |     X  | $DAF8
    .byte $04 ; |     X  | $DAF9
    .byte $1F ; |   XXXXX| $DAFA
    .byte $00 ; |        | $DAFB
LDAFC:
    .byte $22 ; |  X   X | $DAFC
    .byte $49 ; | X  X  X| $DAFD
    .byte $70 ; | XXX    | $DAFE
LDAFF:
    .byte $1C ; |   XXX  | $DAFF
    .byte $43 ; | X    XX| $DB00
    .byte $6A ; | XX X X | $DB01
    .byte $00 ; |        | $DB02
    .byte $00 ; |        | $DB03
    .byte $00 ; |        | $DB04
    .byte $00 ; |        | $DB05
    .byte $10 ; |   X    | $DB06
    .byte $7C ; | XXXXX  | $DB07
    .byte $FE ; |XXXXXXX | $DB08
    .byte $EE ; |XXX XXX | $DB09
    .byte $D6 ; |XX X XX | $DB0A
    .byte $AA ; |X X X X | $DB0B
    .byte $82 ; |X     X | $DB0C
    .byte $00 ; |        | $DB0D
    .byte $00 ; |        | $DB0E
    .byte $44 ; | X   X  | $DB0F
    .byte $82 ; |X     X | $DB10
    .byte $C6 ; |XX   XX | $DB11
    .byte $D6 ; |XX X XX | $DB12
    .byte $7C ; | XXXXX  | $DB13
    .byte $38 ; |  XXX   | $DB14
    .byte $10 ; |   X    | $DB15
    .byte $28 ; |  X X   | $DB16
    .byte $00 ; |        | $DB17
    .byte $00 ; |        | $DB18
    .byte $00 ; |        | $DB19
    .byte $00 ; |        | $DB1A
    .byte $00 ; |        | $DB1B
    .byte $82 ; |X     X | $DB1C
    .byte $92 ; |X  X  X | $DB1D
    .byte $BA ; |X XXX X | $DB1E
    .byte $BA ; |X XXX X | $DB1F
    .byte $54 ; | X X X  | $DB20
    .byte $10 ; |   X    | $DB21
    .byte $10 ; |   X    | $DB22
    .byte $10 ; |   X    | $DB23
    .byte $10 ; |   X    | $DB24
    .byte $10 ; |   X    | $DB25
    .byte $10 ; |   X    | $DB26
    .byte $00 ; |        | $DB27
    .byte $82 ; |X     X | $DB28
    .byte $92 ; |X  X  X | $DB29
    .byte $BA ; |X XXX X | $DB2A
    .byte $BA ; |X XXX X | $DB2B
    .byte $54 ; | X X X  | $DB2C
    .byte $10 ; |   X    | $DB2D
    .byte $10 ; |   X    | $DB2E
    .byte $10 ; |   X    | $DB2F
    .byte $10 ; |   X    | $DB30
    .byte $10 ; |   X    | $DB31
    .byte $10 ; |   X    | $DB32
    .byte $10 ; |   X    | $DB33
    .byte $00 ; |        | $DB34
    .byte $82 ; |X     X | $DB35
    .byte $C6 ; |XX   XX | $DB36
    .byte $6C ; | XX XX  | $DB37
    .byte $28 ; |  X X   | $DB38
    .byte $38 ; |  XXX   | $DB39
    .byte $7C ; | XXXXX  | $DB3A
    .byte $38 ; |  XXX   | $DB3B
    .byte $28 ; |  X X   | $DB3C
    .byte $6C ; | XX XX  | $DB3D
    .byte $C6 ; |XX   XX | $DB3E
    .byte $82 ; |X     X | $DB3F
    .byte $00 ; |        | $DB40
    .byte $44 ; | X   X  | $DB41
    .byte $6C ; | XX XX  | $DB42
    .byte $28 ; |  X X   | $DB43
    .byte $28 ; |  X X   | $DB44
    .byte $38 ; |  XXX   | $DB45
    .byte $7C ; | XXXXX  | $DB46
    .byte $38 ; |  XXX   | $DB47
    .byte $28 ; |  X X   | $DB48
    .byte $28 ; |  X X   | $DB49
    .byte $6C ; | XX XX  | $DB4A
    .byte $44 ; | X   X  | $DB4B
    .byte $00 ; |        | $DB4C
    .byte $10 ; |   X    | $DB4D
    .byte $38 ; |  XXX   | $DB4E
    .byte $28 ; |  X X   | $DB4F
    .byte $28 ; |  X X   | $DB50
    .byte $38 ; |  XXX   | $DB51
    .byte $7C ; | XXXXX  | $DB52
    .byte $38 ; |  XXX   | $DB53
    .byte $28 ; |  X X   | $DB54
    .byte $28 ; |  X X   | $DB55
    .byte $38 ; |  XXX   | $DB56
    .byte $10 ; |   X    | $DB57
    .byte $00 ; |        | $DB58
    .byte $28 ; |  X X   | $DB59
    .byte $28 ; |  X X   | $DB5A
    .byte $28 ; |  X X   | $DB5B
    .byte $28 ; |  X X   | $DB5C
    .byte $38 ; |  XXX   | $DB5D
    .byte $7C ; | XXXXX  | $DB5E
    .byte $38 ; |  XXX   | $DB5F
    .byte $28 ; |  X X   | $DB60
    .byte $28 ; |  X X   | $DB61
    .byte $28 ; |  X X   | $DB62
    .byte $28 ; |  X X   | $DB63
LightGfx:
    .byte $00 ; |        | $DB64
    .byte $09 ; |    X  X| $DB65
    .byte $1D ; |   XXX X| $DB66
    .byte $3F ; |  XXXXXX| $DB67
    .byte $1D ; |   XXX X| $DB68
    .byte $3F ; |  XXXXXX| $DB69
    .byte $1D ; |   XXX X| $DB6A
    .byte $09 ; |    X  X| $DB6B
    .byte $0F ; |    XXXX| $DB6C
    .byte $00 ; |        | $DB6D
    .byte $00 ; |        | $DB6E
    .byte $00 ; |        | $DB6F
    .byte $00 ; |        | $DB70
    .byte $EE ; |XXX XXX | $DB71
    .byte $A8 ; |X X X   | $DB72
    .byte $AE ; |X X XXX | $DB73
    .byte $A2 ; |X X   X | $DB74
    .byte $EE ; |XXX XXX | $DB75
    .byte $00 ; |        | $DB76
    .byte $00 ; |        | $DB77
    .byte $00 ; |        | $DB78
    .byte $00 ; |        | $DB79
    .byte $EE ; |XXX XXX | $DB7A
    .byte $2A ; |  X X X | $DB7B
    .byte $EA ; |XXX X X | $DB7C
    .byte $8A ; |X   X X | $DB7D
    .byte $EE ; |XXX XXX | $DB7E
    .byte $00 ; |        | $DB7F
    .byte $00 ; |        | $DB80
    .byte $00 ; |        | $DB81
    .byte $00 ; |        | $DB82
    .byte $02 ; |      X | $DB83
    .byte $07 ; |     XXX| $DB84
    .byte $FC ; |XXXXXX  | $DB85
    .byte $F9 ; |XXXXX  X| $DB86
    .byte $FF ; |XXXXXXXX| $DB87
    .byte $0D ; |    XX X| $DB88
    .byte $06 ; |     XX | $DB89
    .byte $00 ; |        | $DB8A
    .byte $00 ; |        | $DB8B
    .byte $00 ; |        | $DB8C
    .byte $00 ; |        | $DB8D
    .byte $00 ; |        | $DB8E
    .byte $00 ; |        | $DB8F
    .byte $00 ; |        | $DB90
    .byte $00 ; |        | $DB91
    .byte $00 ; |        | $DB92
    .byte $00 ; |        | $DB93
    .byte $00 ; |        | $DB94
    .byte $00 ; |        | $DB95
    .byte $00 ; |        | $DB96
    .byte $02 ; |      X | $DB97
    .byte $FF ; |XXXXXXXX| $DB98
    .byte $FD ; |XXXXXX X| $DB99
    .byte $FF ; |XXXXXXXX| $DB9A
    .byte $0D ; |    XX X| $DB9B
    .byte $06 ; |     XX | $DB9C
    .byte $00 ; |        | $DB9D
    .byte $00 ; |        | $DB9E
LDB9F:
    .byte $0C ; |    XX  | $DB9F
LDBA0:
    .byte $0C ; |    XX  | $DBA0
    .byte $04 ; |     X  | $DBA1
    .byte $04 ; |     X  | $DBA2
LDBA3:
    .byte $0C ; |    XX  | $DBA3
    .byte $0F ; |    XXXX| $DBA4
    .byte $1C ; |   XXX  | $DBA5
    .byte $1F ; |   XXXXX| $DBA6
LDBA7:
    .byte $0C ; |    XX  | $DBA7
    .byte $00 ; |        | $DBA8
    .byte $00 ; |        | $DBA9
    .byte $00 ; |        | $DBAA
LDBAB:
    .byte $0F ; |    XXXX| $DBAB
    .byte $00 ; |        | $DBAC
    .byte $00 ; |        | $DBAD
    .byte $00 ; |        | $DBAE
LDBAF:
    .byte $10 ; |   X    | $DBAF
    .byte $13 ; |   X  XX| $DBB0
    .byte $17 ; |   X XXX| $DBB1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddScore SUBROUTINE ;x2
    ldy    scoreBCD              ; 3
    sty    ram_BB                ; 3
    ldy    #$01                  ; 2
    bne    LDBC0                 ; 3   always branch

LDBBA SUBROUTINE ;x5
    ldy    scoreBCD              ; 3
    sty    ram_BB                ; 3
    ldy    #$02                  ; 2
LDBC0:
    sta    ram_BC                ; 3
    lda    ram_B6                ; 3
    bne    LDBFB                 ; 2³
    lda    ram_BC                ; 3
    sed                          ; 2
    cmp    #$99                  ; 2
LDBCB:
    adc.wy scoreBCD,Y            ; 4
    sta.wy scoreBCD,Y            ; 5
    lda    #$00                  ; 2
    dey                          ; 2
    bpl    LDBCB                 ; 2³
    cld                          ; 2
    bcc    LDBE5                 ; 2³
    sty    ram_BA                ; 3
    sty    ram_B6                ; 3
    lda    #$BB                  ; 2
    sta    scoreBCD              ; 3
    sta    scoreBCD+1            ; 3
    sta    scoreBCD+2            ; 3
LDBE5:
    lda    ram_BB                ; 3
    and    #$12                  ; 2
    sta    ram_BB                ; 3
    lda    scoreBCD              ; 3
    and    #$12                  ; 2
    eor    ram_BB                ; 3
    beq    LDBFB                 ; 2³
    ldy    #$07                  ; 2
    cpy    ram_B3                ; 3
    beq    LDBFB                 ; 2³
    inc    ram_B3                ; 5
LDBFB:
    rts                          ; 6

LDBFC:
    .byte $15 ; |   X X X| $DBFC
    .byte $3C ; |  XXXX  | $DBFD
    .byte $63 ; | XX   XX| $DBFE
    .byte $00 ; |        | $DBFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawLivesDynamite SUBROUTINE ;x2
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    (ram_91),Y            ; 5
    sta    GRP0                  ; 3
    sta    GRP1                  ; 3
    sta    GRP0                  ; 3
    lda    (ram_95),Y            ; 5
    sta    COLUP0                ; 3
    sta    COLUP1                ; 3
    lda    LDC6C,X               ; 4
    sta    PF2                   ; 3
    lda    LDC6A,X               ; 4
    sta    PF0                   ; 3
    lda    LDC77,X               ; 4
    sta    PF1                   ; 3
    dey                          ; 2
    bpl    DrawLivesDynamite     ; 2³
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    iny                          ; 2
    sty    PF0                   ; 3
    sty    PF1                   ; 3
    sty    PF2                   ; 3
    sty    GRP0                  ; 3
    sty    GRP1                  ; 3
    sty    GRP0                  ; 3
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LDC36:
    .byte $FF ; |XXXXXXXX| $DC36
    .byte $7E ; | XXXXXX | $DC37
    .byte $3C ; |  XXXX  | $DC38
    .byte $18 ; |   XX   | $DC39
LDC3A:
    .byte $FF ; |XXXXXXXX| $DC3A
    .byte $FC ; |XXXXXX  | $DC3B
    .byte $78 ; | XXXX   | $DC3C
    .byte $30 ; |  XX    | $DC3D
LDC3E:
    .byte $FF ; |XXXXXXXX| $DC3E
    .byte $F9 ; |XXXXX  X| $DC3F
    .byte $F0 ; |XXXX    | $DC40
    .byte $60 ; | XX     | $DC41
LDC42:
    .byte $FF ; |XXXXXXXX| $DC42
    .byte $F3 ; |XXXX  XX| $DC43
    .byte $E1 ; |XXX    X| $DC44
    .byte $C0 ; |XX      | $DC45
LDC46:
    .byte $FF ; |XXXXXXXX| $DC46
    .byte $E7 ; |XXX  XXX| $DC47
    .byte $C3 ; |XX    XX| $DC48
    .byte $81 ; |X      X| $DC49
LDC4A:
    .byte $FF ; |XXXXXXXX| $DC4A
    .byte $CF ; |XX  XXXX| $DC4B
    .byte $87 ; |X    XXX| $DC4C
    .byte $03 ; |      XX| $DC4D
LDC4E:
    .byte $FF ; |XXXXXXXX| $DC4E
    .byte $9F ; |X  XXXXX| $DC4F
    .byte $0F ; |    XXXX| $DC50
    .byte $06 ; |     XX | $DC51
LDC52:
    .byte $FF ; |XXXXXXXX| $DC52
    .byte $3F ; |  XXXXXX| $DC53
    .byte $1E ; |   XXXX | $DC54
    .byte $0C ; |    XX  | $DC55

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LDC56 SUBROUTINE ;x1
    ldx    levelNum              ; 3
    lda    LD065,X               ; 4
    cmp    roomNum               ; 3
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LDC5E:
    .byte $87 ; |X    XXX| $DC5E
    .byte $96 ; |X  X XX | $DC5F
    .byte $E0 ; |XXX     | $DC60
CeilingRippleGfx2:
    .byte $FF ; |XXXXXXXX| $DC61  PF1, PF2
    .byte $7E ; | XXXXXX | $DC62
    .byte $3C ; |  XXXX  | $DC63
    .byte $18 ; |   XX   | $DC64
    .byte $00 ; |        | $DC65
CeilingRippleGfx1:
    .byte $F0 ; |XXXX    | $DC66  PF0
    .byte $F0 ; |XXXX    | $DC67
    .byte $60 ; | XX     | $DC68
LDC69:
    .byte $00 ; |        | $DC69
LDC6A:
    .byte $00 ; |        | $DC6A
LDC6B:
    .byte $00 ; |        | $DC6B
LDC6C:
    .byte $03 ; |      XX| $DC6C
    .byte $0F ; |    XXXX| $DC6D
    .byte $3F ; |  XXXXXX| $DC6E
    .byte $FF ; |XXXXXXXX| $DC6F
    .byte $FF ; |XXXXXXXX| $DC70
    .byte $FF ; |XXXXXXXX| $DC71
    .byte $FF ; |XXXXXXXX| $DC72
    .byte $FF ; |XXXXXXXX| $DC73
    .byte $FF ; |XXXXXXXX| $DC74
    .byte $FF ; |XXXXXXXX| $DC75
LDC76:
    .byte $00 ; |        | $DC76
LDC77:
    .byte $00 ; |        | $DC77
    .byte $00 ; |        | $DC78
    .byte $00 ; |        | $DC79
    .byte $00 ; |        | $DC7A
    .byte $00 ; |        | $DC7B
    .byte $00 ; |        | $DC7C
    .byte $C0 ; |XX      | $DC7D
    .byte $F0 ; |XXXX    | $DC7E
    .byte $FC ; |XXXXXX  | $DC7F
    .byte $FF ; |XXXXXXXX| $DC80
    .byte $FF ; |XXXXXXXX| $DC81
    .byte $00 ; |        | $DC82
    .byte $02 ; |      X | $DC83
    .byte $43 ; | X    XX| $DC84
    .byte $44 ; | X   X  | $DC85
    .byte $74 ; | XXX X  | $DC86
    .byte $14 ; |   X X  | $DC87
    .byte $1C ; |   XXX  | $DC88
    .byte $1C ; |   XXX  | $DC89
    .byte $18 ; |   XX   | $DC8A
    .byte $1C ; |   XXX  | $DC8B
    .byte $22 ; |  X   X | $DC8C
    .byte $2E ; |  X XXX | $DC8D
    .byte $76 ; | XXX XX | $DC8E
    .byte $76 ; | XXX XX | $DC8F
    .byte $7E ; | XXXXXX | $DC90
    .byte $6C ; | XX XX  | $DC91
    .byte $26 ; |  X  XX | $DC92
    .byte $2E ; |  X XXX | $DC93
    .byte $28 ; |  X X   | $DC94
    .byte $28 ; |  X X   | $DC95
    .byte $26 ; |  X  XX | $DC96
    .byte $20 ; |  X     | $DC97
    .byte $20 ; |  X     | $DC98
    .byte $F8 ; |XXXXX   | $DC99
    .byte $FF ; |XXXXXXXX| $DC9A
    .byte $0C ; |    XX  | $DC9B
    .byte $08 ; |    X   | $DC9C
    .byte $28 ; |  X X   | $DC9D
    .byte $28 ; |  X X   | $DC9E
    .byte $3E ; |  XXXXX | $DC9F
    .byte $0A ; |    X X | $DCA0
    .byte $0E ; |    XXX | $DCA1
    .byte $1C ; |   XXX  | $DCA2
    .byte $18 ; |   XX   | $DCA3
    .byte $1C ; |   XXX  | $DCA4
    .byte $32 ; |  XX  X | $DCA5
    .byte $34 ; |  XX X  | $DCA6
    .byte $76 ; | XXX XX | $DCA7
    .byte $76 ; | XXX XX | $DCA8
    .byte $7E ; | XXXXXX | $DCA9
    .byte $6C ; | XX XX  | $DCAA
    .byte $26 ; |  X  XX | $DCAB
    .byte $2E ; |  X XXX | $DCAC
    .byte $28 ; |  X X   | $DCAD
    .byte $28 ; |  X X   | $DCAE
    .byte $26 ; |  X  XX | $DCAF
    .byte $20 ; |  X     | $DCB0
    .byte $20 ; |  X     | $DCB1
    .byte $70 ; | XXX    | $DCB2
    .byte $FF ; |XXXXXXXX| $DCB3
    .byte $10 ; |   X    | $DCB4
    .byte $20 ; |  X     | $DCB5
    .byte $22 ; |  X   X | $DCB6
    .byte $24 ; |  X  X  | $DCB7
    .byte $34 ; |  XX X  | $DCB8
    .byte $32 ; |  XX  X | $DCB9
    .byte $16 ; |   X XX | $DCBA
    .byte $1E ; |   XXXX | $DCBB
    .byte $1C ; |   XXX  | $DCBC
    .byte $1C ; |   XXX  | $DCBD
    .byte $32 ; |  XX  X | $DCBE
    .byte $34 ; |  XX X  | $DCBF
    .byte $76 ; | XXX XX | $DCC0
    .byte $76 ; | XXX XX | $DCC1
    .byte $7E ; | XXXXXX | $DCC2
    .byte $6C ; | XX XX  | $DCC3
    .byte $26 ; |  X  XX | $DCC4
    .byte $2E ; |  X XXX | $DCC5
    .byte $28 ; |  X X   | $DCC6
    .byte $28 ; |  X X   | $DCC7
    .byte $26 ; |  X  XX | $DCC8
    .byte $20 ; |  X     | $DCC9
    .byte $20 ; |  X     | $DCCA
    .byte $20 ; |  X     | $DCCB
    .byte $FF ; |XXXXXXXX| $DCCC
    .byte $00 ; |        | $DCCD
    .byte $80 ; |X       | $DCCE
    .byte $80 ; |X       | $DCCF
    .byte $C3 ; |XX    XX| $DCD0
    .byte $62 ; | XX   X | $DCD1
    .byte $62 ; | XX   X | $DCD2
    .byte $36 ; |  XX XX | $DCD3
    .byte $3E ; |  XXXXX | $DCD4
    .byte $1C ; |   XXX  | $DCD5
    .byte $1C ; |   XXX  | $DCD6
    .byte $32 ; |  XX  X | $DCD7
    .byte $34 ; |  XX X  | $DCD8
    .byte $76 ; | XXX XX | $DCD9
    .byte $76 ; | XXX XX | $DCDA
    .byte $7E ; | XXXXXX | $DCDB
    .byte $6C ; | XX XX  | $DCDC
    .byte $26 ; |  X  XX | $DCDD
    .byte $2E ; |  X XXX | $DCDE
    .byte $28 ; |  X X   | $DCDF
    .byte $28 ; |  X X   | $DCE0
    .byte $26 ; |  X  XX | $DCE1
    .byte $20 ; |  X     | $DCE2
    .byte $20 ; |  X     | $DCE3
    .byte $70 ; | XXX    | $DCE4
    .byte $FF ; |XXXXXXXX| $DCE5
    .byte $00 ; |        | $DCE6
    .byte $00 ; |        | $DCE7
    .byte $00 ; |        | $DCE8
    .byte $00 ; |        | $DCE9
    .byte $00 ; |        | $DCEA
    .byte $33 ; |  XX  XX| $DCEB
    .byte $72 ; | XXX  X | $DCEC
    .byte $DA ; |XX XX X | $DCED
    .byte $1E ; |   XXXX | $DCEE
    .byte $1C ; |   XXX  | $DCEF
    .byte $22 ; |  X   X | $DCF0
    .byte $2E ; |  X XXX | $DCF1
    .byte $76 ; | XXX XX | $DCF2
    .byte $76 ; | XXX XX | $DCF3
    .byte $7E ; | XXXXXX | $DCF4
    .byte $6C ; | XX XX  | $DCF5
    .byte $26 ; |  X  XX | $DCF6
    .byte $2E ; |  X XXX | $DCF7
    .byte $28 ; |  X X   | $DCF8
    .byte $28 ; |  X X   | $DCF9
    .byte $26 ; |  X  XX | $DCFA
    .byte $20 ; |  X     | $DCFB
    .byte $20 ; |  X     | $DCFC
    .byte $F8 ; |XXXXX   | $DCFD
    .byte $FF ; |XXXXXXXX| $DCFE
    .byte $00 ; |        | $DCFF
    .byte $00 ; |        | $DD00
LDD01:
    .byte #COLOR01 ; |X    X  | $DD01
    .byte #COLOR02 ; | X X X  | $DD02
    .byte #COLOR03 ; |  X  X  | $DD03
    .byte #COLOR04 ; |XX   X  | $DD04
    .byte $00 ; |        | $DD05
    .byte #COLOR05 ; |   XXX  | $DD06
    .byte #COLOR06 ; |  X X X | $DD07
    .byte #COLOR07 ; |  X  XX | $DD08
ColHighlightTab:
    .byte $04 ; |     X  | $DD09  ceiling highlights
LDD0A:
    .byte $06 ; |     XX | $DD0A  water highlights
    .byte $08 ; |    X   | $DD0B
    .byte $0A ; |    X X | $DD0C

    .byte $0C ; |    XX  | $DD0D
    .byte $00 ; |        | $DD0E
    .byte $00 ; |        | $DD0F
    .byte $00 ; |        | $DD10
    .byte $00 ; |        | $DD11
    .byte $00 ; |        | $DD12
LDD13:
    .byte #COLOR08 ; |  X     | $DD13  never used??
    .byte #COLOR09 ; |XX      | $DD14  screen 2 #COLOR, screen 1
    .byte #COLOR10 ; |X  X    | $DD15
    .byte $00 ; |        | $DD16
    .byte $00 ; |        | $DD17
    .byte $00 ; |        | $DD18
    .byte $00 ; |        | $DD19
    .byte $00 ; |        | $DD1A
    .byte #COLOR04 ; |XX   X  | $DD1B
    .byte #COLOR11 ; |XX   XX | $DD1C
    .byte #COLOR12 ; |XX  X   | $DD1D
    .byte #COLOR13 ; |XX  X X | $DD1E
    .byte #COLOR12 ; |XX  X   | $DD1F
    .byte #COLOR11 ; |XX   XX | $DD20
    .byte #COLOR04 ; |XX   X  | $DD21
    .byte $00 ; |        | $DD22
    .byte $00 ; |        | $DD23
    .byte $00 ; |        | $DD24
    .byte $00 ; |        | $DD25
    .byte $08 ; |    X   | $DD26

    .byte $08 ; |    X   | $DD27
    .byte $08 ; |    X   | $DD28
    .byte $08 ; |    X   | $DD29
    .byte #COLOR12 ; |XX  X   | $DD2A
    .byte #COLOR12 ; |XX  X   | $DD2B
    .byte #COLOR12 ; |XX  X   | $DD2C
    .byte #COLOR12 ; |XX  X   | $DD2D
    .byte #COLOR14 ; | X  X X | $DD2E
    .byte #COLOR14 ; | X  X X | $DD2F
    .byte #COLOR14 ; | X  X X | $DD30
    .byte $08 ; |    X   | $DD31
    .byte #COLOR15 ; |   XXXX | $DD32
    .byte $00 ; |        | $DD33
    .byte $06 ; |     XX | $DD34
    .byte $08 ; |    X   | $DD35
    .byte $0A ; |    X X | $DD36
    .byte #COLOR16 ; |  X X   | $DD37
    .byte #COLOR07 ; |  X  XX | $DD38
    .byte #COLOR03 ; |  X  X  | $DD39
    .byte #COLOR07 ; |  X  XX | $DD3A
    .byte #COLOR16 ; |  X X   | $DD3B
    .byte $0A ; |    X X | $DD3C
    .byte $08 ; |    X   | $DD3D
    .byte $06 ; |     XX | $DD3E
    .byte $00 ; |        | $DD3F

    .byte $00 ; |        | $DD40
    .byte #COLOR15 ; |   XXXX | $DD41
    .byte #COLOR15 ; |   XXXX | $DD42
    .byte #COLOR15 ; |   XXXX | $DD43
    .byte #COLOR15 ; |   XXXX | $DD44
    .byte #COLOR15 ; |   XXXX | $DD45
    .byte #COLOR15 ; |   XXXX | $DD46
    .byte #COLOR15 ; |   XXXX | $DD47
    .byte #COLOR15 ; |   XXXX | $DD48
    .byte #COLOR15 ; |   XXXX | $DD49
    .byte #COLOR15 ; |   XXXX | $DD4A
    .byte #COLOR15 ; |   XXXX | $DD4B
    .byte #COLOR15 ; |   XXXX | $DD4C

    .byte $00 ; |        | $DD4D
    .byte #COLOR03 ; |  X  X  | $DD4E
    .byte #COLOR03 ; |  X  X  | $DD4F  spider #COLORs
    .byte #COLOR07 ; |  X  XX | $DD50
    .byte #COLOR16 ; |  X X   | $DD51
    .byte #COLOR06 ; |  X X X | $DD52
    .byte #COLOR17 ; |  X XX  | $DD53
    .byte $08 ; |    X   | $DD54
    .byte $08 ; |    X   | $DD55
    .byte $08 ; |    X   | $DD56
    .byte $08 ; |    X   | $DD57
    .byte $08 ; |    X   | $DD58
    .byte $08 ; |    X   | $DD59
    .byte $00 ; |        | $DD5A
    .byte #COLOR16 ; |  X X   | $DD5B
    .byte #COLOR06 ; |  X X X | $DD5C
    .byte #COLOR16 ; |  X X   | $DD5D
    .byte #COLOR07 ; |  X  XX | $DD5E
    .byte #COLOR07 ; |  X  XX | $DD5F
    .byte #COLOR07 ; |  X  XX | $DD60
    .byte #COLOR07 ; |  X  XX | $DD61
    .byte #COLOR16 ; |  X X   | $DD62
    .byte #COLOR06 ; |  X X X | $DD63
    .byte #COLOR06 ; |  X X X | $DD64
    .byte #COLOR06 ; |  X X X | $DD65
    .byte #COLOR06 ; |  X X X | $DD66
    .byte $0C ; |    XX  | $DD67
    .byte $0C ; |    XX  | $DD68
DynamiteDispColTab:
    .byte #COLOR18 ; | X   X  | $DD69
    .byte #COLOR18 ; | X   X  | $DD6A
    .byte #COLOR18 ; | X   X  | $DD6B
    .byte #COLOR18 ; | X   X  | $DD6C
    .byte #COLOR18 ; | X   X  | $DD6D
    .byte #COLOR18 ; | X   X  | $DD6E
    .byte #COLOR05 ; |   XXX  | $DD6F
    .byte #COLOR05 ; |   XXX  | $DD70
    .byte #COLOR05 ; |   XXX  | $DD71
    .byte #COLOR05 ; |   XXX  | $DD72
    .byte #COLOR05 ; |   XXX  | $DD73

    .byte $01 ; |       X| $DD74
    .byte $0D ; |    XX X| $DD75
    .byte $0D ; |    XX X| $DD76
    .byte $0D ; |    XX X| $DD77
    .byte $0D ; |    XX X| $DD78
    .byte $0D ; |    XX X| $DD79
    .byte $0D ; |    XX X| $DD7A
    .byte $0D ; |    XX X| $DD7B
    .byte $0D ; |    XX X| $DD7C
    .byte $0D ; |    XX X| $DD7D
    .byte $0D ; |    XX X| $DD7E
    .byte #COLOR19 ; |X  XX  X| $DD7F
    .byte #COLOR19 ; |X  XX  X| $DD80
    .byte #COLOR19 ; |X  XX  X| $DD81
    .byte #COLOR19 ; |X  XX  X| $DD82
    .byte #COLOR19 ; |X  XX  X| $DD83
    .byte #COLOR19 ; |X  XX  X| $DD84
    .byte #COLOR20 ; | X   X X| $DD85
    .byte #COLOR20 ; | X   X X| $DD86
    .byte #COLOR20 ; | X   X X| $DD87
    .byte #COLOR21 ; | X   XXX| $DD88
    .byte #COLOR20 ; | X   X X| $DD89
    .byte #COLOR22 ; |   XXX X| $DD8A
    .byte #COLOR22 ; |   XXX X| $DD8B
    .byte #COLOR22 ; |   XXX X| $DD8C

    .byte $01 ; |       X| $DD8D
    .byte $00 ; |        | $DD8E
    .byte #COLOR15 ; |   XXXX | $DD8F
    .byte #COLOR15 ; |   XXXX | $DD90
    .byte $06 ; |     XX | $DD91
    .byte #COLOR15 ; |   XXXX | $DD92

    .byte $06 ; |     XX | $DD93
    .byte $06 ; |     XX | $DD94
    .byte $06 ; |     XX | $DD95
    .byte $06 ; |     XX | $DD96
    .byte $06 ; |     XX | $DD97
    .byte $00 ; |        | $DD98
    .byte $00 ; |        | $DD99
    .byte $00 ; |        | $DD9A
    .byte $00 ; |        | $DD9B
    .byte $04 ; |     X  | $DD9C
    .byte $04 ; |     X  | $DD9D
    .byte $04 ; |     X  | $DD9E
    .byte $04 ; |     X  | $DD9F
    .byte $04 ; |     X  | $DDA0
    .byte $04 ; |     X  | $DDA1
    .byte $04 ; |     X  | $DDA2
    .byte $04 ; |     X  | $DDA3
    .byte $04 ; |     X  | $DDA4
    .byte $04 ; |     X  | $DDA5
    .byte $04 ; |     X  | $DDA6
    .byte $04 ; |     X  | $DDA7
    .byte $00 ; |        | $DDA8
LivesGfx:
    .byte $10 ; |   X    | $DDA9
    .byte $10 ; |   X    | $DDAA
    .byte $18 ; |   XX   | $DDAB
    .byte $08 ; |    X   | $DDAC
    .byte $08 ; |    X   | $DDAD
    .byte $14 ; |   X X  | $DDAE
    .byte $14 ; |   X X  | $DDAF
    .byte $34 ; |  XX X  | $DDB0
    .byte $28 ; |  X X   | $DDB1
    .byte $2C ; |  X XX  | $DDB2
    .byte $2C ; |  X XX  | $DDB3
    .byte $20 ; |  X     | $DDB4
    .byte $70 ; | XXX    | $DDB5

    .byte $0C ; |    XX  | $DDB6
LivesColTab:
    .byte $0C ; |    XX  | $DDB7
    .byte $0C ; |    XX  | $DDB8
    .byte $0C ; |    XX  | $DDB9
    .byte $0C ; |    XX  | $DDBA
    .byte $0C ; |    XX  | $DDBB
    .byte #COLOR23 ; |X  X X  | $DDBC
    .byte #COLOR23 ; |X  X X  | $DDBD
    .byte #COLOR23 ; |X  X X  | $DDBE
    .byte #COLOR23 ; |X  X X  | $DDBF
    .byte #COLOR24 ; | X   XX | $DDC0
    .byte #COLOR24 ; | X   XX | $DDC1
    .byte #COLOR05 ; |   XXX  | $DDC2
    .byte #COLOR05 ; |   XXX  | $DDC3
    .byte #COLOR25 ; |X X X X | $DDC4
    .byte #COLOR25 ; |X X X X | $DDC5
    .byte #COLOR25 ; |X X X X | $DDC6
    .byte #COLOR25 ; |X X X X | $DDC7
    .byte #COLOR25 ; |X X X X | $DDC8
    .byte #COLOR25 ; |X X X X | $DDC9
    .byte #COLOR25 ; |X X X X | $DDCA
    .byte #COLOR25 ; |X X X X | $DDCB
    .byte #COLOR25 ; |X X X X | $DDCC
    .byte #COLOR25 ; |X X X X | $DDCD
    .byte #COLOR25 ; |X X X X | $DDCE
    .byte #COLOR25 ; |X X X X | $DDCF
    .byte #COLOR25 ; |X X X X | $DDD0
    .byte $00 ; |        | $DDD1
    .byte $00 ; |        | $DDD2
    .byte $00 ; |        | $DDD3
    .byte $00 ; |        | $DDD4
    .byte $00 ; |        | $DDD5
    .byte $00 ; |        | $DDD6
    .byte $00 ; |        | $DDD7
    .byte $00 ; |        | $DDD8
    .byte $00 ; |        | $DDD9
    .byte $00 ; |        | $DDDA
    .byte $00 ; |        | $DDDB
    .byte $00 ; |        | $DDDC
    .byte $00 ; |        | $DDDD
    .byte $00 ; |        | $DDDE
    .byte $00 ; |        | $DDDF
    .byte $00 ; |        | $DDE0
    .byte $00 ; |        | $DDE1
    .byte $00 ; |        | $DDE2
    .byte $00 ; |        | $DDE3
    .byte $00 ; |        | $DDE4
    .byte $00 ; |        | $DDE5
    .byte $00 ; |        | $DDE6
    .byte $00 ; |        | $DDE7
    .byte $00 ; |        | $DDE8
    .byte $00 ; |        | $DDE9
    .byte $00 ; |        | $DDEA
    .byte $00 ; |        | $DDEB
LDDEC:
 IF NTSC
    .byte $84 ; |X    X  | $DDEC
    .byte $D6 ; |XX X XX | $DDED
    .byte $D6 ; |XX X XX | $DDEE
    .byte $1A ; |   XX X | $DDEF
    .byte $26 ; |  X  XX | $DDF0
    .byte $26 ; |  X  XX | $DDF1
    .byte $44 ; | X   X  | $DDF2
 ELSE
	.byte $B4 ; BLUE
	.byte $56 ; GREEN
	.byte $56 ; GREEN
	.byte $2A ; SAND
	.byte $46 ; LIGHT_BROWN
	.byte $46 ; LIGHT_BROWN
	.byte $64
 ENDIF

    .byte $00 ; |        | $DDF3
    .byte $00 ; |        | $DDF4
    .byte $00 ; |        | $DDF5
    .byte $00 ; |        | $DDF6
    .byte $00 ; |        | $DDF7
    .byte $00 ; |        | $DDF8
    .byte $00 ; |        | $DDF9
    .byte $00 ; |        | $DDFA
    .byte $00 ; |        | $DDFB
    .byte $00 ; |        | $DDFC
    .byte $00 ; |        | $DDFD
    .byte $00 ; |        | $DDFE
    .byte $00 ; |        | $DDFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawScore SUBROUTINE ;x1
    lda    #7                    ; 2
DrawLogo SUBROUTINE ;x1
    ldy    #$00                  ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    sta    ram_BC                ; 3
    lda    #$07                  ; 2
    sta    VDELP0                ; 3
    sta    VDELP1                ; 3
    sty    GRP0                  ; 3
    sty    GRP1                  ; 3
    sty    GRP0                  ; 3
    sta    REFP0                 ; 3
    sta    REFP1                 ; 3
    lsr                          ; 2
    sta    NUSIZ0                ; 3
    sta    RESP0                 ; 3
    sta    RESP1                 ; 3
    sta.w  RESBL                 ; 4
    sta    NUSIZ1                ; 3
    lda    #$90                  ; 2
    sta    HMP1                  ; 3
    lda    #$80                  ; 2
    sta    HMP0                  ; 3
    nop                          ; 2
    nop                          ; 2
LDE30:
    ldy    ram_BC                ; 3
    lda    (ram_8D),Y            ; 5
    tax                          ; 2
    lda    (ram_8F),Y            ; 5
    sta    HMOVE                 ; 3
    sta    ram_BB                ; 3
    lda    (ram_85),Y            ; 5
    sta    GRP0                  ; 3
    lda    (ram_87),Y            ; 5
    sta    GRP1                  ; 3
    lda    (ram_89),Y            ; 5
    sta    HMCLR                 ; 3
    sta    GRP0                  ; 3
    lda    (ram_8B),Y            ; 5
    ldy    ram_BB                ; 3
    sta    GRP1                  ; 3
    stx    GRP0                  ; 3
    sty    GRP1                  ; 3
    sty    GRP0                  ; 3
    dec    ram_BC                ; 5
    bpl    LDE30                 ; 2³
    lda    #$80                  ; 2
    sta    HMP0                  ; 3
    sta    HMP1                  ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    asl                          ; 2
    sta    GRP0                  ; 3
    sta    GRP1                  ; 3
    sta    GRP0                  ; 3
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LDE6B SUBROUTINE ;x3
    stx    ram_AE                ; 3
    lda    #$FF                  ; 2
    sta    ram_AD                ; 3
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    XXX XXX X   X XXX XXX
;    X X X X X X X X   X X
;    XXX X X XXXXX XX  XX
;    X   X X XX XX X   X X
;    X   XXX X   X XXX X X
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOne:
    .byte $23 ; |  X   XX| $DE72
    .byte $22 ; |  X   X | $DE73
    .byte $3A ; |  XXX X | $DE74
    .byte $2A ; |  X X X | $DE75
    .byte $3B ; |  XXX XX| $DE76
PowerTwo:
    .byte $A2 ; |X X   X | $DE77
    .byte $B6 ; |X XX XX | $DE78
    .byte $BE ; |X XXXXX | $DE79
    .byte $AA ; |X X X X | $DE7A
    .byte $A2 ; |X X   X | $DE7B
PowerThree:
    .byte $EA ; |XXX X X | $DE7C
    .byte $8A ; |X   X X | $DE7D
    .byte $CC ; |XX  XX  | $DE7E
    .byte $8A ; |X   X X | $DE7F
    .byte $EE ; |XXX XXX | $DE80


    .byte $FF ; |XXXXXXXX| $DE81
    .byte $10 ; |   X    | $DE82
    .byte $10 ; |   X    | $DE83
    .byte $10 ; |   X    | $DE84
    .byte $18 ; |   XX   | $DE85
    .byte $18 ; |   XX   | $DE86
    .byte $08 ; |    X   | $DE87
    .byte $08 ; |    X   | $DE88
    .byte $0C ; |    XX  | $DE89
    .byte $0C ; |    XX  | $DE8A
    .byte $1C ; |   XXX  | $DE8B
    .byte $32 ; |  XX  X | $DE8C
    .byte $34 ; |  XX X  | $DE8D
    .byte $76 ; | XXX XX | $DE8E
    .byte $76 ; | XXX XX | $DE8F
    .byte $7E ; | XXXXXX | $DE90
    .byte $6C ; | XX XX  | $DE91
    .byte $26 ; |  X  XX | $DE92
    .byte $2E ; |  X XXX | $DE93
    .byte $28 ; |  X X   | $DE94
    .byte $28 ; |  X X   | $DE95
    .byte $26 ; |  X  XX | $DE96
    .byte $20 ; |  X     | $DE97
    .byte $20 ; |  X     | $DE98
    .byte $F8 ; |XXXXX   | $DE99
    .byte $FF ; |XXXXXXXX| $DE9A
    .byte $10 ; |   X    | $DE9B
    .byte $10 ; |   X    | $DE9C
    .byte $10 ; |   X    | $DE9D
    .byte $18 ; |   XX   | $DE9E
    .byte $18 ; |   XX   | $DE9F
    .byte $08 ; |    X   | $DEA0
    .byte $08 ; |    X   | $DEA1
    .byte $0C ; |    XX  | $DEA2
    .byte $0C ; |    XX  | $DEA3
    .byte $1C ; |   XXX  | $DEA4
    .byte $32 ; |  XX  X | $DEA5
    .byte $34 ; |  XX X  | $DEA6
    .byte $76 ; | XXX XX | $DEA7
    .byte $76 ; | XXX XX | $DEA8
    .byte $7E ; | XXXXXX | $DEA9
    .byte $6C ; | XX XX  | $DEAA
    .byte $26 ; |  X  XX | $DEAB
    .byte $2E ; |  X XXX | $DEAC
    .byte $28 ; |  X X   | $DEAD
    .byte $28 ; |  X X   | $DEAE
    .byte $26 ; |  X  XX | $DEAF
    .byte $20 ; |  X     | $DEB0
    .byte $20 ; |  X     | $DEB1
    .byte $70 ; | XXX    | $DEB2
    .byte $FF ; |XXXXXXXX| $DEB3
    .byte $10 ; |   X    | $DEB4
    .byte $10 ; |   X    | $DEB5
    .byte $10 ; |   X    | $DEB6
    .byte $18 ; |   XX   | $DEB7
    .byte $18 ; |   XX   | $DEB8
    .byte $08 ; |    X   | $DEB9
    .byte $08 ; |    X   | $DEBA
    .byte $0C ; |    XX  | $DEBB
    .byte $0C ; |    XX  | $DEBC
    .byte $1C ; |   XXX  | $DEBD
    .byte $32 ; |  XX  X | $DEBE
    .byte $34 ; |  XX X  | $DEBF
    .byte $76 ; | XXX XX | $DEC0
    .byte $76 ; | XXX XX | $DEC1
    .byte $7E ; | XXXXXX | $DEC2
    .byte $6C ; | XX XX  | $DEC3
    .byte $26 ; |  X  XX | $DEC4
    .byte $2E ; |  X XXX | $DEC5
    .byte $28 ; |  X X   | $DEC6
    .byte $28 ; |  X X   | $DEC7
    .byte $26 ; |  X  XX | $DEC8
    .byte $20 ; |  X     | $DEC9
    .byte $20 ; |  X     | $DECA
    .byte $20 ; |  X     | $DECB
    .byte $FF ; |XXXXXXXX| $DECC
    .byte $0E ; |    XXX | $DECD
    .byte $0C ; |    XX  | $DECE
    .byte $0C ; |    XX  | $DECF
    .byte $0C ; |    XX  | $DED0
    .byte $0C ; |    XX  | $DED1
    .byte $0C ; |    XX  | $DED2
    .byte $0C ; |    XX  | $DED3
    .byte $0C ; |    XX  | $DED4
    .byte $0C ; |    XX  | $DED5
    .byte $1C ; |   XXX  | $DED6
    .byte $22 ; |  X   X | $DED7
    .byte $2E ; |  X XXX | $DED8
    .byte $76 ; | XXX XX | $DED9
    .byte $76 ; | XXX XX | $DEDA
    .byte $7E ; | XXXXXX | $DEDB
    .byte $6C ; | XX XX  | $DEDC
    .byte $26 ; |  X  XX | $DEDD
    .byte $2E ; |  X XXX | $DEDE
    .byte $28 ; |  X X   | $DEDF
    .byte $28 ; |  X X   | $DEE0
    .byte $26 ; |  X  XX | $DEE1
    .byte $20 ; |  X     | $DEE2
    .byte $20 ; |  X     | $DEE3
    .byte $70 ; | XXX    | $DEE4
    .byte $FF ; |XXXXXXXX| $DEE5
    .byte $00 ; |        | $DEE6
    .byte $10 ; |   X    | $DEE7
    .byte $10 ; |   X    | $DEE8
    .byte $10 ; |   X    | $DEE9
    .byte $18 ; |   XX   | $DEEA
    .byte $18 ; |   XX   | $DEEB
    .byte $08 ; |    X   | $DEEC
    .byte $08 ; |    X   | $DEED
    .byte $0C ; |    XX  | $DEEE
    .byte $0C ; |    XX  | $DEEF
    .byte $1C ; |   XXX  | $DEF0
    .byte $32 ; |  XX  X | $DEF1
    .byte $34 ; |  XX X  | $DEF2
    .byte $76 ; | XXX XX | $DEF3
    .byte $76 ; | XXX XX | $DEF4
    .byte $7E ; | XXXXXX | $DEF5
    .byte $6C ; | XX XX  | $DEF6
    .byte $26 ; |  X  XX | $DEF7
    .byte $2E ; |  X XXX | $DEF8
    .byte $28 ; |  X X   | $DEF9
    .byte $28 ; |  X X   | $DEFA
    .byte $26 ; |  X  XX | $DEFB
    .byte $20 ; |  X     | $DEFC
    .byte $20 ; |  X     | $DEFD
    .byte $70 ; | XXX    | $DEFE
    .byte $00 ; |        | $DEFF

       ORG $0F00
      RORG $DF00

Zero:
    .byte $3C ; |  XXXX  | $DF00
    .byte $66 ; | XX  XX | $DF01
    .byte $66 ; | XX  XX | $DF02
    .byte $66 ; | XX  XX | $DF03
    .byte $66 ; | XX  XX | $DF04
    .byte $66 ; | XX  XX | $DF05
    .byte $66 ; | XX  XX | $DF06
    .byte $3C ; |  XXXX  | $DF07
One:
    .byte $3C ; |  XXXX  | $DF08
    .byte $18 ; |   XX   | $DF09
    .byte $18 ; |   XX   | $DF0A
    .byte $18 ; |   XX   | $DF0B
    .byte $18 ; |   XX   | $DF0C
    .byte $18 ; |   XX   | $DF0D
    .byte $38 ; |  XXX   | $DF0E
    .byte $18 ; |   XX   | $DF0F
Two:
    .byte $7E ; | XXXXXX | $DF10
    .byte $60 ; | XX     | $DF11
    .byte $60 ; | XX     | $DF12
    .byte $3C ; |  XXXX  | $DF13
    .byte $06 ; |     XX | $DF14
    .byte $06 ; |     XX | $DF15
    .byte $46 ; | X   XX | $DF16
    .byte $3C ; |  XXXX  | $DF17
Three:
    .byte $3C ; |  XXXX  | $DF18
    .byte $46 ; | X   XX | $DF19
    .byte $06 ; |     XX | $DF1A
    .byte $0C ; |    XX  | $DF1B
    .byte $0C ; |    XX  | $DF1C
    .byte $06 ; |     XX | $DF1D
    .byte $46 ; | X   XX | $DF1E
    .byte $3C ; |  XXXX  | $DF1F
Four:
    .byte $0C ; |    XX  | $DF20
    .byte $0C ; |    XX  | $DF21
    .byte $0C ; |    XX  | $DF22
    .byte $7E ; | XXXXXX | $DF23
    .byte $4C ; | X  XX  | $DF24
    .byte $2C ; |  X XX  | $DF25
    .byte $1C ; |   XXX  | $DF26
    .byte $0C ; |    XX  | $DF27
Five:
    .byte $7C ; | XXXXX  | $DF28
    .byte $46 ; | X   XX | $DF29
    .byte $06 ; |     XX | $DF2A
    .byte $06 ; |     XX | $DF2B
    .byte $7C ; | XXXXX  | $DF2C
    .byte $60 ; | XX     | $DF2D
    .byte $60 ; | XX     | $DF2E
    .byte $7E ; | XXXXXX | $DF2F
Six:
    .byte $3C ; |  XXXX  | $DF30
    .byte $66 ; | XX  XX | $DF31
    .byte $66 ; | XX  XX | $DF32
    .byte $66 ; | XX  XX | $DF33
    .byte $7C ; | XXXXX  | $DF34
    .byte $60 ; | XX     | $DF35
    .byte $62 ; | XX   X | $DF36
    .byte $3C ; |  XXXX  | $DF37
Seven:
    .byte $18 ; |   XX   | $DF38
    .byte $18 ; |   XX   | $DF39
    .byte $18 ; |   XX   | $DF3A
    .byte $18 ; |   XX   | $DF3B
    .byte $0C ; |    XX  | $DF3C
    .byte $06 ; |     XX | $DF3D
    .byte $42 ; | X    X | $DF3E
    .byte $7E ; | XXXXXX | $DF3F
Eight:
    .byte $3C ; |  XXXX  | $DF40
    .byte $66 ; | XX  XX | $DF41
    .byte $66 ; | XX  XX | $DF42
    .byte $3C ; |  XXXX  | $DF43
    .byte $3C ; |  XXXX  | $DF44
    .byte $66 ; | XX  XX | $DF45
    .byte $66 ; | XX  XX | $DF46
    .byte $3C ; |  XXXX  | $DF47
Nine:
    .byte $3C ; |  XXXX  | $DF48
    .byte $46 ; | X   XX | $DF49
    .byte $06 ; |     XX | $DF4A
    .byte $3E ; |  XXXXX | $DF4B
    .byte $66 ; | XX  XX | $DF4C
    .byte $66 ; | XX  XX | $DF4D
    .byte $66 ; | XX  XX | $DF4E
    .byte $3C ; |  XXXX  | $DF4F
BlankDigit:
    .byte $00 ; |        | $DF50
    .byte $00 ; |        | $DF51
    .byte $00 ; |        | $DF52
    .byte $00 ; |        | $DF53
    .byte $00 ; |        | $DF54
    .byte $00 ; |        | $DF55
    .byte $00 ; |        | $DF56
    .byte $00 ; |        | $DF57
Exclamation_Mark:
    .byte $FF ; |XXXXXXXX| $DF58
    .byte $E7 ; |XXX  XXX| $DF59
    .byte $FF ; |XXXXXXXX| $DF5A
    .byte $E7 ; |XXX  XXX| $DF5B
    .byte $E7 ; |XXX  XXX| $DF5C
    .byte $E7 ; |XXX  XXX| $DF5D
    .byte $E7 ; |XXX  XXX| $DF5E
    .byte $FF ; |XXXXXXXX| $DF5F

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    XX   XXXX XX XX XXXX XX   XX
;    XX   XXXX XX XX XXXX XX   XX
;    XX   XX   XX XX XX   XX   XX
;    XX   XXX  XX XX XXX  XX
;    XX   XXX  XX XX XXX  XX
;    XX   XX    XXX  XX   XX   XX
;    XXXX XXXX  XXX  XXXX XXXX XX
;    XXXX XXXX   X   XXXX XXXX XX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LevelGfxOne:
    .byte $1E ; |   XXXX | $DF60
    .byte $1E ; |   XXXX | $DF61
    .byte $18 ; |   XX   | $DF62
    .byte $18 ; |   XX   | $DF63
    .byte $18 ; |   XX   | $DF64
    .byte $18 ; |   XX   | $DF65
    .byte $18 ; |   XX   | $DF66
    .byte $18 ; |   XX   | $DF67
LevelGfxTwo:
    .byte $F1 ; |XXXX   X| $DF68
    .byte $F3 ; |XXXX  XX| $DF69
    .byte $C3 ; |XX    XX| $DF6A
    .byte $E6 ; |XXX  XX | $DF6B
    .byte $E6 ; |XXX  XX | $DF6C
    .byte $C6 ; |XX   XX | $DF6D
    .byte $F6 ; |XXXX XX | $DF6E
    .byte $F6 ; |XXXX XX | $DF6F
LevelGfxThree:
    .byte $1E ; |   XXXX | $DF70
    .byte $9E ; |X  XXXX | $DF71
    .byte $98 ; |X  XX   | $DF72
    .byte $DC ; |XX XXX  | $DF73
    .byte $DC ; |XX XXX  | $DF74
    .byte $D8 ; |XX XX   | $DF75
    .byte $DE ; |XX XXXX | $DF76
    .byte $DE ; |XX XXXX | $DF77
LevelGfxFour:
    .byte $F6 ; |XXXX XX | $DF78
    .byte $F6 ; |XXXX XX | $DF79
    .byte $C6 ; |XX   XX | $DF7A
    .byte $C0 ; |XX      | $DF7B
    .byte $C0 ; |XX      | $DF7C
    .byte $C6 ; |XX   XX | $DF7D
    .byte $C6 ; |XX   XX | $DF7E
    .byte $C6 ; |XX   XX | $DF7F

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;          X XXXXXXXX    XXXXXXX
;         XX    X   X   XX
;        XXX XX X X X  XX  XXX X XXX X  X
;       XX X X  X X X XX X X   X X X XX X
;      XXXXX X  X X XXX  X XXX X X X XXXX
;     XX   X X  X X XX   X   X X X X X XX
;    XX    X XX X X X    X XXX X XXX X  X
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LogoOne:
    .byte $0C ; |    XX  | $DF80
    .byte $06 ; |     XX | $DF81
    .byte $03 ; |      XX| $DF82
    .byte $01 ; |       X| $DF83
    .byte $00 ; |        | $DF84
    .byte $00 ; |        | $DF85
    .byte $00 ; |        | $DF86
    .byte $00 ; |        | $DF87
LogoTwo:
    .byte $2D ; |  X XX X| $DF88
    .byte $29 ; |  X X  X| $DF89
    .byte $E9 ; |XXX X  X| $DF8A
    .byte $A9 ; |X X X  X| $DF8B
    .byte $ED ; |XXX XX X| $DF8C
    .byte $61 ; | XX    X| $DF8D
    .byte $2F ; |  X XXXX| $DF8E
    .byte $00 ; |        | $DF8F
LogoThree:
    .byte $50 ; | X X    | $DF90
    .byte $58 ; | X XX   | $DF91
    .byte $5C ; | X XXX  | $DF92
    .byte $56 ; | X X XX | $DF93
    .byte $53 ; | X X  XX| $DF94
    .byte $11 ; |   X   X| $DF95
    .byte $F0 ; |XXXX    | $DF96
    .byte $00 ; |        | $DF97
LogoFour:
    .byte $BA ; |X XXX X | $DF98
    .byte $8A ; |X   X X | $DF99
    .byte $BA ; |X XXX X | $DF9A
    .byte $A2 ; |X X   X | $DF9B
    .byte $3A ; |  XXX X | $DF9C
    .byte $80 ; |X       | $DF9D
    .byte $FE ; |XXXXXXX | $DF9E
    .byte $00 ; |        | $DF9F
LogoFive:
    .byte $E9 ; |XXX X  X| $DFA0
    .byte $AB ; |X X X XX| $DFA1
    .byte $AF ; |X X XXXX| $DFA2
    .byte $AD ; |X X XX X| $DFA3
    .byte $E9 ; |XXX X  X| $DFA4
    .byte $00 ; |        | $DFA5
    .byte $00 ; |        | $DFA6
    .byte $00 ; |        | $DFA7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    XXXX                X     X   X    X XXX XXX X X
;    X  X                      X  XXX   X X X X X X X
;    X    XXX XXX X X XX X XXX XXX X    X XXX XXX XXX
;    X  X X X X X X X X  X X X X X X    X   X X X   X
;    XXXX XXX XXX XXX X  X XXX X X X    X   X XXX   X
;             X     X        X
;             X   XXX      XXX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyrightOne:
    .byte $00 ; |        | $DFA8
    .byte $00 ; |        | $DFA9
    .byte $00 ; |        | $DFAA
    .byte $F7 ; |XXXX XXX| $DFAB
    .byte $95 ; |X  X X X| $DFAC
    .byte $87 ; |X    XXX| $DFAD
    .byte $90 ; |X  X    | $DFAE
    .byte $F0 ; |XXXX    | $DFAF
CopyrightTwo:
    .byte $00 ; |        | $DFB0
    .byte $47 ; | X   XXX| $DFB1
    .byte $41 ; | X     X| $DFB2
    .byte $77 ; | XXX XXX| $DFB3
    .byte $55 ; | X X X X| $DFB4
    .byte $75 ; | XXX X X| $DFB5
    .byte $00 ; |        | $DFB6
    .byte $00 ; |        | $DFB7
CopyrightThree:
    .byte $00 ; |        | $DFB8
    .byte $03 ; |      XX| $DFB9
    .byte $00 ; |        | $DFBA
    .byte $4B ; | X  X XX| $DFBB
    .byte $4A ; | X  X X | $DFBC
    .byte $6B ; | XX X XX| $DFBD
    .byte $00 ; |        | $DFBE
    .byte $08 ; |    X   | $DFBF
CopyrightFour:
    .byte $00 ; |        | $DFC0
    .byte $80 ; |X       | $DFC1
    .byte $80 ; |X       | $DFC2
    .byte $AA ; |X X X X | $DFC3
    .byte $AA ; |X X X X | $DFC4
    .byte $BA ; |X XXX X | $DFC5
    .byte $27 ; |  X  XXX| $DFC6
    .byte $22 ; |  X   X | $DFC7
CopyrightFive:
    .byte $00 ; |        | $DFC8
    .byte $00 ; |        | $DFC9
    .byte $00 ; |        | $DFCA
    .byte $11 ; |   X   X| $DFCB
    .byte $11 ; |   X   X| $DFCC
    .byte $17 ; |   X XXX| $DFCD
    .byte $15 ; |   X X X| $DFCE
    .byte $17 ; |   X XXX| $DFCF
CopyrightSix:
    .byte $00 ; |        | $DFD0
    .byte $00 ; |        | $DFD1
    .byte $00 ; |        | $DFD2
    .byte $71 ; | XXX   X| $DFD3
    .byte $51 ; | X X   X| $DFD4
    .byte $77 ; | XXX XXX| $DFD5
    .byte $55 ; | X X X X| $DFD6
    .byte $75 ; | XXX X X| $DFD7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    XXX  XXXX   XXX
;    XXXX XXXXX XX XX
;    XX X XX XX XX XX
;    XX X XX XX XX XX
;    XXXX XXXX  XX XX
;    XXX  XXXX  XX XX
;    XX   XX XX XX XX
;    XX   XX XX  XXX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProGfxOne:
    .byte $C6 ; |XX   XX | $DFD8
    .byte $C6 ; |XX   XX | $DFD9
    .byte $E7 ; |XXX  XXX| $DFDA
    .byte $F7 ; |XXXX XXX| $DFDB
    .byte $D6 ; |XX X XX | $DFDC
    .byte $D6 ; |XX X XX | $DFDD
    .byte $F7 ; |XXXX XXX| $DFDE
    .byte $E7 ; |XXX  XXX| $DFDF
ProGfxTwo:
    .byte $CE ; |XX  XXX | $DFE0
    .byte $DB ; |XX XX XX| $DFE1
    .byte $9B ; |X  XX XX| $DFE2
    .byte $9B ; |X  XX XX| $DFE3
 IF PLUSROM
       ORG $0FE4
      RORG $DFE4
 ELSE
    .byte $DB ; |XX XX XX| $DFE4
    .byte $DB ; |XX XX XX| $DFE5
    .byte $DB ; |XX XX XX| $DFE6
    .byte $8E ; |X   XXX | $DFE7



    .byte $00 ; |        | $DFE8   free bytes
    .byte $00 ; |        | $DFE9
    .byte $00 ; |        | $DFEA
    .byte $00 ; |        | $DFEB

       ORG $0FEC
      RORG $DFEC
 ENDIF

LDFEC:
    ldx    #$FF                  ; 2
    txs                          ; 2
    jmp    LD079                 ; 3

LDFF2:
    bit    BANK_1                ; 4
    jsr    LFFF2                 ; 6

 IF PLUSROM
       ORG $0FFA
      RORG $DFFA
    .word $2FAB
 ELSE
    nop                          ; 2
  IF NTSC
    nop                          ; 2
  ELSE
    .byte $FF
  ENDIF
    nop                          ; 2
    nop                          ; 2
 ENDIF
    .word START_0
    .word START_0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      BANK 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

       ORG $1000
      RORG $F000

START_1:
    sei                          ; 
    sta    BANK_1                ;     space filler, align banks to same point
    cld                          ;  
    ldx    #0                    ; 
Reset:
    lda    #0                    ;     X=$00,$B4,$BA
.loopClear:
    sta    0,X                   ; 
    txs                          ; 
    inx                          ; 
    bne    .loopClear            ; 
    
    lda    ram_B6                ; 3
    bne    .chooseGameVariation  ; 2³  save "PRO" flag, start at level 1
    lda    gameSelect            ;
    and    #$7F                  ;     clear "PRO" flag,
    sta    gameSelect            ;     and find level to start on..
    tax                          ; 
.chooseGameVariation:
    lda    SelectLevelTab,X      ;
    sta    levelNum              ;     $00,$04,$08,$0C,$10
    ldx    #24                   ;
.loopInitializeRam:
    lda    InitializeTab,X       ;
    sta    hPosHERO,X            ;
    dex                          ;
    bpl    .loopInitializeRam    ;
;---------------------------------------
; no effect
;---------------------------------------
    lda    levelNum              ;     $00,$04,$08,$0C,$10
    and    #$03                  ;     A=0
    tax                          ;     X=0
    lda    LFF6A,X               ;  
    sta    ram_A4                ;     #$20, which already done by initialization tab!
;---------------------------------------
; test randomizer
;---------------------------------------
    ldx    randomizer            ; 3
    beq    LF03A                 ; 2³
    jmp    LF0BA                 ; 3

LF03A:
    inx                          ;     X=1
    stx    randomizer            ; 
    dec    ram_BA                ; 5
    jmp    SetupGameVarDisplay   ; 3

LF042:
    ldy    SWCHA                 ;     get joystick
    lda    frameCounter          ;     
    and    #$07                  ; 
    bne    .testDirections       ;
    lda    ram_B6                ;     8th frame yet?
    beq    .testDirections       ;     - no
    ldy    #$FF                  ;     - yes, ignore directions 

 IF PLUSROM
    lda    #16                   ;     test gameSelect bit 4
    bit    gameSelect
    beq    skipSendScore
    jsr    SendPlusROMScore
skipSendScore
 ENDIF

    dec    ram_B6                ;     - decrement big count
    bne    .testDirections       ; 2³
    dec    ram_B6                ; 5
    lda    ram_B5                ; 3
    bmi    .testDirections       ; 2³
    ora    #$80                  ; 2
    sta    ram_B5                ; 3
    ldx    #$BA                  ; 2   wipe out score
    bne    LF07B                 ; 3   always branch

.testDirections:
    tya                          ; 2
    and    #$F0                  ; 2
    sta    ram_84                ; 3
    iny                          ; 2
    beq    LF06F                 ; 2³
    lda    #$00                  ; 2
    sta    ram_B4                ; 3
LF06F:
    lda    ram_FB                ; 3
    nop                          ; 2
    lsr                          ; 2
    bcs    LF07E                 ; 2³
    lda    #$00                  ; 2
    sta    ram_BA                ; 3
    ldx    #$B4                  ; 2   save score, etc...
LF07B:
    jmp    Reset                 ; 3

LF07E:
    ldy    #$00                  ; 2
    lsr                          ; 2
    bcs    LF0B8                 ; 2³
    lda    #$FF                  ; 2
    sta    ram_BA                ; 3
    sta    ram_AD                ; 3
    lda    ram_83                ; 3
    beq    LF091                 ; 2³
    dec    ram_83                ; 5
    bpl    LF0BA                 ; 2³
LF091:
    inc    gameSelect            ; 5
SetupGameVarDisplay:
    lda    gameSelect            ;
    and    #$7F                  ;     ignore "PRO" flag,
    cmp    #5                    ;     has game selection scrolled past "5"?
    bcc    LF0A2                 ;     - no
    lda    #$80                  ;     - yes, rest to "1", and save the "PRO" flag setting
    and    gameSelect            ;  
    sta    gameSelect            ;  
    asl                          ;     A=0
LF0A2:
    sta    ram_B4                ;     0-4
    sta    ram_B5                ;
    ora    #(<BlankDigit <<1)    ;     game variation
    tay                          ; 
    iny                          ;     correct the display
    sty    scoreBCD+2            ;     shared for game variation display
    lda    #(<BlankDigit <<1) | (<BlankDigit >>3) ;
    sta    scoreBCD              ;
    sta    scoreBCD+1            ;
    lda    #$1F                  ; 2
    sta    ram_B6                ; 3
    ldy    #$1E                  ; 2
LF0B8:
    sty    ram_83                ; 3
LF0BA:
    lda    ram_AD                ; 3
    ora    ram_F2                ; 3
    ora    ram_F7                ; 3
    ora    ram_F8                ; 3
    bne    LF0C6                 ; 2³
    inc    ram_F6                ; 5
LF0C6:
    lda    randomizer            ; 3
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    eor    randomizer            ; 3
    asl                          ; 2
    rol    randomizer            ; 5
    lda    ram_B6                ; 3
    beq    LF106                 ; 2³+1
    bit    ram_B4                ; 3
    bpl    LF0DB                 ; 2³
    jmp    LF282                 ; 3

LF0DB:
    jsr    LF630                 ; 6
    ldx    LFF42,Y               ; 4
    lda    ram_AC                ; 3
    beq    LF104                 ; 2³+1
    lda    ram_DF                ; 3
    beq    LF0F3                 ; 2³
    cmp    #$2C                  ; 2
    bcc    LF104                 ; 2³+1
    ldx    LFF56,Y               ; 4
    jmp    LF104                 ; 3

LF0F3:
    lda    ram_A0                ; 3
    sec                          ; 2
    sbc    #$0F                  ; 2
    cmp    hPosHERO              ; 3
    bcs    LF104                 ; 2³+1
    adc    #$17                  ; 2
    cmp    hPosHERO              ; 3
    bcc    LF104                 ; 2³
    ldx    #$D0                  ; 2
LF104:
    stx    ram_84                ; 3
LF106:
    lda    #$00                  ; 2
    sta    ram_BD                ; 3
    lda    ram_D8                ; 3
    cmp    #<Raft                ; 2
    bne    LF14B                 ; 2³
    lda    ram_AD                ; 3
    bne    LF14B                 ; 2³
    lda    roomNum               ; 3
    cmp    #$0B                  ; 2
    bcc    LF14B                 ; 2³
    bit    CXPPMM                ; 3
    bpl    LF14B                 ; 2³
    lda    ram_EC                ; 3
    and    #$7F                  ; 2
    clc                          ; 2
    adc    #$18                  ; 2
    sta    ram_BB                ; 3
    lda    hPosHERO              ; 3
    sec                          ; 2
    sbc    ram_BB                ; 3
    cmp    #$09                  ; 2
    bcs    LF14B                 ; 2³
    lda    #$40                  ; 2
    sta    ram_E6                ; 3
    sta    ram_AC                ; 3
    lda    #$08                  ; 2
    bit    ram_EC                ; 3
    bpl    LF13E                 ; 2³
    lda    #$00                  ; 2
LF13E:
    sta    ram_B0                ; 3
    lda    #$FF                  ; 2
    sta    ram_BD                ; 3
    lda    ram_BB                ; 3
    clc                          ; 2
    adc    #$04                  ; 2
    sta    hPosHERO              ; 3
LF14B:
    lda    ram_D8                ; 3
    cmp    #<Raft                ; 2
    beq    LF177                 ; 2³
    cmp    #<BlankGfx            ; 2
    beq    LF177                 ; 2³
    bit    ram_D1                ; 3
    bmi    LF177                 ; 2³
    lda    ram_AD                ; 3
    bne    LF177                 ; 2³
    bit    CXPPMM                ; 3
    bpl    LF177                 ; 2³
    lda    roomNum               ; 3
    cmp    #$0B                  ; 2
    bcc    LF177                 ; 2³
    ldx    #$F0                  ; 2
    lda    hPosHERO              ; 3
    cmp    ram_A8                ; 3
    beq    LF175                 ; 2³
    ldx    #$70                  ; 2
    bcc    LF175                 ; 2³
    ldx    #$B0                  ; 2
LF175:
    stx    ram_84                ; 3
LF177:
    lda    ram_E1                ; 3
    ora    ram_BA                ; 3
    ora    ram_F2                ; 3
    ora    ram_AD                ; 3
    beq    LF184                 ; 2³
    jmp    LF282                 ; 3

LF184:
    lda    #$10                  ; 2
    and    ram_84                ; 3
    bne    LF190                 ; 2³
    inc    ram_E9                ; 5
    bit    ram_E9                ; 3
    bvc    LF196                 ; 2³
LF190:
    dec    ram_E9                ; 5
    bpl    LF196                 ; 2³
    inc    ram_E9                ; 5
LF196:
    ldx    levelNum              ; 3
    lda    LFF00,X               ; 4
    clc                          ; 2
    adc    roomNum               ; 3
    tax                          ; 2
    lda    ram_E9                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tay                          ; 2
    lda    roomNum               ; 3
    sta    ram_BB                ; 3
    cmp    #$0B                  ; 2
    bcc    LF1B2                 ; 2³
    cpy    #$00                  ; 2
    bne    LF1B2                 ; 2³
    iny                          ; 2
LF1B2:
    lda    ram_9F                ; 3
    cpy    #$04                  ; 2
    bcc    LF1D8                 ; 2³
    bit    ram_E6                ; 3
    bmi    LF20E                 ; 2³+1
    clc                          ; 2
    adc    LFFB0,Y               ; 4
    cmp    #$8A                  ; 2
    bcc    LF20C                 ; 2³+1
    lda    #$04                  ; 2
    sta    ram_9F                ; 3
    dec    roomNum               ; 5
    bpl    LF1D2                 ; 2³
    inc    roomNum               ; 5
    lda    #$8A                  ; 2
    bne    LF20C                 ; 3+1   always branch

LF1D2:
    jsr    LF63A                 ; 6
    jmp    LF20E                 ; 3

LF1D8:
    bit    ram_E6                ; 3
    bvs    LF20E                 ; 2³+1
    sec                          ; 2
    sbc    LFFB0,Y               ; 4
    cmp    #$16                  ; 2
    bcs    LF1F4                 ; 2³
    ldx    roomNum               ; 3
    cpx    #$0A                  ; 2
    bcc    LF1F4                 ; 2³
    ldx    #$00                  ; 2
    stx    ram_AE                ; 3
    lda    #$FF                  ; 2
    sta    ram_AD                ; 3
    lda    #$15                  ; 2
LF1F4:
    cmp    #$FE                  ; 2
    bcc    LF20C                 ; 2³+1
    lda    #$89                  ; 2
    sta    ram_9F                ; 3
    lda    ram_9E                ; 3
    cmp    roomNum               ; 3
    bne    LF204                 ; 2³
    inc    ram_9E                ; 5
LF204:
    inc    roomNum               ; 5
    jsr    LF63A                 ; 6
    jmp    LF20E                 ; 3

LF20C:
    sta    ram_9F                ; 3
LF20E:
    bit    ram_BD                ; 3
    bmi    LF282                 ; 2³
    lda    ram_AD                ; 3
    bne    LF282                 ; 2³
    lda    hPosHERO              ; 3
    and    #$03                  ; 2
    bne    LF236
    bit    ram_84                ; 3
    bpl    LF224                 ; 2³
    bvs    LF282                 ; 2³
    lda    #$08                  ; 2
LF224:
    cmp    ram_B0                ; 3
    beq    LF234                 ; 2³
    ldx    #$FD                  ; 2
    stx    ram_F3                ; 3
    ldx    ram_AC                ; 3
    bne    LF234                 ; 2³
    ldx    #$03                  ; 2
    stx    ram_FC                ; 3
LF234:
    sta    ram_B0                ; 3
LF236:
    lda    roomNum               ; 3
    sta    ram_BB                ; 3
    dec    ram_FC                ; 5
    bpl    LF282                 ; 2³
    inc    ram_FC                ; 5
    lda    hPosHERO              ; 3
    ldx    ram_B0                ; 3
    beq    LF253                 ; 2³
    sec                          ; 2
    sbc    #$01                  ; 2
    sta    hPosHERO              ; 3
    cmp    #$0C                  ; 2
    bcs    LF282                 ; 2³
    ldx    #$00                  ; 2
    beq    LF25E                 ; 3   always branch

LF253:
    clc                          ; 2
    adc    #$01                  ; 2
    sta    hPosHERO              ; 3
    cmp    #$93                  ; 2
    bcc    LF282                 ; 2³
    ldx    #$01                  ; 2
LF25E:
    jsr    LF630                 ; 6
    lda    LF900,Y               ; 4
    and    #$01                  ; 2
    cmp    LFFAA,X               ; 4
    beq    LF278                 ; 2³
    lda    ram_9E                ; 3
    cmp    roomNum               ; 3
    bne    LF273                 ; 2³
    inc    ram_9E                ; 5
LF273:
    inc    roomNum               ; 5
    jmp    LF27A                 ; 3

LF278:
    dec    roomNum               ; 5
LF27A:
    lda    LFFAC,X               ; 4
    sta    hPosHERO              ; 3
    jsr    LF63A                 ; 6
LF282:
    ldx    #$02                  ; 2
LF284:
    lda    ram_A4                ; 3
    lsr                          ; 2
    bcc    LF293                 ; 2³
    lda    ram_E0                ; 3
    ora    ram_DF                ; 3
    beq    LF298                 ; 2³
    lda    #$02                  ; 2
    bne    LF298                 ; 3   always branch

LF293:
    lda    LFFAE,X               ; 4
    ora    ram_A4                ; 3
LF298:
    sta    sectionColors,X       ; 4
    dex                          ; 2
    bpl    LF284                 ; 2³
    jsr    LF630                 ; 6
    lda    LF700,Y               ; 4
    cmp    #$93                  ; 2
    beq    LF2A9                 ; 2³
    and    #$FC                  ; 2
LF2A9:
    sta    ram_A5                ; 3
    lda    LF800,Y               ; 4
    cmp    #$93                  ; 2
    beq    LF2B4                 ; 2³
    and    #$FC                  ; 2
LF2B4:
    sta    ram_A6                ; 3
    lda    LF900,Y               ; 4
    and    #$FC                  ; 2
    ora    #$01                  ; 2
    cmp    #$91                  ; 2
    bne    LF2C3                 ; 2³
    lda    #$93                  ; 2
LF2C3:
    sta    ram_A7                ; 3
;---------------------------------------
; PF1 walls
;---------------------------------------
    lda    #FIRST_CEILING_PF1    ; 
    ldx    roomNum               ;   first room?
    beq    .doTopPF1             ;   - yes
    lda    #CEILING_12_TO_16_PF1 ;   - no
    cpx    #ROOM_12              ;   room 12 or above?
    bcs    .doTopPF1             ;   - yes
    lda    TopBotPF1-1,Y         ;   - no, use data table for PF1 top
.doTopPF1:
    sta    ram_C1                ;   PF1 top
    lda    MidPF1,Y              ;   
    sta    ram_C0                ;   PF1 middle
    lda    TopBotPF1,Y           ;
    sta    ram_BF                ;   PF1 bottom
;---------------------------------------
; PF2 walls
;---------------------------------------
    lda    #FIRST_CEILING_PF2    ;
    ldx    roomNum               ;   first room?
    beq    .doTopPF2             ;   - yes
    lda    #CEILING_12_TO_16_PF2 ;   - no
    cpx    #ROOM_12              ;   room 12 or above?
    bcs    .doTopPF2             ;   -yes
    lda    TopBotPF2-1,Y         ;   - no, use data table for PF2 top
.doTopPF2:
    sta    ram_C4                ;   PF2 top
    lda    MidPF2,Y              ;
    sta    ram_C3                ;   PF2 middle
    lda    TopBotPF2,Y           ; 
    sta    ram_C2                ;   PF2 bottom
;---------------------------------------
;
;---------------------------------------
    lda    ram_B1                ; 3
    rol                          ; 2
    rol                          ; 2
    rol                          ; 2
    and    #$03                  ; 2
    tax                          ; 2
    lda    NuSizTab,X            ; 4
    sta    NUSIZ1                ; 3
    sta    ram_BB                ; 3
    ora    #$05                  ; 2
    sta    CTRLPF                ; 3
    sta    ram_C8                ; 3
    sta    ram_CA                ; 3
    lda    BreakableWallTab,Y    ; 4   Asynchronous playfield?
    lsr                          ; 2
    lda    #$05                  ; 2             PFP | REFLECT
    bcc    LF31C                 ; 2³  - no
    lda    #$04                  ; 2   - yes,    PFP   (no reflect)
LF31C:
    ora    ram_BB                ; 3
    sta    ram_C9                ; 3
    lda    BreakableWallTab,Y    ; 4   Magma walls?
    lsr                          ; 2
    lsr                          ; 2
    bcc    LF334                 ; 2³  - no
    lda    frameCounter          ; 3   - yes
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    and    #$01                  ; 2
    tax                          ; 2
    lda    LavaColTab,X          ; 4
    sta    sectionColors+1       ; 3   middle section color
LF334:
    lda    #$FF                  ; 2
    sta    ram_BE                ; 3
    lda    roomNum               ; 3
    cmp    #$0A                  ; 2
    bcs    LF351                 ; 2³
    ldx    levelNum              ; 3
    lda    LFF28,X               ; 4
    cmp    roomNum               ; 3
    beq    LF355                 ; 2³
    lda    ram_A0                ; 3
    cmp    #$09                  ; 2
    beq    LF351                 ; 2³
    cmp    #$99                  ; 2
    bne    LF355                 ; 2³
LF351:
    lda    #$00                  ; 2
    sta    ram_BE                ; 3
LF355:
    lda    ram_C3                ; 3
    cmp    #$7F                  ; 2
    bne    LF374                 ; 2³
    lda    ram_C0                ; 3
    cmp    #$FF                  ; 2
    bne    LF374                 ; 2³
    lda    levelNum              ; 3
    cmp    #$0D                  ; 2
    bcc    LF374                 ; 2³
    lda    ram_FD                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    and    #$07                  ; 2
    tax                          ; 2
    lda    LFFB8,X               ; 4
    sta    ram_C3                ; 3
LF374:
    lda    ram_F6                ; 3
    lsr                          ; 2
    lsr                          ; 2
    and    #$03                  ; 2
    tax                          ; 2
    lsr                          ; 2
    tay                          ; 2
    lda    LFF8B,Y               ; 4
    sta    ram_85                ; 3
    lda    LFF8D,Y               ; 4
    sta    ram_86                ; 3
    lda    LFF8F,X               ; 4
    sta    ram_87                ; 3
    lda    LFF9B,Y               ; 4
    sta    ram_88                ; 3
    lda    #$4D                  ; 2
    sta    ram_89                ; 3
    lda    #$5A                  ; 2
    sta    ram_8A                ; 3
    lda    #$33                  ; 2
    sta    ram_8B                ; 3
    lda    #$17                  ; 2
    sta    ram_8C                ; 3
    lda    ram_EA                ; 3
    and    #$7F                  ; 2
    sta    ram_BB                ; 3
    lda    ram_EB                ; 3
    and    #$7F                  ; 2
    sta    ram_BC                ; 3
    ldx    #$02                  ; 2
LF3AF:
    cpx    #$02                  ; 2
    beq    LF400                 ; 2³+1
    jsr    LF630                 ; 6
    lda    LF700,Y               ; 4
    and    #$03                  ; 2
    cpx    #$00                  ; 2
    beq    LF3C4                 ; 2³
    lda    LF800,Y               ; 4
    and    #$03                  ; 2
LF3C4:
    tay                          ; 2
    lda    ram_A1,X              ; 4
    cmp    #$32                  ; 2
    beq    LF3F3                 ; 2³
    cpy    #$03                  ; 2
    bne    LF3E1                 ; 2³
    lda    ram_F7,X              ; 4
    beq    LF3D7                 ; 2³
    lda    #$09                  ; 2
    bne    LF3D9                 ; 3   always branch

LF3D7:
    lda    ram_BB                ; 3
LF3D9:
    clc                          ; 2
    adc    ram_A5,X              ; 4
    sta    ram_A5,X              ; 4
    jmp    LF3F3                 ; 3

LF3E1:
    tya                          ; 2
    beq    LF3F3                 ; 2³
    lda    ram_BB                ; 3
    sta    ram_A1,X              ; 4
    cpy    #$02                  ; 2
    bne    LF3F3                 ; 2³
    lda    ram_BC                ; 3
    clc                          ; 2
    adc    ram_A5,X              ; 4
    sta    ram_A5,X              ; 4
LF3F3:
    lda.wy ram_85,Y              ; 4
    sta    ram_CB,X              ; 4
    lda.wy ram_89,Y              ; 4
    sta    ram_CE,X              ; 4
    jmp    LF408                 ; 3

LF400:
    lda    #$8E                  ; 2
    sta    ram_D0                ; 3
    lda    #<LightGfx            ; 2
    sta    ram_CD                ; 3
LF408:
    lda    ram_F7,X              ; 4
    beq    LF41F                 ; 2³
    sec                          ; 2
    sbc    #$01                  ; 2
    sta    ram_F7,X              ; 4
    bne    LF417                 ; 2³
    lda    #$32                  ; 2
    sta    ram_A1,X              ; 4
LF417:
    lda    #$76                  ; 2
    sta    ram_CB,X              ; 4
    lda    #$40                  ; 2
    sta    ram_CE,X              ; 4
LF41F:
    lda    ram_A5,X              ; 4
    cmp    #$93                  ; 2
    bcc    LF429                 ; 2³
    lda    #$8A                  ; 2
    sta    ram_CB,X              ; 4
LF429:
    dex                          ; 2
    bmi    LF42F                 ; 2³
    jmp    LF3AF                 ; 3

LF42F:
    lda    ram_A4                ; 3
    lsr                          ; 2
    bcc    LF447                 ; 2³
    ldx    #$02                  ; 2
LF436:
    lda    ram_DE,X              ; 4
    bne    LF447                 ; 2³
    lda    ram_CB,X              ; 4
    cmp    #$76                  ; 2
    beq    LF444                 ; 2³
    lda    #$9B                  ; 2
    sta    ram_CE,X              ; 4
LF444:
    dex                          ; 2
    bpl    LF436                 ; 2³
LF447:
    ldx    #$02                  ; 2
LF449:
    ldy    ram_E7                ; 3
    lda    LFF93,Y               ; 4
    sta    ram_D8,X              ; 4
    lda    #$68                  ; 2
    sta    ram_DB,X              ; 4
    lda    ram_DE,X              ; 4
    beq    LF48C                 ; 2³
    dec    ram_DE,X              ; 6
    lda    ram_DE,X              ; 4
    bne    LF466                 ; 2³
    sta    ram_FA                ; 3
    lda    #$93                  ; 2
    sta    ram_A8,X              ; 4
    bne    LF48C                 ; 3   always branch

LF466:
    cmp    #$20                  ; 2
    bcs    LF48C                 ; 2³
    cmp    #$13                  ; 2
    bcs    LF476                 ; 2³
    ldy    ram_FA                ; 3
    beq    LF476                 ; 2³
    ldy    #$04                  ; 2
    bne    LF47A                 ; 3   always branch

LF476:
    lsr                          ; 2
    and    #$03                  ; 2
    tay                          ; 2
LF47A:
    lda    LFF96,Y               ; 4
    sta    ram_D8,X              ; 4
    lda    #$40                  ; 2
    sta    ram_DB,X              ; 4
    lda    ram_F2                ; 3
    bne    LF48C                 ; 2³
    lda    LFFA5,Y               ; 4
    sta    ram_E1                ; 3
LF48C:
    lda    ram_A8,X              ; 4
    cmp    #$93                  ; 2
    bne    LF496                 ; 2³
    lda    #<BlankGfx            ; 2
    sta    ram_D8,X              ; 4
LF496:
    dex                          ; 2
    bpl    LF449                 ; 2³
;---------------------------------------
; check for raft
;---------------------------------------
    lda    roomNum               ; 3
    cmp    #ROOM_12              ; 2
    bcc    LF4C0                 ; 2³
    lda    levelNum              ; 3
    cmp    #LEVEL_10             ; 2
    bcc    LF4C0                 ; 2³
    lda    ram_C2                ; 3   PF2 bottom
    bne    LF4C0                 ; 2³
    lda    ram_BF                ; 3   PF1 bottom
    cmp    #$C0                  ; 2
    bne    LF4C0                 ; 2³
    lda    #<Raft                ; 2
    sta    ram_D8                ; 3
    lda    #$05                  ; 2
    sta    ram_DB                ; 3
    lda    ram_EC                ; 3
    and    #$7F                  ; 2
    clc                          ; 2
    adc    #$1C                  ; 2
    sta    ram_A8                ; 3
;---------------------------------------
; 
;---------------------------------------
LF4C0:
    lda    levelNum              ; 3
    cmp    #LEVEL_17             ; 2
    bcc    LF502                 ; 2³+1
    lda    roomNum               ; 3
    cmp    #ROOM_12              ; 2
    bcc    LF54A                 ; 2³+1
    lda    ram_C2                ; 3
    bne    LF54A                 ; 2³+1
    lda    ram_BF                ; 3
    cmp    #$E0                  ; 2
    bne    LF54A                 ; 2³+1
    lda    ram_D8                ; 3
    cmp    #<Raft                ; 2
    beq    LF54A                 ; 2³+1
    lda    ram_A8                ; 3
    cmp    #$93                  ; 2
    bne    LF4F0                 ; 2³
    ldx    #$78                  ; 2
    lda    #$08                  ; 2
    and    ram_B0                ; 3
    bne    LF4EC                 ; 2³
LF4EA:
    ldx    #$1C                  ; 2
LF4EC:
    stx    ram_A8                ; 3
    bne    LF52B                 ; 2³+1
LF4F0:
    cmp    #$92                  ; 2
    beq    LF54A                 ; 2³+1
    lda    ram_AD                ; 3
    cmp    #$95                  ; 2
    bne    LF505                 ; 2³+1
    lda    ram_AE                ; 3
    bne    LF505                 ; 2³+1
    lda    #$92                  ; 2
    sta    ram_A8                ; 3
LF502:
    jmp    LF54A                 ; 3

LF505:
    lda    #$03                  ; 2
    ldx    levelNum              ; 3
    cpx    #$12                  ; 2
    bcc    LF50F                 ; 2³
    lda    #$01                  ; 2
LF50F:
    and    frameCounter          ; 3
    bne    LF52B                 ; 2³
    ldy    ram_A8                ; 3
    cpy    hPosHERO              ; 3
    beq    LF52B                 ; 2³
    bcs    LF524                 ; 2³
    iny                          ; 2
    ldx    #$78                  ; 2
    cpy    #$78                  ; 2
    bcs    LF4EC                 ; 2³+1
    bcc    LF529                 ; 3   always branch

LF524:
    dey                          ; 2
    cpy    #$1C                  ; 2
    bcc    LF4EA                 ; 2³+1
LF529:
    sty    ram_A8                ; 3
LF52B:
    lda    ram_F6                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    and    #$07                  ; 2
    ldx    ram_AD                ; 3
    beq    LF540                 ; 2³
    txa                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tax                          ; 2
    lda    LFFC0,X               ; 4
LF540:
    tax                          ; 2
    lda    LF6D2,X               ; 4
    sta    ram_D8                ; 3
    lda    #$C4                  ; 2
    sta    ram_DB                ; 3
LF54A:
    lda    #$DD                  ; 2
    sta    ram_98                ; 3
    lda    #$DB                  ; 2
    sta    ram_94                ; 3
    lda    #$DA                  ; 2
    sta    ram_9A                ; 3
    lda    ram_9F                ; 3
    sec                          ; 2
    sbc    #$17                  ; 2
    sta    ram_BB                ; 3
    lda    #$DA                  ; 2
    sta    ram_92                ; 3
    ldx    #$E2                  ; 2
    lda    ram_AD                ; 3
    cmp    #$96                  ; 2
    bcs    LF58A                 ; 2³
    lda    #$DE                  ; 2
    sta    ram_92                ; 3
    ldx    #$E6                  ; 2
    lda    ram_E1                ; 3
    bne    LF58A                 ; 2³
    ldy    ram_E7                ; 3
    ldx    LFFA2,Y               ; 4
    lda    ram_AC                ; 3
    beq    LF58A                 ; 2³
    ldx    #$CC                  ; 2
    asl                          ; 2
    bcc    LF58A                 ; 2³
    lda    #$DC                  ; 2
    sta    ram_92                ; 3
    ldy    ram_E8                ; 3
    ldx    LFF9D,Y               ; 4
LF58A:
    txa                          ; 2
    sec                          ; 2
    sbc    ram_BB                ; 3
    sta    ram_91                ; 3
    lda    #$74                  ; 2
    sec                          ; 2
    sbc    ram_BB                ; 3
    sta    ram_95                ; 3
    lda    #$DD                  ; 2
    sta    ram_96                ; 3
    ldy    levelNum              ; 3
    lda    LFF28,Y               ; 4
    cmp    roomNum               ; 3
    bne    LF5DC                 ; 2³
    lda    #$71                  ; 2
    sta    ram_D9                ; 3
    lda    #$26                  ; 2
    sta    ram_DC                ; 3
    lda    #$80                  ; 2
    sta    ram_A9                ; 3
    lda    LFF14,Y               ; 4
    tay                          ; 2
    lda    BreakableWallTab,Y               ; 4
    and    #$FC                  ; 2
    cmp    #$08                  ; 2
    bne    LF5D4                 ; 2³
    ldx    #$01                  ; 2
LF5BF:
    lda    ram_CB,X              ; 4
    cmp    #$76                  ; 2
    bne    LF5C9                 ; 2³
    lda    #$6D                  ; 2
    sta    ram_CB,X              ; 4
LF5C9:
    dex                          ; 2
    bpl    LF5BF                 ; 2³
    lda    #$08                  ; 2
    sta    REFP0                 ; 3
    lda    #$18                  ; 2
    sta    ram_A9                ; 3
LF5D4:
    lda    ram_F2                ; 3
    beq    LF5DC                 ; 2³
    lda    #$7E                  ; 2
    sta    ram_D9                ; 3
LF5DC:
    ldx    #$06                  ; 2
    lda    ram_A5,X              ; 4
    clc                          ; 2
    adc    #$30                  ; 2
    bne    LF5EF                 ; 2³
LF5E5:
    lda    ram_A5,X              ; 4
    cmp    #$93                  ; 2
    bcc    LF5EF                 ; 2³
    lda    #$A9                  ; 2
    bne    LF606                 ; 3+1   always branch

LF5EF:
    ldy    #$FF                  ; 2
    sec                          ; 2
LF5F2:
    iny                          ; 2
    sbc    #$0F                  ; 2
    bcs    LF5F2                 ; 2³
    eor    #$0F                  ; 2
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    adc    #$80                  ; 2
    and    #$F0                  ; 2
    sta    ram_D1,X              ; 4
    tya                          ; 2
    ora    ram_D1,X              ; 4
LF606:
    sta    ram_D1,X              ; 4
    dex                          ; 2
    bpl    LF5E5                 ; 2³+1
    inx                          ; 2
    lda    roomNum               ; 3
    cmp    #$0A                  ; 2
    bcs    LF61B                 ; 2³
    ldy    levelNum              ; 3
    lda    LFF28,Y               ; 4
    cmp    roomNum               ; 3
    bne    LF622                 ; 2³
LF61B:
    lda    frameCounter          ; 3
    lsr                          ; 2
    lsr                          ; 2
    and    #$07                  ; 2
    tax                          ; 2
LF622:
    stx    ram_FB                ; 3
    ldx    #$02                  ; 2
LF626:
    lda    scoreBCD,X            ; 4
    sta    ram_BB,X              ; 4
    dex                          ; 2
    bpl    LF626                 ; 2³
    jmp    LFFEC                 ; 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LF630 SUBROUTINE ;x4
    ldy    levelNum              ; 3
    lda    LFF00,Y               ; 4
    clc                          ; 2
    adc    roomNum               ; 3
    tay                          ; 2
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LF63A SUBROUTINE ;x3
    ldx    #$02                  ; 2
LF63C:
    lda    ram_F7,X              ; 4
    beq    LF648                 ; 2³
    lda    #$32                  ; 2
    sta    ram_A1,X              ; 4
    lda    #$00                  ; 2
    sta    ram_F7,X              ; 4
LF648:
    dex                          ; 2
    bpl    LF63C                 ; 2³
    lda    #$00                  ; 2
    sta    ram_B1                ; 3
    sta    ram_FA                ; 3
    sta    ram_EA                ; 3
    sta    ram_EB                ; 3
    sta    ram_F6                ; 3
    lda    #$50                  ; 2
    sta    ram_FD                ; 3
    lda    #$93                  ; 2
    sta    ram_A8                ; 3
    sta    ram_A9                ; 3
    sta    ram_AA                ; 3
    lda    ram_B0                ; 3
    cmp    #$08                  ; 2
    lda    #$80                  ; 2
    bcc    LF66D                 ; 2³
    lda    #$60                  ; 2
LF66D:
    sta    ram_EC                ; 3
    lda    ram_BB                ; 3
    ldx    roomNum               ; 3
    cpx    ram_9D                ; 3
    sta    ram_9D                ; 3
    bne    LF68B                 ; 2³
    ldx    #$04                  ; 2
LF67B:
    lda    ram_A0,X              ; 4
    sta    ram_BB                ; 3
    lda    ram_ED,X              ; 4
    sta    ram_A0,X              ; 4
    lda    ram_BB                ; 3
    sta    ram_ED,X              ; 4
    dex                          ; 2
    bpl    LF67B                 ; 2³
    rts                          ; 6

LF68B:
    ldx    #$04                  ; 2
LF68D:
    lda    ram_A0,X              ; 4
    sta    ram_ED,X              ; 4
    dex                          ; 2
    bpl    LF68D                 ; 2³
    lda    levelNum              ; 3
    and    #$03                  ; 2
    tax                          ; 2
    lda    LFF6A,X               ; 4
    sta    ram_A4                ; 3
    ldx    levelNum              ; 3
    lda    LFF00,X               ; 4
    clc                          ; 2
    adc    roomNum               ; 3
    tax                          ; 2
    lda    BreakableWallTab,X               ; 4
    and    #$FC                  ; 2
    beq    LF6B0                 ; 2³
    ora    #$01                  ; 2
LF6B0:
    sta    ram_A0                ; 3
    tax                          ; 2
    cpx    #$09                  ; 2
    beq    LF6BD                 ; 2³
    cpx    #$99                  ; 2
    beq    LF6BD                 ; 2³
    ldx    #$00                  ; 2
LF6BD:
    lda    ram_9E                ; 3
    cmp    roomNum               ; 3
    bne    LF6C7                 ; 2³
    lda    #$00                  ; 2
    beq    LF6CB                 ; 3   always branch

LF6C7:
    stx    ram_A0                ; 3
    lda    #$32                  ; 2
LF6CB:
    sta    ram_A1                ; 3
    sta    ram_A2                ; 3
    sta    ram_A3                ; 3
    rts                          ; 6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LF6D2:
    .byte $A6 ; |X X  XX | $F6D2   here2
    .byte $B2 ; |X XX  X | $F6D3
    .byte $BE ; |X XXXXX | $F6D4
    .byte $CA ; |XX  X X | $F6D5
    
    .byte $D6 ; |XX X XX | $F6D6   are these ever used?
    .byte $CA ; |XX  X X | $F6D7
    .byte $BE ; |X XXXXX | $F6D8
    .byte $B2 ; |X XX  X | $F6D9
 IF PLUSROM != 1
    .byte $00 ; |        | $F6DA
    .byte $00 ; |        | $F6DB
    .byte $00 ; |        | $F6DC
    .byte $00 ; |        | $F6DD
    .byte $00 ; |        | $F6DE
    .byte $00 ; |        | $F6DF
    .byte $00 ; |        | $F6E0
    .byte $00 ; |        | $F6E1
    .byte $00 ; |        | $F6E2
    .byte $00 ; |        | $F6E3
    .byte $00 ; |        | $F6E4
    .byte $00 ; |        | $F6E5
    .byte $00 ; |        | $F6E6
    .byte $00 ; |        | $F6E7
    .byte $00 ; |        | $F6E8
    .byte $00 ; |        | $F6E9
    .byte $00 ; |        | $F6EA
    .byte $00 ; |        | $F6EB
    .byte $00 ; |        | $F6EC
    .byte $00 ; |        | $F6ED
    .byte $00 ; |        | $F6EE
    .byte $00 ; |        | $F6EF
    .byte $00 ; |        | $F6F0
    .byte $00 ; |        | $F6F1
    .byte $00 ; |        | $F6F2
    .byte $00 ; |        | $F6F3
    .byte $00 ; |        | $F6F4
    .byte $00 ; |        | $F6F5
    .byte $00 ; |        | $F6F6
    .byte $00 ; |        | $F6F7
    .byte $00 ; |        | $F6F8
    .byte $00 ; |        | $F6F9
    .byte $00 ; |        | $F6FA
    .byte $00 ; |        | $F6FB
    .byte $00 ; |        | $F6FC
    .byte $00 ; |        | $F6FD
    .byte $00 ; |        | $F6FE
    .byte $00 ; |        | $F6FF
 ENDIF

RM3_FB00 = $FF
RM3_FD00 = $3F

RM4_F700 = $93  ; $FC = BOT_ENEMY_POS ($93 compared too), SPIDER = 0, BAT = 1, MOTH = 2, SNAKE = 3
RM4_F800 = $3C  ; $FC = MID_ENEMY_POS ($93 compared too), SPIDER = 0, BAT = 1, MOTH = 2, SNAKE = 3
RM4_F900 = $90  ; lamp position = $FC, unused = $02, used = $01 (for what??)
RM4_FA00 = $00  ; middle PF1
RM4_FB00 = $FC  ; bottom PF1
RM4_FC00 = $00  ; middle PF2
RM4_FD00 = $FF  ; bottom PF2
RM4_FE00 = $34  ; BREAKABLE_WALL_POS = $FC, MAGMA = $02, ASYNCHRONOUS_PF = $01


MAGMA = $02

SPIDER = 0
BAT    = 1
MOTH   = 2
SNAKE  = 3

LF700:
    .byte $93,$93                                                          ; 1
    .byte $93,RM4_F700,$50,$93                                             ; 2
    .byte $93,$46,$93,$28,$93,$93                                          ; 3
    .byte $93,$93,$4C,$18,$40,$4C,$51,$93                                  ; 4
    .byte $93,$93,$5E,$93,$7B,$93,$71,$93                                  ; 5
    .byte $93,$1A,$50,$60,$93,$3C,$18,$68,$93,$93                          ; 6
    .byte $93,$44,$93,$93,$13,$72,$19,$50,$68,$78,$48,$93                  ; 7
    .byte $93,$50,$50,$68,$1B,$93,$93,$93,$63,$93,$93,$36,$53,$93          ; 8
    .byte $93,$7C,$38,$3D,$93,$3A,$93,$18,$93,$2A,$4E,$3E,$53,$52,$93,$93  ; 9
    .byte $93,$19,$93,$1D,$93,$28,$81,$2E,$2E,$2E,$26,$3E,$53,$93,$2A,$93  ;10
    .byte $93,$38,$85,$50,$14,$15,$36,$41,$4D,$65,$93,$6D,$3C,$64,$20,$93  ;11
    .byte $93,$7D,$93,$29,$43,$28,$5A,$93,$36,$52,$5D,$57,$93,$64,$3C,$32  ;12
    .byte $93,$6C,$93,$93,$93,$88,$93,$51,$6D,$93,$3D,$62,$4C,$5E,$65,$3E  ;13
    .byte $93,$93,$43,$93,$43,$32,$93,$93,$25,$93,$16,$5E,$44,$53,$42,$5C  ;14
    .byte $93,$93,$40,$93,$42,$93,$6B,$93,$93,$93,$2A,$53,$5B,$3C,$93,$31  ;15
    .byte $93,$93,$32,$4C,$7F,$36,$42,$60,$61,$61,$4D,$5C,$1E,$4C,$5E,$93  ;16
    .byte $93,$81,$21,$52,$4A,$93,$19,$93,$5E,$40,$13,$2E,$65,$53,$2C,$70  ;17
    .byte $93,$19,$6B,$51,$13,$93,$26,$93,$93,$31,$93,$5E,$4C,$35,$46,$93  ;18
    .byte $93,$93,$3E,$76,$89,$93,$40,$31,$2E,$35,$74,$2E,$4C,$64,$93,$69  ;19
    .byte $93,$80,$62,$28,$3A,$2E,$70,$6A,$62,$70,$4E,$4C,$70,$66,$6A,$93  ;20

LF800:
    .byte $93,$30                                                          ; 1
    .byte $93,RM4_F800,$39,$6D                                             ; 2
    .byte $93,$2C,$30,$69,$42,$2A                                          ; 3
    .byte $93,$7C,$79,$6B,$42,$6C,$84,$53                                  ; 4
    .byte $93,$16,$4C,$4C,$16,$4C,$28,$4E                                  ; 5
    .byte $93,$61,$49,$22,$56,$71,$81,$41,$1E,$34                          ; 6
    .byte $93,$34,$59,$2B,$22,$3C,$80,$17,$68,$4C,$81,$4D                  ; 7
    .byte $93,$3C,$93,$1A,$93,$4C,$70,$5B,$1D,$93,$4C,$63,$28,$4C          ; 8
    .byte $93,$1D,$93,$93,$93,$93,$5C,$93,$41,$54,$80,$93,$70,$70,$84,$4C  ; 9
    .byte $93,$2E,$6A,$2E,$73,$6F,$42,$18,$93,$59,$11,$2E,$3D,$93,$2E,$3E  ;10
    .byte $93,$93,$2A,$16,$72,$32,$4C,$93,$5C,$93,$3C,$5E,$7C,$5E,$79,$2E  ;11
    .byte $93,$24,$4C,$70,$46,$59,$93,$76,$28,$12,$10,$12,$53,$22,$2E,$42  ;12
    .byte $93,$14,$32,$22,$56,$81,$89,$2A,$38,$12,$62,$3C,$12,$2E,$42,$3E  ;13
    .byte $93,$32,$5E,$49,$6D,$93,$78,$89,$32,$2C,$45,$2E,$35,$24,$6C,$59  ;14
    .byte $93,$32,$39,$3A,$21,$4D,$18,$19,$18,$93,$59,$22,$33,$6B,$3E,$4C  ;15
    .byte $93,$89,$26,$54,$2D,$39,$70,$31,$93,$93,$6E,$20,$6E,$21,$2E,$38  ;16
    .byte $93,$2E,$80,$52,$4A,$4D,$32,$66,$78,$93,$32,$78,$1E,$39,$18,$2E  ;17
    .byte $93,$32,$88,$2E,$2E,$6A,$26,$4D,$93,$72,$56,$24,$20,$60,$88,$2A  ;18
    .byte $93,$36,$6E,$21,$80,$4C,$93,$2E,$43,$58,$3F,$75,$15,$22,$28,$62  ;19
    .byte $93,$36,$21,$73,$3A,$93,$12,$31,$31,$93,$88,$21,$1E,$25,$2E,$1A  ;20

LF900:
    .byte $90,$90                                                          ; 1
    .byte $90,RM4_F900,$90,$90                                             ; 2
    .byte $90,$50,$90,$68,$90,$90                                          ; 3
    .byte $90,$50,$14,$24,$18,$50,$84,$90                                  ; 4
    .byte $90,$51,$91,$80,$4C,$80,$50,$90                                  ; 5
    .byte $90,$50,$84,$50,$60,$34,$70,$18,$68,$90                          ; 6
    .byte $90,$50,$18,$4C,$64,$80,$28,$1C,$50,$78,$40,$90                  ; 7
    .byte $90,$50,$68,$50,$68,$78,$50,$18,$68,$30,$39,$91,$91,$91          ; 8
    .byte $90,$50,$80,$80,$80,$80,$80,$40,$18,$50,$80,$90,$90,$90,$90,$90  ; 9
    .byte $90,$50,$80,$4C,$4C,$1C,$28,$84,$88,$88,$81,$91,$91,$91,$91,$91  ;10
    .byte $90,$50,$68,$84,$50,$2C,$84,$68,$88,$88,$68,$90,$90,$90,$90,$90  ;11
    .byte $93,$50,$1C,$90,$70,$50,$88,$80,$90,$68,$69,$91,$91,$91,$91,$91  ;12
    .byte $91,$50,$2C,$18,$28,$88,$88,$90,$50,$2D,$91,$91,$91,$91,$91,$91  ;13
    .byte $90,$51,$91,$50,$90,$50,$68,$84,$90,$88,$4C,$90,$90,$90,$90,$90  ;14
    .byte $90,$50,$68,$60,$20,$58,$80,$80,$80,$80,$51,$91,$91,$91,$91,$91  ;15
    .byte $90,$18,$90,$78,$68,$14,$64,$88,$88,$88,$78,$90,$90,$90,$90,$90  ;16
    .byte $90,$50,$28,$78,$88,$68,$4C,$81,$91,$80,$65,$91,$91,$91,$91,$91  ;17
    .byte $90,$50,$80,$7C,$50,$80,$90,$3C,$4C,$4C,$4C,$90,$90,$90,$90,$90  ;18
    .byte $90,$4C,$70,$5C,$24,$88,$4C,$68,$6C,$88,$79,$91,$91,$91,$91,$91  ;19
    .byte $90,$4C,$80,$88,$88,$88,$80,$70,$80,$80,$84,$90,$90,$90,$90,$90  ;20

MidPF1:
    .byte $00,$C0                                                          ; 1
    .byte $00,RM4_FA00,$E0,$C0                                             ; 2
    .byte $00,$00,$00,$00,$00,$C0                                          ; 3
    .byte $80,$00,$03,$80,$80,$00,$00,$C0                                  ; 4
    .byte $00,$00,$00,$FF,$00,$00,$00,$00                                  ; 5
    .byte $00,$00,$00,$C0,$FF,$00,$00,$00,$C0,$C0                          ; 6
    .byte $80,$80,$00,$FF,$F0,$F0,$FC,$E0,$E0,$C0,$00,$00                  ; 7
    .byte $80,$00,$FF,$00,$F8,$F8,$00,$00,$E0,$F0,$00,$00,$00,$00          ; 8
    .byte $00,$00,$81,$F1,$FE,$FF,$FF,$00,$00,$FF,$00,$00,$00,$00,$00,$00  ; 9
    .byte $00,$00,$00,$00,$FC,$01,$00,$CF,$FF,$FF,$00,$00,$00,$00,$00,$00  ;10
    .byte $80,$FF,$00,$00,$00,$9C,$00,$FF,$FF,$FF,$03,$00,$00,$00,$00,$00  ;11
    .byte $E0,$C0,$00,$00,$00,$FC,$F3,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;12
    .byte $00,$00,$9C,$80,$F0,$C3,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;13
    .byte $00,$00,$00,$00,$00,$FF,$00,$00,$00,$FC,$03,$00,$00,$00,$00,$00  ;14
    .byte $00,$F8,$FC,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$03,$00,$00,$00  ;15
    .byte $00,$00,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$03,$00,$00  ;16
    .byte $00,$F0,$C3,$FF,$FF,$FF,$00,$00,$F0,$FF,$00,$00,$00,$00,$00,$00  ;17
    .byte $00,$00,$07,$00,$00,$00,$00,$FF,$FF,$00,$0E,$00,$00,$00,$00,$00  ;18
    .byte $00,$00,$E0,$F0,$FC,$C0,$FF,$FC,$FF,$FF,$1F,$00,$00,$00,$00,$00  ;19
    .byte $00,$00,$F3,$F3,$FF,$FF,$00,$FF,$00,$FF,$0F,$03,$00,$00,$00,$00  ;20

TopBotPF1:
    .byte $FF,$FF                                                          ; 1
    .byte RM3_FB00,RM4_FB00,$FF,$FF                                        ; 2
    .byte $FF,$C0,$FF,$FC,$FF,$FF                                          ; 3
    .byte $FF,$9F,$F1,$0F,$FF,$9F,$FF,$FF                                  ; 4
    .byte $FF,$FF,$C0,$FF,$CF,$FF,$FC,$FF                                  ; 5
    .byte $FF,$80,$FF,$E7,$FF,$FC,$CF,$FF,$FF,$FF                          ; 6
    .byte $FF,$CF,$FF,$FF,$C3,$00,$07,$FF,$F0,$FF,$F0,$FF                  ; 7
    .byte $FF,$FF,$FF,$FF,$F0,$FF,$CF,$FF,$00,$C0,$FC,$FE,$F0,$FF          ; 8
    .byte $FF,$C3,$C0,$C0,$C0,$C0,$FF,$CF,$FF,$C0,$FF,$F0,$80,$FF,$C0,$FF  ; 9
    .byte $FF,$CF,$FF,$E7,$E7,$F8,$87,$00,$00,$C0,$F0,$E0,$C0,$C0,$FC,$FF  ;10
    .byte $FF,$FF,$9F,$FF,$9E,$9F,$FF,$00,$00,$FF,$C0,$F0,$C0,$FF,$C0,$FF  ;11
    .byte $FF,$E7,$FF,$FC,$FF,$00,$C0,$FF,$FF,$FF,$C0,$00,$FF,$00,$C0,$FF  ;12
    .byte $FF,$9E,$0F,$FC,$03,$0F,$FF,$FF,$FE,$FF,$FF,$C0,$C0,$C0,$FF,$FF  ;13
    .byte $FF,$FF,$FF,$FF,$C3,$FF,$81,$FF,$C0,$FF,$80,$C0,$C0,$C0,$C0,$FF  ;14
    .byte $FF,$FF,$FF,$F3,$FF,$CF,$C0,$CF,$CF,$FF,$FC,$00,$00,$C0,$FF,$FF  ;15
    .byte $CF,$FF,$F0,$FF,$9F,$FF,$00,$00,$00,$F0,$C0,$C0,$E0,$C0,$F0,$FF  ;16
    .byte $FF,$00,$F0,$00,$FF,$FF,$CF,$FF,$C0,$FF,$C7,$E0,$E0,$E0,$C0,$F8  ;17
    .byte $FF,$CC,$E0,$FF,$CF,$FF,$F0,$FF,$FF,$9F,$FF,$E0,$C0,$E0,$FF,$FC  ;18
    .byte $FF,$FC,$FF,$01,$07,$FF,$FF,$FE,$00,$F0,$80,$E0,$C0,$F0,$E0,$FF  ;19
    .byte $FF,$C0,$00,$00,$00,$C0,$FC,$C0,$F0,$80,$80,$C0,$E0,$F0,$E0,$FF  ;20

MidPF2:
    .byte $00,$00                                                          ; 1
    .byte $00,RM4_FC00,$F0,$00                                             ; 2
    .byte $00,$00,$00,$00,$00,$00                                          ; 3
    .byte $00,$00,$FF,$FF,$00,$00,$00,$C0                                  ; 4
    .byte $00,$00,$00,$00,$00,$00,$00,$00                                  ; 5
    .byte $00,$00,$00,$00,$00,$FE,$00,$00,$00,$00                          ; 6
    .byte $00,$00,$00,$00,$F0,$00,$FC,$00,$00,$00,$00,$00                  ; 7
    .byte $00,$00,$1F,$00,$F8,$00,$00,$F0,$C0,$FF,$00,$FC,$00,$00          ; 8
    .byte $00,$00,$FF,$FF,$FC,$F1,$01,$00,$00,$1F,$00,$00,$00,$F0,$FF,$00  ; 9
    .byte $00,$00,$00,$00,$FC,$FF,$00,$7F,$3F,$0F,$FF,$00,$00,$C0,$00,$00  ;10
    .byte $00,$3F,$C0,$00,$1C,$00,$00,$3F,$C3,$3F,$C3,$00,$C0,$00,$00,$00  ;11
    .byte $00,$00,$00,$00,$00,$00,$FF,$00,$F8,$FC,$C0,$00,$C0,$00,$C0,$00  ;12
    .byte $00,$1C,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$E0,$00,$00,$00  ;13
    .byte $00,$00,$00,$00,$00,$7F,$FF,$00,$00,$00,$03,$00,$E0,$00,$00,$00  ;14
    .byte $00,$00,$F0,$00,$00,$00,$F0,$00,$00,$7F,$FF,$00,$03,$FF,$00,$00  ;15
    .byte $00,$F0,$E0,$03,$C0,$E0,$F3,$7F,$7C,$7F,$C0,$FF,$00,$FF,$00,$C0  ;16
    .byte $00,$00,$FF,$00,$03,$03,$00,$00,$00,$7F,$00,$FF,$00,$00,$FF,$00  ;17
    .byte $00,$00,$FF,$00,$00,$00,$00,$00,$7F,$1C,$00,$FF,$FF,$00,$00,$C0  ;18
    .byte $00,$00,$E0,$00,$FC,$00,$7F,$C0,$3F,$CF,$1F,$FC,$FF,$00,$C0,$C0  ;19
    .byte $00,$00,$FF,$FF,$03,$7F,$FF,$FC,$FC,$FC,$FF,$FF,$C0,$F0,$C0,$C0  ;20

TopBotPF2:
    .byte $3F,$FF                                                          ; 1
    .byte RM3_FD00,RM4_FD00,$03,$FF                                        ; 2
    .byte $3F,$00,$FC,$FF,$3F,$FF                                          ; 3
    .byte $3F,$FF,$FF,$FF,$3F,$FF,$07,$FF                                  ; 4
    .byte $3F,$FF,$00,$7F,$FF,$3F,$FF,$FF                                  ; 5
    .byte $3F,$FC,$3F,$F3,$F9,$00,$FF,$FC,$3F,$FF                          ; 6
    .byte $3F,$FF,$7F,$F9,$FF,$FF,$FF,$3F,$FF,$CF,$00,$FF                  ; 7
    .byte $3F,$00,$3F,$FC,$FE,$3F,$FF,$FC,$FC,$F0,$00,$00,$C0,$FF          ; 8
    .byte $3F,$FF,$00,$00,$00,$00,$C3,$FF,$3F,$00,$00,$00,$C0,$00,$00,$FF  ; 9
    .byte $3F,$FF,$7F,$7F,$FF,$FF,$3F,$00,$00,$00,$00,$00,$C0,$00,$C0,$FF  ;10
    .byte $3F,$00,$FF,$3F,$7E,$FF,$00,$00,$00,$00,$E0,$C0,$00,$F0,$FF,$FF  ;11
    .byte $3F,$FF,$FF,$FF,$3F,$FF,$00,$FF,$00,$00,$E0,$E0,$00,$C0,$00,$00  ;12
    .byte $3F,$3E,$FF,$FF,$FF,$FF,$FF,$3F,$FE,$FF,$FF,$E0,$00,$C0,$F0,$00  ;13
    .byte $3F,$FF,$3F,$FF,$3F,$00,$FF,$FF,$FE,$7F,$00,$E0,$00,$C0,$0F,$C0  ;14
    .byte $3F,$FC,$03,$FF,$0F,$7F,$FF,$FF,$7F,$3F,$00,$C0,$F0,$00,$FF,$F8  ;15
    .byte $3F,$FF,$00,$00,$FF,$01,$00,$00,$00,$00,$00,$00,$C0,$00,$E0,$00  ;16
    .byte $3F,$FF,$00,$00,$00,$7F,$FF,$FF,$00,$01,$FF,$00,$C0,$C0,$00,$00  ;17
    .byte $3F,$FF,$FF,$3F,$FF,$FF,$E0,$7F,$7F,$7C,$FF,$00,$00,$C0,$00,$00  ;18
    .byte $7F,$FF,$07,$FF,$FF,$7F,$00,$00,$00,$00,$00,$00,$00,$C0,$00,$00  ;19
    .byte $7F,$FF,$00,$00,$00,$00,$00,$F0,$F0,$F0,$00,$00,$00,$00,$00,$00  ;20

BreakableWallTab:
    .byte $00,$08                                                          ; 1
    .byte $00,RM4_FE00,$01,$98                                             ; 2
    .byte $00,$00,$00,$4C,$5C,$08                                          ; 3
    .byte $00,$00,$00,$00,$5C,$2C,$2C,$98                                  ; 4
    .byte $00,$9A,$08,$02,$34,$32,$3A,$00                                  ; 5
    .byte $02,$3C,$5E,$00,$4E,$01,$02,$4C,$3E,$08                          ; 6
    .byte $42,$5C,$3E,$40,$03,$64,$03,$64,$3E,$64,$0A,$98                  ; 7
    .byte $02,$02,$02,$3E,$02,$3E,$3E,$76,$02,$02,$9A,$10,$4C,$08          ; 8
    .byte $02,$36,$02,$02,$02,$02,$02,$72,$2E,$02,$0A,$90,$4C,$90,$00,$98  ; 9
    .byte $02,$6E,$3E,$6E,$03,$02,$5E,$02,$02,$02,$9A,$00,$4C,$02,$4C,$08  ;10
    .byte $02,$02,$22,$32,$02,$02,$02,$02,$02,$02,$08,$4E,$02,$4C,$4C,$98  ;11
    .byte $02,$36,$0A,$9A,$3A,$62,$02,$0A,$9A,$02,$9A,$4E,$1C,$4E,$02,$0A  ;12
    .byte $02,$22,$02,$4E,$4E,$02,$0A,$9A,$90,$9A,$4E,$4E,$02,$4E,$00,$08  ;13
    .byte $02,$9B,$0A,$0A,$9A,$02,$03,$0A,$9A,$5A,$08,$4E,$92,$4E,$36,$9A  ;14
    .byte $02,$5E,$03,$6E,$32,$2E,$02,$4E,$66,$02,$11,$4E,$45,$02,$00,$08  ;15
    .byte $02,$0A,$9A,$02,$22,$2A,$02,$02,$02,$02,$0A,$02,$4E,$8E,$4E,$9A  ;16
    .byte $02,$62,$02,$00,$02,$02,$66,$9A,$0B,$02,$9A,$10,$4E,$4C,$02,$08  ;17
    .byte $02,$62,$02,$62,$6A,$0A,$9A,$02,$02,$02,$0A,$88,$02,$4E,$02,$9A  ;18
    .byte $02,$5E,$03,$6A,$03,$5A,$02,$01,$02,$02,$98,$10,$02,$4E,$12,$0A  ;19
    .byte $02,$5E,$00,$02,$02,$02,$02,$02,$02,$02,$08,$8E,$8A,$8A,$02,$9A  ;20

LFF00:
    .byte $00,$02,$06,$0C,$14,$1C,$26,$32,$40,$50,$60,$70,$80,$90,$A0,$B0,$C0,$D0,$E0,$F0  ; screen index start
LFF14:
    .byte $01,$05,$0B,$13,$1B,$25,$31,$3F,$4F,$5F,$6F,$7F,$8F,$9F,$AF,$BF,$CF,$DF,$EF,$FF  ; screen index end
LFF28:
    .byte $01,$03,$05,$07,$07,$09,$0B,$0D,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F  ; number of screens

LavaColTab:
    .byte RED+2          ; $FF3C
    .byte RED+4          ; $FF3D

CLOCK_WIDTH_1      = $00
CLOCK_WIDTH_2      = $10
CLOCK_WIDTH_4      = $20
CLOCK_WIDTH_8      = $30

NuSizTab:
    .byte $30   ; $FF3E  laser and breakable wall width
    .byte $30   ; $FF3F
    .byte $20   ; $FF40
    .byte $20   ; $FF41
LFF42:
    .byte $70 ; | XXX    | $FF42
    .byte $B0 ; |X XX    | $FF43
    .byte $70 ; | XXX    | $FF44
    .byte $B0 ; |X XX    | $FF45
    .byte $70 ; | XXX    | $FF46
    .byte $70 ; | XXX    | $FF47
    .byte $70 ; | XXX    | $FF48
    .byte $B0 ; |X XX    | $FF49
    .byte $70 ; | XXX    | $FF4A
    .byte $B0 ; |X XX    | $FF4B
    .byte $70 ; | XXX    | $FF4C
    .byte $B0 ; |X XX    | $FF4D
    .byte $70 ; | XXX    | $FF4E
    .byte $70 ; | XXX    | $FF4F
    .byte $B0 ; |X XX    | $FF50
    .byte $70 ; | XXX    | $FF51
    .byte $B0 ; |X XX    | $FF52
    .byte $70 ; | XXX    | $FF53
    .byte $B0 ; |X XX    | $FF54
    .byte $70 ; | XXX    | $FF55
LFF56:
    .byte $B0 ; |X XX    | $FF56
    .byte $70 ; | XXX    | $FF57
    .byte $B0 ; |X XX    | $FF58
    .byte $70 ; | XXX    | $FF59
    .byte $B0 ; |X XX    | $FF5A
    .byte $B0 ; |X XX    | $FF5B
    .byte $B0 ; |X XX    | $FF5C
    .byte $70 ; | XXX    | $FF5D
    .byte $B0 ; |X XX    | $FF5E
    .byte $70 ; | XXX    | $FF5F
    .byte $B0 ; |X XX    | $FF60
    .byte $70 ; | XXX    | $FF61
    .byte $B0 ; |X XX    | $FF62
    .byte $B0 ; |X XX    | $FF63
    .byte $70 ; | XXX    | $FF64
    .byte $B0 ; |X XX    | $FF65
    .byte $70 ; | XXX    | $FF66
    .byte $B0 ; |X XX    | $FF67
    .byte $70 ; | XXX    | $FF68
    .byte $B0 ; |X XX    | $FF69
LFF6A:
 IF NTSC
    .byte $20 ; |  X     | $FF6A   $A4 ora screen color level 1
    .byte $C0 ; |XX      | $FF6B  other screens besides first
    .byte $90 ; |X  X    | $FF6C
 ELSE
    .byte $40 ; |  X     | $FF6A   $A4 ora screen color level 1
    .byte $50 ; |XX      | $FF6B  other screens besides first
    .byte $D0 ; |X  X    | $FF6C
 ENDIF   
SelectLevelTab:
    .byte  1-1  ; game 1, level 1
    .byte  5-1  ; game 2, level 5
    .byte  9-1  ; game 3, level 9
    .byte 13-1  ; game 4, level 13
    .byte 17-1  ; game 5, level 17
    
InitializeTab:
    .byte $20 ; |  X     | $FF72   $9B
    .byte $00 ; |        | $FF73
    .byte $00 ; |        | $FF74
    .byte $00 ; |        | $FF75
    .byte $8B ; |X   X XX| $FF76
    .byte $3D ; |  XXXX X| $FF77
    .byte $32 ; |  XX  X | $FF78
    .byte $32 ; |  XX  X | $FF79
    .byte $32 ; |  XX  X | $FF7A
 IF NTSC
    .byte $20 ; |  X     | $FF7B   $A4 ora screen color level 1
 ELSE
    .byte $40 ; |  X     | $FF7B   $A4 ora screen color level 1
 ENDIF
    .byte $93 ; |X  X  XX| $FF7C
    .byte $93 ; |X  X  XX| $FF7D
    .byte $93 ; |X  X  XX| $FF7E
    .byte $93 ; |X  X  XX| $FF7F
    .byte $93 ; |X  X  XX| $FF80
    .byte $93 ; |X  X  XX| $FF81
    .byte $00 ; |        | $FF82
    .byte $00 ; |        | $FF83
    .byte $95 ; |X  X X X| $FF84
    .byte $01 ; |       X| $FF85
    .byte $00 ; |        | $FF86
    .byte $00 ; |        | $FF87
    .byte $00 ; |        | $FF88
    .byte $06 ; |     XX | $FF89
    .byte $04 ; |     X  | $FF8A   $B3  used
    
    
LFF8B:
    .byte $1A ; |   XX X | $FF8B
    .byte $27 ; |  X  XXX| $FF8C
LFF8D:
    .byte $02 ; |      X | $FF8D
    .byte $0E ; |    XXX | $FF8E
LFF8F:
    .byte <DynamiteB+1   ; $FF8F
    .byte <DynamiteC     ; $FF90
    .byte <ExplosionA-1  ; $FF91
    .byte <ExplosionB    ; $FF92
LFF93:
    .byte <DynamiteA     ; $FF93
    .byte <DynamiteB     ; $FF94
    .byte <DynamiteC     ; $FF95
LFF96:
    .byte <ExplosionA    ; $FF96
    .byte <ExplosionB    ; $FF97
    .byte <ExplosionC    ; $FF98
    .byte <SeventyFive-1 ; $FF99
    .byte <SeventyFive   ; $FF9A

LFF9B:
    .byte $7F ; | XXXXXXX| $FF9B
    .byte $92 ; |X  X  X | $FF9C
LFF9D:
    .byte $E5 ; |XXX  X X| $FF9D
    .byte $CC ; |XX  XX  | $FF9E
    .byte $B3 ; |X XX  XX| $FF9F
    .byte $9A ; |X  XX X | $FFA0
    .byte $81 ; |X      X| $FFA1
LFFA2:
    .byte $81 ; |X      X| $FFA2
    .byte $9A ; |X  XX X | $FFA3
    .byte $B3 ; |X XX  XX| $FFA4
LFFA5:
    .byte $00 ; |        | $FFA5
    .byte $00 ; |        | $FFA6
    .byte $00 ; |        | $FFA7
    .byte $0A ; |    X X | $FFA8
    .byte $00 ; |        | $FFA9
LFFAA:
    .byte $00 ; |        | $FFAA
    .byte $01 ; |       X| $FFAB
LFFAC:
    .byte $93 ; |X  X  XX| $FFAC
    .byte $0F ; |    XXXX| $FFAD
LFFAE:
    .byte $06 ; |     XX | $FFAE
    .byte $04 ; |     X  | $FFAF
LFFB0:
    .byte $02 ; |      X | $FFB0
    .byte $01 ; |       X| $FFB1
    .byte $00 ; |        | $FFB2
    .byte $00 ; |        | $FFB3
    .byte $00 ; |        | $FFB4
    .byte $00 ; |        | $FFB5
    .byte $01 ; |       X| $FFB6
    .byte $02 ; |      X | $FFB7
LFFB8:
    .byte $0F ; |    XXXX| $FFB8
    .byte $1F ; |   XXXXX| $FFB9
    .byte $3F ; |  XXXXXX| $FFBA
    .byte $7F ; | XXXXXXX| $FFBB
    .byte $FF ; |XXXXXXXX| $FFBC
    .byte $7F ; | XXXXXXX| $FFBD
    .byte $3F ; |  XXXXXX| $FFBE
    .byte $1F ; |   XXXXX| $FFBF
LFFC0:
    .byte $00 ; |        | $FFC0
    .byte $00 ; |        | $FFC1
    .byte $00 ; |        | $FFC2
    .byte $00 ; |        | $FFC3
    .byte $00 ; |        | $FFC4
    .byte $01 ; |       X| $FFC5
    .byte $02 ; |      X | $FFC6
    .byte $03 ; |      XX| $FFC7
    
 IF PLUSROM    
PlusROM_API:
    .byte "a", 0, "h.firmaplus.de", 0
    
SendPlusROMScore:
    ldy    #$ff
    sty    ram_BA                ; 3
    lda    gameSelect
    AND    #$EF                  ; clear gameSelect bit 4
    sta    gameSelect
    sta    WriteToBuffer
    lda    scoreBCD
    sta    WriteToBuffer
    lda    scoreBCD+1
    sta    WriteToBuffer
    lda    scoreBCD+2
    sta    WriteToBuffer
    lda    #7                  ; H.E.R.O game id in Highscore DB
    sta    WriteSendBuffer     ; send request to backend..
    rts

       ORG $1FE4
      RORG $FFE4
 ELSE
    .byte $00 ; |        | $FFC8   free bytes
    .byte $00 ; |        | $FFC9
    .byte $00 ; |        | $FFCA
    .byte $00 ; |        | $FFCB
    .byte $00 ; |        | $FFCC
    .byte $00 ; |        | $FFCD
    .byte $00 ; |        | $FFCE
    .byte $00 ; |        | $FFCF
    .byte $00 ; |        | $FFD0
    .byte $00 ; |        | $FFD1
    .byte $00 ; |        | $FFD2
    .byte $00 ; |        | $FFD3
    .byte $00 ; |        | $FFD4
    .byte $00 ; |        | $FFD5
    .byte $00 ; |        | $FFD6
    .byte $00 ; |        | $FFD7
    .byte $00 ; |        | $FFD8
    .byte $00 ; |        | $FFD9
    .byte $00 ; |        | $FFDA
    .byte $00 ; |        | $FFDB
    .byte $00 ; |        | $FFDC
    .byte $00 ; |        | $FFDD
    .byte $00 ; |        | $FFDE
    .byte $00 ; |        | $FFDF
    .byte $00 ; |        | $FFE0
    .byte $00 ; |        | $FFE1
    .byte $00 ; |        | $FFE2
    .byte $00 ; |        | $FFE3
    .byte $00 ; |        | $FFE4
    .byte $00 ; |        | $FFE5
    .byte $00 ; |        | $FFE6
    .byte $00 ; |        | $FFE7
    .byte $00 ; |        | $FFE8
    .byte $00 ; |        | $FFE9
    .byte $00 ; |        | $FFEA
    .byte $00 ; |        | $FFEB

       ORG $1FEC
      RORG $FFEC
 ENDIF

LFFEC:
    bit    BANK_0                ; 4   bankswitch, goto LD079

    jsr    LDFEC                 ; 6
LFFF2:
    ldx    #$FF                  ; 2
    txs                          ; 2
    jmp    LF042                 ; 3

 IF PLUSROM
       ORG $1FFA
      RORG $FFFA
    .word $2FAB
 ELSE
  IF NTSC
    nop                          ; 2
  ELSE
    .byte $FF
  ENDIF
    nop                          ; 2
    nop                          ; 2
    nop                          ; 2
 ENDIF
    .word START_1
    .word START_1
