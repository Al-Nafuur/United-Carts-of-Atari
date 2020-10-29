;   LIST OFF                         ; don't print the header file equates or
                                    ; comments in the list file
; Pacman4K
; Copyright 2007 Dennis Debro
; V1.1 Completed: 2007/03/12
;
; V1.2 Completed: 2014/09/18
;
; dasm source.s -f3 -osource.bin to compile
;
; Tested with...
;     Z26
;     Stella 1.2
;     Atari2600 (CX2600A) via MaxiCart v1.0
;     Atari7800 via CuttleCartII
;
; AtariAge build stats...
; *** 123 BYTES OF RAM USED 5 BYTES FREE
; ***  40 BYTES OF ROM FREE
;
; Self publish build stats...
; *** 123 BYTES OF RAM USED 5 BYTES FREE
; ***  42 BYTES OF ROM FREE
;
; Pac-Man® & © of NAMCO LTD., ALL RIGHTS RESERVED.
; This project is not endourced by Namco in any way. This project was done by an
; individual that liked Pac-man and wanted to see a faithful version created for the
; Atari2600.
;
; Hopefully you will have as much fun playing it or learning from the source as I had
; creating this game.
;
; Pacman4K source code and assembled binaries have been released for educational
; purposes only. It cannot be sold or made into cartridges without authorization from
; the author. If you find something useful in the code that you would like to use, all
; I ask is that you give credit from the source you pulled it from.
; =====================================================================================
;
; Pacman4K started out as a challenge for me to see if I could get a no frills Pac-man
; written for the 2600 in 4K and stay faithful to the original arcade game. I made
; some sacrifices along the way. Most noticeable was the decision to flicker the
; objects at a rate of 20Hz instead of developing a variable flicker algorithm. I did
; some work in this direction but found that it took up too much ROM to include the
; other features.
;
; Ebivision did a 4K Pac-man back in 1999. You can see pictures of their work at
; http://www.atariage.com/software_page.html?SoftwareLabelID=1022
; and short video clips of it running while at the 1999 Classic Gaming Expo at
; http://www.cyberroach.com/cyromag/six/cge991.htm
; I commend them for their work as this was a basis for my maze layout. They were able
; to do their game without using any undocumented 6502 opcodes. I used undocumented
; opcodes to reduce ROM and to help in kernel timing. Hats off to you Ebivision!
;
; I also had some help in the testing department thanks to John Champeau, Robert
; DeCrescenzo, and Tony Wong. I would send ROMs to them as this project was nearing
; completion. They were kind enough to give me their feedback and report bugs I missed.
; Robert also sent me sound data from his 7800 Pac-man collection to help me in the TIA
; department. If you have an Atari7800 and would like a Pac-man game for it then visit
; the AtariAge store at
; http://www.atariage.com/store/index.php?main_page=product_info&products_id=849
;
; The monster and Pac-man graphics were supplied by Stefan Haddewig (Retrofan) of
; AtariAge. I had originally gone with monster graphics that were supplied by Clay
; Halliwell (ZylonBane) of AtariAge. Clay's graphics were more of a cartoon type of
; look. A poll was conducted on AtariAge and the members of the message board voted
; that they preferred the A8/5200 look of the monsters so I changed them.
;
; The game siren was taken from "A Better Pac-man" by Rob Kudla. Check out his hack at
; http://www.kudla.org/raindog/pac26.html. I checked with Rob to see if it was okay for
; me to use his data and he was fine with it. Thanks Rob, I think your siren sounds are
; perfect.
;
; I released a number of demos on the AtariAge forum. One ask I received was to speed
; up the movement. The movement calculations were based on the frame delay values I had
; received from Eduardo Mello and doing frame delay calculations based on the 7800
; version of Ms. Pac-man. I prefered the original movement values but increased them to
; satsify the players on AtariAge. You can manipulate the speed of your assembly by
; setting the FASTER_SPEED assembler switch below. Setting this to TRUE will increase
; the original speeds by roughly 14%.
;
; I originally didn't have enough ROM to implement the speed differences using the
; difficulty switches. It may be possible now that ROM has been reclaimed with
; version 1.2
;
; =====================================================================================
; Version 1.1 Notes
;
; Minor changes with this version. A compiler switch was added to build an AtariAge
; exclusive edition. The original flagship was modified to be the AtariAge logo. The
; startup tune was added too.
;
; I had e-mail conversations is Kurt Howe (Nukey Shay) of AtariAge on how to squeeze
; in the bytes. He convinced me to use the LSB data of the PF0 graphic data to hold the
; bytes. I then added a baseline to the routine. I'm not too god in the TIA sound
; department but I think it turned out well.
;
; Unfortunately the sound is dependent on the frame count. This will cause the startup
; tune to be slower on PAL50 configurations than on the NTSC configuration.
;
; =====================================================================================
; Version 1.2 Notes
;
; Thomas Jentzsch took a look at the source and pointed out more byte savings. He also
; had a look at the monster AI. The monster AI has been modified to better mimic the
; arcade game.
;
; At the time I completed the first version the Pac-man Dossier hadn't been created or
; I didn't know about it. This can be found at
; http://home.comcast.net/~jpittman2/pacman/pacmandossier.html. This is an excellent
; write up of Pac-man and how the monsters behave.
;
; My first attempt was close however Thomas used the Pac-man Dossier to have monsters
; target tiles like the arcade instead of the pixels I originally had. Now the game
; feels right. Thanks Thomas!
;
; The source code was also cleaned up for release to the public. Hopefully everything
; is commented to the point that the source is easy to understand.
;
; I also found three bugs in the first version while working in Thomas' additions. They
; are...
;     (1) The SELF published version would show a garbled graphic during Pac-man death
;        - This wasn't seen in the AtariAge released version so no carts were affected
;        - It was caused by the graphics sitting too high on a page
;     (2) Startup tune could play when player RESET game after eating a bonus fruit
;        - This would happen if the player ate a bonus fruit and REST the game before
;           touching a monster
;        - Player could move in the maze while the startup tune played
;     (3) Pac-man could pass through a monster while eating bonus fruit
;        - This happens if Pac-man collided with a monster while the fruit sound was
;           still playing

   processor 6502

   LIST ON

   include macro.h
   include "tia_constants.h"
   include vcs.h

;
; Make sure we are using macro.h version 1.06 or greater.
;
   IF VERSION_MACRO < 106

      echo ""
      echo "*** ERROR: macro.h file *must* be version 1.06 or higher!"
      echo ""
      err

   ENDIF

;======================================================================================
; A S S E M B L E R - S W I T C H E S
;======================================================================================

NTSC                    = 0
PAL50                   = 1
PAL60                   = 2

TRUE                    = 1
FALSE                   = 0

PLUSROM                 = 1

;
; publisher values
;
ATARIAGE                = 0
SELF                    = 1

PUBLISHER               = SELF      ; set the publisher of the game for publisher
                                    ; defined ROMs
COMPILE_VERSION         = NTSC      ; change this to compile for different
                                    ; regions -- this changes colors and display timing
                                    ; (NTSC 60 FPS -or- PAL50 50 FPS -or- PAL60 60 FPS)
CHEAT_ENABLE            = FALSE     ; set to TRUE to enable cheat (no death collisions)
FASTER_SPEED            = FALSE     ; set to FALSE for original speed
                                    ; set to TRUE for faster speed (~14% increase)

;======================================================================================
; F R A M E  T I M I N G S
;======================================================================================

   IF COMPILE_VERSION = NTSC || COMPILE_VERSION = PAL60

FPS                     = 60        ; ~60 frames per second
VBLANK_TIME             = 45        ; vertical blanking time for 60 FPS
OVERSCAN_TIME           = 31        ; overscan time for 60 FPS
;
; game speed values
;
   IF FASTER_SPEED

SPEED_PACMAN_NORMAL_1   = $92       ; 4 / 7 pixels per frame
SPEED_PACMAN_NORMAL_2   = $A6       ; 83 / 128 pixels per frame
SPEED_PACMAN_NORMAL_3   = $B6       ; 91 / 128 pixels per frame
SPEED_PACMAN_NORMAL_4   = $A6       ; 83 / 128 pixels per frame

SPEED_PACMAN_BLUE_1     = $A6       ; 83 / 128 pixels per frame
SPEED_PACMAN_BLUE_2     = $AD       ; 173 / 256 pixels per frame
SPEED_PACMAN_BLUE_3     = $B6       ; 91 / 128 pixels per frame
SPEED_PACMAN_BLUE_4     = $A6       ; 83 / 128 pixels per frame

SPEED_MONSTER_NORMAL_1  = $7C       ; 31 / 64 pixels per frame
SPEED_MONSTER_NORMAL_2  = $9E       ; 79 / 128 pixels per frame
SPEED_MONSTER_NORMAL_3  = $AC       ; 43 / 64 pixels per frame
SPEED_MONSTER_NORMAL_4  = $AC       ; 43 / 64 pixels per frame

SPEED_MONSTER_BLUE_1    = $60       ; 3 / 8 pixels per frame
SPEED_MONSTER_BLUE_2    = $68       ; 13 / 32 pixels per frame
SPEED_MONSTER_BLUE_3    = $6D       ; 109 / 256 pixels per frame
SPEED_MONSTER_BLUE_4    = $51       ; 81 / 256 pixels per frame

SPEED_MONSTER_SLOW_1    = $49       ; 73 / 256 pixels per frame
SPEED_MONSTER_SLOW_2    = $51       ; 81 / 256 pixels per frame
SPEED_MONSTER_SLOW_3    = $60       ; 3 / 8 pixels per frame
SPEED_MONSTER_SLOW_4    = $60       ; 3 / 8 pixels per frame

SPEED_CRUISE_ELROY1_1   = $92       ; 4 / 7 pixels per frame
SPEED_CRUISE_ELROY1_2   = $A6       ; 83 / 128 pixels per frame
SPEED_CRUISE_ELROY1_3   = $B6       ; 91 / 128 pixels per frame
SPEED_CRUISE_ELROY1_4   = $B6       ; 91 / 128 pixels per frame

SPEED_CRUISE_ELROY2_1   = $9E       ; 79 / 128 pixels per frame
SPEED_CRUISE_ELROY2_2   = $AC       ; 43 / 64 pixels per frame
SPEED_CRUISE_ELROY2_3   = $C0       ; 3 / 4 pixels per frame
SPEED_CRUISE_ELROY2_4   = $C0       ; 3 / 4 pixels per frame

   ELSE

SPEED_PACMAN_NORMAL_1   = $80       ; 1 / 2 pixels per frame
SPEED_PACMAN_NORMAL_2   = $92       ; 4 / 7 pixels per frame
SPEED_PACMAN_NORMAL_3   = $A0       ; 5 / 8 pixels per frame
SPEED_PACMAN_NORMAL_4   = $92       ; 4 / 7 pixels per frame

SPEED_PACMAN_BLUE_1     = $92       ; 4 / 7 pixels per frame
SPEED_PACMAN_BLUE_2     = $98       ; 19 / 32 pixels per frame
SPEED_PACMAN_BLUE_3     = $A0       ; 5 / 8 pixels per frame
SPEED_PACMAN_BLUE_4     = $92       ; 4 / 7 pixels per frame

SPEED_MONSTER_NORMAL_1  = $6D       ; 3 / 7 pixels per frame
SPEED_MONSTER_NORMAL_2  = $8B       ; 6 / 11 pixels per frame
SPEED_MONSTER_NORMAL_3  = $98       ; 3 / 5 pixels per frame
SPEED_MONSTER_NORMAL_4  = $98       ; 3 / 5 pixels per frame

SPEED_MONSTER_BLUE_1    = $55       ; 1 / 3 pixels per frame
SPEED_MONSTER_BLUE_2    = $5C       ; 9 / 25 pixels per frame
SPEED_MONSTER_BLUE_3    = $60       ; 3 / 8 pixels per frame
SPEED_MONSTER_BLUE_4    = $48       ; 9 / 32 pixels per frame

SPEED_MONSTER_SLOW_1    = $40       ; 1 / 4 pixels per frame
SPEED_MONSTER_SLOW_2    = $48       ; 9 / 32 pixels per frame
SPEED_MONSTER_SLOW_3    = $55       ; 1 / 3 pixels per frame
SPEED_MONSTER_SLOW_4    = $55       ; 1 / 3 pixels per frame

SPEED_CRUISE_ELROY1_1   = $80       ; 1 / 2 pixels per frame
SPEED_CRUISE_ELROY1_2   = $92       ; 4 / 7 pixels per frame
SPEED_CRUISE_ELROY1_3   = $A0       ; 5 / 8 pixels per frame
SPEED_CRUISE_ELROY1_4   = $A0       ; 5 / 8 pixels per frame

SPEED_CRUISE_ELROY2_1   = $8B       ; 6 / 11 pixels per frame
SPEED_CRUISE_ELROY2_2   = $98       ; 3 / 5 pixels per frame
SPEED_CRUISE_ELROY2_3   = $AA       ; 2 / 3 pixels per frame
SPEED_CRUISE_ELROY2_4   = $AA       ; 2 / 3 pixels per frame

   ENDIF                            ; NTSC and PAL60 game speed values

   ELSE

FPS                     = 50        ; ~50 frames per second
VBLANK_TIME             = 67        ; vertical blanking time for 50 FPS
OVERSCAN_TIME           = 69        ; overscan time for 50 FPS
;
; game speed values
;
   IF FASTER_SPEED

SPEED_PACMAN_NORMAL_1   = $AF       ; 4 / 7 pixels per frame
SPEED_PACMAN_NORMAL_2   = $C7       ; 83 / 128 pixels per frame
SPEED_PACMAN_NORMAL_3   = $DA       ; 91 / 128 pixels per frame
SPEED_PACMAN_NORMAL_4   = $C7       ; 83 / 128 pixels per frame

SPEED_PACMAN_BLUE_1     = $C7       ; 83 / 128 pixels per frame
SPEED_PACMAN_BLUE_2     = $CF       ; 173 / 256 pixels per frame
SPEED_PACMAN_BLUE_3     = $DA       ; 91 / 128 pixels per frame
SPEED_PACMAN_BLUE_4     = $C7       ; 83 / 128 pixels per frame

SPEED_MONSTER_NORMAL_1  = $94       ; 31 / 64 pixels per frame
SPEED_MONSTER_NORMAL_2  = $BD       ; 79 / 128 pixels per frame
SPEED_MONSTER_NORMAL_3  = $CE       ; 43 / 64 pixels per frame
SPEED_MONSTER_NORMAL_4  = $CE       ; 43 / 64 pixels per frame

SPEED_MONSTER_BLUE_1    = $73       ; 3 / 8 pixels per frame
SPEED_MONSTER_BLUE_2    = $7C       ; 13 / 32 pixels per frame
SPEED_MONSTER_BLUE_3    = $82       ; 3 / 7 pixels per frame
SPEED_MONSTER_BLUE_4    = $61       ; 81 / 256 pixels per frame

SPEED_MONSTER_SLOW_1    = $57       ; 73 / 256 pixels per frame
SPEED_MONSTER_SLOW_2    = $61       ; 81 / 256 pixels per frame
SPEED_MONSTER_SLOW_3    = $73       ; 3 / 8 pixels per frame
SPEED_MONSTER_SLOW_4    = $73       ; 3 / 8 pixels per frame

SPEED_CRUISE_ELROY1_1   = $AF       ; 4 / 7 pixels per frame
SPEED_CRUISE_ELROY1_2   = $C7       ; 83 / 128 pixels per frame
SPEED_CRUISE_ELROY1_3   = $DA       ; 91 / 128 pixels per frame
SPEED_CRUISE_ELROY1_4   = $DA       ; 91 / 128 pixels per frame

SPEED_CRUISE_ELROY2_1   = $BD       ; 79 / 128 pixels per frame
SPEED_CRUISE_ELROY2_2   = $DA       ; 91 / 128 pixels per frame
SPEED_CRUISE_ELROY2_3   = $E6       ; 3 / 4 pixels per frame
SPEED_CRUISE_ELROY2_4   = $E6       ; 3 / 4 pixels per frame

   ELSE

SPEED_PACMAN_NORMAL_1   = $99       ; 1 / 2 pixels per frame
SPEED_PACMAN_NORMAL_2   = $AF       ; 4 / 7 pixels per frame
SPEED_PACMAN_NORMAL_3   = $C0       ; 5 / 8 pixels per frame
SPEED_PACMAN_NORMAL_4   = $AF       ; 4 / 7 pixels per frame

SPEED_PACMAN_BLUE_1     = $AF       ; 4 / 7 pixels per frame
SPEED_PACMAN_BLUE_2     = $B6       ; 19 / 32 pixels per frame
SPEED_PACMAN_BLUE_3     = $C0       ; 5 / 8 pixels per frame
SPEED_PACMAN_BLUE_4     = $AF       ; 4 / 7 pixels per frame

SPEED_MONSTER_NORMAL_1  = $82       ; 3 / 7 pixels per frame
SPEED_MONSTER_NORMAL_2  = $A6       ; 6 / 11 pixels per frame
SPEED_MONSTER_NORMAL_3  = $B6       ; 19 / 32 pixels per frame
SPEED_MONSTER_NORMAL_4  = $B6       ; 19 / 32 pixels per frame

SPEED_MONSTER_BLUE_1    = $66       ; 1 / 3 pixels per frame
SPEED_MONSTER_BLUE_2    = $6E       ; 9 / 25 pixels per frame
SPEED_MONSTER_BLUE_3    = $73       ; 3 / 8 pixels per frame
SPEED_MONSTER_BLUE_4    = $56       ; 9 / 32 pixels per frame

SPEED_MONSTER_SLOW_1    = $4C       ; 1 / 4 pixels per frame
SPEED_MONSTER_SLOW_2    = $56       ; 9 / 32 pixels per frame
SPEED_MONSTER_SLOW_3    = $66       ; 1 / 3 pixels per frame
SPEED_MONSTER_SLOW_4    = $66       ; 1 / 3 pixels per frame

SPEED_CRUISE_ELROY1_1   = $99       ; 1 / 2 pixels per frame
SPEED_CRUISE_ELROY1_2   = $AF       ; 4 / 7 pixels per frame
SPEED_CRUISE_ELROY1_3   = $C0       ; 5 / 8 pixels per frame
SPEED_CRUISE_ELROY1_4   = $C0       ; 5 / 8 pixels per frame

SPEED_CRUISE_ELROY2_1   = $A6       ; 6 / 11 pixels per frame
SPEED_CRUISE_ELROY2_2   = $B6       ; 19 / 32 pixels per frame
SPEED_CRUISE_ELROY2_3   = $CC       ; 2 / 3 pixels per frame
SPEED_CRUISE_ELROY2_4   = $CC       ; 2 / 3 pixels per frame

   ENDIF                            ; PAL50 game speed values
   ENDIF                            ; frame timings

;======================================================================================
; C O L O R  C O N S T A N T S
;======================================================================================

BLACK                   = $00       ; RGB = 000000
WHITE                   = $0E       ; RGB = ECECEC
DOT_COLOR               = WHITE

   IF COMPILE_VERSION = NTSC

YELLOW                  = $1A       ; RGB = D0D050
BROWN                   = $28       ; RGB = BC8C4C
ORANGE                  = $2A       ; RGB = CCA05C
RED                     = $40       ; RGB = 880000
MAGENTA                 = $50       ; RGB = 78005C
LTBLUE                  = $78       ; RGB = 7C70D0
BLUE                    = $94       ; RGB = 3854A8
DK_BLUE                 = $A0       ; RGB = 002C5C
LT_GREEN                = $B0       ; RGB = 003C2C
GREEN                   = $C0       ; RGB = 003C00

   ELSE

BROWN                   = $24       ; RGB = A8843C
YELLOW                  = $2A       ; RGB = DCC084
GREEN                   = $50       ; RGB = 006414
ORANGE                  = $48       ; RGB = C89870
LT_GREEN                = GREEN     ; RGB = 006414
MAGENTA                 = $60       ; RGB = 700014
RED                     = MAGENTA   ; RGB = 700014
LTBLUE                  = $BA       ; RGB = 7CA0DC
BLUE                    = $B4       ; RGB = 3858A0
DK_BLUE                 = $D0       ; RGB = 000088

   ENDIF


MAZE_COLOR              = BLUE
CHERRIES_COLOR          = RED + 4
STRAWBERRY_COLOR        = RED + 4
PEACH_COLOR             = ORANGE + 2
APPLE_COLOR             = RED + 2
GRAPES_COLOR            = GREEN + 6

   IF PUBLISHER = ATARIAGE

FLAGSHIP_COLOR          = LTBLUE

   ELSE

FLAGSHIP_COLOR          = YELLOW

   ENDIF

MUSH_COLOR              = YELLOW
KEY_COLOR               = DK_BLUE + 12
PACMAN_COLOR            = YELLOW | 1; D0 used for Pac-man pause for eating monster
BLINKY_COLOR            = RED + 6
PINKY_COLOR             = MAGENTA + 10
INKY_COLOR              = LT_GREEN + 10
CLYDE_COLOR             = BROWN
BLUE_MONSTER_COLOR      = BLUE + 4
EYE_COLOR               = WHITE

;======================================================================================
; U S E R - C O N S T A N T S
;======================================================================================

ROMTOP                  = $F000
STACK_POINTER           = $FF

H_KERNEL                = 166

COLLISION_RANGE         = 2

MAX_NUM_OBJ             = 5
NUM_MONSTERS            = 4

SELECT_DELAY            = $3F       ; delay count for select button
                                    ; (updates ~ every second)
MAX_LEVEL_SELECTION     = 7

XMIN                    = 5         ; minimum x value for players
XMAX                    = 164       ; maximum x value for players
YMID                    = H_KERNEL / 2
XMID                    = XMAX / 2
YMIN                    = 12

SIZE_TILE               = 6         ; square box of 6 x 6

PINKY_INTERESTED_OFFSET_VALUE = SIZE_TILE * 4; Pinky looks 4 tiles ahead for an ambush
INKY_INTERESTED_OFFSET_VALUE = SIZE_TILE * 2; Inky looks 2 tiles ahead for an ambush

W_SCREEN                = 159

H_OBJECTS               = 11
H_SCORE                 = 8

PEN_DOOR_SCANLINE       = 12
FRUIT_KERNEL_SECTION    = 9

DOT_SECTIONS            = 20
NUM_RAM_DOT_BYTES       = 40

PF0_DOT_MASK            = $80
PF1_DOT_MASK            = $55
PF2_DOT_MASK            = $2A

