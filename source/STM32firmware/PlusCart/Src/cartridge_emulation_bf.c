
#include <stdlib.h>
#include <stdbool.h>
#include "cartridge_emulation.h"
#include "cartridge_setup.h"
#include "cartridge_emulation_bf.h"
#include "cartridge_firmware.h"

#define STARTUP_BANK_BF 1
#define STARTUP_BANK_BFSC 15

void emulate_bfsc_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d) {

	cartridge_layout * layout = (cartridge_layout *) malloc( sizeof(  cartridge_layout ));
    uint8_t* ram = buffer;

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d, base_type_BFSC)) return;

    uint8_t *bank = layout->banks[STARTUP_BANK_BFSC];
	bool joy_status = false;

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

        if (addr & 0x1000){
            uint16_t address = addr & 0x0fff;

            if (address < 0x80) {
                while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
    			data = data_prev;

                ram[address] = (uint8_t) data;
            } else {
                if (address >= 0x0f80 && address <= 0x0fbf) bank = layout->banks[address - 0x0f80];

                data = (address < 0x0100) ? ram[address & 0x7f] : bank[address];

                DATA_OUT = ((uint16_t)data);
    			SET_DATA_MODE_OUT
    			// wait for address bus to change
    			while (ADDR_IN == addr) ;
    			SET_DATA_MODE_IN
            }

        }else{
            if(addr == SWCHB){
        		while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
        		if( !(data_prev & 0x1) && joy_status)
        			break;
            }else if(addr == SWCHA){
        		while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
        		joy_status = !(data_prev & 0x80);
            }
        }

    }
	exit_cartridge(addr, addr_prev);

	free(layout);
}

void emulate_bf_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d ) {
	cartridge_layout * layout = (cartridge_layout *) malloc( sizeof(  cartridge_layout ));

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d, base_type_BF)) return;

    uint8_t *bank = layout->banks[STARTUP_BANK_BF];
	bool joy_status = false;

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

        if (addr & 0x1000){
            uint16_t address = addr & 0x0fff;

            if (address >= 0x0f80 && address <= 0x0fbf) bank = layout->banks[address - 0x0f80];

            DATA_OUT = ((uint16_t)bank[address]);
            SET_DATA_MODE_OUT
            // wait for address bus to change
            while (ADDR_IN == addr) ;
            SET_DATA_MODE_IN
        }else{
            if(addr == SWCHB){
        		while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
        		if( !(data_prev & 0x1) && joy_status)
        			break;
            }else if(addr == SWCHA){
        		while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
        		joy_status = !(data_prev & 0x80);
            }
        }
    }
	exit_cartridge(addr, addr_prev);

	free(layout);
}
