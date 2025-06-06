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
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#include "global.h"
#include "font.h"
#if USE_WIFI
#include "esp8266.h"
#endif
#if USE_SD_CARD
#include "fatfs.h"
#endif

#include "stm32_udid.h"
#include "flash.h"
#include "cartridge_io.h"
#include "cartridge_firmware.h"
#include "cartridge_emulation_ACE.h"
#include "cartridge_emulation_ar.h"
#include "cartridge_emulation_ELF.h"
#include "cartridge_detection.h"
#include "cartridge_emulation.h"
#include "cartridge_emulation_df.h"
#include "cartridge_emulation_bf.h"
#include "cartridge_emulation_sb.h"
#include "cartridge_emulation_3F.h"


void generate_udid_string(void);

void truncate_curPath(/*uint8_t count*/);

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

typedef struct {
	enum cart_base_type base_type;
	bool withSuperChip;
	bool withPlusFunctions;
	bool uses_ccmram;
	bool uses_systick;
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
	{"ROM",  { base_type_None,    false, false, false, false }},
	{"BIN",  { base_type_None,    false, false, false, false }},
	{"A26",  { base_type_None,    false, false, false, false }},
	{"2K",   { base_type_2K,      false, false, false, false }},
	{"4K",   { base_type_4K,      false, false, false, false }},
	{"4KS",  { base_type_4K,      true,  false, false, false }},
	{"F8",   { base_type_F8,      false, false, false, false }},
	{"F6",   { base_type_F6,      false, false, false, false }},
	{"F4",   { base_type_F4,      false, false, false, false }},
	{"F8S",  { base_type_F8,      true,  false, false, false }},
	{"F6S",  { base_type_F6,      true,  false, false, false }},
	{"F4S",  { base_type_F4,      true,  false, false, false }},
	{"FE",   { base_type_FE,      false, false, false, false }},
	{"3F",   { base_type_3F,      false, false, false, false }},
	{"3E",   { base_type_3E,      false, false, false, false }},
	{"E0",   { base_type_E0,      false, false, false, false }},
	{"084",  { base_type_0840,    false, false, false, false }},
	{"CV",   { base_type_CV,      false, false, false, false }},
	{"EF",   { base_type_EF,      false, false, false, false }},
	{"EFS",  { base_type_EF,      true,  false, false, false }},
	{"F0",   { base_type_F0,      false, false, false, false }},
	{"FA",   { base_type_FA,      false, false, false, false }},
	{"FA2",  { base_type_FA2,     false, false, false, false }},
	{"E7",   { base_type_E7,      false, false, false, false }},
	{"DPC",  { base_type_DPC,     false, false, true,  true  }},
	{"AR",   { base_type_AR,      false, false, false, false }},
	{"BF",   { base_type_BF,      false, false, true,  false }},
	{"BFS",  { base_type_BFSC,    false, false, true,  false }},
	{"ACE",  { base_type_ACE,     false, false, false, false }},
	{"WD",   { base_type_PP,      false, false, false, false }},
	{"DF",   { base_type_DF,      false, false, true,  false }},
	{"DFS",  { base_type_DFSC,    false, false, true,  false }},
	{"3EP",  { base_type_3EPlus,  false, false, false, false }},
	{"DPCP", { base_type_DPCplus, false, false, false, true  }},
	{"SB",   { base_type_SB,      false, false, true,  false }},
	{"UA",   { base_type_UA,      false, false, false, false }},
	{"ELF",  { base_type_ELF,     false, false, false, false }},

	{0,{0,0,0}}
};

