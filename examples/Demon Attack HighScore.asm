; Disassembly of Demon Attack
; by Omegamatrix
;
; Last update Oct 11, 2020
;
; - PlusCart High Scores support
; - NTSC, PAL, PAL60 versions
; - All versions are based off the fixed rom, and do not contain the fatal black screen as an "ending"

      processor 6502

    LIST OFF
      include vcs.h
      include macro.h
    LIST ON




PLUSROM              = 1

NTSC                 = 0
PAL                  = 0
PAL_60               = 1



;---------------------------------------

   IF PLUSROM
WriteToBuffer     equ $1ff0
WriteSendBuffer   equ $1ff1
ReceiveBuffer     equ $1ff2
ReceiveBufferSize equ $1ff3

HIGHSCORE_ID      equ 13      ; Demon Attack game ID in Highscore DB
   ENDIF

;---------------------------------------

  IF NTSC
_60_FRAMES           = 1
COL_NTSC             = 1
  ENDIF
  IF PAL_60
_60_FRAMES           = 1
COL_NTSC             = 0
  ENDIF
  IF PAL
_60_FRAMES           = 0
COL_NTSC             = 0
  ENDIF

;---------------------------------------

  IF _60_FRAMES
LINES_A              = $A5
TIME_VBLANK          = $2D
TIME_OVERSCAN        = $26
CONST_01             = $A0
  ELSE
LINES_A              = $CC
TIME_VBLANK          = $36
TIME_OVERSCAN        = $2B
CONST_01             = $C0
  ENDIF

;---------------------------------------

  IF COL_NTSC
COL_4C               = $4C
COL_4C_B             = $4C
COL_4E               = $4E
COL_6E               = $6E
COL_8C               = $8C
  ELSE
COL_4C               = $6C
COL_4C_B             = $6C+2
COL_4E               = $6E
COL_6E               = $AE
COL_8C               = $BC
  ENDIF



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      RIOT RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

       SEG.U RIOT_RAM
       ORG $80

ram_80             ds 1  ; x5
;-----------------------------
scoreHighBCD       ds 2  ; x4   $81-$82  note, player 1 and player 2 scores are interlaced in ram
scoreMidBCD        ds 2  ; x4   $83-$84
scoreLowBCD        ds 2  ; x4   $85-$86
;-----------------------------
ram_87             ds 3  ; x4
ram_8A             ds 3  ; x2
ram_8D             ds 1  ; x12
ram_8E             ds 1  ; x1
ram_8F             ds 1  ; x3
ram_90             ds 1  ; x9
ram_91             ds 1  ; x12
ram_92             ds 1  ; x1
ram_93             ds 1  ; x1
ram_94             ds 1  ; x7
ram_95             ds 1  ; x10
ram_96             ds 1  ; x4
ram_97             ds 1  ; x8
ram_98             ds 1  ; x3
ram_99             ds 1  ; x13
ram_9A             ds 1  ; x4
ram_9B             ds 1  ; x4
ram_9C             ds 1  ; x15
ram_9D             ds 1  ; x15
ram_9E             ds 1  ; x1
ram_9F             ds 2  ; x2
ram_A1             ds 1  ; x10
ram_A2             ds 1  ; x1
ram_A3             ds 2  ; x1
ram_A5             ds 1  ; x6
ram_A6             ds 9  ; x1
ram_AF             ds 1  ; x32
ram_B0             ds 1  ; x2
ram_B1             ds 1  ; x2
ram_B2             ds 1  ; x14
ram_B3             ds 1  ; x7
ram_B4             ds 1  ; x7
ram_B5             ds 1  ; x18
ram_B6             ds 1  ; x20
ram_B7             ds 1  ; x1
ram_B8             ds 1  ; x3
ram_B9             ds 1  ; x2
ram_BA             ds 1  ; x3
ram_BB             ds 1  ; x7
ram_BC             ds 1  ; x3
ram_BD             ds 1  ; x11
ram_BE             ds 1  ; x5
ram_BF             ds 1  ; x23
ram_C0             ds 1  ; x9
ram_C1             ds 1  ; x2
ram_C2             ds 1  ; x2
ram_C3             ds 1  ; x1
ram_C4             ds 1  ; x3
ram_C5             ds 1  ; x14
ram_C6             ds 1  ; x7
ram_C7             ds 1  ; x10
ram_C8             ds 1  ; x6
ram_C9             ds 3  ; x2
gameFlags          ds 1  ; x7  ram_CC
ram_CD             ds 1  ; x3
ram_CE             ds 1  ; x1
ram_CF             ds 1  ; x4
ram_D0             ds 1  ; x6
ram_D1             ds 1  ; x5
ram_D2             ds 1  ; x2
ram_D3             ds 1  ; x3
ram_D4             ds 1  ; x3
ram_D5             ds 1  ; x11
ram_D6             ds 1  ; x2
ram_D7             ds 1  ; x2
ram_D8             ds 1  ; x3
ram_D9             ds 1  ; x4
ram_DA             ds 1  ; x3
ram_DB             ds 1  ; x4
ram_DC             ds 1  ; x34
ram_DD             ds 1  ; x5
ram_DE             ds 1  ; x1
ram_DF             ds 2  ; x1
ram_E1             ds 2  ; x1
ram_E3             ds 2  ; x1
ram_E5             ds 2  ; x1
ram_E7             ds 2  ; x6
ram_E9             ds 1  ; x4
gameNumBCD         ds 1  ; x6  ram_EA     game number is stored as a value of 1 to 10
ram_EB             ds 1  ; x15
ram_EC             ds 1  ; x2
ram_ED             ds 1  ; x15
ram_EE             ds 1  ; x2
ram_EF             ds 1  ; x2
ram_F0             ds 1  ; x5
ram_F1             ds 1  ; x10
ram_F2             ds 1  ; x8
ram_F3             ds 1  ; x2
ram_F4             ds 1  ; x6
ram_F5             ds 1  ; x4
ram_F6             ds 1  ; x3
ram_F7             ds 1  ; x4
ram_F8             ds 1  ; x8
ram_F9             ds 7  ; x3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      MAIN PROGRAM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

       SEG CODE
       ORG $1000

L1000:
;     ldy    #$00                  ; 2
;     sta    WSYNC                 ; 3
; ;---------------------------------------
;     lda.wy ram_96,Y              ; 4
;     sta    HMBL                  ; 3
;     and    #$0F                  ; 2
;     tay                          ; 2
;     nop                          ; 2
;     nop                          ; 2
; L100E:
;     dey                          ; 2
;     bpl    L100E                 ; 2�
;     lda    ram_BD,X              ; 4
;     sta    RESBL                 ; 3
;     lda    ram_D2                ; 3
;     and    ram_D1                ; 3
;     sta    COLUP0                ; 3
;     sta    COLUP1                ; 3
;     lda    #$03                  ; 2
;     sta    NUSIZ0                ; 3
;     sta    NUSIZ1                ; 3
;     ldy    #$07                  ; 2
;     sta    WSYNC                 ; 3
; ;---------------------------------------
; L1027:
;     dey                          ; 2
;     bne    L1027                 ; 2�
;     nop                          ; 2
;     sta    RESP0                 ; 3
;     sta    RESP1                 ; 3
;     lda    #$F0                  ; 2
;     sta    HMP0                  ; 3
;     sty    HMP1                  ; 3
;     lda    #$01                  ; 2
;     sta    VDELP0                ; 3
;     sta    VDELP1                ; 3


    STA    WSYNC                 ; 3
;---------------------------------------
    LDA    ram_96                ; 3
    STA    HMBL                  ; 3
    AND    #$0F                  ; 2
    TAY                          ; 2
L100E:
    DEY                          ; 2
    BPL    L100E                 ; 2�
    LDA    ram_BD,X              ; 4
    LDA    ram_D2                ; 3
    LDY    #$03                  ; 2
    STA    RESBL                 ; 3
    AND    ram_D1                ; 3
    STA    COLUP0                ; 3
    STA    COLUP1                ; 3
    STY    NUSIZ0                ; 3
    STY    NUSIZ1                ; 3


    STA    WSYNC                 ; 3
;---------------------------------------
    LDY    #$07                  ; 2
L1027:
    DEY                          ; 2
    BNE    L1027                 ; 2�

    STA    RESP0                 ; 3
    STA    RESP1                 ; 3
    LDA    #$F1                  ; 2
    STA    HMP0                  ; 3
    STY    HMP1                  ; 3
    STA    VDELP0                ; 3
    STA    VDELP1                ; 3



    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    lda    ram_BC                ; 3
    sta    COLUBK                ; 3
    lda    #>L1E00               ; 2
    sta    ram_C1                ; 3
    sta    ram_C3                ; 3
L1049:
    lda    INTIM                 ; 4
    bne    L1049                 ; 2�
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    VBLANK                ; 3
    sta    HMCLR                 ; 3
    sta    CXCLR                 ; 3
    lda    #$09                  ; 2
    sta    ram_DC                ; 3
L105A:
    ldy    ram_DC                ; 3
    lda    (ram_DD),Y            ; 5
    sta    GRP0                  ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    lda    (ram_DF),Y            ; 5
    sta    GRP1                  ; 3
    lda    (ram_E1),Y            ; 5
    sta    GRP0                  ; 3
    lda    (ram_E3),Y            ; 5
    sta    ram_BF                ; 3
    lda    (ram_E5),Y            ; 5
    tax                          ; 2
    lda    (ram_E7),Y            ; 5
    tay                          ; 2
    lda    ram_BF                ; 3
    sta    GRP1                  ; 3
    stx    GRP0                  ; 3
    sty    GRP1                  ; 3
    sty    GRP0                  ; 3
    dec    ram_DC                ; 5
    bpl    L105A                 ; 2�
    ldy    #$00                  ; 2
    sty    GRP0                  ; 3
    sty    GRP1                  ; 3
    sty    VDELP0                ; 3
    sty    VDELP1                ; 3
    lda    #$08                  ; 2
    sta    REFP1                 ; 3
    ldx    #LINES_A              ; 2
    dey                          ; 2
    sty    ram_BF                ; 3
L1095:
    inc    ram_BF                ; 5
    sta    WSYNC                 ; 3
;---------------------------------------
    ldy.w  ram_BF                ; 4
    lda.wy ram_8D,Y              ; 4
    sta    HMP0                  ; 3
    and    #$0F                  ; 2
    tay                          ; 2
L10A4:
    dey                          ; 2
    bpl    L10A4                 ; 2�
    ldy    ram_BF                ; 3
    sta    RESP0                 ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    lda.wy ram_91,Y              ; 4
    sta    HMP1                  ; 3
    and    #$0F                  ; 2
    tay                          ; 2
    nop                          ; 2
    nop                          ; 2
L10B7:
    dey                          ; 2
    bpl    L10B7                 ; 2�
    ldy    ram_BF                ; 3
    sta    RESP1                 ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    cpy    #$03                  ; 2
    beq    L1117                 ; 2�+1
    lda.wy ram_9D,Y              ; 4
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    sta    ram_C0                ; 3
    lda.wy ram_A1,Y              ; 4
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    sta    ram_C2                ; 3
    lda.wy ram_C5,Y              ; 4
    sta    ram_C4                ; 3
    lda    #$00                  ; 2
    cpy    ram_97                ; 3
    bne    L10E3                 ; 2�
    lda    #$07                  ; 2
L10E3:
    sta    NUSIZ0                ; 3
    sta    NUSIZ1                ; 3
    dex                          ; 2
    dex                          ; 2
    dex                          ; 2
L10EA:
    sta    WSYNC                 ; 3
;---------------------------------------
    txa                          ; 2
    sec                          ; 2
    sbc    ram_C4                ; 3
    tay                          ; 2
    and    #$F8                  ; 2
    bne    L1103                 ; 2�+1
    lda    (ram_C0),Y            ; 5
    sta    GRP0                  ; 3
    lda    (ram_C2),Y            ; 5
    sta    GRP1                  ; 3
    lda    (ram_CD),Y            ; 5
    sta    COLUP0                ; 3
    sta    COLUP1                ; 3
L1103:
    txa                          ; 2
    sec                          ; 2
    sbc    ram_95                ; 3
    ldy    #$01                  ; 2
    and    #$F8                  ; 2
    bne    L110E                 ; 2�
    iny                          ; 2
L110E:
    sty    ENABL                 ; 3
    dex                          ; 2
    cpx    ram_C4                ; 3
    bcc    L1095                 ; 2�+1
    bcs    L10EA                 ; 3+1   always branch

L1117:
    lda    ram_D3                ; 3
    and    ram_D1                ; 3
    sta    COLUP0                ; 3
    lda    CXPPMM | $30          ; 3
    sta    ram_DC                ; 3
    lda    ram_99                ; 3
    bne    L1168                 ; 2�
    sta    REFP1                 ; 3
    sta    NUSIZ0                ; 3
    sta    NUSIZ1                ; 3
    bit    ram_EB                ; 3
    bpl    L1132                 ; 2�
    jmp    L11B2                 ; 3

L1132:
    lda    ram_B3                ; 3
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    sta    ram_C0                ; 3
L1139:
    sta    WSYNC                 ; 3
;---------------------------------------
    cpx    #$0C                  ; 2
    bcs    L1144                 ; 2�
    lda    L1D88,X               ; 4
    sta    GRP0                  ; 3
L1144:
    txa                          ; 2
    sec                          ; 2
    sbc    ram_C8                ; 3
    tay                          ; 2
    and    #$F8                  ; 2
    bne    L1155                 ; 2�
    lda    (ram_C0),Y            ; 5
    sta    GRP1                  ; 3
    lda    (ram_CD),Y            ; 5
    sta    COLUP1                ; 3
L1155:
    txa                          ; 2
    sec                          ; 2
    sbc    ram_95                ; 3
    ldy    #$01                  ; 2
    and    #$F8                  ; 2
    bne    L1160                 ; 2�
    iny                          ; 2
L1160:
    sty    ENABL                 ; 3
    dex                          ; 2
    bpl    L1139                 ; 2�
    jmp    L11F0                 ; 3

L1168:
    and    #$38                  ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tay                          ; 2
    lda    L1DBC,Y               ; 4
    sta    ram_C0                ; 3
    lda    #$1D                  ; 2
    sta    ram_C1                ; 3
    lda    #$00                  ; 2
    sta    NUSIZ0                ; 3
    sta    NUSIZ1                ; 3
L117D:
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    GRP0                  ; 3
    sta    GRP1                  ; 3
    txa                          ; 2
    ldy    #$01                  ; 2
    sec                          ; 2
    sbc    ram_95                ; 3
    and    #$F8                  ; 2
    bne    L118E                 ; 2�
    iny                          ; 2
L118E:
    sty    ENABL                 ; 3
    txa                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    bcs    L11A8                 ; 2�
    lsr                          ; 2
    tay                          ; 2
    bcs    L11A8                 ; 2�
    cpy    #$05                  ; 2
    bcs    L11A8                 ; 2�
    lda    L1DEC,Y               ; 4
    sta    COLUP0                ; 3
    sta    COLUP1                ; 3
    lda    (ram_C0),Y            ; 5
    bcc    L11AA                 ; 2�
