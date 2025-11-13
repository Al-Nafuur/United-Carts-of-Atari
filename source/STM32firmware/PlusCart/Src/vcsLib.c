#include <stdint.h>
#include <stdlib.h>

#include "vcsLib.h"
#include "cartridge_io.h"

#define SetNextRomAddress(addr) next_address = addr

uint8_t aMask = 0xff;
uint8_t xMask = 0xff;
uint8_t yMask = 0xff;

__attribute__((section(".noinit")))
static uint8_t rand_seed[4];

static uint16_t next_address;
static uint8_t lowMask;
static uint8_t correctionMaskHi;
static uint8_t correctionMaskLo;

static void updateLookupTables();

static const uint8_t Overblank[] =
{
	0xa0,0x00,			// ldy #0
	0xa5,0xe0,			// lda $e0
						// OverblankLoop:
	0x85,0x02,			// sta WSYNC
	0x85,0x2d,			// sta AUDV0 (currently using $2d instead to disable audio until fully implemented
	0x98,				// tya
	0x18,				// clc
	0x6a,				// ror
	0xaa,				// tax
	0xb5,0xe0,			// lda $e0,x
	0x90,0x04,			// bcc
	0x4a,				// lsr
	0x4a,				// lsr
	0x4a,				// lsr
	0x4a,				// lsr
	0xc8,				// iny
	0xc0, 0x1d,			// cpy #$1d
	0xd0, 0x04,			// bne
	0xa2, 0x02,			// ldx #2
	0x86, 0x00,			// stx VSYNC
	0xc0, 0x20,			// cpy #$20
	0xd0, 0x04,			// bne SkipClearVSync
	0xa2, 0x00,			// ldx #0
	0x86, 0x00,			// stx VSYNC
						// SkipClearVSync:
	0xc0, 0x3f,			// cpy #$3f
	0xd0, 0xdb,			// bne OverblankLoop
						// WaitForCart:
	0xae, 0xff, 0xff,	// ldx $ffff
	0xd0, 0xfb,			// bne WaitForCart
	0x4c, 0x00, 0x10	// jmp $1000
};

const uint8_t ReverseByte[] =
{
	0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0,	0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0,
	0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8,	0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8,
	0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4,	0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4,
	0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec,	0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc,
	0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2,	0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2,
	0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea,	0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa,
	0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6,	0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6,
	0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee,	0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe,
	0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1,	0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1,
	0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9,	0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9,
	0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5,	0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5,
	0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed,	0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd,
	0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3,	0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3,
	0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb,	0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb,
	0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7,	0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7,
	0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef,	0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff,
};

__attribute__((section(".RamFunc")))
void InjectRomByte(uint8_t value)
{
	while (next_address != ADDR_IN)
		;

	DATA_OUT = value;
	SET_DATA_MODE_OUT
		next_address++;
}

__attribute__((section(".RamFunc")))
void YieldDataBus(uint16_t address)
{
	while (ADDR_IN != address)
		;

	SET_DATA_MODE_IN
}

static uint8_t opcodeLookup[256]; // Lookup table to quickly map value to stuff to the correct store register instruction
static uint16_t modeLookup[256]; // Lookup table to quickly map value to stuff to the correct mode, only some bits need to be stuffed

__attribute__((long_call, section(".RamFunc")))
void vcsCopyOverblankToRiotRam()
{
	for(int i = 0; i < sizeof(Overblank); i++)
	{
		vcsWrite5((uint8_t)(0x80 + i), Overblank[i]);
	}
}

__attribute__((long_call, section(".RamFunc")))
void vcsLibInit()
{
	// Seed with uninitialized RAM
	srand(*((unsigned int*)rand_seed));
	// Signal ZP load routine to transfer control back to ROM
	SetNextRomAddress(0x1000);
	InjectRomByte(0xd8);
	SetNextRomAddress(0x1fef);
	InjectRomByte(0xff);
	SetNextRomAddress(0x1ffc);
	InjectRomByte(0x00);
	InjectRomByte(0x10);
	SetNextRomAddress(0x1000);
	vcsCopyOverblankToRiotRam();
	vcsStartOverblank();
}

