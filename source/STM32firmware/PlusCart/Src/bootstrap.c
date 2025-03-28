/*
 * bootstrap.c
 *
 *  Created on: Mar 5, 2025
 *      Author: Zack Scolaro
 */

#include "global.h"
#include "cartridge_io.h"
#include "wait_spinner.h"
#include "wait78bin.h"

const uint8_t highByte[30] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0xa, 0xb, 0xc, 0xd,
							  0xe, 0xe, 0xd, 0xc, 0xb, 0xa, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};

// 7800 signature for a ROM of all 0xff
const uint8_t Signature[] = {0x07, 0xBB, 0xD4, 0x11, 0x6A, 0xD1, 0xFE, 0xF8,
							 0xE6, 0x26, 0x0E, 0xA3, 0x21, 0xFC, 0x0F, 0x36, 0xB8, 0xA1, 0x9A, 0x88,
							 0x0D, 0xF5, 0x29, 0xD2, 0x78, 0x14, 0x3C, 0xD4, 0x13, 0x1D, 0x5C, 0x5B,
							 0x0B, 0xFC, 0x3B, 0x24, 0x40, 0x9A, 0x7C, 0x37, 0xE2, 0x0B, 0xA3, 0x93,
							 0x15, 0x49, 0x1B, 0x68, 0x79, 0x62, 0x3A, 0xE8, 0x1F, 0x03, 0xC3, 0x7E,
							 0x1D, 0x48, 0xB1, 0x0F, 0x5F, 0xD8, 0xA6, 0xD9, 0x52, 0xBF, 0xA7, 0xB1,
							 0xF3, 0xA8, 0x7D, 0x14, 0x1F, 0xFE, 0x42, 0xE5, 0xAC, 0xE6, 0x0E, 0x07,
							 0x36, 0x36, 0xC8, 0x6E, 0x77, 0xFA, 0xEA, 0x72, 0x78, 0x2A, 0x92, 0xC2,
							 0xD3, 0x11, 0xA8, 0xDC, 0x07, 0xDE, 0xAA, 0x05, 0x4A, 0xDA, 0xC2, 0x43,
							 0xBF, 0x54, 0x43, 0x22, 0x4D, 0x7D, 0xCC, 0x0E, 0x00, 0x22, 0x7D, 0xE3,
							 0x1F, 0x24, 0x51, 0xea};

RAM_FUNC static void fakeSignature();

void bootStrap2();
void bootStrap()
{
	__disable_irq();
	bootStrap2();
	__enable_irq();
}

