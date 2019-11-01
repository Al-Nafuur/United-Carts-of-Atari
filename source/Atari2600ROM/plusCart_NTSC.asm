; PlusCart Menu
; by Wolfgang Stubig 2019

; UnoCart2600 Menu
;   by Robin Edwards (Electrotrains) 2018
; NTSC Version of Firmware
; Version History
; ---------------
; v1.01 25/1/18 Added Select/Reset as alternative to joysitck for menu navigation
; v1.02 28/3/18 Adds read to $1FF4 on init, to unlock the comms area on the cartridge

; @com.wudsn.ide.asm.hardware=ATARI2600
	icl "vcs.asm"
	icl "macro.asm"

;--------------------------TIA CONSTANTS----------------------------------

;--NUSIZx CONSTANTS
;	player:
ONECOPYNORMAL		=	$00
TWOCOPIESCLOSE		=	$01
TWOCOPIESMED		=	$02
THREECOPIESCLOSE	=	$03
TWOCOPIESWIDE		=	$04
ONECOPYDOUBLE		=	$05
THREECOPIESMED		=	$06
ONECOPYQUAD		=	$07
;---HMxx CONSTANTS
LEFTSEVEN		=	$70
LEFTSIX			=	$60
LEFTFIVE		=	$50
LEFTFOUR		=	$40
LEFTTHREE		=	$30
LEFTTWO			=	$20
LEFTONE			=	$10
NOMOVEMENT		=	$00
RIGHTONE		=	$F0
RIGHTTWO		=	$E0
RIGHTTHREE		=	$D0
RIGHTFOUR		=	$C0
RIGHTFIVE		=	$B0
RIGHTSIX		=	$A0
RIGHTSEVEN		=	$90
RIGHTEIGHT		=	$80

;------------------------------------------------------------------
; colour scheme
;------------------------------------------------------------------
TITLE_BK_COL =		$94	
TITLE_COL =		$9e
STATUS_BK_COL =		$04	
STATUS_COL =		$0e
MENU_BK_COL =		$80	
MENU_ITEM_COL =		$0e
MENU_FOLDER_COL	=	$9a
MENU_FOLDER_BK_COL =	$80
MENU_SEL_COL =		$ce
MENU_SEL_BK_COL =	$c2
;------------------------------------------------------------------
; atari->cart comms addresses
;------------------------------------------------------------------
CART_CMD_SEL_ITEM_n = 	$1E00	// out
CART_CMD_ROOT_DIR = 	$1EF0	// out
CART_CMD_START_CART = 	$1EFF	// out

WaitCart = $84 ; routine to run from 2600 RAM while cart busy copied here
ITEMS_PER_SCREEN = 7
;------------------------------------------------------------------
; non-volatile memory $80-$83
;------------------------------------------------------------------
	org $80
CurItem		.ds 1; current item selected in the menu
;------------------------------------------------------------------
; volatile memory ($88+) overwritten by RAM routine        
;------------------------------------------------------------------
	org $88
Counter		.ds 2
TextBlockPointer	.ds 2
TextLineCounter	.ds 1
Char1Ptr	.ds 2
Char2Ptr	.ds 2
Char3Ptr	.ds 2
Char4Ptr	.ds 2
Char5Ptr	.ds 2
Char6Ptr	.ds 2
Char7Ptr	.ds 2
Char8Ptr	.ds 2
Char9Ptr	.ds 2
Char10Ptr	.ds 2
Char11Ptr	.ds 2
Char12Ptr	.ds 2
Temp		.ds 1
ItemTextPtr	.ds 2
ItemCount	.ds 1	; total # of items
TopItem		.ds 1	; item # at the top of the page
RowItem		.ds 1	; item # we are drawing
RowCount	.ds 1	; 0 ->  ITEMS_PER_SCREEN-1
StickDelayCount	.ds 1
;------------------------------------------------------------------
; Cartridge ROM
;------------------------------------------------------------------
	opt h-f+l+		;Create plain 4k ROM file
	org $f000		;Main part

	.proc cart
