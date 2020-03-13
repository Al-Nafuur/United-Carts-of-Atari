#include <stdbool.h>
#include <string.h>

#include "global.h"
#include "esp8266.h"
#include "flash.h"
#include "cartridge_emulation_bf.h"

#include "cartridge_firmware.h"

#define BUFFER_SIZE_KB 96
#define CCM_SIZE_KB 64

#define RAM_BANKS ((BUFFER_SIZE_KB / 4) - 1)
#define CCM_BANKS (CCM_SIZE_KB / 4)
#define FLASH_BANKS (64 - RAM_BANKS - CCM_BANKS)

#define AVAILABLE_RAM_BASE (RAM_BANKS * 4096)

#define CCM_RAM ((uint8_t*)0x10000000)
#define CCM_SIZE (CCM_SIZE_KB * 1024)

#define CCM_IMAGE_OFFSET (RAM_BANKS * 4096)

#define FLASH_IMAGE_SIZE (FLASH_BANKS * 4096)
#define FLASH_IMAGE_OFFSET ((RAM_BANKS + CCM_BANKS) * 4096)

#define STARTUP_BANK_BF 1
#define STARTUP_BANK_BFSC 15

typedef struct {
    uint8_t* banks[64];
} cartridge_layout;

static bool setup_cartridge_image(const char* filename, uint32_t image_size, uint8_t* buffer, cartridge_layout* layout, MENU_ENTRY *d) {
    if (image_size != 256*1024) return false;

    uint32_t flash_part_address, bytes_read;
	if(d->type == Cart_File ){
	    flash_part_address = (0x08020000 + 128 * 1024 * ( user_settings.first_free_flash_sector - 5));
		esp8266_PlusStore_API_connect();
		esp8266_PlusStore_API_prepare_request_header((char *)filename, TRUE, FALSE );

	    strcat(http_request_header, (char *)"     0-  4095\r\n\r\n");
		__disable_irq();
		HAL_FLASH_Unlock();
		do_flash_update(FLASH_IMAGE_SIZE, (uint8_t *)http_request_header, flash_part_address, FLASH_IMAGE_OFFSET );
	}else{
		flash_part_address = d->flash_base_address + FLASH_IMAGE_OFFSET;
	}

    if(d->type == Cart_File )
		bytes_read = esp8266_PlusStore_API_file_request( CCM_RAM, (char*) filename, CCM_IMAGE_OFFSET, CCM_SIZE );
	else
		bytes_read = flash_file_request( CCM_RAM, d->flash_base_address, CCM_IMAGE_OFFSET, CCM_SIZE );

    if (bytes_read != CCM_SIZE) goto fail_close;

    for (uint8_t i = 0; i < RAM_BANKS; i++) layout->banks[i] = buffer + i * 4096;
    for (uint8_t i = 0; i < CCM_BANKS; i++) layout->banks[RAM_BANKS + i] = CCM_RAM + i * 4096;
    for (uint8_t i = 0; i < FLASH_BANKS; i++) layout->banks[RAM_BANKS + CCM_BANKS + i] = (uint8_t *)(flash_part_address + i * 4096);

	esp8266_PlusStore_API_close_connection();
 	return true;

	fail_close:

	esp8266_PlusStore_API_close_connection();
	return false;
}

void emulate_bfsc_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d) {
    uint8_t *ram_base = buffer + AVAILABLE_RAM_BASE;

    cartridge_layout* layout = (void*)ram_base;
    ram_base += sizeof(cartridge_layout);

    uint8_t* ram = ram_base;

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d)) return;

    uint8_t *bank = layout->banks[STARTUP_BANK_BFSC];

    if (!reboot_into_cartridge()) return;
    __disable_irq();

    uint16_t addr, addr_prev = 0, addr_prev2 = 0, data = 0, data_prev = 0;

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}

        if (!(addr & 0x1000)) continue;

        uint16_t address = addr & 0x0fff;

        if (address < 0x80) {
            while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			data = data_prev;

            ram[address] = data;
        } else {
            if (address >= 0x0f80 && address <= 0x0fbf) bank = layout->banks[address - 0x0f80];

            data = (address < 0x0100) ? ram[address & 0x7f] : bank[address];

            DATA_OUT = ((uint16_t)data);
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
        }
    }
}

void emulate_bf_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d ) {
    uint8_t *ram_base = buffer + AVAILABLE_RAM_BASE;
    cartridge_layout* layout = (void*)ram_base;

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d)) return;

    uint8_t *bank = layout->banks[STARTUP_BANK_BF];

    if (!reboot_into_cartridge()) return;
    __disable_irq();

    uint16_t addr, addr_prev = 0, addr_prev2 = 0;

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}

        if (!(addr & 0x1000)) continue;

        uint16_t address = addr & 0x0fff;

        if (address >= 0x0f80 && address <= 0x0fbf) bank = layout->banks[address - 0x0f80];

        DATA_OUT = ((uint16_t)bank[address]);
        SET_DATA_MODE_OUT
        // wait for address bus to change
        while (ADDR_IN == addr) ;
        SET_DATA_MODE_IN

    }
}