L11A8:
    lda    #$00                  ; 2
L11AA:
    dex                          ; 2
    bpl    L117D                 ; 2�
    inx                          ; 2
    stx    REFP1                 ; 3
    beq    L11F0                 ; 2�
L11B2:
    lda    #COL_4E               ; 2
    sta    COLUP1                ; 3
    lda    CXP1FB | $30          ; 3
    sta    ram_BF                ; 3
L11BA:
    sta    WSYNC                 ; 3
;---------------------------------------
    cpx    #$0C                  ; 2
    bcs    L11C5                 ; 2�
    lda    L1D88,X               ; 4
    sta    GRP0                  ; 3
L11C5:
    txa                          ; 2
    sec                          ; 2
    sbc    ram_95                ; 3
    ldy    #$01                  ; 2
    and    #$F8                  ; 2
    bne    L11D0                 ; 2�
    iny                          ; 2
L11D0:
    sty    ENABL                 ; 3
    txa                          ; 2
    cmp    #$50                  ; 2
    bcs    L11ED                 ; 2�
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tay                          ; 2
    txa                          ; 2
    eor    #$FF                  ; 2
    eor    ram_BD                ; 3
    and    ram_EC                ; 3
    beq    L11E8                 ; 2�
    lda    #$00                  ; 2
    beq    L11EB                 ; 3   always branch

L11E8:
    lda.wy ram_A5,Y              ; 4
L11EB:
    sta    GRP1                  ; 3
L11ED:
    dex                          ; 2
    bpl    L11BA                 ; 2�
L11F0:
    ldx    #$00                  ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    stx    GRP0                  ; 3
    stx    GRP1                  ; 3
    stx    HMP0                  ; 3
    lda    #$10                  ; 2
    sta    HMP1                  ; 3
    lda    ram_F7                ; 3
    and    ram_D1                ; 3
    sta    ram_E7                ; 3
    sta    RESP0                 ; 3
    sta    RESP1                 ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    HMOVE                 ; 3
    bit    ram_F8                ; 3
    bmi    L1212                 ; 2�
    ldx    ram_ED                ; 3
L1212:
    ldy    ram_F2,X              ; 4
    lda    L1DAE,Y               ; 4
    sta    NUSIZ0                ; 3
    lda    L1DB5,Y               ; 4
    sta    NUSIZ1                ; 3
    ldx    ram_D4                ; 3
    stx    COLUP0                ; 3
    stx    COLUP1                ; 3
    ldx    #$06                  ; 2
M1228:
    lda    ram_E7                ; 3
L1228:
    sta    WSYNC                 ; 3
;---------------------------------------
    sta    COLUBK                ; 3
    dex                          ; 2
    bmi    L1247                 ; 2�
    lda    L1D9C,X               ; 4
    cpy    #$00                  ; 2
    beq    L123E                 ; 2�
    sta    GRP0                  ; 3
    cpy    #$02                  ; 2
    bcc    L123E                 ; 2�
    sta    GRP1                  ; 3
L123E:
    dec    ram_E7                ; 5
    dec    ram_E7                ; 5
;     lda    ram_E7                ; 3
;     jmp    L1228                 ; 3
    JMP    M1228

L1247:
    jmp    L187A                 ; 3




START:
;     sei                          ; 2
;     cld                          ; 2
;     ldx    #$FF                  ; 2
;     txs                          ; 2
;     inx                          ; 2
;     txa                          ; 2
; L1251:
;     sta    0,X                   ; 4
;     inx                          ; 2
;     bne    L1251                 ; 2�

    cld
.splshLoopClear:
    ldx    #$0A                  ; ASL opcode = $0A
    inx
    txs
    pha
    bne    .splshLoopClear+1     ; jump between operator and operand to do ASL


    inx                          ; 2
    stx    gameNumBCD            ; 3
    jsr    L1AA7                 ; 6
    lda    #$AB                  ; 2
    sta    scoreHighBCD          ; 3
    lda    #$CD                  ; 2
    sta    scoreMidBCD           ; 3
    lda    #$EA                  ; 2
    sta    scoreLowBCD           ; 3
  IF _60_FRAMES
    sta    ram_D5                ; 3
    ldx    #$0A                  ; 2
  ELSE
    ldx    #$0A                  ; 2
    stx    ram_D5                ; 3
  ENDIF
    lda    #$1F                  ; 2
L126E:
    sta    ram_DE,X              ; 4
    dex                          ; 2
    dex                          ; 2
    bpl    L126E                 ; 2�
    jmp    L145A                 ; 3

L1277:
    lda    #$02                  ; 2
    sta    VBLANK                ; 3
    ldx    #$19                  ; 2
    sta    WSYNC                 ; 3
;---------------------------------------
    stx    TIM8T                 ; 4
    sta    VSYNC                 ; 3
    ldx    #$00                  ; 2
    bit    ram_F1                ; 3
    bmi    L128E                 ; 2�
    stx    ram_B5                ; 3
    bpl    L1292                 ; 2�
L128E:
    lda    ram_99                ; 3
    bne    L12A7                 ; 2�
L1292:
    lda    ram_B5                ; 3
    and    #$0F                  ; 2
    asl                          ; 2

    ADC    #8              ; add an offset to use a pre-existing table and code
    BNE    DoIndirectJump  ; always branch


;     tay                          ; 2
;     lda    L12A1+1,Y             ; 4
;     pha                          ; 3
;     lda    L12A1,Y               ; 4
;     pha                          ; 3
;     rts                          ; 6

; L12A1:
;     .word (L12D2-1)
;     .word (L12CC-1)
;     .word (L12B2-1)

L12A7:
    lsr                          ; 2
    lsr                          ; 2
    tax                          ; 2
    lda    ram_99                ; 3
    and    #$1F                  ; 2
    ldy    #$08                  ; 2
    bne    L12D2                 ; 3   always branch

L12B2: ; indirect jump
    lda    ram_CF                ; 3
    asl                          ; 2
    tax                          ; 2
    lda    ram_CF                ; 3
    eor    #$FF                  ; 2
    and    #$07                  ; 2
    ldy    #$0F                  ; 2
    dec    ram_CF                ; 5
    bpl    L12D2                 ; 2�
    lda    ram_B5                ; 3
    and    #$F0                  ; 2
    sta    ram_B5                ; 3
    ldx    #$00                  ; 2
    beq    L12D2                 ; 3   always branch

L12CC: ; indirect jump
    ldx    #$0C                  ; 2
    lda    ram_BB                ; 3
    ldy    #$08                  ; 2
L12D2: ; indirect jump also
    stx    AUDV0                 ; 3
    sty    AUDC0                 ; 3
    sta    AUDF0                 ; 3
    ldx    #$00                  ; 2
    lda    ram_F4                ; 3
    bne    L131D                 ; 2�+1
    lda    ram_B5                ; 3
    and    #$F0                  ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
DoIndirectJump:
    tay                          ; 2
    lda    L12EF+1,Y             ; 4
    pha                          ; 3
    lda    L12EF,Y               ; 4
    pha                          ; 3
    rts                          ; 6

L12EF:
    .word (L1388-1)
    .word (L135C-1)
    .word (L134F-1)
    .word (L12F7-1)

L12A1:
    .word (L12D2-1)
    .word (L12CC-1)
    .word (L12B2-1)


L12F7: ; indirect jump
    dec    ram_D0                ; 5
    lda    ram_D0                ; 3
    bne    L1305                 ; 2�+1
    sta    ram_B5                ; 3
    lda    #COL_4C               ; 2
    sta    ram_F7                ; 3
    bne    L1317                 ; 3   always branch

L1305:
    tay                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tax                          ; 2
    inc    ram_F7                ; 5
    lda    L1E00,Y               ; 4
    and    #$07                  ; 2
    sta    AUDF0                 ; 3
    adc    #$05                  ; 2
    stx    AUDV0                 ; 3
L1317:
    ldy    #$0C                  ; 2
    sty    AUDC0                 ; 3
    bne    L1388                 ; 3   always branch

L131D:
    dec    ram_F4                ; 5
    lda    ram_F4                ; 3
    bne    L1330                 ; 2�
    ldx    ram_ED                ; 3
    bit    ram_F8                ; 3
    bpl    L132B                 ; 2�
    ldx    #$00                  ; 2
L132B:
    inc    ram_F2,X              ; 6
    inx                          ; 2
    stx    ram_BA                ; 3
L1330:
    cmp    #$3D                  ; 2
    bcs    L1388                 ; 2�
    eor    #$FF                  ; 2
    sta    ram_D4                ; 3
    eor    #$FF                  ; 2
    lsr                          ; 2
    lsr                          ; 2
    tay                          ; 2
    lda    L1FEC,Y               ; 4
    beq    L1388                 ; 2�
    tay                          ; 2
    lda    ram_F4                ; 3
    and    #$03                  ; 2
    asl                          ; 2
    asl                          ; 2
    tax                          ; 2
    tya                          ; 2
    ldy    #$04                  ; 2
    bne    L1388                 ; 3   always branch

L134F: ; indirect jump
    ldx    #$08                  ; 2
    ldy    ram_D0                ; 3
    inc    ram_D0                ; 5
    lda    L1E00,Y               ; 4
    and    #$07                  ; 2
    bpl    L137F                 ; 3   always branch

L135C: ; indirect jump
    lda    ram_BD                ; 3
    eor    #$FF                  ; 2
    and    #$0F                  ; 2
    sec                          ; 2
    sbc    #$04                  ; 2
    bcc    L1388                 ; 2�
    tax                          ; 2
    bit    ram_B2                ; 3
    bmi    L1383                 ; 2�
    lda    ram_BD                ; 3
    and    #$10                  ; 2
    beq    L1376                 ; 2�
    ldx    #$00                  ; 2
    beq    L1388                 ; 3   always branch

L1376:
    lda    #$14                  ; 2
    sec                          ; 2
    sbc    ram_9B                ; 3
    clc                          ; 2
    adc    L1FA2,X               ; 4
L137F:
    ldy    #$0C                  ; 2
    bne    L1388                 ; 3   always branch

L1383:
    lda    L1F96,X               ; 4
    ldy    #$04                  ; 2
L1388: ; indirect jump also
    stx    AUDV1                 ; 3
    sty    AUDC1                 ; 3
    sta    AUDF1                 ; 3
L138E:
    lda    INTIM                 ; 4
    bne    L138E                 ; 2�
    sta    VSYNC                 ; 3
    sta    WSYNC                 ; 3
;---------------------------------------
    lda    #TIME_VBLANK          ; 2
    sta    TIM64T                ; 4
    inc    ram_BD                ; 5
    bne    L13BC                 ; 2�
    inc    ram_B9                ; 5
    bit    gameFlags             ; 3
    bmi    L13B2                 ; 2�
    lda    ram_B9                ; 3
    bne    L13AE                 ; 2�
    lda    #$F3                  ; 2
    sta    ram_D1                ; 3
L13AE:
    lda    ram_F5                ; 3
    bne    L13B6                 ; 2�
L13B2:
    bit    ram_F8                ; 3
    bpl    L13BC                 ; 2�
L13B6:
    lda    ram_ED                ; 3
    eor    #$01                  ; 2
    sta    ram_ED                ; 3
L13BC:
    lda    ram_D5                ; 3
    asl                          ; 2
    eor    ram_D5                ; 3
    asl                          ; 2
    asl                          ; 2
    rol    ram_D5                ; 5
    lda    SWCHB                 ; 4
    ror    ram_9C                ; 5
    bcs    L13D0                 ; 2�
    lsr                          ; 2
    bcs    L141C                 ; 2�+1
    rol                          ; 2
L13D0:
    lsr                          ; 2
    rol    ram_9C                ; 5
    lsr                          ; 2
    bit    ram_E9                ; 3
    bcc    L13DC                 ; 2�
    rol    ram_E9                ; 5
    bne    L1405                 ; 2�+1
L13DC:
    bpl    L13FD                 ; 2�
L13DE:
    lda    ram_BD                ; 3
    and    #$1F                  ; 2
    sta    ram_E9                ; 3
    jsr    L1AA7                 ; 6
    jsr    L1AD2                 ; 6    A=0 and C=1 after subroutine
    sed                          ; 2
    lda    gameNumBCD            ; 3
;     clc                          ; 2
;     adc    #$01                  ; 2
    ADC     #0

    cld                          ; 2
;     sta    gameNumBCD            ; 3   set below now
    cmp    #$11                  ; 2
    bne    M1405  ;L1405                 ; 2�+1
    lda    #$01                  ; 2
M1405:
    sta    gameNumBCD            ; 3
    bne    L1405                 ; 2�+1   always branch


L13FD:
    lda    ram_E9                ; 3
    eor    ram_BD                ; 3
    and    #$1F                  ; 2
    beq    L13DE                 ; 2�+1
L1405:
    bit    gameFlags             ; 3
    bmi    L1419                 ; 2�
    lda    ram_B5                ; 3
    cmp    #$30                  ; 2
    beq    L1419                 ; 2�
    lda    INPT4 | $30           ; 3
    bpl    L1417                 ; 2�
    bit    ram_F9                ; 3
    bpl    L141C                 ; 2�
L1417:
    sta    ram_F9                ; 3
L1419:
    jmp    L14DC                 ; 3

L141C:
    ldx    #$FF                  ; 2
    stx    ram_F1                ; 3
    stx    gameFlags             ; 3
    stx    ram_BE                ; 3
    inx                          ; 2
    ldy    gameNumBCD            ; 3
    dey                          ; 2
    tya                          ; 2
    ldy    #$00                  ; 2
    sty    ram_F8                ; 3
    cmp    #$08                  ; 2
    bcs    L1442                 ; 2�
    lsr                          ; 2
    bcc    L1435                 ; 2�
    iny                          ; 2
L1435:
    lsr                          ; 2
    bcc    L1439                 ; 2�
    dex                          ; 2
L1439:
    lsr                          ; 2
    bcc    L144A                 ; 2�
    lda    #$0B                  ; 2
    sta    ram_BE                ; 3
    bne    L144A                 ; 3   always branch

L1442:
    dex                          ; 2
    stx    ram_F8                ; 3
    cmp    #$08                  ; 2
    bne    L144A                 ; 2�
    inx                          ; 2
L144A:
    stx    ram_F6                ; 3
    sty    ram_F5                ; 3
    sty    ram_ED                ; 3
    lda    #$03                  ; 2
    sta    ram_F2                ; 3
    sta    ram_F3                ; 3
    ldx    #$81                  ; 2
;     bne    L145C                 ; 3   always branch

    .BYTE $0C   ; NOP, skip 2 bytes

L145A:
    ldx    #$87                  ; 2
L145C:
    lda    #$00                  ; 2
L145E:
    sta    0,X                   ; 4
    inx                          ; 2
    cpx    #$BD                  ; 2
    bne    L145E                 ; 2�
    bit    ram_F8                ; 3
    bmi    L147C                 ; 2�
    lda    ram_F5                ; 3
    beq    L147C                 ; 2�
    lda    ram_ED                ; 3
    eor    #$01                  ; 2
    tax                          ; 2
    lda    ram_F2,X              ; 4
    bmi    L147C                 ; 2�
    stx    ram_ED                ; 3
    cpx    #$00                  ; 2
    bne    L147E                 ; 2�
