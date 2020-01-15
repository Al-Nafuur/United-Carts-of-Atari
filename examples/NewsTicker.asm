; 36 character t-online.de Newsticker using PlusROM functions
; By Al_Nafuur

; based on:
; 36 character demo
; By Omegamatrix (last update May 11, 2018)
; https://atariage.com/forums/topic/278667-36-character-demo

      processor 6502
    LIST OFF
TIA_BASE_ADDRESS = $40
      include vcs.h
      include macro.h
    LIST ON

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FAST_LOAD            = 0       ; 1 = shorter spacing between rows, 0 = wider spacing

  IF FAST_LOAD
TOP_LINES            = 50
BOTTOM_LINES         = 77
  ELSE
TOP_LINES            = 54-5*5
BOTTOM_LINES         = 73
  ENDIF

TIME_VBLANK          = 46
TIME_OVERSCAN        = 25

GFX_HEIGHT           = 5

BORDER_SHAPE         = $30

SCROLL_MASK          = $0F

P0_POS_KERNEL_A      = 159
P0_POS_KERNEL_B      = 151
P1_POS_KERNEL_A      = 72
P1_POS_KERNEL_B      = 72-8
BALL_POS             = 12


COL_TEXT             = $0E
COL_SCREEN           = $A2


;74 cycle HMxx
LEFT74_15            = $70
LEFT74_14            = $60
LEFT74_13            = $50
LEFT74_12            = $40
LEFT74_11            = $30
LEFT74_10            = $20
LEFT74_9             = $10
LEFT74_8             = $00
LEFT74_7             = $F0
LEFT74_6             = $E0
LEFT74_5             = $D0
LEFT74_4             = $C0
LEFT74_3             = $B0
LEFT74_2             = $A0
LEFT74_1             = $90
NO_MO_74             = $80

;NUSIZx
ONE_COPY             = $00
TWO_COPIES_CLOSE     = $01
TWO_COPIES_MED       = $02
THREE_COPIES_CLOSE   = $03
TWO_COPIES_WIDE      = $04
DOUBLE_SIZE          = $05
THREE_COPIES_MED     = $06
QUAD_SIZE            = $07

;CTRLPF bits
PF_REFLECT           = $01
PF_SCORE             = $02
PF_PRIORITY          = $04
BALL_8_CLKS          = $30
BALL_4_CLKS          = $20
BALL_2_CLKS          = $10
BALL_1_CLK           = $00

ENABLE               = 2
DISABLE              = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        SEG.U variables
        ORG $80


frameCounter   ds 1
textPtr        ds 2
tempOne        ds 1
tempIndex      ds 1
scrollIndex    ds 1
stackRestore   ds 1  ; constant can be used if stack is known
stackRestore_2 ds 1

gfx_AB_Morph   ds GFX_HEIGHT
gfx_A          ds GFX_HEIGHT
gfx_B          ds GFX_HEIGHT
gfx_C          ds GFX_HEIGHT
gfx_D          ds GFX_HEIGHT
gfx_E          ds GFX_HEIGHT
gfx_F          ds GFX_HEIGHT
gfx_G          ds GFX_HEIGHT
gfx_H          ds GFX_HEIGHT
gfx_I          ds GFX_HEIGHT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;---------------------------------------
;  Macros to draw the display
;---------------------------------------

  MAC KERNEL_A
    SLEEP 5
    lda    gfx_A + {1}           ;3  @8
    sta    GRP0                  ;3  @11
    lda    gfx_D + {1}           ;3  @14
    sta    GRP1                  ;3  @17
    ldx    gfx_C + {1}           ;3  @20
    ldy    gfx_E + {1}           ;3  @23
    sta    RESP0                 ;3  @26
    lda    gfx_B + {1}           ;3  @29
    sta    GRP0                  ;3  @32
    SLEEP 2
    stx    GRP0                  ;3  @37
    lda    gfx_F + {1}           ;3  @40
    ldx    gfx_G + {1}           ;3  @43
    stx    GRP0                  ;3  @46
    sty    GRP1                  ;3  @49
    sta    RESP0                 ;3  @52
    sta    GRP1                  ;3  @55
    sta    RESP0                 ;3  @58
    lda    gfx_H + {1}           ;3  @61
    sta    GRP0                  ;3  @64
    lda    gfx_I + {1}           ;3  @67
    sta    GRP0                  ;3  @70
    sta.w  RESP0                 ;4  @74   extra cycle was necessary for 4 switch
    SLEEP 2
  ENDM

  MAC KERNEL_B
    sta    GRP0                  ;3  @3
    lda    gfx_E + {1}           ;3  @6
    sta    GRP1                  ;3  @9
    ldx    gfx_H + {1}           ;3  @12
    txs                          ;2  @14
    ldx    gfx_C + {1}           ;3  @17
    ldy    gfx_B + {1}           ;3  @20
    lda    gfx_AB_Morph + {1}    ;3  @23
    sta    GRP0                  ;3  @26  early! still drawing the gfx_A...
    sta    RESP0                 ;3  @29
    sty    GRP0                  ;3  @32
    stx    GRP0                  ;3  @35
    lda    gfx_D + {1}           ;3  @38
    sta    GRP0                  ;3  @41
    lda    gfx_F + {1}           ;3  @44
    sta    GRP1                  ;3  @47
    lda    gfx_G + {1}           ;3  @50
    sta    GRP1                  ;3  @53
    sta    RESP0                 ;3  @56
    tsx                          ;2  @58
    stx    GRP0                  ;3  @61
    lda    gfx_I + {1}           ;3  @64
    sta    GRP0                  ;3  @67
    lda    gfx_A + {1} -1        ;3  @70
    sta    HMOVE                 ;3  @73
    sta    RESP0                 ;3  @76
  ENDM

