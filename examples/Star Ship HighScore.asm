; Star Ship for the Atari 2600 VCS
;
; Copyright 1978 Atari
; Written by Bob Whitehead
;
; Reverse-Engineered by Manuel Polik (cybergoth@nexgo.de)
; Compiles with DASM
;
; History
; 01.01.2K2     - Started
; 14.01.2K2     - Discovered the frame counter
; 15.01.2K2     - Discovered how game settings work
; 16.01.2K2     - Score calculation
; 29.08.2K2     - Select / Reset routines
; 17.11.2K3     - setting of color schemes 

    include vcs.h
;===============================================================================
; U S E R - C O N S T A N T S
;===============================================================================

PLUSROM          = 1
PAL60		 = 0
NTSC             = 1

   IF PLUSROM
WriteToBuffer     = $1ff0
WriteSendBuffer   = $1ff1
ReceiveBuffer     = $1ff2
ReceiveBufferSize = $1ff3

HIGHSCORE_ID      = 28      ; Star Ship game ID in Highscore DB
   ENDIF



; RAM variables:

frameCounter        = $80   ; is incremented once every frame
binGameVariant      = $83   ; Current game variant in binary Format(0-16)
color1              = $84   ; color
color2              = $85   ; color
color3              = $86   ; color
color4              = $87   ; color

; Variables from $86 to $A2 are inited with raminitblock on startup

bcdGameVariant      = $94   ; Current game variant in BCD Format(1-17)
gameOffBool         = $95   ; 00 Game is is running / FF Game over

leftScoreHigh       =  $9B   ; Pointer to higher nibble of left score
;leftScoreHigh+1     =  $9C
leftScoreLow        =  $9D   ; Pointer to lower nibble of left score
;leftScoreLow+1      =  $9E

; Variables from $9F to $A5 are inited with varinitblock on SELECT

rightScoreHigh      =  $9F   ; Pointer to higher nibble of right score
;rightScoreHigh+1    =  $A0
rightScoreLow       =  $A1   ; Pointer to lower nibble of right score
;rightScoreLow+1     =  $A2

; End of ROM inited block

; End of SELECT inited block

bcdScores1           = $AE   ; Scores of first player
bcdScores2           = $AF   ; Scores of second player

gameSettingBits     = $B4   ; LUNAR/WARP/ENEMIES/X/X/X/X/TWOPLAYER
cycle4Frames        = $B5   ; Counts frames cycling from 0-3 

tempVar2            = $B6   ; various temporary data
tempVar1            = $B7   ; various temporary data

actualPlayer        = $BC   ; X/X/X/X/X/X/X/PLAYER

laserVertPos        = $BF   ; current position of crosshair/laser

CrosshairLeftX      = $D5   ; Horizont. position of left crosshair part
CrosshairRightX     = $D6   ; Horizont. position of right crosshair part

newLaserVertPos     = $DA   ; Next vertical position of crosshair/laser
stackBackUp         = $DB   ; Backup of the stack pointer
gameTimer           = $DC   ; 00 Saver mode / XX Game timer
SELECTTimer         = $DD   ; SELECT is processed when it counted to 00
saverColor          = $DE   ; Value to EOR colors in saver mode
bwState             = $DF   ; Backup of BW-bit

; Begin source

    processor 6502
    ORG $F000

; Init the game

Start
       SEI                      ; Disable interrupts
       CLD                      ; Decimal mode off
       LDA #$10                 ; Useless port direction instructions...
       STA SWBCNT               ; ...on the 2600 (?)
       LDX #$FF                 ;
       TXS                      ; Initialize stack with $FF
       INX                      ; X-> $00
       TXA                      ; A-> $00
ClearRAM   
       STA $82,X                ; 
       INX                      ;
       BNE ClearRAM             ; Clear RAM from $82 to $FF

       LDX #$1C                 ;
ROM2RAMCopy
       LDA raminitblock,X       ;
       STA $86,X                ;
       DEX                      ;
       BPL ROM2RAMCopy          ; Init the RAM from $86 - $A2

       JSR VariantInit          ; Init first variant

;The main game loop starts here, with the VBLANK

MainLoop: 

; Position crosshair
       LDY #$24                 ; Timer value for ~ 4 scanlines
       LDA cycle4Frames         ; A->0-3
       LSR                      ; A->0-1
       ORA #$02                 ; A->2 v 3
       TAX                      ; X->2 v 3 (=> missile 1 v 2!)
       LDA CrosshairRightX      ; A-> x-pos of right crosshair part
       STA WSYNC                ;
       STX VBLANK               ; Start VBLANK
       STY TIM8T                ; Set timer
       JSR PosPlayer            ; Position right crosshair part
       LDA newLaserVertPos      ; Eventually set new vertical pos...
       STA laserVertPos         ; ... of laser/crosshair
       TXA                      ;
       EOR #$01                 ;
       TAX                      ; Swap to other missile
       LDY #$24                 ; Timer value for ~ 4 scanlines

; Seed Random value ????
       LDA $82                  ; ????
       LSR                      ; ????
       ADC #$00                 ; ????
       LSR                      ; ????
       ROR $82                  ; ????
       INC frameCounter         ; ????
       BNE Wait4Lines           ; ????
       INC $82                  ; ????

Wait4Lines: 
       LDA INTIM        
       BNE Wait4Lines           ; Wait until timer expires
       
       LDA CrosshairLeftX       ; A-> x-pos of left crosshair part
       STA WSYNC                ;

       STX VSYNC                ; Start VSYNC
       STY TIM8T                ; Set timer
       JSR PosPlayer            ; Position right crosshair part

; Update timers

       LDA frameCounter         ; A-> frameCounter
       AND #$3F                 ;
       BNE TimersDone           ; 
       INC saverColor           ; Change saverColor every 64 frames
       LDX gameTimer            ; Game running?
       BEQ TimersDone           ; N: Bail Out
       INC gameTimer            ; Y: Increment game time every 64 frames
       BNE GameRuns             ; Game time over? N: Game running
   IF PLUSROM
       JSR SendPlusROMScore
   ELSE
       STX gameOffBool          ; Y: gameOffBool = true
   ENDIF

; Select player 1 or 2

