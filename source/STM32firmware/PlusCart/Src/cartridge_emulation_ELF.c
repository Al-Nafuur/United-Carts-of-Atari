#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

// #include "flash.h"
#include "cartridge_emulation.h"
#include "cartridge_emulation_ELF.h"
#include "cartridge_firmware.h"
#include "vcsLib.h"
#include "global.h"
#include "wait_spinner.h"

#define NTSC_CLOCK 1193182UL
#define PAL_CLOCK 1182298UL

NameAddressMapEntry NameAddressMap[] = {
	// Color lookup table is updated based on detected system. Keep at index 0
	{(uint32_t)&Ntsc2600[0], "ColorLookup"},
	// Low level bus access - handy for distributing prototype banking schemes without updating firmware
	{(uint32_t)&ADDR_IDR, "ADDR_IDR"},
	{(uint32_t)&DATA_IDR, "DATA_IDR"},
	{(uint32_t)&DATA_ODR, "DATA_ODR"},
	{(uint32_t)&DATA_MODER, "DATA_MODER"},
	// Used by GCC/CRT
	{(uint32_t)memset, "memset"},
	{(uint32_t)memcpy, "memcpy"},
	// Strong-ARM framework
	{(uint32_t)&ReverseByte[0], "ReverseByte"},
	{(uint32_t)vcsLdaForBusStuff2, "vcsLdaForBusStuff2"},
	{(uint32_t)vcsLdxForBusStuff2, "vcsLdxForBusStuff2"},
	{(uint32_t)vcsLdyForBusStuff2, "vcsLdyForBusStuff2"},
	{(uint32_t)vcsWrite3, "vcsWrite3"},
	{(uint32_t)vcsJmp3, "vcsJmp3"},
	{(uint32_t)vcsNop2, "vcsNop2"},
	{(uint32_t)vcsNop2n, "vcsNop2n"},
	{(uint32_t)vcsWrite5, "vcsWrite5"},
	{(uint32_t)vcsWrite6, "vcsWrite6"},
	{(uint32_t)vcsLda2, "vcsLda2"},
	{(uint32_t)vcsLdx2, "vcsLdx2"},
	{(uint32_t)vcsLdy2, "vcsLdy2"},
	{(uint32_t)vcsSax3, "vcsSax3"},
	{(uint32_t)vcsSta3, "vcsSta3"},
	{(uint32_t)vcsStx3, "vcsStx3"},
	{(uint32_t)vcsSty3, "vcsSty3"},
	{(uint32_t)vcsSta4, "vcsSta4"},
	{(uint32_t)vcsStx4, "vcsStx4"},
	{(uint32_t)vcsSty4, "vcsSty4"},
	{(uint32_t)vcsCopyOverblankToRiotRam, "vcsCopyOverblankToRiotRam"},
	{(uint32_t)vcsStartOverblank, "vcsStartOverblank"},
	{(uint32_t)vcsEndOverblank, "vcsEndOverblank"},
	{(uint32_t)vcsRead4, "vcsRead4"},
	{(uint32_t)randint, "randint"},
	{(uint32_t)vcsTxs2, "vcsTxs2"},
	{(uint32_t)vcsJsr6, "vcsJsr6"},
	{(uint32_t)vcsPha3, "vcsPha3"},
	{(uint32_t)vcsPhp3, "vcsPhp3"},
	{(uint32_t)vcsPla4, "vcsPla4"},
	{(uint32_t)vcsPlp4, "vcsPlp4"},
	{(uint32_t)vcsPla4Ex, "vcsPla4Ex"},
	{(uint32_t)vcsPlp4Ex, "vcsPlp4Ex"},
	{(uint32_t)vcsJmpToRam3, "vcsJmpToRam3"},
	{(uint32_t)vcsWaitForAddress, "vcsWaitForAddress"},
	{(uint32_t)vcsInjectDmaData, "vcsInjectDmaData"},
	{(uint32_t)vcsSnoopRead, "vcsSnoopRead"},
	{(uint32_t)vcsPokeRomByte, "vcsPokeRomByte"},
	{(uint32_t)vcsSetNextAddress, "vcsSetNextAddress"},
};

int launch_elf_file(const char *filename, uint32_t buffer_size, uint8_t *buffer)
{
	uint32_t mainArgs[MP_COUNT] =
		{
			0,				 // MP_SYSTEM_TYPE (TBD below)		0
			SystemCoreClock, // MP_CLOCK_HZ			1
			FF_MULTI_CART,	 // MP_FEARTURE_FLAGS		2
		};

	int usesVcsWrite3;
	bool supports2600;
	bool supports7800;
	uint32_t pMainAddress;
	uint32_t metaCount = ((ElfHeader *)buffer)->e_shnum;
	SectionMetaEntry *meta = malloc(sizeof(SectionMetaEntry) * metaCount);
	if (!initSectionsMeta(buffer, meta, (uint32_t)CCM_RAM))
	{
		return 0;
	}
	if (!loadElf(buffer, metaCount, meta, &pMainAddress, &usesVcsWrite3, &supports2600, &supports7800))
	{
		return 0;
	}
	runPreInitFuncs(metaCount, meta);
	runInitFuncs(metaCount, meta);

	if (LockStatus != Locked2600 && supports7800)
	{
		mainArgs[MP_SYSTEM_TYPE] = Is7800Ntsc ? ST_NTSC_7800 : ST_PAL_7800;
	}
	else if (LockStatus != Locked7800 && supports2600)
	{
		switch (user_settings.tv_mode)
		{
		case TV_MODE_PAL:
			mainArgs[MP_SYSTEM_TYPE] = ST_PAL_2600;
			break;
		case TV_MODE_PAL60:
			mainArgs[MP_SYSTEM_TYPE] = ST_PAL60_2600;
			break;
		default:
		case TV_MODE_NTSC:
			mainArgs[MP_SYSTEM_TYPE] = ST_NTSC_2600;
			break;
		}
	}
	else
	{
		// TODO explain issue to user
		return;
	}

	if (mainArgs[MP_SYSTEM_TYPE] == ST_PAL_2600 || mainArgs[MP_SYSTEM_TYPE] == ST_PAL60_2600)
		NameAddressMap[0].address = (uint32_t)&Pal2600[0];

	// Transfer control back to ROM
	__disable_irq();
	if (usesVcsWrite3)
		vcsInitBusStuffing();
	else
		EndWaitSpinner();

	// Update lock status if needed
	if (LockStatus == Unlocked7800)
	{
		if (mainArgs[MP_SYSTEM_TYPE] == ST_NTSC_7800 || mainArgs[MP_SYSTEM_TYPE] == ST_PAL_7800)
		{
			// Lock into 7800 mode
			vcsWrite5(INPTCTRL, 0x7);
			vcsNop2();
			LockStatus = Locked7800;
		}
		else
		{
			// Lock into 2600 mode
			lock2600mode();
		}
	}

	vcsNop2n(1024);

	// Run game
	((void (*)())pMainAddress)(mainArgs);
	// elf rom should have jumped to 0x1000 and put nop on bus
	exit_cartridge(0x1100, 0x1000);
	return 1;
}