L147C:
    inc    ram_BE                ; 5
L147E:
    lda    ram_BE                ; 3
    cmp    #$54                  ; 2
;     nop                          ; 2
;     nop                          ; 2
    sta    ram_80                ; 3
    cmp    #$0C                  ; 2
    bcc    L1496                 ; 2�
L148A:
    sbc    #$0C                  ; 2
    cmp    #$0C                  ; 2
    bcs    L148A                 ; 2�
    sta    ram_80                ; 3
    and    #$03                  ; 2
    adc    #$08                  ; 2
L1496:
    sta    ram_F0                ; 3
    lsr                          ; 2
    tax                          ; 2
    lda    #$2C                  ; 2
    sec                          ; 2
    sbc    ram_F0                ; 3
    sbc    ram_F0                ; 3
    sta    ram_98                ; 3
    lda    L1DF1,X               ; 4
    sta    ram_EB                ; 3
    ldy    #$01                  ; 2
    and    #$20                  ; 2
    beq    L14B0                 ; 2�
    ldy    #$81                  ; 2
L14B0:
    tya                          ; 2
    ora    ram_9C                ; 3
    sta    ram_9C                ; 3
    lda    #$04                  ; 2
    bit    ram_EB                ; 3
    bvc    L14BD                 ; 2�
    lda    #$00                  ; 2
L14BD:
    sta    ram_EC                ; 3
    lda    L1DF7,X               ; 4
    sta    ram_EE                ; 3
    lda    ram_BE                ; 3
    sec                          ; 2
L14C7:
    sbc    #$07                  ; 2
    bcs    L14C7                 ; 2�
    adc    #$07                  ; 2
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    clc                          ; 2
    adc    #$AE                  ; 2
    sta    ram_CD                ; 3
    lda    #$1F                  ; 2
    sta    ram_CE                ; 3
    jsr    L1AA7                 ; 6
L14DC:
    bit    ram_F1                ; 3
    bpl    L14E7                 ; 2�
    bit    gameFlags             ; 3
    bmi    L14E7                 ; 2�
    jmp    L1822                 ; 3

L14E7:
    lda    ram_BD                ; 3
    and    #$07                  ; 2
    tay                          ; 2
    ldx    L1D94,Y               ; 4
    bmi    L1535                 ; 2�+1
    cpx    #$03                  ; 2
    bne    L14FF                 ; 2�
    lda    ram_B3                ; 3
    jsr    L1B28                 ; 6
    sta    ram_B3                ; 3
    jmp    L1533                 ; 3

L14FF:
    lda    ram_B6,X              ; 4
    bpl    L152C                 ; 2�
    lda    ram_9D,X              ; 4
    cmp    ram_A1,X              ; 4
    bne    L1515                 ; 2�
    cmp    #$05                  ; 2
    bcc    L1515                 ; 2�
    jsr    L1B03                 ; 6
;     sta    ram_9D,X              ; 4
;     jmp    L1533                 ; 3
    JMP    M1533


L1515:
    lda    #$BF                  ; 2
    sta    ram_BF                ; 3
    lda    ram_9D,X              ; 4
    jsr    L1B03                 ; 6
    sta    ram_9D,X              ; 4
    lda    #$DF                  ; 2
    sta    ram_BF                ; 3
    lda    ram_A1,X              ; 4
    jsr    L1B03                 ; 6
    jmp    L1533                 ; 3

L152C:
    lda    ram_9D,X              ; 4
    jsr    L1B28                 ; 6
M1533:
    sta    ram_9D,X              ; 4
L1533:
    sta    ram_A1,X              ; 4
L1535:
    lda    ram_99                ; 3
    bne    L15AB                 ; 2�
    bit    ram_B2                ; 3
    bmi    L154F                 ; 2�
    lda    ram_B8                ; 3
    and    #$60                  ; 2
    beq    L154F                 ; 2�
    cmp    #$60                  ; 2
    beq    L154F                 ; 2�
    jsr    L1D31                 ; 6
    bcs    L154F                 ; 2�
    jsr    L1BB8                 ; 6
L154F:
    bit    ram_F1                ; 3
    bmi    L155D                 ; 2�
    ldx    #$06                  ; 2
    bit    ram_BD                ; 3
    bvc    L156B                 ; 2�
    ldx    #$0A                  ; 2
    bne    L156B                 ; 3   always branch

L155D:
    lda    SWCHA                 ; 4
    ldx    ram_ED                ; 3
    bne    L1568                 ; 2�
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
L1568:
    and    #$0F                  ; 2
    tax                          ; 2
L156B:
    ldy    #$01                  ; 2
    bit    ram_F6                ; 3
    bpl    L1572                 ; 2�
    iny                          ; 2
L1572:
    lda    ram_90                ; 3
    cpx    #$08                  ; 2
    bcc    L158B                 ; 2�
    beq    L15AB                 ; 2�
    cpx    #$0C                  ; 2
    bcs    L15AB                 ; 2�
    cmp    #$31                  ; 2
    beq    L15AB                 ; 2�
    cmp    #$21                  ; 2
    beq    L15AB                 ; 2�
    jsr    L1CDE                 ; 6
    beq    L159A                 ; 2�
L158B:
    cpx    #$05                  ; 2
    bcc    L15AB                 ; 2�
    cmp    #$C8                  ; 2
    beq    L15AB                 ; 2�
    cmp    #$D8                  ; 2
    beq    L15AB                 ; 2�
    jsr    L1CCF                 ; 6
L159A:
    sta    ram_90                ; 3
    bit    ram_F6                ; 3
    bmi    L15A4                 ; 2�
    bit    ram_9C                ; 3
    bvs    L15AB                 ; 2�
L15A4:
    ldy    #$01                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_96                ; 3
L15AB:
    bit    ram_9C                ; 3
    bvs    L15D5                 ; 2�
    lda    ram_99                ; 3
    bne    L15E3                 ; 2�
    bit    ram_F1                ; 3
    bpl    L15BD                 ; 2�
    ldx    ram_ED                ; 3
    lda    INPT4 | $30,X         ; 4
    bmi    L15E3                 ; 2�
L15BD:
    lda    ram_9C                ; 3
    ora    #$40                  ; 2
    sta    ram_9C                ; 3
    lda    ram_97                ; 3
    bpl    L15E3                 ; 2�
    lda    ram_B5                ; 3
    and    #$F0                  ; 2
    ora    #$02                  ; 2
    sta    ram_B5                ; 3
    lda    #$07                  ; 2
    sta    ram_CF                ; 3
    bne    L15E3                 ; 3   always branch

L15D5:
    lda    ram_95                ; 3
    clc                          ; 2
    adc    ram_EE                ; 3
    sta    ram_95                ; 3
    cmp    #CONST_01             ; 2
    bcc    L15E3                 ; 2�
    jsr    L1CED                 ; 6
L15E3:
    ldy    ram_BB                ; 3
    bne    L1635                 ; 2�+1
    ldx    #$02                  ; 2
L15E9:
    lda    ram_AF,X              ; 4
    and    #$C0                  ; 2
    beq    L161C                 ; 2�+1
    iny                          ; 2
L15F0:
    dex                          ; 2
    bpl    L15E9                 ; 2�
    cpy    #$00                  ; 2
    bne    L1633                 ; 2�+1
    bit    ram_B2                ; 3
    bmi    L1633                 ; 2�+1
    lda    ram_99                ; 3
    ora    ram_F4                ; 3
    bne    L1635                 ; 2�
    ldx    ram_ED                ; 3
    bit    ram_F8                ; 3
    bpl    L1609                 ; 2�
    ldx    #$00                  ; 2
L1609:
    lda    ram_BA                ; 3
    bne    L1619                 ; 2�
    lda    ram_F2,X              ; 4
    cmp    #$06                  ; 2
    bcs    L1619                 ; 2�
    lda    #$48                  ; 2
    sta    ram_F4                ; 3
    bne    L1633                 ; 3   always branch

L1619:
    jmp    L145A                 ; 3

L161C:
    bit    ram_F1                ; 3
    bpl    L1626                 ; 2�
    lda    ram_9B                ; 3
    cmp    #$08                  ; 2
    beq    L15F0                 ; 2�+1
L1626:
    lda    ram_D5                ; 3
    and    #$1F                  ; 2
    ora    #$01                  ; 2
    sta    ram_BB                ; 3
    jsr    L1D09                 ; 6
    sta    ram_C5,X              ; 4
L1633:
    stx    ram_97                ; 3
L1635:
    lda    ram_BD                ; 3
    and    #$03                  ; 2
    beq    L166B                 ; 2�
    tax                          ; 2
    dex                          ; 2
    jsr    L1D09                 ; 6
    cmp    ram_C5,X              ; 4
    bcs    L1648                 ; 2�
    dec    ram_C5,X              ; 6
    bne    L164A                 ; 2�
L1648:
    inc    ram_C5,X              ; 6
L164A:
    lda    ram_D5                ; 3
    cpx    #$02                  ; 2
    bne    L1661                 ; 2�
    lda    ram_8D,X              ; 4
    jsr    L1D3D                 ; 6
    bit    ram_9C                ; 3
    bvc    L166B                 ; 2�
    lda    ram_95                ; 3
    cmp    ram_C7                ; 3
    bcc    L1665                 ; 2�
    bcs    L166B                 ; 3   always branch

L1661:
    and    #$07                  ; 2
    bne    L166B                 ; 2�
L1665:
    lda    ram_AF,X              ; 4
    eor    #$10                  ; 2
    sta    ram_AF,X              ; 4
L166B:
    jsr    L1C33                 ; 6
    bit    ram_9C                ; 3
    bpl    L16BA                 ; 2�
    ldx    #$02                  ; 2
L1674:
    lda    ram_B6,X              ; 4
    and    #$20                  ; 2
    beq    L16B7                 ; 2�
    lda    ram_B6,X              ; 4
    and    #$08                  ; 2
    beq    L16B7                 ; 2�
    ldy    #$01                  ; 2
    lda    ram_B6,X              ; 4
    and    #$10                  ; 2
    beq    L16A6                 ; 2�
    lda    ram_91,X              ; 4
    cmp    #$C9                  ; 2
    beq    L1696                 ; 2�
    jsr    L1CCF                 ; 6
;     sta    ram_91,X              ; 4
;     jmp    L16B1                 ; 3
    JMP    M16B1


L1696:
    lda    ram_B6,X              ; 4
    eor    #$10                  ; 2
    sta    ram_B6,X              ; 4
    lda    ram_AF,X              ; 4
    and    #$F0                  ; 2
    ora    #$01                  ; 2
    sta    ram_AF,X              ; 4
    bne    L16B1                 ; 2�
L16A6:
    lda    ram_91,X              ; 4
    cmp    #$71                  ; 2
    beq    L1696                 ; 2�
    jsr    L1CDE                 ; 6
M16B1:
    sta    ram_91,X              ; 4
L16B1:
    lda    ram_B6,X              ; 4
    and    #$F7                  ; 2
    sta    ram_B6,X              ; 4
L16B7:
    dex                          ; 2
    bpl    L1674                 ; 2�
L16BA:
    lda    ram_98                ; 3
    bit    ram_B2                ; 3
    bpl    L16C5                 ; 2�
    lda    ram_C8                ; 3
    clc                          ; 2
    adc    #$0C                  ; 2
L16C5:
    sta    ram_DC                ; 3
    lda    ram_C5                ; 3
    cmp    #$97                  ; 2
    bcc    L16CF                 ; 2�
    lda    #$97                  ; 2
L16CF:
    cmp    #$48                  ; 2
    bcs    L16D5                 ; 2�
    lda    #$48                  ; 2
L16D5:
    sta    ram_C5                ; 3
    sec                          ; 2
    sbc    #$0C                  ; 2
    cmp    ram_C6                ; 3
    bcs    L16E0                 ; 2�
    sta    ram_C6                ; 3
L16E0:
    lda    ram_C6                ; 3
    sec                          ; 2
    sbc    #$0C                  ; 2
    cmp    ram_C7                ; 3
    bcs    L16EB                 ; 2�
    sta    ram_C7                ; 3
L16EB:
    lda    ram_C7                ; 3
    cmp    ram_DC                ; 3
    bcs    L16F5                 ; 2�
    lda    ram_DC                ; 3
    sta    ram_C7                ; 3
L16F5:
    lda    ram_EB                ; 3
    and    #$10                  ; 2
    beq    L1712                 ; 2�+1
    lda    ram_99                ; 3
    bne    L1712                 ; 2�+1
    lda    ram_97                ; 3
    cmp    #$02                  ; 2
    beq    L1712                 ; 2�
    bit    ram_B2                ; 3
    bmi    L1712                 ; 2�
    lda    ram_8F                ; 3
    ldy    #$04                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_94                ; 3
L1712:
    ldx    ram_97                ; 3
    bmi    L1744                 ; 2�
    lda    ram_BB                ; 3
    beq    L1783                 ; 2�
    dec    ram_BB                ; 5
    bne    L1783                 ; 2�
    lda    ram_AF,X              ; 4
    and    #$C0                  ; 2
    beq    L1747                 ; 2�
    lda    #$90                  ; 2
    sta    ram_AF,X              ; 4
    lda    #COL_4C_B             ; 2
    sta    ram_D4                ; 3
    lda    #$10                  ; 2
    sta    ram_B5                ; 3
    lda    ram_80                ; 3
    lsr                          ; 2
    tay                          ; 2
    lda    L1B9F,Y               ; 4
    sta    ram_9D,X              ; 4
    sta    ram_A1,X              ; 4
    lda    ram_8D,X              ; 4
    ldy    #$08                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_91,X              ; 4
L1744:
    jmp    L17CF                 ; 3

L1747:
    inc    ram_9B                ; 5
    lda    ram_AF,X              ; 4
    ora    #$40                  ; 2
    sta    ram_AF,X              ; 4
    lda    ram_D5                ; 3
    and    #$7C                  ; 2
    clc                          ; 2
    adc    #$10                  ; 2
    sta    ram_DC                ; 3
    lsr                          ; 2
    sta    ram_D6                ; 3
    lda    #$A0                  ; 2
    sec                          ; 2
    sbc    ram_DC                ; 3
    lsr                          ; 2
    sta    ram_D7                ; 3
    ldy    #$00                  ; 2
    sty    ram_D8                ; 3
    sty    ram_D9                ; 3
    sty    ram_DA                ; 3
    sty    ram_DB                ; 3
    sty    ram_B6,X              ; 4
    lda    #$70                  ; 2
    sta    ram_8D,X              ; 4
    lda    #$A9                  ; 2
    sta    ram_91,X              ; 4
    lda    #$20                  ; 2
    sta    ram_BB                ; 3
    lda    ram_B5                ; 3
    and    #$F0                  ; 2
    ora    #$01                  ; 2
    sta    ram_B5                ; 3