GameRuns: 
       CPX #$7F                 ; Half-time in Two player game?
       ROL                      ; Y: Carry=1 / N: Carry=0
       STA actualPlayer         ; Set correct player!
       LSR                      ; Restore lower bits of frameCounter

TimersDone: 
       AND #$03                 ;
       STA cycle4Frames         ; Set cycle4Frames to next value

Wait4Lines2: 
       LDA INTIM        
       BNE Wait4Lines2          ; Wait until timer expires again

       STA WSYNC                ;
       STA HMOVE                ; Execute horizontal fine-movement
       STA VSYNC                ; Stop VSYNC

       LDA #$FA                 ; 
       STA TIM8T                ; Set Timer for rest VBLANK (~ 26 lines)

; Eventually swap to other player in 2 player mode

       LDA gameTimer            ;
       CMP #$80                 ; First Players time is up?
       BNE NoSwap               ; N: let him go on
       JSR ResetGameData        ; Y: Reset game data
       JSR LF0C7                ; ????
       INC gameTimer            ; Kick off timer for second player
NoSwap:
       LDA SWCHB                ; Read cosole switches
       AND #$03                 ; Mask Reset & Select
       LSR                      ; Select pressed?
       BNE NoSelect             ; N:
       STA gameTimer            ; Y: Clear game timer
       LDA #$FF                 ;
       STA gameOffBool          ; gameOffBool = true
       LDX SELECTTimer          ; Select timer expired?
       BEQ ProcessSelect        ; Y: Process select
       DEX                      ; N: Decrease select timer
       BPL ResetSelectDone      ;   

; Player pressed SELECT, so increment variant and init it

ProcessSelect:
       LDX binGameVariant       ; X-> Binary variant
       LDA bcdGameVariant       ; A-> BCD variant
       CPX #$10                 ; Last variant reached?
       BCC NextVariant          ; N: Next Variant
       LDX #$00                 ; Y: Reset to first variant
       TXA                      ; A-> 00
       DEX                      ; X-> FF
NextVariant: 
       CLC                      ;
       SED                      ;
       ADC #$01                 ; Increment BCD variant
       CLD                      ;
       INX                      ; Increment BIN variant
       STA bcdGameVariant       ; Store BCD variant #
       STX binGameVariant       ; Store BIN variant #
       JSR VariantInit          ; Init new variant
       LDX #$3F                 ; X-> Init select timer
       BNE ResetSelectDone      ; Jump always

; Reset something, most likely the volume on both channels (E0/E2) & ????

LF0C7: LDA #$00                 ; ????
       STA $BB                  ; ????
       LDA #$00                 ; ????
       STA $E0                  ; ????
       LDA #$1F                 ; ????
       STA $E2                  ; ????
       RTS                      ; ????

NoSelect: 
       BCS ClearSelectTimer     ; Reset? N: Clear Select timer

; RESET score(s) and (re)start variant

       LDX #$08                 ; Init score shape pointers...
ClearScores: 
       LDA scoreinitblock,X 
       STA leftScoreHigh-1,X   
       DEX         
       BNE ClearScores          ; ...with void shapes

       STX bcdScores1           ; bcdScores1 -> 0
       STX bcdScores2           ; bcdScores2 -> 0
       LDY #$40    
       STY rightScoreLow        ; display a '0' as score on the right
       LDA gameSettingBits      ; A->gameSettingBits
       LSR                      ; Carry -> 1 v 2 player mode
       TXA                      ; A-> 0
       BCC SinglePlayerReset    ; Two player mode?
       STY leftScoreLow         ; Y: Display a '0' as score for 2nd player
       ROR                      ; A-> $80
SinglePlayerReset: 
       EOR #$81                 ; A-> 01 v 81
       STX gameOffBool          ; gameOffBool-> 0
       STA gameTimer            ; gameTimer-> 01 v 81 (1 v 2 player timer)
       JSR LF0C7                ; ????

ClearSelectTimer: 
       LDX #$00                 ; Clear select timer

ResetSelectDone:
       STX SELECTTimer          ; Set new select timer

       LDX cycle4Frames     
       LDY #$04    
       LDA $B1     
       ASL         
LF105: SEC         
       ROL         
       BCC LF105   
       STA HMCLR   
       STA $81     
       AND #$1C    
       AND frameCounter     
       BNE LF134   
       LDY $90,X   
       LDA gameSettingBits     
       BMI LF130   
       DEY         
       BPL LF130   
       LDY #$1F    
       LDA #$90    
       STA $A6,X   
       STA $AA,X   
       LDA #$4E    
       STA $8C,X   
       DEC $88,X   
       BPL LF130   
       LDA #$03    
       STA $88,X   
LF130: STY $90,X   
       LDY $88,X   
LF134: LDA $AA,X   
       CLC         
       ADC LF7A0,Y 
       STA $AA,X   
       STA $C1     
       LDA $A6,X   
       SEC         
       SBC LF7A0,Y 
       STA $A6,X   
       STA $C0     
       LDA gameSettingBits     
       BPL LF14E   
       LDY #$04    
LF14E: LDA LF77B,Y 
       CPX #$02    
       BCC LF157   
       EOR #$FF    
LF157: ADC $8C,X   
       STA $8C,X   
       LDY $90,X   
       TAX         
       LDA #$00    
       CPY #$0E    
       ROL         
       CPY #$18    
       ADC #$00    
       TAY         
       LDA LF779,Y 
       STA CTRLPF  
       LDA LF7A5,Y 
       STA $D1     
       TXA         
       LDX #$04    
       JSR PosPlayer   
       LDA gameSettingBits     
       AND #$04    
       BEQ LF182   
       STA $C0     
       STA $C1     
LF182: JSR LF622   
       LDA gameSettingBits     
       ASL         
       BPL LF1B5   
       LDA frameCounter     
       ORA gameOffBool     
       AND #$1F    
       ORA $BB     
       BNE LF1B1   
       STA $E3     
       JSR LF464   
       ASL         
       LDA $B1     
       BCS LF1A1   
       LSR         
       BPL LF1A2   
LF1A1: ASL         
LF1A2: AND #$7C    
       BNE LF1A8   
       LDA $B1     
LF1A8: STA $B1     
       ADC $B0     
       STA $B0     
       ROR         
       STA $B2     
LF1B1: LDY #$31    
       BNE LF1FB   
