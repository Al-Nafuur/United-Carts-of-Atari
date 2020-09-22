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
CHAR_H      = 12        ; 10 or 12
CHAR_36     = 0         ; MUST be 0!



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

  IF CHAR_H = 10
NUM_MENU_ENTRIES   = 15
  ELSE
NUM_MENU_ENTRIES   = 15
  ENDIF

  IF NTSC_COL

BACK_COL    = $92
TXT_COL     = $0C       ; complimentary color to create better white

HEADER_COL  = $90
HTXT_COL    = $2e       ; complimentary color to create better white

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
SEL_COL     = $a4
   ENDIF

  ELSE ;/NTSC

BACK_COL    = $D2
TXT_COL     = $0C       ; complimentary color to create better white

HEADER_COL  = $b0
HTXT_COL    = $2e       ; complimentary color to create better white

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
SEL_COL     = $94
   ENDIF

  ENDIF


;===============================================================================
; Z P - V A R I A B L E S
;===============================================================================

WaitCart = $84 ; routine to run from 2600 RAM while cart busy copied here

    SEG.U   variables
    ORG     $80

frameCnt    .byte
CurItem		      DS.B  1
CommandByte     DS.B  1   ; $0 to $f item selected, $10 next page, $20 prev page, $30 ready for reboot.
LineBackColor   DS.B  NUM_MENU_ENTRIES+1
StickDelayCount	DS.B  1



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

  MAC _KERNEL_A                 ;       @14

PatchA1_{1} = . + 1
    ldx     #{3}                ;2
PatchA2_{1} = . + 1
    lda     #{4}                ;2
    sta     GRP1                ;3      @21     {4}
PatchA0_{1} = . + 1
    lda     #{2}                ;2
    sta     GRP0                ;3      @26     {2}
PatchA5_{1} = . + 1
    ldy     #{7}                ;2
    stx.w   GRP0                ;4      @32     {3}
    nop                         ;2
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
; displays: 00--00--11--11--11----00--00--00--00
PatchA_BkCol_{1}_{2} = . + 1
    lda     LineBackColor+{1}  ;#{3}                ;2
    sta     COLUBK              ;3      @05
PatchA_TxtCol_{1}_{2} = . + 1
    lda     #TXT_COL ;#{3}                ;2
    ;sta.w     COLUP0              ;3      @10
    ;nop
    SLEEP 6
;    sta.w   COLUP1              ;4      @14
    _KERNEL_A {1}_{2}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}
  ENDM


  MAC KERNEL_A
; displays: 00--00--11--11--11----00--00--00--00
    SLEEP   14
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
    sta     RESP0               ;3      @00
  ENDM

  MAC KERNEL_B_BOTH
; displays: --00--00--11--11--1100--00--00--
    sta     HMOVE               ;3      @03
PatchB_BkCol_{1}_{2} = . + 1
    lda     LineBackColor+{1}; #{3}                ;2
    sta     COLUBK              ;3      @08
PatchB_TxtCol_{1}_{2} = . + 1
    lda     #TXT_COL ;#{3}                ;2
;    sta     COLUP0              ;3      @13
    ;nop
    ;sta     COLUP1              ;3      @16
    SLEEP 5
    _KERNEL_B {1}_{2}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}
  ENDM


  MAC KERNEL_B
; displays: --00--00--11--11--1100--00--00--
    sta     HMOVE               ;3      @03
    SLEEP   13
    _KERNEL_B {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}
  ENDM

