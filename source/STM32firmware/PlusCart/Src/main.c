/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * File            : main.c
  * Brief           : PlusCart(+) Firmware
  * Author          : Wolfgang Stubig <w.stubig@firmaplus.de>
  * Website         : https://gitlab.com/firmaplus/atari-2600-pluscart
  ******************************************************************************
  * (c) 2019 Wolfgang Stubig (Al_Nafuur)
  * based on: UnoCart2600 by Robin Edwards (ElectroTrains)
  *           https://github.com/robinhedwards/UnoCart-2600
  *           and
  *           UnoCart2600 fork by Christian Speckner (DirtyHairy)
  *           https://github.com/DirtyHairy/UnoCart-2600
  ******************************************************************************
  * This program is free software: you can redistribute it and/or modify
  * it under the terms of the GNU General Public License as published by
  * the Free Software Foundation, either version 3 of the License, or
  * (at your option) any later version.
  *
  * This program is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  * GNU General Public License for more details.
  *
  * You should have received a copy of the GNU General Public License
  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#include "main.h"
#include "font.h"
#include "esp8266.h"
#include "stm32_udid.h"
#include "flash.h"
#include "cartridge_io.h"
#include "cartridge_firmware.h"
#include "cartridge_emulation_ar.h"
#include "cartridge_detection.h"
#include "cartridge_emulation.h"
#include "cartridge_emulation_df.h"
#include "cartridge_emulation_bf.h"
#include "cartridge_emulation_sb.h"
#include "cartridge_emulation_dpcp.h"


void truncate_curPath(uint8_t count);

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

typedef struct {
	enum cart_base_type base_type;
	bool withSuperChip;
	bool withPlusFunctions;
	uint32_t flash_part_address;
} CART_TYPE;

typedef struct {
	const char *ext;
	CART_TYPE cart_type;
} EXT_TO_CART_TYPE_MAP;

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

const EXT_TO_CART_TYPE_MAP ext_to_cart_type_map[]__attribute__((section(".flash01"))) = {
	{"ROM",  { base_type_None, false, false }},
	{"BIN",  { base_type_None, false, false }},
	{"A26",  { base_type_None, false, false }},
	{"2K",   { base_type_2K, false, false }},
	{"4K",   { base_type_4K, false, false }},
	{"4KS",  { base_type_4K, true, false }},
	{"F8",   { base_type_F8, false, false }},
	{"F6",   { base_type_F6, false, false }},
	{"F4",   { base_type_F4, false, false }},
	{"F8S",  { base_type_F8, true, false }},
	{"F6S",  { base_type_F6, true, false }},
	{"F4S",  { base_type_F4, true, false }},
	{"FE",   { base_type_FE, false, false }},
	{"3F",   { base_type_3F, false, false }},
	{"3E",   { base_type_3E, false, false }},
	{"E0",   { base_type_E0, false, false }},
	{"084",  { base_type_0840, false, false }},
	{"CV",   { base_type_CV, false, false }},
	{"EF",   { base_type_EF, false, false }},
	{"EFS",  { base_type_EF, true, false }},
	{"F0",   { base_type_F0, false, false }},
	{"FA",   { base_type_FA, false, false }},
	{"E7",   { base_type_E7, false, false }},
	{"DPC",  { base_type_DPC, false, false }},
	{"AR",   { base_type_AR, false, false }},
	{"BF",   { base_type_BF, false, false }},
	{"BFS",  { base_type_BFSC, false, false }},
	{"ACE",  { base_type_ACE, false, false }},
	{"WD",   { base_type_PP, false, false }},
	{"DF",   { base_type_DF, false, false }},
	{"DFS",  { base_type_DFSC, false, false }},
	{"3EP",  { base_type_3EPlus, false, false }},
	{"DPCP", { base_type_DPCplus, false, false }},
	{"SB",   { base_type_SB, false, false }},
	{"UA",   { base_type_UA, false, false }},

	{0,{0,0,0}}
};

static const char status_message[][28]__attribute__((section(".flash01"))) = {
		"PlusCart(+) by W.Stubig"          ,
		"PlusCart(+) Ver. " VERSION        ,
		"PlusCart(+)"                      ,
		"Select WiFi Network"              ,
		"No WiFi"                          ,
		"WiFi connected"                   ,
		"Request timeout"                  ,
		"Enter WiFi Password"              ,
		"Enter email or username"          ,
		"Connected, email sent"            ,
		"User created, email sent"         ,
		"PlusStore connect failed"         ,
		"Disconnected from PlusStore"      ,
		"Enter Secret-Key"                 ,
		"Secret-Key saved"                 ,
		"Offline ROMs erased"              ,
		"ROM file too big!"                ,
		"ACE is not supported"             ,
		"Unknown/invalid ROM"              ,
		"Done"                             ,
		"Failed"                           ,
		"Firmware download failed"         ,
		"Offline ROMs detected"            ,
		"No offline ROMs detected"         ,
		"DPC+ is not supported"            ,
		"Emulation exited"				   ,
		"ROM Download Failed"              ,

		"Setup",
		"Select TV Mode",
		"Select Font",
		"Select Line Spacing",
		"System Info",
		MENU_TEXT_SEARCH_FOR_ROM,
		"Enter search details",
		"Search results"
};

const uint8_t numMenuItemsPerPage[] = {
		// ref: SPACING enum
		14,									// dense
		12,									// medium
		10									// sparse
};

//
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart1;


/* USER CODE BEGIN PV */
int num_menu_entries = 0;
char http_request_header[512];//__attribute__ ((section (".noinit")));

uint8_t buffer[BUFFER_SIZE * 1024] __attribute__((section(".buffer")));
unsigned int cart_size_bytes;

USER_SETTINGS user_settings;

char curPath[256];
char input_field[STATUS_MESSAGE_LENGTH];

enum inputMode {
	MODE_SHOW_INSTRUCTION,
	MODE_SHOW_INPUT,
	MODE_SHOW_PATH,
};

enum inputMode inputActive = MODE_SHOW_PATH;