LF1B5: LDA #$04    
       TAX         
       CLC         
       ADC $D3     
       STA CrosshairRightX
       JSR LF574   
       STA CrosshairLeftX     
       INC CrosshairLeftX     
       LDA $D8     
       CLC         
       ADC #$07    
       STA newLaserVertPos     
       LDA gameSettingBits     
       ASL         
       PHP         
       LDY $E3     
       BEQ LF1DD   
       DEC $E3     
       CPY #$28    
       BCS LF1F4   
       LDY #$28    
       BNE LF1F4   
LF1DD: LDY #$31    
       JSR LF464   
       BCC LF1E8   
       STX laserVertPos     
       LDX #$1D    
LF1E8: ASL         
       BCC LF1F4   
       LDA $BB     
       BNE LF1F4   
       DEY         
       STY $E3     
       STX $E1     
LF1F4: PLP         
       BCC LF1FB   
       LDY #$32    
       BNE LF20A   
LF1FB: LDA $F44B,Y 
       STA CrosshairLeftX     
       LDA LF455,Y 
       STA CrosshairRightX     
       LDA LF45F,Y 
       STA newLaserVertPos     
LF20A: LDA LF474,Y 
       STA $D0     
       LDA $F469,Y 
       STA $CC     
       LDA $BB     
       BNE LF21B   
       JSR LF50B   
LF21B: LDX cycle4Frames     
       CPX #$02    
       BCC LF224   
       JMP LF2DA   
LF224: LDA $C8,X   
       AND #$03    
       TAY         
       LDA LF775,Y 
       STA $CA,X   
       SEC         
       SBC #$05    
       STA $CE,X   
       TXA         
       ASL         
       CPY #$01    
       TAY         
       LDA $C8,X   
       AND #$FC    
       BCS LF240   
       ORA #$40    
LF240: ASL            
       STA.wy $0097,Y 
       LDA    $D8,X   
       CLC            
       ADC    $D7     
       STA    $BD,X   
       STA    VDELP0,X
       LDA    #$FF    
       STA    $C2,X   
       LDA    #$01    
       LDY    $CE,X   
       BMI    LF25B   
       BEQ    LF25A   
       ASL            
LF25A: ASL            
LF25B: STA    tempVar1     
       ASL            
       ASL            
       ASL            
       STA    $B8     
       LDA    $D3,X   
       SEC            
       SBC    $D2     
       LDY    $BD,X   
       CPY    #$40    
       BCC    LF27B   
       CPY    #$A1    
       BCS    LF27B   
       CMP    #$20    
       BCC    LF27B   
       CMP    #$60    
       BCS    LF27B   
       STA    $C4,X   
LF27B: LDY    gameSettingBits     
       BMI    LF2A8   
       TAY            
       CMP    #$A0    
       BCS    LF294   
       ADC    $B8     
       CMP    #$9F    
       BCC    LF2A7   
LF28A: ASL    $C2,X   
       SBC    tempVar1     
       CMP    #$9F    
       BCS    LF28A   
       BCC    LF2A7   
LF294: CLC            
       ADC    $B8     
       BMI    LF2B1   
       TYA            
       CLC            
       ADC    #$A0    
       TAY            
LF29E: LSR    $C2,X   
       CLC            
       ADC    tempVar1     
       CMP    #$A0    
       BCC    LF29E   
LF2A7: TYA            
LF2A8: JSR    PosPlayer   
       LDA    $C8,X   
       CMP    #$38    
       BCC    LF2B5   
LF2B1: LDA    #$00    
       STA    $C2,X   
LF2B5: TXA            
       BNE    LF2DA   
       LDA    actualPlayer     
       EOR    #$01    
       TAX            
       LDA    $3C,X ;(INPT4)
       BMI    LF2DA   
       LDA    $C4     
       BEQ    LF2DA   
       LDA    gameSettingBits     
       BMI    LF2DA   
       LSR            
       BCC    LF2DA   
       LDA    $BB     
       SBC    #$01    
       BMI    LF2D6   
       EOR    #$05    
       EOR    actualPlayer     
LF2D6: AND    #$07    
       STA    color1     

; Sound Routines. Any Space Fx is played here

LF2DA: 
       LDX    #$01          ; Both channels are handled
LF2DC: LDY    $E0,X   
       LDA    $E2,X   
       BNE    LF2E7   
       LDY    LF7E7,X 
       STY    $E0,X   
LF2E7: LDA    gameOffBool     
       EOR    #$FF    
       BEQ    LF307   
       LDA    LF720,Y 
       AND    frameCounter     
       BEQ    LF2F6   
       INY            
       INY            
LF2F6: TYA            
       BEQ    LF304   
       TXA            
       LSR            
       BCS    LF304   
       LDA    $E2     
       ASL            
       ASL            
       ASL            
       AND    #$F0    
LF304: ORA    LF721,Y 
LF307: STA    AUDC0,X 
       LSR            
       LSR            
       LSR            
       LSR            
       STA    AUDV0,X 
       LDA    LF722,Y 
       CPY    #$08    
       BCS    LF318   
       LDA    $81,X   
LF318: STA    AUDF0,X 
       DEX            
       BPL    LF2DC   

       LDA gameOffBool      ; A-> 00 v FF
       BNE SaverColorOk     ; Game running?
       STA saverColor       ; Y: Savercolor-> 0

SaverColorOk:
       EOR #$FF             ; N: 2 Useless...
   IF PLUSROM
       NOP
       NOP
   ELSE
       STA SWCHB            ; ...instructions (?)
   ENDIF
       LDA SWCHB            ; Check console switches
       AND #$08             ; Mask B/W-switch
       STA bwState          ; bwState-> 08 v 00
       TAY                  ; B/W mode on?
       BNE ColorMode        ; N: Color mode
       LDA saverColor       ; Y: B/W mode
       AND #$0F             ;
       STA saverColor       ; Saver colors -> B/W

ColorMode: 
       LDX #$01             ; 2 sprites to handle
       INY                  ; 09 v 01
ColorSecond: 
       LDA colorschemes2,Y  ; blue/red v 2 B/W values
       EOR saverColor       ; different color in safer mode
       STA COLUP0,X         ; Set player color
       LDA $CC
       ORA $CA,X   
       STA NUSIZ0,X
       DEY         
       DEX         
       BPL ColorSecond   