;@Wolfgang: The following macros are not required by the PlusCart 6507 code, they just show how the macros above have to be used

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


  MAC KERNEL_EVEN ; {index}, {bk-color}, {txt-color}, {32 x chars...}
    ; 10 lines/char, each line has individual color


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
   IF CHAR_H >= 11
    KERNEL_AXC      {1}, 10,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
   ENDIF
   IF CHAR_H >= 12
    KERNEL_BXC      {1}, 11,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
   ENDIF
    stx     GRP0
    stx     GRP1
  ENDM

  MAC KERNEL_ODD ; {index}, {bk-color}, {txt-color}, {32 x chars...}
    ; 10 lines/char, each line has individual color
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
   IF CHAR_H >= 11
    KERNEL_BXC      {1}, 10,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
   ENDIF
   IF CHAR_H >= 12
    KERNEL_AXC      {1}, 11,  0,   0 , {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}, {19}, {20}, {21}, {22}, {23}, {24}, {25}, {26}, {27}, {28}, {29}, {30}, {31}, {32}, {33}, {34}, {35}
   ENDIF
    ldx #0
    stx     GRP0
    stx     GRP1
  ENDM


    MAC TEXT_COLOUR ; {colour}
        lda #{1}
        sta COLUP0
        sta COLUP1
    ENDM


  MAC TOP_NORMAL
   IF CHAR_H >= 12
    ;sta     WSYNC
   ENDIF
    sta     WSYNC
  ENDM


  MAC BTM_NORMAL

    lda #$1C
    sta COLUP0
    sta COLUP1

    ;sta     WSYNC
  ENDM


  MAC BOTTOM_SELECTION
;    sta     WSYNC
;    lda     #LINE_COL
;    sta     COLUBK
    ;sta     WSYNC



    lda     #BACK_COL        ;               back to normal background color
    sta     WSYNC
   IF CHAR_H >= 12
    sta     COLUBK          ; 3

    ;sta     WSYNC
   ENDIF
  ENDM


  MAC START_BANK ; {bank}
    ORG     BASE_ADR + {1} * $1000
    RORG    BASE_ADR + {1} * $2000

ExitKernel = (. & $1fff)
    cld
    sta     HOTSPOT
    jmp     ContDrawScreen

SwitchBank = (. & $1fff)
    sta     HOTSPOT + 1 + {1},x     ;   Note: X is usually 0, except when starting odd kernel
  ENDM


  MAC END_BANK ; {bank}
    jmp     SwitchBank

    ORG     BASE_ADR + $fe6 + {1} * $1000
    RORG    BASE_ADR + $fe6 + {1} * $2000
 
;    ds      8, 0        ; Comm Area !
    .byte    0,0,2,5,12,2,0,0

Start = (. & $1fff)
    sta     HOTSPOT
    jmp     DoStart
;    nop

    ds      8, 0        ; bank switch hotspots
    .word   FirstStart
    .word   FirstStart
  ENDM

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
    SEG     Bank

_FREE SET 0

;-------------------------------------------------------------------------------
; BANK 0
;-------------------------------------------------------------------------------
; First bank is for overall logic
;StartByte
   START_BANK 0

FirstStart
    cld                         ;           Clear BCD math bit.
    lda     #0
    tax
    dex
    txs
.clearLoop:
    tsx
    pha
    bne     .clearLoop

  	lda $1FF4                   ; enable comm Area

  	jsr PrepareWaitCartRoutine
  	ldx #FirstBootCommand
  	jsr WaitCart

_init_blocker	; check right not pressed
	lda #$80
	and SWCHA
	beq _init_blocker


MainLoop
    jsr     GameInit
    jsr     MenuLoop
  	jsr     PrepareWaitCartRoutine
	  ldx     CommandByte
	  jsr     WaitCart
    ;CheckPageType
    lda     CommandByte 
    cmp     #PrevPageCommand - 1
    bcs     MainLoop
    lda     #PAGE_TYPE_KEYBOARD
    cmp     PageType
    beq     MainLoop
    lda     #0
    sta     CurItem
    jmp     MainLoop


DoStart SUBROUTINE
MenuLoop
    jsr     SetActiveItem
    jsr     VerticalBlank
    jsr     GameCalc