RAM_FUNC void bootStrap2()
{
	uint16_t addr;
	// Wait for 1ffc or 0ffc and then 1ffd or 0ffd to detect 2600 or 7800 respectively
	// Must provide a valid ROM while detecting system generation to prevent 2600 crash
	// 0x18 is CLC and results in a reset vector of 0x1818 on the 2600
	SET_DATA_MODE_IN

	uint32_t pollCount = 0;
	DATA_OUT = 0x18;

	while (((addr = ADDR_IN) & 0xfff) != 0xffc)
	{
		pollCount++;
		if (pollCount > 5000000)
		{
			// Must not be in a real system
			// TODO default to an offline ROM when dump/emulate type console
		}
	}

	for (int i = 0; i < 50; i++)
	{
		if (ADDR_IN == 0x1ffc)
		{
			SET_DATA_MODE_OUT;
			vcsSetNextAddress(0x19ff);
			vcsJmp3();

			// See how long it takes to execute 4000 nops to detect the system type
			int totalDelay = 0;
			vcsNop2n(4040);
			while (ADDR_IN != 0x1fa0)
				totalDelay++;
			vcsJmp3();

			// TODO PAL vs NTSC detection

			LockStatus = Locked2600;
			Is7800Ntsc = false;
			StartWaitSpinner();	
		}
	}

	DATA_OUT = 0xf3;
	while (1)
	{
		addr = ADDR_IN;
		if (addr == 0x0884)
		{
			// NTSC 7800 detected

			// drive bus with f3 until all the preliminary bios checks are complete
			uint16_t targetAddr = 0x1ffd;
			while (1)
			{
				addr = ADDR_IN;
				if (addr & 0x1000)
				{
					SET_DATA_MODE_OUT;
					if (addr == targetAddr)
					{
						targetAddr = 0x35b;
					}
				}
				else
				{
					SET_DATA_MODE_IN;
					if (addr == targetAddr)
					{
						// preliminary checks complete

						fakeSignature();
						return;
					}
				}
			}
		}
		else if (addr == 0x0e47)
		{
			// PAL 7800 detected
			// drive bus with f3 until all the preliminary bios checks are complete
			uint16_t targetAddr = 0x1ffd;
			while (1)
			{
				addr = ADDR_IN;
				if (addr & 0x1000)
				{
					SET_DATA_MODE_OUT;
					if (addr == targetAddr)
					{
						targetAddr = 0x0357;
					}
				}
				else
				{
					SET_DATA_MODE_IN;
					if (addr == targetAddr)
					{
						// preliminary checks complete

						// Ignore the read and write to 0x1bea
						while (ADDR_IN != 0x0363)
							;

						// I think the 7800 compares ffff with dfff to differentiate between 2600 and 7800 carts
						// as a final check before the bios turns over control

						//						  2358	c	0358 ad LDA $1bea
						//						  2359	c	0359 ea
						//						  235a	c	035a 1b
						//						  1bea	c	1bea 00
						//						  235b	c	035b 49 EOR #ff
						//						  235c	c	035c ff
						//						  235d	c	035d 8d STA $1bea
						//						  235e	c	035e ea
						//						  235f	c	035f 1b
						//						  1bea	c	1bea ff
						//						  2360	c	0360 a8 TAY
						//						  2361	c	0361 a2 LDX #5
						//						  2362	c	0362 05
						//						  2363	c	0363 bd LDA fffa,x
						//						  2364	c	0364 fa
						//						  2365	c	0365 ff
						//						  ffff	c	1fff ee
						//						  2366	c	0366 dd CMP fdfa,x
						//						  2367	c	0367 fa
						//						  2368	c	0368 df
						//						  dfff	c	1fff 30
						//						  2369	c	0369 d0 BNE

						DATA_OUT = 0xdd;
						while (ADDR_IN != 0x1fff)
							;
						SET_DATA_MODE_OUT;
						while (ADDR_IN != 0x366)
							;
						SET_DATA_MODE_IN;

						DATA_OUT = 0xd0;
						while (ADDR_IN != 0x1fff)
							;
						SET_DATA_MODE_OUT;
						while (ADDR_IN != 0x369)
							;
						SET_DATA_MODE_IN;

						vcsSetNextAddress(0x1000);
						// Now just wait for BIOS to finish up and JMP to the reset vector
						//						  239a	c	039a 6c
						//						  239b	c	039b fc
						//						  239c	c	039c ff
						//						  fffc	c	1ffc 00
						//						  fffd	c	1ffd d0
						while (ADDR_IN != 0x39a)
							;
						while (ADDR_IN != 0x39b)
							;
						while (ADDR_IN != 0x39c)
							;

						// Feed in the reset vector and then we're ready to go

						DATA_OUT = 0xf8;
						while (ADDR_IN != 0x1ffc)
							;
						SET_DATA_MODE_OUT;

						vcsSetNextAddress(0x1900);
						vcsJmp3();

						LockStatus = Unlocked7800;
						Is7800Ntsc = false;
						StartWaitSpinner();
					}
				}
			}
		}
	}
}

