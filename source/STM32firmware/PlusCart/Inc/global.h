#ifndef GLOBAL_H
#define GLOBAL_H

#include <stdint.h>
#include "stm32f4xx_hal.h"

#define VERSION                   "0.10.1"
#define PLUSSTORE_API_HOST        "pluscart.firmaplus.de"

extern UART_HandleTypeDef huart1;
extern uint8_t c;
extern char http_request_header[];

extern uint8_t buffer[];
extern unsigned int cart_size_bytes;
extern uint8_t tv_mode;

enum MENU_ENTRY_Type {
	Root_Menu = -1,
	Leave_Menu,
	Sub_Menu,
	Cart_File,
	Input_Field,
	Keyboard_Char,
	Menu_Action,
	Delete_Keyboard_Char,
	Offline_cart_File
};

typedef struct {
	enum MENU_ENTRY_Type type;
	char entryname[33];
	uint32_t filesize;
} MENU_ENTRY;


#endif // GLOBAL_H