PF0_WALL_MASK           = $E0       ; used to mask start up tune data
STARTUP_TUNE_MASK       = $1F       ; used to mask PF0 graphic data

MAX_NUM_DOTS            = 154

RAND_EOR_8              = $B2

; object id values
ID_BLINKY               = 0
ID_PINKY                = 1
ID_INKY                 = 2
ID_CLYDE                = 3
ID_FRUIT                = 4
ID_PACMAN               = 5

; object starting positions
PACMAN_START_Y          = 44
PACMAN_START_X          = 87

BLINKY_START_Y          = 108
BLINKY_START_X          = 87

PINKY_START_Y           = BLINKY_START_Y - 16
PINKY_START_X           = BLINKY_START_X + 1

INKY_START_Y            = PINKY_START_Y - 2
INKY_START_X            = BLINKY_START_X - 12

CLYDE_START_Y           = INKY_START_Y
CLYDE_START_X           = BLINKY_START_X + 13

FRUIT_START_Y           = 76
FRUIT_START_X           = PACMAN_START_X

; dot array energizer RAM locations
NE_ENERGIZER_RAM_PTR    = 17
NW_ENERGIZER_RAM_PTR    = NE_ENERGIZER_RAM_PTR + 20
SW_ENERGIZER_RAM_PTR    = 4
SE_ENERGIZER_RAM_PTR    = SW_ENERGIZER_RAM_PTR + 20
;
; score values (BCD)
;
DOT_SCORE               = $0010
ENERGIZER_SCORE         = $0050
; monster score values
FIRST_MONSTER_VALUE     = $0200
SECOND_MONSTER_VALUE    = $0400
THIRD_MONSTER_VALUE     = $0800
FOURTH_MONSTER_VALUE    = $1600
; fruit score values
CHERRIES_SCORE          = $0100
STRAWBERRY_SCORE        = $0300
PEACH_SCORE             = $0500
APPLE_SCORE             = $0700
GRAPE_SCORE             = $1000
FLAGSHIP_SCORE          = $2000
MUSH_SCORE              = $3000
KEY_SCORE               = $5000

STARTING_NUM_LIVES      = 2

CHAMBER_TARGET_IDX      = 4

CHAMBER_HOME_HORIZ      = 87
CHAMBER_HOME_VERT       = 108

ATTACK_TIMER_VALUE      = 25

; home position constants
BLINKY_HOME_HORIZ       = 153
PINKY_HOME_HORIZ        = 22
INKY_HOME_HORIZ         = 152
CLYDE_HOME_HORIZ        = PINKY_HOME_HORIZ

BLINKY_HOME_VERT        = (SIZE_TILE * 4) + H_KERNEL
PINKY_HOME_VERT         = BLINKY_HOME_VERT
INKY_HOME_VERT          = 0
CLYDE_HOME_VERT         = INKY_HOME_VERT

; starting level constants
CHERRY_LEVEL            = 0
STRAWBERRY_LEVEL        = 1
PEACH_LEVEL             = 2
APPLE_LEVEL             = 4
GRAPE_LEVEL             = 6
FLAGSHIP_LEVEL          = 8
MUSH_LEVEL              = 10
KEY_LEVEL               = 12

MAX_BLUE_TIME_LEVEL     = 18

INIT_PACMAN_ATE_BONUS_INDEX = 15

;motion constants
MY_MOVE_RIGHT           = %10000000
MY_MOVE_LEFT            = %01000000
MY_MOVE_DOWN            = %00100000
MY_MOVE_UP              = %00010000

VERT_MOTION             = MY_MOVE_UP    | MY_MOVE_DOWN
HORIZ_MOTION            = MY_MOVE_LEFT  | MY_MOVE_RIGHT

ALLOW_MOVE_HORIZ        = MY_MOVE_RIGHT | MY_MOVE_LEFT
ALLOW_MOVE_VERT         = MY_MOVE_UP    | MY_MOVE_DOWN

; direction index constants
DIRECTION_UP            = %00
DIRECTION_RIGHT         = %01
DIRECTION_DOWN          = %10
DIRECTION_LEFT          = %11

; player state values
DEATH_SEQUENCE          = %10000000
START_GAME_MUSIC        = %01000000
FRUIT_TIMER             = %00000111
LIVES_MASK              = %00000011

; energizer mask values
NE_ENERGIZER_MASK_VALUE = %00100000
NW_ENERGIZER_MASK_VALUE = %00010000
SW_ENERGIZER_MASK_VALUE = %00001000
SE_ENERGIZER_MASK_VALUE = %00000100

; pacman attribute values
PACMAN_DELAY_MASK       = %10000000
ENERGIZER_VALUE_MASK    = %00111100
PACMAN_DIRECTION_MASK   = %00000011

; monster attribute values
BLUE_STATE              = %10000000
EYE_STATE               = %01000000
RELEASE_TIME            = %00111100
MONSTER_DIRECTION_MASK  = %00000011

; game state values
NEW_LEVEL_PAUSE         = %10000000
RETURN_HOME             = %01000000
NEW_LEVEL               = %00100000
LEVEL_SELECTION_MASK    = %00000111

; score values
EXTRA_LIFE_REWARDED     = %00000001
FRUIT_SHOWN_MASK        = %00000110
FIRST_FRUIT_SHOWN       = %00000010
SECOND_FRUIT_SHOWN      = %00000100

; game board state values
GAME_BOARD_DONE         = %10000000
DEMO_MODE               = %01000000
CRUISE_ELROY1_STATE     = %00010000 ; only valid for Blinky
CRUISE_ELROY2_STATE     = %00100000 ; only valid for Blinky
CRUISE_ELROY_STATE      = CRUISE_ELROY1_STATE | CRUISE_ELROY2_STATE
FRUIT_SHOW              = %00001000
MONSTER_EATEN_MASK      = %00000111

; attack timer values
ATTACK_COUNTER_MASK     = %11100000
ATTACK_TIMER            = %00011111

   IF PLUSROM
WriteToBuffer     equ $1ff0
WriteSendBuffer   equ $1ff1
ReceiveBuffer     equ $1ff2
ReceiveBufferSize equ $1ff3

HIGHSCORE_ID      equ 21      ; Pac-Man 4K game ID in Highscore DB
   ENDIF


;======================================================================================
; M A C R O S
;======================================================================================

   MAC NOP_W
      .byte $0C
   ENDM

   MAC NOP_B
      .byte $04
   ENDM

   MAC CHECKPAGE
      IF (>(. -1)) != >{1}
         ECHO ""
         ECHO "ERROR: different pages! (", {1}, ",", ., ")"
         ECHO ""
         ERR
      ENDIF
   ENDM

   MAC CHECKBOUNDARY
      IF <. < {1}
         ECHO ""
         ECHO "ERROR: boundary page error! (", <.,")"
         ECHO ""
         ERR
      ENDIF
   ENDM

  MAC FILL_NOP
      REPEAT {1}
         NOP
      REPEND
  ENDM

;
; boundary macro
;
; This is used to push data to certain areas of the ROM. It fills the unused bytes
; with zeros. It also tracks the number of ROM bytes available by using FREE_BYTES.
;
FREE_BYTES SET 0
   MAC BOUNDRY

      REPEAT 256
         IF (<. % {1} = 0) || (<. > {1})
            MEXIT
         ELSE
FREE_BYTES SET FREE_BYTES + 1
            .byte $00
         ENDIF
      REPEND
   ENDM

;
; time wasting macros
;
; These are used to help reduce ROM usage.
;
   MAC SLEEP_5
      dec multi5
   ENDM

;======================================================================================
; Z P - V A R I A B L E S
;======================================================================================
   SEG.U variables
   .org $80
;
; There are only 128 bytes of RAM available to the programmer. Locations $80 - $FF are
; available for RAM use.
;

mazeDots             ds NUM_RAM_DOT_BYTES
frameSecondCount     ds 1           ; temporarily holds clock seconds value

   .org frameSecondCount

object1GraphicPtr    ds 2           ; indirect pointer to object 1 graphic data
selectDebounce       ds 1           ; could use 1 bit but using a byte reduces ROM
objectMotionDelays   ds NUM_MONSTERS + 1; fractional delay values for monsters
;--------------------------------------
blinkyMotionDelay    = objectMotionDelays
pinkyMotionDelay     = blinkyMotionDelay + 1
inkyMotionDelay      = pinkyMotionDelay + 1
clydeMotionDelay     = inkyMotionDelay + 1
pacmanMotionDelay    = clydeMotionDelay + 1
fontHeight           ds 1           ; used by 6 digit kernel (i.e. score display)
;--------------------------------------
object1Sprite        = fontHeight   ; used in kernel to hold GRP1 graphics data
;--------------------------------------
blinkEnergizerOnValue = object1Sprite; holds value for blinking energizers (temporary)
;--------------------------------------
monsterAnimationFrame = blinkEnergizerOnValue
digitHundredthsGraphic ds 1         ; graphic holder for 6-digit display
;--------------------------------------
tempSection          = digitHundredthsGraphic
;--------------------------------------
multi5               = tempSection
;--------------------------------------
allowedMotion        = multi5
;--------------------------------------
tempEnergizerValues  = allowedMotion

deathSoundFreq       ds 1
objectLSBValues      ds 6
;--------------------------------------
object0LSBValues     = objectLSBValues
;--------------------------------------
objectGraphicLSB     = object0LSBValues
;--------------------------------------
blinkyLSBValue       = object0LSBValues
;--------------------------------------
blinkyGraphicLSB     = blinkyLSBValue
pinkyLSBValue        = blinkyLSBValue + 1
;--------------------------------------
pinkyGraphicLSB      = pinkyLSBValue
inkyLSBValue         = pinkyLSBValue + 1
;--------------------------------------
inkyGraphicLSB       = inkyLSBValue
object1LSBValues     = inkyLSBValue + 1
;--------------------------------------
object1GraphicLSB    = object1LSBValues
;--------------------------------------
clydeLSBValue        = object1LSBValues
;--------------------------------------
clydeGraphicLSB      = clydeLSBValue
fruitLSBValue        = clydeLSBValue + 1
;--------------------------------------
fruitGraphicLSB      = fruitLSBValue
pacmanLSBValue       = fruitLSBValue + 1
pacmanGraphicLSB     ds 1
objectColors         ds 6
object0Colors        = objectColors
;--------------------------------------
blinkyColor          = object0Colors
pinkyColor           = blinkyColor + 1
inkyColor            = pinkyColor + 1
object1Colors        = inkyColor + 1
;--------------------------------------
clydeColor           = object1Colors
fruitColor           = clydeColor + 1
pacmanColor          = fruitColor + 1
eatenMonsterNumber   ds 1
energizerValues      ds 1           ; energizer timer
attackTimer          ds 1           ; timer for monster attack/retreat mode
;--------------------------------------
pacmanDeathDelay     = attackTimer
frameCount           ds 1           ; frame counter (updated each frame)
fruitTimer           ds 1           ; using a byte of RAM saves ~15 bytes of ROM
objectHorizPos       ds MAX_NUM_OBJ + 1; horizontal positions of all objects
;--------------------------------------
object0HorizPos      = objectHorizPos
monsterHorizPos      = object0HorizPos
;--------------------------------------
blinkyHorizPos       = monsterHorizPos
pinkyHorizPos        = blinkyHorizPos + 1
inkyHorizPos         = pinkyHorizPos + 1
object1HorizPos      = inkyHorizPos + 1
;--------------------------------------
clydeHorizPos        = object1HorizPos
fruitHorizPos        = clydeHorizPos + 1
pacmanHorizPos       = fruitHorizPos + 1
objectVertPos        ds MAX_NUM_OBJ + 1; vertical positions of all objects
;--------------------------------------
object0VertPos       = objectVertPos
monsterVertPos       = object0VertPos
;--------------------------------------
blinkyVertPos        = monsterVertPos
pinkyVertPos         = blinkyVertPos + 1
inkyVertPos          = pinkyVertPos + 1
object1VertPos       = inkyVertPos + 1
;--------------------------------------
clydeVertPos         = object1VertPos
fruitVertPos         = clydeVertPos + 1
pacmanVertPos        = fruitVertPos + 1
monsterAttributes    ds NUM_MONSTERS; berrrrdd
                                    ; b = blue
                                    ; e = eyes
                                    ; r = release time
                                    ; d = direction
;--------------------------------------
blinkyAttributes     = monsterAttributes
pinkyAttributes      = blinkyAttributes + 1
inkyAttributes       = pinkyAttributes + 1
clydeAttributes      = inkyAttributes + 1
deathSoundIndex      ds 1
;--------------------------------------
eatingMonsterSoundIndex = deathSoundIndex
;--------------------------------------
levelPauseTimer      = eatingMonsterSoundIndex
pacmanAttributes     ds 1           ; Dxppppdd
                                    ; D = frame delay
                                    ; p = energizer values...for blinking
                                    ; d = desired direction
pacmanAteFruit       ds 1           ; could use 1 bit but using a byte reduces ROM
dotsRemaining        ds 1
playerState          ds 1           ; dsxfffll
                                    ; d = death
                                    ; s = start game music
                                    ; f = fruit timer
                                    ; l = lives
score                ds 3           ; 2.5 bytes used for score (i.e. 1 nybble free)
gameBoardState       ds 1           ; dDccfggg
                                    ; d = game board done...flash game board
                                    ; D = demo mode
                                    ; c = Cruise Elroy state
                                    ; f = fruit shown
                                    ; g = monsters eaten - can't go over 4
random               ds 1
gameLevel            ds 1           ; current game level (wraps at 256)
gameState            ds 1           ; Srnxxsss
                                    ; S = new level pause
                                    ; r = return home
                                    ; n = new level start
                                    ; s = selected level
motionDelayIndex     ds 1
extraPlayerSoundIndex ds 1          ; 1up sound index
maxDistance          ds 1           ; temporarily used to determining monster direction

   .org maxDistance

objectOffsetValues   ds 6
;--------------------------------------
object0OffsetValues  = objectOffsetValues
;--------------------------------------
blinkyOffsetValue    = object0OffsetValues
pinkyOffsetValue     = blinkyOffsetValue + 1
inkyOffsetValue      = pinkyOffsetValue + 1
object1OffsetValues  = inkyOffsetValue + 1
;--------------------------------------
clydeOffsetValue     = object1OffsetValues
;--------------------------------------
targetVertPos        = clydeOffsetValue
fruitOffsetValue     = clydeOffsetValue + 1
;--------------------------------------
tempMonsterAttribute = fruitOffsetValue
pacmanOffsetValue    = fruitOffsetValue + 1
;--------------------------------------
targetHorizPos       = pacmanOffsetValue
;--------------------------------------
diagMotionMask       = targetHorizPos
objectMSBValues      ds 6
;--------------------------------------
object0MSBValues     = objectMSBValues
;--------------------------------------
blinkyMSBValue       = object0MSBValues
pinkyMSBValue        = blinkyMSBValue + 1
inkyMSBValue         = pinkyMSBValue + 1
object1MSBValues     = inkyMSBValue + 1
;--------------------------------------
clydeMSBValue        = object1MSBValues
fruitMSBValue        = clydeMSBValue + 1
pacmanMSBValue       = fruitMSBValue + 1
objectId             ds 1           ; id of current object...for kernel
graphicPointers      ds 10
mazeColor            ds 1
;--------------------------------------
horizontalDelta      = mazeColor    ; used in monster AI to determine direction
;--------------------------------------
clydePacmanVertDistance = horizontalDelta

   echo "***",(*-$80)d, "BYTES OF RAM USED", ($100 - *)d, "BYTES FREE"

   .org graphicPointers

objectGraphicPtr     ds 2           ; indirect pointer to object graphic data
;--------------------------------------
fruitColorPointer    = objectGraphicPtr
fruitGraphicPointer  ds 2

   .org fruitGraphicPointer

objectOffset         ds 1
object1Offset        ds 1
kernelSection        ds 1

;======================================================================================
; R O M - C O D E (BANK0)
;======================================================================================

   SEG Bank0
   .org ROMTOP

MazeData
;
; This data is 255 bytes long so it must start at the beginning of a page boundary.
; Placing it at the top of ROM guarantees it starts on a page.
;
; I could have used less bytes for the maze layout if I chose to reduce the resolution.
; I prefered the look of the rounder corners so I decided to keep it using the 255
; bytes.
;
; The GameStartTuneTable is merged with the PF0 data because the lower nybbles aren't
; used for PF0 graphic data. Merging the data saves 32 bytes.
;
; Special thanks to Kurt Howe (Nukey Shay) for convincing me to merge these tables for
; the tune data. I'm not too good in the TIA sound department.
;
MazePF0Data_d
GameStartTuneTable
   .byte $C0 |  0 ;|XX......|
   .byte $20 | 29 ;|..X.....|
   .byte $20 | 14 ;|..X.....|
   .byte $20 | 19 ;|..X.....|
   .byte $E0 | 23 ;|XXX.....|
   .byte $20 | 14 ;|..X.....|
   .byte $20 | 19 ;|..X.....|
   .byte $20 | 23 ;|..X.....|
   .byte $00 |  0 ;|........|
   .byte $00 | 28 ;|........|
   .byte $E0 | 13 ;|XXX.....|
   .byte $00 | 18 ;|........|
   .byte $00 | 22 ;|........|
   .byte $00 | 13 ;|........|
   .byte $C0 | 18 ;|XX......|
;
; last 6 bytes shared with next table so don't cross page boundaries
;
MazePF0Data_c
   .byte $20 | 22 ;|..X.....|
   .byte $20 |  0 ;|..X.....|
   .byte $20 | 29 ;|..X.....|
   .byte $20 | 14 ;|..X.....|
   .byte $20 | 19 ;|..X.....|
   .byte $20 | 23 ;|..X.....|
   .byte $20 | 14 ;|..X.....|
   .byte $20 | 19 ;|..X.....|
   .byte $00 | 23 ;|........|
   .byte $00 |  0 ;|........|
   .byte $00 | 23 ;|........|
   .byte $00 | 21 ;|........|
   .byte $00 | 19 ;|........|
   .byte $00 | 21 ;|........|
   .byte $20 | 19 ;|..X.....|
   .byte $20 | 17 ;|..X.....|
   .byte $20 | 14 ;|..X.....|
   .byte $20 |  0 ;|..X.....|
;
; last 3 bytes  shared with next table so don't cross page boundaries
;
MazePF0Data_a
EndDeathSoundFreq
   .byte $20 |  8 ;|..X.....|
   .byte $20 |  4 ;|..X.....|
   .byte $20 |  2 ;|..X.....|
   .byte $E0 |  8 ;|XXX.....|
   .byte $20 |  4 ;|..X.....|
   .byte $20 |  2 ;|..X.....|
GameStartBaseTuneTable
   .byte $20 | 15 ;|..X.....|
   .byte $C0 |  0 ;|XX......|
   .byte $00 |  7 ;|........|
   .byte $00 |  0 ;|........|
   .byte $00 | 14 ;|........|
   .byte $E0 |  0 ;|XXX.....|
   .byte $00 |  7 ;|........|
   .byte $00 |  0 ;|........|
   .byte $20 | 15 ;|..X.....|
   .byte $20 |  0 ;|..X.....|
   .byte $20 |  7 ;|..X.....|
   .byte $20 |  0 ;|..X.....|
   .byte $20 | 10 ;|..X.....|
   .byte $20 | 17 ;|..X.....|
   .byte $C0 |  7 ;|XX......|
MazePF1Data_c
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $01 ;|.......X|
   .byte $01 ;|.......X|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $01 ;|.......X|
   .byte $01 ;|.......X|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $51 ;|.X.X...X|
;
; last 2 bytes shared with next table so don't cross page boundaries
;
MazePF2Data_c
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $80 ;|X.......|
   .byte $80 ;|X.......|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $80 ;|X.......|
   .byte $80 ;|X.......|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $08 ;|....X...|
   .byte $08 ;|....X...|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $80 ;|X.......|
   .byte $80 ;|X.......|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $88 ;|X...X...|
   .byte $80 ;|X.......|
   .byte $80 ;|X.......|
MazePF1Data_a
   .byte $00 ;|........|
   .byte $7F ;|.XXXXXXX|
   .byte $01 ;|.......X|
   .byte $11 ;|...X...X|
   .byte $10 ;|...X....|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $E1 ;|XXX....X|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $00 ;|........|
   .byte $E1 ;|XXX....X|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $01 ;|.......X|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $71 ;|.XXX...X|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
;
; last byte shared with next table so don't cross page boundaries
;
MazePF2Data_e
   .byte $FF ;|XXXXXXXX|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $08 ;|....X...|
   .byte $08 ;|....X...|
   .byte $78 ;|.XXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
MazePF1Data_b
   .byte $00 ;|........|
   .byte $7F ;|.XXXXXXX|
   .byte $01 ;|.......X|
   .byte $11 ;|...X...X|
   .byte $10 ;|...X....|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $E1 ;|XXX....X|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $00 ;|........|
   .byte $E1 ;|XXX....X|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $01 ;|.......X|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $20 ;|..X.....|
   .byte $51 ;|.X.X...X|
   .byte $00 ;|........|
;
; last byte shared with next table so don't cross page boundaries
;
MazePF1Data_d
   .byte $FF ;|XXXXXXXX|
   .byte $00 ;|........|
   .byte $7F ;|.XXXXXXX|
   .byte $01 ;|.......X|
   .byte $11 ;|...X...X|
   .byte $10 ;|...X....|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $E1 ;|XXX....X|
   .byte $00 ;|........|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $E1 ;|XXX....X|
   .byte $01 ;|.......X|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $51 ;|.X.X...X|
   .byte $20 ;|..X.....|
;
; last byte shared with next table so don't cross page boundaries
;
MazePF2Data_a
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $F8 ;|XXXXX...|
   .byte $08 ;|....X...|
   .byte $08 ;|....X...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
;
; last byte shared with next table so don't cross page boundaries
;
MazePF1Data_e
   .byte $FF ;|XXXXXXXX|
   .byte $00 ;|........|
   .byte $7F ;|.XXXXXXX|
   .byte $01 ;|.......X|
   .byte $11 ;|...X...X|
   .byte $10 ;|...X....|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $E1 ;|XXX....X|
   .byte $00 ;|........|
   .byte $11 ;|...X...X|
   .byte $11 ;|...X...X|
   .byte $E1 ;|XXX....X|
   .byte $01 ;|.......X|
   .byte $71 ;|.XXX...X|
   .byte $00 ;|........|
   .byte $71 ;|.XXX...X|
   .byte $71 ;|.XXX...X|