uint8_t plus_store_status[1];

MENU_ENTRY menu_entries[NUM_MENU_ITEMS] __attribute__((section(".ccmram")));


/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void);

/* USER CODE BEGIN PFP */
enum e_status_message buildMenuFromPath( MENU_ENTRY * )__attribute__((section(".flash0"))) ;
void append_entry_to_path(MENU_ENTRY *);



/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */




/*************************************************************************
 * Menu Handling
 *************************************************************************/

char *get_filename_ext(char *filename) {
	char *dot = strrchr(filename, '.');
	if(!dot || dot == filename) return "";
	return (dot + 1);
}

void make_menu_entry( MENU_ENTRY **dst, const char *name, int type){
	(*dst)->type = type;
	strcpy((*dst)->entryname, name);
	(*dst)->filesize = 0U;
	(*dst)->font = user_settings.font_style;
	(*dst)++;
	num_menu_entries++;
}

void make_menu_entry_font( MENU_ENTRY **dst, char *name, int type, uint8_t font) {
	(*dst)->type = type;
	strcpy((*dst)->entryname, name);
	(*dst)->filesize = 0U;
	(*dst)->font = font;
	(*dst)++;
	num_menu_entries++;
}




const char *keyboardUppercase[]__attribute__((section(".flash0#"))) = {
	" 1  2  3  4  5  6  7  8  9  0",
	"  Q  W  E  R  T  Y  U  I  O  P",
	"   A  S  D  F  G  H  J  K  L",
	"    Z  X  C  V  B  N  M",
	0
};

const char *keyboardLowercase[]__attribute__((section(".flash0#"))) = {
	" 1  2  3  4  5  6  7  8  9  0",
	"  q  w  e  r  t  y  u  i  o  p",
	"   a  s  d  f  g  h  j  k  l",
	"    z  x  c  v  b  n  m",
	0
};

const char *keyboardSymbols[]__attribute__((section(".flash0#"))) = {
	" " MENU_TEXT_SPACE "   ( )  { }  [ ]  < >",
	"  !  ?  .  ,  :  ;  \"  '  `",
	"   @  ^  |  \\  ~  #  $  %  &",
	"    +  -  *  /  =  _",
	0
};


enum keyboardType {
	KEYBOARD_UPPERCASE,
	KEYBOARD_LOWERCASE,
	KEYBOARD_SYMBOLS,
	KEYBOARD_NONE,
};

static const char **keyboards[]__attribute__((section(".flash0#"))) = {
	keyboardUppercase,
	keyboardLowercase,
	keyboardSymbols,
	0
};


enum keyboardType lastKb = KEYBOARD_UPPERCASE;


void make_keyboardFromLine(MENU_ENTRY **dst, char *line) {

	make_menu_entry(dst, MENU_TEXT_GO_BACK, Leave_SubKeyboard_Menu);
	char item[33];
	while (*line) {
		char *entry = item;
		while (*line && *line == ' ')
			line++;
		while (*line && *line != ' ')
			*entry++ = *line++;
		*entry = 0;
		if (*item)
			make_menu_entry(dst, item, Keyboard_Char);
	}
}


void make_keyboard(MENU_ENTRY **dst, enum keyboardType selector){

	make_menu_entry(dst, MENU_TEXT_GO_BACK, Leave_Menu);

	for (const char **kbRow = keyboards[selector]; *kbRow; kbRow++)
		make_menu_entry(dst, *kbRow, Setup_Menu);

	if (selector != KEYBOARD_LOWERCASE)
		make_menu_entry(dst, MENU_TEXT_LOWERCASE, Setup_Menu);
	if (selector != KEYBOARD_UPPERCASE)
		make_menu_entry(dst, MENU_TEXT_UPPERCASE, Setup_Menu);
	if (selector != KEYBOARD_SYMBOLS)
		make_menu_entry(dst, MENU_TEXT_SYMBOLS, Setup_Menu);

	if (*input_field)
		make_menu_entry(dst, MENU_TEXT_DELETE_CHAR, Delete_Keyboard_Char);

	make_menu_entry(dst, "Enter", Menu_Action);
}


MENU_ENTRY* generateSetupMenu(MENU_ENTRY *dst) {
	make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
	make_menu_entry(&dst, MENU_TEXT_TV_MODE_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_FONT_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_SPACING_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_WIFI_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_WPS_CONNECT, Menu_Action);
	make_menu_entry(&dst, MENU_TEXT_WIFI_MANAGER, Menu_Action);
	//make_menu_entry(&dst, MENU_TEXT_PRIVATE_KEY, Input_Field);
	make_menu_entry(&dst, MENU_TEXT_ESP8266_RESTORE, Menu_Action);
	if(strcmp(esp8266_at_version, "1.7.4.0") != 0)
		make_menu_entry(&dst, MENU_TEXT_ESP8266_UPDATE, Menu_Action);

	make_menu_entry(&dst, MENU_TEXT_SYSTEM_INFO, Sub_Menu);

	if (flash_has_downloaded_roms())
		make_menu_entry(&dst, MENU_TEXT_DELETE_OFFLINE_ROMS, Menu_Action);
	else
		make_menu_entry(&dst, MENU_TEXT_DETECT_OFFLINE_ROMS, Menu_Action);

	return dst;
}

MENU_ENTRY* generateSystemInfo(MENU_ENTRY *dst) {
	make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
	make_menu_entry(&dst, "STM32 Firmware Version:", Leave_Menu);
	make_menu_entry(&dst, VERSION, Leave_Menu);
	make_menu_entry(&dst, "WiFi AT Firmware version:", Leave_Menu);
	make_menu_entry(&dst, esp8266_at_version, Leave_Menu);

	if(STM32F4_FLASH_SIZE > 512U){
    	make_menu_entry(&dst, "Flashsize 1MB", Leave_Menu);
	}else{
    	make_menu_entry(&dst, "Flashsize 512K", Leave_Menu);
    }

	make_menu_entry(&dst, "PlusCart Device ID: ", Leave_Menu);
	make_menu_entry(&dst, stm32_udid, Leave_Menu);


	return dst;
}

