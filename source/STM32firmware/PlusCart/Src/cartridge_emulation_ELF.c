#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

// global.h (CMSIS) before vcsLib.h: RESP1 would clash with SDIO_TypeDef.
// vcsLib.h before cartridge_emulation.h/cartridge_io.h: they only define SWCHA/SWCHB if not yet defined.
#include "global.h"
#include "main.h"
#if USE_WIFI
#include "esp8266.h"
#endif
#if USE_SD_CARD
#include "fatfs.h"
#endif
#include "flash.h"
#include "vcsLib.h"
#include "cartridge_emulation.h"
#include "cartridge_emulation_ELF.h"
#include "cartridge_firmware.h"

#define NTSC_CLOCK 1193182UL
#define PAL_CLOCK 1182298UL

// Legacy function - forward declared for backward compatibility with existing ELF binaries
uint8_t vcsRead4(uint16_t address);

NameAddressMapEntry NameAddressMap[] = {
	// Low level bus access - handy for distributing prototype banking schemes without updating firmware
	{(uint32_t)&ADDR_IDR, "ADDR_IDR" },
	{(uint32_t)&DATA_IDR, "DATA_IDR" },
	{(uint32_t)&DATA_ODR, "DATA_ODR" },
	{(uint32_t)&DATA_MODER, "DATA_MODER" },
	// Used by GCC/CRT
	{(uint32_t)memset, "memset" },
	{(uint32_t)memcpy, "memcpy" },
	// Strong-ARM framework
	{(uint32_t)&ReverseByte[0], "ReverseByte" },
	{(uint32_t)vcsLdaForBusStuff2, "vcsLdaForBusStuff2" },
	{(uint32_t)vcsLdxForBusStuff2, "vcsLdxForBusStuff2" },
	{(uint32_t)vcsLdyForBusStuff2, "vcsLdyForBusStuff2" },
	{(uint32_t)vcsWrite3, "vcsWrite3" },
	{(uint32_t)vcsWrite4, "vcsWrite4" },
	{(uint32_t)vcsJmp3, "vcsJmp3" },
	{(uint32_t)vcsNop2, "vcsNop2" },
	{(uint32_t)vcsNop2n, "vcsNop2n" },
	{(uint32_t)vcsWrite5, "vcsWrite5" },
	{(uint32_t)vcsWrite6, "vcsWrite6" },
	{(uint32_t)vcsLda2, "vcsLda2" },
	{(uint32_t)vcsLdx2, "vcsLdx2" },
	{(uint32_t)vcsLdy2, "vcsLdy2" },
	{(uint32_t)vcsSax3, "vcsSax3" },
	{(uint32_t)vcsSta3, "vcsSta3" },
	{(uint32_t)vcsStx3, "vcsStx3" },
	{(uint32_t)vcsSty3, "vcsSty3" },
	{(uint32_t)vcsSta4, "vcsSta4" },
	{(uint32_t)vcsStx4, "vcsStx4" },
	{(uint32_t)vcsSty4, "vcsSty4" },
	{(uint32_t)vcsCopyOverblankToRiotRam, "vcsCopyOverblankToRiotRam" },
	{(uint32_t)vcsStartOverblank, "vcsStartOverblank" },
	{(uint32_t)vcsEndOverblank, "vcsEndOverblank" },
	{(uint32_t)vcsRead4, "vcsRead4" }, // Legacy function to avoid breaking existing ELF bins.
    {(uint32_t)vcsRead6, "vcsRead6" },
	{(uint32_t)randint, "randint" },
	{(uint32_t)vcsTxs2, "vcsTxs2" },
	{(uint32_t)vcsJsr6, "vcsJsr6" },
	{(uint32_t)vcsPha3, "vcsPha3" },
	{(uint32_t)vcsPhp3, "vcsPhp3" },
	{(uint32_t)vcsPla4, "vcsPla4" },
	{(uint32_t)vcsPlp4, "vcsPlp4" },
	{(uint32_t)vcsPla4Ex, "vcsPla4Ex" },
	{(uint32_t)vcsPlp4Ex, "vcsPlp4Ex" },
	{(uint32_t)vcsJmpToRam3, "vcsJmpToRam3" },
	{(uint32_t)vcsWaitForAddress, "vcsWaitForAddress" },
	{(uint32_t)injectDmaData, "injectDmaData" },
	// Non volatile storage
	{(uint32_t)vcsInitNvStore, "vcsInitNvStore" },
	{(uint32_t)vcsWriteNvChunk, "vcsWriteNvChunk" },
	{(uint32_t)vcsProcessNvStoreEvents, "vcsProcessNvStoreEvents" },
	{(uint32_t)vcsIsNvBusy, "vcsIsNvBusy" },
};