;
; last byte shared with next table so don't cross page boundaries
;
MazePF2Data_b
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $F8 ;|XXXXX...|
   .byte $08 ;|....X...|
   .byte $08 ;|....X...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $87 ;|X....XXX|
   .byte $88 ;|X...X...|
   .byte $80 ;|X.......|
;
; last byte shared with next table so don't cross page boundaries
;
MazePF2Data_d
   .byte $FF ;|XXXXXXXX|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $08 ;|....X...|
   .byte $08 ;|....X...|
   .byte $78 ;|.XXXX...|
   .byte $00 ;|........|
   .byte $8F ;|X...XXXX|
   .byte $80 ;|X.......|
   .byte $F8 ;|XXXXX...|
   .byte $00 ;|........|
   .byte $88 ;|X...X...|
   .byte $87 ;|X....XXX|
   .byte $80 ;|X.......|

;
; These arcade fonts were ripped from Eduardo Mello's PMC and used with his
; permission.
;
; NOTE: These are placed after the maze data to make zero start at the beginning of a
; page boundary. This is so the suppressZero subroutine only needs to check for zero to
; know if the zero value is to be suppressed.
;
NumberFonts
zero
   .byte $00 ; |........|
   .byte $1C ; |...XXX..|
   .byte $32 ; |..XX..X.|
   .byte $63 ; |.XX...XX|
   .byte $63 ; |.XX...XX|
   .byte $63 ; |.XX...XX|
   .byte $26 ; |..X..XX.|
   .byte $1C ; |...XXX..|
one
   .byte $00 ; |........|
   .byte $3F ; |..XXXXXX|
   .byte $0C ; |....XX..|
   .byte $0C ; |....XX..|
   .byte $0C ; |....XX..|
   .byte $0C ; |....XX..|
   .byte $1C ; |...XXX..|
   .byte $0C ; |....XX..|
two
   .byte $00 ; |........|
   .byte $7F ; |.XXXXXXX|
   .byte $70 ; |.XXX....|
   .byte $3C ; |..XXXX..|
   .byte $1E ; |...XXXX.|
   .byte $07 ; |.....XXX|
   .byte $63 ; |.XX...XX|
   .byte $3E ; |..XXXXX.|
three
   .byte $00 ; |........|
   .byte $3E ; |..XXXXX.|
   .byte $63 ; |.XX...XX|
   .byte $03 ; |......XX|
   .byte $1E ; |...XXXX.|
   .byte $0C ; |....XX..|
   .byte $06 ; |.....XX.|
   .byte $3F ; |..XXXXXX|
four
   .byte $00 ; |........|
   .byte $06 ; |.....XX.|
   .byte $06 ; |.....XX.|
   .byte $7F ; |.XXXXXXX|
   .byte $66 ; |.XX..XX.|
   .byte $36 ; |..XX.XX.|
   .byte $1E ; |...XXXX.|
   .byte $0E ; |....XXX.|
five
   .byte $00 ; |........|
   .byte $3E ; |..XXXXX.|
   .byte $63 ; |.XX...XX|
   .byte $03 ; |......XX|
   .byte $03 ; |......XX|
   .byte $7E ; |.XXXXXX.|
   .byte $60 ; |.XX.....|
   .byte $7E ; |.XXXXXX.|
six
   .byte $00 ; |........|
   .byte $3E ; |..XXXXX.|
   .byte $63 ; |.XX...XX|
   .byte $63 ; |.XX...XX|
   .byte $7E ; |.XXXXXX.|
   .byte $60 ; |.XX.....|
   .byte $30 ; |..XX....|
   .byte $1E ; |...XXXX.|
seven
   .byte $00 ; |........|
   .byte $18 ; |...XX...|
   .byte $18 ; |...XX...|
   .byte $18 ; |...XX...|
   .byte $0C ; |....XX..|
   .byte $06 ; |.....XX.|
   .byte $63 ; |.XX...XX|
   .byte $7F ; |.XXXXXXX|
eight
   .byte $00 ; |........|
   .byte $3E ; |..XXXXX.|
   .byte $43 ; |.X....XX|
   .byte $4F ; |.X..XXXX|
   .byte $3C ; |..XXXX..|
   .byte $72 ; |.XXX..X.|
   .byte $62 ; |.XX...X.|
   .byte $3C ; |..XXXX..|
nine
   .byte $00 ; |........|
   .byte $3C ; |..XXXX..|
   .byte $06 ; |.....XX.|
   .byte $03 ; |......XX|
   .byte $3F ; |..XXXXXX|
   .byte $63 ; |.XX...XX|
   .byte $63 ; |.XX...XX|
   .byte $3E ; |..XXXXX.|

JoystickDirectionTable
   .byte DIRECTION_UP
   .byte DIRECTION_DOWN
   .byte 0                          ; invalid value...up and down
   .byte DIRECTION_LEFT
   .byte 0, 0, 0                    ; invalid values
   .byte DIRECTION_RIGHT
   .byte 0                          ; invalid values
;
; last 2 bytes shared with table below...
;
LivesIndicatorCount
   .byte ONE_COPY, ONE_COPY, TWO_COPIES, THREE_COPIES

VerticalMazeValues
   .byte 21, 29, 45, 61, 77, 97, 113, 129, 145, 153

MonsterAnimationTable
;
; first frame animation
;
   .byte <MonstersDown_01 - H_KERNEL
   .byte <MonstersUp_01 - H_KERNEL
   .byte <MonstersHoriz_01 - H_KERNEL
;
; NOTE: 5 bytes *MUST* separate the monster animation values...sorry about this but it
; saves ~8 bytes
;
MonsterStaticTargetHorizPos
   .byte BLINKY_HOME_HORIZ, PINKY_HOME_HORIZ, INKY_HOME_HORIZ
   .byte CLYDE_HOME_HORIZ, CHAMBER_HOME_HORIZ
;
; second frame animation
;
   .byte <MonstersDown_02 - H_KERNEL
   .byte <MonstersUp_02 - H_KERNEL
   .byte <MonstersHoriz_02 - H_KERNEL

;-----------------------------------------------------------------SetFruitIndexForLevel
;
; Determine fruit index based on current game level. Kurt removed the table that was
; used for this calculation during the first iteration. Doing so makes the routine
; take longer to execute but it saves ROM space. I'm not concerned with the cycles that
; get used because it's not called during time sensitive situations. Thanks Kurt!
;
SetFruitIndexForLevel
   bit gameBoardState               ; check the current game board state
   bvc .setIndexFromGameLevel       ; branch if not in DEMO_MODE
SetFruitIndexForGameStart
   lda gameState                    ; get the current game state
   and #LEVEL_SELECTION_MASK        ; keep the selected level
   tay                              ; move selected level to y
   and #6
   beq .doneSetFruitIndexForLevel   ; branch if level less than Strawberries
   dey                              ; reduce selected game level
   tya                              ; move game level to accumulator
   asl                              ; multiply value by 2
   tay                              ; set y to level index
   rts

.setIndexFromGameLevel
SetIndexFromGameLevel
   ldy gameLevel                    ; get current game level
   cpy #12                          ; make sure game level doesn't go past 12
   bcc .doneSetFruitIndexForLevel
   ldy #12
.doneSetFruitIndexForLevel
   rts

;-------------------------------------------------------------------------RemoveObjects
;
; Remove all objects from the screen by placing them out of range (i.e. above the start
; of the kernel).
;
RemoveObjects
   ldx #MAX_NUM_OBJ - 1
   lda #H_KERNEL + H_OBJECTS        ; place sprite out of range so it can't be seen
.removeObjectsOffScreen
   sta object0VertPos,x
   dex
   bpl .removeObjectsOffScreen
   rts

ReverseDirToJoystickValueTable
   .byte ~MY_MOVE_DOWN & P0_JOYSTICK_MASK
   .byte ~MY_MOVE_LEFT & P0_JOYSTICK_MASK
   .byte ~MY_MOVE_UP & P0_JOYSTICK_MASK
   .byte ~MY_MOVE_RIGHT & P0_JOYSTICK_MASK

MonsterBlueAnimationTable
   .byte <MonstersBlue_01 - H_KERNEL, <MonstersBlue_02 - H_KERNEL

DirToJoystickValueTable
   .byte MY_MOVE_UP
   .byte MY_MOVE_RIGHT
   .byte MY_MOVE_DOWN
   .byte MY_MOVE_LEFT

   BOUNDRY (H_KERNEL - 4)
   CHECKBOUNDARY (H_KERNEL - 4)
;
; NOTE: These sprites *MUST* reside on the same page as the number fonts. Their
; definition can start anywhere below $xxA1 (i.e. H_KERNEL - 4) as long as they don't
; cross a page boundary.
;
PacmanDeathSprites9
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
;
; last 6 bytes shared with next table so don't cross page boundaries
;
MonsterLowScoreTable
;   .byte FIRST_MONSTER_VALUE
;   .byte SECOND_MONSTER_VALUE
;   .byte THIRD_MONSTER_VALUE
;   .byte FOURTH_MONSTER_VALUE

;
; MonsterLowScoreTable shared with values below...
;
FruitLowScoreTable
   .byte <CHERRIES_SCORE, <STRAWBERRY_SCORE
;   .byte PEACH_SCORE, PEACH_SCORE
;   .byte APPLE_SCORE, APPLE_SCORE
;   .byte GRAPE_SCORE, GRAPE_SCORE
;   .byte FLAGSHIP_SCORE, FLAGSHIP_SCORE
;   .byte MUSH_SCORE, MUSH_SCORE
;   .byte KEY_SCORE

;
; last 11 bytes shared with table below...
;
Blank
PacmanDeathSprites11
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
;
; last 6 bytes shared with next table so don't cross page boundaries
;
MonsterEyes
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $28 ;|..X.X...|
   .byte $28 ;|..X.X...|
   .byte $28 ;|..X.X...|
   .byte $00 ;|........|
   .byte $00 ;|........|
PacmanDeathSprites1
   .byte $28 ;|..X.X...|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $C6 ;|XX...XX.|
   .byte $82 ;|X.....X.|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
PacmanDeathSprites6
   .byte $28 ;|..X.X...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
   .byte $10 ;|...X....|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
PacmanDeathSprites7
   .byte $28 ;|..X.X...|
   .byte $38 ;|..XXX...|
   .byte $38 ;|..XXX...|
   .byte $38 ;|..XXX...|
   .byte $10 ;|...X....|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
;
; last 3 bytes shared with table below...
;
MonsterPoints
_200Points
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $FF ;|XXXXXXXX|
   .byte $95 ;|X..X.X.X|
   .byte $F5 ;|XXXX.X.X|
   .byte $35 ;|..XX.X.X|
   .byte $FF ;|XXXXXXXX|
;
; last 3 bytes shared with table below...don't cross page boundary
;
_400Points
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $3F ;|..XXXXXX|
   .byte $35 ;|..XX.X.X|
   .byte $F5 ;|XXXX.X.X|
   .byte $B5 ;|X.XX.X.X|
   .byte $BF ;|X.XXXXXX|
;
; last 3 bytes shared with table below...don't cross page boundary
;
_800Points
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $FF ;|XXXXXXXX|
   .byte $B5 ;|X.XX.X.X|
   .byte $F5 ;|XXXX.X.X|
   .byte $B5 ;|X.XX.X.X|
   .byte $FF ;|XXXXXXXX|
;
; last 3 bytes shared with table below...don't cross page boundary
;
_1600Points
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $FF ;|XXXXXXXX|
   .byte $D5 ;|XX.X.X.X|
   .byte $F5 ;|XXXX.X.X|
   .byte $D5 ;|XX.X.X.X|
   .byte $DF ;|XX.XXXXX|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|

;----------------------------------------------------------------------------GameKernel
;
; This is the main kernel. This kernel does a constant 20Hz flicker on the objects.
; Doing a variable flicker system would have expanded this game over the 4K limit I'm
; shooting for.
;
; ------------------ Maze PF Timings ------------------
; | PF0 |   PF1   |   PF2   |   PF2   |   PF1   | PF0 |
; |22.??|27 ..  ??|38 ..  ??|48 ..  ??|59 ..  67|70.??|
;
GameKernel
MazeLoop
   stx kernelSection          ; 3 = @22
   cpx #PEN_DOOR_SCANLINE - 1 ; 2         minus 1 because kernelSection reduced
   php                        ; 3 = @27   push to enable/diable ball VDEL'd
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5 = @34
   bcs .storePlayer1Sprite_c  ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.storePlayer1Sprite_c
   lda (object1GraphicPtr),y  ; 5
   dey                        ; 2
   sta object1Sprite          ; 3 = @47
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5 = @54
   lda mazeDots,x             ; 4         get left dot values for kernel section
   tax                        ; 2
   and #PF2_DOT_MASK          ; 2         keep the PF2 dot value
   sta PF2                    ; 3 = @65   draw dot pattern for left PF2
   txa                        ; 2
   and #PF1_DOT_MASK          ; 2         keep the PF1 dot value
   sta PF1                    ; 3 = @72   draw dot pattern for left PF1
   txa                        ; 2
   and #PF0_DOT_MASK          ; 2         keep the PF0 dot value
;-------------------------------------- dot kernel
   sta PF0                    ; 3 = @03   draw dot pattern for left PF0
   lda object1Sprite          ; 3
   sta GRP1                   ; 3 = @09
   lda #DOT_COLOR             ; 2
   sta COLUPF                 ; 3 = @14   <= 30...OKAY
   ldx kernelSection          ; 3
   lda mazeDots + 20,x        ; 4         get the right dot values for kernel section
   SLEEP 2                    ; 2
JumpIntoKernel SUBROUTINE
   tax                        ; 2
   and #PF0_DOT_MASK          ; 2         keep the PF0 dot value
   sta PF0                    ; 3 = @30   draw dot pattern for right PF0
   bcs .drawPlayer0_a         ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawPlayer0_a
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @41   draw object for 1st line of kernel
   txa                        ; 2
   and #PF2_DOT_MASK          ; 2         keep the PF2 dot value
   sta PF2                    ; 3 = @48   draw dot pattern for right PF2
   txa                        ; 2
   and #PF1_DOT_MASK          ; 2         keep the PF1 dot value
   sta PF1                    ; 3 = @55   draw dot pattern for right PF1
   sta ENABL                  ; 3 = @58   D1 = 0 from PF1_DOT_MASK :-)
   ldx kernelSection          ; 3
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5
   lda mazeColor              ; 3
   sta COLUPF                 ; 3 = @74
;--------------------------------------   first line of maze
   lda MazePF0Data_a,x        ; 4 = @02
   and #PF0_WALL_MASK         ; 2
   sta PF0                    ; 3 = @07
   bcs .drawPlayer1_a         ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawPlayer1_a
   lda (object1GraphicPtr),y  ; 5
   sta GRP1                   ; 3 = @18
   lda MazePF1Data_a,x        ; 4
   sta PF1                    ; 3 = @25   < 27
   lda MazePF2Data_a,x        ; 4
   sta PF2                    ; 3 = @32   < 38
   dey                        ; 2
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5
   bcs .drawObject_b          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_b
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @52   draw object for 2nd line of kernel
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5 = @59
   lda MazePF2Data_b,x        ; 4
   sta PF2                    ; 3 = @66
   lda MazePF1Data_b,x        ; 4
   sta PF1                    ; 3 = @73
   bcs .drawPlayer1_b         ; 2
;--------------------------------------   second line of maze
   lda #0                     ; 2 = @01
   NOP_W                      ; -1
.drawPlayer1_b
   lda (object1GraphicPtr),y  ; 5 = @05
   sta GRP1                   ; 3 = @08
   dey                        ; 2
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5
   bcs .drawObject_c          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_c
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @28   draw object for 3rd line of kernel
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5 = @35
   bcs .storePlayer1Sprite_c  ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.storePlayer1Sprite_c
   lda (object1GraphicPtr),y  ; 5
   sta object1Sprite          ; 3 = @46
   dey                        ; 2         reduce scan line for 3rd line of maze
   pla                        ; 4         point to stack to ENABL for door
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5
; ------------------ Maze PF Timings ------------------
; | PF0 |   PF1   |   PF2   |   PF2   |   PF1   | PF0 |
; |22.??|27 ..  ??|38 ..  ??|48 ..  ??|59 ..  67|70.??|
   lda MazePF2Data_c,x        ; 4
   sta PF2                    ; 3 = @66
   lda MazePF1Data_c,x        ; 4
   sta PF1                    ; 3 = @73
;--------------------------------------   third line of maze
   lda MazePF0Data_c,x        ; 4 = @01
   and #PF0_WALL_MASK         ; 2
   sta PF0                    ; 3 = @06
   lda object1Sprite          ; 3
   sta GRP1                   ; 3 = @12
   bcs .drawObject_d          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_d
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @23   draw object for 4th line of kernel
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5 = @30
   bcs .storePlayer1InSection ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.storePlayer1InSection
   lda (object1GraphicPtr),y  ; 5
   dey                        ; 2         reduce scan line for 4th line of maze
   sta WSYNC
;--------------------------------------   forth line of maze
   sta GRP1                   ; 3 = @03
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5
   bcs .drawObject_e          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_e
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @21   draw object for 5th line of kernel
   lda #H_OBJECTS - 1         ; 2
   sta WSYNC
;--------------------------------------   fifth line of maze
   dcp object1Offset          ; 5 = @05
   bcs .drawPlayer1_f         ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawPlayer1_f
   lda (object1GraphicPtr),y  ; 5
   sta GRP1                   ; 3 = @16
   dey                        ; 2
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5
   bcs .drawObject_f          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_f
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @36   draw object for 6th line of kernel
   SLEEP_5                    ; 5
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5
   bcs .drawPlayer1           ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawPlayer1
   lda (object1GraphicPtr),y  ; 5
   sta object1Sprite          ; 3 = @59
   lda MazePF2Data_d,x        ; 4
   sta PF2                    ; 3 = @66
   lda MazePF1Data_d,x        ; 4
   sta PF1                    ; 3 = @73
   lda object1Sprite          ; 3
;--------------------------------------   sixth line of maze
   sta GRP1                   ; 3 = @03
   lda MazePF0Data_d,x        ; 4
   and #PF0_WALL_MASK         ; 2
   sta PF0                    ; 3 = @12
   dey                        ; 2
   lda #H_OBJECTS - 1         ; 2
   dcp objectOffset           ; 5
   bcs .drawObject_g          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_g
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @32   draw object for 7th line of kernel
   lda #H_OBJECTS - 1         ; 2
   dcp object1Offset          ; 5
   bcs .storePlayer1Sprite_b  ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.storePlayer1Sprite_b
   lda (object1GraphicPtr),y  ; 5
   sta object1Sprite          ; 3 = @50
   dey                        ; 2
   lda #H_OBJECTS - 1         ; 2         prepare logic to draw player 0 on
   dcp objectOffset           ; 5         next scan line since we have time
   lda MazePF2Data_e,x        ; 4
   sta PF2                    ; 3 = @66   > 59...OKAY
   lda MazePF1Data_e,x        ; 4
   sta PF1                    ; 3 = @73   > 67...OKAY
   lda object1Sprite          ; 3
;--------------------------------------   seventh line of maze
   sta GRP1                   ; 3 = @01
   bcs .drawObject_h          ; 2
   lda #0                     ; 2
   NOP_W                      ; -1
.drawObject_h
   lda (objectGraphicPtr),y   ; 5
   sta GRP0                   ; 3 = @12   draw object for 8th line of kernel
   dex                        ; 2
   bmi DrawStatusKernel       ; 2³
   jmp MazeLoop               ; 3

Start
;
; Set up everything so the power up state is known.
;
;   sei                             ; No interrupts are used for this game. This is
                                    ; here for clarity purposes and commented out to
                                    ; save 1 byte :-)
   cld                              ; clear BCD bit
   ldy INTIM                        ; for random number seed
;
; The next routine comes courtesy of Andrew Davie :-) The routine clears all variables,
; TIA registers, and initializes the stack pointer to #$FF in 8 bytes. It does this in
; the unusual way of wrapping the stack. Very ingenious!!
;
   ldx #0
   txa                              ; accumulator now 0
.clear
   dex
   txs                              ; stack pointer now equals x
   pha                              ; pushes 0 to stack pointer and moves stack pointer
   bne .clear                       ; continue until x reaches 0 (255 times)

;--------------------------------------------------------------------GameInitialization
;
; Initialize the game variables on cart start up. These variables must be set for the
; game to function properly.
;
GameInitialization
   sty random                       ; set the random number seed
   jmp .setToDemoMode               ; set game to DEMO_MODE

MonsterHighScoreTable
   .byte FIRST_MONSTER_VALUE >> 8
   .byte SECOND_MONSTER_VALUE >> 8
   .byte THIRD_MONSTER_VALUE >> 8
   .byte FOURTH_MONSTER_VALUE >> 8

EnergizerRAMLocations
   .byte NE_ENERGIZER_RAM_PTR, NW_ENERGIZER_RAM_PTR
   .byte SW_ENERGIZER_RAM_PTR, SE_ENERGIZER_RAM_PTR

;
; values below are subtracted by 1 because we do a ADC with the carry bit set
;
PinkyInterestedOffsetValues
   .byte 0 - 1, PINKY_INTERESTED_OFFSET_VALUE - 1, 0 - 1, -PINKY_INTERESTED_OFFSET_VALUE - 1
;
; last byte shared with table below...
;
InkyInterestedOffsetValues
   .byte 0 - 1, INKY_INTERESTED_OFFSET_VALUE - 1
   .byte  0 - 1, -INKY_INTERESTED_OFFSET_VALUE - 1;, 0 - 1
;
; last byte shared with table below...
;
ROMDotPatterns
   .byte $FF
   .byte $A0
   .byte $FE
   .byte $46
   .byte $EF
   .byte $A4
   .byte $FF
   .byte $04
   .byte $04
   .byte $04
   .byte $04
   .byte $04
   .byte $04
   .byte $04
   .byte $FE
   .byte $86
   .byte $FF
   .byte $A4
   .byte $A4
   .byte $FF
;
; NOTE: Pac-man animation sprites *MUST* reside on the same page. Their definition can
; start anywhere below $xxA1 (i.e. H_KERNEL - 4) as long as they don't cross a page
; boundary. These sprites were re-done by Stefan Haddewig.
;

   BOUNDRY (H_KERNEL - 4)
   CHECKBOUNDARY (H_KERNEL - 4)

PacmanSprites
PacmanUp1
PacmanDeathSprites0
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $EE ;|XXX.XXX.|
   .byte $C6 ;|XX...XX.|
   .byte $82 ;|X.....X.|
