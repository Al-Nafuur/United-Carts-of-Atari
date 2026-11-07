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
#include "stm32_udid.h"
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

extern uint8_t _eccmram[]; // end of the firmware variables in CCM RAM (linker script)

// .bss may use all of CCM RAM. The menu entries are not needed while an ELF runs,
// the few hundred bytes of menu state behind them are saved and restored on exit.
#define CCM_MENU_ENTRIES_END ((uint8_t*)&menu_entries[NUM_MENU_ITEMS])
#define CCM_END (CCM_RAM + CCM_RAM_SIZE * 1024U)

// Files bigger than the RAM buffer are run from flash, like the big bank switching
// ROMs. identify_cartridge() has already loaded the first BUFFER_SIZE KB to the
// buffer, so they are flashed from there and only the rest is requested again.
static uint8_t* elf_to_flash(const char* filename, uint32_t file_size, uint8_t* buffer, MENU_ENTRY* d)
{
	// d lives in CCM RAM, which may get overwritten below
	enum MENU_ENTRY_Type type = d->type;
	if (type != Cart_File && type != SD_Cart_File)
		return (uint8_t*)(d->flash_base_address + TAR_HEADER_SIZE); // offline ROM, already in flash

	if (user_settings.first_free_flash_sector < FLASH_SECTOR_5)
		return 0;
	uint8_t* flash = (uint8_t*)(DOWNLOAD_AREA_START_ADDRESS + 128U * 1024U * (uint32_t)(user_settings.first_free_flash_sector - 5));
	if ((uint32_t)flash + file_size > FLASH_BASE + STM32F4_FLASH_SIZE * 1024U)
		return 0;

	const uint32_t buffered = BUFFER_SIZE * 1024U;
	flash_erase_storage(user_settings.first_free_flash_sector);
	flash_buffer_at(buffer, buffered, flash);

	if (type == Cart_File)
	{
#if USE_WIFI
		flash_download_at((char*)filename, file_size - buffered, buffered, flash + buffered);
#endif
	}
	else
	{
#if USE_SD_CARD
		const uint32_t chunk_max = (uint32_t)(CCM_MENU_ENTRIES_END - CCM_RAM);
		for (uint32_t done = buffered; done < file_size; )
		{
			uint32_t chunk = file_size - done > chunk_max ? chunk_max : file_size - done;
			if (sd_card_file_request(CCM_RAM, filename, done, chunk) != chunk)
				return 0;
			flash_buffer_at(CCM_RAM, chunk, flash + done);
			done += chunk;
		}
#endif
	}
	return flash;
}

// Catches truncated files and failed downloads before anything gets relocated
static bool elf_sections_valid(uint8_t* elf, uint32_t file_size)
{
	ElfHeader* header = (ElfHeader*)elf;
	if (header->e_shoff + header->e_shnum * sizeof(SectionHeader) > file_size)
		return false;

	SectionHeader* sections = (SectionHeader*)&elf[header->e_shoff];
	for (int i = 1; i < header->e_shnum; i++)
	{
		if (sections[i].sh_type != SHT_NOBITS && (sections[i].sh_offset > file_size || sections[i].sh_size > file_size - sections[i].sh_offset))
			return false;
	}
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
	uint8_t* elf = buffer;
	uint8_t* ram = 0;
	if (buffer_size > BUFFER_SIZE * 1024U)
	{
		elf = elf_to_flash(filename, buffer_size, buffer, d);
		ram = buffer;
	}
	if (!elf || !elf_sections_valid(elf, buffer_size))
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

	uint8_t ccm_menu_state[_eccmram - CCM_MENU_ENTRIES_END];
	memcpy(ccm_menu_state, CCM_MENU_ENTRIES_END, sizeof(ccm_menu_state));

	int usesBusStuffing;
	uint32_t pMainAddress;
	uint32_t metaCount = ((ElfHeader*)elf)->e_shnum;
	SectionMetaEntry* meta = malloc(sizeof(SectionMetaEntry) * metaCount);
	if (!meta || !initSectionsMeta(elf, meta, (uint32_t)CCM_RAM, (uint32_t)CCM_END, ram, BUFFER_SIZE * 1024U))
	{
		free(meta);
		exit_cartridge(0x1100, 0x1000);
		return 0;
	}
	if (!loadElf(elf, metaCount, meta, &pMainAddress, &usesBusStuffing))
	{
		free(meta);
		memcpy(CCM_MENU_ENTRIES_END, ccm_menu_state, sizeof(ccm_menu_state));
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
	memcpy(CCM_MENU_ENTRIES_END, ccm_menu_state, sizeof(ccm_menu_state));
	exit_cartridge(0x1100, 0x1000);

	return 1;
}