ReadControls
	lda StickDelayCount
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
	cpx ItemsOnActPage           ; vergleiche mit ItemCount on this page ?
	beq _pageDown
	inc CurItem
	lda #10
	sta StickDelayCount
	jmp _x4               ; todo use BRA
	
	
_x1	; check up
	lda #$10
	and SWCHA
	bne _x2
	; up pressed
	ldx CurItem
	beq _pageUp            ; branch to 
	dec CurItem
	lda #10
	sta StickDelayCount
	jmp _x4               ; todo use BRA


_x2	; check left          left and right just send page up/down to Cart !
	lda #$40
	and SWCHA
	bne _x3
	; left pressed
_pageUp ; CurPage-- request
	ldx CurPage
	beq _x3
  lda #NUM_MENU_ENTRIES-1    ; set CurItem to last entry
  sta CurItem
	lda PrevPageCommand
  jmp     ExitMenu

_x3	; check right
	lda #$80
	and SWCHA
	bne _x4
	; right pressed

_pageDown ; CurPage++ request
	ldx CurPage
	cpx MaxPage
	beq _x4
  lda #0                ; set CurItem to first entry
  sta CurItem
	lda NextPageCommand
  jmp     ExitMenu
_x4

    jsr     DrawScreen
    jsr     OverScan

; check fire button
  	bit     INPT4
  	bmi     NotFire
  	jmp     ItemSelected
; check reset
NotFire
  	lda     #$01
  	and     SWCHB
	  beq     ItemSelected
NoSelection
    jmp     MenuLoop

ItemSelected
    lda CurItem
ExitMenu
    sta CommandByte
	  rts



GameInit
    lda     #%11
    sta     NUSIZ0
    sta     NUSIZ1

    lda     #$d0
    sta     COLUBK
    lda     #%01110000           ; mask left and right border
    sta     PF0
    lda     #%1
    sta     CTRLPF
    lda     #HEADER_COL          ; set HEADER_COL for first textline in RAM
    sta     LineBackColor
    lda     CurItem
    cmp     ItemsOnActPage
    bcc     EndGameInit
    lda     #0
    sta     CurItem
EndGameInit
    rts




; ALIGN 256

PrepareWaitCartRoutine
; copy routine to ram
    ldy #( EndWaitCartRoutine - WaitCartRoutine )
add
  	lda WaitCartRoutine-1,y
  	sta WaitCart-1,y
	  dey
	  bne add
; score mode
  	lda #2
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

;------------------------------------------------------------------
WaitCartRoutine
  	stx SendCartCommand       ; sent cmd to cart
frame_loop
; Enable VBLANK (disable output)
  	lda #2
  	sta VBLANK
; At the beginning of the frame we set the VSYNC bit...
  	sta VSYNC
; And hold it on for 3 scanlines...
  	sta WSYNC
  	sta WSYNC
  	sta WSYNC
; Now we turn VSYNC off.
  	lda #0
  	sta VSYNC
; Now we need 37 lines of VBLANK...	
  	ldx #37
lVBLANK sta WSYNC
  	dex
  	bne lVBLANK
; Re-enable output (disable VBLANK)	
  	lda #0
  	sta VBLANK
	
  IF NTSC_TIM
	  ldx #32	          ; 32 scanlines, total 192(ntsc, pal60)
  ELSE
    ldx #42           ; 42 scanlines, total 242(pal)
  ENDIF

scan1
  	sta WSYNC
	  dex
	  bne scan1

  	ldy #0
scan2
	  sta WSYNC
  	tya
    lsr
	  lsr
	  tax
  	lda WaitCart + #(PlusLogo  -  WaitCartRoutine) ,x  
  	sta PF1
  	iny
  	cpy #24	; 24 scanlines
  	bcc scan2
	
  IF NTSC_TIM
	  ldx #136 ; 136 scanlines
  ELSE
    ldx #176 ; 176 scanlines
  ENDIF

scan3
  	sta WSYNC
  	dex
  	bne scan3

; Enable VBLANK again
  	lda #2
  	sta VBLANK