__attribute__((long_call, section(".RamFunc")))
void vcsInitBusStuffing()
{
	lowMask = 0xff; // Start with stuffing all bits low
	correctionMaskHi = 0x00;
	correctionMaskLo = 0x00;
	uint8_t highMask = 0xff; // Tracks high stuff failures
	// Initialize the lookup table
	updateLookupTables();
	vcsEndOverblank();
	vcsJmp3();
	vcsWrite5(VBLANK, 0);

	// Position P0
	vcsSta3(WSYNC);
	for (int i = 0; i < 15; i++)
	{
		vcsJmp3();
	}
	vcsSta3(RESP0);
	vcsWrite5(HMP0, 0x20);
	vcsSta3(WSYNC);
	vcsSta3(HMOVE);

	vcsSta3(WSYNC);
	vcsWrite5(VSYNC, 0);
	vcsSta3(HMCLR);

	// get ready
	vcsWrite5(CTRLPF, 0x01);
	vcsWrite5(COLUBK, 0x00);
	vcsWrite5(COLUPF, 0x00);
	vcsWrite5(NUSIZ0, 0x07);
	vcsWrite5(COLUP0, 0x00);
	vcsSta3(WSYNC);

	// test low first, then high
	for (int k = 0; k < 2; k++)
	{
		if( k ==1)
		{
			// Update tables with stuff-low results
			vcsJmp3();
			vcsNop2n(1000);
			updateLookupTables();
		}
		// Iterate through each bit
		for (int i = 0; i < 8; i++)
		{
			vcsWrite5(GRP0, 1 << i); // Set the Player pixel for the bit we're testing
			vcsSta3(WSYNC);

			for (int j = 0; j < 256; j++)
			{
				uint8_t tmp = (uint8_t)( k == 0 ? (j & ~(1 << i)) // Always clear bit for low test
						: (j | (1 << i))); // Always set bit for high test
				vcsLda2(lowMask); // Set all registers so it doesn't matter what opcodeLookup has in it
				vcsLdx2(lowMask); // Since low mask is already configured, only failed bits get tested for stuffing high
				vcsLdy2(lowMask);
				vcsNop2();
				vcsSta3(CXCLR);
				vcsWrite3(PF2, tmp);	// Try stuffing in a value, but the bit we're testing is always low/high depending on k
				for (int l = 0; l < 15; l++)
				{
					vcsJmp3();
				}
				uint8_t cx = vcsRead6(CXP0FB);	// Check collision register for stuff failures
				vcsSta3(WSYNC);
				if (k == 0)
				{
					if (cx & 0x80)
					{
						// Stuff low failed, update mask
						lowMask &= (uint8_t)~(1 << i); // This breaks testing low for this bit, but we've already marked it as failed
					}
				}
				else
				{
					if ((cx & 0x80) == 0)
					{
						// Stuff high failed, update mask, implies that both low and high failed
						highMask &= (uint8_t)~(1 << i);
					}
				}
			}
			vcsSta3(WSYNC);
		}
		vcsSta3(WSYNC);
	}

	vcsNop2n(1000);

	// calculate error correction
	// First correct bits that can't be stuffed either way
	for (int i = 7; i >= 0; i--)
	{
		if (0 == ((1 << i) & highMask))
		{
			if (correctionMaskLo == 0)
			{
				correctionMaskLo = 1 << i;
			}
			else if (correctionMaskHi == 0)
			{
				correctionMaskHi = 1 << i;
			}
		}
	}
	// Then correct bits that can only be stuffed high
	for (int i = 7; i >= 0; i--)
	{
		if (0 == ((1 << i) & lowMask) && 0 != ((1 << i) & highMask))
		{
			if (correctionMaskLo == 0)
			{
				correctionMaskLo = 1 << i;
			}
			else if (correctionMaskHi == 0)
			{
				correctionMaskHi = 1 << i;
			}
		}
	}
	// Finally correct any free bits to minimize how much we stuff
	// Try to correct most significant bits since they produce the most significant errors
	if (correctionMaskLo == 0)
	{
		correctionMaskLo = 0x40;
		correctionMaskHi = 0x80;
	}
	else if (correctionMaskHi == 0 || correctionMaskHi == correctionMaskLo)
	{
		correctionMaskHi = correctionMaskLo == 0x80 ? 0x40 : 0x80;
	}
	// Stop stuffing these bits and let correction do it's thing.
	lowMask &= (uint8_t)~correctionMaskLo;
	lowMask &= (uint8_t)~correctionMaskHi;

	// final masks
	aMask = lowMask | correctionMaskLo;
	xMask = lowMask | correctionMaskHi;
	yMask = lowMask | correctionMaskHi | correctionMaskLo;

	// Finalize lookups now that we have the final masks in place
	updateLookupTables();

	// Bus stuffing is ready now
	vcsStartOverblank();
}