const char *status_message[]__attribute__((section(".flash01#"))) = {

#if MENU_TYPE == UNOCART
	"UnoCart 2600",
#else
	"PlusCart(+)",
#endif
	"Select WiFi Network",
	"No WiFi",
	"WiFi connected",
	"Request timeout",
	"Enter WiFi Password",
	"Enter email or username",
	"Your Chat Message",
	"Offline ROMs erased",
	"ROM file too big!",
	"ACE file unsupported",
	"Unknown/invalid ROM",
	"Done",
	"Failed",
	"Firmware download failed",
	"Offline ROMs detected",
	"No offline ROMs detected",
	"DPC+ is not supported",
	"Emulation exited",
	"ROM Download Failed",

	"Setup",
	"Select TV Mode",
	"Select Font",
	"Select Line Spacing",
	"Setup/System Info",
	MENU_TEXT_SEARCH_FOR_ROM,
	"Enter search details",
	"Search results",
	"Host name or IP address",

//	MENU_TEXT_APPEARANCE,
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
#if USE_SD_CARD
SPI_HandleTypeDef hspi2;
#endif
#if USE_WIFI
UART_HandleTypeDef huart1;
#endif

/* USER CODE BEGIN PV */
int num_menu_entries = 0;
char http_request_header[512] __attribute__ ((section (".noinit")));

char stm32_udid[25];


uint8_t buffer[BUFFER_SIZE * 1024] __attribute__((section(".buffer")));
unsigned int cart_size_bytes;

USER_SETTINGS user_settings;

char curPath[256] __attribute__ ((section (".noinit")));
char input_field[STATUS_MESSAGE_LENGTH] __attribute__ ((section (".noinit")));

int inputActive __attribute__ ((section (".noinit")));

uint8_t plus_store_status[1];

MENU_ENTRY menu_entries[NUM_MENU_ITEMS] __attribute__((section(".ccmram")));


/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
#if USE_WIFI
static void MX_USART1_UART_Init(void);
#endif
#if USE_SD_CARD
static void MX_SPI2_Init(void);
#endif
/* USER CODE BEGIN PFP */
enum e_status_message buildMenuFromPath( MENU_ENTRY * )__attribute__((section(".flash0"))) ;
void append_entry_to_path(MENU_ENTRY *);



/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */


void generate_udid_string(){
	int i;
	uint8_t c;
	memset(stm32_udid, '0', 24);
	stm32_udid[24] = '\0';
	for (int j = 2; j > -1; j--){
		uint32_t content_len = STM32_UDID[j];
		i = (j * 8) + 7;
		while (content_len != 0 && i > -1) {
			c = content_len % 16;
			stm32_udid[i--] = (char)((c > 9)? (c-10) + 'a' : c + '0');
			content_len = content_len/16;
		}
	}
}


/*************************************************************************
 * Menu Handling
 *************************************************************************/

char *get_filename_ext(char *filename) {
	char *dot = strrchr(filename, '.');
	if(!dot || dot == filename) return "";
	return (dot + 1);
}

/*inline*/ void make_menu_entry_font( MENU_ENTRY **dst, const char *name, int type, uint8_t font) {
	(*dst)->type = type;
	strcpy((*dst)->entryname, name);
	(*dst)->filesize = 0U;
	(*dst)->font = font;
	(*dst)++;
	num_menu_entries++;
}

void make_menu_entry( MENU_ENTRY **dst, const char *name, int type){
	make_menu_entry_font(dst, name, type, user_settings.font_style);
}


const char *keyboardUppercase[]__attribute__((section(".flash0#"))) = {
	" 1  2  3  4  5  6  7  8  9  0",
	"  Q  W  E  R  T  Y  U  I  O  P",
	"   A  S  D  F  G  H  J  K  L",
	"    Z  X  C  V  B  N  M",
	"     " MENU_TEXT_SPACE " !  ?  ,  .",
	0
};

const char *keyboardLowercase[]__attribute__((section(".flash0#"))) = {
	" 1  2  3  4  5  6  7  8  9  0",
	"  q  w  e  r  t  y  u  i  o  p",
	"   a  s  d  f  g  h  j  k  l",
	"    z  x  c  v  b  n  m",
	"     " MENU_TEXT_SPACE " !  ?  ,  .",
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

int compVersions ( const char * version1, const char * version2 ) {
    unsigned major1 = 0, minor1 = 0, bugfix1 = 0;
    unsigned major2 = 0, minor2 = 0, bugfix2 = 0;
    sscanf(version1, "%u.%u.%u", &major1, &minor1, &bugfix1);
    sscanf(version2, "%u.%u.%u", &major2, &minor2, &bugfix2);
    if (major1 < major2) return -1;
    if (major1 > major2) return 1;
    if (minor1 < minor2) return -1;
    if (minor1 > minor2) return 1;
    if (bugfix1 < bugfix2) return -1;
    if (bugfix1 > bugfix2) return 1;
    return 0;
}

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
		make_menu_entry(dst, *kbRow, Keyboard_Row);

	if (selector != KEYBOARD_LOWERCASE)
		make_menu_entry(dst, MENU_TEXT_LOWERCASE, Keyboard_Row);
	if (selector != KEYBOARD_UPPERCASE)
		make_menu_entry(dst, MENU_TEXT_UPPERCASE, Keyboard_Row);
	if (selector != KEYBOARD_SYMBOLS)
		make_menu_entry(dst, MENU_TEXT_SYMBOLS, Keyboard_Row);

	if (*input_field)
		make_menu_entry(dst, MENU_TEXT_DELETE_CHAR, Delete_Keyboard_Char);

	make_menu_entry(dst, "Enter", Menu_Action);
}

/*
MENU_ENTRY *generateAppearanceMenu(MENU_ENTRY *dst) {
	make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
	make_menu_entry(&dst, MENU_TEXT_TV_MODE_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_FONT_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_SPACING_SETUP, Setup_Menu);
	return dst;
}*/


MENU_ENTRY* generateSetupMenu(MENU_ENTRY *dst) {
	make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
#if USE_WIFI
	make_menu_entry(&dst, MENU_TEXT_WIFI_SETUP, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_API_HOST, Input_Field);
#endif
	make_menu_entry(&dst, MENU_TEXT_DISPLAY, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_SYSTEM_INFO, Sub_Menu);

	if (flash_has_downloaded_roms())
		make_menu_entry(&dst, MENU_TEXT_DELETE_OFFLINE_ROMS, Menu_Action);
	else
		make_menu_entry(&dst, MENU_TEXT_DETECT_OFFLINE_ROMS, Menu_Action);
	make_menu_entry(&dst, MENU_TEXT_FORMAT_EEPROM, Menu_Action);
	if (EXIT_SWCHB_ADDR == SWCHB)
		make_menu_entry(&dst, MENU_TEXT_DISABLE_EMU_EXIT, Menu_Action);
	else
		make_menu_entry(&dst, MENU_TEXT_ENABLE_EMU_EXIT, Menu_Action);

	return dst;
}

MENU_ENTRY* generateSystemInfo(MENU_ENTRY *dst) {
#if MENU_TYPE == PLUSCART
	make_menu_entry(&dst, "PlusCart Device ID", Leave_Menu);
#elif MENU_TYPE == UNOCART
	make_menu_entry(&dst, "UnoCart Device ID", Leave_Menu);
#endif

	sprintf(input_field, "        %s", stm32_udid);
	make_menu_entry(&dst, input_field, Leave_Menu);

	make_menu_entry(&dst, "STM Firmware       "VERSION, Leave_Menu);

#if USE_WIFI
	sprintf(input_field, "WiFi Firmware      %s", esp8266_at_version);
	make_menu_entry(&dst, input_field, Leave_Menu);
	make_menu_entry(&dst, "API Host", Leave_Menu);
	sprintf(input_field, "  %s", user_settings.api_host);
	make_menu_entry(&dst, input_field, Leave_Menu);
#endif

	sprintf(input_field, "Flash Size         %s", STM32F4_FLASH_SIZE > 512U ? "1 MiB": "512 KiB");
	make_menu_entry(&dst, input_field, Leave_Menu);


	sprintf(input_field, "Flash Used         %d KiB", (user_settings.first_free_flash_sector - 4 ) * 128);
	make_menu_entry(&dst, input_field, Leave_Menu);

#if USE_SD_CARD
	int * sd_stat = sd_card_statistic();
   	sprintf(input_field, "SD-Card Size       %d MiB", sd_stat[sd_card_total_size] );
   	make_menu_entry(&dst, input_field, Leave_Menu);
   	sprintf(input_field, "SD-Card Used       %d MiB", sd_stat[sd_card_used_size] );
   	make_menu_entry(&dst, input_field, Leave_Menu);
#endif

	*input_field = 0;
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
				truncate_curPath();
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
	truncate_curPath();
	return menuStatusMessage;
}

int entry_compare(const void* p1, const void* p2){
	MENU_ENTRY* e1 = (MENU_ENTRY*)p1;
	MENU_ENTRY* e2 = (MENU_ENTRY*)p2;
	if (e1->type == Leave_Menu) return -1;
	else if (e2->type == Leave_Menu) return 1;
	else if (e1->type == SD_Sub_Menu && e2->type != SD_Sub_Menu) return -1;
	else if (e1->type != SD_Sub_Menu && e2->type == SD_Sub_Menu) return 1;
	else return strcasecmp(e1->entryname, e2->entryname);
}

enum e_status_message buildMenuFromPath( MENU_ENTRY *d )  {
	bool loadStore = false; // ToDo rename to loadPath (could be SD, flash or WiFi path)
	num_menu_entries = 0;
	enum e_status_message menuStatusMessage = STATUS_NONE;

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
		// and this caters for the trailing slash in the setup string (if present)
//	char *mtsap = mts + sizeof(MENU_TEXT_APPEARANCE);

	if (d->type == Input_Field || d->type == Keyboard_Char || d->type == Keyboard_Row ||
			d->type == Delete_Keyboard_Char || d->type == Leave_SubKeyboard_Menu ){
		// toDo  Input_Field to Leave_SubKeyboard_Menu consecutive!
		int new_status = 1;
		if (strstr(curPath, MENU_TEXT_SEARCH_FOR_ROM) == curPath){
		    new_status = STATUS_SEARCH_DETAILS;
		}else{  // All Setup menu stuff here!
			char *mts = curPath + sizeof(MENU_TEXT_SETUP);   // does a +1 because of MENU_TEXT_SETUP trailing 0
		    if(strstr(mts, MENU_TEXT_PLUS_CONNECT) == mts)
		        new_status = plus_connect;
		    else if(strstr(mts, MENU_TEXT_WIFI_SETUP) == mts)
		        new_status = insert_password;
		    else if(strstr(mts, MENU_TEXT_API_HOST) == mts)
		        new_status = STATUS_HOST_OR_IP;
		    else
		        new_status = STATUS_YOUR_MESSAGE;
		}
		if (d->type == Input_Field)
			*input_field = 0;

		menuStatusMessage = generateKeyboard(&dst, d, menuStatusMessage, new_status);
	}
	else if(strstr(curPath, MENU_TEXT_SETUP) == curPath) {
		char *mts = curPath + sizeof(MENU_TEXT_SETUP);   // does a +1 because of MENU_TEXT_SETUP trailing 0

		if (!strcmp(curPath, MENU_TEXT_SETUP)){
			menuStatusMessage = STATUS_SETUP;
			dst = generateSetupMenu(dst);
			loadStore = true;
		}

//		else if (strstr(mts, MENU_TEXT_APPEARANCE) == mts) {
//			dst = generateAppearanceMenu(dst);
//			loadStore = true;
//		}

		else if (strstr(mts, URLENCODE_MENU_TEXT_SYSTEM_INFO) == mts) {
			menuStatusMessage = STATUS_SETUP_SYSTEM_INFO;
			dst = generateSystemInfo(dst);
			loadStore = true;
		}
#if USE_WIFI
		else if (strstr(mts, MENU_TEXT_API_HOST) == mts) {
			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> change host
				// curPath is:
				// MENU_TEXT_SETUP "/" MENU_TEXT_API_HOST "/" api_host[30] "/Enter" '\0'
				truncate_curPath(); // delete "/Enter" at end of Path
				strcpy(user_settings.api_host, &curPath[SIZEOF_API_HOST_BASE_PATH]);
				flash_set_eeprom_user_settings(user_settings);
				curPath[0] = '\0';
			}

		}
		// WiFi Setup
		else if (strstr(mts, MENU_TEXT_WIFI_SETUP) == mts) {

			int i = sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_WIFI_SETUP) - 1;

			if ( strlen(curPath) <= i ){

				set_menu_status_msg(curPath);

				make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
				make_menu_entry(&dst, MENU_TEXT_WIFI_SELECT, Setup_Menu);
				make_menu_entry(&dst, MENU_TEXT_WIFI_WPS_CONNECT, Menu_Action);
				make_menu_entry(&dst, MENU_TEXT_WIFI_MANAGER, Menu_Action);
				make_menu_entry(&dst, MENU_TEXT_ESP8266_RESTORE, Menu_Action);
				if(compVersions(esp8266_at_version, CURRENT_ESP8266_FIRMWARE) == -1)
					make_menu_entry(&dst, MENU_TEXT_ESP8266_UPDATE, Menu_Action);

			}

			else {

				mts += sizeof(MENU_TEXT_WIFI_SETUP);

				if (strstr(mts, MENU_TEXT_WIFI_SELECT) == mts) {

					i += (int) sizeof(MENU_TEXT_WIFI_SELECT);
					if (strlen(curPath) > i){

						if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect to WiFi
							// curPath is:
							// MENU_TEXT_SETUP "/" MENU_TEXT_WIFI_SETUP "/" MENU_TEXT_WIFI_SELECT "/" ssid[33] "/" Password "/Enter" '\0'
							truncate_curPath(); // delete "/Enter" at end of Path

							// TODO before we send them to esp8266 escape , " and \ in SSID and Password..
					        while( curPath[i] != 30 && i < ( SIZEOF_WIFI_SELECT_BASE_PATH + 31) ){
					            i++;
					        }
					        curPath[i] = 0;

					    	if(esp8266_wifi_connect( &curPath[SIZEOF_WIFI_SELECT_BASE_PATH  ],
					    			&curPath[SIZEOF_WIFI_SELECT_BASE_PATH + 33])){
					        	menuStatusMessage = wifi_connected;
					    	}else{
					        	menuStatusMessage = wifi_not_connected;
					    	}
							curPath[0] = '\0';
						}
					}

					else {
						menuStatusMessage = select_wifi_network;
						make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
						if( esp8266_wifi_list( &dst, &num_menu_entries) == false){
				    		return esp_timeout;
				    	}
					}

				}
				else if (strstr(mts, MENU_TEXT_WIFI_WPS_CONNECT) == mts) {

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
				else if (strstr(mts, MENU_TEXT_ESP8266_UPDATE) == mts) {
					esp8266_update();
					truncate_curPath();
					menuStatusMessage = buildMenuFromPath(d);
				}
			}
		}
#endif
		else if (strstr(mts, MENU_TEXT_FORMAT_EEPROM) == mts) {
			flash_erase_eeprom();
			truncate_curPath();
			buildMenuFromPath(d);
			menuStatusMessage = done;
		}
		else if (strstr(mts, MENU_TEXT_ENABLE_EMU_EXIT) == mts) {
			EXIT_SWCHB_ADDR = SWCHB;
			truncate_curPath();
			buildMenuFromPath(d);
			menuStatusMessage = done;
		}
		else if (strstr(mts, MENU_TEXT_DISABLE_EMU_EXIT) == mts) {
			EXIT_SWCHB_ADDR = 0xffff; // Impossible address prevents snooping SWCHB reads
			truncate_curPath();
			buildMenuFromPath(d);
			menuStatusMessage = done;
		}
		// Display
		else if (strstr(mts, MENU_TEXT_DISPLAY) == mts) {


			int i = sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_DISPLAY) - 1;
			if (strlen(curPath) <= i) {

				set_menu_status_msg(curPath);

				make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);
				make_menu_entry(&dst, MENU_TEXT_TV_MODE_SETUP, Setup_Menu);
				make_menu_entry(&dst, MENU_TEXT_FONT_SETUP, Setup_Menu);
				make_menu_entry(&dst, MENU_TEXT_SPACING_SETUP, Setup_Menu);
			}

			else {

				mts += sizeof(MENU_TEXT_DISPLAY);
				if (strstr(mts, MENU_TEXT_TV_MODE_SETUP) == mts) {

					if(d->type == Menu_Action){

						uint8_t tvMode = TV_MODE_NTSC;
						while (!strstr(tvModes[tvMode], d->entryname + 1))
							tvMode++;

						set_tv_mode(tvMode);

						if(user_settings.tv_mode != tvMode){
							user_settings.tv_mode = tvMode;
							flash_set_eeprom_user_settings(user_settings);
						}

						truncate_curPath();
						menuStatusMessage = buildMenuFromPath(d);
					}

					else {

						menuStatusMessage = STATUS_SETUP_TV_MODE;
						set_menu_status_msg(curPath);

						make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);

						for (int tv = 1; tv < sizeof tvModes / sizeof *tvModes; tv++) {
							make_menu_entry(&dst, tvModes[tv], Menu_Action);
							if (user_settings.tv_mode == tv)
								*(dst-1)->entryname = CHAR_SELECTION;
						}
					}

				}

				else if (strstr(mts, MENU_TEXT_FONT_SETUP) == mts) {

					if(d->type == Menu_Action){

						uint8_t fontStyle = 0;
						while (!strstr(menuFontNames[fontStyle], d->entryname + 1))
							fontStyle++;

						if(user_settings.font_style != fontStyle){
							user_settings.font_style = fontStyle;
							flash_set_eeprom_user_settings(user_settings);
						}

						truncate_curPath();
						menuStatusMessage = buildMenuFromPath(d);
					}

					else{

						menuStatusMessage = STATUS_SETUP_FONT_STYLE;
						make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);

						for (uint8_t font=0; font < sizeof menuFontNames / sizeof *menuFontNames; font++) {
							make_menu_entry_font(&dst, menuFontNames[font], Menu_Action, font);
							if (user_settings.font_style == font)
								*(dst-1)->entryname = CHAR_SELECTION;
						}
					}

				}

				// Text line spacing
				else if (strstr(mts, MENU_TEXT_SPACING_SETUP) == mts) {

					if(d->type == Menu_Action) {

						uint8_t lineSpacing = 0;
						while (!strstr(spacingModes[lineSpacing], d->entryname + 1))
							lineSpacing++;

						if(user_settings.line_spacing != lineSpacing) {
							user_settings.line_spacing = lineSpacing;
							flash_set_eeprom_user_settings(user_settings);
						}

						truncate_curPath();
						menuStatusMessage = buildMenuFromPath(d);
					}

					else {

						menuStatusMessage = STATUS_SETUP_LINE_SPACING;

						make_menu_entry(&dst, MENU_TEXT_GO_BACK, Leave_Menu);

						for (uint8_t spacing = 0; spacing < sizeof spacingModes / sizeof *spacingModes; spacing++) {
							make_menu_entry(&dst, spacingModes[spacing], Menu_Action);
							if (user_settings.line_spacing == spacing)
								*(dst-1)->entryname = CHAR_SELECTION;
						}
					}
				}
			}
		}

		else if (strstr(mts, MENU_TEXT_OFFLINE_ROM_UPDATE) == mts) {
#if USE_WIFI
			if( flash_download("&r=1", d->filesize , 0 , false ) != DOWNLOAD_AREA_START_ADDRESS)
				menuStatusMessage = download_failed;
			else {
				menuStatusMessage = done;
	        	*curPath = 0;
			}
#endif
#if USE_SD_CARD
			menuStatusMessage = done;
			*curPath = 0;
#endif
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
		else{
			// unknown entry must be from PlusStore API, so load from store.
			loadStore = true;
		}
	}

	else if (d->type == Menu_Action){

		if (strstr(curPath, MENU_TEXT_FIRMWARE_UPDATE) == curPath) {
			uint32_t bytes_to_read = d->filesize - 0x4000;
#if USE_WIFI
			strcpy(curPath, "&u=1");
			uint32_t bytes_to_ram = d->filesize > FIRMWARE_MAX_RAM ? FIRMWARE_MAX_RAM : d->filesize;
			uint32_t bytes_read = esp8266_PlusStore_API_file_request( buffer, curPath, 0, 0x4000 );

			bytes_read += esp8266_PlusStore_API_file_request( &buffer[0x4000], curPath, 0x8000, (bytes_to_ram - 0x8000));
			if (d->filesize > FIRMWARE_MAX_RAM ){
				bytes_read += esp8266_PlusStore_API_file_request( ((uint8_t*)0x10000000), curPath, FIRMWARE_MAX_RAM, ( d->filesize - FIRMWARE_MAX_RAM) );
			}

#else
			uint32_t bytes_read = 0;
#endif

			if(bytes_read == bytes_to_read ){
				__disable_irq();
				HAL_FLASH_Unlock();
				flash_firmware_update(bytes_read);
			}else{
				menuStatusMessage = download_failed;
			}
			*curPath = 0;
		}
		else if (strstr(curPath, MENU_TEXT_SD_FIRMWARE_UPDATE) == curPath) {
			uint32_t bytes_to_read = d->filesize - 0x4000;
#if USE_SD_CARD
			uint32_t bytes_to_ram = d->filesize > FIRMWARE_MAX_RAM ? FIRMWARE_MAX_RAM : d->filesize;
			uint32_t bytes_read = sd_card_file_request( buffer, MENU_TEXT_SD_CARD_CONTENT"/firmware.bin", 0, 0x4000 );
			bytes_read += sd_card_file_request( &buffer[0x4000], MENU_TEXT_SD_CARD_CONTENT"/firmware.bin", 0x8000, (bytes_to_ram - 0x8000) );
			if (d->filesize > FIRMWARE_MAX_RAM ){
				bytes_read += sd_card_file_request( ((uint8_t*)0x10000000),  MENU_TEXT_SD_CARD_CONTENT"/firmware.bin", FIRMWARE_MAX_RAM, ( d->filesize - FIRMWARE_MAX_RAM) );
			}
#else
			uint32_t bytes_read = 0;
#endif

			if(bytes_read == bytes_to_read ){
				__disable_irq();
				HAL_FLASH_Unlock();
				flash_firmware_update(bytes_read);
			}else{
				menuStatusMessage = download_failed;
			}
			*curPath = 0;
		}
#if USE_SD_CARD
		else if (strstr(curPath, MENU_TEXT_SEARCH_FOR_ROM) == curPath) {
			// Cart with SD and WiFi will search only here (SD) ! -> maybe use "Search SD ROM" ?
			loadStore = false;
			truncate_curPath(); // delete "/Enter"
			make_menu_entry(&dst, "..", Leave_Menu);
			http_request_header[0] = '\0';
			sd_card_find_file( http_request_header, &curPath[sizeof(MENU_TEXT_SEARCH_FOR_ROM)], &dst, &num_menu_entries );
		}
#endif
		else if (strstr(curPath, MENU_TEXT_WIFI_RECONNECT) == curPath){
			loadStore = true;
			*curPath = 0;
		}else{
#if USE_WIFI
			loadStore = true;
#endif
		}

	}

	else {
		set_menu_status_msg(curPath);
		loadStore = true;
	}


	// Test we should load store and if connected to AP
    if(	loadStore || strlen(curPath) == 0 ){
    	int trim_path = 0;
    	if(strlen(curPath) == 0){
#if USE_SD_CARD
    		// check for firmware.bin file in SD root
    		int firmware_file_size = sd_card_file_size("firmware.bin");
    		if(firmware_file_size > 0){
    			// ToDo make_menu_entry_filesize();
    			dst->filesize = (uint32_t)firmware_file_size;
    			strcpy(dst->entryname, MENU_TEXT_SD_FIRMWARE_UPDATE);
        		dst->type = Menu_Action;
        		dst->font = user_settings.font_style;
                dst++;
                num_menu_entries++;
    		}
#endif
    	}

    	if (d->type == Offline_Sub_Menu || strstr(curPath, MENU_TEXT_OFFLINE_ROMS) == curPath) {
    		make_menu_entry(&dst, "..", Leave_Menu);
    		flash_file_list(&curPath[sizeof(MENU_TEXT_OFFLINE_ROMS) - 1], &dst, &num_menu_entries);
    	}

#if USE_SD_CARD
    	else if(d->type == SD_Sub_Menu || strstr(curPath, MENU_TEXT_SD_CARD_CONTENT) == curPath){
    		if(sd_card_file_list(&curPath[sizeof(MENU_TEXT_SD_CARD_CONTENT) - 1], &dst, &num_menu_entries ))
    			qsort((MENU_ENTRY *)&menu_entries[0], num_menu_entries, sizeof(MENU_ENTRY), entry_compare);
    	}
#endif

#if USE_WIFI
    	else if(esp8266_is_connected() == true){
    		*input_field = 0;
    		trim_path = esp8266_file_list(curPath, &dst, &num_menu_entries, plus_store_status, input_field);
    		if(*input_field)
    			menuStatusMessage = STATUS_MESSAGE_STRING;
        }else if(strlen(curPath) == 0){
        	make_menu_entry(&dst, MENU_TEXT_WIFI_RECONNECT, Menu_Action);
    	}
#endif
        if(trim_path){
        	inputActive = 0; // API response trim overrules internal truncate
        	                 // toDo merge trim_path and inputActive ? centralize truncate_curPath() call ?
        	while (trim_path--){
        		truncate_curPath();
        	}
        }

    }

    if(strlen(curPath) == 0){
    	if(menuStatusMessage == STATUS_NONE)
    		menuStatusMessage = STATUS_ROOT;

#if USE_SD_CARD
    	make_menu_entry(&dst, MENU_TEXT_SD_CARD_CONTENT, SD_Sub_Menu);
#if USE_WIFI == 0 // todo check how to sort man menu and how to search
    	make_menu_entry(&dst, MENU_TEXT_SEARCH_FOR_ROM, Input_Field);
#endif
#endif
    	if(	flash_has_downloaded_roms() )
    		make_menu_entry(&dst, MENU_TEXT_OFFLINE_ROMS, Offline_Sub_Menu);

    	make_menu_entry(&dst, MENU_TEXT_SETUP, Setup_Menu);
	}

    if(num_menu_entries == 0){
		make_menu_entry(&dst, "..", Leave_Menu);
    }

    return menuStatusMessage;
}