enum e_status_message generateKeyboard(
		MENU_ENTRY **dst,
		MENU_ENTRY *d,
		enum e_status_message menuStatusMessage,
		enum e_status_message new_status) {

	// Scan for any keyboard rows, and if found then generate menu for row
	for (const char ***kb = keyboards; *kb; kb++)
		for (const char **row = *kb; *row; row++)
			if (!strcmp(*row, d->entryname)) {
				make_keyboardFromLine(dst, d->entryname);
				truncate_curPath(1);
				return menuStatusMessage;
			}

	// look for change of keyboard
	if (!strcmp(d->entryname, MENU_TEXT_LOWERCASE))
		lastKb = KEYBOARD_LOWERCASE;
	else if (!strcmp(d->entryname, MENU_TEXT_UPPERCASE))
		lastKb = KEYBOARD_UPPERCASE;
	else if (!strcmp(d->entryname, MENU_TEXT_SYMBOLS))
		lastKb = KEYBOARD_SYMBOLS;
	else {

		// initial case - use previous keyboard
		menuStatusMessage = new_status;
		strcat(curPath, "/");				// trimmed off, below
	}

	make_keyboard(dst, lastKb);
	truncate_curPath(1);
	return menuStatusMessage;
}


enum e_status_message buildMenuFromPath( MENU_ENTRY *d )  {
	int count = 0;
	bool loadStore = false;
	bool is_entry_row;
	uint8_t pos = 0, c;
	num_menu_entries = 0;
	enum e_status_message menuStatusMessage = none;

	char *menuFontNames[] = {
			// same ordering as font IDs
			MENU_TEXT_FONT_TJZ,
			MENU_TEXT_FONT_TRICHOTOMIC12,
			MENU_TEXT_FONT_CAPTAIN_MORGAN_SPICE,
			MENU_TEXT_FONT_GLACIER_BELLE
	};

	char *tvModes[] = {
			0,
			MENU_TEXT_TV_MODE_NTSC,		// -->1
			MENU_TEXT_TV_MODE_PAL,		// -->2
			MENU_TEXT_TV_MODE_PAL60,	// -->3
	};

	char *spacingModes[] = {
			MENU_TEXT_SPACING_DENSE,		// referenced by SPACING enum
			MENU_TEXT_SPACING_MEDIUM,
			MENU_TEXT_SPACING_SPARSE,
	};


	MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];
	char *mts = curPath + sizeof(MENU_TEXT_SETUP);   // does a +1 because of MENU_TEXT_SETUP trailing 0
		// and this caters for the trailing slash in the setup string (if present)

	if(strstr(curPath, MENU_TEXT_SETUP) == curPath) {

		if (!strcmp(curPath, MENU_TEXT_SETUP)){
			menuStatusMessage = STATUS_SETUP;
			dst = generateSetupMenu(dst);
			loadStore = true;
		}
		else if (strstr(mts, URLENCODE_MENU_TEXT_SYSTEM_INFO) == mts) {
			menuStatusMessage = STATUS_SETUP_SYSTEM_INFO;
			dst = generateSystemInfo(dst);
			loadStore = true;

		}
		else if (strstr(mts, MENU_TEXT_ESP8266_UPDATE) == mts) {
			esp8266_update();
			truncate_curPath(1);
			menuStatusMessage = buildMenuFromPath(d);
		}

		// Text line spacing
		else if (strstr(mts, MENU_TEXT_SPACING_SETUP) == mts) {

			if(d->type == Menu_Action){

				uint8_t new_spacing = 0;  // dense
				while ( strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + 2 + sizeof(MENU_TEXT_SPACING_SETUP)],
						&spacingModes[new_spacing][2]) != 0)
					new_spacing++;

				if(user_settings.line_spacing != new_spacing){
					user_settings.line_spacing = new_spacing;
					flash_set_eeprom_user_settings(user_settings);
				}

				truncate_curPath(1);
				menuStatusMessage = buildMenuFromPath(d);
			}

			else{

				menuStatusMessage = STATUS_SETUP_LINE_SPACING;

				make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);

				for (uint8_t spacing = 0; spacing < sizeof spacingModes / sizeof *spacingModes; spacing++) {
					char spacingLine[33];
					strcpy(spacingLine, spacingModes[spacing]);
					if (user_settings.line_spacing == spacing)
						spacingLine[0] = CHAR_SELECTION;
					make_menu_entry(&dst, spacingLine, Menu_Action);
				}
			}
		}

		// WiFi Setup
		else if (strstr(mts, MENU_TEXT_WIFI_SETUP) == mts) {

			int i = sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP);
			if (strlen(curPath) > i){

				if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect to WiFi
					// curPath is: MENU_TEXT_SETUP + "/" + MENU_TEXT_WIFI_SETUP + "/" SSID[33] + Password + "/Enter" + '\0'
					curPath[strlen(curPath) - 6 ] = '\0'; // delete "/Enter" at end of Path

					// TODO before we send them to esp8266 escape , " and \ in SSID and Password..
			        while( curPath[i] != 30 && i < ( sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP) + 31) ){
			            i++;
			        }
			        curPath[i] = 0;

			    	if(esp8266_wifi_connect( &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP)  ],
			    			&curPath[sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP) + 32])){
			        	menuStatusMessage = wifi_connected;
			    	}else{
			        	menuStatusMessage = wifi_not_connected;
			    	}
					curPath[0] = '\0';
				}

				else
					menuStatusMessage = generateKeyboard(&dst, d, menuStatusMessage, insert_password);

			}

			else {
				menuStatusMessage = select_wifi_network;
				make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
				if( esp8266_wifi_list( &dst, &num_menu_entries) == false){
		    		return esp_timeout;
		    	}
			}
		}

		else if (strstr(mts, MENU_TEXT_TV_MODE_SETUP) == mts) {

			if(d->type == Menu_Action){

				uint8_t new_tv_mode = TV_MODE_NTSC;
				while ( strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + 2 + sizeof(MENU_TEXT_TV_MODE_SETUP)],
						&tvModes[new_tv_mode][2]) != 0)
					new_tv_mode++;

				set_tv_mode(new_tv_mode);
				if(user_settings.tv_mode != new_tv_mode){
					user_settings.tv_mode = new_tv_mode;
					flash_set_eeprom_user_settings(user_settings);
				}

				truncate_curPath(1);
				menuStatusMessage = buildMenuFromPath(d);
			}

			else {

				menuStatusMessage = STATUS_SETUP_TV_MODE;

				make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);

				for (int tv = 1; tv < sizeof tvModes / sizeof *tvModes; tv++) {
					char tvLine[33];
					strcpy(tvLine, tvModes[tv]);
					if (user_settings.tv_mode == tv)
						tvLine[0] = CHAR_SELECTION;
					make_menu_entry(&dst, tvLine, Menu_Action);
				}
			}

		}

		else if (strstr(mts, MENU_TEXT_FONT_SETUP) == mts) {

			if(d->type == Menu_Action){

				uint8_t new_font_style = 0;
				while ( new_font_style < sizeof(menuFontNames)/sizeof(char *) - 1 &&
						strcmp( &curPath[sizeof(MENU_TEXT_SETUP) + 2 + sizeof(MENU_TEXT_FONT_SETUP)],
								&menuFontNames[new_font_style][2]))
					new_font_style++;

				if(user_settings.font_style != new_font_style){
					user_settings.font_style = new_font_style;
					flash_set_eeprom_user_settings(user_settings);
				}

				truncate_curPath(1);
				menuStatusMessage = buildMenuFromPath(d);
			}

			else{

				menuStatusMessage = STATUS_SETUP_FONT_STYLE;

				make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);

				uint8_t fontCount = sizeof menuFontNames / sizeof *menuFontNames;
				char fontLine[fontCount][33];
				for (uint8_t font=0; font < fontCount; font++) {
					strcpy(fontLine[font], menuFontNames[font]);
					fontLine[font][0] = user_settings.font_style == font ? CHAR_SELECTION: ' ';
					make_menu_entry_font(&dst, fontLine[font], Menu_Action, font);
				}
			}

		}

		else if (strstr(mts, MENU_TEXT_PLUS_CONNECT) == mts) {

			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect user

				if( esp8266_PlusStore_API_connect() == false)
					return esp_timeout;

				esp8266_PlusStore_API_prepare_request_header(curPath, false, true );
	        	esp8266_print(http_request_header);
	        	esp8266_skip_http_response_header();
	        	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){}

	        	switch (c) {
				case '0':
	        		menuStatusMessage = plus_connect_failed;
	        		break;
				case '1':
	        		menuStatusMessage = plus_created;
	        		break;
				default:
	        		menuStatusMessage = plus_connected;
	        		break;
	        	}


	        	esp8266_PlusStore_API_end_transmission();

	        	*curPath = 0;
			}

			else{

				menuStatusMessage = generateKeyboard(&dst, d, menuStatusMessage, plus_connect);
				//TODO:
//				switch (inputActive) {
//				case MODE_SHOW_INSTRUCTION:
//					menuStatusMessage = plus_connect;
//					inputActive = MODE_SHOW_INPUT;
//					break;
//				case MODE_SHOW_INPUT:
//					menuStatusMessage = keyboard_input;
//					break;
//				case MODE_SHOW_PATH:
//					break;
//				default:
//					break;
//				}

				//if (inputActive /*strlen(input_field)*/)
				//	menuStatusMessage = keyboard_input;
			}
		}

		else if (strstr(mts, MENU_TEXT_PLUS_REMOVE) == mts) {

			if( esp8266_PlusStore_API_connect() == false)
				return esp_timeout;

			esp8266_PlusStore_API_prepare_request_header(curPath, false, true );
        	esp8266_print(http_request_header);

            esp8266_skip_http_response_header();
        	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){}

        	menuStatusMessage = (c == '0') ? plus_connect_failed : plus_removed;

        	esp8266_PlusStore_API_end_transmission();

        	*curPath = 0;
		}

		else if (strstr(mts, MENU_TEXT_OFFLINE_ROM_UPDATE) == mts) {

			if( flash_download("&r=1", d->filesize , 0 , false ) != DOWNLOAD_AREA_START_ADDRESS)
				menuStatusMessage = download_failed;

			else {
				menuStatusMessage = done;
	        	*curPath = 0;
			}
		}

		else if (strstr(mts, MENU_TEXT_DELETE_OFFLINE_ROMS) == mts) {

			flash_erase_storage((uint8_t)FLASH_SECTOR_5);
			user_settings.first_free_flash_sector = (uint8_t) FLASH_SECTOR_5;
		    flash_set_eeprom_user_settings(user_settings);
		    menuStatusMessage = offline_roms_deleted;
        	*curPath = 0;
		}

		else if (strstr(mts, MENU_TEXT_DETECT_OFFLINE_ROMS) == mts) {

			uint32_t last_address = flash_check_offline_roms_size();
			if(last_address > DOWNLOAD_AREA_START_ADDRESS + 1024){
			    user_settings.first_free_flash_sector = (uint8_t) (((last_address - ADDR_FLASH_SECTOR_5) / 0x20000 ) + 6);
			    flash_set_eeprom_user_settings(user_settings);
			    menuStatusMessage = offline_roms_detected;
			}

			else
				menuStatusMessage = no_offline_roms_detected;

    		num_menu_entries = 0;
        	*curPath = 0;
		}

		else if (strstr(mts, MENU_TEXT_WPS_CONNECT) == mts) {

	    	menuStatusMessage = esp8266_wps_connect() ? wifi_connected : wifi_not_connected;
			*curPath = 0;
			HAL_Delay(2000);
		}

		else if (strstr(mts, MENU_TEXT_WIFI_MANAGER) == mts) {

			menuStatusMessage = done;
			esp8266_AT_WiFiManager();
	    	*curPath = 0;
		}

		else if (strstr(mts, MENU_TEXT_ESP8266_RESTORE) == mts) {

			menuStatusMessage = esp8266_reset(true) ? done : failed;
			*curPath = 0;
		}

		else if (strstr(mts, MENU_TEXT_PRIVATE_KEY) == mts) {

			if(d->type == Menu_Action) { // if actual Entry is of type Menu_Action -> Save Private key
				menuStatusMessage = private_key_saved;
	        	*curPath = 0;
			}

			else {

				if (!strcmp(mts, MENU_TEXT_PRIVATE_KEY ))
					menuStatusMessage = private_key;		//????  what have i broken that this compare would have worked

				menuStatusMessage = generateKeyboard(&dst, d, menuStatusMessage, private_key);
			}
		}
		else{
			// unknown entry must be from PlusStore API, so load from store.
			loadStore = true;
		}
	}

	else if (strstr(curPath, MENU_TEXT_OFFLINE_ROMS) == curPath) {
		make_menu_entry(&dst, "..", Leave_Menu);
		flash_file_list(&curPath[sizeof(MENU_TEXT_OFFLINE_ROMS) - 1], &dst, &num_menu_entries);
	}

	else if (strstr(curPath, MENU_TEXT_SEARCH_FOR_ROM) == curPath) {

		if(d->type == Menu_Action){
			// Send search to API
			for (char* p = curPath; (p = strchr(p, ' ')); *p++ = '+');			// ' ' --> '+'
			loadStore = true;
			menuStatusMessage = STATUS_CHOOSE_ROM;
		}
		else {

			// Temporary HACK.  We want to clear the input_field on first-run
			// Use of "inputActive" does not work... :(

			if (strstr(input_field, "Search ROM"))
				*input_field = 0;

			menuStatusMessage = generateKeyboard(&dst, d, menuStatusMessage, STATUS_SEARCH_DETAILS);
		}
	}

	else if (d->type == Menu_Action){

		if (strstr(curPath, MENU_TEXT_FIRMWARE_UPDATE) == curPath) {

			strcpy(curPath, "&u=1");

			uint32_t bytes_read = esp8266_PlusStore_API_file_request( buffer, curPath, 0, 0x4000 );
			bytes_read += esp8266_PlusStore_API_file_request( &buffer[0x4000], curPath, 0x8000, (d->filesize - 0x8000) );
			if(bytes_read == d->filesize - 0x4000 ){
				__disable_irq();
				HAL_FLASH_Unlock();
				flash_firmware_update(d->filesize);
			}else{
				menuStatusMessage = download_failed;
			}
		}

		else if (strstr(curPath, MENU_TEXT_WIFI_RECONNECT) == curPath)
			loadStore = true;

		*curPath = 0;

	}

	else {
		set_menu_status_msg(curPath);
		loadStore = true;
	}


	// Test we should load store and if connected to AP
    if(	loadStore || strlen(curPath) == 0 ){
    	if(esp8266_is_connected() == true){
			if( esp8266_PlusStore_API_connect() == false){
				return esp_timeout;
			}
			esp8266_PlusStore_API_prepare_request_header(curPath, false, false);

        	esp8266_print(http_request_header);
            uint16_t bytes_read = 0, content_length = esp8266_skip_http_response_header();
        	count = 0;
        	while(bytes_read < content_length){
        		if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) != HAL_OK){
        			break;
        		}
        		if(bytes_read < 2){
        			if(bytes_read < 1)
        				plus_store_status[bytes_read] = (uint8_t)c;

        		}else if(num_menu_entries < NUM_MENU_ITEMS){
                    if(count == 0){ // first char defines if its an entry row
                    	is_entry_row = (c >= '0' && c <= '9' ); // First char is entry.type '0' to '9'
                        if(is_entry_row){
                        	dst->type = c - 48;
                        }
                    }else if( is_entry_row ){
                    	if(count == 1){
                            dst->filesize = 0U;
                            pos = 0;
                    	}else if( count < 8 ){ // get the filesize
                   			dst->filesize = dst->filesize * 10 + (uint8_t)( c - '0' );
                    	}else if( count > 8 && count < 41 && c != '\n'){ // filename/dirname should begin at index 9
                    		dst->entryname[pos] = c;
                    		pos++;
                    	}
                    }
                    if (c == '\n'){
                    	if(is_entry_row){
                    		dst->entryname[pos] = '\0';
                    		dst->font = user_settings.font_style;
                            dst++;
                            num_menu_entries++;
                    	}
                        count = 0;
                    }else{
                        count++;
                    }
        		}
        		bytes_read++;
        	}

        	esp8266_PlusStore_API_end_transmission();
        }else if(strlen(curPath) == 0){
        	make_menu_entry(&dst, MENU_TEXT_WIFI_RECONNECT, Menu_Action);
    	}
    }

    if(strlen(curPath) == 0){
    	if(	flash_has_downloaded_roms() )
    		make_menu_entry(&dst, MENU_TEXT_OFFLINE_ROMS, Offline_Sub_Menu);

    	if(menuStatusMessage == none)
    		menuStatusMessage = STATUS_ROOT;

    	make_menu_entry(&dst, MENU_TEXT_SETUP, Setup_Menu);
	}

