;==========================
; Equates for TIA Registers
;==========================
;----------------------
; Write Address Summary
;----------------------
VSYNC	equ	$00	;Vertical sync set-clear
VBLANK	equ	$01	;Vertical blank set-clear
WSYNC	equ	$02	;Wait for leading edge of horizontal blank
RSYNC	equ	$03	;Reset horizontal sync counter
NUSIZ0	equ	$04	;Number size Player Missile 0
NUSIZ1	equ	$05	;Number size Player Missile 1
COLUP0	equ	$06	;Color-lum Player 0
COLUP1	equ	$07	;Color-lum Player 1
COLUPF	equ	$08	;Color-lum playfield
COLUBK	equ	$09	;Color-lum background
CTRLPF	equ	$0A	;Ctrol playfield ball size & collisions
REFP0	equ	$0B	;Reflect player #0
REFP1	equ	$0C	;Reflect player #1
PF0	equ	$0D	;First 4 bits of playfield
PF1	equ	$0E	;Middle 8 bits of playfield
PF2	equ	$0F	;Last 8 bits of playfield
RESP0	equ	$10	;Reset player #0 X coord
RESP1	equ	$11	;Reset player #1 X coord
RESM0	equ	$12	;Reset missile #0 X coord
RESM1	equ	$13	;Reset missile #1 X coord
RESBL	equ	$14	;Reset ball
AUDC0	equ	$15	;Audio control 0
AUDC1	equ	$16	;Audio control 1
AUDF0	equ	$17	;Audio frequency 0
AUDF1	equ	$18	;Audio frequency 1
AUDV0	equ	$19	;Audio volume 0
AUDV1	equ	$1A	;Audio volume 1
GRP0	equ	$1B	;Pixel data player #0
GRP1	equ	$1C	;Pixel data player #1
ENAM0	equ	$1D	;Missile 0 enable register
ENAM1	equ	$1E	;Missile 1 enable register
ENABL	equ	$1F	;Ball enable register
HMP0	equ	$20	;Horizontal motion Player #0
HMP1	equ	$21	;Horizontal motion Player #1
HMBL	equ	$24	;Horizontal motion Ball
VDELP0	equ	$25
VDELP1	equ	$26
HMOVE	equ	$2A	;Add horizontal motion to registers
HMCLR	equ	$2B	;Clear horizontal motion registers
CXCLR	equ	$2C	;Clear collision registers

;---------------------
; Read Address Summary
;---------------------

CXM0P	equ	$00	;Read collision M0-P1/M0-P0
CXM1P	equ	$01	;Read collision M1-P0/M1-P1
CXP0FB	equ	$02	;Read collision P0-PF/P0-BL
CXP1FB	equ	$03	;Read collision P1-PF/P1-BL
CXM0FB	equ	$04	;Read collision M0-PF/M0-BL
CXM1FB	equ	$05	;Read collision M1-PF/M1-BL
CXBLPF	equ	$06	;Read collision BL-PF/-----
CXPPMM	equ	$07	;Read collision P0-P1/M0-M1
INPT0	equ	$08	;Paddle #0
INPT1	equ	$09	;Paddle #1
INPT2	equ	$0A	;Paddle #2
INPT3	equ	$0B	;Paddle #3
INPT4	equ	$0C	;Misc input #0
INPT5	equ	$0D	;Misc input #1

;======================
; Equates for PIA Ports
;======================
SWCHA	equ	$280
SWACNT	equ	$281
SWCHB	equ	$282
SWBCNT	equ	$283
INTIM	equ	$284
TIM1T	equ	$294
TIM8T	equ	$295
TIM64T	equ	$296
T1024T	equ	$297
