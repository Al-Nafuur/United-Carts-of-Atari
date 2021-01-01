#ifndef GLOBAL_H
#define GLOBAL_H

#include <stdint.h>
#include "stm32f4xx_hal.h"

#define VERSION                   "0.16.5 DEV"
#define PLUSSTORE_API_HOST        "pluscart.firmaplus.de"

#define CHARS_PER_LINE					32
#define STATUS_MESSAGE_LENGTH           256

#define NUM_MENU_ITEMS			      	1024

#define MENU_TEXT_GO_BACK                   "(Go Back)"
#define MENU_TEXT_DELETE_CHAR               "Delete Character"
#define MENU_TEXT_OFFLINE_ROMS              "Offline ROMs"
#define MENU_TEXT_DETECT_OFFLINE_ROMS       "Detect Offline ROMs"
#define MENU_TEXT_DELETE_OFFLINE_ROMS       "Erase Offline ROMs"
#define MENU_TEXT_SETUP 	                "Setup"
#define MENU_TEXT_WIFI_SETUP 	            "WiFi Setup"
#define MENU_TEXT_WPS_CONNECT               "WiFi WPS Connect"
#define MENU_TEXT_WIFI_MANAGER               "Start WiFi Manager Portal"
#define MENU_TEXT_WIFI_RECONNECT            "WiFi Retry"
#define MENU_TEXT_TV_MODE_SETUP             "TV Mode"
#define MENU_TEXT_TV_MODE_PAL               "  PAL"
#define MENU_TEXT_TV_MODE_PAL60             "  PAL 60 Hz"
#define MENU_TEXT_TV_MODE_NTSC              "  NTSC"
#define MENU_TEXT_FONT_SETUP                "Font Style"
#define MENU_TEXT_FONT_TJZ                  "  Small Caps"
#define MENU_TEXT_FONT_TRICHOTOMIC12        "  Trichotomic-12"
#define MENU_TEXT_FONT_CAPTAIN_MORGAN_SPICE	"  Captain Morgan Spice"
#define MENU_TEXT_FONT_GLACIER_BELLE        "  Glacier Belle"

#define MENU_TEXT_SPACING_SETUP				"Line Spacing"
#define MENU_TEXT_SPACING_DENSE             "  Dense"
#define MENU_TEXT_SPACING_MEDIUM            "  Regular"
#define MENU_TEXT_SPACING_SPARSE      		"  Sparse"

#define MENU_TEXT_PRIVATE_KEY               "Private Key"
#define MENU_TEXT_FIRMWARE_UPDATE           "** Update Firmware **"
#define MENU_TEXT_OFFLINE_ROM_UPDATE        "Download Offline ROMs"
#define MENU_TEXT_PLUS_CONNECT              "PlusStore Connect"
#define MENU_TEXT_PLUS_REMOVE               "PlusStore Disconnect"
#define MENU_TEXT_ESP8266_RESTORE           "ESP8266 Factory Reset"
#define MENU_TEXT_ESP8266_UPDATE            "ESP8266 Update"

#define MENU_TEXT_SYSTEM_INFO               "System Info"
#define MENU_TEXT_SEARCH_FOR_ROM            "Search ROM"
#define MENU_TEXT_SPACE						"Space"
#define MENU_TEXT_LOWERCASE					"Lowercase"
#define MENU_TEXT_UPPERCASE					"Uppercase"
#define MENU_TEXT_SYMBOLS					"Symbols"

#define URLENCODE_MENU_TEXT_SYSTEM_INFO     "System%20Info"
#define URLENCODE_MENU_TEXT_PLUS_CONNECT    "PlusStore%20Connect"
#define URLENCODE_MENU_TEXT_SETUP 	        "Setup"

#define AUTOSTART_FILENAME_PREFIX           "Autostart."

#define PATH_SEPERATOR '/' /*CHAR_SELECTION*/

extern UART_HandleTypeDef huart1;
extern char http_request_header[];

extern uint8_t buffer[];
extern unsigned int cart_size_bytes;

enum eStatus_bytes_id {
	STATUS_StatusByteReboot,
	STATUS_CurPage,
	STATUS_MaxPage,
	STATUS_ItemsOnActPage,
	STATUS_PageType,
	STATUS_Unused1,
	STATUS_Unused2,

	STATUS_MAX
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
	Keyboard_Row,
	Menu_Action,
	Delete_Keyboard_Char,
	Offline_Cart_File,
	Offline_Sub_Menu,
	Setup_Menu,
	Leave_SubKeyboard_Menu,
};

enum cart_base_type{
	base_type_Load_Failed = -1,
	base_type_None,
	base_type_2K,
	base_type_4K,
	base_type_4KSC,
	base_type_F8,
	base_type_F6,
	base_type_F4,
	base_type_FE,
	base_type_3F,
	base_type_3E,
	base_type_E0,
	base_type_0840,
	base_type_CV,
	base_type_EF,
	base_type_F0,
	base_type_FA,
	base_type_E7,
	base_type_DPC,
	base_type_AR,
	base_type_PP,
	base_type_DF,
	base_type_DFSC,
	base_type_BF,
	base_type_BFSC,
	base_type_3EPlus,
	base_type_DPCplus,
	base_type_SB,
	base_type_UA,
	base_type_ACE
};

typedef struct {
	enum MENU_ENTRY_Type type;
	char entryname[CHARS_PER_LINE+1];
	uint32_t filesize;
	uint32_t flash_base_address;
	uint8_t font;
} MENU_ENTRY;

typedef struct {
	uint8_t tv_mode;
	uint8_t first_free_flash_sector;
	uint8_t font_style;
	uint8_t line_spacing;
} USER_SETTINGS;


extern USER_SETTINGS user_settings;
extern const uint8_t numMenuItemsPerPage[];

#endif // GLOBAL_H
