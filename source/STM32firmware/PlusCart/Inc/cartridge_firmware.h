#ifndef CARTRIDGE_FIRMWARE_H
#define CARTRIDGE_FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>
#include "global.h"

#include "cartridge_io.h"


#define CART_CMD_HOTSPOT	      0x1fe6
#define CART_STATUS_BYTES_START	  0x1fe7	                    // start status bytes area
#define CART_STATUS_BYTES_END	  CART_STATUS_BYTES_START + 6	// 7 bytes of status

#define CART_CMD_ROOT_DIR	0xff     // Menu waits for boot menu
#define CART_CMD_START_CART	0x30     // Menu ready for reboot into selected ROM

extern int numMenuItemsPerPage;

enum TV_MODE {
	TV_MODE_UNKNOWN,

	TV_MODE_NTSC,		TV_MODE_DEFAULT = 1,
	TV_MODE_PAL,
	TV_MODE_PAL60,

	TV_MODE_MAX

};

enum FONT_TYPE {
	FONT_TJZ,
	FONT_AD,
	FONT_MORGAN,
	FONT_GLACIER,		FONT_DEFAULT = 3,

	FONT_MAX

};

enum SPACING {
	SPACING_DENSE,
	SPACING_REGULAR,	SPACING_DEFAULT = 1,
	SPACING_SPARSE,

	SPACING_MAX
};

void set_menu_status_msg(const char* message);

void createMenuForAtari(MENU_ENTRY * menu_entries, uint8_t page_id, int num_menu_entries, bool is_connected, uint8_t * plus_store_status);

void set_menu_status_byte(enum eStatus_bytes_id byte_id, uint8_t status_byte);

bool reboot_into_cartridge();

int emulate_firmware_cartridge();

#endif // CARTRIDGE_FIRMWARE_H