;
; last 4 bytes shared with next table so don't cross page boundaries
;
PacmanDown1
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $82 ;|X.....X.|
   .byte $C6 ;|XX...XX.|
   .byte $EE ;|XXX.XXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
;
; last byte shared with next table so don't cross page boundaries
;
PacmanUp0
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $EE ;|XXX.XXX.|
   .byte $EE ;|XXX.XXX.|
   .byte $C6 ;|XX...XX.|
   .byte $C6 ;|XX...XX.|
   .byte $44 ;|.X...X..|
;
; last 2 bytes shared with next table so don't cross page boundaries
;
PacmanDown0
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $44 ;|.X...X..|
   .byte $C6 ;|XX...XX.|
   .byte $C6 ;|XX...XX.|
   .byte $EE ;|XXX.XXX.|
   .byte $EE ;|XXX.XXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
;
; last byte shared with next table so don't cross page boundaries
;
PacmanStationary
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
;
; last byte shared with next table so don't cross page boundaries
;
LivesIndicator
PacmanHoriz0
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $F8 ;|XXXXX...|
   .byte $F0 ;|XXXX....|
   .byte $E0 ;|XXX.....|
   .byte $F0 ;|XXXX....|
   .byte $F8 ;|XXXXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
;
; last byte shared with next table so don't cross page boundaries
;
PacmanHoriz1
   .byte $38 ;|..XXX...|
   .byte $78 ;|.XXXX...|
   .byte $70 ;|.XXX....|
   .byte $F0 ;|XXXX....|
   .byte $E0 ;|XXX.....|
   .byte $E0 ;|XXX.....|
   .byte $E0 ;|XXX.....|
   .byte $F0 ;|XXXX....|
   .byte $70 ;|.XXX....|
   .byte $78 ;|.XXXX...|
   .byte $38 ;|..XXX...|

   CHECKPAGE PacmanSprites

DrawStatusKernel
   txs                        ; 3 = @20   reset stack to the beginning (i.e. x = #$FF)
   jsr SetFruitIndexForLevel  ; 6
   stx REFP1                  ; 3 = @53   reflect GRP1 (i.e. D3 = 1)
   sta WSYNC
;--------------------------------------
   inx                        ; 2         x = 0
   stx VDELP0                 ; 3 = @05   turn off vertical delay for player 0
   stx PF0                    ; 3 = @08
   stx PF1                    ; 3 = @11
   stx PF2                    ; 3 = @14
   stx GRP0                   ; 3 = @17
   stx GRP1                   ; 3 = @20
   lda #LIVES_MASK            ; 2
   sta RESP1                  ; 3 = @25
   stx REFP0                  ; 3 = @28   don't reflect GRP0 (i.e. D3 = 0)
   stx HMCLR                  ; 3 = @31
   ldx FruitColorsTableLSB,y  ; 4         set the pointers to point to the
   stx fruitColorPointer      ; 3         fruit colors
   ldx #>BonusFruitColors     ; 3
   stx fruitColorPointer + 1  ; 3
   ldx FruitOffsetTable,y     ; 4
   and playerState            ; 3
   tay                        ; 2
   lda LivesIndicatorColor,y  ; 4
   sta COLUP1                 ; 3 = @60
   lda LivesIndicatorCount,y  ; 4
   ldy #H_OBJECTS - 1         ; 2
   sta NUSIZ1                 ; 3 = @69
   sta RESP0                  ; 3 = @72   coarse move fruit to pixel 210
.drawStatusKernel
   sta WSYNC
;--------------------------------------
   lda LivesIndicator,y       ; 4
   sta GRP1                   ; 3 = @07
   lda FruitSprites - 1,x     ; 4
   sta GRP0                   ; 3 = @14
   lda (fruitColorPointer),y  ; 5
   sta COLUP0                 ; 3 = @22
   dex                        ; 2
   dey                        ; 2
   bpl .drawStatusKernel      ; 2³

MainLoop
;------------------------------------------------------------------------------Overscan
;
; The display kernel is done at this point. So we turn off the TIA and do more game
; calculations before the next frame is drawn
;
Overscan
   lda #OVERSCAN_TIME               ; get value for the overscan wait time
   sta WSYNC                        ; end the last scanline
   sty VBLANK                       ; turn off TIA (D1 = 1)
   sta TIM64T                       ; set the timer for the "big wait"

;---------------------------------------------------------------------------CenterScore
;
; Center players on screen for 48-pixel display kernel.
;
   ldx #HMOVE_R7 | THREE_COPIES     ; = $73 (%01110011) only top nybbles used
   stx HMBL                         ; move ball right 7 pixels = @148
   stx NUSIZ0                       ; 3 copies of GRP0 close (D1 and D0 = 1)
   stx NUSIZ1                       ; 3 copies of GRP1 close (D1 and D0 = 1)
   stx VDELP0                       ; vertical delay for GRP0 (D0 = 1)
   stx VDELP1                       ; vertical delay for GRP1 (D0 = 1)
   stx VDELBL
   stx REFP1                        ; don't reflect GRP1 (i.e. D3 = 0)
   lax frameCount                   ; get the current frame count
   ldy #HMOVE_R1
   sta.w RESP0                      ; = @39 position player 0 @ pixel 117
   sta RESP1                        ; = @42 position player 1 @ pixel 126
   and #$3F                         ; determine the current second count
   sta RESBL                        ; = @47 position ball @ pixel 141
   sty HMP0                         ; move player 1 right 1 pixel @116
   sta frameSecondCount             ; store frame second count
   and #8
   sta monsterAnimationFrame        ; updated ~every 8 frames

;------------------------------------------------------------------CheckEnergizerValues
;
; Check to see if the energizer timer value needs to be reduced this frame. The
; energizer timer is reduced every other frame and is avoided when Pac-man is paused
; for eating a monster (i.e. while monster points are shown).
;
CheckEnergizerValues
   txa                              ; get the current frame count
   and pacmanColor                  ; and with current Pac-man color
   lsr                              ; shift D0 to carry
   ldx energizerValues              ; get energizer time value
   beq .returnMonsterState          ; branch if energizer not on
   bcc .skipDecrementEnergizerValue ; branch if not time to reduce energizer time
   dec energizerValues              ; reduced every other frame
   bcs .doneCheckEnergizerValues    ; unconditional branch

.returnMonsterState
   ldx #NUM_MONSTERS - 1
.restoreMonsterStateLoop
   rol monsterAttributes,x          ; rotate monster attributes left
   lsr monsterAttributes,x          ; shift monster attributes right to clear D7
   dex
   bpl .restoreMonsterStateLoop
.skipDecrementEnergizerValue
.doneCheckEnergizerValues

;----------------------------------------------------------------------CheckAttactTimer
;
; Increment the attack timer approxiately every second. I used a chart from
; http://www.webpacman.com/ for this behavior. The monsters start out in scatter mode
; and will stay there for ~9 seconds. After that the monsters will start to chase
; Pac-man for ~20 seconds. Then they will return to scatter mode. This is done 7 times
; and then the monsters stay in attack mode.
;
CheckAttactTimer
   bit playerState                  ; check current player state
   bmi .doneCheckAttackTimer        ; branch if in death sequence
   bvs PlayGameStartTune            ; branch if starting a new game
   lda frameSecondCount             ; get frame second count
   ora energizerValues              ; or in energizer values
   bne .doneCheckAttackTimer        ; skip check if not time
   lax attackTimer                  ; get attack timer value
   and #ATTACK_COUNTER_MASK         ; keep the attack counter
   cmp #(7 << 5)
   bcs .doneCheckAttackTimer        ; branch if done 7 times
   bit gameState                    ; check the current game state
   txa                              ; move attack timer to accumulator
   and #ATTACK_TIMER                ; keep ATTACK_TIMER value
   bvc .monstersNotReturningHome    ; branch if RETURN_HOME flag clear
   cmp #ATTACK_TIMER_VALUE - 10
.monstersNotReturningHome
   bne .decrementAttackTimer
.resetAttackTimerValue
   txa                              ; move attack timer to accumulator
   and #<~ATTACK_TIMER              ; clear attack timer value
   adc #((1 << 5) + ATTACK_TIMER_VALUE) - 1; increment number of times done...carry set
   sta attackTimer                  ; set new attack timer value
   lda gameState                    ; get current game state
   and #<~NEW_LEVEL                 ; clear the NEW_LEVEL flag
   eor #RETURN_HOME                 ; flip the RETURN_HOME flag
   sta gameState
   brk                              ; branch to reverse monster directions
   NOP_W                            ; skip next 2 bytes
.decrementAttackTimer
   dec attackTimer
.doneCheckAttackTimer

;------------------------------------------------------------------------PlayGameSounds
;
; Play all game sounds in this routine.
;
PlayGameSounds
   bit gameState
   bmi .reduceLevelPauseTimer       ; branch if pausing for a new level
   lda gameBoardState               ; get the current game board state
   and #GAME_BOARD_DONE | DEMO_MODE ; keep D7 and D6
   bne .reduceLevelPauseTimer       ; skip game sounds if level done or in DEMO_MODE
.playPacmanSounds
   bit playerState                  ; check current player state
   bpl .checkToPlayPacmanEatingSounds; check for Pac-man eating sounds if not dieing
   lda #11 + 1
   cmp pacmanDeathDelay             ; get Pac-man death delay value
   bcc .jmpSkipPlayGameSounds       ; branch if pausing after Pac-man was caught
   sta AUDC1                        ; set audio channel for death sound (i.e. a = 12)
   lsr                              ; divide value by 2 (i.e. a = 6)
   sta AUDV1                        ; set death sound volume
   lsr                              ; divide value by 2 (i.e. a = 3)
   and frameCount
   bne .jmpSkipPlayGameSounds       ; decrement death sound index every 4th frame
   lda deathSoundIndex              ; get death sound index
   lsr                              ; shift D0 to carry
   dec deathSoundIndex
   bmi .endDeathSound
   lda deathSoundFreq               ; get death sound frequency
   bcs .addSoundFreq                ; increment frequency by 2 on odd frames
.decSoundFreq
   sbc #3 - 1                       ; subtract frequency by 1 on even frames
.addSoundFreq
   adc #2 - 1
   tay
   bne .saveDeathSoundFrequency     ; unconditional branch

.checkToPlayPacmanEatingSounds
.checkToPlayAteMonsterSound
   ldx eatingMonsterSoundIndex      ; get the monster eating sound index
   beq .checkToPlayEatingDotSound
   lda frameCount                   ; get current frame count
   lsr                              ; shift D1 to carry bit
   lsr
   bcs .checkToPlayEatingDotSound   ; pause for 2 frames and decrement for 2 frames
   dex                              ; reduce monster eating sound index
   stx eatingMonsterSoundIndex
   txa                              ; move monster eating sound index to accumulator
   adc #10                          ; increment value by 10...carry clear
   sta AUDF0
   lda #12
   sta AUDC0
   lsr                              ; a = 6
   bne .setChannel0Volume           ; unconditional branch

PlayGameStartTune
   lda #6
   sta AUDC0                        ; set audio channel for bassline
   lda frameCount                   ; get the current frame count
   jsr SetYRegisterToDiv8
   lsr                              ; divide value by 2 for bassline index
   tax
   lda GameStartBaseTuneTable,x     ; read baseline table
   and #STARTUP_TUNE_MASK           ; keep only the sound data needed
   beq .doSquareSound
   sta AUDF0
   lda #14
.doSquareSound
   sta AUDV0
   lda GameStartTuneTable,y         ; read the values from tune table
   and #STARTUP_TUNE_MASK
   beq .setAudioChannel1Volume
   bne .setBonusSoundAttributes     ; unconditional branch

.reduceLevelPauseTimer
   ldx levelPauseTimer              ; get pause timer for starting a new level
   beq .jmpSkipPlayGameSounds       ; done waiting for level start when reaches 0
   dex                              ; reduce pause timer value
   stx levelPauseTimer
   bpl .bplDonePlayGameSounds       ; unconditional branch

.endDeathSound
   ldy deathSoundFreq               ; get Pac-man death sound frequency value
   cpy #6
   bcc .playEndDeathSound           ; branch if ending death sound routine started
   ldy #6
.playEndDeathSound
   lda EndDeathSoundFreq - 1,y
   and #<~PF0_WALL_MASK
   dey
.saveDeathSoundFrequency
   sta AUDF1                        ; set Pac-man ending death sound frequency
   sty deathSoundFreq
   bne .jmpSkipPlayGameSounds
   sty AUDV1                        ; turn off volume if done with death sound
.jmpSkipPlayGameSounds
   jmp .skipPlayGameSounds

.checkToPlayEatingDotSound
   lda pacmanAttributes             ; get Pac-man attributes
   bpl .donePacmanSounds            ; skip dot eating sound if not delayed
   lda #30
   sta AUDF0
   lda #7
   sta AUDC0
   asl                              ; a = 14
.setChannel0Volume
   sta AUDV0                        ; set volume for channel 0
.donePacmanSounds

.playMonsterSounds
   lda extraPlayerSoundIndex        ; get bonus sound index
   beq .checkToPlayMonsterRetreatSound; branch if not playing bonus sound
   lsr                              ; shift D0 to carry
   lda frameCount                   ; get current frame count
   and #7
   bne .skipDecrementBonusSoundIndex
   dec extraPlayerSoundIndex        ; reduce 1up sound index
.skipDecrementBonusSoundIndex
   lda #10
   bcs .setBonusSoundAttributes
   lda #0                           ; turn off bonus sound every other frame
   beq .turnOffBonusSound           ; unconditional branch

.checkToPlayMonsterRetreatSound
   lda blinkyAttributes             ; get Blinky's attributes
   ora pinkyAttributes              ; combine with Pinky's attributes
   ora inkyAttributes               ; combine with Inky's attributes
   ora clydeAttributes              ; combine with Clyde's attributes
   asl                              ; shift value left (i.e. EYE_STATE in D7)
   bpl .checkToPlayEnergizerSound   ; branch if no monsters in EYE_STATE
   lda frameCount                   ; get the current frame count
   asr #15                          ; make value 0 <= a <= 15 and divide value by 2
   bcs .playEyeSound                ; play retreat sound on odd frames
   lda #-(11 - 1)                   ; turn off retreat sound on even frames
.playEyeSound
   adc #11 - 1                      ; increment value by 11 (i.e. carry set)
.setBonusSoundAttributes
   sta AUDF1                        ; set frequency for 1up sound
   lda #4
   sta AUDC1                        ; set channel for 1up sound
   asl                              ; multiply value by 2
.turnOffBonusSound
.setAudioChannel1Volume
   sta AUDV1
.bplDonePlayGameSounds
   bpl .donePlayGameSounds          ; unconditional branch

.checkToPlayEnergizerSound
   bcc .playSirenSound              ; branch if no monster in BLUE_STATE
.playEnergizerSound
   lda #12
   sta AUDC1                        ; set energizer sound channel
   ldy #3
   bne .setSirenSound               ; unconditional branch

.playSirenSound
   ldy #0
   lda #4
   sta AUDC1                        ; set siren sound channel
   ldx dotsRemaining                ; get number of dots remaining
   cpx #MAX_NUM_DOTS - 73 + 1
   bcs .setSirenSound
   iny                              ; y = 1
   cpx #MAX_NUM_DOTS - 114 + 1
   bcs .setSirenSound
   iny                              ; y = 2
   lda #CRUISE_ELROY1_STATE
   cpx #MAX_NUM_DOTS - 134 + 1
   bcs .setBlinkyCruiseElroyState
   iny                              ; y = 3
   ora #CRUISE_ELROY2_STATE         ; set Blinky to CRUISE_ELROY2_STATE
.setBlinkyCruiseElroyState
   ora gameBoardState
   sta gameBoardState
.setSirenSound
   lda frameCount
   and #$0F                         ; mask upper nybbles
   ora #$10
   tax                              ; move value to x
   lda SirenMaskTable,y
   and frameCount
   beq .setSirenFreq
   txa
   eor #$0F
   sec
   sbc SirenModulatorTable,y
   tax
.setSirenFreq
   stx AUDF1
   lda #4
   sta AUDV1
.skipPlayMonsterSounds
.skipPacmanDeathSound
.skipPlayGameSounds
   rol gameState                    ; rotate game state left
   lsr gameState                    ; shift game state right to clear D7
.donePlayGameSounds

;------------------------------------------------------------------CheckConsoleSwitches
;
; Check the VCS's console switches.
; ------------------------
; SELECT = Select game variation
; RESET  = Restart the game for the selected game variation
;
CheckConsoleSwitches
   ldx #0
   lda SWCHB                        ; load accumulator with console switch value
   lsr                              ; move RESET value to carry
   bcc .startNewGame                ; RESET button pressed
   lsr                              ; move SELECT value to carry
   bcc .selectSwitchDown            ; branch if SELECT button pressed
.selectNotPressed
   stx selectDebounce               ; clear select debounce value
   bcs .endConsoleSwitchCheck       ; unconditional branch

.selectSwitchDown
   bit selectDebounce
   bpl .continueSelectSwitchDown
   lda frameSecondCount             ; delay select debounce ~ every second
   bne .endConsoleSwitchCheck
.continueSelectSwitchDown
   stx frameCount                   ; reset frame counter
   dex                              ; x = -1
   stx selectDebounce               ; show that select switch held down
   bit gameBoardState
   bvc SetToDemoMode                ; set to demo mode if game in progress
.changeGameSelection
   lax gameState                    ; get current game state
   and #LEVEL_SELECTION_MASK        ; mask to get selected level
   cmp #MAX_LEVEL_SELECTION         ; compare with the maximum game selection value
   txa                              ; move gameState back to accumulator
   bcc .incrementGameSelection      ; increment game selection if not reached max
   sbc #MAX_LEVEL_SELECTION + 2     ; clear selected level values (i.e. wrap back to 0)
.incrementGameSelection
   adc #1                           ; carry already clear
   sta gameState                    ; set new game selection value
.endConsoleSwitchCheck

;-----------------------------------------------------------CheckForPacmanDeathSequence
;
CheckForPacmanDeathSequence
   bit playerState                  ; check current player state
   bpl .doneCheckDeathSequence
   ldy pacmanDeathDelay             ; get Pac-man death delay value
   cpy #11 + 1
   bcs .skipRemoveObjects           ; branch if still pausing for death
   jsr RemoveObjects
   ldy pacmanDeathDelay
   lda PacmanDeathAnimationLSB,y    ; get death animation LSB value
   sta pacmanGraphicLSB
   lda PacmanDeathAnimationMSB,y    ; get death animation MSB value
   sta pacmanMSBValue
.skipRemoveObjects
   lda frameCount                   ; get current frame count
   and #7
   bne .jmpToDoneDeterminePacmanNewDirection
   dey
   sty pacmanDeathDelay
   bpl .jmpToDoneDeterminePacmanNewDirection
   lda playerState                  ; get current game state
   and #LIVES_MASK                  ; keep number of lives
   bne .restartLevel                ; restart level if player has lives left
  IF PLUSROM
   jsr SendPlusROMScore
  ENDIF

;-------------------------------------------------------------------------SetToDemoMode
;
SetToDemoMode
   inx                              ; x = 0
.setToDemoMode
   stx gameLevel                    ; set game level back to CHERRY_LEVEL (i.e. x = 0)
   jsr NewLevel
   lda playerState                  ; get current player state
   and #<~(LIVES_MASK | START_GAME_MUSIC); clear number of lives and turn off start up
   sta playerState                  ; music for game start up
   lda #DEMO_MODE
   sta gameBoardState               ; place game in DEMO_MODE
.jmpToSetObjectKernelValues
   jmp BCDToDigits

.restartLevel
   dec playerState                  ; reduce number of remaining lives
   jsr RestartLevel                 ; restart level if death animation done
.jmpToDoneDeterminePacmanNewDirection
   bpl .doneDeterminePacmanNewDirection; unconditional branch

.doneCheckDeathSequence

;-----------------------------------------------------------DeterminePacmanNewDirection
;
DeterminePacmanNewDirection
   lda pacmanAttributes             ; get Pac-man attributes
   bpl .determinePacmanNewDirection ; determine new direction if not delayed
   and #<~PACMAN_DELAY_MASK         ; clear PACMAN_DELAY_MASK
   sta pacmanAttributes
   jmp .donePacmanMove

.doneDeterminePacmanNewDirectionForDemo
   bit INPT4                        ; read left port trigger
   bmi .doneDeterminePacmanNewDirection; unconditional branch
.startNewGame
   jsr StartNewGame                 ; start a new game
   lda #1
   sta levelPauseTimer              ; set pause timer to wait for one frame
   lda playerState                  ; get current player state
   ora #START_GAME_MUSIC
   sta playerState                  ; set to begin start-up tune
   bne .jmpToSetObjectKernelValues  ; unconditional branch

.determinePacmanNewDirection
   ldx eatingMonsterSoundIndex      ; get eating monster sound index
   bne .skipTurnPacmanSoundOff
   stx AUDV0                        ; turn off Pac-man sound if not eating monster
.skipTurnPacmanSoundOff
   ldx #ID_PACMAN
   jsr DetermineAllowedMotion       ; determine if Pac-man at intersection
   sec                              ; set carry so Pac-man slows for DEMO_MODE
   bit gameBoardState               ; check current game board status
   bvs .doneDeterminePacmanNewDirectionForDemo; branch if in DEMO_MODE
   bit gameState                    ; check current game state
   bmi .doneDeterminePacmanNewDirection; skip movement if in NEW_LEVEL_PAUSE
.movePacmanWithJoystick
   lax pacmanAttributes             ; get current Pac-man attributes
   and #PACMAN_DIRECTION_MASK       ; keep current direction value
   tay
   lda DirToJoystickValueTable,y    ; get joystick value based on direction
   eor #P0_NO_MOVE                  ; flip the bit values to look like SWCHA values
   sta diagMotionMask
   lda SWCHA                        ; read joystick values
   and #P0_NO_MOVE
   eor #P0_NO_MOVE                  ; flip the bit values
   beq .joystickNotMoved
.joystickMoved
   and diagMotionMask               ; clear diagonal motion
   and allowedMotion                ; and with allowed motion
   beq .joystickNotMoved            ; branch if direction not allowed
   jsr SetYRegisterToDiv16          ; divide motion value by 16 and place in y
   txa                              ; get current Pac-man attributes
   and #<~PACMAN_DIRECTION_MASK     ; clear the direction values
   ora JoystickDirectionTable - 1,y ; or in new desired direction
   sta pacmanAttributes
   bcc MovePacman                   ; unconditional branch

.joystickNotMoved
   txa                              ; get Pac-man's attributes
   and #PACMAN_DIRECTION_MASK       ; keep the current direction value
   tay
   lda allowedMotion                ; get allowed motion
   and DirToJoystickValueTable,y    ; and with direction joystick values
   beq .bcsToDonePacmanMove         ; branch if direction not allowed (i.e. carry set)
.doneDeterminePacmanNewDirection
;----------------------------------------------------------------------------MovePacman
;
; Determine if it's time to move Pac-man. Decrement Pac-man's motion delay until an
; overflow occurs.
;
MovePacman
   ldx pacmanAteFruit               ; check to see if Pac-man ate fruit
   bne .determinePacmanMotionDelayIndex; branch to bypass movement pause if ate fruit
   lda gameBoardState               ; check current game board state
   ora playerState                  ; or in current player state
   and #GAME_BOARD_DONE | DEATH_SEQUENCE; keep D7
   ora eatingMonsterSoundIndex
   bne .donePacmanMove              ; branch if level done or Pac-man caught
.determinePacmanMotionDelayIndex
   lda motionDelayIndex             ; get motion delay index for level
   ldx energizerValues              ; get energizer time
   beq .performPacmanFrameDelay     ; branch if energizer time over
   ora #4                           ; increment by 4 for Pac-man blue time delay index
.performPacmanFrameDelay
   tay                              ; move frame delay to y-register
   bcc .movePacman                  ; skip frame delay if Pac-man changing direction
   lda pacmanMotionDelay            ; get Pac-man motion delay value
   sbc PacmanDelayTable,y           ; decrement delay value for level (i.e. carry set)
   sta pacmanMotionDelay
.bcsToDonePacmanMove
   bcs .donePacmanMove              ; skip movement routine if not time
.movePacman
   lda pacmanAttributes             ; get Pac-man's attributes
   bit gameBoardState               ; check current game board status
   bvc .skipDemoMovement            ; branch if not in DEMO_MODE
   and #PACMAN_DIRECTION_MASK       ; clear the direction values
   tay
   lda allowedMotion
   and ReverseDirToJoystickValueTable,y; clear direction so Pac-man can't reverse
   sta allowedMotion                ; direction in DEMO_MODE
   jsr BlueMonsterAI                ; use a random direction for Pac-man in DEMO_MODE
.setPacmanDemoDirection
   lda pacmanAttributes             ; get current Pac-man attributes
   and #<~PACMAN_DIRECTION_MASK     ; clear the direction values
   ora JoystickDirectionTable - 1,y ; or in new desired direction
   sta pacmanAttributes
.skipDemoMovement
   lsr                              ; shift Pac-man horizontal direction to carry
   bcs .pacmanMovingHorizontally
.pacmanMovingVertically
   lsr                              ; shift down direction to carry
   php                              ; push status flag to stack
   lda pacmanVertPos                ; get Pac-man vertical position
   bcc .pacmanMovingUp
.pacmanMovingDown
   sbc #2 + 3                       ; reduce Pac-man vertical position by 2
.pacmanMovingUp
   adc #2                           ; increment Pac-man vertical position by 2
   sta pacmanVertPos                ; set Pac-man new vertical position
   lsr                              ; divide value by 4 to reduce animation rate
   asr #6                           ; make the value 0 <= a <= 3
   ora #4                           ; set for vertical animation
   plp                              ; pull status flag from stack
   bcc .setPacmanGraphicLSBIndex    ; branch to set up upward animation sprites
   eor #12                          ; go pass upward sprite animation spites
   bne .setPacmanGraphicLSBIndex    ; unconditional branch

.pacmanMovingHorizontally
   ldx pacmanHorizPos               ; get Pac-man horizontal position
   lsr                              ; shift left direction to carry
   bcc .pacmanMovingRight
.pacmanMovingLeft
   dex                              ; reduce Pac-man horizontal position
   cpx #XMIN - 1                    ; see if Pac-man wraps around to right
   dex
   bcs .setPacmanReflectState
   ldx #XMAX - 2
.pacmanMovingRight
.setPacmanReflectState
   inx                              ; increment Pac-man horizontal position
   cpx #XMAX
   bcc .setPacmanHorizontalPosition
   ldx #XMIN - 1
.setPacmanHorizontalPosition
   stx pacmanHorizPos
   txa                              ; get Pac-man horizontal position
   lsr                              ; divide value by 4
   asr #6                           ; make the value 0 <= a <= 3
.setPacmanGraphicLSBIndex
   tay
.setPacmanGraphicLSB
   lda PacmanAnimationTable,y       ; read LSB value for the horizontal graphics
   sta pacmanGraphicLSB
.donePacmanMove
   ldy pacmanGraphicLSB

;---------------------------------------------------------------------CheckForLevelDone
;
; Check the dotsRemaining to determine if the level is done. If so then...
; (1) set the gameBoardState flag to show to flash the screen
; (2) set Pac-man stationary animation
; (3) reset frameCount for flash timer
; (4) move monsters off the screen
;
CheckForLevelDone SUBROUTINE
   lda gameBoardState               ; get the current game board status
   bmi .setObjectStatesForLevelDone ; branch if value already set from before
   ldx dotsRemaining                ; check number of dots remaining
   bne .levelNotDone                ; branch if level not done
   ora #GAME_BOARD_DONE
   sta gameBoardState               ; set level done flag
   stx frameCount                   ; reset frame count (i.e. x = 0)
   stx AUDV0                        ; turn off Pac-man sounds
   stx AUDV1                        ; turn off monster sounds
.setObjectStatesForLevelDone
   jsr RemoveObjects
   ldy #<PacmanStationary - H_KERNEL - 1; set Pac-man stationary animation
.levelNotDone
   sty pacmanLSBValue

;------------------------------------------------------------------------CollisionCheck
;
; Check all game collisions.
;
CollisionCheck SUBROUTINE
   ldy #0
   ldx #ID_FRUIT
   bit playerState                  ; check player death flag
   bmi .bmiDoneCollisionCheck       ; branch if player dieing
   lda eatenMonsterNumber           ; see if Pac-man is eating a monster
   bpl .doneCollisionCheck          ; skip collision check if Pac-man eating a monster
.checkObjectCollisions
   lda pacmanVertPos                ; get Pac-man's vertical position
   sec
   sbc objectVertPos,x              ; subtract object's vertical position
   jsr CheckCollisionRange
   bcs .checkNextObject
   lda pacmanHorizPos               ; get Pac-man's horizontal position
   sec
   sbc objectHorizPos,x             ; subtract object's horizontal position
   jsr CheckCollisionRange
   bcs .checkNextObject
   cpx #ID_FRUIT
   bne .checkMonsterCollisions      ; branch if not collided with fruit
   lda gameBoardState               ; get current game board state
   and #FRUIT_SHOW                  ; check fruit shown flag
   beq .checkNextObject             ; branch if fruit not shown
   stx pacmanAteFruit               ; set to any non-zero value
   sty fruitTimer                   ; clear fruit timer (i.e. y = 0)
   jsr SetIndexFromGameLevel        ; sets game level to y register
   tya                              ; move level index to x register
   tax
   ldy FruitHighScoreTable,x
   lda FruitLowScoreTable,x
   bpl .incrementScoreForBonus      ; unconditional branch

.checkMonsterCollisions
   lda monsterAttributes,x          ; get the monster attributes
   asl                              ; shift EYE_STATE to D7
   bmi .checkNextObject             ; branch if Pac-man collided with eyes
   sty pacmanAteFruit               ; clear Pac-man ate fruit value (i.e. y = 0)
   bcs .pacmanAteMonster            ; branch if Pac-man ate monster

   IF CHEAT_ENABLE

      FILL_NOP 26                   ; fill with 26 NOPs if cheat enabled

   ELSE

   sty AUDV0                        ; turn off Pac-man sounds
   sty AUDV1                        ; turn off monster sounds
   asl pacmanAttributes             ; shift Pac-man attributes left
   lsr pacmanAttributes             ; shift right to clear dot delay value
   lda #20
   sta deathSoundIndex
   lda #17
   sta pacmanDeathDelay             ; set Pac-man death delay value
   rol playerState                  ; rotate player state left
   lsr                              ; divide value by 2 and set carry bit
   ror playerState                  ; rotate carry to D7 to set DEATH_SEQUENCE flag
   sta deathSoundFreq               ; set death sound frequency to 8
   NOP_B                            ; skip next byte

   ENDIF

.checkNextObject
   dex
   bpl .checkObjectCollisions
.bmiDoneCollisionCheck
   bmi .doneCollisionCheck          ; unconditional branch

.pacmanAteMonster
   lsr                              ; clear monster BLUE_STATE
   ora #EYE_STATE                   ; set monster to EYE_STATE
   sta monsterAttributes,x
   stx eatenMonsterNumber           ; set to show which monster was eaten
   sty pacmanColor                  ; blank out Pac-man color (i.e. y = 0)
   lda gameBoardState               ; get current game board state
   and #MONSTER_EATEN_MASK          ; keep number of monsters eaten so far
   tax
   ldy MonsterHighScoreTable,x
   lda MonsterLowScoreTable,x
   inc gameBoardState               ; increment number of monsters eaten
.incrementScoreForBonus
   jsr IncrementScore               ; increment score for eating monster
   lda #INIT_PACMAN_ATE_BONUS_INDEX
   sta eatingMonsterSoundIndex      ; set eating monster sound index to play sound
.doneCollisionCheck

;--------------------------------------------------------------------CheckForEatingDots
;
; See if Pac-man is eating a dot. If so then slow him down for one frame. Also
; increment the score accordingly. We have to take the energizers in account here too.
; Their *real* value is not stored in the dot array like the rest of the dots. The
; energizer blink state is stored in the dot array because it's used by the kernel for
; drawing purposes. The real energizer values are stored in D5 - D2 of
; pacmanAttributes.
;
CheckForEatingDots
   lda pacmanVertPos                ; get vertical position of Pac-man
   sec
   sbc #YMIN                        ; subtract the lowest possible value
   tax                              ; move to x temporarily
   and #7                           ; see if value is divisible by 8
   bne .branchToDoneEatingDots      ; leave if not eating dots
   txa
   lsr                              ; divide value by 8 to get dot row
   lsr
   lsr
   tax                              ; x now holds row for RAM pointer
   lda pacmanHorizPos               ; get horizontal position of Pac-man
   cmp #XMAX - 10
   bcs .bcsDoneEatingDots           ; skip processing if out of range
   cmp #PACMAN_START_X - 2
   bcc .pacmanOnLeftSide
   cmp #[XMAX / 2] + 16 - 1
   bcc .bccDoneEatingDots
.pacmanOnRightSide
   sbc #33                          ; carry set -- subtract right min value
   tay
   txa
   adc #DOT_SECTIONS - 1
   tax
   tya
   bcc .skipLeftSideProcessing      ; unconditional branch

.pacmanOnLeftSide
   sbc #DOT_SECTIONS                ; carry clear here -- subtract min x value
   bcc .bccDoneEatingDots           ; done eating dots if out of range
.skipLeftSideProcessing
   tay                              ; move to y temporarily
   and #7                           ; see if value is divisible by 8
.branchToDoneEatingDots
   bne .bccDoneEatingDots           ; leave if not eating dots
   tya
   lsr                              ; divide by 8 to get bit masking value
   lsr
   lsr
   beq .checkForEatingEnergizer     ; if zero then in energizer zone
   cmp #15
   bne .notEatingEnergizer          ; if 15 then in energizer zone
.checkForEatingEnergizer
   tay                              ; move bit masking value to y register
   lda #NE_ENERGIZER_MASK_VALUE     ; get NE_ENERGIZER_MASK_VALUE
   cpx #NE_ENERGIZER_RAM_PTR
   beq .pacmanEatingEnergizer       ; branch if in NE energizer position
   lsr                              ; shift to get NW_ENERGIZER_MASK_VALUE
   cpx #NW_ENERGIZER_RAM_PTR
   beq .pacmanEatingEnergizer       ; branch if in NW energizer position
   lsr                              ; shift to get SW_ENERGIZER_MASK_VALUE
   cpx #SW_ENERGIZER_RAM_PTR
   beq .pacmanEatingEnergizer       ; branch if in SW energizer position
   lsr                              ; shift to get SE_ENERGIZER_MASK_VALUE
   cpx #SE_ENERGIZER_RAM_PTR
   beq .pacmanEatingEnergizer       ; branch if in SE energizer position
   tya                              ; move bit masking value to accumulator
.notEatingEnergizer
   cmp #7 + 1
   bcc .determineDotEaten
   eor #$0F
.determineDotEaten
   tay
   lda DotMaskingBits,y             ; read the dot masking values
   eor mazeDots,x                   ; flip the bits to remove dot from array
   cmp mazeDots,x                   ; see if dot already eaten
   bcs .doneEatingDots              ; branch if dot already eaten
   sta mazeDots,x                   ; set new dot value
   lda #DOT_SCORE
.incrementScoreForEatingDot
   jsr IncrementTensPosition
   dec dotsRemaining                ; reduce number of dots remaining
   asl pacmanAttributes             ; shift Pac-man attributes left
   sec                              ; set carry bit
   ror pacmanAttributes             ; rotate right to set Pac-man dot delay value
.bccDoneEatingDots
   sec
.bcsDoneEatingDots
   bcs .doneEatingDots              ; unconditional branch

.pacmanEatingEnergizer
   bit pacmanAttributes             ; see if energizer already eaten
   beq .doneEatingDots              ; bit used to save contents of accumulator
   eor #$FF                         ; flip the bits
   and pacmanAttributes             ; and value to remove dot from array
   sta pacmanAttributes
   lda gameBoardState               ; get current game board state
   and #<~MONSTER_EATEN_MASK        ; clear number of monsters eaten so far
   sta gameBoardState
   ldy gameLevel                    ; get the current game level
   cpy #MAX_BLUE_TIME_LEVEL         ; compare with maximum blue time value
   bcc .setBlueTime
   ldy #MAX_BLUE_TIME_LEVEL
.setBlueTime
   lda EnergizerTimeTable,y
   sta energizerValues              ; set energizer time for game board
   beq .skipSetMonsterToBlueState   ; skip setting monter to BLUE_STATE if no time
   ldx #NUM_MONSTERS - 1
.setMonstersToBlueState
   rol monsterAttributes,x          ; shift EYE_STATE to D7
   bmi .setNextMonster              ; branch if monster in EYE_STATE
   sec                              ; set carry bit to set to BLUE_STATE
.setNextMonster
   ror monsterAttributes,x          ; restore monster attribute value
   dex
   bpl .setMonstersToBlueState
.skipSetMonsterToBlueState
   brk                              ; branch to reverse monster directions
.setEnergizerScore
   lda #ENERGIZER_SCORE
   bne .incrementScoreForEatingDot  ; unconditional branch

.doneEatingDots

;-----------------------------------------------------------------------BlinkEnergizers
;
; Blink the energizers ever 8th frame.
;
BlinkEnergizers
   ldy #3 + 1
   lda pacmanAttributes             ; get Pac-man attributes
   asr #ENERGIZER_VALUE_MASK        ; mask out all but energizer values and shift
   lsr                              ; energizer values down to lower nybbles
   sta tempEnergizerValues          ; save in temp variable to shift values
.blinkEnergizers
   ldx EnergizerRAMLocations - 1,y  ; read the RAM location for energizer
   asl mazeDots,x                   ; shift dot array left
   lda blinkEnergizerOnValue        ; get blink energizer value
   clc                              ; clear carry
   bne .blinkEnergizersOff          ; blink off if not time to show it
   lsr tempEnergizerValues          ; shift energizer value to carry
.blinkEnergizersOff
   ror mazeDots,x                   ; rotate right to set energizer value
   dey
   bne .blinkEnergizers

;--------------------------------------------------------------------CheckToEnableFruit
;
; The fruit is shown twice during a round and is based on the number of dots Pac-man
; has eaten. The number of dots in my game is less than the number of dots in the
; arcade version.
;
; The first fruit is shown after 44 dots have been eaten (i.e. ~29%). The second fruit
; is shown after 107 dots have been eaten (i.e. ~69%).
;
CheckToEnableFruit
   lda fruitTimer
   bne .reduceFruitTimer            ; reduce fruit timer if fruit present
   ldx dotsRemaining                ; get the number of dots remaining
   lda score + 2                    ; get score value
   lsr                              ; shift FIRST_FRUIT_SHOWN to D7 and
   lsr                              ; shift SECOND_FRUIT_SHOWN to carry
   ror
   bcs .turnOffFruit                ; branch if second fruit already shown
   bmi .checkToTurnOnSecondFruit    ; branch if first fruit already shown
   cpx #MAX_NUM_DOTS - 44
   bne .turnOffFruit                ; branch if first number of dots not reached
   lda #FIRST_FRUIT_SHOWN           ; set status to show first fruit has been shown
   bne .setFruitShownState          ; unconditional branch

.checkToTurnOnSecondFruit
   cpx #MAX_NUM_DOTS - 107
   bne .turnOffFruit                ; branch if second number of dots not reached
   lda #SECOND_FRUIT_SHOWN          ; set status to show second fruit has been shown
.setFruitShownState
   ora score + 2                    ; set the state to show which fruit was shown
   sta score + 2
   lda #FRUIT_TIMER
   sta fruitTimer                   ; init the fruit timer for ~15 seconds
   lda gameBoardState               ; get current game board state
   ora #FRUIT_SHOW
   ldx #FRUIT_START_Y               ; set fruit vertical position
   bne .setFruitVertPos             ; unconditional branch

.reduceFruitTimer
   lda gameBoardState               ; get current game board state
   and #FRUIT_SHOW
   beq .turnOffFruit                ; branch if fruit not shown
   lda pacmanColor                  ; get Pac-man color
   beq .doneFruitCheck              ; don't reduce timer if showing monster points
   lda frameCount                   ; get current frame count
   asr #$3F                         ; shift D0 to carry
   bcs .doneFruitCheck              ; branch if on an odd frame
   bne .doneFruitCheck
   dec fruitTimer
   bne .doneFruitCheck
.turnOffFruit
   lda gameBoardState               ; get current game board state
   and #<~FRUIT_SHOW
   ldx #H_KERNEL + H_OBJECTS        ; place fruit out of range
.setFruitVertPos
   stx fruitVertPos
   sta gameBoardState               ; set new game board state
.doneFruitCheck

;-----------------------------------------------------------------SetObjectKernelValues
;
; Calculate the object's kernel section and set it's color for display.
;
SetObjectKernelValues
   ldx #MAX_NUM_OBJ - 1
.setObjectKernelValues
   cpx #ID_FRUIT
   bne .setMonsterColor             ; branch if not fruit id
   jsr SetIndexFromGameLevel        ; set y to index for current fruit level
   lda FruitOffsetTable,y
   clc
   adc #<(FruitSprites - H_OBJECTS - H_KERNEL - 1)
   sta fruitGraphicLSB              ; set fruit LSB value
   tya                              ; move fruit index value to accumulator
   lsr                              ; divide value by 2
   tay
   lda FruitColorsTable,y
   bne .setObjectColor              ; unconditional branch

.setMonsterColor
   lda monsterAttributes,x          ; get monster's attributes
   bmi .setMonsterToBlue            ; branch if monster in BLUE_STATE
   asl                              ; shift EYE_STATE to D7
   bmi .setMonsterEyeColor          ; branch if monster in EYE_STATE
   lda MonsterColorTable,x          ; get monster normal color from table
   bne .setObjectColor              ; unconditional branch

.setMonsterToBlue
   lda energizerValues              ; get energizer value
   cmp #(5 << 4)                    ; monsters to blink 5 times
   bcs .dontBlinkMonsters
   and #8
   bne .setMonsterEyeColor
.dontBlinkMonsters
   lda #BLUE_MONSTER_COLOR          ; set accumulator for blue color state
   NOP_W                            ; skip next 2 bytes :-)