Start
	cld			;Clear decimal flag
	lda #0
	tax
init	sta $00,x		;Clear TIA ($00-$3f) and 128 bytes of RAM ($80-$ff)
	inx
	bne init
	dex
	txs			;Set stack pointer to $ff

; multicart init
	; the firmware looks for an access to $1FF4 before unlocking the comms area ($1Exx).
	; this is because the 7800 firmware accesses this area on power-up, and we want to ignore
	; these reads until the 7800 has started the cart in 2600 mode.
	lda $1FF4
	
	jsr PrepareWaitCartRoutine
	ldx #$F0 ; CART_CMD_ROOT_DIR
	jsr WaitCart
	
; main sd navigation loop
loop	jsr InitMenu
	jsr Menu
	
; an item has been selected from the menu
	jsr PrepareWaitCartRoutine
	ldx CurItem
	jsr WaitCart
	jmp loop
;------------------------------------------------------------------
; Menu
;------------------------------------------------------------------
	.proc InitMenu
	lda #0
	sta StickDelayCount
	sta CurItem
	sta TopItem
	sta ItemCount
	
	; count items
	mwa #ItemsList ItemTextPtr
        ldy #0
NextItem
        ; check if null string
        lda (ItemTextPtr),y
	beq DoneItems
	clc
	adw ItemTextPtr #12
	inc ItemCount
	lda ItemCount
	bne NextItem
DoneItems
	rts
	.endp
;------------------------------------------------------------------
	.proc ReadControls
	lda StickDelayCount
	beq _0
	dec StickDelayCount
	rts
_0
	; check down
	lda #$20
	and swcha
	beq _0X
	; check select
	lda #$02
	and swchb
	beq _0X
	jmp _1
_0X	; down/select pressed
	ldx CurItem
	inx
	cpx ItemCount
	beq _1
	inc CurItem
	lda #10
	sta StickDelayCount
	
_1	; check up
	lda #$10
	and swcha
	bne _2
	; up pressed
	ldx CurItem
	beq _2
	dec CurItem
	lda #10
	sta StickDelayCount

_2	; check left
	lda #$40
	and swcha
	bne _3
	; left pressed
	lda CurItem
	cmp #ITEMS_PER_SCREEN
	bcc _3
	sec
	sbc #ITEMS_PER_SCREEN
	sta CurItem
	lda #10
	sta StickDelayCount
	
_3	; check right
	lda #$80
	and swcha
	bne _4
	; right pressed
	lda CurItem
	clc
	adc #ITEMS_PER_SCREEN
	cmp ItemCount
	bcc _3a
	ldy ItemCount
	dey
	tya
_3a	sta CurItem
	lda #10
	sta StickDelayCount
_4
	rts
	.endp
;------------------------------------------------------------------
	.proc Menu       
        
        ; use the playfield to mask the player artifacts
        lda #0
        sta COLUPF
        lda #$70
        sta PF0
        lda #0
        sta PF1
        lda #0
        sta PF2
        lda #1
        sta CTRLPF

NextFrame
; VBlank ------------------------------------------------------------------
	lda #2
	sta vblank
	sta vsync
	sta wsync
	sta wsync
	sta wsync
	lda #0
	sta vsync
	
	TIMER_SETUP 37
        jsr ReadControls
        
        dec Counter
       	lda #1
	sta VDELP0
	sta VDELP1
	lda #THREECOPIESMED
	sta NUSIZ0
	sta NUSIZ1
	lda #$15
	ldx #0
	jsr PositionASpriteSubroutine
	lda #$25
	ldx #1
	jsr PositionASpriteSubroutine
	
; from the current item, set topItem and the item text pointer
	mwa #ItemsList ItemTextPtr
	lda #0
       	sta TextLineCounter
       	sta TopItem
	lda CurItem
	sta Temp

@	sec
	sbc #ITEMS_PER_SCREEN
	bmi DoneTopItem
	sta Temp
	lda TopItem
	clc
	adc #ITEMS_PER_SCREEN
	sta TopItem
	adw ItemTextPtr #(ITEMS_PER_SCREEN*12)
	lda Temp
	jmp @-