//    else if(strncmp(MENU_TEXT_SETUP, curPath, sizeof(MENU_TEXT_SETUP) - 1) != 0 ){
//		menuStatusMessage = paging;
//	}

    if(num_menu_entries == 0){
		make_menu_entry(&dst, "..", Leave_Menu);
    }

    return menuStatusMessage;
}


CART_TYPE identify_cartridge( MENU_ENTRY *d )
{

	CART_TYPE cart_type = { base_type_None, false, false };

	strcat(curPath, "/");
	append_entry_to_path(d);

	// Test if connected to AP
    if(d->type == Cart_File && esp8266_is_connected() == false ){
    	return cart_type;
    }

    // select type by file extension?
	char *ext = get_filename_ext(d->entryname);
	const EXT_TO_CART_TYPE_MAP *p = ext_to_cart_type_map;
	while (p->ext) {
		if (strcasecmp(ext, p->ext) == 0) {
			cart_type.base_type = p->cart_type.base_type;
			cart_type.withSuperChip = p->cart_type.withSuperChip;
			break;
		}
		p++;
	}

	// Supercharger cartridges get special treatment, since we don't load the entire
	// file into the buffer here
	if (cart_type.base_type == base_type_None && ( (d->filesize % 8448) == 0 || d->filesize == 6144))
		cart_type.base_type = base_type_AR;
	if (cart_type.base_type == base_type_AR){
		goto close;
	}


	uint32_t bytes_read, bytes_to_read = d->filesize > (BUFFER_SIZE * 1024)?(BUFFER_SIZE * 1024):d->filesize;
	uint8_t tail[16], bytes_read_tail;
	if(d->type == Cart_File ){
		bytes_read = esp8266_PlusStore_API_file_request( buffer, curPath, 0, bytes_to_read );
	}else{
		bytes_read = flash_file_request( buffer, d->flash_base_address, 0, bytes_to_read );
	}

	if( bytes_read != bytes_to_read ){
		cart_type.base_type = base_type_Load_Failed;
		goto close;
	}
	if(d->filesize >  (BUFFER_SIZE * 1024)){
		if(d->type == Cart_File ){
			bytes_read_tail = (uint8_t)esp8266_PlusStore_API_file_request( tail, curPath, (d->filesize - 16), 16 );
		}else{
			bytes_read_tail = (uint8_t)flash_file_request( tail, d->flash_base_address, (d->filesize - 16), 16 );
		}
		if( bytes_read_tail != 16 ){
			cart_type.base_type = base_type_Load_Failed;
			goto close;
		}
	}else{
		cart_type.withPlusFunctions = isProbablyPLS(d->filesize, buffer);
		cart_type.withSuperChip =  isProbablySC(d->filesize, buffer);
	}

	// disconnect here or if cart_type != CART_TYPE_NONE
	if (cart_type.base_type != base_type_None) goto close;

	// If we don't already know the type (from the file extension), then we
	// auto-detect the cart type - largely follows code in Stella's CartDetector.cpp

	if (d->filesize <= 64 * 1024 && (d->filesize % 1024) == 0 && isProbably3EPlus(d->filesize, buffer))
	{
		cart_type.base_type = base_type_3EPlus;
	}
	else if (d->filesize == 2*1024)
	{
		if (isProbablyCV(d->filesize, buffer))
			cart_type.base_type = base_type_CV;
		else
			cart_type.base_type = base_type_2K;
	}
	else if (d->filesize == 4*1024)
	{
		cart_type.base_type = base_type_4K;
	}
	else if (d->filesize == 8*1024)
	{
		// First check for *potential* F8
		int f8 = isPotentialF8(d->filesize, buffer);

		if (memcmp(buffer, buffer + 4096, 4096) == 0)
			cart_type.base_type = base_type_4K;
		else if (isProbablyE0(d->filesize, buffer))
			cart_type.base_type = base_type_E0;
		else if (isProbably3E(d->filesize, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
		else if (isProbablyUA(d->filesize, buffer))
			cart_type.base_type = base_type_UA;
		else if (isProbablyFE(d->filesize, buffer) && !f8)
			cart_type.base_type = base_type_FE;
		else if (isProbably0840(d->filesize, buffer))
			cart_type.base_type = base_type_0840;
		else
			cart_type.base_type = base_type_F8;
	}
	else if (d->filesize == 8*1024 + 3) {
		cart_type.base_type = base_type_PP;
	}
	else if(d->filesize >= 10240 && d->filesize <= 10496)
	{  // ~10K - Pitfall II
		cart_type.base_type = base_type_DPC;
	}
	else if (d->filesize == 12*1024)
	{
		cart_type.base_type = base_type_FA;
	}
	else if (d->filesize == 16*1024)
	{
		if (isProbablyE7(d->filesize, buffer))
			cart_type.base_type = base_type_E7;
		else if (isProbably3E(d->filesize, buffer))
			cart_type.base_type = base_type_3E;
		else
			cart_type.base_type = base_type_F6;
	}
	else if (d->filesize == 29*1024)
	{
		if (isProbablyDPCplus(d->filesize, buffer))
			cart_type.base_type = base_type_DPCplus;
	}
	else if (d->filesize == 32*1024)
	{
		if (isProbably3E(d->filesize, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
		else if (isProbablyDPCplus(d->filesize, buffer))
			cart_type.base_type = base_type_DPCplus;
		else
			cart_type.base_type = base_type_F4;
	}
	else if (d->filesize == 64*1024)
	{
		if (isProbably3E(d->filesize, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
		else if (isProbablyEF(d->filesize, buffer))
			cart_type.base_type = base_type_EF;
		else
			cart_type.base_type = base_type_F0;
	}
	else if (d->filesize == 128 * 1024) {
		if (isProbablyDF(tail))
			cart_type.base_type = base_type_DF;
		else if (isProbablyDFSC(tail)){
			cart_type.base_type = base_type_DFSC;
			cart_type.withSuperChip = 1;
		}else
			cart_type.base_type = base_type_SB;
	}
	else if (d->filesize == 256 * 1024)
	{
		if (isProbablyBF(tail))
			cart_type.base_type = base_type_BF;
		else if (isProbablyBFSC(tail)){
			cart_type.base_type = base_type_BFSC;
			cart_type.withSuperChip = 1;
		}else
			cart_type.base_type = base_type_SB;
	}

	close:

	if (cart_type.base_type != base_type_None)
		cart_size_bytes = d->filesize;

	return cart_type;
}




/*************************************************************************
 * Main loop/helper functions
 *************************************************************************/

void emulate_cartridge(CART_TYPE cart_type, MENU_ENTRY *d)
{
	int offset = 0;
	if (cart_type.withPlusFunctions == true ){
 		// Read path and hostname in ROM File from where NMI points to till '\0' and
		// copy to http_request_header
		offset = esp8266_PlusROM_API_connect(cart_size_bytes);
	}

	if (cart_type.base_type == base_type_2K){
		memcpy(buffer+0x800, buffer, 0x800);
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x2000, 0x0000, cart_type.withSuperChip);
	}else if (cart_type.base_type == base_type_4K )
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x2000, 0x0000, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F8)
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x1FF8, 0x1FF9, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F6)
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x1FF6, 0x1FF9, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F4)
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x1FF4, 0x1FFB, cart_type.withSuperChip );
	else if (cart_type.base_type == base_type_FE)
		emulate_FE_cartridge();
	else if (cart_type.base_type == base_type_UA)
		emulate_UA_cartridge();
	else if (cart_type.base_type == base_type_3F)
		emulate_3F_cartridge();
	else if (cart_type.base_type == base_type_3E)
		emulate_3E_cartridge(offset, cart_type.withPlusFunctions);
	else if (cart_type.base_type == base_type_E0)
		emulate_E0_cartridge();
	else if (cart_type.base_type == base_type_0840)
		emulate_0840_cartridge();
	else if (cart_type.base_type == base_type_CV)
		emulate_CV_cartridge();
	else if (cart_type.base_type == base_type_EF)
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x1FE0, 0x1FEF, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F0)
		emulate_F0_cartridge();
	else if (cart_type.base_type == base_type_FA)
		emulate_FA_cartridge(offset, cart_type.withPlusFunctions);
	else if (cart_type.base_type == base_type_E7)
		emulate_E7_cartridge();
	else if (cart_type.base_type == base_type_DPC)
		emulate_DPC_cartridge((uint32_t)cart_size_bytes);
	else if (cart_type.base_type == base_type_AR)
		emulate_ar_cartridge(curPath, cart_size_bytes, buffer, user_settings.tv_mode);
	else if (cart_type.base_type == base_type_PP)
		emulate_pp_cartridge( buffer + 8*1024);
	else if (cart_type.base_type == base_type_DF)
		emulate_df_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_DFSC)
		emulate_dfsc_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_BF)
		emulate_bf_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_BFSC)
		emulate_bfsc_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_3EPlus)
		emulate_3EPlus_cartridge(offset, cart_type.withPlusFunctions);
	else if (cart_type.base_type == base_type_DPCplus)
		emulate_DPCplus_cartridge(cart_size_bytes);
	else if (cart_type.base_type == base_type_SB)
		emulate_SB_cartridge(curPath, cart_size_bytes, buffer, d);

	if (cart_type.withPlusFunctions == true ){
		esp8266_PlusStore_API_end_transmission();
	}

}

