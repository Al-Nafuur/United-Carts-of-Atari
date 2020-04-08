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
#define CART_CMD_PAGE_DOWN	0x10     // previous page request (page--)
#define CART_CMD_PAGE_UP	0x20     // next page request (page++)
#define CART_CMD_START_CART	0x30     // Menu ready for reboot into selected ROM

#define TV_MODE_NTSC	1
#define TV_MODE_PAL     2
#define TV_MODE_PAL60   3

void set_menu_status_msg(const char* message);

void createMenuForAtari( MENU_ENTRY * menu_entries, uint8_t page_id, int num_menu_entries, _Bool paging_required, _Bool is_connected, uint8_t * plus_store_status);

void set_menu_status_byte(uint8_t byte_id, char status_byte);

void set_tv_mode(int tv_mode);

int emulate_firmware_cartridge();

bool reboot_into_cartridge();

#endif // CARTRIDGE_FIRMWARE_H