; 30 lines of overscan to complete the frame
  	ldx #30
lvover	sta WSYNC
  	dex
  	bne lvover

;check if firmware back
  	lda $1000
  	cmp #$d8 ; d8 8d for cart
  	bne frame_loop
	
  	lda StatusByteReboot
  	bne reboot
	  rts

reboot
	  lda #0
	  tax
add2
	  sta $00,x		;Clear TIA ($00-$3f)
	  inx
	  cpx #$3f
	  bcc add2
	  ldx #$FD		;Set stack pointer to $fd
	  txs
; tell cart we are ready for switch
    lda #RebootCommand
	  sta SendCartCommand
	  lda #0
	  sta WSYNC
	  sta WSYNC
	  jmp ($fffc)
PlusLogo
    .byte $22
	  .byte $49
	  .byte $5D
	  .byte $49
	  .byte $22
EndWaitCartRoutine
	  .byte $0	


 
VerticalBlank SUBROUTINE
    lda     #%00001110
.loopVSync:
    sta     WSYNC
    sta     VSYNC
    lsr
    bne     .loopVSync

    inc     frameCnt
  IF NTSC_TIM
    lda     #44-8
  ELSE
    lda     #77-8-1
  ENDIF
    sta     TIM64T
    rts
; VerticalBlank


GameCalc SUBROUTINE
    ldx     #0
    lda     frameCnt
    lsr
    lda     #0
    bcc     .evenFrame0
    lda     #3
.evenFrame0
    jsr     SetXPos
    inx
    lda     #48
    jsr     SetXPos
    sta     WSYNC
    sta     HMOVE
    sta     WSYNC
    sta     HMCLR
    lda     #$b0
    sta     HMP0
    lda     #$80
    sta     HMP1

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
; GameCalc

OverScan SUBROUTINE
  IF NTSC_TIM
    lda     #36-8
  ELSE
    lda     #63-9+1
  ENDIF
    sta     TIM64T

.waitTim:
    lda     INTIM
    bne     .waitTim
    rts
; OverScan

    ALIGN 256

SetXPos SUBROUTINE
    sec
    sta     WSYNC
WaitObject:
    sbc     #$0f            ; 2
    bcs     WaitObject      ; 2³

  CHECKPAGE WaitObject

    eor     #$07            ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    asl                     ; 2
    sta     HMP0,x          ; 4
    sta.w  RESP0,x         ; 5     @23!
    rts
; SetXPos

DrawScreen SUBROUTINE
    ldx     #227+17
.waitTim:
    lda     INTIM
    bne     .waitTim
    sta     WSYNC
    sta     VBLANK
    stx     TIM64T

    lda     #HEADER_COL
    sta     COLUBK
    sta     WSYNC
    sta     WSYNC
    sta     WSYNC

    ldx     #1-1            ; even kernels start at bank 1
    lda     frameCnt
    lsr
    bcc     .evenFrame
    ldx     #4-1            ; odd kernels start at bank 4
.evenFrame
    jmp     SwitchBank

ContDrawScreen
    stx     GRP0
    stx     GRP1
;    stx     GRP0

    ldx     #2
.waitScreen:
    lda     INTIM
    bne     .waitScreen
    sta     WSYNC
    stx     VBLANK
    ;nop                     ; TODO: removing this causes a rolling screen on real hardware!?
    rts
; DrawScreen

SetActiveItem
    ldx     #NUM_MENU_ENTRIES
    lda     #BACK_COL              ; BACK_COL TXT_COL
.loopColor
    sta     LineBackColor,x
    dex
    bne     .loopColor
    lda     #SEL_COL
    ldx     CurItem                 ; CurItem
    sta     LineBackColor+1,x
    rts

    END_BANK 0


