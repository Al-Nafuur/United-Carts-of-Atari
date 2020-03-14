#ifndef GLOBAL_H
#define GLOBAL_H

#include <stdint.h>
#include "stm32f4xx_hal.h"

#define VERSION                   "0.11.16"
#define PLUSSTORE_API_HOST        "pluscart.firmaplus.de"

#define TRUE 1
#define FALSE 0


extern UART_HandleTypeDef huart1;
extern char http_request_header[];

extern uint8_t buffer[];
extern unsigned int cart_size_bytes;

enum MENU_ENTRY_Type {
	Root_Menu = -1,
	Leave_Menu,
	Sub_Menu,
	Cart_File,
	Input_Field,
	Keyboard_Char,
	Menu_Action,
	Delete_Keyboard_Char,
	Offline_Cart_File,
	Offline_Sub_Menu,
	Setup_Menu
};

typedef struct {
	enum MENU_ENTRY_Type type;
	char entryname[33];
	uint32_t filesize;
	uint32_t flash_base_address;
} MENU_ENTRY;

typedef struct {
	uint8_t tv_mode;
	uint8_t first_free_flash_sector;
	char secret_key[10];
} USER_SETTINGS;


extern USER_SETTINGS user_settings;

#endif // GLOBAL_H