LF34C: LDA INTIM   
       BNE LF34C   

; Display kernel starts here

       STA WSYNC            ; Finish current line
       STA HMOVE            ; Execute horizontal move
       STA VBLANK           ; Stop VBLANK
       TSX                  ; X-> Stack pointer
       STX stackBackUp      ; Backup stack pointer
       LDX #$22             ; X-> $22 (Inits linecount)

       LDA frameCounter     ; A-> frameCounter
       ORA #$40             ; Set highest bit (works for both players!)
       AND gameTimer        ; A-> X1XXXXXX & gameTimer
       ASL                  ; A-> 1XXXXXX0 & gameTimer
       CMP #$E0             ; Shall we blink?
       BCS SkipScores       ; Y: Skip Scores

; Draw Score Lines, 5 Scannlines tall

       LDY #$04             ; 5 lines to draw
ScoreLoop: 
       INX                  ; Increment linecount
       CPX #$2B             ; 9 blank lines first
       STA WSYNC            ;
       BCC ScoreLoop        ;
       LDA (leftScoreLow),Y ;
       AND #$0F             ; Extract lower left digit
       STA tempVar1         ;
       LDA (leftScoreHigh),Y;
       AND #$F0             ; Extract higher left digit
       ORA tempVar1         ; Merge digits
       STA PF1              ; Draw left score
       LDA (rightScoreLow),Y;
       AND #$0F             ; Extract lower right digit
       STA tempVar1         ;
       LDA (rightScoreHigh),Y; 
       AND #$F0             ; Extract higher right digit
       ORA tempVar1         ; Merge digits
       STA PF1              ; Draw right score
       TXA                  ;
       LSR                  ; Force 2LK resolution
       BCS ScoreLoop        ;
       DEY                  ; Score done?
       BPL ScoreLoop        ; N: Draw next score line

SkipScores: 
       STX tempVar2         ; Store current linecount temporary
       LDX #$00             ;
       STA WSYNC            ;
       STA HMCLR            ; Clear horizontal motion registers
       STX PF1              ; Clear playfield

; Set colors

SetColorScheme
       LDA color1,X         ; Load colors for P0/P1/PF/BK
       ORA bwState          ; Show BW colors
       TAY                  ;
       LDA colorschemes1,Y   ; A-> color for P0/P1/PF/BK
       EOR saverColor       ;
       STA COLUP0,X         ; Set color
       STA tempVar1,X       ; Store color temporary
       INX                  ;
       CPX #$04             ;
       BCC SetColorScheme   ; Set all 4 colors

       LDY $BB     
       BEQ LF3C6   
       STA.wy $0005,Y 
       LDA.wy $00B6,Y 
       LDY $E4     
       BNE LF3C0   
       LDX $BB     
LF3C0: CPY cycle4Frames     
       BNE LF3C6   
       STA NUSIZ1,X
LF3C6: 
       STY $E4     
       LDX tempVar2     
LF3CA: INX         
       TXA         
       LDX #$1F    
       TXS         
       TAX         
       SEC         
       SBC $BD     
       LSR         
       LDY $CE     
       BMI LF3DC   
       BEQ LF3DB   
       LSR         
LF3DB: LSR         
LF3DC: TAY         
       AND #$78    
       BEQ LF3E5   
       LDA #$00    
       BEQ LF3E7   
LF3E5: LDA ($97),Y 
LF3E7: STA WSYNC   
       AND $C2     
       STA GRP0    
       TXA         
       SEC         
       SBC $C0     
       AND $D1     
       BEQ LF3FB   
       TXA         
       SEC         
       SBC $C1     
       AND $D1     
LF3FB: PHP         
       TXA         
       SEC         
       SBC $BE     
       LSR         
       LDY $CF     
       BMI LF409   
       BEQ LF408   
       LSR         
LF408: LSR         
LF409: TAY         
       AND #$78    
       BEQ LF412   
       LDA #$00    
       BEQ LF414   
LF412: LDA ($99),Y 
LF414: AND $C3     
       STA WSYNC   
       STA GRP1    
       TXA         
       SEC         
       SBC laserVertPos     
       AND $D0     
       PHP         
       PHP         
       INX         
       BNE LF3CA   
       TXA         
       LDY #$04    
LF428: STX GRP0,Y  
       DEY         
       BPL LF428   
       PHA         
       PHA         
       LDX stackBackUp          ; X-> Original STACK value
       TXS                      ; Restore Stack
       JMP MainLoop   

PosPlayer: 
       CLC         
       ADC #$37    
       PHA         
       LSR         
       LSR         
       LSR         
       LSR         
       TAY         
       PLA         
       AND #$0F    
       STY tempVar1     
       CLC         
       ADC tempVar1     
       CMP #$0F    
       BCC LF44D   
       SBC #$0F    
       INY         
LF44D: CMP #$08    
       EOR #$0F    
       BCS LF456   
       ADC #$01    
LF455: DEY         
LF456: ASL         
       ASL         
       ASL         
       ASL         
       STY WSYNC   
LF45C: DEY         
       BPL LF45C   
LF45F: STA RESP0,X 
       STA HMP0,X  
       RTS         

LF464: LDA cycle4Frames     
       BNE LF472   
       LDX actualPlayer     
       LDA $3C,X    ;(INPT4)
       ORA gameOffBool     
       LDX #$18    
       EOR #$FF    
LF472: RTS         

       .byte $4C ; | X  XX  | $F473