;---------------------------------------
;  Macros to prep the ram graphics
;---------------------------------------

   MAC INDEX_TEMP
    clc
    lda    tempIndex
    adc    #{1}
    tay
    lax    (textPtr),Y  ; LEFT
    iny
    lda    (textPtr),Y  ; RIGHT
    tay
   ENDM

   MAC RAM_STORE_A
;left digit appears shifted 1 pixel to right on the screen
    lda    RightGfxTab,Y
    asl
    ora    LeftGfxTab,X
    pha
    lda    RightGfxTab+1,Y
    asl
    ora    LeftGfxTab+1,X
    pha
    lda    RightGfxTab+2,Y
    asl
    ora    LeftGfxTab+2,X
    pha
    lda    RightGfxTab+3,Y
    asl
    ora    LeftGfxTab+3,X
    pha
    lda    RightGfxTab+4,Y
    asl
    ora    LeftGfxTab+4,X
    pha
  ENDM

   MAC RAM_STORE_B
    lda    RightGfxTab,Y
    ora    LeftGfxTab,X
    pha
    lda    RightGfxTab+1,Y
    ora    LeftGfxTab+1,X
    pha
    lda    RightGfxTab+2,Y
    ora    LeftGfxTab+2,X
    pha
    lda    RightGfxTab+3,Y
    ora    LeftGfxTab+3,X
    pha
    lda    RightGfxTab+4,Y
    ora    LeftGfxTab+4,X
    pha
  ENDM

   MAC RAM_STORE_C
    lda    RightGfxTab,Y
    ora    LeftGfxTab,X
    lsr
    pha
    lda    RightGfxTab+1,Y
    ora    LeftGfxTab+1,X
    lsr
    pha
    lda    RightGfxTab+2,Y
    ora    LeftGfxTab+2,X
    lsr
    pha
    lda    RightGfxTab+3,Y
    ora    LeftGfxTab+3,X
    lsr
    pha
    lda    RightGfxTab+4,Y
    ora    LeftGfxTab+4,X
    lsr
    pha
  ENDM

  MAC RAM_STORE_D
    lda    gfx_A+4
    and    #$0F
    sta    tempOne
    lda    gfx_B+4
    and    #$F8
    ora    tempOne
    pha

    lda    gfx_A+3
    and    #$0F
    sta    tempOne
    lda    gfx_B+3
    and    #$F8
    ora    tempOne
    pha

    lda    gfx_A+2
    and    #$0F
    sta    tempOne
    lda    gfx_B+2
    and    #$F8
    ora    tempOne
    pha

    lda    gfx_A+1
    and    #$0F
    sta    tempOne
    lda    gfx_B+1
    and    #$F8
    ora    tempOne
    pha

    lda    gfx_A+0
    and    #$0F
    sta    tempOne
    lda    gfx_B+0
    and    #$F8
    ora    tempOne
    pha
  ENDM

;---------------------------------------
;  Macros to prep the ram graphics (using nested subroutines to save bytes)
;---------------------------------------

  MAC SAVE_SP
    tsx
    stx    stackRestore_2
    tax    ; using PHA to write to ram
    txs
  ENDM

  MAC PREP_RAM_WRITE
    SAVE_SP
    clc
    tya
    adc    tempIndex
    tay
    lax    (textPtr),Y  ; LEFT
    iny
    lda    (textPtr),Y  ; RIGHT
    tay
  ENDM

  MAC FINISH_RAM_WRITE
    tsx
    txa    ; save index the subsequent routines
    ldx    stackRestore_2
    txs
    rts
  ENDM

  MAC RAM_STORE_A_SUB
    PREP_RAM_WRITE
    RAM_STORE_A
    FINISH_RAM_WRITE
  ENDM

  MAC RAM_STORE_B_SUB
    PREP_RAM_WRITE
    RAM_STORE_B
    FINISH_RAM_WRITE
  ENDM

  MAC RAM_STORE_C_SUB
    PREP_RAM_WRITE
    RAM_STORE_C
    FINISH_RAM_WRITE
  ENDM

  MAC RAM_STORE_D_SUB
    SAVE_SP
    RAM_STORE_D
    FINISH_RAM_WRITE
  ENDM

ORIGIN SET 0
ROM_BANK_SIZE         = $800
SWITCH_BANK           = $3F

SET_BANK_RAM                = $3E               ; write address to switch RAM banks
RAM_3E                      = $1000
RAM_SIZE                    = $400
RAM_WRITE                   = $400              ; add this to RAM address when doing writes


FIXED_BANK             = 3 * 2048           ;-->  8K ROM tested OK
;FIXED_BANK              = 7 * 2048          ;-->  16K ROM tested OK
;FIXED_BANK             = 15 * 2048           ; ->> 32K
;FIXED_BANK             = 31 * 2048           ; ->> 64K


            MAC NEWBANK ; bank name
                SEG {1}
                ORG ORIGIN
                RORG $F000            ; non-fixed banks always at $F000 (2k)
BANK_START      SET *
{1}             SET ORIGIN / 2048
ORIGIN          SET ORIGIN + 2048
_CURRENT_BANK   SET {1}
            ENDM


;------------------------------------------------------------------------------
;                                 MAIN PROGRAM
;------------------------------------------------------------------------------
WriteToBuffer equ $1ff0
WriteSendBuffer equ $1ff1
ReceiveBuffer equ $1ff2
ReceiveBufferSize equ $1ff3


        SEG code
        NEWBANK BANK_A


DemoTable1:
	.byte "NewsTickerAPI.php", #0
	.byte "pluscart.firmaplus"
        
DemoTable2:
        .byte ".de", #0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    .byte _4,_5,_6,_7,_8,_9,_A,_B,_C,_D,_E,_F,_G,_H,_I,_J,_K,_L,_M,_N,_O,_P,_Q,_R,_S,_T,_U,_V,_W,_X,_Y,_Z

DemoTable3:
    .byte _T,_H,_E, _SPACE, _3,_6, _SPACE, _C,_H,_A,_R,_A,_C,_T,_E,_R, _SPACE, _D,_E,_M,_O, _SPACE, _B,_Y, _SPACE, _O,_M,_E,_G,_A,_M,_A,_T,_R,_I,_X

