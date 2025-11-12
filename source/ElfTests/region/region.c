#include "vcsLib.h"

const uint8_t NTSC[32] =
{
	0x82, 0xc2, 0xa2, 0x92, 0x8a, 0x86, 0x82, 0x00,
	0xfe, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x00,
	0x7e, 0x80, 0x80, 0x7c, 0x02, 0x02, 0xfc, 0x00,
	0x3e, 0x40, 0x80, 0x80, 0x80, 0x40, 0x3e, 0x00
};

const uint8_t PAL[32] =
{
	0x7c, 0x82, 0x82, 0xfc, 0x80, 0x80, 0x80, 0x00,
	0x10, 0x28, 0x44, 0xfe, 0x82, 0x82, 0x82, 0x00,
	0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xfe, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};


int elf_main(uint32_t* args)
{
	const uint8_t* pf = NTSC;
	// Always reset PC first, cause it's going to be close to the end of the 6507 address space
	vcsJmp3();
	
	// Init TIA and RIOT RAM
	vcsLda2(0);
	for (int i = 0; i < 256; i++) {
		vcsSta3((unsigned char)i);
	}

	while (1)
	{
		// 3 lines of VSYNC
		vcsLda2(2);
		vcsSta3(VSYNC);
		for (int i = 0; i < 3; i++) {
			vcsSta3(WSYNC);
		}
		vcsLda2(0);
		vcsSta3(VSYNC);
		// 37 lines of VBLANK
		for (int i = 0; i < 37; i++) {
			vcsSta3(WSYNC);
		}
		if (args[MP_SYSTEM_TYPE] == ST_NTSC_2600)
		{
			pf = NTSC;
		}
		else
		{
			pf = PAL;
		}
		vcsLda2(0);
		vcsSta3(VBLANK);
		// 192 lines of COLUBK
		for (int i = 0; i < 32; i++) 
		{
			for (int j = 0; j < 6; j++)
			{
				vcsSta3(WSYNC);
				vcsWrite5(COLUPF, 0xff);
				vcsWrite5(PF1, pf[i]);
				vcsJmp3();
			}
		}
	
		vcsWrite5(VBLANK, 2);
		// 30 lines of Overscan
		for (int i = 0; i < 30; i++) {
			vcsSta3(WSYNC);
			uint8_t p0Button = vcsRead6(INPT4);
			if (0 == (p0Button & 0x80))
			{
				vcsJmp3();
				vcsNop2n(0xf00);
				return 0;
			}
		}
	}
}