LF474: .byte $44 ; | X   X  | $F474
       .byte $3C ; |  XXXX  | $F475
       .byte $34 ; |  XX X  | $F476
       .byte $2C ; |  X XX  | $F477
       .byte $24 ; |  X  X  | $F478
       .byte $1C ; |   XXX  | $F479
       .byte $14 ; |   X X  | $F47A
       .byte $0C ; |    XX  | $F47B
       .byte $48 ; | X  X   | $F47C
       .byte $4F ; | X  XXXX| $F47D
       .byte $57 ; | X X XXX| $F47E
       .byte $5F ; | X XXXXX| $F47F
       .byte $67 ; | XX  XXX| $F480
       .byte $6F ; | XX XXXX| $F481
       .byte $77 ; | XXX XXX| $F482
       .byte $7F ; | XXXXXXX| $F483
       .byte $87 ; |X    XXX| $F484
       .byte $8F ; |X   XXXX| $F485
       .byte $50 ; | X X    | $F486
       .byte $90 ; |X  X    | $F487
       .byte $98 ; |X  XX   | $F488
       .byte $A0 ; |X X     | $F489
       .byte $A8 ; |X X X   | $F48A
       .byte $B0 ; |X XX    | $F48B
       .byte $B8 ; |X XXX   | $F48C
       .byte $C0 ; |XX      | $F48D
       .byte $C8 ; |XX  X   | $F48E
       .byte $D0 ; |XX X    | $F48F
       .byte $90 ; |X  X    | $F490
       .byte $00 ; |        | $F491
       .byte $00 ; |        | $F492
       .byte $00 ; |        | $F493
       .byte $10 ; |   X    | $F494
       .byte $10 ; |   X    | $F495
       .byte $10 ; |   X    | $F496
       .byte $20 ; |  X     | $F497
       .byte $20 ; |  X     | $F498
       .byte $00 ; |        | $F499
       .byte $20 ; |  X     | $F49A
       .byte $00 ; |        | $F49B
       .byte $FE ; |XXXXXXX | $F49C
       .byte $FE ; |XXXXXXX | $F49D
       .byte $FE ; |XXXXXXX | $F49E
       .byte $FC ; |XXXXXX  | $F49F
       .byte $FC ; |XXXXXX  | $F4A0
       .byte $FC ; |XXXXXX  | $F4A1
       .byte $F8 ; |XXXXX   | $F4A2
       .byte $F8 ; |XXXXX   | $F4A3
       .byte $FE ; |XXXXXXX | $F4A4
       .byte $FE ; |XXXXXXX | $F4A5
       .byte $F8 ; |XXXXX   | $F4A6

LF4A7: LDA    $82     
       STA    tempVar1     
       LDA    $C8,X   
       CMP    #$38    
       BCS    LF4CB   
       AND    #$0C    
       LSR            
       LSR            
       STA    color1,X   
       LDA    $B1     
       ADC    $C6,X   
       STA    $C6,X   
       BCC    LF4CF   
       INC    $C8,X   
       LDA    $C8,X   
       AND    #$03    
       BNE    LF4CF   
       LDA    #$38    
       STA    $C8,X   
LF4CB: LDA    #$00    
       STA    $D8,X   
LF4CF: LDA    $C8,X   
       CMP    #$38    
       BCC    LF4FE   
       LDA    $82     
       AND    #$03    
       BNE    LF4FE   
       LDA    gameSettingBits     
       AND    #$08    
       BEQ    LF4E5   
       EOR    $82     
       AND    #$0C    
LF4E5: STA    $C8,X   
       LDA    #$00    
       STA    $C6,X   
LF4EB: LDA    $82     
LF4ED: AND    #$7F    
       SBC    $D7     
       ADC    #$3E    
       STA    $D8,X   
       LDA    $82     
       LSR            
       ADC    $D2     
       ADC    #$0A    
       STA    $D3,X   
LF4FE: LDA    gameSettingBits     
       BPL    LF50A   
       LDA    #$16    
       STA    $C9     
       LDA    #$01    
       STA    color2     
LF50A: RTS            

LF50B: LDX    cycle4Frames
       LDY    cycle4Frames     
       LDA    gameSettingBits     
       BPL    LF514   
       DEY            
LF514: TYA            
       LSR            
       EOR    actualPlayer     
       EOR    #$01    
       AND    #$01    
       TAY            
       CPX    #$02    
       BCC    LF528   
       BNE    LF527   
       LDA    gameSettingBits     
       BPL    LF538   
LF527: RTS            

LF528: LDA    gameSettingBits     
       ASL            
       CPX    #$01    
       BCC    LF530   
       ASL            
LF530: ASL            
       BMI    LF549   
       TYA            
       ORA    #$04    
       STA    color1,X   
LF538: LDA    SWCHA   
       ORA    gameOffBool     
       DEY            
       BMI    LF544   
       ASL            
       ASL            
       ASL            
       ASL            
LF544: STA    tempVar1     
       JMP    LF54C   
LF549: JSR    LF4A7   
LF54C: TXA            
       TAY            
       EOR    frameCounter     
       AND    $A3,X   
       BNE    LF59F   
       LDX    LF7BB,Y 
       TXA            
LF558: ASL    tempVar1     
       BCC    LF564   
       BMI    LF568   
       DEC    $D2,X   
       DEC    $D2,X   
       BCS    LF568   
LF564: INC    $D2,X   
       INC    $D2,X   
LF568: ASL    tempVar1     
       INX            
       INX            
       INX            
       INX            
       INX            
       CPX    #$08    
       BCC    LF558   
       TAX            
LF574: LDA    gameSettingBits     
       BPL    LF59D   
       LDA    $D2,X   
       CMP    #$A0    
       BCC    LF589   
       CMP    #$B4    
       BCS    LF587   
       SBC    #$9F    
       JMP    LF589   
LF587: ADC    #$9F    
LF589: STA    $D2,X   
       LDA    $D7,X   
       CMP    #$28    
       BCC    LF599   
       CMP    #$E8    
       BCC    LF59D   
       ADC    #$3F    
       BPL    LF59B   
LF599: SBC    #$3F    
LF59B: STA    $D7,X   
LF59D: LDA    $D2,X   
LF59F: RTS            

; Calculates and sets a new score & sets the right score pointers too
; Pointers are calculated by a clever multiply with 5 and adding #$40.
; They range in the ROM from F740 to F771.
; in:   A -> Points to be added (0-3)
; in:   X -> Player (0-1)

SetAndCalculateScore:
       SED                      ; Decimal mode
       CLC                      ; 
       ADC bcdScores1,X          ; Add Points
       CLD                      ;
       STA bcdScores1,X          ; Store new score
       LDY #$00                 ;
       CPX #$00                 ;
       BEQ SetLeftPointer       ; Select left (Y->0) or right (Y->4)...
       LDY #$04                 ; ...score pointer, according to #player