DemoTable4:
    .byte _SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE
    .byte _SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE
    .byte _H,_E,_L,_L,_O,_SPACE,_T,_H,_E,_R,_E,_EXCLAMATION,_SPACE,_T,_H,_I,_S,_SPACE,_I,_S,_SPACE,_A,_SPACE,_D,_E,_M,_O,_SPACE,_F,_O,_R,_SPACE,_T,_H,_E,_SPACE,_A,_T,_A,_R,_I,_SPACE,_2,_6,_0,_0,_PERIOD
    .byte _SPACE,_C,_A,_N,_SPACE,_Y,_O,_U,_SPACE,_R,_E,_A,_D,_SPACE,_T,_H,_I,_S,_SPACE,_T,_E,_X,_T,_SPACE,_A,_S,_SPACE,_I,_T,_SPACE,_S,_C,_R,_O,_L,_L,_S,_SPACE,_A,_C,_R,_O,_S,_S,_SPACE,_T,_H,_E,_SPACE,_S,_C,_R,_E,_E,_N,_QUESTION
    .byte _SPACE,_T,_H,_I,_S,_SPACE,_D,_I,_S,_P,_L,_A,_Y,_SPACE,_I,_S,_SPACE,_B,_E,_I,_N,_G,_SPACE,_D,_O,_N,_E,_SPACE,_W,_I,_T,_H,_SPACE,_S,_T,_O,_C,_K,_SPACE,_H,_A,_R,_D,_W,_A,_R,_E,_SPACE,_A,_T,_SPACE,_3,_0,_H,_Z,_PERIOD
    .byte _SPACE,_T,_H,_E,_SPACE,_A,_L,_I,_G,_N,_M,_E,_N,_T,_SPACE,_I,_S,_SPACE,_N,_O,_T,_SPACE,_P,_E,_R,_F,_E,_C,_T,_COMMA,_SPACE,_B,_U,_T,_SPACE,_I,_SPACE,_H,_O,_P,_E,_SPACE,_Y,_O,_U,_SPACE,_E,_N,_J,_O,_Y,_SPACE,_I,_T,_SPACE
    .byte _A,_L,_L,_SPACE,_T,_H,_E,_SPACE,_S,_A,_M,_E,_PERIOD