DoneTopItem

	sta wsync
        TIMER_WAIT
        sta wsync
	lda #0
	sta wsync
	sta vblank
	sta wsync	
; Frame ------------------------------------------------------------------
	TIMER_SETUP 192
	
; menu heading
	mwa #MenuTitle TextBlockPointer
	lda #0
       	sta TextLineCounter        
  	jsr SetTextPointersSubroutine
	lda #TITLE_COL
	sta COLUP0
	sta COLUP1
	lda #TITLE_BK_COL
	sta wsync
	sta COLUBK
  	jsr DrawLineOfTextSubroutine

; items  	
; start of item loop
	lda #0
	sta RowCount
       	sta TextLineCounter        
       	
	lda #0
	sta wsync
	sta COLUBK

NextItem
	lda TopItem
	clc
	adc RowCount
	sta RowItem
	cmp ItemCount
	bcs DrawBlankItem
DrawItem	
	mwa ItemTextPtr TextBlockPointer
  	jsr SetTextPointersSubroutine
  	sta wsync
; check if we are drawing the current selection	
  	lda RowItem
  	cmp CurItem
	bne NotCurrent
; current item
	ldx #MENU_SEL_COL
	ldy #MENU_SEL_BK_COL
	lda #MENU_SEL_COL
	jmp OutputLine
; not current item
NotCurrent
	; test the high-bit of the first character (directory flag)
	ldy TextLineCounter
	lda (TextBlockPointer),y
	and #$80
	beq NotDir
	ldx #MENU_FOLDER_COL
	ldy #MENU_FOLDER_BK_COL
	jmp OutputLine
NotDir
	ldx #MENU_ITEM_COL
	ldy #MENU_BK_COL
OutputLine
	stx COLUP0
	stx COLUP1
	sta wsync
	sty COLUBK	
  	jsr DrawLineOfTextSubroutine

	lda TextLineCounter
	clc
	adc #12
	sta TextLineCounter
	jmp EndDrawItem
	
DrawBlankItem
	mwa #BlankLine TextBlockPointer
	lda #0
       	sta TextLineCounter        
  	jsr SetTextPointersSubroutine
  	lda #MENU_BK_COL
	sta wsync
	sta COLUBK	
  	jsr DrawLineOfTextSubroutine
	sta wsync
EndDrawItem
; move onto the next row
   	inc RowCount
; reset background colour
	lda #MENU_BK_COL
	sta wsync
	sta COLUBK
; are we done?
   	lda RowCount
   	cmp #ITEMS_PER_SCREEN
	bne NextItem
        
DoneItems
 	lda #0
	sta wsync
	sta COLUBK
	sta wsync

; menu footer
	mwa #StatusBytes TextBlockPointer
	lda #0
       	sta TextLineCounter        
  	jsr SetTextPointersSubroutine
	lda #STATUS_COL
	sta COLUP0
	sta COLUP1
	lda #STATUS_BK_COL
	sta wsync
	sta COLUBK
  	jsr DrawLineOfTextSubroutine
	lda #0
	sta wsync
	sta COLUBK
	
	TIMER_WAIT
	sta wsync
	
	lda #2
	sta vblank
	sta wsync
	TIMER_SETUP 30
        TIMER_WAIT
        sta wsync
        
; check fire button
	bit inpt4
	bmi NotFire
	jmp FirePressed
; check reset
NotFire	lda #$01
	and swchb
	beq FirePressed
NoSelection
	jmp NextFrame
FirePressed
	lda ItemCount	; check there is an item to select
	beq NoSelection
	rts
	.endp
;------------------------------------------------------------------
; Subroutines
;------------------------------------------------------------------
	.proc PrepareWaitCartRoutine
; copy routine to ram
	ldy #.len[WaitCartRoutine]
@
	lda WaitCartRoutine-1,y
	sta WaitCart-1,y
	dey
	bne @-