CART_TYPE identify_cartridge( MENU_ENTRY *d )
{

	CART_TYPE cart_type = { base_type_None, false, false, false, false };

	strcat(curPath, "/");
	append_entry_to_path(d);

	// Test if connected to AP
    if(d->type == Cart_File ){
#if USE_WIFI
    	if(esp8266_is_connected() == false)
#endif
    		return cart_type;
    }
    if(d->type == SD_Cart_File ){
#if ! USE_SD_CARD
   		return cart_type;
#endif
    }

    // Check for exit function disable key in filename
    if (strstr(d->entryname, EXIT_FUNCTION_DISABLE_FILENAME_KEY) != NULL)
		EXIT_SWCHB_ADDR = 0xffff; // Impossible address prevents snooping SWCHB reads

    // select type by file extension?
	char *ext = get_filename_ext(d->entryname);
	const EXT_TO_CART_TYPE_MAP *p = ext_to_cart_type_map;
	while (p->ext) {
		if (strcasecmp(ext, p->ext) == 0) {
			cart_type.base_type = p->cart_type.base_type;
			cart_type.withSuperChip = p->cart_type.withSuperChip;
			cart_type.uses_ccmram = p->cart_type.uses_ccmram;
			cart_type.uses_systick = p->cart_type.uses_systick;
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
	uint8_t tail[16], bytes_read_tail=0;
	if(d->type == Cart_File ){
#if USE_WIFI
		bytes_read = esp8266_PlusStore_API_file_request( buffer, curPath, 0, bytes_to_read );
#endif
	}else if(d->type == SD_Cart_File ){
#if USE_SD_CARD
		bytes_read = sd_card_file_request(buffer, curPath, 0, bytes_to_read);
#endif
	}else{
		bytes_read = flash_file_request( buffer, d->flash_base_address, 0, bytes_to_read );
	}

	if( bytes_read != bytes_to_read ){
		cart_type.base_type = base_type_Load_Failed;
		goto close;
	}
	if(d->filesize >  (BUFFER_SIZE * 1024)){
		cart_type.uses_ccmram = true;
		if(d->type == Cart_File ){
#if USE_WIFI
			bytes_read_tail = (uint8_t)esp8266_PlusStore_API_file_request( tail, curPath, (d->filesize - 16), 16 );
#endif
		}else if(d->type == SD_Cart_File ){
#if USE_SD_CARD
			bytes_read_tail = (uint8_t)sd_card_file_request( tail, curPath, (d->filesize - 16), 16 );
#endif
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

	// Check with types that have headers first since they are more reliable than huristics
	if(isElf(bytes_read, buffer))
	{
		cart_type.base_type = base_type_ELF;
	}
	else if(is_ace_cartridge(bytes_read, buffer)){
		cart_type.base_type = base_type_ACE;
	}
	else if (d->filesize <= 64 * 1024 && (d->filesize % 1024) == 0 && isProbably3EPlus(d->filesize, buffer))
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
		else if (isProbablyE78K(d->filesize, buffer)) {
			cart_type.base_type = base_type_E7;
			memmove(buffer+0x2000,buffer,0x2000);
			d->filesize = 16*1024;
		} else
			cart_type.base_type = base_type_F8;
	}
	else if (d->filesize == 8*1024 + 3) {
		cart_type.base_type = base_type_PP;
	}
	else if(d->filesize >= 10240 && d->filesize <= 10496)
	{  // ~10K - Pitfall II
		cart_type.uses_ccmram = true;
		cart_type.uses_systick = true;
		cart_type.base_type = base_type_DPC;
	}
	else if (d->filesize == 12*1024)
	{
		if (isProbablyE7(d->filesize, buffer)){
			cart_type.base_type = base_type_E7;
			memmove(buffer+0x1000, buffer, 0x3000);
			d->filesize = 16*1024;
		} else
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
	else if (d->filesize == 24*1024 || d->filesize == 28*1024)
	{
		cart_type.base_type = base_type_FA2;
	}
	else if (d->filesize == 29*1024)
	{
		if (isProbablyDPCplus(d->filesize, buffer)){
			cart_type.base_type = base_type_DPCplus;
		} else{
			cart_type.base_type = base_type_FA2;
			memmove(buffer, buffer+0x0400, 0x7000);
			d->filesize = 28*1024;
		}
	}
	else if (d->filesize == 32*1024)
	{
		if (isProbably3E(d->filesize, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
		else if (isProbablyDPCplus(d->filesize, buffer)){
			cart_type.base_type = base_type_DPCplus;
			cart_type.uses_systick = true;
		}
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
		}else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
		else
			cart_type.base_type = base_type_SB;
	}
	else if (d->filesize == 256 * 1024)
	{
		if (isProbablyBF(tail))
			cart_type.base_type = base_type_BF;
		else if (isProbablyBFSC(tail)){
			cart_type.base_type = base_type_BFSC;
			cart_type.withSuperChip = 1;
		}else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
		else
			cart_type.base_type = base_type_SB;
	}
	else if (d->filesize == 512 * 1024)
	{
		 // if (isProbably3F(d->filesize, buffer)) // 3F is the only 512K ROM supported
			 cart_type.base_type = base_type_3F;
//	}else{ // No else so far

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


#if USE_WIFI
	if (cart_type.withPlusFunctions == true ){
 		// Read path and hostname in ROM File from where NMI points to till '\0' and
		// copy to http_request_header
		offset = esp8266_PlusROM_API_connect(cart_size_bytes);
	}
#endif


	if (cart_type.base_type == base_type_2K) {
		memcpy(buffer+0x800, buffer, 0x800);
		emulate_standard_cartridge(offset, cart_type.withPlusFunctions, 0x2000, 0x0000, cart_type.withSuperChip);
	}

	else if (cart_type.base_type ==  base_type_4K)
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
		emulate_3F_cartridge(curPath, cart_size_bytes, buffer, d);

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
		emulate_FA_FA2_cartridge(offset, cart_type.withPlusFunctions, 0x1FF8, 0x1FFA);

	else if (cart_type.base_type == base_type_FA2){
		/* Workaround to set Melody Flash-ROM hotspot ($1ff4 bit 6) to 0 in every bank */
		for (long hotspot = 0xff4; hotspot < 0x7000; hotspot += 0x1000) {
			buffer[hotspot] &= 0b10111111;
		} // End of workaround
		emulate_FA_FA2_cartridge(offset, cart_type.withPlusFunctions, 0x1FF5, 0x1FFB);
	}

	else if (cart_type.base_type == base_type_E7)
		emulate_E7_cartridge(offset, cart_type.withPlusFunctions);

	else if (cart_type.base_type == base_type_DPC)
		emulate_DPC_cartridge((uint32_t)cart_size_bytes);

	else if (cart_type.base_type == base_type_AR)
		emulate_ar_cartridge(curPath, cart_size_bytes, buffer, user_settings.tv_mode, d);

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

	else if (cart_type.base_type == base_type_SB)
		emulate_SB_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_ACE)
	{
		static unsigned char CCMUsageFinder __attribute__((section(".ccmram#"))); //Method of finding where allocation has reached for CCM RAM
		uint32_t* CCMpointer=(uint32_t*)&CCMUsageFinder; //Find address of CCM allocation and cast as a pointer
		launch_ace_cartridge(curPath, cart_size_bytes, buffer, d, offset, cart_type.withPlusFunctions,CCMpointer); //Open the ACE bootloader library function
	}
	else if (cart_type.base_type == base_type_ELF)
	{
		launch_elf_file(curPath, cart_size_bytes, buffer);
	}

#if USE_WIFI
	if (cart_type.withPlusFunctions)
		esp8266_PlusStore_API_end_transmission();
#endif

}

void truncate_curPath(){

	for (int selector = 0; keyboards[selector]; selector++)
		for (const char **kbRow = keyboards[selector]; *kbRow; kbRow++) {
			char *kb = strstr(curPath, *kbRow);
			if (kb) {
				*(kb-1) = 0;
				return;
			}
		}

	// trim to last / OR if none, whole path
	char *sep = strrchr(curPath, PATH_SEPERATOR);
	if (!sep)
		sep = curPath;
	*sep = 0;

}

void check_autostart(bool check_PlusROM){
	if(flash_has_downloaded_roms() ){
	    MENU_ENTRY *d = &menu_entries[0];
	    MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];
		curPath[0] = '\0';
		flash_file_list( curPath, &dst, &num_menu_entries);

		if( ( !check_PlusROM &&
			strncmp(STD_ROM_AUTOSTART_FILENAME_PREFIX, d->entryname, sizeof(STD_ROM_AUTOSTART_FILENAME_PREFIX) - 1) == 0 )
			||
			( check_PlusROM &&
			strncmp(PLUSROM_AUTOSTART_FILENAME_PREFIX, d->entryname, sizeof(PLUSROM_AUTOSTART_FILENAME_PREFIX) - 1) == 0 )
		){
    		CART_TYPE cart_type = identify_cartridge(d);
            HAL_Delay(200);
            if (cart_type.base_type != base_type_None){
                emulate_cartridge(cart_type, d);
            }
		}
		num_menu_entries = 0;
	}

}

void system_secondary_init(void){
	check_autostart(false);

	//	check user_settings properties that haven't been in user_setting since v1
	if( user_settings.line_spacing >= SPACING_MAX )
		user_settings.line_spacing = SPACING_DEFAULT;

	if( user_settings.font_style >= FONT_MAX )
		user_settings.font_style = FONT_DEFAULT;

	generate_udid_string();

#if USE_SD_CARD
	// put SD-Card init here
	MX_SPI2_Init();
	MX_FATFS_Init();
#if ! USE_WIFI
	HAL_Delay(500); //a short delay is important to let the SD card settle
#endif
#endif

#if USE_WIFI
	MX_USART1_UART_Init();
	esp8266_init();
	read_esp8266_at_version();
	check_autostart(true);
#endif

	set_menu_status_byte(STATUS_StatusByteReboot, 0);

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
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
	    int ret = emulate_firmware_cartridge();

		if (ret == CART_CMD_ROOT_DIR) {
			system_secondary_init();

			d->type = Root_Menu;
			d->filesize = 0;

			*input_field = *curPath = 0;
			inputActive = 0;

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

			if (d->type == Cart_File || d->type == Offline_Cart_File || d->type == SD_Cart_File) {

				// selection is a rom file
				int flash_sectors = (STM32F4_FLASH_SIZE > 512U) ? 12 : 8;
				int32_t max_romsize = (((BUFFER_SIZE + CCM_RAM_SIZE) * 1024)
						+ (flash_sectors - user_settings.first_free_flash_sector ) * 128 * 1024);
				if (d->filesize > max_romsize)
					menuStatusMessage = not_enough_menory;

				else {

					CART_TYPE cart_type = identify_cartridge(d);
					HAL_Delay(200);

					if (cart_type.base_type == base_type_ACE && !(is_ace_cartridge(d->filesize, buffer)))
						menuStatusMessage = romtype_ACE_unsupported;

					else if (cart_type.base_type == base_type_Load_Failed)
						menuStatusMessage = rom_download_failed;

					else if (cart_type.base_type == base_type_DPCplus)
						menuStatusMessage = romtype_DPCplus_unsupported;

					else if (cart_type.base_type != base_type_None) {

						emulate_cartridge(cart_type, d);
						set_menu_status_byte(STATUS_StatusByteReboot, 0);
						menuStatusMessage = exit_emulation;

						if(cart_type.uses_systick){
							SysTick_Config(SystemCoreClock / 1000U);	// 1KHz
						}
					}

					else
						menuStatusMessage = romtype_unknown;
				}

				truncate_curPath();

				d->type = Sub_Menu;
				buildMenuFromPath(d);

			}

			else {  // not a cart file...

				// selection is a directory or Menu_Action, or Keyboard_Char
				if (d->type == Leave_Menu) {

					inputActive++;
					while(inputActive--)
						truncate_curPath();

					inputActive = 0;
					*input_field = 0;
				}

				else if (d->type == Leave_SubKeyboard_Menu) {
				}

				else if (d->type == Delete_Keyboard_Char) {

					unsigned int len = strlen(input_field);
					if (len) {
						input_field[--len] = 0;
						curPath[strlen(curPath) - 1] = 0;
					}

				} else {

					if (d->type != Keyboard_Char && strlen(curPath) > 0 ) {
						strcat(curPath, "/");
					}
					else if (d->type == Keyboard_Char && !strcmp(d->entryname, MENU_TEXT_SPACE))
						strcpy(d->entryname, " ");

					append_entry_to_path(d);

					if (d->type == Keyboard_Char) {

						if (strlen(input_field) + strlen(d->entryname) < STATUS_MESSAGE_LENGTH - 1)
							strcat(input_field, d->entryname);

					}
					else if (d->type == Input_Field) {
						strcat(curPath, "/");
						inputActive++; // = 1 ???
					}
					else {
						if (d->type == Menu_Action) {
							if(inputActive)
								inputActive += 2; // input + "Enter", if input contains path_sep trim will be corrected by API
							*input_field = 0;
						}
					}
				}
				menuStatusMessage = buildMenuFromPath(d);
			}
		}


		if (*input_field || menuStatusMessage == STATUS_MESSAGE_STRING) {
			set_menu_status_msg(input_field);
			set_menu_status_byte(STATUS_PageType, (uint8_t) Keyboard);
		}

	    else {

	    	if (menuStatusMessage >= STATUS_ROOT)
	    		set_menu_status_msg(status_message[menuStatusMessage]);

	    	if(act_page > (num_menu_entries / numMenuItemsPerPage[user_settings.line_spacing]) )
	    		act_page = 0;

	    	set_menu_status_byte(STATUS_PageType, (uint8_t) Directory);
	    }
	#if USE_WIFI
		bool is_connected = esp8266_is_connected();
	#else
		bool is_connected = false;
	#endif
		createMenuForAtari(menu_entries, act_page, num_menu_entries, is_connected, plus_store_status );
	    HAL_Delay(200);
  }
  /* USER CODE END 3 */
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
  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 432;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 9;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB buses clocks
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
  * @brief SPI2 Initialization Function
  * @param None
  * @retval None
  */
#if USE_SD_CARD
static void MX_SPI2_Init(void)
{

  /* USER CODE BEGIN SPI2_Init 0 */

  /* USER CODE END SPI2_Init 0 */

  /* USER CODE BEGIN SPI2_Init 1 */

  /* USER CODE END SPI2_Init 1 */
  /* SPI2 parameter configuration*/
  hspi2.Instance = SPI2;
  hspi2.Init.Mode = SPI_MODE_MASTER;
  hspi2.Init.Direction = SPI_DIRECTION_2LINES;
  hspi2.Init.DataSize = SPI_DATASIZE_8BIT;
  hspi2.Init.CLKPolarity = SPI_POLARITY_LOW;
  hspi2.Init.CLKPhase = SPI_PHASE_1EDGE;
  hspi2.Init.NSS = SPI_NSS_SOFT;
  hspi2.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_32;
  hspi2.Init.FirstBit = SPI_FIRSTBIT_MSB;
  hspi2.Init.TIMode = SPI_TIMODE_DISABLE;
  hspi2.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
  hspi2.Init.CRCPolynomial = 10;
  if (HAL_SPI_Init(&hspi2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN SPI2_Init 2 */

  /* USER CODE END SPI2_Init 2 */

}
#endif
/**
  * @brief USART1 Initialization Function
  * @param None
  * @retval None
  */
#if USE_WIFI
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
#endif
/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOE_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(SD_CS_GPIO_Port, SD_CS_Pin, GPIO_PIN_RESET);

#if HARDWARE_TYPE == PLUSCART
  /*Configure GPIO pins : PC0 PC1 PC2 PC3
                           PC4 PC5 PC6 PC7 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
#elif HARDWARE_TYPE == UNOCART
  /*Configure GPIO pins : PE8 PE9 PE10 PE11
                           PE12 PE13 PE14 PE15 */
  GPIO_InitStruct.Pin = GPIO_PIN_8|GPIO_PIN_9|GPIO_PIN_10|GPIO_PIN_11
                          |GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(GPIOE, &GPIO_InitStruct);
#endif
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
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

  /*Configure GPIO pin : SD_CS_Pin */
  GPIO_InitStruct.Pin = SD_CS_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(SD_CS_GPIO_Port, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */

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
