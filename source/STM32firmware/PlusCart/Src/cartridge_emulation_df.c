
#include <stdlib.h>
#include "cartridge_setup.h"
#include "cartridge_emulation_df.h"
#include "cartridge_firmware.h"

#define STARTUP_BANK_BF 1
#define STARTUP_BANK_BFSC 15

void emulate_dfsc_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d ) {

	cartridge_layout * layout = (cartridge_layout *) malloc( sizeof(  cartridge_layout ));
    uint8_t* ram = buffer;

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d, base_type_DFSC)) return;

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
            if (address >= 0x0fc0 && address <= 0x0fdf) bank = layout->banks[address - 0x0fc0];

            data = (address < 0x0100) ? ram[address & 0x7f] : bank[address];

            DATA_OUT = ((uint16_t)data);
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
        }
    }
	__enable_irq();

	free(layout);
}

void emulate_df_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d ) {
	cartridge_layout * layout = (cartridge_layout *) malloc( sizeof(  cartridge_layout ));

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d, base_type_DF)) return;

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

        if (address >= 0x0fc0 && address <= 0x0fdf) bank = layout->banks[address - 0x0fc0];

        DATA_OUT = ((uint16_t)bank[address]);
        SET_DATA_MODE_OUT
        // wait for address bus to change
        while (ADDR_IN == addr) ;
        SET_DATA_MODE_IN
    }
	__enable_irq();

	free(layout);
}
