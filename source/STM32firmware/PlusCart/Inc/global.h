#ifndef GLOBAL_H
#define GLOBAL_H

#include <stdint.h>
#include "stm32f4xx_hal.h"

#define VERSION                   "0.14.2"
#define PLUSSTORE_API_HOST        "pluscart.firmaplus.de"

#define TRUE 1
#define FALSE 0

#define STATUS_MESSAGE_LENGTH           27
#define NUM_MENU_ITEMS_PER_PAGE      	12
#define NUM_MENU_ITEMS			      1024

#define MENU_TEXT_OFFLINE_ROMS              "Offline ROMs"
#define MENU_TEXT_DETECT_OFFLINE_ROMS       "Detect offline ROMs"
#define MENU_TEXT_DELETE_OFFLINE_ROMS       "Erase offline ROMs"
#define MENU_TEXT_SETUP 	                "Setup"
#define MENU_TEXT_WIFI_SETUP 	            "WiFi Setup"
#define MENU_TEXT_WPS_CONNECT               "WiFi WPS Connect"
#define MENU_TEXT_WIFI_MANGER               "start WiFi Manager Portal"
#define MENU_TEXT_WIFI_RECONNECT            "WiFi retry"
#define MENU_TEXT_TV_MODE_SETUP             "Set TV Mode"
#define MENU_TEXT_TV_MODE_PAL               "PAL"
#define MENU_TEXT_TV_MODE_PAL60             "PAL 60Hz"
#define MENU_TEXT_TV_MODE_NTSC              "NTSC"
#define MENU_TEXT_PRIVATE_KEY               "Private Key"
#define MENU_TEXT_FIRMWARE_UPDATE           "** Update firmware **"
#define MENU_TEXT_OFFLINE_ROM_UPDATE        "Download offline ROMs"
#define MENU_TEXT_PLUS_CONNECT              "PlusStore connect"
#define MENU_TEXT_PLUS_REMOVE               "PlusStore disconnect"
#define MENU_TEXT_ESP8266_RESTORE           "ESP8266 Factory Reset"

#define URLENCODE_MENU_TEXT_PLUS_CONNECT            "PlusStore%20connect"
#define URLENCODE_MENU_TEXT_SETUP 	                "Setup"


extern UART_HandleTypeDef huart1;
extern char http_request_header[];

extern uint8_t buffer[];
extern unsigned int cart_size_bytes;

enum eStatus_bytes_id {
	StatusByteReboot,
	CurPage,
	MaxPage,
	ItemsOnActPage,
	PageType
};

enum eStatus_bytes_PageTypes {
	Directory,
	Menu,
	Keyboard
};

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
