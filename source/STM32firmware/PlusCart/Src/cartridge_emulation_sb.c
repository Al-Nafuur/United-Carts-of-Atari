
#include <stdlib.h>
#include "cartridge_setup.h"
#include "cartridge_emulation_sb.h"
#include "cartridge_firmware.h"

void emulate_SB_cartridge( const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d  )
{
	cartridge_layout * layout = (cartridge_layout *) malloc( sizeof(  cartridge_layout ));

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d, base_type_SB)) return;

    uint8_t banks = ( image_size / 4096 ) - 1;
    uint8_t *bank = layout->banks[banks];

	uint16_t addr, addr_prev = 0;

	if (!reboot_into_cartridge()) return;
	__disable_irq();	// Disable interrupts

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			DATA_OUT = ((uint16_t)bank[addr & 0xFFF]);
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}else if (addr & 0x0800 ){
			bank = layout->banks[addr & banks];
			// wait for address bus to change
			while (ADDR_IN == addr) ;
	    }
	}
	__enable_irq();

	free(layout);
}