; score mode
	lda #2
	sta ctrlpf
	lda #MENU_BK_COL
	sta colubk
	sta colup1
	lda #MENU_FOLDER_COL
	sta colup0
	lda #0
	sta pf0
	sta pf2
	rts
	.endp
;------------------------------------------------------------------
	.proc WaitCartRoutine
	lda $1e00,x	; sent cmd to cart
frame_loop
; Enable VBLANK (disable output)
	lda #2
	sta vblank
; At the beginning of the frame we set the VSYNC bit...
	sta vsync
; And hold it on for 3 scanlines...
	sta wsync
	sta wsync
	sta wsync
; Now we turn VSYNC off.
	lda #0
	sta vsync
; Now we need 37 lines of VBLANK...	
	ldx #37
lvblank sta wsync
	dex
	bne lvblank
; Re-enable output (disable VBLANK)	
	lda #0
	sta vblank
	
; total 192(ntsc)
	ldx #32	; 32 scanlines
scan1
	sta wsync
	dex
	bne scan1

	ldy #0
scan2
	sta wsync
	tya
	lsr
	lsr
	tax
	lda WaitCart + (SDLogo-WaitCartRoutine),x
	sta pf1
	iny
	cpy #24	; 24 scanlines
	bcc scan2
	
	ldx #136 ; 136 scanlines
scan3
	sta wsync
	dex
	bne scan3

; Enable VBLANK again
	lda #2
	sta vblank
; 30 lines of overscan to complete the frame
	ldx #30
lvover	sta wsync
	dex
	bne lvover

;check if firmware back
	lda $1000
	cmp #$D8 ;D8 for cart
	bne frame_loop
	
	lda StatusByteReboot
	bne reboot
	
	rts
reboot
	lda #0
	tax
@	sta $00,x		;Clear TIA ($00-$3f)
	inx
	cpx #$3f
	bcc @-
	ldx #$FD		;Set stack pointer to $fd
	txs
; tell cart we are ready for switch
	lda CART_CMD_START_CART
	sta wsync
	sta wsync
	jmp ($fffc)
SDLogo
	.byte $22
	.byte $49
	.byte $5D
	.byte $49
	.byte $22
	.byte $0	
	.endp
	
;-------------------------------------------------------------------------
; Text output modified from https://github.com/tdididit/a26-flashcart
;-------------------------------------------------------------------------
	.align $100
PositionASpriteSubroutine 
	sec
        sta HMCLR
	sta WSYNC                    ;begin line 1
DivideLoop
	sbc #15
	bcs DivideLoop			;+4/5	 4/ 9.../54

	eor #7				;+2	 6/11.../56
	asl
	asl
	asl
	asl				;+8	14/19.../64

	sta.w HMP0,X			;+5	19/24.../69
        sta RESP0,X     		;+4     23/28/33/38/43/48/53/58/63/68/73
        sta WSYNC      			;+3      0      begin line 2
        sta HMOVE       		;+3
Ret
        rts             ;+6      9

;-------------------------------------------------------------------------
SetTextPointersSubroutine
	ldx #0
	lda TextLineCounter ;input ascii character
	sta Temp
SetCharPtrsLoop
	ldy Temp
	lda (TextBlockPointer),y
	and #$7F
	tay
	lda ASCIILookupTable,y
        asl
        asl
        asl
	sta Char1Ptr,x
	lda #>FontData
	sta Char1Ptr+1,x
        bcc NoCarry
        inc Char1Ptr+1,x
NoCarry
	inx
	inx
	inc Temp
	cpx #24
	bne SetCharPtrsLoop
	rts
        
;-------------------------------------------------------------------------
DrawLineOfTextSubroutine

LF303: STA    HMCLR   
       STA    WSYNC   
	SLEEP 36		;+36	36
       LDX    #RIGHTSEVEN
       LDY    #8    		;+4	40
       LDA    Counter
       AND    #1    		;+5	45
       BEQ    SpritesLeft	;+2	47
       JMP    SpritesRight	;+3	50