SetLeftPointer: 
       LSR                      ;
       LSR                      ;
       LSR                      ;
       LSR                      ; Select higher nibble
       STA tempVar1             ; Store temporary
       ASL                      ; ...
       ASL                      ; ...
       ADC tempVar1             ; Multiply with 5!
       ORA #$40                 ; Add 40!
       STA leftScoreHigh,Y      ; Store high pointer
       LDA bcdScores1,X          ; Reload score
       AND #$0F                 ; Selecet lower nibble
       STA tempVar1             ; Store temporary
       ASL                      ; ...
       ASL                      ; ...
       ADC tempVar1             ; Multiply with 5!
       ORA #$40                 ; Add 40!
       STA leftScoreLow,Y       ;
       RTS

VariantInit
       LDX #$07                 ;
ROM2RAMCopy2
       LDA varinitblock,X       ;
       STA $9E,X                ;
       DEX                      ;
       BNE ROM2RAMCopy2         ; Init variant in RAM from $9F - A5
       LDA bcdGameVariant       ; Write current variant number...
       STA bcdScores1            ; ...into left score
       TXA                      ; A->X->0
       JSR SetAndCalculateScore ; Set variant number in score display

       LDX binGameVariant       ; X->0-16
       LDA gamesettingtab,X     ; A-> settings of actual variant
       STA gameSettingBits      ; store settings
       AND #$01                 ; In single player mode, ...
       EOR #$01                 ; ... start with player = 1...
       STA actualPlayer         ; ... in two player mode with 0...

ResetGameData: 
       LDX #$00                 ; Clear...
       STX $D2                  ; ???? Horizontal movement(?)
       STX $D7                  ; ???? Vertical   movement(?)
       STX $BB                  ;
       JSR LF4EB   
       INX         
       LDA frameCounter     
       JSR LF4ED   
       LDA gameSettingBits     
       LSR         
       LSR         
       LDA #$08    
       BCC LF608   
       ASL         
       ASL         
LF608: STA $B1     
       STA $B3     
       LDX #$14    
       LDY #$16    
       LDA gameSettingBits     
       BMI LF61D   
       LDX #$38    
       LDY #$38    
       LSR         
       BCC LF61D   
       LDX #$1A    
LF61D: STX $C8     
       STY $C9     
       RTS         

LF622: LDA cycle4Frames     
       EOR #$03    
       BNE LF69A   
       DEC $E2     
       BPL LF690   
       INC $E2     
       LDA gameOffBool     
       BNE LF687   
       LDX $BB     
       BEQ LF64D   
       LDY #$38    
       DEX         
       BNE LF647   
       LDA gameSettingBits     
       AND #$20    
       BNE LF647   
       LDA #$1E    
       STA $E2     
       LDY $C8,X   
LF647: TYA         
       JSR LF4E5   
       BNE LF687   
LF64D: LDA gameSettingBits     
       BPL LF65A   
       LDA $32 ;(CXP0FB)
       LDY #$01    
       ASL         
       BPL LF6B0   
       BMI LF675   
LF65A: LDX #$02    
LF65C: LDA #$BF    
       CMP $C5,X   
       BCS LF66E   
       LDA $C7,X   
       ADC #$01    
       AND #$03    
       BNE LF66E   
       LDA $C3,X   
       BNE LF671   
LF66E: DEX         
       BNE LF65C   
LF671: TXA         
       BEQ LF69B   
       TAY         
LF675: LDX actualPlayer     
       LDA $B3     
       STA $B1     
       LDA bcdScores1,X   
       BEQ LF681   
       LDA #$99    
LF681: LDX #$95
       STY $E4     
       BNE LF6F1   
LF687: ASL $B2     
       LDA #$00    
       STA $BB     
       ROL         
       BNE LF6F9   
LF690: STA CXCLR   
       LDA #$00    
       STA $B2     
       STA $C4     
       STA $C5     
LF69A: RTS         

LF69B: LDA gameSettingBits     
       LSR         
       BCC LF6B0   
       LDA $C9     
       EOR #$FF    
       AND #$03    
       BNE LF6B0   
       LDA #$02    
       LDY #$01    
       LDX $37 ;(CXPPMM)
       BMI LF681   
LF6B0: LDA SWCHB   
       LDX actualPlayer     
       BNE LF6B8   
       ASL         
LF6B8: ASL         
       LDA #$07    
       BCS LF6BF   
       LDA #$23    
LF6BF: STA tempVar1     
       LDA $E3     
       BEQ LF687   
       CMP tempVar1     
       BCS LF687   
       LDA $31 ;(CXM1P)
       ASL         
       ASL         
       LDA $31 ;(CXM1P)
       ROR         
       ORA $30 ;(CXM0P)
       ROL         
       ROL         
       ROL         
       LDX gameSettingBits     
       BPL LF6DB   
       AND #$FE    
LF6DB: AND #$03    
       BEQ LF687   
       CMP #$03    
       BNE LF6E5   
       LDA #$02    
LF6E5: TAY         
       LDA.wy $00C7,Y 
       LSR            
       LSR            
       AND    #$03    
       BEQ    LF687   
       LDX    #$90    
LF6F1: STY    $BB     
       STX    $E0     
       LDX    #$1F    
       STX    $E2     
LF6F9: LDX    actualPlayer     
       JSR    SetAndCalculateScore   
       BNE    LF690   
       PHP            
       .byte $42 ;.JAM
       BPL    LF709   
       LDY    #$08    
       .byte $42 ;.JAM
       BPL    LF709   
LF709: RTS            

       .byte $F0 ; |XXXX    | $F70A
       .byte $FF ; |XXXXXXXX| $F70B
       .byte $66 ; | XX  XX | $F70C
       .byte $0C ; |    XX  | $F70D
       .byte $1F ; |   XXXXX| $F70E
       .byte $00 ; |        | $F70F
       .byte $00 ; |        | $F710
       .byte $00 ; |        | $F711
       .byte $18 ; |   XX   | $F712
       .byte $3C ; |  XXXX  | $F713
       .byte $FF ; |XXXXXXXX| $F714
       .byte $7E ; | XXXXXX | $F715
       .byte $00 ; |        | $F716
       .byte $00 ; |        | $F717
       .byte $24 ; |  X  X  | $F718
       .byte $18 ; |   XX   | $F719
       .byte $3C ; |  XXXX  | $F71A
       .byte $BF ; |X XXXXXX| $F71B
       .byte $FD ; |XXXXXX X| $F71C
       .byte $3C ; |  XXXX  | $F71D
       .byte $5A ; | X XX X | $F71E
       .byte $C3 ; |XX    XX| $F71F
