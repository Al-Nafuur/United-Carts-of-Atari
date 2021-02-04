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
#include "cartridge_emulation_ar.h"
#include "cartridge_detection.h"
#include "cartridge_emulation.h"
#include "cartridge_emulation_df.h"
#include "cartridge_emulation_bf.h"
#include "cartridge_emulation_sb.h"
#include "cartridge_emulation_dpcp.h"

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
	"Connected, email sent",
	"User created, email sent",
	"PlusStore connect failed",
	"Disconnected from PlusStore",
	"Enter Secret-Key",
	"Secret-Key saved",
	"Offline ROMs erased",
	"ROM file too big!",
	"ACE is not supported",
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

inline void make_menu_entry_font( MENU_ENTRY **dst, const char *name, int type, uint8_t font) {
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
#endif
#if USE_SD_CARD
	make_menu_entry(&dst, "Format SD-Card", Menu_Action);
#endif
	make_menu_entry(&dst, MENU_TEXT_DISPLAY, Setup_Menu);
	make_menu_entry(&dst, MENU_TEXT_SYSTEM_INFO, Sub_Menu);

	if (flash_has_downloaded_roms())
		make_menu_entry(&dst, MENU_TEXT_DELETE_OFFLINE_ROMS, Menu_Action);
	else
		make_menu_entry(&dst, MENU_TEXT_DETECT_OFFLINE_ROMS, Menu_Action);

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
#endif

	sprintf(input_field, "Flash Size         %s", STM32F4_FLASH_SIZE > 512U ? "1 MiB": "512 KiB");
	make_menu_entry(&dst, input_field, Leave_Menu);


	sprintf(input_field, "Flash Used         %d KiB", (user_settings.first_free_flash_sector - 4 ) * 128);
	make_menu_entry(&dst, input_field, Leave_Menu);

#if USE_SD_CARD
    FATFS FatFs; 	//Fatfs handle
    //Open the file system
    if (f_mount(&FatFs, "", 1) == FR_OK) {
        //Let's get some statistics from the SD card
        DWORD free_clusters, used_size, total_size;
        FATFS* getFreeFs;
        if (f_getfree("", &free_clusters, &getFreeFs) == FR_OK) {
            //Formula comes from ChaN's documentation
            total_size = (getFreeFs->n_fatent - 2) * getFreeFs->csize;
            used_size = total_size - (free_clusters * getFreeFs->csize);

        	sprintf(input_field, "SD-Card Size       %d MiB", (int)(total_size / 2048));
        	make_menu_entry(&dst, input_field, Leave_Menu);
        	sprintf(input_field, "SD-Card Used       %d MiB", (int)(used_size / 2048));
        	make_menu_entry(&dst, input_field, Leave_Menu);
        }
		f_mount(0, "", 1);
    }
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
		// and this caters for the trailing slash in the setup string (if present)
//	char *mtsap = mts + sizeof(MENU_TEXT_APPEARANCE);

	if(strstr(curPath, MENU_TEXT_SETUP) == curPath) {
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
							// curPath is: MENU_TEXT_SETUP + "/" + MENU_TEXT_WIFI_SETUP + "/" + MENU_TEXT_WIFI_SELECT + "/" SSID[33] + Password + "/Enter" + '\0'
							//curPath[strlen(curPath) - 6 ] = '\0'; // delete "/Enter" at end of Path
							truncate_curPath();

							// TODO before we send them to esp8266 escape , " and \ in SSID and Password..
					        while( curPath[i] != 30 && i < ( SIZEOF_WIFI_SELECT_BASE_PATH + 31) ){
					            i++;
					        }
					        curPath[i] = 0;

					    	if(esp8266_wifi_connect( &curPath[SIZEOF_WIFI_SELECT_BASE_PATH  ],
					    			&curPath[SIZEOF_WIFI_SELECT_BASE_PATH + 32])){
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
#endif
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
/*
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
*/
		else{
			// unknown entry must be from PlusStore API, so load from store.
			loadStore = true;
		}
	}

	else if (strstr(curPath, MENU_TEXT_SEARCH_FOR_ROM) == curPath) {

		if(d->type == Menu_Action){
			// Cart with SD and WiFi will search on both..
#if USE_SD_CARD
			loadStore = false;
			make_menu_entry(&dst, "SD Search not Implemented", Leave_Menu);
#endif
#if USE_WIFI
			// Send search to API
			for (char* p = curPath; (p = strchr(p, ' ')); *p++ = '+');			// ' ' --> '+'
			loadStore = true;
			menuStatusMessage = STATUS_CHOOSE_ROM;
#endif
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

#if USE_WIFI
			strcpy(curPath, "&u=1");
			uint32_t bytes_read = esp8266_PlusStore_API_file_request( buffer, curPath, 0, 0x4000 );
			bytes_read += esp8266_PlusStore_API_file_request( &buffer[0x4000], curPath, 0x8000, (d->filesize - 0x8000) );
#else
			uint32_t bytes_read = 0;
#endif

			if(bytes_read == d->filesize - 0x4000 ){
				__disable_irq();
				HAL_FLASH_Unlock();
				flash_firmware_update(d->filesize);
			}else{
				menuStatusMessage = download_failed;
			}
		}
		else if (strstr(curPath, MENU_TEXT_SD_FIRMWARE_UPDATE) == curPath) {
//
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
    	if (d->type == Offline_Sub_Menu || strstr(curPath, MENU_TEXT_OFFLINE_ROMS) == curPath) {
    		make_menu_entry(&dst, "..", Leave_Menu);
    		num_menu_entries += flash_file_list(&curPath[sizeof(MENU_TEXT_OFFLINE_ROMS) - 1], dst);
    	}

#if USE_SD_CARD
    	else if(d->type == SD_Sub_Menu || strstr(curPath, MENU_TEXT_SD_CARD_CONTENT) == curPath){
    		make_menu_entry(&dst, "..", Leave_Menu);
    		num_menu_entries += sd_card_file_list(&curPath[sizeof(MENU_TEXT_SD_CARD_CONTENT) - 1], dst );
            qsort((MENU_ENTRY *)&menu_entries[0], num_menu_entries, sizeof(MENU_ENTRY), entry_compare);
    	}
#endif

#if USE_WIFI
    	else if(esp8266_is_connected() == true){
			int count = 0;
			bool is_entry_row;
			uint8_t pos = 0, c;
			if( esp8266_PlusStore_API_connect() == false){
				return esp_timeout;
			}
			esp8266_PlusStore_API_prepare_request_header(curPath, false, false);

        	esp8266_print(http_request_header);
            uint16_t bytes_read = 0, content_length = esp8266_skip_http_response_header();
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
#endif
    }

    if(strlen(curPath) == 0){
    	if(menuStatusMessage == none)
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
		cart_type.uses_ccmram = true;
		cart_type.uses_systick = true;
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

#if USE_WIFI
	if (cart_type.withPlusFunctions)
		esp8266_PlusStore_API_end_transmission();
#endif

}

void truncate_curPath(/*uint8_t count*/){

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

void system_secondary_init(void){
	if(flash_has_downloaded_roms() ){
	    MENU_ENTRY *d = &menu_entries[0];
	    MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];
		curPath[0] = '\0';
		strcat(curPath, MENU_TEXT_OFFLINE_ROMS);
		flash_file_list(&curPath[sizeof(MENU_TEXT_OFFLINE_ROMS) - 1], dst);

//		if (strstr(d->entryname, AUTOSTART_FILENAME_PREFIX) == d->entryname) {

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

#if USE_SD_CARD
	// put SD-Card init here
//	MX_GPIO_SD_CS_Init();
	MX_SPI2_Init();
	MX_FATFS_Init();
#if ! USE_WIFI
//	HAL_Delay(1000); //a short delay is important to let the SD card settle
#endif
#endif

#if USE_WIFI
	MX_USART1_UART_Init();
	esp8266_init();
	read_esp8266_at_version();
#endif
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

			if (d->type == Cart_File || d->type == Offline_Cart_File || d->type == SD_Cart_File) {

				// selection is a rom file
				int flash_sectors = (STM32F4_FLASH_SIZE > 512U) ? 12 : 8;
				int32_t max_romsize = (((BUFFER_SIZE + CCM_RAM_SIZE) * 1024)
						+ (flash_sectors - user_settings.first_free_flash_sector ) * 128 * 1024);
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

						if(cart_type.uses_systick){
							SysTick_Config(SystemCoreClock / 1000U);	// 1KHz
						}
						if (cart_type.uses_ccmram) {
							truncate_curPath();
							d->type = Sub_Menu;
							buildMenuFromPath(d);
						}
					}

					else
						menuStatusMessage = romtype_unknown;
				}

				truncate_curPath();

			}

			else {  // not a cart file...

				// selection is a directory or Menu_Action, or Keyboard_Char
				if (d->type == Leave_Menu) {

					if (strstr(curPath, "Search") == curPath)
						*curPath = 0;
					else
						truncate_curPath();

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

						if (strlen(input_field) + strlen(d->entryname) < STATUS_MESSAGE_LENGTH - 1)
							strcat(input_field, d->entryname);

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
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 7;
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

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(SD_CS_GPIO_Port, SD_CS_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pins : PC0 PC1 PC2 PC3
                           PC4 PC5 PC6 PC7 */
  GPIO_InitStruct.Pin = GPIO_PIN_0|GPIO_PIN_1|GPIO_PIN_2|GPIO_PIN_3
                          |GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
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
