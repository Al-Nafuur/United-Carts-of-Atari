#ifndef CARTRIDGE_FIRMWARE_H
#define CARTRIDGE_FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>

#include "cartridge_io.h"

#define CART_CMD_MENU_START	0x1720
#define CART_CMD_ROOT_DIR	0xff
#define CART_CMD_START_CART	0x1ff1

#define CART_STATUS_BYTES	0x1fe0	// 16 bytes of status

#define NUM_MENU_ITEMS      	186
#define NUM_MENU_ITEMS_MEM		(NUM_MENU_ITEMS + 1  ) * 12


#define TV_MODE_NTSC	1
#define TV_MODE_PAL     2
#define TV_MODE_PAL60   3

void set_menu_status_msg(const char* message);

void set_menu_status_byte(char status_byte);

void set_tv_mode(int tv_mode);

uint8_t* get_menu_ram();

int emulate_firmware_cartridge();

bool reboot_into_cartridge();

#endif // CARTRIDGE_FIRMWARE_H