__attribute__((long_call, section(".RamFunc")))
static void updateLookupTables()
{
	for (int i = 0; i < 256; i++)
	{
		if (i & correctionMaskHi)
		{
			opcodeLookup[i] = (i & correctionMaskLo) ? 0x84 : 0x86;
		}
		else
		{
			opcodeLookup[i] = (i & correctionMaskLo) ? 0x85 : 0x87;
		}
		uint16_t mode = (uint8_t)i ^ lowMask;
		// Never drive the bits that get corrected by opcodes above
		mode &= (uint16_t)~correctionMaskLo;
		mode &= (uint16_t)~correctionMaskHi;

		modeLookup[i] = (uint16_t)(((mode & 0x80) << 7) | ((mode & 0x40) << 6) | ((mode & 0x20) << 5) | ((mode & 0x10) << 4) |
				((mode & 0x08) << 3) | ((mode & 0x04) << 2) | ((mode & 0x02) << 1) | (mode & 0x01));
	}
}

// Uses Bus-Stuffing, requires A,X,Y to be set via vcsLd*ForBusStuff2() functions prior to use and any time those registers are changed.
__attribute__((long_call, section(".RamFunc")))
void vcsWrite3(uint8_t ZP, uint8_t data)
{
	InjectRomByte(opcodeLookup[data]);
	InjectRomByte(ZP);

	// Stuff in the data over what's there
	while (ZP != ADDR_IN)
		;

	// The full value is written to ODR, but thanks to modeLookup[], only bits that need to be stuffed get driven
	DATA_OUT = data;
	SET_DATA_MODE(modeLookup[data]);
}

// Uses Bus-Stuffing, requires A,X,Y to be set via vcsLd*ForBusStuff2() functions prior to use and any time those registers are changed.
__attribute__((long_call, section(".RamFunc")))
void vcsWrite4(uint16_t address, uint8_t data)
{
    InjectRomByte(opcodeLookup[data] + 8); // Adding 8 to the opcode changes the address mode from zero page to absolute.
    InjectRomByte((uint8_t)address);
    InjectRomByte((uint8_t)(address >> 8));

	// Stuff in the data over what's there
	while (address != ADDR_IN)
		;

	// The full value is written to ODR, but thanks to modeLookup[], only bits that need to be stuffed get driven
	DATA_OUT = data;
	SET_DATA_MODE(modeLookup[data]);
}

__attribute__((long_call, section(".RamFunc")))
void vcsJmp3()
{
	InjectRomByte(0x4c);
	InjectRomByte(0x00);
	InjectRomByte(0x10);
	SetNextRomAddress(0x1000);
}

__attribute__((long_call, section(".RamFunc")))
void vcsLda2(uint8_t data)
{
	InjectRomByte(0xa9);
	InjectRomByte(data);
}

