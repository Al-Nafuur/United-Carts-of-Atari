#ifndef VCSLIB_H
#define VCSLIB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MP_SYSTEM_TYPE    0
#define MP_CLOCK_HZ       1
#define MP_FEATURE_FLAGS  2
#define MP_ELAPSED        3 // Do not use, debug only, will be replaced in future
#define MP_THRESHOLD      4 // Do not use, debug only, will be replaced in future
#define MP_COUNT          5

// MP_SYSTEM_TYPE values
#define ST_NTSC_2600      0
#define ST_PAL_2600       1 
#define ST_PAL60_2600     2 // Note: PAL60 is used by the UCA carts to convey the user preference
#define ST_NTSC_7800      3
#define ST_PAL_7800       4

// feature flags
#define FF_MULTI_CART     1 // Indicates elf is loaded by multicart and should allow exiting (return from elf_main() function)
#define FF_CHAMELEON_CART 2 // Indicates running on Chameleon Cart and console is already initialized
#define FF_REDUCED_HMOVE  4 // Indicates that cycle 73/74 hmoves will be reduced by 1 pixel (late model JRs often do this) 

// Defines for VCS/2600 memory mapped registers
#define VSYNC             0x00
#define VBLANK            0x01
#define WSYNC             0x02
#define RSYNC             0x03
#define NUSIZ0            0x04
#define NUSIZ1            0x05
#define COLUP0            0x06
#define COLUP1            0x07
#define COLUPF            0x08
#define COLUBK            0x09
#define CTRLPF            0x0A
#define REFP0             0x0B
#define REFP1             0x0C
#define PF0               0x0D
#define PF1               0x0E
#define PF2               0x0F
#define RESP0             0x10
#define RESP1             0x11
#define RESM0             0x12
#define RESM1             0x13
#define RESBL             0x14
#define AUDC0             0x15
#define AUDC1             0x16
#define AUDF0             0x17
#define AUDF1             0x18
#define AUDV0             0x19
#define AUDV1             0x1A
#define GRP0              0x1B
#define GRP1              0x1C
#define ENAM0             0x1D
#define ENAM1             0x1E
#define ENABL             0x1F
#define HMP0              0x20
#define HMP1              0x21
#define HMM0              0x22
#define HMM1              0x23
#define HMBL              0x24
#define VDELP0            0x25
#define VDELP1            0x26
#define VDELBL            0x27
#define RESMP0            0x28
#define RESMP1            0x29
#define HMOVE             0x2A
#define HMCLR             0x2B
#define CXCLR             0x2C

#define CXM0P             0x00
#define CXM1P             0x01
#define CXP0FB            0x02
#define CXP1FB            0x03
#define CXM0FB            0x04
#define CXM1FB            0x05
#define CXBLPF            0x06
#define CXPPMM            0x07
#define INPT0             0x08
#define INPT1             0x09
#define INPT2             0x0A
#define INPT3             0x0B
#define INPT4             0x0C
#define INPT5             0x0D

#define SWCHA             0x0280
#define SWACNT            0x0281
#define SWCHB             0x0282
#define SWBCNT            0x0283
#define INTIM             0x0284
#define TIMINT            0x0285
#define TIM1T             0x0294
#define TIM8T             0x0295
#define TIM64T            0x0296
#define T1024T            0x0297

// For firmware use only
extern const uint8_t Ntsc2600[256];
extern const uint8_t Pal2600[256];
extern const uint8_t Ntsc7800[256];
extern const uint8_t Pal7800[256];
void vcsLibInit();
void vcsInitBusStuffing();

// For firmware or game use
extern const uint8_t ColorLookup[256];
extern const uint8_t ReverseByte[256]; // Reverses the order of the bits. 7..0 becomes 0..7. Useful for PF0, PF2, and reflecting sprites in software.

// Used to define functions that will be copied to and run from RAM
#define RAM_FUNC __attribute__((noinline, long_call, section(".RamFunc")))

// Bus Stuffing - must load A, X, and Y prior to using vcsWrite3() or vcsWrite4()
void vcsLdaForBusStuff2();
void vcsLdxForBusStuff2();
void vcsLdyForBusStuff2();
void vcsWrite3(uint8_t ZP, uint8_t data);
void vcsWrite4(uint16_t address, uint8_t data);

void vcsJmp3(); // jmp $f000 - used to keep PC in range of ROM. Call this when there are spare cycles to kill

// nop can be used to adjust timing of display kernel code, or to give ARM more time between servicing 6502 bus
void vcsNop2();
void vcsNop2n(uint16_t n);

void vcsWrite5(uint8_t zeroPage, uint8_t data); // lda #, sta zp
void vcsWrite6(uint16_t address, uint8_t data); // lda #, sta abs

void vcsLda2(uint8_t data);
void vcsLdx2(uint8_t data);
void vcsLdy2(uint8_t data);

void vcsSax3(uint8_t zeroPage); // uses undocumented sax opcode to store (A & X) to zero page
void vcsSta3(uint8_t zeroPage);
void vcsStx3(uint8_t zeroPage);
void vcsSty3(uint8_t zeroPage);

void vcsSta4(uint16_t address);
void vcsStx4(uint16_t address);
void vcsSty4(uint16_t address);

void vcsCopyOverblankToRiotRam();
void vcsStartOverblank();
void vcsEndOverblank();

uint8_t vcsRead6(uint16_t address);
int randint();

// Stack operations for advanced kernels without the use of bus stuffing
void vcsTxs2();
void vcsJsr6(uint16_t target);
void vcsPha3();
void vcsPhp3();
void vcsPla4();
void vcsPlp4();
// Can be used when SP is aimed at TIA registers to simultaneously load a register with a 6 bit value, and undo SP change of PHP PHA
void vcsPla4Ex(uint8_t data);
void vcsPlp4Ex(uint8_t data);

// primarily used in 7800 games
void vcsJmpToRam3(uint16_t addr); // Transfer 6502 execution to 6502 RAM
void vcsWaitForAddress(uint16_t address); // spin lock arm until 6502 accesses the specified address
void injectDmaData(int address, int count, const uint8_t* pBuffer);

// helper macro to generate a sleep of a specific number of cycles (must be > 1)
#define vcsSleep(cycles) \
    _Static_assert((cycles) > 1, "vcsSleep: cycles must be greater than 1"); \
    ((cycles) == 3 ? vcsJmp3() : \
    ((cycles) & 1 ? (vcsJmp3(), vcsNop2n(((cycles)-3)>>1)) : vcsNop2n((cycles)>>1)))

#ifdef __cplusplus
}
#endif

#endif // VCSLIB_H