L1783:
    lda    ram_AF,X              ; 4
    and    #$C0                  ; 2
    cmp    #$40                  ; 2
    bne    L17CF                 ; 2�
    ldy    ram_D8                ; 3
    lda    ram_87,X              ; 4
    clc                          ; 2
    adc    ram_D9                ; 3
    sta    ram_87,X              ; 4
    bcc    L1797                 ; 2�
    iny                          ; 2
L1797:
    cpy    #$00                  ; 2
    beq    L17A2                 ; 2�
    lda    ram_8D,X              ; 4
    jsr    L1CCF                 ; 6
    sta    ram_8D,X              ; 4
L17A2:
    ldy    ram_DA                ; 3
    lda    ram_8A,X              ; 4
    clc                          ; 2
    adc    ram_DB                ; 3
    sta    ram_8A,X              ; 4
    bcc    L17AE                 ; 2�
    iny                          ; 2
L17AE:
    cpy    #$00                  ; 2
    beq    L17B9                 ; 2�
    lda    ram_91,X              ; 4
    jsr    L1CDE                 ; 6
    sta    ram_91,X              ; 4
L17B9:
    lda    ram_D9                ; 3
    clc                          ; 2
    adc    ram_D6                ; 3
    sta    ram_D9                ; 3
    bcc    L17C4                 ; 2�
    inc    ram_D8                ; 5
L17C4:
    lda    ram_DB                ; 3
    clc                          ; 2
    adc    ram_D7                ; 3
    sta    ram_DB                ; 3
    bcc    L17CF                 ; 2�
    inc    ram_DA                ; 5
L17CF:
    bit    ram_EB                ; 3
    bpl    L1822                 ; 2�+1
    ldy    ram_F0                ; 3
    inc    ram_9A                ; 5
    lda    ram_9A                ; 3
    cmp    L1DA2,Y               ; 4
    bne    L1822                 ; 2�+1
    jsr    L1AE6                 ; 6
    ldx    #$00                  ; 2
    stx    ram_9A                ; 3
L17E5:
    lda    ram_A6,X              ; 4
    sta    ram_A5,X              ; 4
    inx                          ; 2
    cpx    #$09                  ; 2
    bne    L17E5                 ; 2�
    lda    ram_C7                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    tax                          ; 2
    cpx    #$0A                  ; 2
    bcc    L17FA                 ; 2�
    ldx    #$09                  ; 2
L17FA:
    lda    ram_B4                ; 3
    bne    L1802                 ; 2�+1
    ldx    #$09                  ; 2
    bne    L1820                 ; 3   always branch

L1802:
    dec    ram_B4                ; 5
    bit    ram_EB                ; 3
    bvc    L1812                 ; 2�
    lda    #$81                  ; 2
    bit    ram_B8                ; 3
    bpl    L1820                 ; 2�
    lda    #$80                  ; 2
    bne    L1820                 ; 3   always branch

L1812:
    lda    #$0F                  ; 2
    bit    ram_B8                ; 3
    bpl    L181A                 ; 2�
    lda    #$03                  ; 2
L181A:
    and    ram_D5                ; 3
    tay                          ; 2
    lda    L1EE0,Y               ; 4
L1820:
    sta    ram_A5,X              ; 4
L1822:
    ldx    #$00                  ; 2
    txa                          ; 2
    bit    ram_F1                ; 3
    bpl    L183D                 ; 2�
    bit    gameFlags             ; 3
    bvs    L183D                 ; 2�
    jsr    L1C11                 ; 6
    lda    gameNumBCD            ; 3
    jsr    L1C11                 ; 6
    lda    #$AA                  ; 2
;     jsr    L1C11                 ; 6
;     jmp    L1851                 ; 3
    JMP    M1851


L183D:
    ldy    ram_ED                ; 3
    lda.wy scoreHighBCD,Y        ; 4
    jsr    L1C11                 ; 6
    lda.wy scoreMidBCD,Y         ; 4
    jsr    L1C11                 ; 6
    lda.wy scoreLowBCD,Y         ; 4
M1851:
    jsr    L1C11                 ; 6
L1851:
    ldx    #$00                  ; 2
L1853:
    lda    ram_DD,X              ; 4
    bne    L1861                 ; 2�
    lda    #$64                  ; 2
    sta    ram_DD,X              ; 4
    inx                          ; 2
    inx                          ; 2
    cpx    #$0A                  ; 2
    bne    L1853                 ; 2�
L1861:
    ldx    ram_B5                ; 3
    cpx    #$30                  ; 2
    bne    L186B                 ; 2�
    lda    ram_BC                ; 3
    bcs    L1870                 ; 2�
L186B:
    ldy    ram_ED                ; 3
    lda    L1ACE,Y               ; 4
L1870:
    sta    ram_D3                ; 3
    lda    L1AD0,Y               ; 4
    sta    ram_D2                ; 3
    jmp    L1000                 ; 3

L187A:
    lda    #TIME_OVERSCAN        ; 2
    sta    TIM64T                ; 4
    bit    ram_EB                ; 3
    bmi    L1887                 ; 2�
    lda    CXP1FB | $30          ; 3
    sta    ram_BF                ; 3
L1887:
    lda    CXPPMM | $30          ; 3
    bpl    L18B5                 ; 2�
    bit    ram_DC                ; 3
    bmi    L18B5                 ; 2�
    lda    #$40                  ; 2
    sta    ram_99                ; 3
    sta    ram_BA                ; 3
    lda    ram_90                ; 3
    ldy    #$04                  ; 2
    jsr    L1CDE                 ; 6
    sta    ram_90                ; 3
    ldy    #$08                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_94                ; 3
    sty    ram_B4                ; 3
    sty    ram_B2                ; 3
    lda    ram_EB                ; 3
    ora    #$80                  ; 2
    sta    ram_EB                ; 3
    bit    ram_9C                ; 3
    bvs    L18B5                 ; 2�
    sty    COLUPF                ; 3
L18B5:
    lda    ram_99                ; 3
    beq    L191F                 ; 2�+1
    dec    ram_99                ; 5
    bne    L1915                 ; 2�+1
    lda    #COL_6E               ; 2
    sta    COLUPF                ; 3
    lda    #$05                  ; 2
    sta    ram_90                ; 3
    jsr    L1CED                 ; 6
    bit    ram_F1                ; 3
    bpl    L1915                 ; 2�+1

    ldx    ram_ED                ; 3
    bit    ram_F8                ; 3
    bpl    L18DF                 ; 2�
    txa                          ; 2
    eor    #$01                  ; 2
    tay                          ; 2
    ldx    #$05                  ; 2
    lda    #$00                  ; 2
    jsr    UpdateScore           ; 6
    ldx    #$00                  ; 2
L18DF:
    dec    ram_F2,X              ; 6
    bpl    L1915                 ; 2�+1
    lda    ram_F5                ; 3
    beq    L18FF                 ; 2�
    txa                          ; 2
    eor    #$01                  ; 2
    tax                          ; 2
    lda    ram_F2,X              ; 4
    bmi    L18FF                 ; 2�
    lda    #$08                  ; 2
    sta    ram_9B                ; 3
    sty    ram_AF                ; 3
    sty    ram_B0                ; 3
    sty    ram_B1                ; 3
    sty    ram_BB                ; 3
    sty    ram_B2                ; 3
;     bpl    L1915                 ; 2�+1   always branch

L1915:
    LDA    ram_99
    CMP    #$30
    BCC    L191F
    AND    #$0F
    STA    ram_BC
L191F:
    BIT    ram_9C
    BVS    L1926
L1923:
    JMP    L19D6





L18FF:
    stx    COLUPF                ; 3
    stx    ram_D3                ; 3
    jsr    L1AD2                 ; 6


                                               ; If:
                                               ;   1) Game is power-on and attract mode is running
                                               ;   2) Player is being blown up
                                               ;   3) User presses select switch
                                               ; Then:
                                               ;   This part of the code is reached. At that moment the P0 BCD score holds $ABCDEF,
                                               ;      which indexes the graphics of the IMAGIC display. P1 BCD score holds $000000.

  IF PLUSROM

      lda scoreHighBCD                         ; skip PlusCart writes should this condition occur...
      cmp #$AB
      beq .skipPlusCart

SendPlusROMScore:
      lda gameNumBCD
      sta WriteToBuffer
      lda SWCHB
      sta WriteToBuffer
      lda scoreHighBCD            ; only player 1 score is being saved...
      sta WriteToBuffer
      lda scoreMidBCD
      sta WriteToBuffer
      lda scoreLowBCD
      sta WriteToBuffer
      lda #HIGHSCORE_ID               ; Demon Attack game id in Highscore DB
      sta WriteSendBuffer             ; send request to backend..
  ENDIF

;     lda    #$40                  ; 2
;     sta    gameFlags             ; 3   mark as game over
;     lda    #$30                  ; 2
;     sta    ram_B5                ; 3
;     lda    #$78                  ; 2
;     sta    ram_D0                ; 3
;     jmp    L1A7D                 ; 3

.skipPlusCart:
    JMP    M1A7D


; L1915:
;     lda    ram_99                ; 3
;     cmp    #$30                  ; 2
;     bcc    L191F                 ; 2�
;     and    #$0F                  ; 2
;     sta    ram_BC                ; 3
; L191F:
;     bit    ram_9C                ; 3
;     bvs    L1926                 ; 2�
; L1923:
;     jmp    L19D6                 ; 3

L1926:
    lda    CXP0FB | $30          ; 3
    ora    ram_BF                ; 3
    and    #$40                  ; 2
    beq    L1942                 ; 2�
    ldx    #$00                  ; 2
    lda    ram_95                ; 3
    cmp    #$0D                  ; 2
    bcc    L1923                 ; 2�
;     clc                          ; 2
;     adc    #$08                  ; 2
    ADC    #8-1    ; carry is set

L1939:
    cmp    ram_C5,X              ; 4
    bcs    L1944                 ; 2�
    inx                          ; 2
    cpx    #$04                  ; 2
    bne    L1939                 ; 2�
L1942:
    beq    L1923                 ; 2�
L1944:
    cpx    ram_97                ; 3
    beq    L1923                 ; 2�
    lda    #$03                  ; 2
    cpx    #$03                  ; 2
    bne    L195E                 ; 2�
    bit    ram_EB                ; 3
    bmi    L1923                 ; 2�
    cmp    ram_B3                ; 3
    bcs    L1923                 ; 2�
    sta    ram_B3                ; 3
    ldy    #$04                  ; 2
    sty    ram_DC                ; 3
    bcc    L1998                 ; 2�
L195E:
    ldy    ram_B6,X              ; 4
    bpl    L197E                 ; 2�
    ldy    #$02                  ; 2
    sty    ram_DC                ; 3
    bit    CXP0FB | $30          ; 3
    bvs    L1976                 ; 2�
    bit    ram_BF                ; 3
    bvc    L19D6                 ; 2�
    cmp    ram_A1,X              ; 4
    bcs    L19D6                 ; 2�
    sta    ram_A1,X              ; 4
    bvs    L19A0                 ; 2�
L1976:
    cmp    ram_9D,X              ; 4
    bcs    L19D6                 ; 2�
    sta    ram_9D,X              ; 4
    bvs    L19A0                 ; 2�
L197E:
    ldy    #$01                  ; 2
    sty    ram_DC                ; 3
    bit    ram_9C                ; 3
    bmi    L198C                 ; 2�
    cmp    ram_9D,X              ; 4
;     bcs    L19D6                 ; 2�
;     bcc    L1994                 ; 3   always branch
    JMP    M1994

L198C:
    lda    #$18                  ; 2
    ldy    ram_9D,X              ; 4
    cpy    #$16                  ; 2
M1994:
    bcs    L19D6                 ; 2�
L1994:
    sta    ram_9D,X              ; 4
    sta    ram_A1,X              ; 4
L1998:
    lda    ram_AF,X              ; 4
    and    #$3F                  ; 2
    ora    #$C0                  ; 2
    sta    ram_AF,X              ; 4
L19A0:
    jsr    L1CED                 ; 6
    bit    ram_F1                ; 3
    bpl    L19D6                 ; 2�
    ldx    #$00                  ; 2
    lda    ram_F0                ; 3
    lsr                          ; 2
    tay                          ; 2
    txa                          ; 2
    sed                          ; 2
L19AF:
    clc                          ; 2
    adc    L1FE6,Y               ; 4
    bcc    L19B6                 ; 2�
    inx                          ; 2
L19B6:
    dec    ram_DC                ; 5
    bne    L19AF                 ; 2�
    cld                          ; 2
    ldy    ram_ED                ; 3
    jsr    UpdateScore           ; 6
    lda    #$00                  ; 2
    sta    ram_B4                ; 3
    ldy    ram_80                ; 3
    lda    L1B9F,Y               ; 4
    asl                          ; 2
    asl                          ; 2
    asl                          ; 2
    sta    ram_D0                ; 3
    lda    ram_B5                ; 3
    and    #$0F                  ; 2
    ora    #$20                  ; 2
    sta    ram_B5                ; 3
L19D6:
    lda    ram_BD                ; 3
    and    #$03                  ; 2
    tax                          ; 2
    lda    ram_AF,X              ; 4
    and    #$F0                  ; 2
    sta    ram_DC                ; 3
    inc    ram_AF,X              ; 6
    lda    ram_AF,X              ; 4
    and    #$0F                  ; 2
    ora    ram_DC                ; 3
    sta    ram_AF,X              ; 4
    ldx    #$02                  ; 2
L19ED:
    lda    ram_AF,X              ; 4
    and    #$C0                  ; 2
    cmp    #$80                  ; 2
;     beq    L19F8                 ; 2�
;     jmp    L1A77                 ; 3

    BNE    L1A77

L19F8:
    lda    ram_B4                ; 3
    beq    L1A00                 ; 2�+1
    cpx    #$02                  ; 2
    beq    L1A1B                 ; 2�
L1A00:
    lda    ram_AF,X              ; 4
    and    #$07                  ; 2
    tay                          ; 2
    lda    ram_C9,X              ; 4
    clc                          ; 2
    adc    L1EF0,Y               ; 4
    sta    ram_C9,X              ; 4
    bcc    L1A1B                 ; 2�
    lda    ram_AF,X              ; 4
    and    #$08                  ; 2
    beq    L1A19                 ; 2�
    inc    ram_C5,X              ; 6
    bne    L1A1B                 ; 2�
L1A19:
    dec    ram_C5,X              ; 6
L1A1B:
    lda    ram_B6,X              ; 4
    sta    ram_DC                ; 3
    lda    ram_87,X              ; 4
    clc                          ; 2
    adc    L1EF8,Y               ; 4
    sta    ram_87,X              ; 4
    bcc    L1A77                 ; 2�
    bit    ram_DC                ; 3
    bpl    L1A35                 ; 2�
    lda    ram_B6,X              ; 4
    ora    #$08                  ; 2
    sta    ram_B6,X              ; 4
    bvc    L1A77                 ; 2�
L1A35:
    cpx    #$02                  ; 2
    bne    L1A3D                 ; 2�
    lda    ram_B4                ; 3
    bne    L1A77                 ; 2�
