    processor 6502
    include "vcs.h"


;===============================================================================
; A S S E M B L E R - S W I T C H E S
;===============================================================================

VERSION     = $0000
BASE_ADR    = $1000

NTSC        = 1
PAL60       = 0
PAL50       = 0

ILLEGAL     = 1
DEBUG       = 0

  IF NTSC
NTSC_TIM    = 1
NTSC_COL    = 1
  ENDIF

  IF PAL60
NTSC_TIM    = 1
NTSC_COL    = 0
  ENDIF

  IF PAL50
NTSC_TIM    = 0
NTSC_COL    = 0
  ENDIF

HOTSPOT     = $fff4

COLOR       = 3         ; color scheme



;///////////////////////////////////////////////////////////////////////////////
;@BOO
; This enables/disables the check for $D8 without changing wait routine length

PLUSACTIVE = $D8      ; <-- $D8 for running on PlusCart, anything else for Stella

SPINNER = 1             ; 0 = spining PlusCart logo, 1 = flashing UnoCart SD logo

    ; MODIFY "MAGNIFY" TO CHANGE SIZE OF PLUSLOGO!!
    ; Adjusts the vertical height of the logo (# lines per pixel)
    ; Screen timing will AUTOMATICALLY ADJUST

    IF NTSC_TIM
MAGNIFY = 6
    ELSE
MAGNIFY = 7
    ENDIF


    ; DO NOT MODIFY FOLLOWING
    ; THIS IS CALCULATING THE AUTO-ADUST TO KEEP SCREEN CORRECT SIZE...

LINES_USED = (MAGNIFY +1)* 8


    IF NTSC_TIM
SCANLINES = 262
TOPSHIFT = 22
    ELSE
SCANLINES = 312
TOPSHIFT = 32
    ENDIF

VSYNC_LINES = 4
VBLANK_LINES = 37
OVERSCAN_LINES = 30

BOTTOMPAD = SCANLINES - VSYNC_LINES - VBLANK_LINES - TOPSHIFT - LINES_USED - OVERSCAN_LINES



;===============================================================================
; FONT SWITCHING....

FONT_NUM SET 0
    MAC DEFONT ;{1} = name
FONT_{1} = FONT_NUM
FONT_NUM SET FONT_NUM + 1
    ENDM

    DEFONT SMALLCAPS
    DEFONT Trichotomic_12
    DEFONT CaptainMorganSpice
    DEFONT GlacierBelle

    MAC USEFONT ;{1} = name
FONT = FONT_{1}
    ENDM


    ;USEFONT Trichotomic_12  ; << change as needed

;... or...
FONT = 3

;===============================================================================
; C O N S T A N T S
;===============================================================================

LINE_SPACING = 0

    IF LINE_SPACING < 0 || LINE_SPACING > 2
        ECHO "BAD LINE SPACING VALUE", [LINE_SPACING]d, "(MUST BE 0,1 OR 2)"
        ERR
    ENDIF


NUM_MENU_ENTRIES   = 14         ; maximum supported

  IF NTSC_COL

BACK_COL    = $92
TXT_COL     = $08      ; SPINNER colour complimentary color to create better white

HEADER_COL  = $90
HTXT_COL    = $0A       ; complimentary color to create better white

   IF COLOR = 0         ; orange selection
STXT_COL    = $ae       ; complimentary color to create better white
LINE_COL    = $3a
SEL_COL     = $34
   ENDIF
   IF COLOR = 1         ; grey selection
STXT_COL    = $0e       ; complimentary color to create better white
LINE_COL    = $08
SEL_COL     = $04
   ENDIF
   IF COLOR = 2         ; blue selection
STXT_COL    = $2e       ; complimentary color to create better white
LINE_COL    = $98
SEL_COL     = $92
   ENDIF
   IF COLOR = 3         ; cyan selection
STXT_COL    = $3e       ; complimentary color to create better white
LINE_COL    = $a6
SEL_COL     = $24
   ENDIF

  ELSE
  ;/PAL...

BACK_COL    = $D2
TXT_COL     = $0A       ; complimentary color to create better white

HEADER_COL  = $B0
HTXT_COL    = $0A       ; complimentary color to create better white

   IF COLOR = 0         ; orange selection
STXT_COL    = $de       ; complimentary color to create better white
LINE_COL    = $4a
SEL_COL     = $44
   ENDIF
   IF COLOR = 1         ; grey selection
STXT_COL    = $0e       ; complimentary color to create better white
LINE_COL    = $0a
SEL_COL     = $06
   ENDIF
   IF COLOR = 2         ; blue selection
STXT_COL    = $2e       ; complimentary color to create better white
LINE_COL    = $b8
SEL_COL     = $b2
   ENDIF
   IF COLOR = 3         ; cyan selection
STXT_COL    = $4e       ; complimentary color to create better white
LINE_COL    = $96
SEL_COL     = $44
   ENDIF

  ENDIF


;===============================================================================
; Z P - V A R I A B L E S
;===============================================================================


    SEG.U   variables
    ORG     $80

    ; THESE MUST BE AT START TO PRESERVE THEM

CommandByte         ds 1   ; $0 to $f item selected, $10 next page, $20 prev page, $30 ready for reboot.
CurItem		        ds 1
lineCounter         ds 1

RESERVED_ZP = * - $80

    ; THESE CAN BE ANY ORDER
    ; THEY ARE ZAPPED BY THE WAIT ROUTINE

frameCnt            ds 1
LineBackColor       ds NUM_MENU_ENTRIES+1
StickDelayCount	    ds 1


;===============================================================================
; M A C R O S
;===============================================================================

DEBUG_BYTES SET 0

  MAC DEBUG_BRK
    IF DEBUG
DEBUG_BYTES SET DEBUG_BYTES + 1
      brk                         ;
    ENDIF
  ENDM

  MAC BIT_B
    .byte   $24
  ENDM

  MAC BIT_W
    .byte   $2c
  ENDM

  MAC SLEEP
    IF {1} = 1
      ECHO "ERROR: SLEEP 1 not allowed !"
      END
    ENDIF
    IF {1} & 1
      nop $00
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

  MAC _KERNEL_A                                     ; @14

PatchA1_{1} = . + 1
                    ldx #{3}                        ; 2
PatchA2_{1} = . + 1
                    lda #{4}                        ; 2
                    sta GRP1                        ; 3      @21     {4}
PatchA0_{1} = . + 1
                    lda #{2}                        ; 2
                    sta GRP0                        ; 3      @26     {2}
PatchA5_{1} = . + 1
                    ldy #{7}                        ; 2
                    stx.w GRP0                      ; 4      @32     {3}
                    nop                             ; 2
PatchA6_{1} = . + 1
    ldx     #{8}                ;2
PatchA3_{1} = . + 1
    lda     #{5}                ;2
    sta     GRP1                ;3      @41     {5}
PatchA4_{1} = . + 1
    lda     #{6}                ;2
    sta.w   GRP1                ;4      @47     {6}
    sta     RESP0               ;3      @50
    sty     GRP0                ;3      @53     {7}
    sta     RESP0               ;3      @56
    stx.w   GRP0                ;4      @60     {8}
PatchA7_{1} = . + 1
    lda     #{9}                ;2
    sta.w   GRP0                ;4      @66     {9}
; preparation for next line
    ldx     #$80                ;2
    stx     HMP1                ;3      @71
    nop
    sta     RESP0               ;3      @00
  ENDM

    MAC KERNEL_A_BOTH
        ;lda LineBackColor+{1}
        ;sta COLUBK
        SLEEP 8+6
        _KERNEL_A {1}_{2}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}
    ENDM


  MAC KERNEL_A