__attribute__((long_call, section(".RamFunc")))
void vcsSta3(uint8_t ZP)
{
	InjectRomByte(0x85);
	InjectRomByte(ZP);
	YieldDataBus(ZP);
}

__attribute__((long_call, section(".RamFunc")))
uint8_t SnoopDataBus(uint16_t address)
{
	while (ADDR_IN != address)
		;

	SET_DATA_MODE_IN
	// Give peripheral time to respond
	while (ADDR_IN == address)
		;

	return DATA_IN;
}

// Legacy function to avoid breaking existing ELF bins. Chameleon Cart requires vcsRead6.
__attribute__((long_call, section(".RamFunc")))
uint8_t vcsRead4(uint16_t address)
{
	InjectRomByte(0xad);
	InjectRomByte((uint8_t)(address & 0xff));
	InjectRomByte((uint8_t)(address >> 8));
	return SnoopDataBus(address);
}

// 6-cycle read function - required for Chameleon Cart compatibility
__attribute__((long_call, section(".RamFunc")))
uint8_t vcsRead6(uint16_t address)
{
    InjectRomByte(0xad); 
    InjectRomByte((uint8_t)(address & 0xff));
    InjectRomByte((uint8_t)(address >> 8));
    uint8_t value = SnoopDataBus(address);
    vcsNop2(); // allows extra cycles to process read
    return value;
}

__attribute__((long_call, section(".RamFunc")))
void vcsStartOverblank()
{
	InjectRomByte(0x4c);
	InjectRomByte(0x80);
	InjectRomByte(0x00);
	YieldDataBus(0x0080);
}

__attribute__((long_call, section(".RamFunc")))
void vcsEndOverblank()
{
	SetNextRomAddress(0x1fff);
	InjectRomByte(0x00);
	YieldDataBus(0x00ac);
	SetNextRomAddress(0x1000);
}

__attribute__((long_call, section(".RamFunc")))
void vcsLdaForBusStuff2()
{
	vcsLda2(aMask);
}

__attribute__((long_call, section(".RamFunc")))
void vcsLdxForBusStuff2()
{
	vcsLdx2(xMask);
}

__attribute__((long_call, section(".RamFunc")))
void vcsLdyForBusStuff2()
{
	vcsLdy2(yMask);
}

__attribute__((long_call, section(".RamFunc")))
void vcsWrite5(uint8_t ZP, uint8_t data)
{
	InjectRomByte(0xa9);
	InjectRomByte(data);
	InjectRomByte(0x85);
	InjectRomByte(ZP);
	YieldDataBus(ZP);
}

__attribute__((long_call, section(".RamFunc")))
void vcsWrite6(uint16_t address, uint8_t data)
{
	InjectRomByte(0xa9);
	InjectRomByte(data);
	InjectRomByte(0x8d);
	InjectRomByte((uint8_t)(address & 0xff));
	InjectRomByte((uint8_t)(address >> 8));
	YieldDataBus(address);
}

__attribute__((long_call, section(".RamFunc")))
void vcsLdx2(uint8_t data)
{
	InjectRomByte(0xa2);
	InjectRomByte(data);
}

__attribute__((long_call, section(".RamFunc")))
void vcsLdy2(uint8_t data)
{
	InjectRomByte(0xa0);
	InjectRomByte(data);
}

__attribute__((long_call, section(".RamFunc")))
void vcsSta4(uint16_t address)
{
	InjectRomByte(0x8d);
	InjectRomByte((uint8_t)(address & 0xff));
	InjectRomByte((uint8_t)(address >> 8));
	YieldDataBus(address);
}

__attribute__((long_call, section(".RamFunc")))
void vcsSax3(uint8_t ZP)
{
	InjectRomByte(0x87);
	InjectRomByte(ZP);
	YieldDataBus(ZP);
}

__attribute__((long_call, section(".RamFunc")))
void vcsStx3(uint8_t ZP)
{
	InjectRomByte(0x86);
	InjectRomByte(ZP);
	YieldDataBus(ZP);
}