L1A3D:
    ldy    #$01                  ; 2
    lda    ram_AF,X              ; 4
    and    #$10                  ; 2
    beq    L1A61                 ; 2�
    lda    ram_8D,X              ; 4
    cmp    #$49                  ; 2
    beq    L1A53                 ; 2�
    jsr    L1CCF                 ; 6
;     sta    ram_8D,X              ; 4
;     jmp    L1A6C                 ; 3
    JMP    M1A6C


L1A53:
    lda    ram_AF,X              ; 4
    eor    #$10                  ; 2
    and    #$F0                  ; 2
    ora    #$01                  ; 2
    sta    ram_AF,X              ; 4
    lda    ram_8D,X              ; 4
    bne    L1A6C                 ; 2�
L1A61:
    lda    ram_8D,X              ; 4
    cmp    #$71                  ; 2
    beq    L1A53                 ; 2�
    jsr    L1CDE                 ; 6
M1A6C:
    sta    ram_8D,X              ; 4
L1A6C:
    ldy    ram_B6,X              ; 4
    bne    L1A77                 ; 2�
    ldy    #$08                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_91,X              ; 4
L1A77:
    dex                          ; 2
    bmi    L1A7D                 ; 2�
    jmp    L19ED                 ; 3

M1A7D:
    LDA    #$40
    STA    gameFlags             ; mark as game over
    LDA    #$30
    STA    ram_B5
    LDA    #$78
    STA    ram_D0


L1A7D:
    lda    INTIM                 ; 4
    bne    L1A7D                 ; 2�
    jmp    L1277                 ; 3

UpdateScore:
    sed                          ; 2
    clc                          ; 2
    adc.wy scoreLowBCD,Y         ; 4
    sta.wy scoreLowBCD,Y         ; 5
    txa                          ; 2
    bcc    L1A92                 ; 2�
    adc    #$00                  ; 2
L1A92:
    clc                          ; 2
    adc.wy scoreMidBCD,Y         ; 4
    sta.wy scoreMidBCD,Y         ; 5
    lda    #$00                  ; 2
    bcc    L1A9F                 ; 2�
    adc    #$00                  ; 2
L1A9F:
    adc.wy scoreHighBCD,Y        ; 4
    sta.wy scoreHighBCD,Y        ; 5
    cld                          ; 2
    rts                          ; 6


L1AA7:
    lda    #$05                  ; 2
    sta    ram_90                ; 3
    lda    #$F5                  ; 2
    sta    ram_96                ; 3
    sta    ram_F9                ; 3
    lda    #$03                  ; 2
    sta    ram_95                ; 3
    lda    #$96                  ; 2
    sta    ram_C5                ; 3
    lda    #$87                  ; 2
    sta    ram_C6                ; 3
    lda    #$78                  ; 2
    sta    ram_C7                ; 3
    lda    #COL_6E               ; 2
    sta    COLUPF                ; 3
    lda    #COL_8C               ; 2
    sta    ram_F7                ; 3
    lda    #$FF                  ; 2
    sta    ram_D1                ; 3
    rts                          ; 6

; L1ACE:
;     .byte $56 ; | X X XX | $1ACE
;     .byte $F8 ; |XXXXX   | $1ACF
; L1AD0:
;     .byte $2C ; |  X XX  | $1AD0
;     .byte $7A ; | XXXX X | $1AD1

L1AD2:
    lda    #$00                  ; 2
    sta    gameFlags             ; 3
    ldx    #$9D                  ; 2
L1AD8:
    sta    0,X                   ; 4
    inx                          ; 2
    cpx    #$BD                  ; 2
    bne    L1AD8                 ; 2�
    stx    ram_F1                ; 3
    sta    ram_F2                ; 3
    sta    ram_F3                ; 3
    rts                          ; 6

L1AE6:
    lda    ram_D5                ; 3
    sta    ram_DC                ; 3
    ldx    #$07                  ; 2
L1AEC:
    lda    ram_A5,X              ; 4
    beq    L1AFF                 ; 2�
    clc                          ; 2
    bit    ram_DC                ; 3
    bpl    L1AF8                 ; 2�
L1AF5:
    ror                          ; 2
    bcc    L1AFB                 ; 2�
L1AF8:
    rol                          ; 2
    bcs    L1AF5                 ; 2�
L1AFB:
    sta    ram_A5,X              ; 4
    asl    ram_DC                ; 5
L1AFF:
    dex                          ; 2
    bpl    L1AEC                 ; 2�+1
    rts                          ; 6

L1B03:
    cmp    #$00                  ; 2
    bne    L1B08                 ; 2�
L1B07:
    rts                          ; 6

L1B08:
    ldy    ram_AF,X              ; 4
    sty    ram_DC                ; 3
    cmp    #$04                  ; 2
    bcs    L1B21                 ; 2�
    sec                          ; 2
    sbc    #$01                  ; 2
    bne    L1B07                 ; 2�
    lda    ram_B6,X              ; 4
    and    ram_BF                ; 3
    sta    ram_B6,X              ; 4
    and    #$60                  ; 2
    beq    L1B52                 ; 2�
    bne    L1B5F                 ; 3   always branch

L1B21:
    tay                          ; 2
;     lda    #$07                  ; 2
;     sta    ram_BF                ; 3
;     bne    L1B7D                 ; 3   always branch
    JMP    M1B7D

L1B28:
    ldy    ram_AF,X              ; 4
    sty    ram_DC                ; 3
    bit    ram_DC                ; 3
    bmi    L1B33                 ; 2�
    bvs    L1B65                 ; 2�
    rts                          ; 6

L1B33:
    bvc    L1B6F                 ; 2�
    sec                          ; 2
    sbc    #$01                  ; 2
    beq    L1B52                 ; 2�
    cmp    #$15                  ; 2
    bne    L1B64                 ; 2�
    lda    ram_DC                ; 3
    and    #$0F                  ; 2
    ora    #$80                  ; 2
    sta    ram_AF,X              ; 4
    lda    ram_B6,X              ; 4
    ora    #$F0                  ; 2
    sta    ram_B6,X              ; 4
    jsr    L1BAF                 ; 6
    lda    #$19                  ; 2
    rts                          ; 6

L1B52:
    lda    ram_DC                ; 3
    and    #$3F                  ; 2
    sta    ram_AF,X              ; 4
    cpx    #$03                  ; 2
    bne    L1B5F                 ; 2�
    jsr    L1CC2                 ; 6
L1B5F:
    jsr    L1BAF                 ; 6
    lda    #$00                  ; 2
L1B64:
    rts                          ; 6

L1B65:
    clc                          ; 2
    adc    #$01                  ; 2
    cmp    #$04                  ; 2
    bne    L1B64                 ; 2�
    lda    #$01                  ; 2
    rts                          ; 6

L1B6F:
    tay                          ; 2
    lda    ram_80                ; 3
    lsr                          ; 2
;     sta    ram_BF                ; 3    set below
    cpx    #$03                  ; 2
;     bne    L1B7D                 ; 2�
    BNE    N1B7D

M1B7D:
    lda    #$07                  ; 2
N1B7D:
    sta    ram_BF                ; 3
L1B7D:
    lda    ram_DC                ; 3
    and    #$20                  ; 2
    bne    L1B95                 ; 2�
    iny                          ; 2
    tya                          ; 2
    ldy    ram_BF                ; 3
    cmp    L1BA7,Y               ; 4
    bne    L1B64                 ; 2�
L1B8C:
    tay                          ; 2
    lda    ram_DC                ; 3
    eor    #$20                  ; 2
    sta    ram_AF,X              ; 4
    tya                          ; 2
    rts                          ; 6

L1B95:
    dey                          ; 2
    tya                          ; 2
    ldy    ram_BF                ; 3
    cmp    L1B9F,Y               ; 4
    beq    L1B8C                 ; 2�
    rts                          ; 6

; L1B9F:
;     .byte $04 ; |     X  | $1B9F
;     .byte $07 ; |     XXX| $1BA0
;     .byte $0A ; |    X X | $1BA1
;     .byte $0D ; |    XX X| $1BA2
;     .byte $10 ; |   X    | $1BA3
;     .byte $13 ; |   X  XX| $1BA4
;     .byte $16 ; |   X XX | $1BA5
;     .byte $19 ; |   XX  X| $1BA6
; L1BA7:
;     .byte $06 ; |     XX | $1BA7
;     .byte $09 ; |    X  X| $1BA8
;     .byte $0C ; |    XX  | $1BA9
;     .byte $0F ; |    XXXX| $1BAA
;     .byte $12 ; |   X  X | $1BAB
;     .byte $15 ; |   X X X| $1BAC
;     .byte $18 ; |   XX   | $1BAD
;     .byte $1B ; |   XX XX| $1BAE

L1BAF:
    lda    ram_B5                ; 3
    and    #$0F                  ; 2
    ora    #$10                  ; 2
    sta    ram_B5                ; 3
    rts                          ; 6

L1BB8:
    ldy    ram_8F                ; 3
    ldx    ram_9F                ; 3
    cpx    #$05                  ; 2
    bcs    L1BC8                 ; 2�
    ldx    ram_A3                ; 3
    ldy    ram_93                ; 3
    cpx    #$05                  ; 2
    bcc    L1C10                 ; 2�+1
L1BC8:
    sty    ram_94                ; 3
    stx    ram_B3                ; 3
    lda    ram_EB                ; 3
    and    #$7F                  ; 2
    sta    ram_EB                ; 3
    lda    ram_C7                ; 3
    sta    ram_C8                ; 3
    lda    ram_B1                ; 3
    and    #$F0                  ; 2
    sta    ram_B2                ; 3
    ldx    #$01                  ; 2
L1BDE:
    lda    ram_AF,X              ; 4
    sta    ram_B0,X              ; 4
    lda    ram_8D,X              ; 4
    sta    ram_8E,X              ; 4
    lda    ram_91,X              ; 4
    sta    ram_92,X              ; 4
    lda    ram_9D,X              ; 4
    sta    ram_9E,X              ; 4
    lda    ram_A1,X              ; 4
    sta    ram_A2,X              ; 4
    lda    ram_C5,X              ; 4
    sta    ram_C6,X              ; 4
    lda    ram_B6,X              ; 4
    sta    ram_B7,X              ; 4
    dex                          ; 2
    bpl    L1BDE                 ; 2�
    lda    ram_97                ; 3
    bmi    L1C03                 ; 2�
    inc    ram_97                ; 5
L1C03:
    inx                          ; 2
    stx    ram_AF                ; 3
    stx    ram_9D                ; 3
    stx    ram_A1                ; 3
    stx    ram_B6                ; 3
    lda    #$96                  ; 2
    sta    ram_C5                ; 3
L1C10:
    rts                          ; 6

L1C11:
    sta    ram_DC                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    jsr    L1C2A                 ; 6
    sta    ram_DD,X              ; 4
    inx                          ; 2
    inx                          ; 2
    lda    ram_DC                ; 3
    and    #$0F                  ; 2
    jsr    L1C2A                 ; 6
    sta    ram_DD,X              ; 4
    inx                          ; 2
    inx                          ; 2
    rts                          ; 6

L1C2A:
    asl                          ; 2
    sta    ram_BF                ; 3
    asl                          ; 2
    asl                          ; 2
    clc                          ; 2
    adc    ram_BF                ; 3
    rts                          ; 6

L1C33:
    lda    ram_99                ; 3
    bne    L1C6D                 ; 2�
    bit    ram_B2                ; 3
    bmi    L1C6E                 ; 2�
    lda    ram_9F                ; 3
    cmp    #$04                  ; 2
    bcc    L1C6D                 ; 2�
    ldy    ram_D5                ; 3
    cpy    #$B0                  ; 2
    bcc    L1C6D                 ; 2�
    lda    ram_8F                ; 3
    ldy    #$04                  ; 2
    jsr    L1CCF                 ; 6
    jsr    L1D31                 ; 6
    bcs    L1C6D                 ; 2�
    ldy    ram_C7                ; 3
    cpy    #$50                  ; 2
    bcs    L1C6D                 ; 2�
    sta    ram_94                ; 3
    bit    ram_EB                ; 3
    bvc    L1C63                 ; 2�
    lda    #$04                  ; 2
 ;    bne    L1C67                 ; 3   always branch
    .BYTE $0C ; NOP, skip 2 bytes

L1C63:
    lda    ram_D5                ; 3
    and    #$07                  ; 2
L1C67:
    sta    ram_B4                ; 3
    lda    #$00                  ; 2
    sta    ram_9A                ; 3
L1C6D:
    rts                          ; 6

L1C6E:
    bit    ram_B2                ; 3
    bvs    L1CCE                 ; 2�
    lda    ram_B2                ; 3
    and    #$07                  ; 2
    bne    L1C81                 ; 2�
    ldx    #$03                  ; 2
    lda    ram_91,X              ; 4
    jsr    L1D3D                 ; 6
    lda    #$00                  ; 2
L1C81:
    tay                          ; 2
    lda    ram_C8                ; 3
    clc                          ; 2
    adc    L1CB2,Y               ; 4
    sta    ram_C8                ; 3
    beq    L1CC2                 ; 2�
    lda    ram_EF                ; 3
    clc                          ; 2
    adc    L1CBA,Y               ; 4
    sta    ram_EF                ; 3
    bcc    L1CCE                 ; 2�
    ldy    #$01                  ; 2
    lda    ram_B2                ; 3
    and    #$10                  ; 2
    beq    L1CA6                 ; 2�
    lda    ram_94                ; 3
    jsr    L1CCF                 ; 6
    jmp    L1CAF                 ; 3

L1CA6:
    lda    ram_94                ; 3
    cmp    #$71                  ; 2
    beq    L1CAF                 ; 2�
    jsr    L1CDE                 ; 6
L1CAF:
    sta    ram_94                ; 3
    rts                          ; 6

; L1CB2:
;     .byte $FF ; |XXXXXXXX| $1CB2
;     .byte $FF ; |XXXXXXXX| $1CB3
;     .byte $FF ; |XXXXXXXX| $1CB4
;     .byte $FF ; |XXXXXXXX| $1CB5
;     .byte $FF ; |XXXXXXXX| $1CB6
;     .byte $01 ; |       X| $1CB7
;     .byte $01 ; |       X| $1CB8
;     .byte $01 ; |       X| $1CB9
; L1CBA:
;     .byte $40 ; | X      | $1CBA
;     .byte $80 ; |X       | $1CBB
;     .byte $C0 ; |XX      | $1CBC
;     .byte $FF ; |XXXXXXXX| $1CBD
;     .byte $FF ; |XXXXXXXX| $1CBE
;     .byte $C0 ; |XX      | $1CBF
;     .byte $80 ; |X       | $1CC0
;     .byte $40 ; | X      | $1CC1

L1CC2:
    lda    #$00                  ; 2
    sta    ram_B2                ; 3
    sta    ram_B3                ; 3
    lda    ram_EB                ; 3
    ora    #$80                  ; 2
    sta    ram_EB                ; 3
L1CCE:
    rts                          ; 6

L1CCF:
    sec                          ; 2
    sbc    #$10                  ; 2
    bmi    L1CDA                 ; 2�
    cmp    #$70                  ; 2
    bcc    L1CDA                 ; 2�
    adc    #$F0                  ; 2