; displays: 00--00--11--11--11----00--00--00--00
    SLEEP   13
    _KERNEL_A {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}
  ENDM


  MAC _KERNEL_B                 ;       @16
; displays: --00--00--11--11--1100--00--00--
PatchB4_{1} = . + 1
    ldy     #{6}                ;2
PatchB2_{1} = . + 1
    lda     #{4}                ;2
    sta     GRP1                ;3      @23     {4}
PatchB3_{1} = . + 1
    ldx     #{5}                ;2
PatchB0_{1} = . + 1
    lda     #{2}                ;2
    sta     GRP0                ;3      @30     {2}
PatchB1_{1} = . + 1
    lda     #{3}                ;2
    sta     GRP0                ;3      @35     {3}
PatchB5_{1} = . + 1
    lda     #{7}                ;2
    sta.w   GRP0                ;4      @41     {7}
    stx     GRP1                ;3      @44     {5}
    sta     RESP0               ;3      @47
    sty     GRP1                ;3      @50     {6}
    sta     RESP0               ;3      @53
PatchB6_{1} = . + 1
    lda     #{8}                ;2
    sta.w   GRP0                ;4      @59     {8}
PatchB7_{1} = . + 1
    lda     #{9}                ;2
    sta     GRP0                ;3      @64     {9}
; preparation for next line
    ldx     #$00                ;2              also clear value for next kernel
    stx     HMP1                ;3      @69
    sta.w   HMOVE               ;4      @73
    sta.w   RESP0               ;3      @00
  ENDM

 MAC KERNEL_B_BOTH

    sta     HMOVE               ;3      @03
    ;lda     LineBackColor+{1}; #{3}                ;2
    ;sta     COLUBK              ;3      @08
;   SLEEP 7+6
    sta      RESP0              ;3      @06
    SLEEP 10
    _KERNEL_B {1}_{2}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}
  ENDM


    MAC KERNEL_B
        ; displays: --00--00--11--11--1100--00--00--
        sta HMOVE               ;3      @03
;       SLEEP 13
    sta RESP0               ;3      @06
    SLEEP 10
        _KERNEL_B {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}
    ENDM
    ;The following macros are not required by the PlusCart 6507 code, they just show how the macros above have to be used

    MAC KERNEL_AXC_BOTH ; {index}, {line}, {bk-color}, {txt-color}, {32 x chars...}
        KERNEL_A_BOTH {1}, {2}, {3}, {4}, _{5}_L{2}|_{6}_R{2}, _{9}_L{2}|_{10}_R{2}, _{13}_L{2}|_{14}_R{2}, _{17}_L{2}|_{18}_R{2}, _{21}_L{2}|_{22}_R{2}, <((_{27}_L{2}|_{28}_R{2}) << 1), <((_{31}_L{2}|_{32}_R{2}) << 1), <((_{35}_L{2}|_{36}_R{2}) << 1)
    ENDM


    MAC KERNEL_AXC ; {index}, {line}, {ignored}, {ignored}, {32 x chars...}
        KERNEL_A {1}_{2},                _{5}_L{2}|_{6}_R{2}, _{9}_L{2}|_{10}_R{2}, _{13}_L{2}|_{14}_R{2}, _{17}_L{2}|_{18}_R{2}, _{21}_L{2}|_{22}_R{2}, <((_{27}_L{2}|_{28}_R{2}) << 1), <((_{31}_L{2}|_{32}_R{2}) << 1), <((_{35}_L{2}|_{36}_R{2}) << 1)
    ENDM


    MAC KERNEL_BXC_BOTH ; {index}, {line}, {bk-color}, {txt-color}, {32 x chars...}
        KERNEL_B_BOTH {1}, {2}, {3}, {4}, _{7}_L{2}|_{8}_R{2}, _{11}_L{2}|_{12}_R{2}, _{15}_L{2}|_{16}_R{2}, _{19}_L{2}|_{20}_R{2}, _{23}_L{2}|_{24}_R{2}, _{25}_L{2}|_{26}_R{2}, _{29}_L{2}|_{30}_R{2}, _{33}_L{2}|_{34}_R{2}
    ENDM


    MAC KERNEL_BXC ; {index}, {line}, {ignored}, {ignored}, {32 x chars...}
        KERNEL_B {1}_{2},                _{7}_L{2}|_{8}_R{2}, _{11}_L{2}|_{12}_R{2}, _{15}_L{2}|_{16}_R{2}, _{19}_L{2}|_{20}_R{2}, _{23}_L{2}|_{24}_R{2}, _{25}_L{2}|_{26}_R{2}, _{29}_L{2}|_{30}_R{2}, _{33}_L{2}|_{34}_R{2}
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC KERNEL_EVEN ; {index}, {bk-color}, {txt-color}, {32 x chars...}

        KERNEL_AXC_BOTH {1},  0, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  1,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  2,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  3,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  4,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  5,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  6,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  7,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  8,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  9,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1}, 10,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1}, 11,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}

        END_KERNEL

    ENDM