.setMonsterEyeColor
   lda #EYE_COLOR                   ; set accumulator for eye color state
.setObjectColor
   sta objectColors,x               ; set monster color value
.calculateKernelSection
   dex
   bpl .setObjectKernelValues

;---------------------------------------------------------------------------BCDToDigits
;
; Convert the score into game fonts. The leading zeros are suppressed so they are not
; shown.
;
BCDToDigits
   ldy #2
   ldx #10 + 2
.bcdToDigitsLoop
   lda score,y                      ; get score digit
   and #$0F                         ; mask upper nybbles
   asl                              ; multiply value by 8 (i.e. height of font)
   asl
   asl
   sta graphicPointers - 2,x        ; set digit LSB value
   lda #>NumberFonts                ; get MSB of number fonts
   sta graphicPointers - 1,x        ; set digit MSB value
   dex
   dex
   beq .suppressZeros               ; branch to suppress zeros when done
   sta graphicPointers - 1,x        ; set digit MSB value
   lda score,y                      ; get score digit
   asr #$F0                         ; keep upper nybbles and divide value by 2
   sta graphicPointers - 2,x        ; set digit LSB value
   dex
   dex
   dey
   bpl .bcdToDigitsLoop             ; unconditional branch

.suppressZeros
   ldy #<Blank
.suppressZeroLoop
   lda graphicPointers,x            ; cycle through the digit pointers
   bne .skipSuppressZero            ; branch if value is not zero
   sty graphicPointers,x            ; set LSB to space if one is found
   inx
   inx
   cpx #8                           ; keep the last 2 zeroes
   bcc .suppressZeroLoop
.skipSuppressZero

;--------------------------------------------------------------------------VerticalSync
;
; This routine will take care of vertical sync house keeping. Vertical sync starts a
; new television frame. Each frame starts with 3 vertical sync lines. These signal to
; to the television to start a new frame.
;
VerticalSync SUBROUTINE
.waitTime
   ldy INTIM                        ; wait for overscan period to end
   bne .waitTime
   ldx #VBLANK_TIME                 ; used to set timer for vertical blanking period
   VERTICAL_SYNC                    ; vertical sync macro
   stx TIM64T                       ; set timer for vertical blank wait
   inc frameCount                   ; frame count is update every frame
   bne .setCurrentObjectId
   lda playerState                  ; get current player state
   and #<~START_GAME_MUSIC          ; clear the START_GAME_MUSIC flag
   sta playerState
.setCurrentObjectId
   dec objectId                     ; reduce object id
   bpl .skipObjectWrap              ; branch if not time to roll over value
   ldx #2                           ; wrap object id to maximum value
   stx objectId