L1CDA:
    dey                          ; 2
    bne    L1CCF                 ; 2�
    rts                          ; 6

L1CDE:
    clc                          ; 2
    adc    #$10                  ; 2
    bpl    L1CE9                 ; 2�
    cmp    #$90                  ; 2
    bcs    L1CE9                 ; 2�
    sbc    #$F0                  ; 2
L1CE9:
    dey                          ; 2
    bne    L1CDE                 ; 2�
    rts                          ; 6

L1CED:
    lda    ram_99                ; 3
    beq    L1CF5                 ; 2�
    lda    #$00                  ; 2
    sta    COLUPF                ; 3
L1CF5:
    lda    #$03                  ; 2
    sta    ram_95                ; 3
    lda    ram_9C                ; 3
    and    #$BF                  ; 2
    sta    ram_9C                ; 3
    lda    ram_90                ; 3
    ldy    #$01                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_96                ; 3
    rts                          ; 6

; L1D09:
;     cpx    #$00                  ; 2
;     bne    L1D15                 ; 2�
;     lda    #$97                  ; 2
;     clc                          ; 2
;     adc    ram_C6                ; 3
; ;     jmp    L1D2F                 ; 3
;     ROR
;     RTS

; L1D15:
;     cpx    #$01                  ; 2
;     bne    L1D21                 ; 2�
;     lda    ram_C5                ; 3
;     clc                          ; 2
;     adc    ram_C7                ; 3
; ;     jmp    L1D2F                 ; 3
;     ROR
;     RTS









L1D09:
    cpx    #$00                  ; 2
    bne    L1D15                 ; 2�
    lda    #$97                  ; 2        X=0
.AddValue:
    clc                          ; 2
    adc    ram_C6,X
;     jmp    L1D2F                 ; 3
    ROR
    RTS

L1D15:
    cpx    #$01                  ; 2
    bne    L1D21                 ; 2�
    lda    ram_C5                ; 3
;     clc                          ; 2
;     adc    ram_C7                ; 3
;     ROR
;     RTS
    jmp    .AddValue   ; X=1




L1D21:
    lda    ram_C6                ; 3
    clc                          ; 2
    bit    ram_B2                ; 3
;     bpl    L1D2D                 ; 2�
;     adc    ram_C8                ; 3
;     jmp    L1D2F                 ; 3

; L1D2D:
;     adc    ram_98                ; 3
; L1D2F:
;     ror                          ; 2
;     rts                          ; 6



    BPL    M1D2D
    ADC    ram_C8

    .BYTE $0C
M1D2D:
    ADC    ram_98
    ROR
    RTS


L1D31:
    ldx    #$09                  ; 2
    sec                          ; 2
L1D34:
    ldy    ram_A5,X              ; 4
    bne    L1D3C                 ; 2�
    dex                          ; 2
    bpl    L1D34                 ; 2�
    clc                          ; 2
L1D3C:
    rts                          ; 6

L1D3D:
    ldy    #$04                  ; 2
    jsr    L1CCF                 ; 6
    sta    ram_BF                ; 3
    and    #$0F                  ; 2
    sta    ram_DC                ; 3
    lda    ram_90                ; 3
    and    #$0F                  ; 2
    cmp    ram_DC                ; 3
    bne    L1D7B                 ; 2�
    lda    SWCHB                 ; 4
    asl                          ; 2
    ldy    ram_ED                ; 3
    bne    L1D59                 ; 2�
    asl                          ; 2
L1D59:
    ldy    #$FF                  ; 2
    bcc    L1D5F                 ; 2�
    ldy    #$0F                  ; 2
L1D5F:
    sty    ram_C0                ; 3
    lda    ram_BF                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    clc                          ; 2
    adc    #$08                  ; 2
    eor    ram_C0                ; 3
    sta    ram_DC                ; 3
    lda    ram_90                ; 3
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    lsr                          ; 2
    clc                          ; 2
    adc    #$08                  ; 2
    eor    ram_C0                ; 3
    cmp    ram_DC                ; 3
L1D7B:
    lda    ram_AF,X              ; 4
    bcc    L1D83                 ; 2�
    ora    #$10                  ; 2
;     bne    L1D85                 ; 3   always branch
    .BYTE $0C ; NOP, skip 2 bytes

L1D83:
    and    #$EF                  ; 2
L1D85:
    sta    ram_AF,X              ; 4
    rts                          ; 6






   IF PLUSROM
PlusROM_API:
    .byte "a", 0, "h.firmaplus.de", 0
  ENDIF




    ECHO [L1FEC-*]d, "bytes free", *, "-", L1FEC


      ORG $1D58+12

L1FEC:
    .byte $15 ; |   X X X| $1FEC
    .byte $00 ; |        | $1FED
    .byte $00 ; |        | $1FEE
    .byte $1A ; |   XX X | $1FEF
    .byte $00 ; |        | $1FF0
    .byte $00 ; |        | $1FF1
    .byte $00 ; |        | $1FF2
    .byte $1C ; |   XXX  | $1FF3
    .byte $17 ; |   X XXX| $1FF4
    .byte $1A ; |   XX X | $1FF5
    .byte $15 ; |   X X X| $1FF6
    .byte $17 ; |   X XXX| $1FF7
    .byte $13 ; |   X  XX| $1FF8
    .byte $15 ; |   X X X| $1FF9
    .byte $11 ; |   X   X| $1FFA
    .byte $00 ; |        | $1FFB


L1B9F:
    .byte $04 ; |     X  | $1B9F
    .byte $07 ; |     XXX| $1BA0
    .byte $0A ; |    X X | $1BA1
    .byte $0D ; |    XX X| $1BA2
    .byte $10 ; |   X    | $1BA3
    .byte $13 ; |   X  XX| $1BA4
    .byte $16 ; |   X XX | $1BA5
    .byte $19 ; |   XX  X| $1BA6
L1BA7:
    .byte $06 ; |     XX | $1BA7
    .byte $09 ; |    X  X| $1BA8
    .byte $0C ; |    XX  | $1BA9
    .byte $0F ; |    XXXX| $1BAA
    .byte $12 ; |   X  X | $1BAB
    .byte $15 ; |   X X X| $1BAC
    .byte $18 ; |   XX   | $1BAD
    .byte $1B ; |   XX XX| $1BAE

L1CB2:
    .byte $FF ; |XXXXXXXX| $1CB2
    .byte $FF ; |XXXXXXXX| $1CB3
    .byte $FF ; |XXXXXXXX| $1CB4
    .byte $FF ; |XXXXXXXX| $1CB5
    .byte $FF ; |XXXXXXXX| $1CB6
    .byte $01 ; |       X| $1CB7
    .byte $01 ; |       X| $1CB8
    .byte $01 ; |       X| $1CB9
L1CBA:
    .byte $40 ; | X      | $1CBA
    .byte $80 ; |X       | $1CBB
    .byte $C0 ; |XX      | $1CBC
    .byte $FF ; |XXXXXXXX| $1CBD
    .byte $FF ; |XXXXXXXX| $1CBE
    .byte $C0 ; |XX      | $1CBF
    .byte $80 ; |X       | $1CC0
    .byte $40 ; | X      | $1CC1


L1D88:
    .byte $C6 ; |XX   XX | $1D88
    .byte $C6 ; |XX   XX | $1D89
    .byte $C6 ; |XX   XX | $1D8A
    .byte $C6 ; |XX   XX | $1D8B
    .byte $EE ; |XXX XXX | $1D8C
    .byte $EE ; |XXX XXX | $1D8D
    .byte $6C ; | XX XX  | $1D8E
    .byte $6C ; | XX XX  | $1D8F
    .byte $28 ; |  X X   | $1D90
    .byte $28 ; |  X X   | $1D91
    .byte $28 ; |  X X   | $1D92
    .byte $28 ; |  X X   | $1D93
L1D94:
    .byte $00 ; |        | $1D94
    .byte $80 ; |X       | $1D95
    .byte $01 ; |       X| $1D96
    .byte $03 ; |      XX| $1D97
    .byte $02 ; |      X | $1D98
    .byte $80 ; |X       | $1D99
    .byte $03 ; |      XX| $1D9A
    .byte $80 ; |X       | $1D9B
; L1D9C:
;     .byte $00 ; |        | $1D9C
;     .byte $28 ; |  X X   | $1D9D
;     .byte $28 ; |  X X   | $1D9E
;     .byte $38 ; |  XXX   | $1D9F
;     .byte $10 ; |   X    | $1DA0
;     .byte $10 ; |   X    | $1DA1
L1DA2:
  IF _60_FRAMES
    .byte $08 ; |    X   | $1DA2
    .byte $06 ; |     XX | $1DA3
    .byte $06 ; |     XX | $1DA4
    .byte $03 ; |      XX| $1DA5
    .byte $05 ; |     X X| $1DA6
    .byte $04 ; |     X  | $1DA7
    .byte $05 ; |     X X| $1DA8
    .byte $04 ; |     X  | $1DA9
    .byte $05 ; |     X X| $1DAA
    .byte $04 ; |     X  | $1DAB
    .byte $05 ; |     X X| $1DAC
    .byte $04 ; |     X  | $1DAD
  ELSE
    .byte $07 ; |     XXX| $1DA2
    .byte $05 ; |     X X| $1DA3
    .byte $05 ; |     X X| $1DA4
    .byte $03 ; |      XX| $1DA5
    .byte $04 ; |     X  | $1DA6
    .byte $04 ; |     X  | $1DA7
    .byte $04 ; |     X  | $1DA8
    .byte $04 ; |     X  | $1DA9
    .byte $05 ; |     X X| $1DAA
    .byte $03 ; |      XX| $1DAB
    .byte $04 ; |     X  | $1DAC
    .byte $03 ; |      XX| $1DAD
  ENDIF
; L1DAE:
;     .byte $00 ; |        | $1DAE
;     .byte $00 ; |        | $1DAF
;     .byte $00 ; |        | $1DB0
;     .byte $01 ; |       X| $1DB1
;     .byte $01 ; |       X| $1DB2
;     .byte $03 ; |      XX| $1DB3
;     .byte $03 ; |      XX| $1DB4
; L1DB5:
;     .byte $00 ; |        | $1DB5
;     .byte $00 ; |        | $1DB6
;     .byte $00 ; |        | $1DB7
;     .byte $00 ; |        | $1DB8
;     .byte $01 ; |       X| $1DB9
;     .byte $01 ; |       X| $1DBA
;     .byte $03 ; |      XX| $1DBB

L1DB5:
    .byte $00 ; |        | $1DB5
L1DAE:
    .byte $00 ; |        | $1DAE  shared
    .byte $00 ; |        | $1DAF  shared
    .byte $00 ; |        | $1DB0  shared
    .byte $01 ; |       X| $1DB1  shared
    .byte $01 ; |       X| $1DB2  shared
    .byte $03 ; |      XX| $1DB3  shared
    .byte $03 ; |      XX| $1DB4


L1DBC:
    .byte $E7 ; |XXX  XXX| $1DBC
    .byte $E2 ; |XXX   X | $1DBD
    .byte $DD ; |XX XXX X| $1DBE
    .byte $D8 ; |XX XX   | $1DBF
    .byte $D3 ; |XX X  XX| $1DC0
    .byte $CE ; |XX  XXX | $1DC1
    .byte $C9 ; |XX  X  X| $1DC2
    .byte $C4 ; |XX   X  | $1DC3
    .byte $06 ; |     XX | $1DC4
    .byte $03 ; |      XX| $1DC5
    .byte $01 ; |       X| $1DC6
    .byte $00 ; |        | $1DC7
    .byte $00 ; |        | $1DC8
    .byte $06 ; |     XX | $1DC9
    .byte $01 ; |       X| $1DCA
    .byte $04 ; |     X  | $1DCB
    .byte $02 ; |      X | $1DCC
    .byte $00 ; |        | $1DCD
    .byte $0A ; |    X X | $1DCE
    .byte $00 ; |        | $1DCF
    .byte $02 ; |      X | $1DD0
    .byte $10 ; |   X    | $1DD1
    .byte $04 ; |     X  | $1DD2
    .byte $10 ; |   X    | $1DD3
    .byte $02 ; |      X | $1DD4
    .byte $04 ; |     X  | $1DD5
    .byte $40 ; | X      | $1DD6
    .byte $10 ; |   X    | $1DD7
    .byte $00 ; |        | $1DD8
    .byte $10 ; |   X    | $1DD9
    .byte $82 ; |X     X | $1DDA
    .byte $44 ; | X   X  | $1DDB
    .byte $00 ; |        | $1DDC
    .byte $00 ; |        | $1DDD
    .byte $40 ; | X      | $1DDE
    .byte $90 ; |X  X    | $1DDF
    .byte $02 ; |      X | $1DE0
    .byte $08 ; |    X   | $1DE1
    .byte $40 ; | X      | $1DE2
    .byte $80 ; |X       | $1DE3
    .byte $08 ; |    X   | $1DE4
    .byte $00 ; |        | $1DE5
    .byte $24 ; |  X  X  | $1DE6
    .byte $80 ; |X       | $1DE7
    .byte $00 ; |        | $1DE8
    .byte $00 ; |        | $1DE9
    .byte $00 ; |        | $1DEA
    .byte $84 ; |X    X  | $1DEB
L1DEC:
    .byte $8A ; |X   X X | $1DEC
    .byte $6A ; | XX X X | $1DED
    .byte $4A ; | X  X X | $1DEE
    .byte $7A ; | XXXX X | $1DEF
    .byte $9A ; |X  XX X | $1DF0
L1DF1:
    .byte $80 ; |X       | $1DF1
    .byte $C0 ; |XX      | $1DF2
    .byte $A0 ; |X X     | $1DF3
    .byte $E0 ; |XXX     | $1DF4
    .byte $B0 ; |X XX    | $1DF5
    .byte $F0 ; |XXXX    | $1DF6
L1DF7:
  IF _60_FRAMES
    .byte $03 ; |      XX| $1DF7
    .byte $04 ; |     X  | $1DF8
    .byte $05 ; |     X X| $1DF9
    .byte $05 ; |     X X| $1DFA
    .byte $06 ; |     XX | $1DFB
    .byte $06 ; |     XX | $1DFC
  ELSE
    .byte $04 ; |     X  | $1DF7
    .byte $05 ; |     X X| $1DF8
    .byte $06 ; |     XX | $1DF9
    .byte $06 ; |     XX | $1DFA
    .byte $07 ; |     XXX| $1DFB
    .byte $07 ; |     XXX| $1DFC
  ENDIF
    .byte $00 ; |        | $1DFD
    .byte $00 ; |        | $1DFE
    .byte $00 ; |        | $1DFF