void truncate_curPath(uint8_t count){

	for (int selector = 0; keyboards[selector]; selector++)
		for (const char **kbRow = keyboards[selector]; *kbRow; kbRow++) {
			char *kb = strstr(curPath, *kbRow);
			if (kb) {
				*(kb-1) = 0;
				return;
			}
		}

	for (uint8_t i = 0; i < count; i++) {
		unsigned int len = strlen(curPath);

		while (len && curPath[--len] != PATH_SEPERATOR);
		curPath[len] = 0;
	}
}

void system_secondary_init(void){
	if(flash_has_downloaded_roms() ){
	    MENU_ENTRY *d = &menu_entries[0];
	    MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];
		curPath[0] = '\0';
		strcat(curPath, MENU_TEXT_OFFLINE_ROMS);
		flash_file_list(&curPath[sizeof(MENU_TEXT_OFFLINE_ROMS) - 1], &dst, &num_menu_entries);

		if(strncmp(AUTOSTART_FILENAME_PREFIX, d->entryname, sizeof(AUTOSTART_FILENAME_PREFIX) - 1) == 0 ){
    		CART_TYPE cart_type = identify_cartridge(d);
            HAL_Delay(200);
            if (cart_type.base_type != base_type_None){
                emulate_cartridge(cart_type, d);
            }
		}
		num_menu_entries = 0;
		curPath[0] = '\0';
	}
	//	check user_settings properties that haven't been in user_setting since v1
	if( user_settings.line_spacing >= SPACING_MAX )
		user_settings.line_spacing = SPACING_DEFAULT;

	if( user_settings.font_style >= FONT_MAX )
		user_settings.font_style = FONT_DEFAULT;

	set_menu_status_byte(STATUS_StatusByteReboot, 0);
	generate_udid_string();

	MX_USART1_UART_Init();
	esp8266_init();
	read_esp8266_at_version();
	// set up status area
}