;---------------------------------------------------------------------------------------------------

    MAC KERNEL_ODD ; {index}, {bk-color}, {txt-color}, {32 x chars...}

        KERNEL_BXC_BOTH {1},  0, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  1,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  2,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  3,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  4,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  5,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  6,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  7,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1},  8,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1},  9,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_BXC      {1}, 10,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
        KERNEL_AXC      {1}, 11,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}

        END_KERNEL

    ENDM

;---------------------------------------------------------------------------------------------------

    MAC TEXT_COLOUR ; {colour}
        lda #{1}
        sta COLUP0
        sta COLUP1

        lda #1
        sta lineCounter
        sta WSYNC


    ENDM

;---------------------------------------------------------------------------------------------------

    MAC END_KERNEL
        ldx #0
        stx GRP0
        stx GRP1
    ENDM

    MAC NORMAL_BOTTOM ; {line}

        inc lineCounter
        lda LineBackColor+{1}

    IF FONT != 0
        REPEAT LINE_SPACING
            sta WSYNC
        REPEND
    ENDIF

    IF FONT=0
        REPEAT LINE_SPACING
            sta WSYNC
        REPEND

        IF LINE_SPACING > 0
            sta WSYNC
        ENDIF
    ENDIF    


        sta COLUBK
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC NORMAL_TOP ; {line, #text colour}

        lda #{2}
        sta COLUP0
        sta COLUP1

    IF FONT != 0
        REPEAT LINE_SPACING+1
            sta WSYNC
        REPEND
    ENDIF

    IF FONT=0 && LINE_SPACING = 0
        sta WSYNC
    ENDIF    

    IF FONT=0 && LINE_SPACING != 0
        REPEAT LINE_SPACING
            sta WSYNC
        REPEND
    ENDIF    

    ENDM

;---------------------------------------------------------------------------------------------------

;    MAC NORMAL_BOTTOM
;    ENDM

;---------------------------------------------------------------------------------------------------

    MAC HEADER_BOTTOM

        lda #BACK_COL
        sta WSYNC
        sta COLUBK

        sta WSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC

        lda LineBackColor+1
        sta COLUBK

    REPEAT LINE_SPACING
            sta WSYNC
    REPEND

        lda #%00011010
        sta COLUP0
        sta COLUP1

        sta WSYNC

    ENDM

;---------------------------------------------------------------------------------------------------

    MAC START_BANK ; {bank}

    ORG     BASE_ADR + {1} * $1000
    RORG    BASE_ADR + {1} * $2000

ExitKernel = (. & $1fff)

        cld
        sta HOTSPOT
        jmp ContDrawScreen

SwitchBank = (. & $1fff)

        sta HOTSPOT + 1 + {1},x         ; X is usually 0, except when starting odd kernel
  ENDM

;---------------------------------------------------------------------------------------------------

    MAC END_BANK ; {bank}

        jmp SwitchBank

    ORG     BASE_ADR + $fe6 + {1} * $1000
    RORG    BASE_ADR + $fe6 + {1} * $2000
 
    ; Comms area
    ; Initialisation for stand-alone/testing...
    
    ;ds 8 ; or...

    .byte 0                                         ; don't reboot
    .byte 0                                         ; current page
    .byte 2                                         ; max pages
    .byte 5                                         ; items on act page
    .byte NUM_MENU_ENTRIES
    .byte 2                                         ; page type (keyboard)

    .byte 0                                         ; unused
    .byte 0                                         ; unused

Start = (. & $1fff)

                    sta HOTSPOT
                    jmp DoStart

                    ;nop

    ds 8, 0                                         ; bank switch hotspots

    .word   FirstStart
    .word   FirstStart

  ENDM

;---------------------------------------------------------------------------------------------------

;WriteByte (command area)
SendCartCommand   equ $1fe6  ; Command byte to send to Cart firmware
                             ; ($0 -> $f): first nibble item is selected on act page. 
PrevPageCommand   equ $10    ; ($10)     : previous page request (act page--) 
NextPageCommand   equ $20    ; ($20)     : next page request (act page++) 
RebootCommand     equ $30    ; ($30)     : tell cart we are ready for reboot
FirstBootCommand  equ $ff    ; ($ff)     : tell cart we are ready at bootup

;ReadBytes (info/status area)
StatusByteReboot  equ $1fe7  ; tells us to reboot after selecting an item (if > 0 )
CurPage           equ $1fe8  ; current page
MaxPage           equ $1fe9  ; Max pages
ItemsOnActPage    equ $1fea  ; items on act page
PageType          equ $1feb  ; type of current page ($0 = Directory, $1 = Menu, $2 = Keyboard)
FreeByte2         equ $1fec  ; 
FreeByte3         equ $1fed  ; 

PAGE_TYPE_DIRECTORY = 0
PAGE_TYPE_MENU      = 1
PAGE_TYPE_KEYBOARD  = 2

;===============================================================================
; R O M - C O D E
;===============================================================================

    SEG Bank

_FREE SET 0

;-------------------------------------------------------------------------------
; BANK 0
;-------------------------------------------------------------------------------
; First bank is for overall logic
;StartByte

    START_BANK 0

FirstStart

                    cld                             ; Clear BCD math bit.  << WAIT ROUTINE RELIES ON THIS HERE
                    lda #0
                    tax
                    dex
                    txs
.clearLoop          tsx
                    pha
                    bne .clearLoop

  	                lda $1FF4                       ; enable comm Area


                    jsr DetectSystemType

                    jsr PrepareWaitCartRoutine
                    ldx #FirstBootCommand
                    jsr START_WAITCART
                    jsr WaitCart


_init_blocker       lda SWCHA
                    bpl _init_blocker               ; why...?


MainLoop
                    jsr GameInit
                    jsr MenuLoop

                    jsr PrepareWaitCartRoutine


                    ldx CommandByte
                    jsr START_WAITCART  ;@BOO
                    jsr WaitCart
                                        
                    lda CommandByte 
                    cmp #PrevPageCommand - 1
                    bcs MainLoop

                    lda #PAGE_TYPE_KEYBOARD
                    cmp PageType
                    beq MainLoop

                    lda #0
                    sta CurItem
                    jmp MainLoop



;///////////////////////////////////////////////////////////////////////////////
;@BOO
; Calls the ZP spinner/wait routine, which returns when PlusCart is active
; (through detection of CLD @ start of this ROM)

WaitCart            SUBROUTINE

                    lda StatusByteReboot
  	                beq .dontReboot


                    ldx #$3F
                    lda #0
.clearTIA           sta 0,x	                        ; Clear TIA ($00-$3f) inclusive
                    dex
                    bpl .clearTIA

    ; copy exit routine to ram

                    ldx #ZP_REQUIRED_EXIT-1
.add                lda ExitCartRoutine,x
                    sta $80+RESERVED_ZP,x
                    dex
                    bpl .add

                    jmp EXIT_WAITCART


.dontReboot         rts
    

;///////////////////////////////////////////////////////////////////////////////


DoStart             SUBROUTINE
MenuLoop
                    jsr SetActiveItem
                    jsr VerticalBlank
                    jsr GameCalc

ReadControls    	lda StickDelayCount
                    beq _x0
                    dec StickDelayCount
                    jmp _x4
_x0
	; check down
                    lda #$20
                    and SWCHA
                    beq _x0X

    ; check select
                    lda #$02
                    and SWCHB
                    bne _x1

_x0X	; down/select pressed

                    ldx CurItem
                    inx
                    cpx ItemsOnActPage              ; vergleiche mit ItemCount on this page ?
                    beq _pageDown

                    inc CurItem
                    bne .debounce ;unconditional
	
	
_x1	; check up
                    lda #$10
                    and SWCHA
                    bne _x2
    ; up pressed
                    ldx CurItem
                    beq _pageUp

                    dec CurItem

.debounce           lda #10
                    sta StickDelayCount
                    bne _x4


_x2
    ; check left          left and right just send page up/down to Cart !

                    lda #$40
                    and SWCHA
                    bne _x3
    ; left pressed

                    sta CurItem

                    ldx CurPage
                    beq _x3
                    lda #PrevPageCommand
                    bne ExitMenu                    ; unconditional


_pageUp             ldx CurPage
                    beq _x3

                    ldx lineCounter ;ItemsOnActPage              ; set CurItem to last entry
                    dex
                    stx CurItem

_pageUp2            ldx CurPage
                    beq _x3

_pp2                lda #PrevPageCommand
                    bne ExitMenu

_x3
    ; check right
                    lda #$80
                    and SWCHA
                    bne _x4
	; right pressed

_pageDown

     ; CurPage++ request


                    ldx ItemsOnActPage
                    dex
                    stx CurItem

                    ldx CurPage
                    cpx MaxPage
                    beq _x4

                    lda #0                          ; set CurItem to first entry
                    sta CurItem
                    lda #NextPageCommand
                    jmp ExitMenu
_x4

                    jsr DrawScreen
                    jsr OverScan

    ; check fire button
                    bit INPT4
                    bmi NotFire
                    jmp ItemSelected
; check reset
NotFire
                    lda #$01
                    and SWCHB
                    beq ItemSelected
NoSelection
                    jmp MenuLoop

ItemSelected        lda CurItem
ExitMenu            sta CommandByte
	                rts



GameInit
                    lda #%11
                    sta NUSIZ0
                    sta NUSIZ1

                    ;lda #$d0
                    ;sta COLUBK
                    
                    lda #%01110000           ; mask left and right border
                    sta PF0
                    
                    lda #%00110001
                    sta CTRLPF
                    
                    lda #HEADER_COL          ; set HEADER_COL for first textline in RAM
                    sta LineBackColor
                    
                    lda CurItem
                    cmp ItemsOnActPage
                    bcc EndGameInit
                    lda #0
                    sta CurItem
EndGameInit
                    rts


;--------------------------------------------------------------------------------------------------

DetectSystemType
ZP_DetectNTSC_PAL = $80 + RESERVED_ZP

                    ldy #ZP_REQUIRED_FOR_DETECT_ROUTINE-1
.add2                lda DetectNTSC_PAL,y
                    sta ZP_DetectNTSC_PAL,y
                    dey
                    bpl .add2

                    jmp ZP_DetectNTSC_PAL

DetectNTSC_PAL
                    ldx #0
                    ldy #0
detector            dey
                    bne detector
                    dex
                    bne detector
                    rts

ZP_REQUIRED_FOR_DETECT_ROUTINE = * - DetectNTSC_PAL

;--------------------------------------------------------------------------------------------------


; ALIGN 256

PrepareWaitCartRoutine

    ; copy routine to ram

                    ldy #ZP_REQUIRED-1
.add                lda WaitCartRoutine,y
                    sta $80+RESERVED_ZP,y
                    dey
                    bpl .add


; score mode
                    lda #%00110010
                    sta CTRLPF

                    lda #BACK_COL
                    sta COLUBK
                    sta COLUP1
                    
                    lda #TXT_COL
                    sta COLUP0
                    
                    lda #0
                    sta PF0
                    sta PF2
                    rts

;---------------------------------------------------------------------------------------------------

; FOLLOWING LIVES AT ZP *AFTER* RESERVED ZP VARS

ExitCartRoutine     SUBROUTINE

    ; + ADD LOCAL ZP VARS HERE IF REQUIRED

EXIT_WAITCART = * - ExitCartRoutine + $80 + RESERVED_ZP

    ; NOTE: Because we are called from a single-depth subroutine, the SP will have the
    ; return addres and so, currently, it is already $FD. No need to initialise it to such.
    ; However, if SP = $FF is required, this must be added here.


    ; tell cart we are ready for switch

                    lda #RebootCommand
                    sta SendCartCommand

                    sta WSYNC
                    sta WSYNC                       ; probably superfluous

                    jmp ($fffc)

ZP_REQUIRED_EXIT = * - ExitCartRoutine


;---------------------------------------------------------------------------------------------------

; THE FOLLOWING LIVES AT ZERO PAGE *AFTER* THE RESERVED ZP VARS


WaitCartRoutine     SUBROUTINE
ADJUST = -WaitCartRoutine+$80+RESERVED_ZP

    ; Variables...

logoBase            .byte 240                       ; (can change) start point of cycle
SPINNER_ZP_SIZE = * - logoBase

    ; THE ACTUAL SPINNER GRAPHICS

PlusLogoAnimation

    IF SPINNER = 0

    .byte 0, %00011000,%00000100,%00010010,%10111010,%10010000,%01000000,%00110000
    .byte 0, %00111000,%01000100,%00010000,%00111000,%00010000,%01000100,%00111000
    .byte 0, %00110000,%01000000,%10010000,%10111010,%00010010,%00000100,%00011000
    .byte 0, %00000000,%01000100,%10010010,%10111010,%10010010,%01000100,%00000000 ; static 

    ENDIF

    IF SPINNER = 1

    .byte 0, %00000000,%00000000,%00000000,%00011000,%00000000,%00000000,%00000000
    .byte 0, %00000000,%00000000,%00011000,%00111100,%00011000,%00000000,%00000000
    .byte 0, %00000000,%01001100,%00101010,%01101010,%01001010,%00101100,%00000000
    .byte 0, %11001100,%00101010,%00101001,%01001001,%10001001,%10001010,%01101100 ; static

    ENDIF

 
    ; START OF ZERO PAGE DISPLAY ROUTINE
    ; WE HAVE 128 - 4 (two return addresses on stack) - 1 (zp command byte)
    ; = 123 bytes available to use

START_WAITCART = * + ADJUST


                  	stx SendCartCommand             ; sent cmd to cart

frame_loop

    ; VERTICAL SYNC

                    lda #%1110                      ; each '1' bits generate a VSYNC ON line (bits 1..3)
.VSLP1              sta WSYNC                       ; 1st '0' bit resets Vsync, 2nd '0' bit exit loop
                    sta VSYNC
                    lsr
                    bne .VSLP1                      ; branch until VYSNC has been reset


    ; Now we need 37 lines of VBLANK...	

                  	ldx #VBLANK_LINES ;37
                    jsr waitLine+ADJUST

    ; Re-enable output (disable VBLANK)	

                  	stx VBLANK


    ; TOP OF SCREEN BEFORE PLUSLOGO

	                ldx #TOPSHIFT
                    jsr waitLine+ADJUST

    ; animate - copy the shape data for the frame to the generic logo buffer


                    inc logoBase+ADJUST
                    lda logoBase+ADJUST

    ; calculate frame index so we have either 3 (normal standard frame)
    ; or spinning 0,1,2
                    
                    asl

                    ldx #3<<3
                    cmp #3*8
                    bcs .xok

;                    asl
                    and #%11000
                    tax
.xok

    ; now write the frame offset to the self-mod load

                    stx SML+ADJUST+1            ; write SELF-MOD address for load

    
    ; DRAW THE SPINNER


                    ldx #PlusLogoAnimation+ADJUST+7     ; # lines in shape definition (only 6 used)

    ; X reg is $80+line#  -- $80 being the start of shape data

drawLogo            ldy #MAGNIFY

SML                 lda 0,x                     ; get shape data (self-modd'd)

drawLogoScan    	sta WSYNC
                    sta PF1

                    dey
                    bpl drawLogoScan

                    dex
                    cpx #$80+RESERVED_ZP
                    bne drawLogo

    
    ; WAIT TO BOTTOM OF SCREEN
    ; @ --> RESIZE_HERE

                    ldx #BOTTOMPAD


;    IF NTSC_TIM
;                    ldx #121
;    ELSE
;                    ldx #153
;    ENDIF
                    jsr waitLine+ADJUST

    ; Enable VBLANK again

                    lda #2
                    sta VBLANK

    ; 30 lines of overscan to complete the frame
                  	ldx #OVERSCAN_LINES ;30
                    jsr waitLine+ADJUST

    ; check if firmware back
                    lda ExitKernel
                    cmp #PLUSACTIVE ; d8 8d for cart
                    bne frame_loop
                    rts
                    

waitLine            sta WSYNC
                    dex
                    bne waitLine
                    rts


ZP_REQUIRED = * - WaitCartRoutine

STACK_USED = 2
WAITLINE_CALL = 2

ZP_AVAILABLE = 128 - RESERVED_ZP - STACK_USED - WAITLINE_CALL
    ECHO "Zero Page used =",[ZP_REQUIRED]d,"of",[ZP_AVAILABLE]d,"bytes"
    IF ZP_REQUIRED > ZP_AVAILABLE
        ECHO "ERROR: PROBABLE OVERFLOW IN WAIT ROUTINE SIZE"
    ENDIF

;---------------------------------------------------------------------------------------------------

 
VerticalBlank       SUBROUTINE
                    
                    lda #%00001110
.loopVSync:         sta WSYNC
                    sta VSYNC
                    lsr
                    bne .loopVSync

                    inc frameCnt

  IF NTSC_TIM
                    lda #36
  ELSE
                    lda #68
  ENDIF
                    sta TIM64T
                    rts

;---------------------------------------------------------------------------------------------------

GameCalc            SUBROUTINE

                    ldx #0
                    lda frameCnt
                    lsr
                    lda #0
                    bcc .evenFrame0
                    lda #3
.evenFrame0

                    jsr SetXPos
                    inx
                    lda #48
                    jsr SetXPos

                    ldx #4
                    lda #82
                    jsr SetXPos
                    ;lda #0 ;%11000000
                    ;sta HMBL

                    sta WSYNC
                    sta HMOVE
                    sta WSYNC
                    sta HMCLR

;                    lda #$b0
                    lda #$C0
                    sta HMP0
                    lda #$80
                    sta HMP1

                    ;sta WSYNC
    ; ball

;    lda     frameCnt
;    and     #$0f
;    bne     .skipJoy
;    ldx     selected
;    lda     SWCHA
;    asl
;    asl
;    bmi     .skipUp
;    dex
;    bpl     .setSelected
;    inx
;    bpl     .setSelected
;
;.skipUp
;    asl
;    bmi     .skipJoy
;    cpx     #NUM_LINES-1
;    bcs     .skipJoy
;    inx
;.setSelected
;    stx     selected
;.skipJoy
                    rts

;---------------------------------------------------------------------------------------------------

OverScan            SUBROUTINE

  IF NTSC_TIM
                    lda #26
  ELSE
                    lda #53
  ENDIF
                    sta TIM64T

.waitTim            lda INTIM
                    bne .waitTim
                    rts

;---------------------------------------------------------------------------------------------------

;    ALIGN 256

SetXPos             SUBROUTINE

                    sec
                    sta WSYNC
WaitObject          sbc #$0f                        ; 2
                    bcs WaitObject                  ; 2³

  CHECKPAGE WaitObject

                    eor #$07                        ; 2
                    asl                             ; 2
                    asl                             ; 2
                    asl                             ; 2
                    asl                             ; 2
                    sta HMP0,x                      ; 4
                    sta.w  RESP0,x                  ; 5     @23!
                    
                    rts

;---------------------------------------------------------------------------------------------------


DrawScreen          SUBROUTINE

                    ldx #244

.waitTim            lda INTIM
                    bne .waitTim

                    sta WSYNC
                    sta VBLANK
                    stx TIM64T

                    lda #HEADER_COL
                    sta COLUBK
                    sta WSYNC
                    sta WSYNC
                    sta WSYNC

                    ldx #1-1                        ; even kernels start at bank 1
                    lda frameCnt
                    lsr
                    bcc .evenFrame
                    ldx #4-1                        ; odd kernels start at bank 4

.evenFrame          jmp SwitchBank

ContDrawScreen

;                    stx GRP0
;                    stx GRP1


                    ldx #2
.waitScreen         lda INTIM
                    bne .waitScreen

                    sta WSYNC
                    stx VBLANK

                    ;nop                     ; TODO: removing this causes a rolling screen on real hardware!?

                    rts

;---------------------------------------------------------------------------------------------------


SetActiveItem       SUBROUTINE

                    ldx #NUM_MENU_ENTRIES
                    lda #BACK_COL
.loopColor          sta LineBackColor,x
                    dex
                    bne .loopColor

                    lda #SEL_COL
                    ldx CurItem
                    sta LineBackColor+1,x

                    rts

    ECHO "SIZE=", [*-$1000+3]d
    END_BANK 0


;-------------------------------------------------------------------------------
; BANK 1
;-------------------------------------------------------------------------------

    START_BANK 1

    TEXT_COLOUR HTXT_COL
    
    KERNEL_EVEN 0, HEADER_COL, HTXT_COL, P,l,u,s,C,a,r,t,OpenRound,Plus,CloseRound,1,2,3,4,5,6,7,8,9,A,B,Blank,1, 3,Slash,2,7,Wifi,Wifi, Account,Account
    HEADER_BOTTOM


    KERNEL_EVEN 1, BACK_COL, TXT_COL, N,o,v,e,m,b,e,r,Blank,M,o,v,e,m,y,e,r,Blank,Blank,i,o,n,Blank,s,h,o,u,l,d,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 2

    NORMAL_TOP 2, %00101010
    KERNEL_EVEN 2, BACK_COL, TXT_COL, I,N,T,Blank,I,M,T,Blank,Blank,Blank,A,N,N,O,T,A,T,I,O,N,Blank,e,v,i,n,g,Blank,t,h,e,Blank,Blank
    NORMAL_BOTTOM 3

    NORMAL_TOP 3, %00111010
    KERNEL_EVEN 3, BACK_COL, TXT_COL, A,N,G,R,Y,Blank,N,O,T,Blank,A,X,Y,O,T,A,T,I,O,M,Blank,Blank,o,n,Blank,t,h,e,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 4

    NORMAL_TOP 4, %01001010
    KERNEL_EVEN 4, BACK_COL, TXT_COL,  A,M,G,R,Y,Blank,M,O,T,Blank,r,e,t,u,r,n,i,n,g,Blank,h,i,m,Blank,s,a,f,e,l,y,Blank,Blank
    NORMAL_BOTTOM 5

    END_BANK 1


;-------------------------------------------------------------------------------
; BANK 2
;-------------------------------------------------------------------------------

    START_BANK 2

 ;   NORMAL_BOTTOM

    NORMAL_TOP 5, %01011010
    KERNEL_EVEN 5, BACK_COL, TXT_COL, t,o,Blank,t,h,e,Blank,E,a,r,t,h,Period,Quote,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 6

    NORMAL_TOP 6, %01101010
    KERNEL_EVEN 6, BACK_COL, TXT_COL, Blank,Blank,Minus,Blank,J,o,h,n,Blank,F,Period,Blank,K,e,n,n,e,d,y,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 7

    NORMAL_TOP 7, %01111010
    KERNEL_EVEN 7, BACK_COL, TXT_COL, a,b,c,d,e,f,Blank,Blank,Blank,A,B,C,D,E,F,Blank,Blank,Blank,Blank,0,1,Blank,Blank,Blank,Blank,Exclamation,Quote,Hash,Dollar,Percent,At,Blank
    NORMAL_BOTTOM 8

    NORMAL_TOP 8, %10001010
    KERNEL_EVEN 8, BACK_COL, TXT_COL, g,h,i,j,k,l,m,Blank,Blank,G,H,I,J,K,L,M,Blank,Blank,9,Blank,Blank,2,Blank,Blank,Blank,Ampersand,Apostrophe,OpenRound,CloseRound,Asterisk,OpenCurly,CloseCurly
    NORMAL_BOTTOM 9

    NORMAL_TOP 9, %10011010
    KERNEL_EVEN 9, BACK_COL, TXT_COL,  n,o,p,q,r,s,t,Blank,Blank,N,O,P,Q,R,S,T,Blank,8,Blank,Blank,Blank,Blank,3,Blank,Blank,Plus,Minus,Comma,Period,Slash,BackSlash,Tilde
    NORMAL_BOTTOM 10

    END_BANK 2


;-------------------------------------------------------------------------------
; BANK 3
;-------------------------------------------------------------------------------

    START_BANK 3

    NORMAL_TOP 10, %10101010
    KERNEL_EVEN 10, BACK_COL, TXT_COL, u,v,w,x,y,z,Blank,Blank,Blank,U,V,W,X,Y,Z,Blank,Blank,Blank,7,Blank,Blank,4,Blank,Blank,Blank,Colon,SemiColon,Less,Equal,Greater,Question,Blank

    IF NUM_MENU_ENTRIES > 10
    NORMAL_BOTTOM 11
    NORMAL_TOP 11, %10111010
    KERNEL_EVEN 11, BACK_COL, TXT_COL, Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,6,5,Blank,Blank,Blank,Blank,OpenSquare,CloseSquare,Accent,UnderScore,Grave,Blank,Blank
    ENDIF

    IF NUM_MENU_ENTRIES > 11
    NORMAL_BOTTOM 12
    NORMAL_TOP 12, %11001010
    KERNEL_EVEN 12, BACK_COL, TXT_COL, T,h,e,Blank,f,o,l,l,o,w,i,n,g,Blank,a,r,e,Blank,B,O,N,U,S,Blank,l,i,n,e,s,Exclamation,Blank,Blank
    ENDIF

    IF NUM_MENU_ENTRIES > 12
    NORMAL_BOTTOM 13
    NORMAL_TOP 13, %11011010
    KERNEL_EVEN 13, BACK_COL, TXT_COL, O,u,r,s,Blank,i,s,Blank,n,o,t,Blank,t,o,Blank,r,e,a,s,o,n,Blank,w,h,y,SemiColon,Blank,Blank,Blank,Blank,Blank,Blank
    ENDIF

    IF NUM_MENU_ENTRIES > 13
    NORMAL_BOTTOM 14
    NORMAL_TOP 14, %11101010
    KERNEL_EVEN 14, BACK_COL, TXT_COL, Period,Period,Period,o,u,r,s,Blank,i,s,Blank,b,u,t,Blank,t,o,Blank,d,o,Blank,o,r,Blank,d,i,e,Period,Blank,Blank,Blank,Blank
    ENDIF

    REPEAT LINE_SPACING
        sta WSYNC
    REPEND
    lda #0
    sta COLUBK

    jmp ExitKernel

    END_BANK 3


;-------------------------------------------------------------------------------
; BANK 4
;-------------------------------------------------------------------------------

    START_BANK 4
    TEXT_COLOUR HTXT_COL
    
    KERNEL_ODD 0, HEADER_COL, HTXT_COL, P,l,u,s,C,a,r,t,OpenRound,Plus,CloseRound,1,2,3,4,5,6,7,8,9,A,B,Blank,1, 3,Slash,2,7,Wifi,Wifi, Account,Account
    HEADER_BOTTOM

    KERNEL_ODD 1, BACK_COL, TXT_COL, N,o,v,e,m,b,e,r,Blank,M,o,v,e,m,y,e,r,Blank,Blank,i,o,n,Blank,s,h,o,u,l,d,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 2

    NORMAL_TOP 2, %00101010
    KERNEL_ODD 2, BACK_COL, TXT_COL, I,N,T,Blank,I,M,T,Blank,Blank,Blank,A,N,N,O,T,A,T,I,O,N,Blank,e,v,i,n,g,Blank,t,h,e,Blank,Blank
    NORMAL_BOTTOM 3

    NORMAL_TOP 3, %00111010
    KERNEL_ODD 3, BACK_COL, TXT_COL, A,N,G,R,Y,Blank,N,O,T,Blank,A,X,Y,O,T,A,T,I,O,M,Blank,Blank,o,n,Blank,t,h,e,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 4

    NORMAL_TOP 4, %01001010
    KERNEL_ODD 4, BACK_COL, TXT_COL,  A,M,G,R,Y,Blank,M,O,T,Blank,r,e,t,u,r,n,i,n,g,Blank,h,i,m,Blank,s,a,f,e,l,y,Blank,Blank
    NORMAL_BOTTOM 5

    END_BANK 4


;-------------------------------------------------------------------------------
; BANK 5
;-------------------------------------------------------------------------------

    START_BANK 5


    NORMAL_TOP 5, %01011010
    KERNEL_ODD 5, BACK_COL, TXT_COL, t,o,Blank,t,h,e,Blank,E,a,r,t,h,Period,Quote,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 6

    NORMAL_TOP 6, %01101010
    KERNEL_ODD 6, BACK_COL, TXT_COL, Blank,Blank,Minus,Blank,J,o,h,n,Blank,F,Period,Blank,K,e,n,n,e,d,y,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    NORMAL_BOTTOM 7

    NORMAL_TOP 7, %01111010
    KERNEL_ODD 7, BACK_COL, TXT_COL, a,b,c,d,e,f,Blank,Blank,Blank,A,B,C,D,E,F,Blank,Blank,Blank,Blank,0,1,Blank,Blank,Blank,Blank,Exclamation,Quote,Hash,Dollar,Percent,At,Blank
    NORMAL_BOTTOM 8

    NORMAL_TOP 8, %10001010
    KERNEL_ODD 8, BACK_COL, TXT_COL, g,h,i,j,k,l,m,Blank,Blank,G,H,I,J,K,L,M,Blank,Blank,9,Blank,Blank,2,Blank,Blank,Blank,Ampersand,Apostrophe,OpenRound,CloseRound,Asterisk,OpenCurly,CloseCurly
    NORMAL_BOTTOM 9

    NORMAL_TOP 9, %10011010
    KERNEL_ODD 9, BACK_COL, TXT_COL,  n,o,p,q,r,s,t,Blank,Blank,N,O,P,Q,R,S,T,Blank,8,Blank,Blank,Blank,Blank,3,Blank,Blank,Plus,Minus,Comma,Period,Slash,BackSlash,Tilde
    NORMAL_BOTTOM 10

    END_BANK 5

;-------------------------------------------------------------------------------
; BANK 6
;-------------------------------------------------------------------------------

    START_BANK 6


    NORMAL_TOP 10, %10101010
    KERNEL_ODD 10, BACK_COL, TXT_COL, u,v,w,x,y,z,Blank,Blank,Blank,U,V,W,X,Y,Z,Blank,Blank,Blank,7,Blank,Blank,4,Blank,Blank,Blank,Colon,SemiColon,Less,Equal,Greater,Question,Blank

    IF NUM_MENU_ENTRIES > 10
    NORMAL_BOTTOM 11
    NORMAL_TOP 11, %10111010
    KERNEL_ODD 11, BACK_COL, TXT_COL, Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,6,5,Blank,Blank,Blank,Blank,OpenSquare,CloseSquare,Accent,UnderScore,Grave,Blank,Blank
    ENDIF

    IF NUM_MENU_ENTRIES > 11
    NORMAL_BOTTOM 12
    NORMAL_TOP 12, %11001010
    KERNEL_ODD 12, BACK_COL, TXT_COL, T,h,e,Blank,f,o,l,l,o,w,i,n,g,Blank,a,r,e,Blank,B,O,N,U,S,Blank,l,i,n,e,s,Exclamation,Blank,Blank
    ENDIF

    IF NUM_MENU_ENTRIES > 12
    NORMAL_BOTTOM 13
    NORMAL_TOP 13, %11011010
    KERNEL_ODD 13, BACK_COL, TXT_COL, O,u,r,s,Blank,i,s,Blank,n,o,t,Blank,t,o,Blank,r,e,a,s,o,n,Blank,w,h,y,SemiColon,Blank,Blank,Blank,Blank,Blank,Blank
    ENDIF

    IF NUM_MENU_ENTRIES > 13
    NORMAL_BOTTOM 14
    NORMAL_TOP 14, %11101010
    KERNEL_ODD 14, BACK_COL, TXT_COL, Period,Period,Period,o,u,r,s,Blank,i,s,Blank,b,u,t,Blank,t,o,Blank,d,o,Blank,o,r,Blank,d,i,e,Period,Blank,Blank,Blank,Blank
    ENDIF

    REPEAT LINE_SPACING
        sta WSYNC
    REPEND
    lda #0
    sta COLUBK

    jmp ExitKernel
    END_BANK 6


;-------------------------------------------------------------------------------
; BANK 7
;-------------------------------------------------------------------------------
; empty

    START_BANK 7
    END_BANK 7

; digit graphics definititions (3x10 pixel, looks nicer than 3x5 with doubled lines)

  MAC _CHAR_D ; {1}, {2}, {3}
_{1}_R{2} = {3}
_{1}_L{2} = {3} << 4
  ENDM

  MAC _CHAR_L ; {1}, {2}, {3}
_{1}_L{2} = {3} << 4
  ENDM

  MAC _CHAR_R ; {1}, {2}, {3}
_{1}_R{2} = {3}
  ENDM


    IF FONT = FONT_SMALLCAPS
    include "SmallCaps.asm"
    ENDIF
    
    IF FONT = FONT_Trichotomic_12
    include "Trichotomic-12.asm"
    ENDIF
    
    IF FONT = FONT_CaptainMorganSpice
    include "CaptainMorgan.asm"
    ENDIF
    
    IF FONT = FONT_GlacierBelle
    include "GlacierBelle.asm"
    ENDIF