L1E00:
    .byte $00 ; |        | $1E00
    .byte $00 ; |        | $1E01
    .byte $00 ; |        | $1E02
    .byte $00 ; |        | $1E03
    .byte $00 ; |        | $1E04
    .byte $00 ; |        | $1E05
    .byte $00 ; |        | $1E06
    .byte $00 ; |        | $1E07
    .byte $00 ; |        | $1E08
    .byte $88 ; |X   X   | $1E09
    .byte $20 ; |  X     | $1E0A
    .byte $08 ; |    X   | $1E0B
    .byte $00 ; |        | $1E0C
    .byte $02 ; |      X | $1E0D
    .byte $40 ; | X      | $1E0E
    .byte $10 ; |   X    | $1E0F
    .byte $00 ; |        | $1E10
    .byte $40 ; | X      | $1E11
    .byte $08 ; |    X   | $1E12
    .byte $40 ; | X      | $1E13
    .byte $04 ; |     X  | $1E14
    .byte $00 ; |        | $1E15
    .byte $48 ; | X  X   | $1E16
    .byte $02 ; |      X | $1E17
    .byte $00 ; |        | $1E18
    .byte $44 ; | X   X  | $1E19
    .byte $00 ; |        | $1E1A
    .byte $40 ; | X      | $1E1B
    .byte $04 ; |     X  | $1E1C
    .byte $20 ; |  X     | $1E1D
    .byte $09 ; |    X  X| $1E1E
    .byte $00 ; |        | $1E1F
    .byte $00 ; |        | $1E20
    .byte $03 ; |      XX| $1E21
    .byte $07 ; |     XXX| $1E22
    .byte $0E ; |    XXX | $1E23
    .byte $19 ; |   XX  X| $1E24
    .byte $F0 ; |XXXX    | $1E25
    .byte $02 ; |      X | $1E26
    .byte $00 ; |        | $1E27
    .byte $00 ; |        | $1E28
    .byte $06 ; |     XX | $1E29
    .byte $03 ; |      XX| $1E2A
    .byte $CE ; |XX  XXX | $1E2B
    .byte $71 ; | XXX   X| $1E2C
    .byte $00 ; |        | $1E2D
    .byte $04 ; |     X  | $1E2E
    .byte $00 ; |        | $1E2F
    .byte $00 ; |        | $1E30
    .byte $4C ; | X  XX  | $1E31
    .byte $46 ; | X   XX | $1E32
    .byte $23 ; |  X   XX| $1E33
    .byte $1F ; |   XXXXX| $1E34
    .byte $02 ; |      X | $1E35
    .byte $01 ; |       X| $1E36
    .byte $08 ; |    X   | $1E37
    .byte $00 ; |        | $1E38
    .byte $10 ; |   X    | $1E39
    .byte $21 ; |  X    X| $1E3A
    .byte $22 ; |  X   X | $1E3B
    .byte $24 ; |  X  X  | $1E3C
    .byte $14 ; |   X X  | $1E3D
    .byte $0F ; |    XXXX| $1E3E
    .byte $0C ; |    XX  | $1E3F
    .byte $00 ; |        | $1E40
    .byte $40 ; | X      | $1E41
    .byte $82 ; |X     X | $1E42
    .byte $84 ; |X    X  | $1E43
    .byte $64 ; | XX  X  | $1E44
    .byte $1F ; |   XXXXX| $1E45
    .byte $06 ; |     XX | $1E46
    .byte $00 ; |        | $1E47
    .byte $00 ; |        | $1E48
    .byte $44 ; | X   X  | $1E49
    .byte $24 ; |  X  X  | $1E4A
    .byte $14 ; |   X X  | $1E4B
    .byte $0F ; |    XXXX| $1E4C
    .byte $03 ; |      XX| $1E4D
    .byte $00 ; |        | $1E4E
    .byte $00 ; |        | $1E4F
    .byte $00 ; |        | $1E50
    .byte $36 ; |  XX XX | $1E51
    .byte $1D ; |   XXX X| $1E52
    .byte $02 ; |      X | $1E53
    .byte $04 ; |     X  | $1E54
    .byte $0A ; |    X X | $1E55
    .byte $04 ; |     X  | $1E56
    .byte $00 ; |        | $1E57
    .byte $00 ; |        | $1E58
    .byte $09 ; |    X  X| $1E59
    .byte $1E ; |   XXXX | $1E5A
    .byte $32 ; |  XX  X | $1E5B
    .byte $24 ; |  X  X  | $1E5C
    .byte $08 ; |    X   | $1E5D
    .byte $0A ; |    X X | $1E5E
    .byte $00 ; |        | $1E5F
    .byte $00 ; |        | $1E60
    .byte $02 ; |      X | $1E61
    .byte $9F ; |X  XXXXX| $1E62
    .byte $B2 ; |X XX  X | $1E63
    .byte $E4 ; |XXX  X  | $1E64
    .byte $48 ; | X  X   | $1E65
    .byte $10 ; |   X    | $1E66
    .byte $24 ; |  X  X  | $1E67
    .byte $00 ; |        | $1E68
    .byte $9F ; |X  XXXXX| $1E69
    .byte $8F ; |X   XXXX| $1E6A
    .byte $87 ; |X    XXX| $1E6B
    .byte $88 ; |X   X   | $1E6C
    .byte $90 ; |X  X    | $1E6D
    .byte $64 ; | XX  X  | $1E6E
    .byte $00 ; |        | $1E6F
    .byte $00 ; |        | $1E70
    .byte $4F ; | X  XXXX| $1E71
    .byte $98 ; |X  XX   | $1E72
    .byte $8C ; |X   XX  | $1E73
    .byte $87 ; |X    XXX| $1E74
    .byte $88 ; |X   X   | $1E75
    .byte $70 ; | XXX    | $1E76
    .byte $04 ; |     X  | $1E77
    .byte $00 ; |        | $1E78
    .byte $27 ; |  X  XXX| $1E79
    .byte $4C ; | X  XX  | $1E7A
    .byte $98 ; |X  XX   | $1E7B
    .byte $8C ; |X   XX  | $1E7C
    .byte $87 ; |X    XXX| $1E7D
    .byte $48 ; | X  X   | $1E7E
    .byte $32 ; |  XX  X | $1E7F
    .byte $00 ; |        | $1E80
    .byte $04 ; |     X  | $1E81
    .byte $44 ; | X   X  | $1E82
    .byte $24 ; |  X  X  | $1E83
    .byte $23 ; |  X   XX| $1E84
    .byte $23 ; |  X   XX| $1E85
    .byte $14 ; |   X X  | $1E86
    .byte $08 ; |    X   | $1E87
    .byte $00 ; |        | $1E88
    .byte $20 ; |  X     | $1E89
    .byte $24 ; |  X  X  | $1E8A
    .byte $28 ; |  X X   | $1E8B
    .byte $24 ; |  X  X  | $1E8C
    .byte $23 ; |  X   XX| $1E8D
    .byte $27 ; |  X  XXX| $1E8E
    .byte $18 ; |   XX   | $1E8F
    .byte $00 ; |        | $1E90
    .byte $10 ; |   X    | $1E91
    .byte $20 ; |  X     | $1E92
    .byte $48 ; | X  X   | $1E93
    .byte $44 ; | X   X  | $1E94
    .byte $42 ; | X    X | $1E95
    .byte $47 ; | X   XXX| $1E96
    .byte $3F ; |  XXXXXX| $1E97
    .byte $00 ; |        | $1E98
    .byte $00 ; |        | $1E99
    .byte $00 ; |        | $1E9A
    .byte $00 ; |        | $1E9B
    .byte $01 ; |       X| $1E9C
    .byte $01 ; |       X| $1E9D
    .byte $00 ; |        | $1E9E
    .byte $00 ; |        | $1E9F
    .byte $00 ; |        | $1EA0
    .byte $00 ; |        | $1EA1
    .byte $00 ; |        | $1EA2
    .byte $03 ; |      XX| $1EA3
    .byte $05 ; |     X X| $1EA4
    .byte $03 ; |      XX| $1EA5
    .byte $00 ; |        | $1EA6
    .byte $00 ; |        | $1EA7
    .byte $00 ; |        | $1EA8
    .byte $00 ; |        | $1EA9
    .byte $06 ; |     XX | $1EAA
    .byte $09 ; |    X  X| $1EAB
    .byte $09 ; |    X  X| $1EAC
    .byte $09 ; |    X  X| $1EAD
    .byte $06 ; |     XX | $1EAE
    .byte $00 ; |        | $1EAF
    .byte $00 ; |        | $1EB0
    .byte $20 ; |  X     | $1EB1
    .byte $04 ; |     X  | $1EB2
    .byte $11 ; |   X   X| $1EB3
    .byte $80 ; |X       | $1EB4
    .byte $14 ; |   X X  | $1EB5
    .byte $42 ; | X    X | $1EB6
    .byte $90 ; |X  X    | $1EB7
    .byte $00 ; |        | $1EB8
    .byte $40 ; | X      | $1EB9
    .byte $04 ; |     X  | $1EBA
    .byte $12 ; |   X  X | $1EBB
    .byte $A0 ; |X X     | $1EBC
    .byte $14 ; |   X X  | $1EBD
    .byte $40 ; | X      | $1EBE
    .byte $84 ; |X    X  | $1EBF
    .byte $00 ; |        | $1EC0
    .byte $00 ; |        | $1EC1
    .byte $20 ; |  X     | $1EC2
    .byte $14 ; |   X X  | $1EC3
    .byte $68 ; | XX X   | $1EC4
    .byte $08 ; |    X   | $1EC5
    .byte $14 ; |   X X  | $1EC6
    .byte $20 ; |  X     | $1EC7
    .byte $00 ; |        | $1EC8
    .byte $00 ; |        | $1EC9
    .byte $00 ; |        | $1ECA
    .byte $10 ; |   X    | $1ECB
    .byte $28 ; |  X X   | $1ECC
    .byte $6C ; | XX XX  | $1ECD
    .byte $C6 ; |XX   XX | $1ECE
    .byte $82 ; |X     X | $1ECF
    .byte $00 ; |        | $1ED0
    .byte $00 ; |        | $1ED1
    .byte $82 ; |X     X | $1ED2
    .byte $82 ; |X     X | $1ED3
    .byte $D6 ; |XX X XX | $1ED4
    .byte $6C ; | XX XX  | $1ED5
    .byte $00 ; |        | $1ED6
    .byte $00 ; |        | $1ED7
    .byte $00 ; |        | $1ED8
    .byte $00 ; |        | $1ED9
    .byte $44 ; | X   X  | $1EDA
    .byte $82 ; |X     X | $1EDB
    .byte $82 ; |X     X | $1EDC
    .byte $C6 ; |XX   XX | $1EDD
    .byte $7C ; | XXXXX  | $1EDE
    .byte $10 ; |   X    | $1EDF
L1EE0:
    .byte $80 ; |X       | $1EE0
    .byte $20 ; |  X     | $1EE1
    .byte $10 ; |   X    | $1EE2
    .byte $50 ; | X X    | $1EE3
    .byte $41 ; | X     X| $1EE4
    .byte $84 ; |X    X  | $1EE5
    .byte $88 ; |X   X   | $1EE6
    .byte $42 ; | X    X | $1EE7
    .byte $40 ; | X      | $1EE8
    .byte $08 ; |    X   | $1EE9
    .byte $04 ; |     X  | $1EEA
    .byte $01 ; |       X| $1EEB
    .byte $81 ; |X      X| $1EEC
    .byte $22 ; |  X   X | $1EED
    .byte $11 ; |   X   X| $1EEE
    .byte $44 ; | X   X  | $1EEF
  IF _60_FRAMES
L1EF0:
    .byte $40 ; | X      | $1EF0
    .byte $80 ; |X       | $1EF1
    .byte $C0 ; |XX      | $1EF2
    .byte $F0 ; |XXXX    | $1EF3
    .byte $F0 ; |XXXX    | $1EF4
    .byte $C0 ; |XX      | $1EF5
    .byte $80 ; |X       | $1EF6
    .byte $40 ; | X      | $1EF7
L1EF8:
    .byte $FF ; |XXXXXXXX| $1EF8
    .byte $C0 ; |XX      | $1EF9
    .byte $A0 ; |X X     | $1EFA
    .byte $80 ; |X       | $1EFB
    .byte $80 ; |X       | $1EFC
    .byte $A0 ; |X X     | $1EFD
    .byte $C0 ; |XX      | $1EFE
    .byte $FF ; |XXXXXXXX| $1EFF
  ELSE
L1EF0:
    .byte $60 ; | XX     | $1EF0
    .byte $A0 ; |X X     | $1EF1
    .byte $D0 ; |XX X    | $1EF2
    .byte $FF ; |XXXXXXXX| $1EF3
    .byte $FF ; |XXXXXXXX| $1EF4
    .byte $D0 ; |XX X    | $1EF5
    .byte $A0 ; |X X     | $1EF6
    .byte $60 ; | XX     | $1EF7