.skipObjectWrap
   sty GRP0                         ; clear player graphic data from kernel execution
   sty GRP1
   lda gameBoardState               ; get the current game board state
   bmi .jmpToDoneMoveMonsters       ; branch if level done
   bit playerState                  ; check the current player state
   bpl MoveMonsters                 ; branch if Pac-man not caught
   ldx pacmanDeathDelay             ; get Pac-man death delay value
   cpx #11 + 1
   bcs MoveMonsters                 ; branch to set monster graphic pointers
.jmpToDoneMoveMonsters
   jmp .doneMoveMonster             ; branch if game board done

;-------------------------------------------------------------------CheckCollisionRange
;
CheckCollisionRange
   bcs .checkCollisionRange
NegateValue
   eor #$FF                         ; negate value
   adc #1                           ; carry already clear
.checkCollisionRange
   cmp #COLLISION_RANGE + 1         ; determine carry bit
   rts

;--------------------------------------------------------------------------MoveMonsters
;
; Loop through each monster to see if it's time to be moved. This routine also changes
; the monster direction if they're at an intersection.
;
MoveMonsters
   ldx #NUM_MONSTERS - 1
.moveMonsterLoop
   lda playerState                  ; get the current player state
   bmi .bneCheckNextMonster         ; branch if in death sequence (don't move monsters)
   lda monsterAttributes,x          ; get monster's attributes
   sta tempMonsterAttribute
   asl                              ; shift EYE_STATE to D7
   bmi .determineMonsterAllowedMotion; branch if monster in EYE_STATE
   and #RELEASE_TIME << 1           ; keep monster release time
   cmp #((1 << 2) + 1) << 1
   bcc .skipReleaseTimeReduction    ; branch if monster leaving pen or not in pen
   lda frameSecondCount             ; get current frame seconds count
   bne .skipReleaseTimeReduction
   lda monsterAttributes,x          ; get monster's attributes
   sbc #(1 << 2)                    ; reduce release time by 1...carry set
   sta monsterAttributes,x
.skipReleaseTimeReduction
.determineToMoveMonster
   lda pacmanAteFruit               ; check to see if Pac-man ate fruit
   bne .moveMonster                 ; branch to bypass movement pause if fruit eaten
   ldy eatingMonsterSoundIndex      ; get eating monster sound index
.bneCheckNextMonster
   bne .secondBNECheckNextMonster
   dey                              ; y = -1
   sty eatenMonsterNumber           ; set to show no monster eaten
   lda #PACMAN_COLOR
   sta pacmanColor                  ; reset Pac-man color...not showing monster points
.moveMonster
   lda motionDelayIndex             ; get motion delay index for the level
   asl                              ; multiply value by 4
   asl
   adc motionDelayIndex             ; add in original so value * 5
   tay                              ; y set to pointer to MonsterDelayTable
   lda monsterAttributes,x
   bmi .determineMonsterFrameDelay  ; branch if monster in BLUE_STATE
   iny                              ; increment for SPEED_MONSTER_SLOW
.checkForMonsterInTunnel
   lda monsterVertPos,x             ; get the monster vertical position
   cmp #92
   bne .monsterNotInTunnel          ; branch if monster not in tunnel
   lda monsterHorizPos,x
   cmp #46 - 1
   bcc .determineMonsterFrameDelay
   cmp #130 - 1
   bcs .determineMonsterFrameDelay  ; branch if monster in tunnel
.monsterNotInTunnel
   iny                              ; increment for SPEED_MONSTER_NORMAL
   txa
   bne .determineMonsterFrameDelay  ; branch if monster in NORMAL_STATE
   lda gameBoardState               ; get game board state
   and #CRUISE_ELROY_STATE
   beq .determineMonsterFrameDelay  ; branch if Blinky in NORMAL_STATE
   iny                              ; increment for CRUISE_ELROY2
   asl
   asl
   bmi .determineMonsterFrameDelay  ; branch if Blinky in CRUISE_ELROY2_STATE
   iny                              ; increment for CRUISE_ELROY1
.determineMonsterFrameDelay
   sec
   lda objectMotionDelays,x         ; get monster motion delay value
   sbc MonsterDelayTable,y          ; subtract delay value for level
   sta objectMotionDelays,x
   bcs .checkNextMonster            ; skip movement routine if not time
.determineMonsterAllowedMotion
   cpx eatenMonsterNumber           ; check to see if monster was eaten
   beq .setMonsterPointSprite       ; branch if showing monster points
   jsr DetermineAllowedMotion       ; determine if monster at intersection
   lda monsterAttributes,x          ; get monster's attributes
   and #MONSTER_DIRECTION_MASK      ; get monster current direction
   tay
   lda allowedMotion                ; get valid directions for monster
   and ReverseDirToJoystickValueTable,y; don't allow monster to reverse
   jsr MonsterAI                    ; do monster AI routine
   lda monsterAttributes,x          ; get monster's attributes
   and #<~MONSTER_DIRECTION_MASK    ; clear current direction value
   ora JoystickDirectionTable - 1,y
   sta monsterAttributes,x          ; set new monster direction
   lsr                              ; shift monster horiz direction to carry
   bcs .monsterMovingHorizontally
.monsterMovingVertically
   lsr                              ; shift down direction to carry
   lda objectVertPos,x              ; get monster vertical position
   bcc .monsterMovingUp
.monsterMovingDown
   sbc #2 + 3                       ; reduce vertical position by 2
.monsterMovingUp
   adc #2                           ; increment vertical position by 2
.setMonsterVeritalPosition
   sta objectVertPos,x              ; store new monster vertical position
.secondBNECheckNextMonster
   bne .checkNextMonster            ; unconditional branch...never 0

.monsterMovingHorizontally
   ldy objectHorizPos,x             ; get monster horizontal position
   lsr
   bcc .monsterMovingRight
.monsterMovingLeft
   dey                              ; reduce monster horizontal position
   cpy #XMIN - 1
   bcs .setMonsterHorizontalPosition; branch if monster not reached left side
   ldy #XMAX - 2                    ; wrap monster to right side
.monsterMovingRight
   iny                              ; increment monster horizontal position
   cpy #XMAX
   bcc .setMonsterHorizontalPosition; branch if monster not reached right side
   ldy #XMIN - 1                    ; wrap monster to left side
.setMonsterHorizontalPosition
   sty objectHorizPos,x
.checkNextMonster
   ldy monsterAnimationFrame        ; get monster animation frame value
   lda monsterAttributes,x          ; get monster's attributes
   bmi .setMonsterBlueAnimation     ; branch if monster in BLUE_STATE
   asl                              ; shift EYE_STATE to D7
   bmi .setMonsterEyeAnimation      ; branch if monster in EYE_STATE
   lsr                              ; restore accumulator value
   lsr                              ; shift monster horiz direction to carry
   bcs .setMonsterHorizontalAnimation
.setMonsterVerticalAnimation
   ldy monsterAnimationFrame        ; get monster animation frame value
   lsr                              ; shift down direction to carry
   bcs .setMonsterDownAnimation
.setMonsterUpAnimation
   iny                              ; increment y for up animation
   bne .setMonsterAnimationValues   ; unconditional branch

.setMonsterHorizontalAnimation
   iny                              ; increment y for horizontal animation
   iny
.setMonsterDownAnimation
.setMonsterAnimationValues
   lda MonsterAnimationTable,y
.setMonsterAnimationMSBValue
   ldy #>MonsterAnimationSprites
   bmi .setMonsterGraphicsPointers  ; unconditional branch

.setMonsterBlueAnimation
   tya                              ; move monster animation frame to accumulator
   jsr SetYRegisterToDiv8           ; divide value by 8 and set y register
   lda MonsterBlueAnimationTable,y
   bne .setMonsterAnimationMSBValue ; unconditional branch

.setMonsterPointSprite
   lda gameBoardState               ; get current game board state
   and #MONSTER_EATEN_MASK          ; keep number of monsters eaten so far
   tay
   lda MonsterPointsLSB - 1,y       ; get LSB value for monster points
   NOP_W                            ; skip next 2 bytes
.setMonsterEyeAnimation
   lda #<MonsterEyes - H_KERNEL     ; get the LSB value for monster eye sprite
   ldy #>MonsterEyes
.setMonsterGraphicsPointers
   sta objectGraphicLSB,x           ; set graphic pointer LSB value
   sty objectMSBValues,x            ; set graphic pointer MSB value
.nextMonster
   dex
   bmi .doneMoveMonster
   jmp .moveMonsterLoop

.doneMoveMonster
   ldx frameCount                   ; get current frame count
   lda gameBoardState               ; get current game board state
   asl                              ; move GAME_BOARD_DONE to carry and DEMO_MODE to D7
   bmi .setScoreColor               ; branch if in demo mode
   ldx #WHITE
.setScoreColor
   stx COLUP0                       ; set the color for the score digits
   stx COLUP1
   ldy #MAZE_COLOR
   lax frameCount                   ; get current frame count
   bcc .setMazeColor                ; set maze color if level not done
   and #16
   bne .setMazeColor
   ldy #WHITE
   txa                              ; move frame count to accumulator
   bpl .setMazeColor
   asl gameBoardState               ; rotate GAME_BOARD_DONE to carry
   lsr gameBoardState               ; rotate right to clear GAME_BOARD_DONE
   inc gameLevel                    ; increment game level
   jsr NewLevel
.setMazeColor
   sty mazeColor
   ldy #H_SCORE - 1

;-------------------------------------------------------------------------DisplayKernel
;
; The screen must be updated each frame on the 2600. Here the program waits for
; vertical blank period to end and then displays the game screen.
;
DisplayKernel SUBROUTINE
.waitTime
   ldx INTIM                        ; big timer wait
   bne .waitTime
   stx WSYNC                        ; end the current scan line
;--------------------------------------
   stx VBLANK                 ; 3         set TIA value for output (i.e. D1 = 0)
   sta HMOVE                  ; 3 = @06   new line...position players horizontally
;
; The famous 48-pixel display slightly modified to save a few bytes. Thanks Kurt.
;
DrawIt
   lda (graphicPointers),y    ; 5
   sta GRP0                   ; 3 = @72
   sta WSYNC
;--------------------------------------
   lda (graphicPointers + 2),y; 5
   sta GRP1                   ; 3 = @08
   lda (graphicPointers + 4),y; 5
   sta GRP0                   ; 3 = @16
   lda (graphicPointers + 6),y; 5
   sta digitHundredthsGraphic ; 3
   lax (graphicPointers + 8),y; 5
   lda zero,y                 ; 4         last digit always zero
   dey                        ; 2
   sty fontHeight             ; 3
   ldy digitHundredthsGraphic ; 3
   sty GRP1                   ; 3 = @44
   stx GRP0                   ; 3 = @47
   sta GRP1                   ; 3 = @50
   sty GRP0                   ; 3 = @53
   ldy fontHeight             ; 3
   bpl DrawIt                 ; 2³

   CHECKPAGE DrawIt

   ldy #2                     ; 2 = @60
   sec                        ; 2
   sta WSYNC
;--------------------------------------
   ldx objectId               ; 3         set x to current object id
   inx                        ; 2
   inx                        ; 2
   inx                        ; 2
.movePlayersLoop
   lda object0HorizPos,x      ; 4
.movePlayers
   sbc #15                    ; 2       divide the player's horizontal position by 15
   bcs .movePlayers           ; 2³
   sta RESP0 - 1,y            ; 5       set the player's course horizontal position
   sta WSYNC
;--------------------------------------
   eor #7                     ; 2
   asl                        ; 2
   asl                        ; 2
   asl                        ; 2
   asl                        ; 2
   sta HMP0 - 1,y             ; 5 = @15 set the player's fine horizontal position
   dey                        ; 2
   beq .doneMovePlayers       ; 2³
   dex
   sta WSYNC
;--------------------------------------
   dex                        ; 2
   dex                        ; 2
   sec                        ; 2
   bcs .movePlayersLoop       ; 3 unconditional branch

.doneMovePlayers
   cpx #1                     ; 2
   sty HMBL                   ; 3 = @25
   sty VDELP1                 ; 3 = @28   turn off VDELP1 (i.e. y = 0)
   beq .reflectNotNeededForGRP1;2³        reflection not needed for fruit sprite
   lda monsterAttributes + 3,x; 4         get object attributes (i.e. Pac-man or Clyde)
   bcs .setReflectForPacman   ; 2³        branch if object is Pac-man
   asl                        ; 2         shift EYE_STATE to D7
   bmi .reflectNotNeededForGRP1;2³        branch if in EYE_STATE
   bcs .reflectNotNeededForGRP1;2³        branch if monter is BLUE
   lsr                        ; 2
.setReflectForPacman
   asl                        ; 2         shift left direction value to D3
   asl                        ; 2
   sta REFP1                  ; 3 = @51   set the reflective state of GRP1
.reflectNotNeededForGRP1
   lda monsterAttributes,x    ; 4         get monster attributes
   bmi .reflectNotNeededForGRP0;2³        branch if monster is BLUE
   asl                        ; 2         shift left direction value to D3
   asl                        ; 2
   bcs .reflectNotNeededForGRP0;2³        monster EYE_STATE in carry
   sta REFP0                  ; 3 = @66   set the reflective state of GRP0
.reflectNotNeededForGRP0
   lda #H_KERNEL              ; 2
   sta WSYNC
;--------------------------------------
   sec                        ; 2
   sbc object0VertPos,x       ; 4
   adc #H_OBJECTS - 2         ; 2         subtract 2 because this player is VDEL'd
   sta object0OffsetValues,x  ; 4
   adc objectGraphicLSB,x     ; 4
   sta object0LSBValues,x     ; 4 = @20
   lda #H_KERNEL              ; 2
   sec                        ; 2
   sbc object1VertPos,x       ; 4
   adc #H_OBJECTS - 1         ; 2
   sta object1OffsetValues,x  ; 4
   adc object1GraphicLSB,x    ; 4
   cpx #1                     ; 2         set carry if object is Pac-man or the fruit
   sbc #1 - 1                 ; 2         so subtracts 1 if the object is Clyde
   sta object1LSBValues,x     ; 4
   lda object1MSBValues,x     ; 4         set object graphic pointer data
   sta object1GraphicPtr + 1  ; 3 = @53
   lda object1LSBValues,x     ; 4
   sta object1GraphicPtr      ; 3 = @60
   lda object1OffsetValues,x  ; 4
   sta object1Offset          ; 3 = @67   set object offset value
   lda object1Colors,x        ; 4         read color value for object
   sta HMOVE                  ; 3 = @74
;--------------------------------------
   sta COLUP1                 ; 3 = @01   set object color
   lda object0Colors,x        ; 4         read color value for object
   sta COLUP0                 ; 3 = @08   set object color
   lda object0MSBValues,x     ; 4         set object graphic pointer data
   sta objectGraphicPtr + 1   ; 3
   lda object0LSBValues,x     ; 4
   sta objectGraphicPtr       ; 3
   lda object0OffsetValues,x  ; 4
   ldx #<ENABL - 1            ; 2
   txs                        ; 2         set stack to ENABL for chamber door
   sta WSYNC
;--------------------------------------
   sta objectOffset           ; 3         set object offset value
   sty NUSIZ0                 ; 3 = @06   set to show ONE_COPY of the players
   sty NUSIZ1                 ; 3 = @09
   tya                        ; 2         set accumulator to 0 (i.e. y = 0)
   ldx #DOT_SECTIONS          ; 2
   stx kernelSection          ; 3 = @16   initialize kernel section value
   ldy #H_KERNEL              ; 2
   clc                        ; 2 = @20   clear carry to prepare to jump into kernel
   jmp JumpIntoKernel         ; 3 = @23

;----------------------------------------------------------------------MoveMonsterInPen
;
MoveMonsterInPen
   cmp #(1 << 2) << 1
   beq .moveMonsterOutOfPen         ; move out of pen if release time reached 1
   lsr
   lsr
   lsr                              ; shift vertical direction to carry
   lda objectVertPos,x              ; get monster vertical position
   bcs .monsterMovingDownInPen
.monsterMovingUpInPen
   cmp #PINKY_START_Y + 2
   NOP_W                            ; skip next 2 bytes
.monsterMovingDownInPen
   cmp #INKY_START_Y
   bcc .moveMonsterUpInPen
.moveMonsterDownInPen
   ldy #MY_MOVE_DOWN >> 4
   rts

.moveMonsterOutOfPen
   lda objectHorizPos,x             ; get monster horizontal position
   cmp #BLINKY_START_X
   bne .moveMonsterInPen            ; branch if monster stays in pen
.releaseMonsterFromPen
   lda objectVertPos,x              ; get monster vertical position
   cmp #BLINKY_START_Y
   bcc .moveMonsterUpInPen          ; monster up if haven't reached outside of pen
   lda monsterAttributes,x          ; get monster attributes
   and #<~RELEASE_TIME              ; clear RELEASE_TIME as monster is out of pen
   sta monsterAttributes,x
.moveMonsterInPen
   ldy #MY_MOVE_RIGHT >> 4          ; assume monster will move right to center of pen
   bcc .moveMonsterRightInPen
   ldy #MY_MOVE_LEFT >> 4           ; assume monster will move left to center of pen
.moveMonsterRightInPen
   rts

.returnEyesToChamber
   ldy #CHAMBER_TARGET_IDX
   lda #CHAMBER_HOME_HORIZ
   cmp objectHorizPos,x
   bne .setTargetHorizPos
   lda objectVertPos,x              ; get monster's vertical position
   cmp #CHAMBER_HOME_VERT + 1
   bcs .returnMonsterToHome         ; branch if eyes not at vertical target
   cmp #FRUIT_START_Y + 1
   bcc .returnMonsterToHome         ; branch if eyes are below the fruit position
   cmp #PINKY_START_Y - 1
   bcs .moveMonsterDownInPen        ; branch if not time to change eyes to monster
.reinstateMonster
   lda monsterAttributes,x          ; get monster attributes
   and #<~EYE_STATE                 ; clear EYE_STATE
   ora #(1 << 2)                    ; set to release now to avoid eye reversal bug
   sta monsterAttributes,x
.moveMonsterUpInPen
   ldy #MY_MOVE_UP >> 4
   rts

;-----------------------------------------------------------------------------MonsterAI
;
; Enter this routine with x set to the object id
;
; I tried to get this routine as close to the arcade version as I could.
;
; The first check is determined whether the monster is the pen or if the monster's eyes
; are returning to the pen. The next step is to check if the monsters are interested
; in finding Pac-man or the respective home corners.
;
; The targeting system for the objects are the same. They all will first try to reduce
; the greater distance (horizontal or vertical) between themselves and their target.
;
; Even though the targeting systems are the same; each monster has a unique way of
; finding Pac-man if they are interested
;
; Blinky (i.e. Shadow or Red)
; ===========================
; Blinky is the most aggressive of all the monsters. He will target Pac-man's actual
; horizontal and vertical position.
;
; Pinky (i.e. Speedy or Pink)
; ===========================
; Pinky will try to ambush Pac-man by targeting four tiles in front of the direction
; Pac-man is traveling.
;
; Inky (i.e. Bashful or Blue)
; ===========================
; Inky's target is based on Blinky's position to Pac-man. His targeting is also based
; on Pinky's in a way. First he tries to ambush Pac-man by targeting two tiles in
; front of the direction Pac-man is traveling. Then this value is reduced by Blinky's
; position to get Inky's target position.
;
; Clyde (i.e. Pokey or Brown)
; ===========================
; Clyde takes on Blinky's behavior where he targets Pac-man's actual position. Once
; Clyde gets within eight tiles of Pac-man then he targets his home corner.
;
MonsterAI
   sta allowedMotion                ; set monster allowed motion
   txa
   tay                              ; set y to monster id
   lda monsterAttributes,x          ; get monster attributes
   asl                              ; shift EYE_STATE to D7
   bmi .returnEyesToChamber
   and #(RELEASE_TIME << 1)         ; keep monster release time
   bne MoveMonsterInPen             ; branch if monster in pen
   bcs .blueMonsterAI               ; branch if monster blue
.skipMoveMonsterInPen
   lda gameState                    ; get the current game state
   and #NEW_LEVEL
   bne .returnMonsterToHome         ; return monsters home if starting a new level
   bit gameState                    ; check the current game state
   bvc .monsterInterested           ; branch if monsters not returning home
   cpx #ID_BLINKY                   ; check if we are moving Blinky
   bne .returnMonsterToHome         ; return home if not Blinky
   lda gameBoardState               ; get the game board state
   and #CRUISE_ELROY_STATE          ; check to see if in Cruise Elroy state
   beq .returnMonsterToHome         ; return home if not Cruise Elroy
.monsterInterested
   lda pacmanAttributes
   and #PACMAN_DIRECTION_MASK       ; keep Pac-man direction
   tay                              ; place in y for table lookup for Pinky and Inky
   lda pacmanHorizPos               ; get Pac-man horizontal position
   cpx #ID_PINKY                    ; see if the corresponding monster is Pinky
   beq .pinkyInterested
   cpx #ID_INKY
   bne .checkIfBlinkyOrClydeInterested
.inkyInterested
   adc InkyInterestedOffsetValues,y ; increment Pac-man's horizontal position by offset
   asl                              ; multiply value by 2
   bcs .inkyOverflowHoriz           ; branch if an overflow occurred
   sec
   sbc blinkyHorizPos               ; subtract Blinky's horizontal position
   bcs .setInkyHorizontalTarget
   lda #0                           ; force Inky to target left most pixel
   bcc .setInkyHorizontalTarget     ; unconditional branch

.blueMonsterAI
BlueMonsterAI
   lda random                       ; get current random value
   lsr                              ; shift D0 to carry
   bcs .skipEor                     ; branch if random value was odd
   eor #RAND_EOR_8                  ; flip random value bits
.skipEor
   sta random
   tay
.returnMonsterToHome
   lda MonsterStaticTargetHorizPos,y
.setTargetHorizPos
   sta targetHorizPos
   lda MonsterStaticTargetVertPos,y
   jmp .setTargetVertPos

.inkyOverflowHoriz
   sbc blinkyHorizPos               ; subtract Blinky's horizontal position...carry set
   bcc .setInkyHorizontalTarget     ; branch if no overflow has happened
   lda #XMAX + INKY_INTERESTED_OFFSET_VALUE; Inky target right most pixel
.setInkyHorizontalTarget
   sta targetHorizPos
   lda InkyInterestedOffsetValues + 1,y;read Inky vertical offset value
   sec
   adc pacmanVertPos                ; add to Pac-man's vertical position
   asl                              ; multiply value by 2
   bcs .inkyOverflowVert            ; branch if overflow occurred
   sec
   sbc blinkyVertPos                ; subtract Blinky's vertical position
   bcs .setTargetVertPos            ; branch if no overflow has happened
   bcc .setMonsterToTargetLowestVertPoint; unconditional branch

.pinkyInterested
   adc PinkyInterestedOffsetValues,y; carry set here
   cmp #-PINKY_INTERESTED_OFFSET_VALUE
   bcc .setPinkyHorizontalTarget    ; branch if no negative overflow
   lda #0                           ; force Pinky to target left most pixel
.setPinkyHorizontalTarget
   sta targetHorizPos
   sec                              ; set carry...value offset by 1
   lda PinkyInterestedOffsetValues + 1,y
   adc pacmanVertPos
   cmp #-PINKY_INTERESTED_OFFSET_VALUE
   bcc .setTargetVertPos            ; branch if no negative overflow
.setMonsterToTargetLowestVertPoint
   lda #0                           ; force Pinky to target lower most pixel
   beq .setTargetVertPos            ; unconditional branch

.checkIfBlinkyOrClydeInterested
   sta targetHorizPos               ; set horiz target to Pac-man's horiz position
   lda pacmanVertPos                ;
   sta targetVertPos                ; set monster's target to Pac-man's vertical position
   bcc DetermineMonsterNewDirection ; branch if Blinky
.clydeInterested
   sbc clydeVertPos                 ; subract Clyde's vertical position from Pac-man's
   bcs .setVerticalAbsoluteValue
   jsr NegateValue                  ; overflow happenend so get the ABS value
.setVerticalAbsoluteValue
   sta clydePacmanVertDistance
   lda pacmanHorizPos               ; get Pac-man's horizontal position
   sec
   sbc clydeHorizPos                ; subtract Clyde's horizontal position
   bcs .determineClydeStrategy
   jsr NegateValue                  ; overflow happened so get the ABS value
.determineClydeStrategy
   clc
   adc clydePacmanVertDistance      ; add with Pac-man and Clyde's vertical ABS distance
   ror                              ; divide value by 2 to get the average
   cmp #31
   bcs DetermineMonsterNewDirection ; if greater than 8 tiles then do Blinky's strategy
   bcc .returnMonsterToHome         ; move Clyde to home position...unconditional branch

.inkyOverflowVert
   sbc blinkyVertPos                ; subtract Blinky's vertical position...carry set
   bcc .setTargetVertPos            ; branch if no overflow has happened
   lda #H_KERNEL + INKY_INTERESTED_OFFSET_VALUE; Inky target upper most pixel
.setTargetVertPos
   sta targetVertPos
;----------------------------------------------------------DetermineMonsterNewDirection
;
; Now determine which direction the monster should travel now that the desired target
; values and allowed directions have been determined.
;
; The monster's new direction is based on reducing the greatest distance from itself
; and it's respective target. If the vertical and horizontal distances are the same
; then the direction is chosen based on a direction priority. The priority order from
; lowest to highest priority is...RIGHT, DOWN, LEFT, UP
;
; Thanks Thomas for simplifying my original overly complicated first attempt. This
; saves ROM and is much easier to follow.
;
DetermineMonsterNewDirection
.checkToMoveMonsterRight
   lda #0                           ; default maximum distance value
   asl allowedMotion                ; shift MY_MOVE_RIGHT value to carry
   bcc .checkToMoveMonsterDown      ; branch if not allowed to move right
   lda targetHorizPos               ; get target horizontal position
   sbc objectHorizPos,x             ; subtract monster's horizontal position
   ror                              ; shift right to compare with carry bit
.checkToMoveMonsterDown
   sta  maxDistance                 ; set the maximum distance value
   ldy #MY_MOVE_RIGHT >> 4          ; assume monster will move right
   bit allowedMotion                ; check if monster allowed to move down
   bvc .checkToMoveMonsterLeft      ; branch if not allowed to move down
   lda objectVertPos,x              ; get monster's vertical position
   sec
   sbc targetVertPos                ; subtract target vertical position
   ror                              ; shift right to compare with carry bit
   cmp maxDistance                  ; check with distance is greater
   bcc .checkToMoveMonsterLeft      ; branch if vertical distance is less than horizontal
   sta  maxDistance                 ; set current maximum distance value
   ldy #MY_MOVE_DOWN >> 4           ; MY_MOVE_DOWN has better priority at the moment
.checkToMoveMonsterLeft
   asl allowedMotion                ; shift MY_MOVE_LEFT to carry
   bcc .checkToMoveMonsterUp        ; branch if not allowed to move left
   lda objectHorizPos,x             ; get monster's horizontal position
   sbc targetHorizPos               ; subtract target horizontal position
   ror                              ; shift right to compare with carry bit
   cmp maxDistance                  ; check which distance is greater
   bcc .checkToMoveMonsterUp        ; branch if left distance is less
   sta  maxDistance                 ; set current maximum distance value
   ldy #MY_MOVE_LEFT >> 4           ; MY_MOVE_LEFT has better priority at the moment
.checkToMoveMonsterUp
   bit allowedMotion                ; check if monster allowed to move up
   bvc .doneDetermineNewDirection   ; branch if monster not allowed to move up
   lda targetVertPos                ; get target vertical position
   sec
   sbc objectVertPos,x              ; subtract monster's vertical position
   ror                              ; shift right to compare with carry bit
   cmp maxDistance                  ; check which distance is greater
   bcc .doneDetermineNewDirection   ; branch if up distance is less
   lda #MY_MOVE_UP                  ; MY_MOVE_UP has better priority

SetYRegisterToDiv16
   lsr                              ; shift upper nybbles to lower nybbles
SetYRegisterToDiv8
   lsr
   lsr
   lsr
   tay                              ; move value to y for table look up
.doneDetermineNewDirection
   rts

;
; NOTE: Monster animation sprites *MUST* reside on the same page. Their definition can
; start anywhere below $xxA1 (i.e. H_KERNEL - 4) as long as they don't cross a page
; boundary.
;

  IF PLUSROM
SendPlusROMScore:
   lda score
   sta WriteToBuffer
   lda score+1
   sta WriteToBuffer
   lda score+2
   sta WriteToBuffer
   lda #HIGHSCORE_ID          	    ; game id in Highscore DB
   sta WriteSendBuffer              ; send request to backend..
   rts
  ENDIF


   BOUNDRY (H_KERNEL - 4)
   CHECKBOUNDARY (H_KERNEL - 4)

MonsterAnimationSprites
MonstersHoriz_01
   .byte $AA ;|X.X.X.X.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $EA ;|XXX.X.X.|
   .byte $EA ;|XXX.X.X.|
   .byte $EA ;|XXX.X.X.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
MonstersHoriz_02
   .byte $54 ;|.X.X.X..|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $EA ;|XXX.X.X.|
   .byte $EA ;|XXX.X.X.|
   .byte $EA ;|XXX.X.X.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
MonstersDown_01
   .byte $55 ;|.X.X.X.X|
   .byte $7F ;|.XXXXXXX|
   .byte $6B ;|.XX.X.XX|
   .byte $6B ;|.XX.X.XX|
   .byte $6B ;|.XX.X.XX|
   .byte $7F ;|.XXXXXXX|
   .byte $7F ;|.XXXXXXX|
   .byte $7F ;|.XXXXXXX|
   .byte $3E ;|..XXXXX.|
   .byte $3E ;|..XXXXX.|
   .byte $1C ;|...XXX..|
MonstersDown_02
   .byte $2A ;|..X.X.X.|
   .byte $7F ;|.XXXXXXX|
   .byte $6B ;|.XX.X.XX|
   .byte $6B ;|.XX.X.XX|
   .byte $6B ;|.XX.X.XX|
   .byte $7F ;|.XXXXXXX|
   .byte $7F ;|.XXXXXXX|
   .byte $7F ;|.XXXXXXX|
   .byte $3E ;|..XXXXX.|
   .byte $3E ;|..XXXXX.|
   .byte $1C ;|...XXX..|
MonstersUp_01
   .byte $AA ;|X.X.X.X.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
MonstersUp_02
   .byte $54 ;|.X.X.X..|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|

MonsterBlueSprites
MonstersBlue_01
   .byte $AA ;|X.X.X.X.|
   .byte $FE ;|XXXXXXX.|
   .byte $AA ;|X.X.X.X.|
   .byte $D6 ;|XX.X.XX.|
   .byte $FE ;|XXXXXXX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
MonstersBlue_02
   .byte $54 ;|.X.X.X..|
   .byte $FE ;|XXXXXXX.|
   .byte $AA ;|X.X.X.X.|
   .byte $D6 ;|XX.X.XX.|
   .byte $FE ;|XXXXXXX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|

   CHECKPAGE MonsterAnimationSprites

SirenMaskTable
   .byte $10, $10, $08, $08

MonsterStaticTargetVertPos
   .byte BLINKY_HOME_VERT, PINKY_HOME_VERT, INKY_HOME_VERT
   .byte CLYDE_HOME_VERT, CHAMBER_HOME_VERT

;---------------------------------------------------------------ReverseMonsterDirection
;
ReverseMonsterDirection
   dec STACK_POINTER - 1            ; reduce return address LSB
   ldx #NUM_MONSTERS - 1
.reverseMonsterDirections
   lda monsterAttributes,x          ; get the monster attribute values
   and #RELEASE_TIME
   bne .reverseNextMonster          ; don't reverse monster in pen or in CRUISE_ELROY
   lda monsterAttributes,x          ; get the monster attribute values
   eor #2                           ; flip it's direction bits so they reverse
   sta monsterAttributes,x
.reverseNextMonster
   dex
   bpl .reverseMonsterDirections
   rti

;
; The energizer time values were taken from http://nrchapman.com/pacman/
; The values are divided by 2 so they are updated every other frame. Also notice that
; starting with the 7th key the monsters no longer have blue time.
;
EnergizerTimeTable
   .byte (6 * FPS) / 2              ; Cherries     6 sec
   .byte (5 * FPS) / 2              ; Strawberry   5 sec
   .byte (4 * FPS) / 2              ; 1st Peach    4 sec
   .byte (3 * FPS) / 2              ; 2nd Peach    3 sec
   .byte (2 * FPS) / 2              ; 1st Apple    2 sec
;--------------------------------------
   .byte (5 * FPS) / 2              ; 2nd Apple    5 sec
   .byte (2 * FPS) / 2              ; 1st Grape    2 sec
   .byte (2 * FPS) / 2              ; 2nd Grape    2 sec
   .byte (1 * FPS) / 2              ; 1st Flagship 1 sec
;--------------------------------------
   .byte (5 * FPS) / 2              ; 2nd Flagship 5 sec
   .byte (2 * FPS) / 2              ; 1st Mush     2 sec
   .byte (1 * FPS) / 2              ; 2nd Mush     1 sec
   .byte (1 * FPS) / 2              ; 1st Key      1 sec
;--------------------------------------
   .byte (3 * FPS) / 2              ; 2nd Key      3 sec
   .byte (1 * FPS) / 2              ; 3rd Key      1 sec
   .byte (1 * FPS) / 2              ; 4th Key      1 sec
   .byte (0 * FPS) / 2              ; 5th Key      0 sec
   .byte (1 * FPS) / 2              ; 6th Key      1 sec
   .byte (0 * FPS) / 2              ; 7th Key      0 sec

FruitOffsetTable
   .byte <(Cherries - FruitSprites + H_OBJECTS)
   .byte <(Strawberry - FruitSprites + H_OBJECTS)
   .byte <(Peach - FruitSprites + H_OBJECTS)
   .byte <(Peach - FruitSprites + H_OBJECTS)
   .byte <(Apple - FruitSprites + H_OBJECTS)
   .byte <(Apple - FruitSprites + H_OBJECTS)
   .byte <(Grapes - FruitSprites + H_OBJECTS)
   .byte <(Grapes - FruitSprites + H_OBJECTS)
   .byte <(Flagship - FruitSprites + H_OBJECTS)
   .byte <(Flagship - FruitSprites + H_OBJECTS)
   .byte <(Mush - FruitSprites + H_OBJECTS)
   .byte <(Mush - FruitSprites + H_OBJECTS)
   .byte <(Key - FruitSprites + H_OBJECTS)

;--------------------------------------------------------------------------StartNewGame
;
; Set the level number, clear the score, and set the number of lives.
;
StartNewGame
   jsr SetFruitIndexForGameStart
   sty gameLevel                    ; set starting game level
   lda gameState                    ; get the current game state
   and #LEVEL_SELECTION_MASK        ; mask to get the current selected level
   ldx #<(gameBoardState - pacmanLSBValue) + 1
   bne .startNewGame                ; unconditional branch

;------------------------------------------------------------------------------NewLevel
;
; Reset the dot array for a new level and fall through to RestartLevel.
;
NewLevel
   ldy #0                           ; set y to 0 so dot array is re-initialized
   ldx #<(dotsRemaining - pacmanLSBValue) + 1
   lda score + 2                    ; get score value
   and #<~FRUIT_SHOWN_MASK          ; remove the FRUIT_SHOWN values
   sta score + 2
   NOP_W                            ; skip over next two bytes
;--------------------------------------------------------------------------RestartLevel
;
; Reset Pac-man and monster positions to restart the current level.
;
RestartLevel
   ldx #<(levelPauseTimer - pacmanLSBValue) + 1
   lda #NEW_LEVEL_PAUSE
   ora gameState                    ; set game state to show a new level was started
   sta gameState
.startNewGame
   ora #RETURN_HOME | NEW_LEVEL
   sta gameState                    ; set game state to have monsters return home
   iny
.ramInitLoop
   lda LevelInitTable - 1,x
   sta pacmanLSBValue - 1,x
   dex
   bne .ramInitLoop
   stx AUDV1                        ; turn off sounds (i.e. x = 0)
   stx AUDV0
   lda #MSBL_SIZE8 | PF_REFLECT
   sta CTRLPF
   tya                              ; move y to accumulator to determine if the dots
   beq .doneInitDotArray            ; should be re-initialized
   ldx #(NUM_RAM_DOT_BYTES / 2)
.storeDotPatterns
   lda ROMDotPatterns - 1,x
   sta mazeDots - 1,x
   sta mazeDots + 19,x
   dex
   bne .storeDotPatterns
.doneInitDotArray
   lda gameBoardState               ; get current game board state
   and #<~CRUISE_ELROY_STATE        ; remove the CRUISE_ELROY_STATE values so Blinky
   sta gameBoardState               ; does not start in Cruise Elroy mode
   lda #>PacmanSprites
   sta pacmanMSBValue
   lda #>FruitSprites
   sta fruitMSBValue
   lda pacmanAttributes             ; get Pac-man attributes
   and #ENERGIZER_VALUE_MASK        ; keep current energizer values
   ora #DIRECTION_LEFT              ; set initial Pac-man direction
   sta pacmanAttributes
   asl playerState                  ; get the current player state
   lsr playerState                  ; clear DEATH_SEQUENCE flag
   lda gameLevel                    ; get current game level
   beq .doneDetermineMotionIndex
   inx                              ; increment for next motion delay value
   cmp #4
   bcc .doneDetermineMotionIndex
   inx                              ; increment for next motion delay value
   cmp #20
   bcc .doneDetermineMotionIndex
   inx                              ; increment for next motion delay value
.doneDetermineMotionIndex
   stx motionDelayIndex
   lda InkyStartAttributes,x
   sta inkyAttributes
   lda ClydeStartAttributes,x
   sta clydeAttributes
   rts

FruitColorsTable
   .byte CHERRIES_COLOR, PEACH_COLOR, APPLE_COLOR
   .byte GRAPES_COLOR, FLAGSHIP_COLOR, MUSH_COLOR, KEY_COLOR

PacmanDelayTable
;
; normal Pac-man speeds
;
   .byte SPEED_PACMAN_NORMAL_1, SPEED_PACMAN_NORMAL_2
   .byte SPEED_PACMAN_NORMAL_3, SPEED_PACMAN_NORMAL_4
;
; blue time Pac-man speeds
;
   .byte SPEED_PACMAN_BLUE_1, SPEED_PACMAN_BLUE_2
   .byte SPEED_PACMAN_BLUE_3, SPEED_PACMAN_BLUE_4

LivesIndicatorColor
   .byte BLACK, PACMAN_COLOR, PACMAN_COLOR, PACMAN_COLOR

LevelInitTable
   .byte <(PacmanStationary - H_KERNEL - 1) ; pacmanLSBValue
   .byte <(PacmanStationary - H_KERNEL - 1) ; pacmanGraphicLSB
MonsterColorTable
   .byte BLINKY_COLOR               ; blinkyColor
   .byte PINKY_COLOR                ; pinkyColor
   .byte INKY_COLOR                 ; inkyColor
   .byte CLYDE_COLOR                ; clydeColor
   .byte 0                          ; fruitColor
   .byte PACMAN_COLOR               ; pacmanColor
   .byte -1                         ; eatenMonsterNumber
   .byte 0                          ; energizerValues
   .byte ATTACK_TIMER_VALUE         ; attackTimer
   .byte 0                          ; frameCount
   .byte 0                          ; fruitTimer
   .byte BLINKY_START_X             ; blinkyHorizPos
   .byte PINKY_START_X              ; pinkyHorizPos
   .byte INKY_START_X               ; inkyHorizPos
   .byte CLYDE_START_X              ; clydeHorizPos
   .byte FRUIT_START_X              ; fruitHorizPos
   .byte PACMAN_START_X             ; pacmanHorizPos
   .byte BLINKY_START_Y             ; blinkyVertPos
   .byte PINKY_START_Y              ; pinkyVertPos
   .byte INKY_START_Y               ; inkyVertPos
   .byte CLYDE_START_Y              ; clydeVertPos
   .byte H_KERNEL + H_OBJECTS       ; fruitVertPos
   .byte PACMAN_START_Y             ; pacmanVertPos
   .byte DIRECTION_LEFT             ; blinkyAttributes
   .byte (((1 * 12) / 7) << 2) | DIRECTION_UP; pinkyAttributes
   .byte 0, 0
   .byte #$3F                       ; levelPauseTimer
   .byte ENERGIZER_VALUE_MASK | DIRECTION_LEFT; pacmanAttributes
   .byte 0                          ; pacmanAteFruit
   .byte MAX_NUM_DOTS               ; dotsRemaining
   .byte STARTING_NUM_LIVES         ; playerState
   .byte 0, 0, 0                    ; score
   .byte 0                          ; gameBoardState

ClydeStartAttributes
   .byte (((8 * 12) / 7) << 2) | DIRECTION_DOWN
InkyStartAttributes
   .byte (((4 * 12) / 7) << 2) | DIRECTION_DOWN
   .byte (((1 * 12) / 7) << 2) | DIRECTION_DOWN
   .byte (((1 * 12) / 7) << 2) | DIRECTION_DOWN
   .byte (((1 * 12) / 7) << 2) | DIRECTION_DOWN

MonsterPointsLSB
   .byte <_200Points - H_KERNEL, <_400Points - H_KERNEL
   .byte <_800Points - H_KERNEL, <_1600Points - H_KERNEL

;----------------------------------------------------------------DetermineAllowedMotion
;
; Enter this routine with x set to the object id you are trying to move. When this
; routine exits, allowedMotion will hold the allowed directions for the maze section
; of the object.
;
; My first attempt was to use a table to look for the object section. This took less
; ROM but could potentially run for 108 cycles.
;
DetermineAllowedMotion
   ldy objectVertPos,x              ; get the object's vertical position
   lda #(DOT_SECTIONS / 2) - 1      ; set to maximum section
   cpy #H_KERNEL - 2
   beq .sectionFound                ; branch if object in top section
   cpy #140 + 1
   bcs .sectionNotFound             ; branch if object not in a section
   tya                              ; move object vertical position to accumulator
   and #$0F                         ; keep lower nybbles
   cmp #12
   beq .setFoundSection             ; branch if object in a section
.sectionNotFound
   lda #VERT_MOTION
   bne .setMotion                   ; set to only allow vertical motion

.setFoundSection
   tya                              ; move object vertical position to accumulator
   lsr                              ; move section number to lower nybbles
   lsr
   lsr
   lsr
.sectionFound
   sta tempSection
   asl                              ; * 2
   asl                              ; * 4
   adc tempSection                  ; * 5 (x * 5 = (x * 4) + x)...carry clear
   sta multi5
.checkVertMovement
   lda objectHorizPos,x             ; get the object's horizontal position
   ldy #9
.nextVert
   cmp VerticalMazeValues,y         ; compare with valid maze vertical values
   beq .vertSectionFound
   dey
   bpl .nextVert
   lda #HORIZ_MOTION                ; object allowed to move horiz
   bne .setMotion                   ; unconditional branch

.vertSectionFound
   tya                              ; move vertical section to accumulator
   lsr                              ; divide by 2
   php                              ; save processor flags
   clc                              ; divide by 2 could set carry :-(
   adc multi5                       ; add in dot section for table offset
   tay
   plp                              ; pull processor flags from stack
   lda MazeRules,y
   bcc .evenMazeRule                ; branch to keep upper nybbles
   asl                              ; shift even maze rule value to upper
   asl                              ; nybble
   asl
   asl
.evenMazeRule
   cpx #ID_PACMAN
   beq .setMotion                   ; set motion if the object is Pac-man
   bit tempMonsterAttribute         ; check monster attributes
   bmi .setNoneRestrictedMotion     ; set motion if monster is in BLUE_STATE
   bvs .setNoneRestrictedMotion     ; set motion if monster is in EYE_STATE
   cpy #12                          ; check if index is for T-tunnels (i.e.
   beq .dontAllowMonsterToTravelUp  ; monster not allowed to move up in T-
   cpy #32                          ; tunnels)
   bne .setNoneRestrictedMotion
.dontAllowMonsterToTravelUp
   and #<~MY_MOVE_UP & P0_JOYSTICK_MASK; mask the MOVE_UP bit
.setNoneRestrictedMotion
.setMotion
   sta allowedMotion
   rts

;
; NOTE: Fruit sprites *MUST* reside on the same page. Their definition can start
; anywhere below $xx41 (i.e. FRUIT_START_Y - 10) as long as they don't cross a page
; boundary.
;
   BOUNDRY (FRUIT_START_Y - H_OBJECTS + 1)
   CHECKBOUNDARY (FRUIT_START_Y - H_OBJECTS + 1)

   IF PUBLISHER = ATARIAGE

FruitSprites
Strawberry
   .byte $38 ;|..XXX...|
   .byte $6C ;|.XX.XX..|
   .byte $5C ;|.X.XXX..|
   .byte $74 ;|.XXX.X..|
   .byte $FE ;|XXXXXXX.|
   .byte $B6 ;|X.XX.XX.|
   .byte $EA ;|XXX.X.X.|
   .byte $BE ;|X.XXXXX.|
   .byte $FA ;|XXXXX.X.|
   .byte $54 ;|.X.X.X..|
;
; last byte shared with table below...don't cross page boundary
;
Key
   .byte $10 ;|...X....|
   .byte $28 ;|..X.X...|
   .byte $2C ;|..X.XX..|
   .byte $28 ;|..X.X...|
   .byte $28 ;|..X.X...|
   .byte $2C ;|..X.XX..|
   .byte $28 ;|..X.X...|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $C6 ;|XX...XX.|
;
; last byte shared with table below...don't cross page boundary
;
Peach
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
   .byte $16 ;|...X.XX.|
;
; last byte shared with table below...don't cross page boundary
;
Cherries
   .byte $0C ;|....XX..|
   .byte $1E ;|...XXXX.|
   .byte $5A ;|.X.XX.X.|
   .byte $D6 ;|XX.X.XX.|
   .byte $DE ;|XX.XXXX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $A8 ;|X.X.X...|
   .byte $44 ;|.X...X..|
   .byte $34 ;|..XX.X..|
   .byte $0F ;|....XXXX|
   .byte $03 ;|......XX|
Apple
   .byte $6C ;|.XX.XX..|
   .byte $7C ;|.XXXXX..|
   .byte $F6 ;|XXXX.XX.|
   .byte $FA ;|XXXXX.X.|
   .byte $FA ;|XXXXX.X.|
   .byte $FA ;|XXXXX.X.|
   .byte $FC ;|XXXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $28 ;|..X.X...|
   .byte $16 ;|...X.XX.|
   .byte $0C ;|....XX..|
Mush
   .byte $7E ;|.XXXXXX.|
   .byte $81 ;|X......X|
   .byte $FF ;|XXXXXXXX|
   .byte $DF ;|XX.XXXXX|
   .byte $5E ;|.X.XXXX.|
   .byte $5E ;|.X.XXXX.|
   .byte $6E ;|.XX.XXX.|
   .byte $3C ;|..XXXX..|
   .byte $3C ;|..XXXX..|
   .byte $24 ;|..X..X..|
   .byte $18 ;|...XX...|
Flagship
   .byte $00 ;|........|
   .byte $3C ;|..XXXX..|
   .byte $42 ;|.X....X.|
   .byte $C3 ;|XX....XX|
   .byte $A5 ;|X.X..X.X|
   .byte $DB ;|XX.XX.XX|
   .byte $A5 ;|X.X..X.X|
   .byte $99 ;|X..XX..X|
   .byte $42 ;|.X....X.|
   .byte $3C ;|..XXXX..|
   .byte $00 ;|........|
Grapes
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $6C ;|.XX.XX..|
   .byte $DE ;|XX.XXXX.|
   .byte $B6 ;|X.XX.XX.|
   .byte $BE ;|X.XXXXX.|
   .byte $5C ;|.X.XXX..|
   .byte $6C ;|.XX.XX..|
   .byte $38 ;|..XXX...|
   .byte $10 ;|...X....|
   .byte $7C ;|.XXXXX..|

   CHECKBOUNDARY (H_KERNEL - 4)
;
; NOTE: These sprites *MUST* reside on the same page. Their definition can start
; anywhere below $xxA1 (i.e. H_KERNEL - 4) as long as they don't cross a page boundary.
;
PacmanDeathSprites4
   .byte $28 ;|..X.X...|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $38 ;|..XXX...|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
;
; last byte shared with table below...don't cross page boundary
;

SirenModulatorTable
   .byte 0, 2, 4, 6

   ELSE

FruitSprites
Strawberry
   .byte $38 ;|..XXX...|
   .byte $6C ;|.XX.XX..|
   .byte $5C ;|.X.XXX..|
   .byte $74 ;|.XXX.X..|
   .byte $FE ;|XXXXXXX.|
   .byte $B6 ;|X.XX.XX.|
   .byte $EA ;|XXX.X.X.|
   .byte $BE ;|X.XXXXX.|
   .byte $FA ;|XXXXX.X.|
   .byte $54 ;|.X.X.X..|
;
; last byte shared with table below...don't cross page boundary
;
Flagship
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $10 ;|...X....|
   .byte $54 ;|.X.X.X..|
   .byte $92 ;|X..X..X.|
   .byte $BA ;|X.XXX.X.|
   .byte $BA ;|X.XXX.X.|
   .byte $BA ;|X.XXX.X.|
;
; last byte shared with table below...don't cross page boundary
;
Key
   .byte $10 ;|...X....|
   .byte $28 ;|..X.X...|
   .byte $2C ;|..X.XX..|
   .byte $28 ;|..X.X...|
   .byte $28 ;|..X.X...|
   .byte $2C ;|..X.XX..|
   .byte $28 ;|..X.X...|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $C6 ;|XX...XX.|
;
; last byte shared with table below...don't cross page boundary
;
Peach
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
   .byte $16 ;|...X.XX.|
;
; last byte shared with table below...don't cross page boundary
;
Cherries
   .byte $0C ;|....XX..|
   .byte $1E ;|...XXXX.|
   .byte $5A ;|.X.XX.X.|
   .byte $D6 ;|XX.X.XX.|
   .byte $DE ;|XX.XXXX.|
   .byte $D6 ;|XX.X.XX.|
   .byte $A8 ;|X.X.X...|
   .byte $44 ;|.X...X..|
   .byte $34 ;|..XX.X..|
   .byte $0F ;|....XXXX|
   .byte $03 ;|......XX|
Apple
   .byte $6C ;|.XX.XX..|
   .byte $7C ;|.XXXXX..|
   .byte $F6 ;|XXXX.XX.|
   .byte $FA ;|XXXXX.X.|
   .byte $FA ;|XXXXX.X.|
   .byte $FA ;|XXXXX.X.|
   .byte $FC ;|XXXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $28 ;|..X.X...|
   .byte $16 ;|...X.XX.|
   .byte $0C ;|....XX..|
Mush
   .byte $7E ;|.XXXXXX.|
   .byte $81 ;|X......X|
   .byte $FF ;|XXXXXXXX|
   .byte $DF ;|XX.XXXXX|
   .byte $5E ;|.X.XXXX.|
   .byte $5E ;|.X.XXXX.|
   .byte $6E ;|.XX.XXX.|
   .byte $3C ;|..XXXX..|
   .byte $3C ;|..XXXX..|
   .byte $24 ;|..X..X..|
   .byte $18 ;|...XX...|
Grapes
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $6C ;|.XX.XX..|
   .byte $DE ;|XX.XXXX.|
   .byte $B6 ;|X.XX.XX.|
   .byte $BE ;|X.XXXXX.|
   .byte $5C ;|.X.XXX..|
   .byte $6C ;|.XX.XX..|
   .byte $38 ;|..XXX...|
   .byte $10 ;|...X....|
   .byte $7C ;|.XXXXX..|

   CHECKBOUNDARY (H_KERNEL - 4)
;
; NOTE: These sprites *MUST* reside on the same page. Their definition can start
; anywhere below $xxA1 (i.e. H_KERNEL - 4) as long as they don't cross a page boundary.
;
PacmanDeathSprites4
   .byte $28 ;|..X.X...|
   .byte $7C ;|.XXXXX..|
   .byte $FE ;|XXXXXXX.|
   .byte $38 ;|..XXX...|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
;
; last byte shared with table below...don't cross page boundary
;

SirenModulatorTable
   .byte 0, 2, 4, 6

   ENDIF

PacmanDeathSprites8
   .byte $10 ;|...X....|
   .byte $38 ;|..XXX...|
   .byte $38 ;|..XXX...|
   .byte $38 ;|..XXX...|
   .byte $10 ;|...X....|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
PacmanDeathSprites2
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $C6 ;|XX...XX.|
   .byte $82 ;|X.....X.|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
PacmanDeathSprites3
   .byte $38 ;|..XXX...|
   .byte $7C ;|.XXXXX..|
   .byte $7C ;|.XXXXX..|
   .byte $C6 ;|XX...XX.|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
PacmanDeathSprites5
   .byte $38 ;|..XXX...|
   .byte $FE ;|XXXXXXX.|
   .byte $7C ;|.XXXXX..|
   .byte $38 ;|..XXX...|
   .byte $10 ;|...X....|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
   .byte $00 ;|........|
;
; last byte shared with table below...don't cross page boundary
;
PacmanDeathSprites10
   .byte $00 ;|........|
   .byte $44 ;|.X...X..|
   .byte $28 ;|..X.X...|
   .byte $44 ;|.X...X..|
   .byte $00 ;|........|
   .byte $C6 ;|XX...XX.|
   .byte $00 ;|........|
   .byte $44 ;|.X...X..|
   .byte $28 ;|..X.X...|
   .byte $44 ;|.X...X..|
   .byte $00 ;|........|

   CHECKPAGE FruitSprites

PacmanAnimationTable
   .byte <PacmanHoriz0 - H_KERNEL - 1
   .byte <PacmanHoriz1 - H_KERNEL - 1
   .byte <PacmanHoriz0 - H_KERNEL - 1
   .byte <PacmanStationary - H_KERNEL - 1
;
; Pac-man up animation data
;
   .byte <PacmanStationary - H_KERNEL - 1
   .byte <PacmanUp0 - H_KERNEL - 1
   .byte <PacmanUp1 - H_KERNEL - 1
   .byte <PacmanUp0 - H_KERNEL - 1
;
; Pac-man down animation data
;
   .byte <PacmanStationary - H_KERNEL - 1
   .byte <PacmanDown0 - H_KERNEL - 1
   .byte <PacmanDown1 - H_KERNEL - 1
   .byte <PacmanDown0 - H_KERNEL - 1

MonsterDelayTable
   .byte SPEED_MONSTER_BLUE_1, SPEED_MONSTER_SLOW_1, SPEED_MONSTER_NORMAL_1
   .byte SPEED_CRUISE_ELROY2_1, SPEED_CRUISE_ELROY1_1

   .byte SPEED_MONSTER_BLUE_2, SPEED_MONSTER_SLOW_2, SPEED_MONSTER_NORMAL_2
   .byte SPEED_CRUISE_ELROY2_2, SPEED_CRUISE_ELROY1_2

   .byte SPEED_MONSTER_BLUE_3, SPEED_MONSTER_SLOW_3, SPEED_MONSTER_NORMAL_3
   .byte SPEED_CRUISE_ELROY2_3, SPEED_CRUISE_ELROY1_3

   .byte SPEED_MONSTER_BLUE_4, SPEED_MONSTER_SLOW_4, SPEED_MONSTER_NORMAL_4
   .byte SPEED_CRUISE_ELROY2_4, SPEED_CRUISE_ELROY1_4

;------------------------------------------------------------------------IncrementScore
;
; Enter this routine with accumulator set to point value.
;
IncrementTensPosition
   ldy #0
IncrementScore
   bit gameBoardState               ; check current game board status
   bvs .doneIncrementScore          ; don't increment score if in DEMO_MODE
   sed                              ; set to decimal mode
   clc                              ; clear carry for addition
   ldx #3
.incrementScore
   adc score - 1,x                  ; increment hundreds position
   sta score - 1,x
   tya                              ; move thousands value to accumulator
   ldy #0                           ; set thousands value to 0
   dex
   bne .incrementScore
   cld                              ; clear decimal mode
   lda score                        ; get score for the thousands position
   lsr                              ; shift D0 to carry
   bcc .doneIncrementScore          ; no extra life if not reached 10,000 points
   ror score + 2                    ; shift EXTRA_LIFE_REWARDED flag to carry
   bcs .doneCheckForExtraLife       ; branch if extra life already rewarded
   lda #15
   sta extraPlayerSoundIndex        ; set 1up sound index for bonus "ding" sound
   inc playerState                  ; increment number of lives
   sec                              ; set carry to set EXTRA_LIFE_REWARDED flag
.doneCheckForExtraLife
   rol score + 2                    ; restore score value with EXTRA_LIFE_REWARDED flag
.doneIncrementScore
   rts

FruitColorsTableLSB
   .byte <CherriesColor, <StrawberryColor, <PeachColor, <PeachColor
   .byte <AppleColor, <AppleColor, <GrapesColor, <GrapesColor
   .byte <FlagshipColor, <FlagshipColor, <MushColor, <MushColor
   .byte <KeyColor

DotMaskingBits
   .byte $80, $40, $10, $04, $01, $02, $08, $20

PacmanDeathAnimationLSB
   .byte <PacmanDeathSprites11 - H_KERNEL - 1
   .byte <PacmanDeathSprites10 - H_KERNEL - 1
   .byte <PacmanDeathSprites9 - H_KERNEL - 1
   .byte <PacmanDeathSprites8 - H_KERNEL - 1
   .byte <PacmanDeathSprites7 - H_KERNEL - 1
   .byte <PacmanDeathSprites6 - H_KERNEL - 1
   .byte <PacmanDeathSprites5 - H_KERNEL - 1
   .byte <PacmanDeathSprites4 - H_KERNEL - 1
   .byte <PacmanDeathSprites3 - H_KERNEL - 1
   .byte <PacmanDeathSprites2 - H_KERNEL - 1
   .byte <PacmanDeathSprites1 - H_KERNEL - 1
   .byte <PacmanDeathSprites0 - H_KERNEL - 1

PacmanDeathAnimationMSB
   .byte >PacmanDeathSprites11
   .byte >PacmanDeathSprites10
   .byte >PacmanDeathSprites9
   .byte >PacmanDeathSprites8
   .byte >PacmanDeathSprites7
   .byte >PacmanDeathSprites6
   .byte >PacmanDeathSprites5
   .byte >PacmanDeathSprites4
   .byte >PacmanDeathSprites3
   .byte >PacmanDeathSprites2
   .byte >PacmanDeathSprites1
   .byte >PacmanDeathSprites0
;
; Maze rules are compressed where two rules use one byte. The upper nybble represents
; the even number intersection and the lower nybble represents the odd number
; intersection.
;
MazeRules
   .byte MY_MOVE_UP|MY_MOVE_RIGHT | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ >> 4)
   .byte MY_MOVE_UP|ALLOW_MOVE_HORIZ | (MY_MOVE_UP|ALLOW_MOVE_HORIZ) >> 4
   .byte ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_HORIZ | (MY_MOVE_UP|MY_MOVE_LEFT) >> 4

   .byte MY_MOVE_RIGHT|MY_MOVE_DOWN | (MY_MOVE_UP|ALLOW_MOVE_HORIZ) >> 4
   .byte MY_MOVE_UP|MY_MOVE_LEFT | (MY_MOVE_UP|MY_MOVE_RIGHT) >> 4
   .byte MY_MOVE_LEFT|MY_MOVE_DOWN | (MY_MOVE_RIGHT|MY_MOVE_DOWN) >> 4
   .byte MY_MOVE_UP|MY_MOVE_LEFT | (MY_MOVE_UP|MY_MOVE_RIGHT) >> 4
   .byte MY_MOVE_UP|ALLOW_MOVE_HORIZ | (MY_MOVE_LEFT|MY_MOVE_DOWN) >> 4

   .byte MY_MOVE_UP|MY_MOVE_RIGHT | (MY_MOVE_LEFT|MY_MOVE_DOWN) >> 4
   .byte ALLOW_MOVE_VERT|MY_MOVE_RIGHT | (ALLOW_MOVE_HORIZ|MY_MOVE_DOWN) >> 4
   .byte MY_MOVE_UP|ALLOW_MOVE_HORIZ | (MY_MOVE_UP|ALLOW_MOVE_HORIZ) >> 4
   .byte ALLOW_MOVE_HORIZ|MY_MOVE_DOWN | (ALLOW_MOVE_VERT|MY_MOVE_LEFT) >> 4
   .byte MY_MOVE_RIGHT|MY_MOVE_DOWN | (MY_MOVE_UP|MY_MOVE_LEFT) >> 4

   .byte MY_MOVE_RIGHT|MY_MOVE_DOWN | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_HORIZ|ALLOW_MOVE_VERT | (MY_MOVE_UP|ALLOW_MOVE_HORIZ) >> 4
   .byte MY_MOVE_LEFT|MY_MOVE_DOWN | (MY_MOVE_RIGHT|MY_MOVE_DOWN) >> 4
   .byte MY_MOVE_UP|ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ|ALLOW_MOVE_VERT) >> 4
   .byte ALLOW_MOVE_HORIZ | (MY_MOVE_LEFT|MY_MOVE_DOWN) >> 4

   .byte NO_MOVE | NO_MOVE
   .byte ALLOW_MOVE_VERT | (ALLOW_MOVE_VERT|MY_MOVE_RIGHT) >> 4
   .byte ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_VERT|MY_MOVE_LEFT | (ALLOW_MOVE_VERT >> 4)
   .byte NO_MOVE | NO_MOVE

   .byte ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_VERT|ALLOW_MOVE_HORIZ | (MY_MOVE_LEFT|ALLOW_MOVE_VERT) >> 4
   .byte NO_MOVE | NO_MOVE
   .byte MY_MOVE_RIGHT|ALLOW_MOVE_VERT | (ALLOW_MOVE_VERT|ALLOW_MOVE_HORIZ) >> 4
   .byte ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ >> 4)

   .byte NO_MOVE | NO_MOVE
   .byte ALLOW_MOVE_VERT | (MY_MOVE_RIGHT|MY_MOVE_DOWN) >> 4
   .byte MY_MOVE_UP | ALLOW_MOVE_HORIZ | (MY_MOVE_UP|ALLOW_MOVE_HORIZ) >> 4
   .byte MY_MOVE_LEFT|MY_MOVE_DOWN | (ALLOW_MOVE_VERT >> 4)
   .byte NO_MOVE | NO_MOVE

   .byte MY_MOVE_UP|MY_MOVE_RIGHT | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_VERT|MY_MOVE_LEFT | (MY_MOVE_UP|MY_MOVE_RIGHT) >> 4
   .byte MY_MOVE_LEFT|MY_MOVE_DOWN | (MY_MOVE_RIGHT|MY_MOVE_DOWN) >> 4
   .byte MY_MOVE_UP|MY_MOVE_LEFT | (ALLOW_MOVE_VERT|MY_MOVE_RIGHT) >> 4
   .byte ALLOW_MOVE_HORIZ | (MY_MOVE_UP|MY_MOVE_LEFT) >> 4

   .byte ALLOW_MOVE_VERT|MY_MOVE_RIGHT | (ALLOW_MOVE_HORIZ >> 4)
   .byte ALLOW_MOVE_VERT|ALLOW_MOVE_HORIZ | (MY_MOVE_DOWN|ALLOW_MOVE_HORIZ) >> 4
   .byte MY_MOVE_UP|ALLOW_MOVE_HORIZ | (MY_MOVE_UP|ALLOW_MOVE_HORIZ) >> 4
   .byte MY_MOVE_DOWN|ALLOW_MOVE_HORIZ | (ALLOW_MOVE_VERT|ALLOW_MOVE_HORIZ) >> 4
   .byte ALLOW_MOVE_HORIZ | (ALLOW_MOVE_VERT|MY_MOVE_LEFT) >> 4

   .byte MY_MOVE_DOWN|MY_MOVE_RIGHT | (ALLOW_MOVE_HORIZ >> 4)
   .byte MY_MOVE_DOWN|ALLOW_MOVE_HORIZ | (ALLOW_MOVE_HORIZ >> 4)
   .byte MY_MOVE_DOWN|MY_MOVE_LEFT | (MY_MOVE_DOWN|MY_MOVE_RIGHT) >> 4
   .byte ALLOW_MOVE_HORIZ | (MY_MOVE_DOWN|ALLOW_MOVE_HORIZ) >> 4
   .byte ALLOW_MOVE_HORIZ | (MY_MOVE_DOWN|MY_MOVE_LEFT) >> 4