LF720: .byte $00 ; |        | $F720
LF721: .byte $23 ; |  X   XX| $F721
LF722: .byte $00 ; |        | $F722
       .byte $A6 ; |X X  XX | $F723
       .byte $64 ; | XX  X  | $F724
       .byte $00 ; |        | $F725
       .byte $00 ; |        | $F726
       .byte $00 ; |        | $F727
       .byte $18 ; |   XX   | $F728
       .byte $7E ; | XXXXXX | $F729
       .byte $5B ; | X XX XX| $F72A
       .byte $F7 ; |XXXX XXX| $F72B
       .byte $BF ; |X XXXXXX| $F72C
       .byte $F6 ; |XXXX XX | $F72D
       .byte $7C ; | XXXXX  | $F72E
       .byte $18 ; |   XX   | $F72F
       .byte $C6 ; |XX   XX | $F730
       .byte $D6 ; |XX X XX | $F731
       .byte $38 ; |  XXX   | $F732
       .byte $FE ; |XXXXXXX | $F733
       .byte $7C ; | XXXXX  | $F734
       .byte $10 ; |   X    | $F735
       .byte $10 ; |   X    | $F736
       .byte $00 ; |        | $F737
       .byte $01 ; |       X| $F738
       .byte $00 ; |        | $F739
       .byte $00 ; |        | $F73A
       .byte $81 ; |X      X| $F73B
       .byte $00 ; |        | $F73C
       .byte $00 ; |        | $F73D
       .byte $88 ; |X   X   | $F73E
       .byte $14 ; |   X X  | $F73F

       .byte $07 ; |     XXX| $F740
       .byte $05 ; |     X X| $F741
       .byte $05 ; |     X X| $F742
       .byte $05 ; |     X X| $F743
       .byte $07 ; |     XXX| $F744

       .byte $11 ; |   X   X| $F745
       .byte $11 ; |   X   X| $F746
       .byte $11 ; |   X   X| $F747
       .byte $11 ; |   X   X| $F748
       .byte $11 ; |   X   X| $F749

       .byte $77 ; | XXX XXX| $F74A
       .byte $44 ; | X   X  | $F74B
       .byte $77 ; | XXX XXX| $F74C
       .byte $11 ; |   X   X| $F74D
       .byte $77 ; | XXX XXX| $F74E

       .byte $77 ; | XXX XXX| $F74F
       .byte $11 ; |   X   X| $F750
       .byte $33 ; |  XX  XX| $F751
       .byte $11 ; |   X   X| $F752
       .byte $77 ; | XXX XXX| $F753

       .byte $11 ; |   X   X| $F754
       .byte $11 ; |   X   X| $F755
       .byte $77 ; | XXX XXX| $F756
       .byte $55 ; | X X X X| $F757
       .byte $55 ; | X X X X| $F758

       .byte $77 ; | XXX XXX| $F759
       .byte $11 ; |   X   X| $F75A
       .byte $77 ; | XXX XXX| $F75B
       .byte $44 ; | X   X  | $F75C
       .byte $77 ; | XXX XXX| $F75D

       .byte $77 ; | XXX XXX| $F75E
       .byte $55 ; | X X X X| $F75F
       .byte $77 ; | XXX XXX| $F760
       .byte $44 ; | X   X  | $F761
       .byte $77 ; | XXX XXX| $F762

       .byte $11 ; |   X   X| $F763
       .byte $11 ; |   X   X| $F764
       .byte $11 ; |   X   X| $F765
       .byte $11 ; |   X   X| $F766
       .byte $77 ; | XXX XXX| $F767

       .byte $77 ; | XXX XXX| $F768
       .byte $55 ; | X X X X| $F769
       .byte $77 ; | XXX XXX| $F76A
       .byte $55 ; | X X X X| $F76B
       .byte $77 ; | XXX XXX| $F76C

       .byte $77 ; | XXX XXX| $F76D
       .byte $11 ; |   X   X| $F76E
       .byte $77 ; | XXX XXX| $F76F
       .byte $55 ; | X X X X| $F770
       .byte $77 ; | XXX XXX| $F771

       .byte $00 ; |        | $F772
       .byte $00 ; |        | $F773
       .byte $00 ; |        | $F774
LF775: .byte $00 ; |        | $F775
       .byte $00 ; |        | $F776

       .byte $05 ; |     X X| $F777
       .byte $07 ; |     XXX| $F778
LF779: .byte $22 ; |  X   X | $F779
       .byte $12 ; |   X  X | $F77A
LF77B: .byte $02 ; |      X | $F77B
       .byte $02 ; |      X | $F77C
       .byte $01 ; |       X| $F77D
       .byte $01 ; |       X| $F77E
       .byte $00 ; |        | $F77F
       .byte $50 ; | X X    | $F780
       .byte $A0 ; |X X     | $F781
       .byte $50 ; | X X    | $F782
       .byte $A0 ; |X X     | $F783
       .byte $00 ; |        | $F784
       .byte $00 ; |        | $F785
       .byte $00 ; |        | $F786
       .byte $00 ; |        | $F787
       .byte $80 ; |X       | $F788
       .byte $F0 ; |XXXX    | $F789
       .byte $20 ; |  X     | $F78A
       .byte $70 ; | XXX    | $F78B
       .byte $00 ; |        | $F78C
       .byte $00 ; |        | $F78D
       .byte $00 ; |        | $F78E
       .byte $00 ; |        | $F78F
       .byte $00 ; |        | $F790
       .byte $60 ; | XX     | $F791
       .byte $F0 ; |XXXX    | $F792
       .byte $00 ; |        | $F793
       .byte $00 ; |        | $F794
       .byte $00 ; |        | $F795
       .byte $00 ; |        | $F796
       .byte $00 ; |        | $F797
       .byte $40 ; | X      | $F798
       .byte $E0 ; |XXX     | $F799
       .byte $40 ; | X      | $F79A
       .byte $A0 ; |X X     | $F79B
       .byte $00 ; |        | $F79C
       .byte $00 ; |        | $F79D
       .byte $00 ; |        | $F79E
       .byte $00 ; |        | $F79F