L1EF8:
    .byte $FF ; |XXXXXXXX| $1EF8
    .byte $F0 ; |XXXX    | $1EF9
    .byte $C0 ; |XX      | $1EFA
    .byte $A0 ; |X X     | $1EFB
    .byte $A0 ; |X X     | $1EFC
    .byte $C0 ; |XX      | $1EFD
    .byte $F0 ; |XXXX    | $1EFE
    .byte $FF ; |XXXXXXXX| $1EFF
  ENDIF

    .byte $7C ; | XXXXX  | $1F00
    .byte $64 ; | XX  X  | $1F01
    .byte $64 ; | XX  X  | $1F02
    .byte $64 ; | XX  X  | $1F03
    .byte $64 ; | XX  X  | $1F04
    .byte $64 ; | XX  X  | $1F05
    .byte $64 ; | XX  X  | $1F06
    .byte $64 ; | XX  X  | $1F07
    .byte $7C ; | XXXXX  | $1F08
    .byte $00 ; |        | $1F09
    .byte $18 ; |   XX   | $1F0A
    .byte $18 ; |   XX   | $1F0B
    .byte $18 ; |   XX   | $1F0C
    .byte $18 ; |   XX   | $1F0D
    .byte $18 ; |   XX   | $1F0E
    .byte $18 ; |   XX   | $1F0F
    .byte $18 ; |   XX   | $1F10
    .byte $18 ; |   XX   | $1F11
    .byte $38 ; |  XXX   | $1F12
    .byte $00 ; |        | $1F13
    .byte $7C ; | XXXXX  | $1F14
    .byte $4C ; | X  XX  | $1F15
    .byte $4C ; | X  XX  | $1F16
    .byte $40 ; | X      | $1F17
    .byte $3C ; |  XXXX  | $1F18
    .byte $0C ; |    XX  | $1F19
    .byte $4C ; | X  XX  | $1F1A
    .byte $4C ; | X  XX  | $1F1B
    .byte $7C ; | XXXXX  | $1F1C
    .byte $00 ; |        | $1F1D
    .byte $7C ; | XXXXX  | $1F1E
    .byte $4C ; | X  XX  | $1F1F
    .byte $4C ; | X  XX  | $1F20
    .byte $0C ; |    XX  | $1F21
    .byte $38 ; |  XXX   | $1F22
    .byte $0C ; |    XX  | $1F23
    .byte $4C ; | X  XX  | $1F24
    .byte $4C ; | X  XX  | $1F25
    .byte $7C ; | XXXXX  | $1F26
    .byte $00 ; |        | $1F27
    .byte $0C ; |    XX  | $1F28
    .byte $0C ; |    XX  | $1F29
    .byte $7E ; | XXXXXX | $1F2A
    .byte $4C ; | X  XX  | $1F2B
    .byte $4C ; | X  XX  | $1F2C
    .byte $4C ; | X  XX  | $1F2D
    .byte $4C ; | X  XX  | $1F2E
    .byte $4C ; | X  XX  | $1F2F
    .byte $4C ; | X  XX  | $1F30
    .byte $00 ; |        | $1F31
    .byte $7C ; | XXXXX  | $1F32
    .byte $4C ; | X  XX  | $1F33
    .byte $4C ; | X  XX  | $1F34
    .byte $0C ; |    XX  | $1F35
    .byte $0C ; |    XX  | $1F36
    .byte $7C ; | XXXXX  | $1F37
    .byte $40 ; | X      | $1F38
    .byte $4C ; | X  XX  | $1F39
    .byte $7C ; | XXXXX  | $1F3A
    .byte $00 ; |        | $1F3B
    .byte $7C ; | XXXXX  | $1F3C
    .byte $4C ; | X  XX  | $1F3D
    .byte $4C ; | X  XX  | $1F3E
    .byte $4C ; | X  XX  | $1F3F
    .byte $7C ; | XXXXX  | $1F40
    .byte $40 ; | X      | $1F41
    .byte $4C ; | X  XX  | $1F42
    .byte $4C ; | X  XX  | $1F43
    .byte $7C ; | XXXXX  | $1F44
    .byte $00 ; |        | $1F45
    .byte $30 ; |  XX    | $1F46
    .byte $30 ; |  XX    | $1F47
    .byte $30 ; |  XX    | $1F48
    .byte $18 ; |   XX   | $1F49
    .byte $18 ; |   XX   | $1F4A
    .byte $0C ; |    XX  | $1F4B
    .byte $4C ; | X  XX  | $1F4C
    .byte $4C ; | X  XX  | $1F4D
    .byte $7C ; | XXXXX  | $1F4E
    .byte $00 ; |        | $1F4F
    .byte $7C ; | XXXXX  | $1F50
    .byte $4C ; | X  XX  | $1F51
    .byte $4C ; | X  XX  | $1F52
    .byte $4C ; | X  XX  | $1F53
    .byte $7C ; | XXXXX  | $1F54
    .byte $64 ; | XX  X  | $1F55
    .byte $64 ; | XX  X  | $1F56
    .byte $64 ; | XX  X  | $1F57
    .byte $7C ; | XXXXX  | $1F58
    .byte $00 ; |        | $1F59
    .byte $7C ; | XXXXX  | $1F5A
    .byte $4C ; | X  XX  | $1F5B
    .byte $4C ; | X  XX  | $1F5C
    .byte $0C ; |    XX  | $1F5D
    .byte $7C ; | XXXXX  | $1F5E
    .byte $4C ; | X  XX  | $1F5F
    .byte $4C ; | X  XX  | $1F60
    .byte $4C ; | X  XX  | $1F61
    .byte $7C ; | XXXXX  | $1F62
    .byte $00 ; |        | $1F63
    .byte $00 ; |        | $1F64
    .byte $00 ; |        | $1F65
    .byte $00 ; |        | $1F66
    .byte $00 ; |        | $1F67
    .byte $00 ; |        | $1F68
    .byte $00 ; |        | $1F69
    .byte $00 ; |        | $1F6A
    .byte $00 ; |        | $1F6B
    .byte $00 ; |        | $1F6C
    .byte $00 ; |        | $1F6D
    .byte $3F ; |  XXXXXX| $1F6E
    .byte $40 ; | X      | $1F6F
    .byte $49 ; | X  X  X| $1F70
    .byte $89 ; |X   X  X| $1F71
    .byte $89 ; |X   X  X| $1F72
    .byte $89 ; |X   X  X| $1F73
    .byte $89 ; |X   X  X| $1F74
    .byte $48 ; | X  X   | $1F75
    .byte $40 ; | X      | $1F76
    .byte $3F ; |  XXXXXX| $1F77
    .byte $FF ; |XXXXXXXX| $1F78
    .byte $00 ; |        | $1F79
    .byte $54 ; | X X X  | $1F7A
    .byte $54 ; | X X X  | $1F7B
    .byte $57 ; | X X XXX| $1F7C
    .byte $54 ; | X X X  | $1F7D
    .byte $54 ; | X X X  | $1F7E
    .byte $A3 ; |X X   XX| $1F7F
    .byte $00 ; |        | $1F80
    .byte $FF ; |XXXXXXXX| $1F81
    .byte $FF ; |XXXXXXXX| $1F82
    .byte $00 ; |        | $1F83
    .byte $99 ; |X  XX  X| $1F84
    .byte $A5 ; |X X  X X| $1F85
    .byte $AD ; |X X XX X| $1F86
    .byte $A1 ; |X X    X| $1F87
    .byte $A5 ; |X X  X X| $1F88
    .byte $19 ; |   XX  X| $1F89
    .byte $00 ; |        | $1F8A
    .byte $FF ; |XXXXXXXX| $1F8B
    .byte $FC ; |XXXXXX  | $1F8C
    .byte $02 ; |      X | $1F8D
    .byte $32 ; |  XX  X | $1F8E
    .byte $49 ; | X  X  X| $1F8F
    .byte $41 ; | X     X| $1F90
    .byte $41 ; | X     X| $1F91
    .byte $49 ; | X  X  X| $1F92
    .byte $32 ; |  XX  X | $1F93
    .byte $02 ; |      X | $1F94
    .byte $FC ; |XXXXXX  | $1F95
L1F96:
    .byte $06 ; |     XX | $1F96
    .byte $07 ; |     XXX| $1F97
    .byte $08 ; |    X   | $1F98
    .byte $07 ; |     XXX| $1F99
    .byte $06 ; |     XX | $1F9A
    .byte $07 ; |     XXX| $1F9B
    .byte $06 ; |     XX | $1F9C
    .byte $05 ; |     X X| $1F9D
    .byte $04 ; |     X  | $1F9E
    .byte $03 ; |      XX| $1F9F
    .byte $04 ; |     X  | $1FA0
    .byte $06 ; |     XX | $1FA1
L1FA2:
    .byte $01 ; |       X| $1FA2
    .byte $00 ; |        | $1FA3
    .byte $02 ; |      X | $1FA4
    .byte $00 ; |        | $1FA5
    .byte $03 ; |      XX| $1FA6
    .byte $00 ; |        | $1FA7
    .byte $04 ; |     X  | $1FA8
    .byte $00 ; |        | $1FA9
    .byte $05 ; |     X X| $1FAA
    .byte $00 ; |        | $1FAB
    .byte $06 ; |     XX | $1FAC
    .byte $00 ; |        | $1FAD
  IF COL_NTSC
    .byte $C8 ; |XX  X   | $1FAE
    .byte $C8 ; |XX  X   | $1FAF
    .byte $88 ; |X   X   | $1FB0
    .byte $48 ; | X  X   | $1FB1
    .byte $38 ; |  XXX   | $1FB2
    .byte $28 ; |  X X   | $1FB3
    .byte $76 ; | XXX XX | $1FB4
    .byte $78 ; | XXXX   | $1FB5
    .byte $0C ; |    XX  | $1FB6
    .byte $0C ; |    XX  | $1FB7
    .byte $8A ; |X   X X | $1FB8
    .byte $7A ; | XXXX X | $1FB9
    .byte $6A ; | XX X X | $1FBA
    .byte $5A ; | X XX X | $1FBB
    .byte $4A ; | X  X X | $1FBC
    .byte $3A ; |  XXX X | $1FBD
    .byte $48 ; | X  X   | $1FBE
    .byte $48 ; | X  X   | $1FBF
    .byte $48 ; | X  X   | $1FC0
    .byte $78 ; | XXXX   | $1FC1
    .byte $88 ; |X   X   | $1FC2
    .byte $98 ; |X  XX   | $1FC3
    .byte $A8 ; |X X X   | $1FC4
    .byte $B8 ; |X XXX   | $1FC5
    .byte $C6 ; |XX   XX | $1FC6
    .byte $C6 ; |XX   XX | $1FC7
    .byte $C6 ; |XX   XX | $1FC8
    .byte $C6 ; |XX   XX | $1FC9
    .byte $EE ; |XXX XXX | $1FCA
    .byte $EE ; |XXX XXX | $1FCB
    .byte $6C ; | XX XX  | $1FCC
    .byte $6C ; | XX XX  | $1FCD
    .byte $46 ; | X   XX | $1FCE
    .byte $46 ; | X   XX | $1FCF
    .byte $46 ; | X   XX | $1FD0
    .byte $46 ; | X   XX | $1FD1
    .byte $3E ; |  XXXXX | $1FD2
    .byte $3E ; |  XXXXX | $1FD3
    .byte $9C ; |X  XXX  | $1FD4
    .byte $9C ; |X  XXX  | $1FD5
    .byte $86 ; |X    XX | $1FD6
    .byte $86 ; |X    XX | $1FD7
    .byte $48 ; | X  X   | $1FD8
    .byte $48 ; | X  X   | $1FD9
    .byte $E4 ; |XXX  X  | $1FDA
    .byte $E4 ; |XXX  X  | $1FDB
    .byte $28 ; |  X X   | $1FDC
    .byte $28 ; |  X X   | $1FDD
    .byte $38 ; |  XXX   | $1FDE
    .byte $38 ; |  XXX   | $1FDF
    .byte $48 ; | X  X   | $1FE0
    .byte $48 ; | X  X   | $1FE1
    .byte $68 ; | XX X   | $1FE2
    .byte $68 ; | XX X   | $1FE3
    .byte $78 ; | XXXX   | $1FE4
    .byte $78 ; | XXXX   | $1FE5
  ELSE
    .byte $5C ; | X XXX  | $1FAE
    .byte $5C ; | X XXX  | $1FAF
    .byte $BC ; |X XXXX  | $1FB0
    .byte $6C ; | XX XX  | $1FB1
    .byte $4C ; | X  XX  | $1FB2
    .byte $4C ; | X  XX  | $1FB3
    .byte $B8 ; |X XXX   | $1FB4
    .byte $BC ; |X XXXX  | $1FB5
    .byte $0E ; |    XXX | $1FB6
    .byte $0E ; |    XXX | $1FB7
    .byte $BC ; |X XXXX  | $1FB8
    .byte $BC ; |X XXXX  | $1FB9
    .byte $AC ; |X X XX  | $1FBA
    .byte $8C ; |X   XX  | $1FBB
    .byte $6C ; | XX XX  | $1FBC
    .byte $4C ; | X  XX  | $1FBD
    .byte $4A ; | X  X X | $1FBE
    .byte $4A ; | X  X X | $1FBF
    .byte $4A ; | X  X X | $1FC0
    .byte $BC ; |X XXXX  | $1FC1
    .byte $BC ; |X XXXX  | $1FC2
    .byte $DC ; |XX XXX  | $1FC3
    .byte $9A ; |X  XX X | $1FC4
    .byte $7A ; | XXXX X | $1FC5
    .byte $58 ; | X XX   | $1FC6
    .byte $58 ; | X XX   | $1FC7
    .byte $5A ; | X XX X | $1FC8
    .byte $5A ; | X XX X | $1FC9
    .byte $3E ; |  XXXXX | $1FCA
    .byte $3E ; |  XXXXX | $1FCB
    .byte $AE ; |X X XXX | $1FCC
    .byte $AE ; |X X XXX | $1FCD
    .byte $4A ; | X  X X | $1FCE
    .byte $4A ; | X  X X | $1FCF
    .byte $4A ; | X  X X | $1FD0
    .byte $48 ; | X  X   | $1FD1
    .byte $BE ; |X XXXXX | $1FD2
    .byte $BE ; |X XXXXX | $1FD3
    .byte $DE ; |XX XXXX | $1FD4
    .byte $DE ; |XX XXXX | $1FD5
    .byte $BA ; |X XXX X | $1FD6
    .byte $BA ; |X XXX X | $1FD7
    .byte $4A ; | X  X X | $1FD8
    .byte $4C ; | X  XX  | $1FD9
    .byte $28 ; |  X X   | $1FDA
    .byte $28 ; |  X X   | $1FDB
    .byte $4C ; | X  XX  | $1FDC
    .byte $4A ; | X  X X | $1FDD
    .byte $4C ; | X  XX  | $1FDE
    .byte $4A ; | X  X X | $1FDF
    .byte $4C ; | X  XX  | $1FE0
    .byte $4A ; | X  X X | $1FE1
    .byte $AC ; |X X XX  | $1FE2
    .byte $AA ; |X X X X | $1FE3
    .byte $BC ; |X XXXX  | $1FE4
    .byte $BA ; |X XXX X | $1FE5
  ENDIF
L1FE6:
    .byte $10 ; |   X    | $1FE6
    .byte $15 ; |   X X X| $1FE7
    .byte $20 ; |  X     | $1FE8
    .byte $25 ; |  X  X X| $1FE9
    .byte $30 ; |  XX    | $1FEA
    .byte $35 ; |  XX X X| $1FEB


       ORG $1FEC

  IF COL_NTSC
L1ACE:
    .byte $56 ; | X X XX | $1ACE
    .byte $F8 ; |XXXXX   | $1ACF
L1AD0:
    .byte $2C ; |  X XX  | $1AD0
    .byte $7A ; | XXXX X | $1AD1
  ELSE
L1ACE:
    .byte $88 ; |X   X   | $1ACE
    .byte $2A ; |  X X X | $1ACF
L1AD0:
    .byte $4E ; | X  XXX | $1AD0
    .byte $BC ; |X XXXX  | $1AD1
  ENDIF

; L1FEC:
;     .byte $15 ; |   X X X| $1FEC
;     .byte $00 ; |        | $1FED
;     .byte $00 ; |        | $1FEE
;     .byte $1A ; |   XX X | $1FEF
;     .byte $00 ; |        | $1FF0
;     .byte $00 ; |        | $1FF1
;     .byte $00 ; |        | $1FF2
;     .byte $1C ; |   XXX  | $1FF3
;     .byte $17 ; |   X XXX| $1FF4
;     .byte $1A ; |   XX X | $1FF5
;     .byte $15 ; |   X X X| $1FF6
;     .byte $17 ; |   X XXX| $1FF7
;     .byte $13 ; |   X  XX| $1FF8
;     .byte $15 ; |   X X X| $1FF9
;     .byte $11 ; |   X   X| $1FFA
;     .byte $00 ; |        | $1FFB


       ORG $1FF4

L1D9C:
    .byte $00 ; |        | $1D9C
    .byte $28 ; |  X X   | $1D9D
    .byte $28 ; |  X X   | $1D9E
    .byte $38 ; |  XXX   | $1D9F
    .byte $10 ; |   X    | $1DA0
    .byte $10 ; |   X    | $1DA1

       ORG $1FFA
  IF PLUSROM
    .word ((PlusROM_API & $0FFF) + $1000)
  ELSE
    .word START
  ENDIF

       ORG $1FFC

    .word START
    .word START

