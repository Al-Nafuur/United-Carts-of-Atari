#include <string.h>

#include "cartridge_firmware.h"

#include "firmware_pal_rom.h"
#include "firmware_pal60_rom.h"
#include "firmware_ntsc_rom.h"

static unsigned char menu_ram[NUM_MENU_ITEMS_MEM]__attribute__((section(".ccmram")));	// < NUM_DIR_ITEMS * 12
static char menu_status[16]__attribute__((section(".ccmram")));
static unsigned const char *firmware_rom = firmware_ntsc_rom;

void set_menu_status_msg(const char* message) {
	strncpy(menu_status, message, 15);
}

void set_menu_status_byte(char status_byte) {
	menu_status[15] = status_byte;
}

void set_tv_mode(int tv_mode) {
	switch (tv_mode) {
		case TV_MODE_NTSC:
			firmware_rom = firmware_ntsc_rom;
			break;

		case TV_MODE_PAL:
			firmware_rom = firmware_pal_rom;
			break;

		case TV_MODE_PAL60:
			firmware_rom = firmware_pal60_rom;
			break;
	}
}

uint8_t* get_menu_ram() {
	return menu_ram;
}

// We require the menu to do a write to $1FF4 to unlock the comms area.
// This is because the 7800 bios accesses this area on console startup, and we wish to ignore these
// spurious reads until it has started the cartridge in 2600 mode.
bool comms_enabled = false;

int emulate_firmware_cartridge() {
	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	uint8_t data = 0, data_prev = 0;
	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (comms_enabled)
			{	// normal mode, once the cartridge code has done its init.
				// on a 7800, we know we are in 2600 mode now.
				if (addr == 0x1ff0){	// atari 2600 has sent a command
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					addr = data_prev;
					break;
				}
				if(addr == CART_CMD_START_CART){
					break;
				}
				if (addr > 0x171f && addr < CART_STATUS_BYTES)
					DATA_OUT = ((uint16_t)menu_ram[addr - 0x1720]);
				else if ((addr & 0x1ff0) == CART_STATUS_BYTES)
					DATA_OUT = ((uint16_t)menu_status[addr&0xF]);
				else
					DATA_OUT = ((uint16_t)firmware_rom[addr&0xFFF]);
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
			else
			{	// prior to an access to $1FF4, we might be running on a 7800 with the CPU at
				// ~1.8MHz so we've got less time than usual - keep this short.
				DATA_OUT = ((uint16_t)firmware_rom[addr&0xFFF]);
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN

				if (addr == 0x1FF4)
					comms_enabled = true;
			}
		}
	}

	__enable_irq();
	return addr;
}

bool reboot_into_cartridge() {
	set_menu_status_byte(1);

	return emulate_firmware_cartridge() == CART_CMD_START_CART;
}
