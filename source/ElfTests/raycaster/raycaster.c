#include "vcsLib.h"
#include "assets.h"
#include "overblank.h"

#define vcsWritePF3(address, data, nextCol)	vcsWrite3(address, data); \
	colupf = heights[nextCol] >= start ? colors[nextCol] : colbak;


// TODO move to common location

int elf_main(uint32_t *args)
{
	uint8_t but0 = 0xff;
	uint8_t joy0 = 0xff;

	// Always reset PC first, cause it's going to be close to the end of the 6507 address space
	vcsJmp3();
	// Init TIA
	for (int i = 0; i < 0x80; i++) {
		vcsLda2(0);
		vcsSta3((unsigned char)i);
	}

	vcsCopyOverblankToRiotRam();
	vcsStartOverblank();

	for (int i = 0; i < 40; i++)
	{
		heights[i] = 100;
		colors[i] = (uint8_t)((i << 4) | 0xf);
	}

	while (1)
	{
		overblank(but0, joy0, colors, args[MP_SYSTEM_TYPE]);

		vcsEndOverblank();
		if (0 == (but0 & 0x80))
		{
			vcsJmp3();
			vcsNop2n(0xf00);
			return 0;
		}

		vcsWrite5(CTRLPF, 0);
		vcsWrite5(GRP0, 0);
		vcsWrite5(GRP1, 0);
		vcsWrite5(ENAM0, 0);
		vcsWrite5(ENAM1, 0);
		vcsWrite5(ENABL, 0);

		vcsWrite5(COLUBK, 0);
		vcsWrite5(COLUPF, 0);

		vcsSta3(WSYNC);
		vcsSta3(WSYNC);
		vcsSta3(WSYNC);
		vcsSta3(WSYNC);


		vcsWrite5(VBLANK, 0);

		vcsLdaForBusStuff2();
		vcsLdxForBusStuff2();
		vcsLdyForBusStuff2();

		vcsSta3(WSYNC);
		vcsSta3(WSYNC);

		for (int i = 0; i < 64; i++)
		{
			unsigned char colupf;
			// First
			vcsNop2n(3);
			int start = i < 32 ? 32 - i : i - 32;
			int colbak = ((start >> 2) & 0x0f);
			colbak |= i < 32 ? 0x80 : 0xc0;
			vcsWrite3(PF0, 0x55);
			vcsWrite3(PF1, 0x49);
			vcsWritePF3(PF2, 0x24, 0);
			vcsWrite3(COLUPF, colupf);

			vcsJmp3();
			vcsWritePF3(COLUPF, 0, 5);
			vcsWritePF3(COLUPF, colupf, 8);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 11);
			vcsWritePF3(COLUPF, colupf, 14);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 17);
			vcsWritePF3(COLUPF, colupf, 20);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 25);
			vcsWrite3(COLUPF, 0); // MASKED
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 28);
			vcsWritePF3(COLUPF, colupf, 31);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 34);
			vcsWritePF3(COLUPF, colupf, 37);
			vcsNop2();
			vcsWrite3(COLUPF, colupf);
			vcsSta3(WSYNC);

			// Second
			vcsWrite3(PF0, 0xaa);
			vcsWrite3(PF1, 0x24);
			vcsWritePF3(PF2, 0x49, 1);
			vcsWritePF3(COLUPF, colupf, 3);
			vcsJmp3();
			vcsJmp3();
			vcsJmp3();
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 6);
			vcsWritePF3(COLUPF, colupf, 9);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 12);
			vcsWritePF3(COLUPF, colupf, 15);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 18);
			vcsWritePF3(COLUPF, colupf, 21);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 23);
			vcsWritePF3(COLUPF, colupf, 26);
			vcsWritePF3(COLUPF, colupf, 29);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 32);
			vcsWritePF3(COLUPF, colupf, 35);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 38);
			vcsWrite3(COLUPF, colupf); // 38
			vcsSta3(WSYNC);

			// Third
			vcsWrite3(PF0, 0x44);
			vcsWrite3(PF1, 0x92);
			vcsWritePF3(PF2, 0x92, 2);
			vcsWritePF3(COLUPF, colupf, 4);
			vcsJmp3();
			vcsJmp3();
			vcsJmp3();
			vcsJmp3();
			vcsWritePF3(COLUPF, colupf, 7);
			vcsWritePF3(COLUPF, colupf, 10);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 13);
			vcsWritePF3(COLUPF, colupf, 16);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 19);
			vcsWritePF3(COLUPF, colupf, 22);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 24);
			vcsWritePF3(COLUPF, colupf, 27);
			vcsWritePF3(COLUPF, colupf, 30);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 33);
			vcsWritePF3(COLUPF, colupf, 36);
			vcsNop2();
			vcsWritePF3(COLUPF, colupf, 39);
			vcsWrite3(COLUPF, colupf); // 39

			vcsSta3(PF0); // Waste 3 cycles with as much time as possible before next bus service is needed
		}

		vcsWrite5(VBLANK, 2);
		but0 = vcsRead6(INPT4);
		joy0 = vcsRead6(SWCHA);
		vcsStartOverblank();
	}
}