LF7A0: .byte $01 ; |       X| $F7A0
       .byte $02 ; |      X | $F7A1
       .byte $03 ; |      XX| $F7A2
       .byte $04 ; |     X  | $F7A3
       .byte $00 ; |        | $F7A4
LF7A5: .byte $F8 ; |XXXXX   | $F7A5
       .byte $FC ; |XXXXXX  | $F7A6
       .byte $FE ; |XXXXXXX | $F7A7
       .byte $C0 ; |XX      | $F7A8
       .byte $C2 ; |XX    X | $F7A9
       .byte $3E ; |  XXXXX | $F7AA
       .byte $2C ; |  X XX  | $F7AB
       .byte $7E ; | XXXXXX | $F7AC
       .byte $42 ; | X    X | $F7AD
       .byte $42 ; | X    X | $F7AE
       .byte $E7 ; |XXX  XXX| $F7AF
       .byte $02 ; |      X | $F7B0
       .byte $01 ; |       X| $F7B1
       .byte $02 ; |      X | $F7B2
       .byte $01 ; |       X| $F7B3
       .byte $03 ; |      XX| $F7B4
       .byte $00 ; |        | $F7B5
       .byte $08 ; |    X   | $F7B6
       .byte $0C ; |    XX  | $F7B7

; Next 19 bytes init the RAM from $86 to $A2

raminitblock

       .byte $06 ; |     XX | $F7B8
       .byte $07 ; |     XXX| $F7B9
       .byte $03 ; |      XX| $F7BA
LF7BB: .byte $01 ; |       X| $F7BB
       .byte $02 ; |      X | $F7BC
       .byte $00 ; |        | $F7BD
       .byte $48 ; | X  X   | $F7BE
       .byte $40 ; | X      | $F7BF
       .byte $4E ; | X  XXX | $F7C0
       .byte $58 ; | X XX   | $F7C1
       .byte $07 ; |     XXX| $F7C2
       .byte $17 ; |   X XXX| $F7C3
       .byte $0F ; |    XXXX| $F7C4
       .byte $1F ; |   XXXXX| $F7C5

       .byte $01    ; Start with game variant 1
       .byte $FF    ; Start with gameOffBool = true

       .byte $03 ; |      XX| $F7C8
       .byte $00 ; |        | $F7C9
       .byte $F7 ; |XXXX XXX| $F7CA
       .byte $00 ; |        | $F7CB

scoreinitblock
        .byte $F7 ; |XXXX XXX| $F7CC

; Next 8 bytes init the score pointers with void shapes RESET is pressed
       .word $F772  ; Start/RESET with left score blanked
       .byte $72    ; Start/RESET with left score blanked

varinitblock
       .byte $F7    ; Start with left score blanked 

; Next 7 bytes init the RAM from $9F to $A5 when SELECT is pressed
       .word $F772  ; Start/SELECT/RESET with right score blanked
       .word $F772  ; Start/SELECT/RESET with right score blanked
; End of raminitblock / scoreinitblock

       .byte $04 ; |     X  | $F7D5
       .byte $0C ; |    XX  | $F7D6
       .byte $00 ; |        | $F7D7
; End of varinitblock


; 8 B/W values and 8 color values.
colorschemes1
       .byte $0A ; |    X X | $F7D8
       .byte $0A ; |    X X | $F7D9
       .byte $08 ; |    X   | $F7DA
       .byte $08 ; |    X   | $F7DB
colorschemes2
       .byte $0C ; |    XX  | $F7DC
       .byte $06 ; |     XX | $F7DD
       .byte $0C ; |    XX  | $F7DE
       .byte $00 ; |        | $F7DF

  IF PAL60
       .byte $48
       .byte $28
       .byte $D6
       .byte $86
       .byte $66
       .byte $96
  ELSE
       .byte $38 ; |  XXX   | $F7E0
       .byte $E8 ; |XXX X   | $F7E1
       .byte $86 ; |X    XX | $F7E2
       .byte $56 ; | X X XX | $F7E3
       .byte $46 ; | X   XX | $F7E4
       .byte $A6 ; |X X  XX | $F7E5
  ENDIF  
       .byte $0E ; |    XXX | $F7E6
LF7E7: .byte $00 ; |        | $F7E7
       .byte $03 ; |      XX| $F7E8


gamesettingtab: 
;                            L        
;                            U        
;                            NW        
;                            AA     T  
;                            RR     W  
;                             PE    O 
;                            L N    P 
;                            ADE    L  
;                            NRM    A   
;                            DII    Y   
;                            EVE    E   
;                            RES    R   
                .byte $38 ; |  XXX   | Variant 01
                .byte $28 ; |  X X   | Variant 02
                .byte $2A ; |  X X X | Variant 03
                .byte $3A ; |  XXX X | Variant 04
                .byte $0B ; |    X XX| Variant 05
                .byte $11 ; |   X   X| Variant 06
                .byte $13 ; |   X  XX| Variant 07
                .byte $19 ; |   XX  X| Variant 08
                .byte $1B ; |   XX XX| Variant 09
                .byte $60 ; | XX     | Variant 10
                .byte $70 ; | XXX    | Variant 11
                .byte $94 ; |X  X X  | Variant 12
                .byte $90 ; |X  X    | Variant 13
                .byte $92 ; |X  X  X | Variant 14
                .byte $85 ; |X    X X| Variant 15
                .byte $81 ; |X      X| Variant 16
                .byte $83 ; |X     XX| Variant 17
  IF PLUSROM
PlusROM_API
	.byte "a", 0, "h.firmaplus.de", 0
SendPlusROMScore:
	STX gameOffBool          ; Y: gameOffBool = true
        CPX #$7F                 ; Half-time in Two player game?
        BEQ returnFromSend

	lda bcdGameVariant       ; BCD game variation (1-17)
	sta WriteToBuffer
	lda SWCHB
	sta WriteToBuffer
	lda bcdScores2           ; BCD score
	sta WriteToBuffer
	lda #HIGHSCORE_ID        ; game id in Highscore DB
	sta WriteSendBuffer
returnFromSend
        RTS
 


	ORG $FFFA

        .word (PlusROM_API-$E000)
        .word Start
        .word Start
  ELSE
        ORG $F7FA

        .word Start
        .word Start
        .word Start
  ENDIF