__attribute__((long_call, section(".RamFunc")))
void vcsStx4(uint16_t address)
{
	InjectRomByte(0x8e);
	InjectRomByte((uint8_t)(address & 0xff));
	InjectRomByte((uint8_t)(address >> 8));
	YieldDataBus(address);
}

__attribute__((long_call, section(".RamFunc")))
void vcsSty3(uint8_t ZP)
{
	InjectRomByte(0x84);
	InjectRomByte(ZP);
	YieldDataBus(ZP);
}

__attribute__((long_call, section(".RamFunc")))
void vcsSty4(uint16_t address)
{
	InjectRomByte(0x8c);
	InjectRomByte((uint8_t)(address & 0xff));
	InjectRomByte((uint8_t)(address >> 8));
	YieldDataBus(address);
}

__attribute__((long_call, section(".RamFunc")))
void vcsJsr6(uint16_t target)
{
	InjectRomByte(0x20);
	InjectRomByte((uint8_t)(target & 0xff));

	//Stack operations
	while (ADDR_IN & 0x1000)
		;
	SET_DATA_MODE_IN

	InjectRomByte((uint8_t)(target >> 8));
	SetNextRomAddress(target & 0x1fff);
}

__attribute__((long_call, section(".RamFunc")))
void vcsNop2()
{
	InjectRomByte(0xea);
}

// Puts nop on bus for n * 2 cycles
// Use this to perform lengthy calculations
__attribute__((long_call, section(".RamFunc")))
void vcsNop2n(uint16_t n)
{
	InjectRomByte(0xea);
	next_address += (uint16_t)(n-1);
}


__attribute__((long_call, section(".RamFunc")))
void vcsTxs2()
{
	InjectRomByte(0x9a);
}

__attribute__((long_call, section(".RamFunc")))
void vcsPha3()
{
	InjectRomByte(0x48);
	while (ADDR_IN & 0x1e00)
		;
	SET_DATA_MODE_IN
}

__attribute__((long_call, section(".RamFunc")))
void vcsPhp3()
{
	InjectRomByte(0x08);
	while (ADDR_IN & 0x1e00)
		;
	SET_DATA_MODE_IN
}

__attribute__((long_call, section(".RamFunc")))
void vcsPla4()
{
	InjectRomByte(0x68);
	while (ADDR_IN & 0x1e00)
		;
	SET_DATA_MODE_IN
}


__attribute__((long_call, section(".RamFunc")))
void vcsPlp4()
{
	InjectRomByte(0x28);
	while (ADDR_IN & 0x1e00)
		;
	SET_DATA_MODE_IN
}

__attribute__((long_call, section(".RamFunc")))
void vcsPla4Ex(uint8_t data)
{
	InjectRomByte(0x08);
	while (ADDR_IN & 0x1e00)
		;
	// d7,d6 are not driven by cart, because they're driven by TIA
	*DATA_ODR = data;
	SET_DATA_MODE(0x0555)
}

__attribute__((long_call, section(".RamFunc")))
void vcsPlp4Ex(uint8_t data)
{
	InjectRomByte(0x28);
	while (ADDR_IN & 0x1e00)
		;
	// d7,d6 are not driven by cart, because they're driven by TIA
	*DATA_ODR = data;
	SET_DATA_MODE(0x0555)
}


__attribute__((long_call, section(".RamFunc")))
void vcsWaitForAddress(uint16_t address)
{
	while(ADDR_IN != address)
		;
}

__attribute__((long_call, section(".RamFunc")))
void vcsJmpToRam3(uint16_t address)
{
	// JMP address
	InjectRomByte(0x4c);
	InjectRomByte((uint8_t)(address & 0xff));
	InjectRomByte((uint8_t)(address >> 8));
	YieldDataBus(address);
}


__attribute__((long_call, section(".RamFunc")))
void injectDmaData(int address, int count, const uint8_t* pBuffer)
{
	// TODO
}

int randint()
{
	return rand();
}