FruitHighScoreTable
   .byte CHERRIES_SCORE >> 8, STRAWBERRY_SCORE >> 8, PEACH_SCORE >> 8
   .byte PEACH_SCORE >> 8, APPLE_SCORE >> 8, APPLE_SCORE >> 8, GRAPE_SCORE >> 8
   .byte GRAPE_SCORE >> 8, FLAGSHIP_SCORE >> 8, FLAGSHIP_SCORE >> 8
   .byte MUSH_SCORE >> 8, MUSH_SCORE >> 8, KEY_SCORE >> 8;12

   IF PUBLISHER = ATARIAGE

BonusFruitColors
AppleColor
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte BROWN
   .byte GRAPES_COLOR
   .byte BROWN

CherriesColor
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte BROWN
   .byte BROWN
   .byte BROWN
   .byte BROWN

PeachColor
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte GRAPES_COLOR
   .byte ORANGE

StrawberryColor
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
;
; last 2 bytes shared with next table so don't cross page boundaries
;
GrapesColor
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR

KeyColor
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
;
; last 4 bytes shared with next table so don't cross page boundaries
;
FlagshipColor
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
   .byte LTBLUE
;
; last 2 bytes shared with next table so don't cross page boundaries
;
MushColor
   .byte LTBLUE
   .byte LTBLUE
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW

   ELSE