LF327: STA    GRP1    	;+3	 9
       LDA    (Char5Ptr),Y 
       STA    GRP0    	;+8	17
       LDA    (Char7Ptr),Y 	;+5	22
       STX    HMP0    
       STX    HMP1    	;+6	28
       STA    GRP1    	;+3	31
       LDA    (Char9Ptr),Y 
       STA    GRP0    	;+8	39
       LDA    (Char11Ptr),Y 
       STA    GRP1    	;+8	47
       STA    GRP0    	;+3	50
SpritesRight
	DEY            
       BEQ    LF37D   	;+4	54

       LDA    (Char2Ptr),Y 
       LSR            
       STA    GRP0    	;+10	64
       LDA    (Char4Ptr),Y 
       LSR
       STA.w  $001C   	;+11	75	GRP1, I assume.
       STA    HMOVE   	;+3	 2	sprites moved right
       LDA    (Char6Ptr),Y 
       LSR            
       STA    GRP0    	;+10	12
       LDA    (Char10Ptr),Y 
       LSR            
       STA    Temp     	;+10	22
       LDA    (Char8Ptr),Y 
       LSR            
       STA    GRP1    	;+10	32
       LDA    Temp     
       STA    GRP0    	;+6	38
       LDA    (Char12Ptr),Y 
       LSR            
       STA    GRP1    	;+10	48
SpritesLeft
	STA    GRP0    	;+3	51
       LDA    #LEFTSEVEN
       STA    HMP0    
       STA    HMP1    	;+8	59
       DEY            
       BEQ    LF387   	;+4	63
       LDA    (Char1Ptr),Y 
       STA    GRP0    	;+8	71
       LDA    (Char3Ptr),Y 	;+5	76
       STA    HMOVE   	;+3	 3	sprites moved left
       JMP    LF327   	;+3	 6

LF37D: STX    HMP0    
       STX    HMP1    
       STA    WSYNC   
       STA    HMOVE   
       BEQ    LF38C   

LF387: STA    WSYNC   
       NOP            
       NOP            
       NOP            

LF38C: LDA    #0    
       STA    GRP0    
       STA    GRP1    
       STA    GRP0    
       RTS            
	
;------------------------------------------------------------------
; Data
;------------------------------------------------------------------
; convert from ascii to internal representation
; maps characters to '_' (41) if we don't have a font glyph
 	org $f480
ASCIILookupTable
	.byte 63,63,63,63,63,63,63,63
	.byte 63,63,63,63,63,63,63,63
	.byte 63,63,63,63,63,63,63,63
	.byte 63,63,63,63,63,63,63,63
	.byte 00,01,02,03,04,05,06,07
	.byte 08,09,10,11,12,13,14,15
	.byte 16,17,18,19,20,21,22,23
	.byte 24,25,26,27,28,29,30,31
	.byte 32,33,34,35,36,37,38,39
	.byte 40,41,42,43,44,45,46,47
	.byte 48,49,50,51,52,53,54,55
	.byte 56,57,58,59,60,61,62,63
	.byte 63,33,34,35,36,37,38,39
	.byte 40,41,42,43,44,45,46,47
	.byte 48,49,50,51,52,53,54,55
	.byte 56,57,58,63,63,63,63,63
	
; 8x8 Font data.
; Beginning must be aligned to page boundary
       org $f500