;-------------------------------------------------------------------------------
; BANK 1
;-------------------------------------------------------------------------------

    START_BANK 1

    sta     WSYNC
    
    KERNEL_EVEN 0, HEADER_COL, HTXT_COL, Q,u,o,t,e,Blank,o,f,Blank,t,h,e,Blank,D,a,y,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Wifi,Blank,Blank,Blank
    BOTTOM_SELECTION

    sta     WSYNC
    sta     WSYNC
    sta     COLUBK
    sta     WSYNC
    sta     WSYNC
    sta     WSYNC

    lda #%00011100
    sta COLUP0
    sta COLUP1
    
    sta     WSYNC

    KERNEL_EVEN 1, BACK_COL, TXT_COL, Quote,I,Blank,b,e,l,i,e,v,e,Blank,t,h,i,s,Blank,n,a,t,i,o,n,Blank,s,h,o,u,l,d,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %00101100
    TOP_NORMAL
    KERNEL_EVEN 2, BACK_COL, TXT_COL, c,o,m,m,i,t,Blank,i,t,s,e,l,f,Blank,t,o,Blank,a,c,h,i,e,v,i,n,g,Blank,t,h,e,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %00111100
    TOP_NORMAL
    KERNEL_EVEN 3, BACK_COL, TXT_COL, g,o,a,l,Blank,o,f,Blank,l,a,n,d,i,n,g,Blank,a,Blank,m,a,n,Blank,o,n,Blank,t,h,e,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %01001100
    TOP_NORMAL
    KERNEL_EVEN 4, BACK_COL, TXT_COL,  M,o,o,n,Comma,Blank,a,n,d,Blank,r,e,t,u,r,n,i,n,g,Blank,h,i,m,Blank,s,a,f,e,l,y,Blank,Blank

    END_BANK 1


;-------------------------------------------------------------------------------
; BANK 2
;-------------------------------------------------------------------------------

    START_BANK 2

    BTM_NORMAL

    TEXT_COLOUR %01011100
    TOP_NORMAL
    KERNEL_EVEN 5, BACK_COL, TXT_COL, t,o,Blank,t,h,e,Blank,E,a,r,t,h,Period,Quote,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %01101100
    TOP_NORMAL
    KERNEL_EVEN 6, BACK_COL, TXT_COL, Blank,Blank,Minus,Blank,J,o,h,n,Blank,F,Period,Blank,K,e,n,n,e,d,y,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %01111100
    TOP_NORMAL
    KERNEL_EVEN 7, BACK_COL, TXT_COL, a,b,c,d,e,f,Blank,Blank,Blank,A,B,C,D,E,F,Blank,Blank,Blank,Blank,0,1,Blank,Blank,Blank,Blank,Exclamation,Quote,Hash,Dollar,Percent,At,Blank
    BTM_NORMAL

    TEXT_COLOUR %10001100
    TOP_NORMAL
    KERNEL_EVEN 8, BACK_COL, TXT_COL, g,h,i,j,k,l,m,Blank,Blank,G,H,I,J,K,L,M,Blank,Blank,9,Blank,Blank,2,Blank,Blank,Blank,Ampersand,Apostrophe,OpenRound,CloseRound,Asterisk,OpenCurly,CloseCurly
    BTM_NORMAL

    TEXT_COLOUR %10011100
    TOP_NORMAL
    KERNEL_EVEN 9, BACK_COL, TXT_COL,  n,o,p,q,r,s,t,Blank,Blank,N,O,P,Q,R,S,T,Blank,8,Blank,Blank,Blank,Blank,3,Blank,Blank,Plus,Minus,Comma,Period,Slash,BackSlash,Tilde
    BTM_NORMAL

    END_BANK 2