BonusFruitColors
AppleColor
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte BROWN
   .byte GRAPES_COLOR
   .byte BROWN

CherriesColor
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte CHERRIES_COLOR
   .byte BROWN
   .byte BROWN
   .byte BROWN
   .byte BROWN

PeachColor
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte PEACH_COLOR
   .byte GRAPES_COLOR
   .byte ORANGE

StrawberryColor
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
   .byte STRAWBERRY_COLOR
;
; last 2 bytes shared with next table so don't cross page boundaries
;
GrapesColor
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR
   .byte GRAPES_COLOR

KeyColor
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte WHITE
   .byte LTBLUE
   .byte LTBLUE
;
; last 2 bytes shared with next table so don't cross page boundaries
;
MushColor
   .byte LTBLUE
   .byte LTBLUE
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
;
; last 5 bytes shared with next table so don't cross page boundaries
;
FlagshipColor
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte YELLOW
   .byte BLUE
   .byte BLUE
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte APPLE_COLOR
   .byte YELLOW

   ENDIF
   IF PLUSROM
PlusROM_API
   .byte 0, "h.stubig.de", 0
   .org ROMTOP + 4096 - 6, 0      ; 4K ROM

   .word (PlusROM_API-$E000)
   ELSE
   BOUNDRY 252                      ; push to RESET vector (this was done instead of
                                    ; using an .ORG to easily keep track of free ROM)
   ENDIF
   echo "***", (FREE_BYTES)d, "BYTES OF ROM FREE"

   .word Start                      ; RESET vector
   .word ReverseMonsterDirection    ; BRK vector