void append_entry_to_path(MENU_ENTRY *d){

	if(d->type == Cart_File || d->type == Sub_Menu	)
		for (char *p = d->entryname; *p; p++)
			sprintf(curPath + strlen(curPath), strchr(" =+&#%", *p) ? "%%%02X" : "%c", *p);
	else
		strcat(curPath, d->entryname);
}


/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

	uint8_t act_page = 0;
    MENU_ENTRY *d = &menu_entries[0];

  /* USER CODE END 1 */


  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();

  /* USER CODE BEGIN 2 */

  user_settings = flash_get_eeprom_user_settings();
  set_tv_mode(user_settings.tv_mode);

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  enum e_status_message menuStatusMessage = STATUS_ROOT; //, main_status = none;
  while (1){


    int ret = emulate_firmware_cartridge();

	if (ret == CART_CMD_ROOT_DIR) {
		system_secondary_init();

		d->type = Root_Menu;
		d->filesize = 0;

		*input_field = *curPath = 0;
		inputActive = MODE_SHOW_PATH;

		menuStatusMessage = buildMenuFromPath(d);
	}

	else if (ret == CART_CMD_PAGE_DOWN) {
		act_page--;
	}

	else if (ret == CART_CMD_PAGE_UP) {
		act_page++;
	}

	else {

		ret += act_page * numMenuItemsPerPage[user_settings.line_spacing];
		d = &menu_entries[ret];

		act_page = 0; // seems to fix the "blank" menus - because page # was not init'd on new menu

		if (d->type == Cart_File || d->type == Offline_Cart_File) {

			// TODO: THIS MAGIC NUMBER "12" SHOULD BE FIXED TO AN EQUATE
			// selection is a rom file
			int32_t max_romsize = (((BUFFER_SIZE + CCM_RAM_SIZE) * 1024)
					+ (12 - user_settings.first_free_flash_sector) * 128 * 1024);	//TODO: what's the 12?  linespermenu?

			if (d->filesize > max_romsize)
				menuStatusMessage /*main_status*/ = not_enough_menory;

			else {

				CART_TYPE cart_type = identify_cartridge(d);
				HAL_Delay(200);

				if (cart_type.base_type == base_type_ACE)
					menuStatusMessage = /*main_status =*/ romtype_ACE_unsupported;

				else if (cart_type.base_type == base_type_Load_Failed)
					menuStatusMessage = /*main_status = */rom_download_failed;

				else if (cart_type.base_type != base_type_None) {

					emulate_cartridge(cart_type, d);
					set_menu_status_byte(STATUS_StatusByteReboot, 0);
					menuStatusMessage = /*main_status = */exit_emulation;


					// ...?
					if (d->filesize > (BUFFER_SIZE * 1024)) { // reload menu
						truncate_curPath(1);
						menuStatusMessage = buildMenuFromPath(d);
					}
				}

				else
					menuStatusMessage = romtype_unknown;
			}

			truncate_curPath(1);

		}

		else {  // not a cart file...

			// selection is a directory or Menu_Action, or Keyboard_Char
			if (d->type == Leave_Menu) {

				if (strstr(curPath, "Search") == curPath)
					*curPath = 0;
				else
					truncate_curPath(1);

				inputActive = MODE_SHOW_PATH;
				*input_field = 0;
			}

			else if (d->type == Delete_Keyboard_Char) {

				unsigned int len = strlen(input_field);
				if (len) {
					input_field[--len] = 0;
					curPath[strlen(curPath) - 1] = 0;
				}
				menuStatusMessage = keyboard_input;

			} else {

				if ((d->type != Keyboard_Char && strlen(curPath) > 0)
						|| !strcmp(MENU_TEXT_SETUP"/"MENU_TEXT_PLUS_CONNECT, curPath)
						|| !strcmp(MENU_TEXT_SEARCH_FOR_ROM, curPath)) {
					strcat(curPath, "/");
				}

				if (!strcmp(d->entryname, MENU_TEXT_SPACE))
					strcpy(d->entryname, " ");

				append_entry_to_path(d);

				if (d->type == Keyboard_Char) {

					inputActive = MODE_SHOW_INPUT;
					//if (inputActive == MODE_SHOW_INPUT)
					strcat(input_field, d->entryname);


					// essentially "redundant" as the curPath won't be long enough anyway...

					if (strlen(input_field) > STATUS_MESSAGE_LENGTH - 1)
						for (int i = 0; i < STATUS_MESSAGE_LENGTH - 1; i++)
							input_field[i] = input_field[i + 1];

					menuStatusMessage = keyboard_input;
				}

				else {
					if (d->type == Menu_Action) {
						inputActive = MODE_SHOW_PATH;
						*input_field = 0;
					}
				}
			}
			menuStatusMessage = buildMenuFromPath(d);
		}
	}


	if (*input_field) {
		set_menu_status_msg(input_field);
		set_menu_status_byte(STATUS_PageType, (uint8_t) Keyboard);
	}

    else {

    	if (menuStatusMessage >= 0)
    		set_menu_status_msg(status_message[menuStatusMessage]);

    	if(act_page > (num_menu_entries / numMenuItemsPerPage[user_settings.line_spacing]) )
    		act_page = 0;

    	set_menu_status_byte(STATUS_PageType, (uint8_t) Directory);
    }
    bool paging_required = (menuStatusMessage == /*(main_status == */paging);
    bool is_connected = esp8266_is_connected();

    createMenuForAtari(menu_entries, act_page, num_menu_entries, paging_required, is_connected, plus_store_status );
    HAL_Delay(200);

  } // while(1)
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);
  /** Initializes the CPU, AHB and APB busses clocks
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 432;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 7;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB busses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief USART1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART1_UART_Init(void)
{

  /* USER CODE BEGIN USART1_Init 0 */

  /* USER CODE END USART1_Init 0 */

  /* USER CODE BEGIN USART1_Init 1 */
	  __HAL_RCC_GPIOA_CLK_ENABLE();

  /* USER CODE END USART1_Init 1 */
  huart1.Instance = USART1;
  huart1.Init.BaudRate = 115200;
  huart1.Init.WordLength = UART_WORDLENGTH_8B;
  huart1.Init.StopBits = UART_STOPBITS_1;
  huart1.Init.Parity = UART_PARITY_NONE;
  huart1.Init.Mode = UART_MODE_TX_RX;
  huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart1.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART1_Init 2 */

  /* USER CODE END USART1_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
//  __HAL_RCC_GPIOC_CLK_ENABLE();
  SET_BIT(RCC->AHB1ENR, RCC_AHB1ENR_GPIOCEN);
//  __HAL_RCC_GPIOD_CLK_ENABLE();
  SET_BIT(RCC->AHB1ENR, RCC_AHB1ENR_GPIODEN);
//  READ_BIT(RCC->AHB1ENR, RCC_AHB1ENR_GPIOCEN);
//  READ_BIT(RCC->AHB1ENR, RCC_AHB1ENR_GPIODEN);

  /*Configure GPIO pins : PC0 PC1 PC2 PC3
                           PC4 PC5 PC6 PC7 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_MEDIUM;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);

  /*Configure GPIO pins : PD8 PD9 PD10 PD11
                           PD12 PD13 PD14 PD15
                           PD0 PD1 PD2 PD3
                           PD4 PD5 PD6 PD7 */
  GPIO_InitStruct.Pin = GPIO_PIN_8|GPIO_PIN_9|GPIO_PIN_10|GPIO_PIN_11
                          |GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15
                          |GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  set_menu_status_msg("Init error 1");
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{ 
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