;-------------------------------------------------------------------------------
; BANK 3
;-------------------------------------------------------------------------------

    START_BANK 3

    TEXT_COLOUR %10101100
    TOP_NORMAL
    KERNEL_EVEN 10, BACK_COL, TXT_COL, u,v,w,x,y,z,Blank,Blank,Blank,U,V,W,X,Y,Z,Blank,Blank,Blank,7,Blank,Blank,4,Blank,Blank,Blank,Colon,SemiColon,Less,Equal,Greater,Question,Blank
    BTM_NORMAL

    TEXT_COLOUR %10111100
    TOP_NORMAL
    KERNEL_EVEN 11, BACK_COL, TXT_COL, Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,6,5,Blank,Blank,Blank,Blank,OpenSquare,CloseSquare,Accent,UnderScore,Grave,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %11001100
    TOP_NORMAL
    KERNEL_EVEN 12, BACK_COL, TXT_COL, T,h,e,Blank,f,o,l,l,o,w,i,n,g,Blank,a,r,e,Blank,B,O,N,U,S,Blank,l,i,n,e,s,Exclamation,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %11011100
    TOP_NORMAL
    KERNEL_EVEN 13, BACK_COL, TXT_COL, O,u,r,s,Blank,i,s,Blank,n,o,t,Blank,t,o,Blank,r,e,a,s,o,n,Blank,w,h,y,SemiColon,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %11101100
    TOP_NORMAL
    KERNEL_EVEN 14, BACK_COL, TXT_COL, Period,Period,Period,o,u,r,s,Blank,i,s,Blank,b,u,t,Blank,t,o,Blank,d,o,Blank,o,r,Blank,d,i,e,Period,Blank,Blank,Blank,Blank
    BTM_NORMAL

  IF CHAR_H = 10


    TEXT_COLOUR %11111100
    TOP_NORMAL
    KERNEL_EVEN 15, BACK_COL, TXT_COL, F,o,n,t,Colon,Blank,T,r,i,c,h,o,t,o,m,i,c,Blank,1,0,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL
  ENDIF
    jmp ExitKernel

    END_BANK 3


;-------------------------------------------------------------------------------
; BANK 4
;-------------------------------------------------------------------------------

    START_BANK 4

    sta     WSYNC
    
    KERNEL_ODD 0, HEADER_COL, HTXT_COL, Q,u,o,t,e,Blank,o,f,Blank,t,h,e,Blank,D,a,y,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Wifi,Blank,Blank,Blank
    BOTTOM_SELECTION

    sta     WSYNC
    sta     WSYNC
    sta     COLUBK
    sta     WSYNC
    sta     WSYNC
    sta     WSYNC

    TEXT_COLOUR %00011100

    sta     WSYNC
    
    KERNEL_ODD 1, BACK_COL, TXT_COL, Quote,I,Blank,b,e,l,i,e,v,e,Blank,t,h,i,s,Blank,n,a,t,i,o,n,Blank,s,h,o,u,l,d,Blank,Blank,Blank,Blank
bp100:
    BTM_NORMAL

    TEXT_COLOUR %00101100
    TOP_NORMAL
    KERNEL_ODD 2, BACK_COL, TXT_COL, c,o,m,m,i,t,Blank,i,t,s,e,l,f,Blank,t,o,Blank,a,c,h,i,e,v,i,n,g,Blank,t,h,e,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %00111100
    TOP_NORMAL
    KERNEL_ODD 3, BACK_COL, TXT_COL, g,o,a,l,Blank,o,f,Blank,l,a,n,d,i,n,g,Blank,a,Blank,m,a,n,Blank,o,n,Blank,t,h,e,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %01001100
    TOP_NORMAL
    KERNEL_ODD 4, BACK_COL, TXT_COL,  M,o,o,n,Comma,Blank,a,n,d,Blank,r,e,t,u,r,n,i,n,g,Blank,h,i,m,Blank,s,a,f,e,l,y,Blank,Blank

    END_BANK 4