RAM_FUNC static void fakeSignature()
{
	uint16_t addr;
	int i;

	// inject the ROM signature
	i = 0x77; // SignatureLength-1
	uint16_t expectedAddress = (uint16_t)(0x1f80 + i);
	DATA_OUT = Signature[i];
	while (1)
	{
		while (ADDR_IN != 0x053e)
			;
		while (ADDR_IN != expectedAddress)
			;
		SET_DATA_MODE_OUT;
		while (ADDR_IN == expectedAddress)
			;
		SET_DATA_MODE_IN;
		i--;
		if (i < 0)
		{
			break;
		}
		else
		{
			expectedAddress--;
			DATA_OUT = Signature[i];
		}
	}

	DATA_OUT = 0xff;
	// Top page ff7f-fff9 (wraps around to top of page
	expectedAddress = 0x1f7f;
	for (i = 0; i < 0x87; i++)
	{
		// DMA frequently starts as the address of the ROM is being put on the bus
		// So the expected ROM read may occur just after DMA ends and we will miss it if we only handle the first
		// instance of the ROM address occurring on the bus.
		while (ADDR_IN != 0x378 || ADDR_IN != 0x378)
			;
		while (1)
		{
			addr = ADDR_IN;
			if (addr == (expectedAddress))
			{
				SET_DATA_MODE_OUT;
				;
			}
			else
			{
				SET_DATA_MODE_IN;
				;
				if (addr == 0x379)
					break;
			}
		}
		expectedAddress--;
		expectedAddress |= 0x1f00;
	}

	// Pages 0-e, then e-0 (30 pages total)
	for (i = 0; i < 30; i++)
	{
		expectedAddress = (uint16_t)(0x1000 + (highByte[i] << 8));

		while (1)
		{

			// Look for 0x2405 on the bus to avoid seeing RAM accesses to 0x1800
			while (ADDR_IN != 0x404 || ADDR_IN != 0x404)
				;
			while (ADDR_IN != 0x405 || ADDR_IN != 0x405)
				;
			while (ADDR_IN != 0x406 || ADDR_IN != 0x406)
				;

			// Same as above. Maria DMA is making life difficult for us.
			while (1)
			{
				addr = ADDR_IN;
				if (addr == (expectedAddress))
				{
					SET_DATA_MODE_OUT;
					;
				}
				else
				{
					SET_DATA_MODE_IN;
					;
					if (addr == 0x407)
						break;
				}
			}

			if ((expectedAddress & 0xff) == 0xff)
			{
				break;
			}
			else
			{
				expectedAddress++;
			}
		}
	}

	while (ADDR_IN != 0x03f2)
		;
	while (ADDR_IN == 0x03f2)
		;
	while (ADDR_IN != 0x1a77)
		;
	while (ADDR_IN == 0x1a77)
		;

	for (expectedAddress = 0x6bd; expectedAddress < 0x6c0; expectedAddress++)
	{
		while (ADDR_IN != (expectedAddress) || ADDR_IN != (expectedAddress))
			;
	}

	DATA_OUT = 0xf8;
	while (ADDR_IN != 0x1ffc)
		;
	SET_DATA_MODE_OUT;

	vcsSetNextAddress(0x1900);
	// vcsWrite5(INPTCTRL, 0x7); // Lock into 7800 mode
	vcsNop2();
	LockStatus = Unlocked7800;
	Is7800Ntsc = true;
	StartWaitSpinner();
	// // vcsJmp3();
	// while (1)
	// 	;

	//
	// vcsSta3(MARIA_WSYNC);

	// for (int i = 0; i < sizeof(Wait78Bin); i++)
	// {
	// 	vcsJmp3();
	// 	vcsWrite6((uint16_t)(WAIT78BIN_ARG_LOAD + i), Wait78Bin[i]);
	// }
	// vcsJmpToRam3(WAIT78BIN_ARG_START);
	// // i = 0;
	// // Color pattern
	// while (1)
	// {
	// 	vcsSta3(MARIA_WSYNC);
	// 	vcsWrite6(BACKGRND, (uint8_t)i++);
	// 	vcsJmp3();
	// }

	// Lock into 2600 mode
	// vcsWrite5(INPTCTRL, 0xd);
	// vcsNop2n(1024);
	// LockStatus = Locked2600;
	// StartWaitSpinner();

	// while(1)
	// 	;
	//	uint32_t mainArgs2600[] = {
	//	ST_NTSC_2600, // MP_SYSTEM_TYPE (TBD)		0
	//			0, // MP_CLOCK_HZ			1
	//			0, // MP_FEARTURE_FLAGS		2
	//			0, // Elapsed
	//			0 // threshold
	//			};
	//	//Emulate4K();
	//	elf_main(mainArgs2600);
	//	while (1)
	//		;

	//

	// Lock into 7800 mode
	//	vcsWrite5(INPTCTRL, 0x7);
	//	vcsSta3(MARIA_WSYNC);
	//	vcsNop2n(1024);
	//
	//	while(1){
	//		for(int i = 0; i < 62; i++){
	//			vcsSta3(MARIA_WSYNC);
	//			vcsJmp3();
	//		}
	//		for(int i = 0; i < 16; i++){
	//			for(int j = 0; j < 10; j++){
	//			vcsWrite6(BACKGRND, j)
	//		}
	//
	//	}
	//
	//				uint32_t mainArgs[] =
	//				{
	//					ST_NTSC_7800, // MP_SYSTEM_TYPE (TBD)		0
	//					0, // MP_CLOCK_HZ			1
	//					0, // MP_FEARTURE_FLAGS		2
	//					0, // Elapsed
	//					0 // threshold
	//				};
	//				elf_main(mainArgs);
	// while(1)
	// 	;
}