const uint32_t NameAddressMapCount = sizeof(NameAddressMap) / sizeof(NameAddressMapEntry);

extern MENU_ENTRY menu_entries[NUM_MENU_ITEMS];

// The menu entries in CCM RAM are not needed while an ELF runs, so .bss and the
// rest of files bigger than the RAM buffer go there.
#define ELF_CCM_END ((uint8_t*)&menu_entries[NUM_MENU_ITEMS])

static uint32_t elf_file_request(uint8_t* dst, const char* filename, enum MENU_ENTRY_Type type,
		uint32_t flash_base_address, uint32_t start, uint32_t length)
{
	if (type == Cart_File)
	{
#if USE_WIFI
		return esp8266_PlusStore_API_file_request(dst, (char*)filename, start, length);
#endif
	}
	else if (type == SD_Cart_File)
	{
#if USE_SD_CARD
		return sd_card_file_request(dst, filename, start, length);
#endif
	}
	else
		return flash_file_request(dst, flash_base_address, start, length);

	return 0;
}

// identify_cartridge() loads only the first BUFFER_SIZE KB of a file. All loadable
// sections have to be in there, everything behind them (relocations, symbols,
// section headers) is loaded to CCM RAM behind .bss.
static bool load_elf_tail(const char* filename, uint32_t file_size, uint8_t* buffer, MENU_ENTRY* d)
{
	if (file_size <= BUFFER_SIZE * 1024U)
	{
		elfSetTail(UINT32_MAX, 0);
		return true;
	}

	// d lives in CCM RAM, which gets overwritten below
	enum MENU_ENTRY_Type type = d->type;
	uint32_t flash_base_address = d->flash_base_address;

	ElfHeader* header = (ElfHeader*)buffer;
	uint32_t headers_size = (uint32_t)header->e_shnum * sizeof(SectionHeader);
	SectionHeader* sections = (SectionHeader*)(ELF_CCM_END - ((headers_size + 3) & ~3U));
	if (elf_file_request((uint8_t*)sections, filename, type, flash_base_address, header->e_shoff, headers_size) != headers_size)
		return false;

	uint32_t split = 0, bss_size = 0;
	for (int i = 1; i < header->e_shnum; i++)
	{
		if (sections[i].sh_type == SHT_NOBITS)
			bss_size += (sections[i].sh_size + 3) & ~3U;
		else if ((sections[i].sh_flags & SHF_ALLOC) && sections[i].sh_offset + sections[i].sh_size > split)
			split = sections[i].sh_offset + sections[i].sh_size;
	}
	split &= ~3U; // keeps the tail word aligned

	uint8_t* tail = CCM_RAM + bss_size;
	uint32_t tail_size = file_size - split;
	if (split > BUFFER_SIZE * 1024U || tail + tail_size > ELF_CCM_END)
		return false;

	if (elf_file_request(tail, filename, type, flash_base_address, split, tail_size) != tail_size)
		return false;

	elfSetTail(split, tail);
	return true;
}

int launch_elf_file(const char* filename, uint32_t buffer_size, uint8_t* buffer, MENU_ENTRY* d)
{
	uint32_t mainArgs[MP_COUNT] =
	{
		0, // MP_SYSTEM_TYPE (TBD below)		0
		SystemCoreClock, // MP_CLOCK_HZ			1
		FF_MULTI_CART, // MP_FEARTURE_FLAGS		2
	};

	// Still in the menu, the 6502 waits until control is transferred to the ROM
	if (!load_elf_tail(filename, buffer_size, buffer, d))
		return 0;

	// Transfer control back to ROM
	__disable_irq();
	vcsLibInit();

	switch(user_settings.tv_mode)
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

	int usesBusStuffing;
	uint32_t pMainAddress;
	uint32_t metaCount = ((ElfHeader*)buffer)->e_shnum;
	SectionMetaEntry* meta = malloc(sizeof(SectionMetaEntry) * metaCount);
	if (!initSectionsMeta(buffer, meta, (uint32_t)CCM_RAM))
	{
		free(meta);
		exit_cartridge(0x1100, 0x1000);
		return 0;
	}
	if (!loadElf(buffer, metaCount, meta, &pMainAddress, &usesBusStuffing))
	{
		free(meta);
		exit_cartridge(0x1100, 0x1000);
		return 0;
	}

	runPreInitFuncs(metaCount, meta);
	runInitFuncs(metaCount, meta);
	free(meta); // not needed while the game runs

	if(usesBusStuffing)
		vcsInitBusStuffing();

	vcsEndOverblank();
	vcsNop2n(1024);

	// Run game
	((void (*)())pMainAddress)(mainArgs);

	// elf rom should have jumped to 0x1000 and put nop on bus
	exit_cartridge(0x1100, 0x1000);

	return 1;
}