;-------------------------------------------------------------------------------
; BANK 5
;-------------------------------------------------------------------------------

    START_BANK 5
    BTM_NORMAL

    TEXT_COLOUR %01011100
    TOP_NORMAL
    KERNEL_ODD 5, BACK_COL, TXT_COL, t,o,Blank,t,h,e,Blank,E,a,r,t,h,Period,Quote,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %01101100
    TOP_NORMAL
    KERNEL_ODD 6, BACK_COL, TXT_COL, Blank,Blank,Minus,Blank,J,o,h,n,Blank,F,Period,Blank,K,e,n,n,e,d,y,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %01111100
    TOP_NORMAL
    KERNEL_ODD 7, BACK_COL, TXT_COL, a,b,c,d,e,f,Blank,Blank,Blank,A,B,C,D,E,F,Blank,Blank,Blank,Blank,0,1,Blank,Blank,Blank,Blank,Exclamation,Quote,Hash,Dollar,Percent,At,Blank
    BTM_NORMAL

    TEXT_COLOUR %10001100
    TOP_NORMAL
    KERNEL_ODD 8, BACK_COL, TXT_COL, g,h,i,j,k,l,m,Blank,Blank,G,H,I,J,K,L,M,Blank,Blank,9,Blank,Blank,2,Blank,Blank,Blank,Ampersand,Apostrophe,OpenRound,CloseRound,Asterisk,OpenCurly,CloseCurly
    BTM_NORMAL

    TEXT_COLOUR %10011100
    TOP_NORMAL
    KERNEL_ODD 9, BACK_COL, TXT_COL,  n,o,p,q,r,s,t,Blank,Blank,N,O,P,Q,R,S,T,Blank,8,Blank,Blank,Blank,Blank,3,Blank,Blank,Plus,Minus,Comma,Period,Slash,BackSlash,Tilde
    BTM_NORMAL

    END_BANK 5

;-------------------------------------------------------------------------------
; BANK 6
;-------------------------------------------------------------------------------

    START_BANK 6


    TEXT_COLOUR %10101100
    TOP_NORMAL
    KERNEL_ODD 10, BACK_COL, TXT_COL, u,v,w,x,y,z,Blank,Blank,Blank,U,V,W,X,Y,Z,Blank,Blank,Blank,7,Blank,Blank,4,Blank,Blank,Blank,Colon,SemiColon,Less,Equal,Greater,Question,Blank
    BTM_NORMAL

    TEXT_COLOUR %10111100
    TOP_NORMAL
    KERNEL_ODD 11, BACK_COL, TXT_COL, Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,6,5,Blank,Blank,Blank,Blank,OpenSquare,CloseSquare,Accent,UnderScore,Grave,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %11001100
    TOP_NORMAL
    KERNEL_ODD 12, BACK_COL, TXT_COL, T,h,e,Blank,f,o,l,l,o,w,i,n,g,Blank,a,r,e,Blank,B,O,N,U,S,Blank,l,i,n,e,s,Exclamation,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %11011100
    TOP_NORMAL
    KERNEL_ODD 13, BACK_COL, TXT_COL, O,u,r,s,Blank,i,s,Blank,n,o,t,Blank,t,o,Blank,r,e,a,s,o,n,Blank,w,h,y,SemiColon,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL

    TEXT_COLOUR %11101100
    TOP_NORMAL
    KERNEL_ODD 14, BACK_COL, TXT_COL, Period,Period,Period,o,u,r,s,Blank,i,s,Blank,b,u,t,Blank,t,o,Blank,d,o,Blank,o,r,Blank,d,i,e,Period,Blank,Blank,Blank,Blank
    BTM_NORMAL

  IF CHAR_H = 10


    TEXT_COLOUR %11111100
    TOP_NORMAL
    KERNEL_ODD 15, BACK_COL, TXT_COL, F,o,n,t,Colon,Blank,T,r,i,c,h,o,t,o,m,i,c,Blank,1,0,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank,Blank
    BTM_NORMAL
  ENDIF
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

  IF CHAR_H = 10
	include "Chars10.asm"
  ENDIF
  IF CHAR_H = 12


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

	;include "Chars12.asm"
  ENDIF