FontData

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $00 ; |        |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $66 ; | XX  XX |
       .byte $66 ; | XX  XX |
       .byte $66 ; | XX  XX |

       .byte $00 ; |        |
       .byte $28 ; |  X X   |
       .byte $28 ; |  X X   |
       .byte $7C ; | XXXXX  |
       .byte $28 ; |  X X   |
       .byte $7C ; | XXXXX  |
       .byte $28 ; |  X X   |
       .byte $28 ; |  X X   |

       .byte $00 ; |        |
       .byte $18 ; |   XX   |
       .byte $7C ; | XXXXX  |
       .byte $06 ; |     XX |
       .byte $7C ; | XXXXX  |
       .byte $C0 ; |XX      |
       .byte $7C ; | XXXXX  |
       .byte $18 ; |   XX   |

       .byte $00 ; |        |
       .byte $0C ; |    XX  |
       .byte $0C ; |    XX  |
       .byte $70 ; | XXX    |
       .byte $0E ; |    XXX |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $7E ; | XXXXXX |
       .byte $CC ; |XX  XX  |
       .byte $66 ; | XX  XX |
       .byte $38 ; |  XXX   |
       .byte $60 ; | XX     |
       .byte $30 ; |  XX    |
       .byte $0E ; |    XXX |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |

       .byte $00 ; |        |
       .byte $18 ; |   XX   |
       .byte $30 ; |  XX    |
       .byte $60 ; | XX     |
       .byte $60 ; | XX     |
       .byte $60 ; | XX     |
       .byte $30 ; |  XX    |
       .byte $18 ; |   XX   |

       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $30 ; |  XX    |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $30 ; |  XX    |
       .byte $60 ; | XX     |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $66 ; | XX  XX |
       .byte $18 ; |   XX   |
       .byte $7E ; | XXXXXX |
       .byte $7E ; | XXXXXX |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $FC ; |XXXXXX  |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $FC ; |XXXXXX  |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $60 ; | XX     |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $18 ; |   XX   |
       .byte $0C ; |    XX  |
       .byte $0C ; |    XX  |
       .byte $06 ; |     XX |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $E6 ; |XXX  XX |
       .byte $D6 ; |XX X XX |
       .byte $CE ; |XX  XXX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $FC ; |XXXXXX  |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $70 ; | XXX    |
       .byte $30 ; |  XX    |

       .byte $00 ; |        |
       .byte $FE ; |XXXXXXX |
       .byte $E0 ; |XXX     |
       .byte $78 ; | XXXX   |
       .byte $3C ; |  XXXX  |
       .byte $0E ; |    XXX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $06 ; |     XX |
       .byte $3C ; |  XXXX  |
       .byte $18 ; |   XX   |
       .byte $0C ; |    XX  |
       .byte $7E ; | XXXXXX |

       .byte $00 ; |        |
       .byte $0C ; |    XX  |
       .byte $0C ; |    XX  |
       .byte $FE ; |XXXXXXX |
       .byte $CC ; |XX  XX  |
       .byte $6C ; | XX XX  |
       .byte $3C ; |  XXXX  |
       .byte $1C ; |   XXX  |


       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $06 ; |     XX |
       .byte $06 ; |     XX |
       .byte $FC ; |XXXXXX  |
       .byte $C0 ; |XX      |
       .byte $FC ; |XXXXXX  |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FC ; |XXXXXX  |
       .byte $C0 ; |XX      |
       .byte $60 ; | XX     |
       .byte $3C ; |  XXXX  |

       .byte $00 ; |        |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $18 ; |   XX   |
       .byte $0C ; |    XX  |
       .byte $C6 ; |XX   XX |
       .byte $FE ; |XXXXXXX |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $78 ; | XXXX   |
       .byte $0C ; |    XX  |
       .byte $06 ; |     XX |
       .byte $7E ; | XXXXXX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $60 ; | XX     |
       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $60 ; | XX     |
       .byte $00 ; |        |


       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $60 ; | XX     |
       .byte $30 ; |  XX    |
       .byte $00 ; |        |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $02 ; |      X |
       .byte $0C ; |    XX  |
       .byte $30 ; |  XX    |
       .byte $C0 ; |XX      |
       .byte $30 ; |  XX    |
       .byte $0C ; |    XX  |
       .byte $02 ; |      X |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $3C ; |  XXXX  |
       .byte $00 ; |        |
       .byte $3C ; |  XXXX  |
       .byte $00 ; |        |
       .byte $00 ; |        |

       .byte $00 ; |        |
       .byte $80 ; |X       |
       .byte $60 ; | XX     |
       .byte $18 ; |   XX   |
       .byte $06 ; |     XX |
       .byte $18 ; |   XX   |
       .byte $60 ; | XX     |
       .byte $80 ; |X       |

       .byte $00 ; |        |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $00 ; |        |
       .byte $18 ; |   XX   |
       .byte $0C ; |    XX  |
       .byte $66 ; | XX  XX |
       .byte $18 ; |   XX   |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C0 ; |XX      | 
       .byte $CE ; |XX  XXX |
       .byte $D6 ; |XX X XX |
       .byte $CE ; |XX  XXX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FE ; |XXXXXXX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $6C ; | XX XX  |
       .byte $38 ; |  XXX   |

       .byte $00 ; |        |
       .byte $FC ; |XXXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FC ; |XXXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FC ; |XXXXXX  |

       .byte $00 ; |        |
       .byte $3C ; |  XXXX  |
       .byte $66 ; | XX  XX |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $66 ; | XX  XX |
       .byte $3C ; |  XXXX  |

       .byte $00 ; |        |
       .byte $F8 ; |XXXXX   |
       .byte $CC ; |XX  XX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $CC ; |XX  XX  |
       .byte $F8 ; |XXXXX   |

       .byte $00 ; |        |
       .byte $FE ; |XXXXXXX |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $F8 ; |XXXXX   |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $FE ; |XXXXXXX |

       .byte $00 ; |        |
       .byte $C0 ; |XX      | 
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $FC ; |XXXXXX  |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $FE ; |XXXXXXX |

       .byte $00 ; |        |
       .byte $3E ; |  XXXXX |
       .byte $66 ; | XX  XX |
       .byte $C6 ; |XX   XX |
       .byte $CE ; |XX  XXX |
       .byte $C0 ; |XX      |
       .byte $60 ; | XX     |
       .byte $3E ; |  XXXXX |

       .byte $00 ; |        |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FE ; |XXXXXXX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $78 ; | XXXX   |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $78 ; | XXXX   |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $06 ; |     XX |
       .byte $06 ; |     XX |
       .byte $06 ; |     XX |
       .byte $06 ; |     XX |
       .byte $06 ; |     XX |

       .byte $00 ; |        |
       .byte $CE ; |XX  XXX |
       .byte $DC ; |XX XXX  |
       .byte $F8 ; |XXXXX   |
       .byte $F0 ; |XXXX    |
       .byte $D8 ; |XX XX   |
       .byte $CC ; |XX  XX  |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $FE ; |XXXXXXX |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |

       .byte $00 ; |        |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $D6 ; |XX X XX |
       .byte $FE ; |XXXXXXX |
       .byte $FE ; |XXXXXXX |
       .byte $EE ; |XXX XXX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $C6 ; |XX   XX |
       .byte $CE ; |XX  XXX |
       .byte $DE ; |XX XXXX |
       .byte $FE ; |XXXXXXX |
       .byte $F6 ; |XXXX XX |
       .byte $E6 ; |XXX  XX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $C0 ; |XX      |
       .byte $C0 ; |XX      |
       .byte $FC ; |XXXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FC ; |XXXXXX  |

       .byte $00 ; |        |
       .byte $76 ; | XXX XX |
       .byte $CC ; |XX  XX  |
       .byte $DA ; |XX XX X |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $7C ; | XXXXX  |

       .byte $00 ; |        |
       .byte $CE ; |XX  XXX |
       .byte $DC ; |XX XXX  |
       .byte $F8 ; |XXXXX   |
       .byte $CE ; |XX  XXX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $FC ; |XXXXXX  |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $06 ; |     XX |
       .byte $7C ; | XXXXX  |
       .byte $C0 ; |XX      |
       .byte $CC ; |XX  XX  |
       .byte $78 ; | XXXX   |

       .byte $00 ; |        |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $FC ; |XXXXXX  |

       .byte $00 ; |        |
       .byte $7C ; | XXXXX  |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $10 ; |   X    |
       .byte $38 ; |  XXX   |
       .byte $7C ; | XXXXX  |
       .byte $EE ; |XXX XXX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $C6 ; |XX   XX |
       .byte $EE ; |XXX XXX |
       .byte $FE ; |XXXXXXX |
       .byte $FE ; |XXXXXXX |
       .byte $D6 ; |XX X XX |
       .byte $C6 ; |XX   XX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $C6 ; |XX   XX |
       .byte $EE ; |XXX XXX |
       .byte $7C ; | XXXXX  |
       .byte $38 ; |  XXX   |
       .byte $7C ; | XXXXX  |
       .byte $EE ; |XXX XXX |
       .byte $C6 ; |XX   XX |

       .byte $00 ; |        |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $78 ; | XXXX   |
       .byte $CC ; |XX  XX  |
       .byte $CC ; |XX  XX  |
       .byte $CC ; |XX  XX  |

       .byte $00 ; |        |
       .byte $FE ; |XXXXXXX |
       .byte $E0 ; |XXX     |
       .byte $70 ; | XXX    |
       .byte $38 ; |  XXX   |
       .byte $1C ; |   XXX  |
       .byte $0E ; |    XXX |
       .byte $FE ; |XXXXXXX |

       .byte $00 ; |        |
       .byte $38 ; |  XXX   |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $38 ; |  XXX   |

       .byte $00 ; |        |
       .byte $06 ; |     XX |
       .byte $0C ; |    XX  |
       .byte $0C ; |    XX  |
       .byte $18 ; |   XX   |
       .byte $30 ; |  XX    |
       .byte $30 ; |  XX    |
       .byte $60 ; | XX     |

       .byte $00 ; |        |
       .byte $38 ; |  XXX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $18 ; |   XX   |
       .byte $38 ; |  XXX   |

       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $66 ; | XX  XX |
       .byte $3C ; |  XXXX  |
       .byte $18 ; |   XX   |

       .byte $00 ; |        |
       .byte $FE ; |XXXXXXX |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |
       .byte $00 ; |        |

	org $f700