DemoTable5:
    .byte _EXCLAMATION      ;  !
    .byte _QUOTE            ;  "
    .byte _NUMBER           ;  #
    .byte _DOLLAR           ;  $
    .byte _PERCENT          ;  %
    .byte _AMPERSAND        ;  &
    .byte _APOSTROPHE       ;  '
    .byte _L_BRACKET        ;  (
    .byte _R_BRACKET        ;  )
    .byte _ASTERIX          ;  *
    .byte _PLUS             ;  +
    .byte _COMMA            ;  ,
    .byte _HYPHEN           ;  -
    .byte _PERIOD           ;  .
    .byte _F_SLASH          ;  /
    .byte _COLON            ;  :
    .byte _SEMICOLON        ;  ;
    .byte _LESS_THAN        ;  <
    .byte _EQUAL            ;  =
    .byte _GREATER_THAN     ;  >
    .byte _QUESTION         ;  ?
    .byte _AT               ;  @
    .byte _L_SQR_BRACKET    ;  [
    .byte _B_SLASH          ;  \
    .byte _R_SQR_BRACKET    ;  ]
    .byte _CARET            ;  ^
    .byte _UNDERSCORE       ;  _
    .byte _ACCENT           ;  `
    .byte _L_CURLY_BRACKET  ;  {
    .byte _VERT_BAR         ;  |
    .byte _R_CURLY_BRACKET  ;  }
    .byte _TILDE            ;  ~
    .byte _DEGREE           ;
    .byte _SQUARE           ;
    .byte _PLUS_MINUS       ;
    .byte _DIVISION         ;



ORIGIN      SET FIXED_BANK

            NEWBANK THE_FIXED_BANK
            RORG $f800                  ; FIXED BANK ALWAYS AT $F800 (2K long)
DemoTable0:
    .byte _T,_HYPHEN,_O,_N,_L,_I,_N,_E,_SPACE,_N,_E,_W,_S,_HYPHEN,_T,_I,_C,_K,_E,_R,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE,_SPACE, _SPACE,_SPACE,_SPACE,_SPACE,_SPACE


START:
    cld
.splshLoopClear:
    ldx    #$0A                  ; ASL opcode = $0A
    inx
    txs
    pha
    bne    .splshLoopClear+1     ; jump between operator and operand to do ASL


;------------------------------------------------------------------------------
;                               VSYNC AND VBLANK
;------------------------------------------------------------------------------
    lda #0
    sta SET_BANK_RAM
    lda #0                       ; Stella 3E detection ?
    sta WriteSendBuffer
; Clear RAM
    ldx #$ff
    lda #_SPACE
.clearRAM1:
    sta DemoTable1 + RAM_WRITE,x 
    dex
    bne    .clearRAM1     ; jump between operator and operand to do ASL



LoopMain:
    lda    #$0E
.loopVsync:
    sta    WSYNC
;---------------------------------------
    sta    VSYNC
    lsr
    bne    .loopVsync

    lda    #TIME_VBLANK
    sta    TIM64T


    lda    #COL_SCREEN
    sta    COLUBK
    sta    COLUPF
    lda    #COL_TEXT
    sta    COLUP0
    sta    COLUP1
    lda    #THREE_COPIES_CLOSE
    sta    NUSIZ0
    sta    NUSIZ1

    lda    #BORDER_SHAPE
    sta    PF0

    lda    #BALL_1_CLK | PF_PRIORITY | PF_REFLECT
    sta    CTRLPF


;---------------------------------------
;  Do Positioning
;---------------------------------------

    lda    frameCounter
    and    #$01
    tay

    lda    P0_Tab,Y
    ldx    #0
    jsr    Positioning

    lda    P1_Tab,Y
    inx                        ; X=1
    jsr    Positioning

    lda    #BALL_POS
    ldx    #4
    jsr    Positioning

    sta    WSYNC
;---------------------------------------
    sta    HMOVE

    sta    WSYNC
;---------------------------------------
    lda    #LEFT74_12
    sta    HMP0
    lda    #NO_MO_74
    sta    HMP1
    sta    HMBL

.waitVblank:
    lda    INTIM
    bne    .waitVblank
    sta    WSYNC
;---------------------------------------
    sta    VBLANK


;------------------------------------------------------------------------------
;                                 KERNEL
;------------------------------------------------------------------------------

    ldy    #TOP_LINES
.loopTop:
    sta    WSYNC
;---------------------------------------
    dey
    bne    .loopTop


    ldx    #>DemoTable0
    ldy    #<DemoTable0
    lda    #0
    jsr    LoadDemoTable
    jsr    DrawRow

    ldx    #>DemoTable1
    ldy    #<DemoTable1
    lda    #0
    jsr    LoadDemoTable
    jsr    DrawRow

    ldx    #>DemoTable2
    ldy    #<DemoTable2
    lda    #0
    jsr    LoadDemoTable
    jsr    DrawRow

    ldx    #>DemoTable3
    ldy    #<DemoTable3
    lda    #0
    jsr    LoadDemoTable
    jsr    DrawRow

    ldx    #>DemoTable4
    ldy    #<DemoTable4
    lda    scrollIndex
    jsr    LoadDemoTable
    jsr    DrawRow

    ldy    #BOTTOM_LINES
.loopBottom:
    sta    WSYNC
;---------------------------------------
    dey
    bne    .loopBottom

;------------------------------------------------------------------------------
;                                 OVERSCAN
;------------------------------------------------------------------------------

    lda    #2
    sta    VBLANK
    lda    #TIME_OVERSCAN
    sta    TIM64T

    inc    frameCounter

    lda    frameCounter
    and    #SCROLL_MASK
    bne    .skipScrollUpdate
    inc    scrollIndex
.skipScrollUpdate:

    lda ReceiveBufferSize
    beq .waitOverscan
FillRAMFromInternet
                lda ReceiveBuffer
                sta DemoTable1 + RAM_WRITE,x
                inx
                lda ReceiveBufferSize
                bne FillRAMFromInternet
    


.waitOverscan:
    lda    INTIM
    bne    .waitOverscan
    jmp    LoopMain
    

;------------------------------------------------------------------------------
;                                 SUBROUTINES
;------------------------------------------------------------------------------

DrawRow:
    lda    frameCounter
    lsr
    lda    #ENABLE
    sta    ENABL
    tsx
    stx    stackRestore
    bcc    .doKernelA
    jmp    .doKernelB

.doKernelA:
    sta    WSYNC
;---------------------------------------
    KERNEL_A  4
    KERNEL_A  3
    KERNEL_A  2
    KERNEL_A  1
    KERNEL_A  0
    jmp    .finishRow

.doKernelB:
    lda    gfx_A + GFX_HEIGHT-1
    sta    WSYNC
;---------------------------------------
    KERNEL_B  4
    KERNEL_B  3
    KERNEL_B  2
    KERNEL_B  1
    KERNEL_B  0

.finishRow:
    lda    #0                  ; clear all
    sta    GRP0
    sta    GRP1
    sta    ENABL
    ldx    stackRestore
    txs
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadDemoTable: SUBROUTINE

; fast load is all inline, otherwise nested subroutines are used

  IF FAST_LOAD

    stx    textPtr+1
    sty    textPtr
    sta    tempIndex
    tsx
    stx    stackRestore
    ldx    #<gfx_I + GFX_HEIGHT-1
    txs
    lda    frameCounter
    lsr
    sta    WSYNC
    bcs    .loadKernel
;---------------------------------------
    jmp    .loadKernel2

.loadKernel:
;---------------------------------------
; Digits 33, 34 (stores to "gfx_I")
;---------------------------------------
    INDEX_TEMP 33-1
    RAM_STORE_A
;---------------------------------------
; Digits 29, 30 (stores to "gfx_H")
;---------------------------------------
    INDEX_TEMP 29-1
    RAM_STORE_A
;---------------------------------------
; Digits 23, 24 (stores to "gfx_G")
;---------------------------------------
    INDEX_TEMP 23-1
    RAM_STORE_B
;---------------------------------------
; Digits 19, 20 (stores to "gfx_F")
;---------------------------------------
    INDEX_TEMP 19-1
    RAM_STORE_B
;---------------------------------------
; Digits 15, 16 (stores to "gfx_E")
;---------------------------------------
    INDEX_TEMP 15-1
    RAM_STORE_B
;---------------------------------------
; Digits 13, 14 (stores to "gfx_D")
;---------------------------------------
    INDEX_TEMP 13-1
    RAM_STORE_B
;---------------------------------------
; Digits 9, 10 (stores to "gfx_C")
;---------------------------------------
    INDEX_TEMP 9-1
    RAM_STORE_B
;---------------------------------------
; Digits 5, 6 (stores to "gfx_B")
;---------------------------------------
    INDEX_TEMP 5-1
    RAM_STORE_B
;---------------------------------------
; Digits 1, 2 (stores to "gfx_A")
;---------------------------------------
    INDEX_TEMP 1-1
    RAM_STORE_C
;---------------------------------------
; Digits 1,2 morph to 5,6 (stores to "gfx_AB_Morph")
;---------------------------------------
    RAM_STORE_D
    ldx    stackRestore
    txs
    rts


.loadKernel2:
;---------------------------------------
; Digits 35, 36 (stores to "gfx_I")
;---------------------------------------
    INDEX_TEMP 35-1
    RAM_STORE_C
;---------------------------------------
; Digits 31, 32 (stores to "gfx_H")
;---------------------------------------
    INDEX_TEMP 31-1
    RAM_STORE_C
;---------------------------------------
; Digits 27, 28 (stores to "gfx_G")
;---------------------------------------
    INDEX_TEMP 27-1
    RAM_STORE_C
;---------------------------------------
; Digits 25, 26 (stores to "gfx_F")
;---------------------------------------
    INDEX_TEMP 25-1
    RAM_STORE_B
;---------------------------------------
; Digits 21, 22 (stores to "gfx_E")
;---------------------------------------
    INDEX_TEMP 21-1
    RAM_STORE_B
;---------------------------------------
; Digits 17, 18 (stores to "gfx_D")
;---------------------------------------
    INDEX_TEMP 17-1
    RAM_STORE_B
;---------------------------------------
; Digits 11, 12 (stores to "gfx_C")
;---------------------------------------
    INDEX_TEMP 11-1
    RAM_STORE_C
;---------------------------------------
; Digits 7, 8 (stores to "gfx_B")
;---------------------------------------
    INDEX_TEMP 7-1
    RAM_STORE_C
;---------------------------------------
; Digits 3, 4 (stores to "gfx_A")
;---------------------------------------
    INDEX_TEMP 3-1
    RAM_STORE_C

    ldx    stackRestore
    txs
    sta    WSYNC
;---------------------------------------
    rts


  ELSE

; nested subroutines save bytes, but takes longer to load
    stx    textPtr+1
    sty    textPtr
    sta    tempIndex
    tsx
    stx    stackRestore
    lda    frameCounter
    lsr
    lda    #<gfx_I + GFX_HEIGHT-1
    bcs    .loadKernel
    jmp    .loadKernel2


.loadKernel:
;---------------------------------------
; Digits 33, 34 (stores to "gfx_I")
;---------------------------------------
    ldy    #33-1
    jsr    RamStoreA
;---------------------------------------
; Digits 29, 30 (stores to "gfx_H")
;---------------------------------------
    ldy    #29-1
    jsr    RamStoreA
;---------------------------------------
; Digits 23, 24 (stores to "gfx_G")
;---------------------------------------
    ldy    #23-1
    jsr    RamStoreB
;---------------------------------------
; Digits 19, 20 (stores to "gfx_F")
;---------------------------------------
    ldy    #19-1
    jsr    RamStoreB
;---------------------------------------
; Digits 15, 16 (stores to "gfx_E")
;---------------------------------------
    ldy    #15-1
    jsr    RamStoreB
;---------------------------------------
; Digits 13, 14 (stores to "gfx_D")
;---------------------------------------
    ldy    #13-1
    jsr    RamStoreB
;---------------------------------------
; Digits 9, 10 (stores to "gfx_C")
;---------------------------------------
    ldy    #9-1
    jsr    RamStoreB
;---------------------------------------
; Digits 5, 6 (stores to "gfx_B")
;---------------------------------------
    ldy    #5-1
    jsr    RamStoreB
;---------------------------------------
; Digits 1, 2 (stores to "gfx_A")
;---------------------------------------
    ldy    #1-1
    jsr    RamStoreC
;---------------------------------------
; Digits 1,2 morph to 5,6 (stores to "gfx_AB_Morph")
;---------------------------------------
    jsr    RamStoreD
    ldx    stackRestore
    txs
    rts


.loadKernel2:
;---------------------------------------
; Digits 35, 36 (stores to "gfx_I")
;---------------------------------------
    ldy    #35-1
    jsr    RamStoreC
;---------------------------------------
; Digits 31, 32 (stores to "gfx_H")
;---------------------------------------
    ldy    #31-1
    jsr    RamStoreC
;---------------------------------------
; Digits 27, 28 (stores to "gfx_G")
;---------------------------------------
    ldy    #27-1
    jsr    RamStoreC
;---------------------------------------
; Digits 25, 26 (stores to "gfx_F")
;---------------------------------------
    ldy    #25-1
    jsr    RamStoreB
;---------------------------------------
; Digits 21, 22 (stores to "gfx_E")
;---------------------------------------
    ldy    #21-1
    jsr    RamStoreB
;---------------------------------------
; Digits 17, 18 (stores to "gfx_D")
;---------------------------------------
    ldy    #17-1
    jsr    RamStoreB
;---------------------------------------
; Digits 11, 12 (stores to "gfx_C")
;---------------------------------------
    ldy    #11-1
    jsr    RamStoreC
;---------------------------------------
; Digits 7, 8 (stores to "gfx_B")
;---------------------------------------
    ldy    #7-1
    jsr    RamStoreC
;---------------------------------------
; Digits 3, 4 (stores to "gfx_A")
;---------------------------------------
    ldy    #3-1
    jsr    RamStoreC

    ldx    stackRestore
    txs
    sta    WSYNC
    sta    WSYNC
;---------------------------------------
    rts

;left digit appears shifted 1 pixel to right on the screen in RamStoreA
RamStoreA: SUBROUTINE
    RAM_STORE_A_SUB

RamStoreB: SUBROUTINE
    RAM_STORE_B_SUB

RamStoreC: SUBROUTINE
    RAM_STORE_C_SUB

;RamStoreD is only called once, and can be placed inline
RamStoreD: SUBROUTINE
    RAM_STORE_D_SUB

  ENDIF

;------------------------------------------------------------------------------
;                               GFX AND DATA
;------------------------------------------------------------------------------

       ALIGN 256
LeftGfxTab:

GfxStart:

_I = *-GfxStart
    .byte $E0 ; |XXX     |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
_J = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
_R = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $A0 ; |X X     |
    .byte $C0 ; |XX      |
_K = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
_D = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |
_B = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $A0 ; |X X     |
_P = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $A0 ; |X X     |  shared
    .byte $C0 ; |XX      |  shared
_L = *-GfxStart
    .byte $80 ; |X       |  shared
    .byte $80 ; |X       |  shared
    .byte $80 ; |X       |
    .byte $80 ; |X       |
_Z = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $20 ; |  X     |
    .byte $40 ; | X      |
    .byte $80 ; |X       |
_F = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $80 ; |X       |
    .byte $C0 ; |XX      |
    .byte $80 ; |X       |
    .byte $80 ; |X       |
_G = *-GfxStart
    .byte $60 ; | XX     |
    .byte $80 ; |X       |
    .byte $A0 ; |X X     |
    .byte $A0 ; |X X     |
_S = *-GfxStart
    .byte $60 ; | XX     |  shared
    .byte $80 ; |X       |
    .byte $40 ; | X      |
    .byte $20 ; |  X     |
_Q = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $A0 ; |X X     |
    .byte $A0 ; |X X     |
    .byte $C0 ; |XX      |
_L_SQR_BRACKET = *-GfxStart
    .byte $60 ; | XX     |  shared
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $60 ; | XX     |

_2 = *-GfxStart
    .byte $E0 ; |XXX     |
    .byte $20 ; |  X     |
_5 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $80 ; |X       |  shared
    .byte $E0 ; |XXX     |  shared
    .byte $20 ; |  X     |
_3 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $20 ; |  X     |
    .byte $60 ; | XX     |
    .byte $20 ; |  X     |
_6 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $80 ; |X       |
_8 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $A0 ; |X X     |  shared
_9 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $A0 ; |X X     |  shared
_7 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $20 ; |  X     |  shared
    .byte $20 ; |  X     |
    .byte $40 ; | X      |
_AMPERSAND = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $A0 ; |X X     |
    .byte $40 ; | X      |
    .byte $A0 ; |X X     |
_DOLLAR = *-GfxStart
    .byte $60 ; | XX     |  shared
    .byte $C0 ; |XX      |
    .byte $40 ; | X      |
    .byte $60 ; | XX     |
_N = *-GfxStart
    .byte $C0 ; |XX      |  shared
_U = *-GfxStart
    .byte $A0 ; |X X     |  shared
_W = *-GfxStart
    .byte $A0 ; |X X     |  shared
_H = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
    .byte $E0 ; |XXX     |  shared
_V = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
_X = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
    .byte $40 ; | X      |  shared
_Y = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
    .byte $40 ; | X      |
_APOSTROPHE = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $40 ; | X      |  shared
_SPACE = *-GfxStart
    .byte $00 ; |        |  shared
_PERIOD = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
_O = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $A0 ; |X X     |
    .byte $A0 ; |X X     |
_AE = *-GfxStart
    .byte $A0 ; |X X     |
_A = *-GfxStart
    .byte $40 ; | X      |  shared
_M = *-GfxStart
    .byte $A0 ; |X X     |  shared
_0 = *-GfxStart
    .byte $E0 ; |XXX     |  shared
    .byte $A0 ; |X X     |  shared
_4 = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |  shared
    .byte $E0 ; |XXX     |  shared
_F_SLASH = *-GfxStart
    .byte $20 ; |  X     |  shared
    .byte $20 ; |  X     |  shared
    .byte $40 ; | X      |
_B_SLASH = *-GfxStart
    .byte $80 ; |X       |  shared
    .byte $80 ; |X       |  shared
    .byte $40 ; | X      |
    .byte $20 ; |  X     |
_LESS_THAN = *-GfxStart
    .byte $20 ; |  X     |
    .byte $40 ; | X      |
_GREATER_THAN = *-GfxStart
    .byte $80 ; |X       |  shared
    .byte $40 ; | X      |  shared
    .byte $20 ; |  X     |  shared
    .byte $40 ; | X      |
    .byte $80 ; |X       |

_NUMBER = *-GfxStart
    .byte $A0 ; |X X     |
    .byte $E0 ; |XXX     |
    .byte $A0 ; |X X     |
    .byte $E0 ; |XXX     |
_PERCENT = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $20 ; |  X     |
    .byte $40 ; | X      |
    .byte $80 ; |X       |
_QUOTE = *-GfxStart
    .byte $A0 ; |X X     |  shared
    .byte $A0 ; |X X     |
_COMMA = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
    .byte $20 ; |  X     |
_L_BRACKET = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $80 ; |X       |
    .byte $80 ; |X       |
    .byte $80 ; |X       |
    .byte $40 ; | X      |
_R_BRACKET = *-GfxStart
    .byte $80 ; |X       |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $80 ; |X       |
_ASTERIX = *-GfxStart
    .byte $00 ; |        |
    .byte $A0 ; |X X     |
_CARET = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $A0 ; |X X     |  shared
_UNDERSCORE = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
_HYPHEN = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $00 ; |        |  shared
    .byte $E0 ; |XXX     |  shared
    .byte $00 ; |        |
_EQUAL =  *-GfxStart
    .byte $00 ; |        |  shared
    .byte $E0 ; |XXX     |
    .byte $00 ; |        |
    .byte $E0 ; |XXX     |
    .byte $00 ; |        |

_R_SQR_BRACKET = *-GfxStart
    .byte $C0 ; |XX      |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
    .byte $40 ; | X      |
_QUESTION = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $20 ; |  X     |
    .byte $40 ; | X      |
    .byte $00 ; |        |
_AT = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $A0 ; |X X     |
    .byte $A0 ; |X X     |
    .byte $80 ; |X       |
_C = *-GfxStart
    .byte $60 ; | XX     |  shared
    .byte $80 ; |X       |
    .byte $80 ; |X       |
    .byte $80 ; |X       |
_E = *-GfxStart
    .byte $60 ; | XX     |  shared
    .byte $80 ; |X       |
    .byte $C0 ; |XX      |
    .byte $80 ; |X       |
_L_CURLY_BRACKET = *-GfxStart
    .byte $60 ; | XX     |  shared
    .byte $40 ; | X      |
_R_CURLY_BRACKET = *-GfxStart
    .byte $C0 ; |XX      |  shared
    .byte $40 ; | X      |  shared
    .byte $60 ; | XX     |  shared
_1 = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $C0 ; |XX      |  shared
    .byte $40 ; | X      |
    .byte $40 ; | X      |
_T = *-GfxStart
    .byte $E0 ; |XXX     |  shared
_VERT_BAR = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $40 ; | X      |  shared
_EXCLAMATION = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $40 ; | X      |  shared
    .byte $40 ; | X      |  shared
_PLUS = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $40 ; | X      |  shared
    .byte $E0 ; |XXX     |
    .byte $40 ; | X      |
_TILDE = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $20 ; |  X     |
    .byte $E0 ; |XXX     |
    .byte $80 ; |X       |
_COLON = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $40 ; | X      |
_SEMICOLON = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $40 ; | X      |  shared
    .byte $00 ; |        |  shared
    .byte $40 ; | X      |
_ACCENT = *-GfxStart
    .byte $80 ; |X       |  shared
    .byte $40 ; | X      |
    .byte $00 ; |        |
    .byte $00 ; |        |
    .byte $00 ; |        |

_PLUS_MINUS = *-GfxStart
    .byte $40 ; | X      |
    .byte $E0 ; |XXX     |
    .byte $40 ; | X      |
_SQUARE = *-GfxStart
    .byte $00 ; |        |  shared
    .byte $E0 ; |XXX     |  shared
    .byte $E0 ; |XXX     |
    .byte $E0 ; |XXX     |
    .byte $00 ; |        |

_DIVISION = *-GfxStart
    .byte $40 ; | X      |
    .byte $00 ; |        |
    .byte $E0 ; |XXX     |
    .byte $00 ; |        |
_DEGREE = *-GfxStart
    .byte $40 ; | X      |  shared
    .byte $A0 ; |X X     |
    .byte $40 ; | X      |
    .byte $00 ; |        |
    .byte $00 ; |        |




       ALIGN 256

RightGfxTab:

; _I = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
; _J = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
; _R = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $A0 >> 4 ; |X X     |
    .byte $C0 >> 4 ; |XX      |
; _K = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
; _D = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |
; _B = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $A0 >> 4 ; |X X     |
; _P = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $C0 >> 4 ; |XX      |  shared
; _L = *-GfxStart
    .byte $80 >> 4 ; |X       |  shared
    .byte $80 >> 4 ; |X       |  shared
    .byte $80 >> 4 ; |X       |
    .byte $80 >> 4 ; |X       |
; _Z = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $20 >> 4 ; |  X     |
    .byte $40 >> 4 ; | X      |
    .byte $80 >> 4 ; |X       |
; _F = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $80 >> 4 ; |X       |
    .byte $C0 >> 4 ; |XX      |
    .byte $80 >> 4 ; |X       |
    .byte $80 >> 4 ; |X       |
; _G = *-GfxStart
    .byte $60 >> 4 ; | XX     |
    .byte $80 >> 4 ; |X       |
    .byte $A0 >> 4 ; |X X     |
    .byte $A0 >> 4 ; |X X     |
; _S = *-GfxStart
    .byte $60 >> 4 ; | XX     |  shared
    .byte $80 >> 4 ; |X       |
    .byte $40 >> 4 ; | X      |
    .byte $20 >> 4 ; |  X     |
; _Q = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $A0 >> 4 ; |X X     |
    .byte $A0 >> 4 ; |X X     |
    .byte $C0 >> 4 ; |XX      |
; _L_SQR_BRACKET = *-GfxStart
    .byte $60 >> 4 ; | XX     |  shared
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $60 >> 4 ; | XX     |

; _2 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |
    .byte $20 >> 4 ; |  X     |
; _5 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $80 >> 4 ; |X       |  shared
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $20 >> 4 ; |  X     |
; _3 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $20 >> 4 ; |  X     |
    .byte $60 >> 4 ; | XX     |
    .byte $20 >> 4 ; |  X     |
; _6 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $80 >> 4 ; |X       |
; _8 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
; _9 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
; _7 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $20 >> 4 ; |  X     |  shared
    .byte $20 >> 4 ; |  X     |
    .byte $40 >> 4 ; | X      |
; _AMPERSAND = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $A0 >> 4 ; |X X     |
    .byte $40 >> 4 ; | X      |
    .byte $A0 >> 4 ; |X X     |
; _DOLLAR = *-GfxStart
    .byte $60 >> 4 ; | XX     |  shared
    .byte $C0 >> 4 ; |XX      |
    .byte $40 >> 4 ; | X      |
    .byte $60 >> 4 ; | XX     |
; _N = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
; _U = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
; _W = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
; _H = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $E0 >> 4 ; |XXX     |  shared
; _V = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
; _X = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $40 >> 4 ; | X      |  shared
; _Y = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $40 >> 4 ; | X      |
; _APOSTROPHE = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $40 >> 4 ; | X      |  shared
; _SPACE = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
; _PERIOD = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
; _O = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $A0 >> 4 ; |X X     |
    .byte $A0 >> 4 ; |X X     |
    .byte $A0 >> 4 ; |X X     |
; _A = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
; _M = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
; _0 = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
; _4 = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $E0 >> 4 ; |XXX     |  shared
; _F_SLASH = *-GfxStart
    .byte $20 >> 4 ; |  X     |  shared
    .byte $20 >> 4 ; |  X     |  shared
    .byte $40 >> 4 ; | X      |
; _B_SLASH = *-GfxStart
    .byte $80 >> 4 ; |X       |  shared
    .byte $80 >> 4 ; |X       |  shared
    .byte $40 >> 4 ; | X      |
    .byte $20 >> 4 ; |  X     |
; _LESS_THAN = *-GfxStart
    .byte $20 >> 4 ; |  X     |
    .byte $40 >> 4 ; | X      |
; _GREATER_THAN = *-GfxStart
    .byte $80 >> 4 ; |X       |  shared
    .byte $40 >> 4 ; | X      |  shared
    .byte $20 >> 4 ; |  X     |  shared
    .byte $40 >> 4 ; | X      |
    .byte $80 >> 4 ; |X       |

; _NUMBER = *-GfxStart
    .byte $A0 >> 4 ; |X X     |
    .byte $E0 >> 4 ; |XXX     |
    .byte $A0 >> 4 ; |X X     |
    .byte $E0 >> 4 ; |XXX     |
; _PERCENT = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $20 >> 4 ; |  X     |
    .byte $40 >> 4 ; | X      |
    .byte $80 >> 4 ; |X       |
; _QUOTE = *-GfxStart
    .byte $A0 >> 4 ; |X X     |  shared
    .byte $A0 >> 4 ; |X X     |
; _COMMA = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
    .byte $20 >> 4 ; |  X     |
; _L_BRACKET = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $80 >> 4 ; |X       |
    .byte $80 >> 4 ; |X       |
    .byte $80 >> 4 ; |X       |
    .byte $40 >> 4 ; | X      |
; _R_BRACKET = *-GfxStart
    .byte $80 >> 4 ; |X       |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $80 >> 4 ; |X       |
; _ASTERIX = *-GfxStart
    .byte $00 >> 4 ; |        |
    .byte $A0 >> 4 ; |X X     |
; _CARET = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $A0 >> 4 ; |X X     |  shared
; _UNDERSCORE = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
; _HYPHEN = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $00 >> 4 ; |        |  shared
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $00 >> 4 ; |        |
; _EQUAL =  *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $E0 >> 4 ; |XXX     |
    .byte $00 >> 4 ; |        |
    .byte $E0 >> 4 ; |XXX     |
    .byte $00 >> 4 ; |        |

; _R_SQR_BRACKET = *-GfxStart
    .byte $C0 >> 4 ; |XX      |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
; _QUESTION = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $20 >> 4 ; |  X     |
    .byte $40 >> 4 ; | X      |
    .byte $00 >> 4 ; |        |
; _AT = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $A0 >> 4 ; |X X     |
    .byte $A0 >> 4 ; |X X     |
    .byte $80 >> 4 ; |X       |
; _C = *-GfxStart
    .byte $60 >> 4 ; | XX     |  shared
    .byte $80 >> 4 ; |X       |
    .byte $80 >> 4 ; |X       |
    .byte $80 >> 4 ; |X       |
; _E = *-GfxStart
    .byte $60 >> 4 ; | XX     |  shared
    .byte $80 >> 4 ; |X       |
    .byte $C0 >> 4 ; |XX      |
    .byte $80 >> 4 ; |X       |
; _L_CURLY_BRACKET = *-GfxStart
    .byte $60 >> 4 ; | XX     |  shared
    .byte $40 >> 4 ; | X      |
; _R_CURLY_BRACKET = *-GfxStart
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $40 >> 4 ; | X      |  shared
    .byte $60 >> 4 ; | XX     |  shared
; _1 = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $C0 >> 4 ; |XX      |  shared
    .byte $40 >> 4 ; | X      |
    .byte $40 >> 4 ; | X      |
; _T = *-GfxStart
    .byte $E0 >> 4 ; |XXX     |  shared
; _VERT_BAR = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $40 >> 4 ; | X      |  shared
; _EXCLAMATION = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $40 >> 4 ; | X      |  shared
    .byte $40 >> 4 ; | X      |  shared
; _PLUS = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $40 >> 4 ; | X      |  shared
    .byte $E0 >> 4 ; |XXX     |
    .byte $40 >> 4 ; | X      |
; _TILDE = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $20 >> 4 ; |  X     |
    .byte $E0 >> 4 ; |XXX     |
    .byte $80 >> 4 ; |X       |
; _COLON = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $40 >> 4 ; | X      |
; _SEMICOLON = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $40 >> 4 ; | X      |  shared
    .byte $00 >> 4 ; |        |  shared
    .byte $40 >> 4 ; | X      |
; _ACCENT = *-GfxStart
    .byte $80 >> 4 ; |X       |  shared
    .byte $40 >> 4 ; | X      |
    .byte $00 >> 4 ; |        |
    .byte $00 >> 4 ; |        |
    .byte $00 >> 4 ; |        |

; _PLUS_MINUS = *-GfxStart
    .byte $40 >> 4 ; | X      |
    .byte $E0 >> 4 ; |XXX     |
    .byte $40 >> 4 ; | X      |
; _SQUARE = *-GfxStart
    .byte $00 >> 4 ; |        |  shared
    .byte $E0 >> 4 ; |XXX     |  shared
    .byte $E0 >> 4 ; |XXX     |
    .byte $E0 >> 4 ; |XXX     |
    .byte $00 >> 4 ; |        |

; _DIVISION = *-GfxStart
    .byte $40 >> 4 ; | X      |
    .byte $00 >> 4 ; |        |
    .byte $E0 >> 4 ; |XXX     |
    .byte $00 >> 4 ; |        |
; _DEGREE = *-GfxStart
    .byte $40 >> 4 ; | X      |  shared
    .byte $A0 >> 4 ; |X X     |
    .byte $40 >> 4 ; | X      |
    .byte $00 >> 4 ; |        |
    .byte $00 >> 4 ; |        |




P0_Tab:
    .byte P0_POS_KERNEL_A
    .byte P0_POS_KERNEL_B

P1_Tab:
    .byte P1_POS_KERNEL_A
    .byte P1_POS_KERNEL_B

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Positioning: SUBROUTINE
    sec
    sta    WSYNC
;---------------------------------------
.divide15:
    sbc    #15
    bcs    .divide15
    eor    #7
    asl
    asl
    asl
    asl
    sta.wx HMP0,X
    sta    RESP0,X
    rts


               ORG FIXED_BANK + $7F0
               RORG $7ff0
   .byte #0,#0,#0,#0
   
               SEG Vectors
               ORG FIXED_BANK + $7FC
               RORG $7ffC

    .word START
    .word START
