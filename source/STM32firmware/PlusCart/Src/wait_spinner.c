#include "wait_spinner.h"
#include "waitbin.h"
#include "wait78bin.h"
#include "spinner.h"

static RAM_FUNC void StartWaitSpinner2600();
static RAM_FUNC void StartWaitSpinner7800();

void StartWaitSpinner()
{
	if (LockStatus == Locked2600)
	{
		StartWaitSpinner2600();
	}
	else
	{
		StartWaitSpinner7800();
	}
}

RAM_FUNC uint16_t writePadding(uint16_t address)
{
	vcsWrite6(address++, 0x0f);
	vcsWrite6(address++, WAIT78BIN_ARG_DISPLAY_LIST >> 8);
	vcsWrite6(address++, 5);
	return address;
}

RAM_FUNC void StartWaitSpinner7800()
{
	vcsJmp3();

	// To make spinner quad wide each bit becomes a byte in 160A mode
	// 32 bytes becomes a full 256 byte page of graphics
	uint16_t baseAddress = WAIT78BIN_ARG_GRAPHICS;
	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 8; j++)
		{
			for (int k = 0; k < 8; k++)
			{
				vcsWrite6(baseAddress++, (SDSpinner[i * 8 + (7 - j)] >> (7 - k)) & 1 ? 0x55 : 0);
			}
		}
	}

	vcsJmp3();

	// Generate the DLL
	// 3 byte header: offset, high, low
	baseAddress = WAIT78BIN_ARG_DISPLAY_LIST_LIST;
	// Top Padding
	baseAddress = writePadding(baseAddress);
	baseAddress = writePadding(baseAddress);
	// 7 rows of graphics
	for (int i = 0; i < 7; i++)
	{
		for (int j = 0; j < 6; j++)
		{
			vcsWrite6(baseAddress++, 0);							   // Zone Height=1
			vcsWrite6(baseAddress++, WAIT78BIN_ARG_DISPLAY_LIST >> 8); // High
			vcsWrite6(baseAddress++, i * 7);						   // Low
		}
	}
	// Bottom Padding
	for (int i = 0; i < 19; i++)
	{
		baseAddress = writePadding(baseAddress);
	}

	vcsJmp3();

	// Generate Display Lists
	baseAddress = WAIT78BIN_ARG_DISPLAY_LIST;
	for (int i = 0; i < 7; i++)
	{
		// 5 Byte Header
		vcsWrite6(baseAddress++, i * 8);					   // Low
		vcsWrite6(baseAddress++, 0x40);						   // Mode - 160A Direct
		vcsWrite6(baseAddress++, WAIT78BIN_ARG_GRAPHICS >> 8); // High
		vcsWrite6(baseAddress++, 0x18);						   // Palette=P0, Width=8bytes
		vcsWrite6(baseAddress++, 16);						   // Position
		// End DL
		vcsWrite6(baseAddress++, 0);
		vcsWrite6(baseAddress++, 0);
	}

	vcsJmp3();

	// Copy Kernel
	for (int i = 0; i < WAIT78BIN_ARG_KERNEL_SIZE; i++)
	{
		vcsWrite6((uint16_t)(WAIT78BIN_ARG_KERNEL + i), Wait78Bin[i]);
	}
	// Transfer control
	vcsJmpToRam3(WAIT78BIN_ARG_KERNEL);
}

RAM_FUNC void StartWaitSpinner2600()
{
	vcsJmp3();

	for (int i = 0; i < 128; i++)
	{
		vcsWrite5(i, 0);
	}
	vcsJmp3();
	vcsSta3(WSYNC);
	vcsLdx2(0xff);
	vcsTxs2();
	vcsSta3(RESPONE);
	vcsWrite5(COLUPF, 0x0a);
	vcsWrite5(COLUBK, 0x82);
	vcsWrite5(COLUP0, 0x82);
	vcsWrite5(GRP0, 0xff);
	vcsWrite5(NUSIZ0, 0x07);
	vcsWrite5(GRP1, 0xff);
	vcsWrite5(COLUP1, 0);
	vcsWrite5(HMP1, 0x30);
	vcsNop2();
	vcsSta3(RESP0);

	vcsSta3(WSYNC);
	vcsSta3(HMOVE);

	for (uint8_t i = 0; i < 32; i++)
	{
		vcsWrite5(WAITBIN_ARG_START_SPINNER + i, SDSpinner[i]);
	}
	vcsJmp3();

	for (int i = 0; i < sizeof(WaitBin); i++)
	{
		vcsWrite5(0xa0 + i, WaitBin[i]);
	}

	vcsJmpToRam3(WAITBIN_ARG_START_WAIT);
}

RAM_FUNC void EndWaitSpinner()
{
	vcsPokeRomByte(0x1ffe, 0xa5);
	vcsPokeRomByte(0x1fff, 0x5a);
	vcsSetNextAddress(0x1000);
	vcsNop2n(5);
}