MenuTitle
	.byte 'PLUSCART(+) '
BlankLine
	.byte '            '

; List of directory entries dynamically filled by the cart
	org $f800
ItemsList
	.byte 'COMBAT (PAL)'
	.byte 'TESTING 1   '
	.byte 'TESTING.2   '
	.byte $80+'T','ESTING,3   '
	.byte 'TESTING_4   '
	.byte 'TESTING 5   '
	.byte 'TESTING 6   '
	.byte 'TESTING 7   '
	.byte 'TESTING 8   '
	.byte 'TESTING 9   '
	.byte 'TESTING 10  '
	.byte 'TESTING 11  '
	.byte 'TESTING 12  '
	.byte 'TESTING 13  '
	.byte 'TESTING 14  '
	.byte 'TESTING 15  '
	.byte 'TESTING 16  '
	.byte 'TESTING 17  '
	.byte 'TESTING 18  '
	.byte 'TESTING 19  '
	.byte 'TESTING 20  '
	.byte 'TESTING 21  '
	.byte 'TESTING 22  '
	.byte 'TESTING 23  '
	.byte 'TESTING 24  '
	.byte 'TESTING 25  '
	.byte 'TESTING 26  '
	.byte 'TESTING 27  '
	.byte 'TESTING 28  '
	.byte 'TESTING 29  '
	.byte 0
	.endp
	
;------------------------------------------------------------------
; Atari->Cart Command Area
;------------------------------------------------------------------
	org $fe00
	
;------------------------------------------------------------------
; Status area dynamically filled by the cart
;------------------------------------------------------------------
	org $ffe0
StatusBytes
	.byte 'STATUS MSG..'
	org $ffef
StatusByteReboot
	.byte 0	; tells us to reboot after selecting an item

;------------------------------------------------------------------
; Cartridge Vectors
;------------------------------------------------------------------
	org $fffa		;Cartridge vectors
	.word $ffff		;NMI vector
	.word cart.start	;Reset vector
	.word $ffff		;IRQ vector
