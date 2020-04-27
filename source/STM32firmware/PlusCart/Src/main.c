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
#include <ctype.h>
#include <string.h>

#include "main.h"
#include "esp8266.h"
#include "flash.h"
#include "cartridge_io.h"
#include "cartridge_firmware.h"
#include "cartridge_supercharger.h"
#include "cartridge_detection.h"
#include "cartridge_emulation.h"
#include "cartridge_emulation_df.h"
#include "cartridge_emulation_bf.h"


/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
enum cart_base_type{
	base_type_None,
	base_type_2K,
	base_type_4K,
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
	base_type_ACE
};

typedef struct {
	enum cart_base_type base_type;
	_Bool withSuperChip;
	_Bool withPlusFunctions;
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
	{"ROM", { base_type_None, FALSE, FALSE }},
	{"BIN", { base_type_None, FALSE, FALSE }},
	{"A26", { base_type_None, FALSE, FALSE }},
	{"2K",  { base_type_2K, FALSE, FALSE }},
	{"4K",  { base_type_4K, FALSE, FALSE }},
	{"F8",  { base_type_F8, FALSE, FALSE }},
	{"F6",  { base_type_F6, FALSE, FALSE }},
	{"F4",  { base_type_F4, FALSE, FALSE }},
	{"F8S", { base_type_F8, TRUE, FALSE }},
	{"F6S", { base_type_F6, TRUE, FALSE }},
	{"F4S", { base_type_F4, TRUE, FALSE }},
	{"FE",  { base_type_FE, FALSE, FALSE }},
	{"3F",  { base_type_3F, FALSE, FALSE }},
	{"3E",  { base_type_3E, FALSE, FALSE }},
	{"E0",  { base_type_E0, FALSE, FALSE }},
	{"084", { base_type_0840, FALSE, FALSE }},
	{"CV", { base_type_CV, FALSE, FALSE }},
	{"EF", { base_type_EF, FALSE, FALSE }},
	{"EFS", { base_type_EF, TRUE, FALSE }},
	{"F0", { base_type_F0, FALSE, FALSE }},
	{"FA", { base_type_FA, FALSE, FALSE }},
	{"E7", { base_type_E7, FALSE, FALSE }},
	{"DPC", { base_type_DPC, FALSE, FALSE }},
	{"AR",  { base_type_AR, FALSE, FALSE }},
	{"BF",  { base_type_BF, FALSE, FALSE }},
	{"BFS",  { base_type_BFSC, FALSE, FALSE }},
	{"ACE",  { base_type_ACE, FALSE, FALSE }},
	{"WD",  { base_type_PP, FALSE, FALSE }},
	{"DF",  { base_type_DF, FALSE, FALSE }},
	{"DFS",  { base_type_DFSC, FALSE, FALSE }},
	{0,{0,0,0}}
};

static const char status_message[][28]__attribute__((section(".flash01"))) = {
		"PlusCart(+) by W.Stubig"          ,
		"PlusCart(+) Ver. " VERSION        ,
		"PlusCart(+)"                      ,
		"Select your WiFi Network"         ,
		"No WiFi"                          ,
		"WiFi connected"                   ,
		"Request timeout"                  ,
		"Insert WiFi Password"             ,
		"Insert email or username"         ,
		"Connected, email send"            ,
		"User created, email send"         ,
		"PlusStore connect failed"         ,
		"Disconnected from PlusStore"      ,
		"Insert Secret-Key"                ,
		"Secret-Key saved"                 ,
		"Offline ROMs erased"              ,
		"ROM file too big!"                ,
		"ACE ROMs are not supported"       ,
		"Unknown/invalid ROM"              ,
		"Done"                             ,
		"Failed"                           ,
		"Firmware download failed"         ,
		"Offline ROMs detected"            ,
		"No offline ROMs detected"
};


/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart1;


/* USER CODE BEGIN PV */
int num_menu_entries = 0;
char http_request_header[512];

uint8_t buffer[BUFFER_SIZE * 1024];
unsigned int cart_size_bytes;

USER_SETTINGS user_settings;

char curPath[256];

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

void make_menu_entry( MENU_ENTRY **dst, char *name, int type){
	(*dst)->type = type;
	strcpy((*dst)->entryname, name);
	(*dst)->filesize = 0U;
	(*dst)++;
	num_menu_entries++;
}
void make_keyboard(MENU_ENTRY **dst){
	make_menu_entry(&(*dst), "(GO BACK)", Leave_Menu);
	make_menu_entry(&(*dst), "(DEL CHAR)", Delete_Keyboard_Char);
	char Key[2] = "0";
	for (char i=32; i < 100; i++){
		Key[0] = i;
		make_menu_entry(&(*dst), Key, Keyboard_Char);
	}
	make_menu_entry(&(*dst), "Enter", Menu_Action);

}

enum e_status_message buildMenuFromPath( MENU_ENTRY *d )  {
	int count = 0;
	_Bool loadStore = FALSE;
	_Bool is_entry_row;
	uint8_t pos = 0, c;
	num_menu_entries = 0;
	enum e_status_message menu_status = none;

	MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];

	if(strncmp(MENU_TEXT_SETUP, curPath, sizeof(MENU_TEXT_SETUP) - 1) == 0 ){
		//char *  curPathPos = (char *) &curPath[sizeof(MENU_TEXT_SETUP)];
		if(strlen(curPath) == sizeof(MENU_TEXT_SETUP) - 1 ){
			make_menu_entry(&dst, "(GO Back)", Leave_Menu);
			make_menu_entry(&dst, MENU_TEXT_TV_MODE_SETUP, Setup_Menu);
			make_menu_entry(&dst, MENU_TEXT_WIFI_SETUP, Setup_Menu);
			make_menu_entry(&dst, MENU_TEXT_WPS_CONNECT, Menu_Action);
			make_menu_entry(&dst, MENU_TEXT_WIFI_MANGER, Menu_Action);
			//make_menu_entry(&dst, MENU_TEXT_PRIVATE_KEY, Input_Field);
			make_menu_entry(&dst, MENU_TEXT_ESP8266_RESTORE, Menu_Action);

			if(	flash_has_downloaded_roms() )
	    		make_menu_entry(&dst, MENU_TEXT_DELETE_OFFLINE_ROMS, Menu_Action);
			else
	    		make_menu_entry(&dst, MENU_TEXT_DETECT_OFFLINE_ROMS, Menu_Action);

        	menu_status = version;
			loadStore = TRUE;
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_WIFI_SETUP, sizeof(MENU_TEXT_WIFI_SETUP) - 1) == 0 ){
			if(strlen(curPath) > sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP) ){
				if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect to WiFi
					// curPath is: MENU_TEXT_SETUP + "/" + MENU_TEXT_WIFI_SETUP + "/" SSID[33] + Password + "/Enter" + '\0'
					curPath[strlen(curPath) - 6 ] = '\0'; // delete "/Enter" at end of Path

					// TODO before we send them to esp8266 escape , " and \ in SSID and Password..
					int i = sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP);
			        while( curPath[i] != 30 && i < ( sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP) + 31) ){
			            i++;
			        }
			        curPath[i] = 0;

			    	if(esp8266_wifi_connect( &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP)  ], &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP) + 32])){
			        	menu_status = wifi_connected;
			    	}else{
			        	menu_status = wifi_not_connected;
			    	}
					curPath[0] = '\0';
				}else{
					if(d->type == Setup_Menu){
						menu_status = insert_password;
					}
					make_keyboard(&dst);
				}

			}else{
				menu_status = select_wifi_network;
				make_menu_entry(&dst, "(GO BACK)", Leave_Menu);
				if( esp8266_wifi_list( &dst, &num_menu_entries) == FALSE){
		    		return esp_timeout;
		    	}
			}
		}else if( strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_TV_MODE_SETUP, sizeof(MENU_TEXT_TV_MODE_SETUP) - 1) == 0 ){
			if(d->type == Menu_Action){
				uint8_t new_tv_mode = TV_MODE_NTSC;
				if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_PAL) == 0){
					new_tv_mode = TV_MODE_PAL;
				}else if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_PAL60) == 0){
					new_tv_mode = TV_MODE_PAL60;
				}
				set_tv_mode(new_tv_mode);
				if(user_settings.tv_mode != new_tv_mode){
					user_settings.tv_mode = new_tv_mode;
					flash_set_eeprom_user_settings(user_settings);
				}
	        	curPath[0] = '\0';
			}else{
				make_menu_entry(&dst, "(GO Back)", Leave_Menu);
				make_menu_entry(&dst, MENU_TEXT_TV_MODE_PAL, Menu_Action);
				make_menu_entry(&dst, MENU_TEXT_TV_MODE_PAL60, Menu_Action);
				make_menu_entry(&dst, MENU_TEXT_TV_MODE_NTSC, Menu_Action);
			}

		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PLUS_CONNECT, sizeof(MENU_TEXT_PLUS_CONNECT) - 1) == 0 ){
			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect user
				if( esp8266_PlusStore_API_connect() == FALSE){
					return esp_timeout;
				}
				esp8266_PlusStore_API_prepare_request_header(curPath, FALSE, TRUE );
	        	esp8266_print(http_request_header);
	        	esp8266_skip_http_response_header();
	        	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){}
	        	if(c == '0'){
	        		menu_status = plus_connect_failed;
	        	}else if(c == '1'){
	        		menu_status = plus_created;
	        	}else{
	        		menu_status = plus_connected;
	        	}

	        	esp8266_PlusStore_API_end_transmission();

	        	curPath[0] = '\0';
			}else{
				if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PLUS_CONNECT) == 0){
					menu_status = plus_connect;
				}
				make_keyboard(&dst);
			}
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PLUS_REMOVE, sizeof(MENU_TEXT_PLUS_REMOVE) - 1) == 0 ){
			if( esp8266_PlusStore_API_connect() == FALSE){
				return esp_timeout;
			}
			esp8266_PlusStore_API_prepare_request_header(curPath, FALSE, TRUE );
        	esp8266_print(http_request_header);

            esp8266_skip_http_response_header();
        	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){}
        	if(c == '0'){
        		menu_status = plus_connect_failed;
        	}else{
        		menu_status = plus_removed;
        	}

        	esp8266_PlusStore_API_end_transmission();

        	curPath[0] = '\0';

		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_OFFLINE_ROM_UPDATE, sizeof(MENU_TEXT_OFFLINE_ROM_UPDATE) - 1) == 0 ){
			if( flash_download("&r=1", d->filesize , 0 , FALSE ) != DOWNLOAD_AREA_START_ADDRESS){
		    	menu_status = download_failed;
			}else{
	    		menu_status = done;
	        	curPath[0] = '\0';
			}
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_DELETE_OFFLINE_ROMS, sizeof(MENU_TEXT_DELETE_OFFLINE_ROMS) - 1) == 0 ){
			flash_erase_storage((uint8_t)FLASH_SECTOR_5);
			user_settings.first_free_flash_sector = (uint8_t) FLASH_SECTOR_5;
		    flash_set_eeprom_user_settings(user_settings);
    		menu_status = offline_roms_deleted;
        	curPath[0] = '\0';
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_DETECT_OFFLINE_ROMS, sizeof(MENU_TEXT_DELETE_OFFLINE_ROMS) - 1) == 0 ){
			uint32_t last_address = flash_check_offline_roms_size();
			if(last_address > DOWNLOAD_AREA_START_ADDRESS + 1024){
			    user_settings.first_free_flash_sector = ((last_address - ADDR_FLASH_SECTOR_5) / 0x20000 ) + 6;
			    flash_set_eeprom_user_settings(user_settings);
	    		menu_status = offline_roms_detected;
			}else{
	    		menu_status = no_offline_roms_detected;
			}
    		num_menu_entries = 0;
        	curPath[0] = '\0';
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_WPS_CONNECT, sizeof(MENU_TEXT_WPS_CONNECT) - 1) == 0 ){
	    	if(esp8266_wps_connect()){
	        	menu_status = wifi_connected;
	    	}else{
	        	menu_status = wifi_not_connected;
	    	}
			curPath[0] = '\0';
			HAL_Delay(2000);
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_WIFI_MANGER, sizeof(MENU_TEXT_WIFI_MANGER) - 1) == 0 ){
			menu_status = done;
			esp8266_AT_WiFiManager();
	    	curPath[0] = '\0';
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_ESP8266_RESTORE, sizeof(MENU_TEXT_ESP8266_RESTORE) - 1) == 0 ){
	    	if(esp8266_reset(TRUE)){
	        	menu_status = done;
	    	}else{
	        	menu_status = failed;
	    	}
			curPath[0] = '\0';

		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PRIVATE_KEY, sizeof(MENU_TEXT_PRIVATE_KEY) - 1) == 0 ){
			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Save Private key
				menu_status = private_key_saved;
	        	curPath[0] = '\0';
			}else{
				if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PRIVATE_KEY ) == 0){
					menu_status = private_key;
				}
				make_keyboard( &dst);
			}
		}
	}else if(strncmp(MENU_TEXT_OFFLINE_ROMS, curPath, sizeof(MENU_TEXT_OFFLINE_ROMS) - 1) == 0 ){
		make_menu_entry(&dst, "..", Leave_Menu);
		flash_file_list(&curPath[sizeof(MENU_TEXT_OFFLINE_ROMS) - 1], &dst, &num_menu_entries);
	}else if(d->type == Menu_Action){
		if(strncmp(MENU_TEXT_FIRMWARE_UPDATE, curPath, sizeof(MENU_TEXT_FIRMWARE_UPDATE) - 1) == 0 ){
	    	curPath[0] = '\0';
		    strcat(curPath, (char *)"&u=1");
			uint32_t bytes_read = esp8266_PlusStore_API_file_request( buffer, curPath, 0, 0x4000 );
			bytes_read += esp8266_PlusStore_API_file_request( &buffer[0x4000], curPath, 0x8000, (d->filesize - 0x8000) );
			if(bytes_read == d->filesize - 0x4000 ){
				__disable_irq();
				HAL_FLASH_Unlock();
				flash_firmware_update(d->filesize);
			}else{
		    	menu_status = download_failed;
			}
		} else if(strncmp(MENU_TEXT_WIFI_RECONNECT, curPath, sizeof(MENU_TEXT_WIFI_RECONNECT) - 1) == 0 ){

			loadStore = TRUE;
		}

    	curPath[0] = '\0';
	}else{
		loadStore = TRUE;
	}

	// Test we should load store and if connected to AP
    if(	loadStore || strlen(curPath) == 0 ){
    	if(esp8266_is_connected() == TRUE){
			if( esp8266_PlusStore_API_connect() == FALSE){
				return esp_timeout;
			}
			esp8266_PlusStore_API_prepare_request_header(curPath, FALSE, FALSE);

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
                    if(count == 0){ // first char defines if its an entry row (or Header Row)
                    	is_entry_row = (c > '/' && c < ':' ) ? TRUE : FALSE; // First char is entry.type '0' to '9'
                        if(is_entry_row){
                        	dst->type = c - 48;
                        }
                    }else if( is_entry_row ){
                    	if(count == 1){
                            dst->filesize = 0U;
                            pos = 0;
                    	}else if( count < 8 ){ // get the filesize
                   			dst->filesize = dst->filesize * 10 + ( c -'0' );
                    	}else if( count > 8 && count < 41 && c != '\n'){ // filename/dirname should begin at index 9
                    		dst->entryname[pos] = c;
                    		pos++;
                    	}
                    }
                    if (c == '\n'){
                    	if(is_entry_row){
                    		dst->entryname[pos] = '\0';
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

    	if(menu_status == none)
    		menu_status = root;

    	make_menu_entry(&dst, MENU_TEXT_SETUP, Setup_Menu);
	}else if(strncmp(MENU_TEXT_SETUP, curPath, sizeof(MENU_TEXT_SETUP) - 1) != 0 ){
		menu_status = paging;
	}

    if(num_menu_entries == 0){
		make_menu_entry(&dst, "..", Leave_Menu);
    }

    return menu_status;
}


CART_TYPE identify_cartridge( MENU_ENTRY *d )
{

	CART_TYPE cart_type = { base_type_None, FALSE, FALSE };

	strcat(curPath, "/");
	append_entry_to_path(d);

	// Test if connected to AP
    if(d->type == Cart_File && esp8266_is_connected() == FALSE ){
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

	if(d->filesize >  (BUFFER_SIZE * 1024)){
		if(d->type == Cart_File ){
			bytes_read_tail = (uint8_t)esp8266_PlusStore_API_file_request( tail, curPath, (d->filesize - 16), 16 );
		}else{
			bytes_read_tail = (uint8_t)flash_file_request( tail, d->flash_base_address, (d->filesize - 16), 16 );
		}
		if( bytes_read_tail != 16 || bytes_read != bytes_to_read){
			cart_type.base_type = base_type_None;
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

	if (d->filesize == 2*1024)
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
	else if (d->filesize == 32*1024)
	{
		if (isProbably3E(d->filesize, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(d->filesize, buffer))
			cart_type.base_type = base_type_3F;
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
		else if (isProbablyDFSC(tail))
			cart_type.base_type = base_type_DFSC;
	}
	else if (d->filesize == 256 * 1024)
	{
		if (isProbablyBF(tail))
			cart_type.base_type = base_type_BF;
		else if (isProbablyBFSC(tail))
			cart_type.base_type = base_type_BFSC;
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
	if (cart_type.withPlusFunctions == TRUE ){
 		// Read path and hostname in ROM File from where NMI points to till '\0' and
		// copy to http_request_header
		offset = esp8266_PlusROM_API_connect(cart_size_bytes);
	}

	if (cart_type.base_type == base_type_2K)
		emulate_2k_4k_cartridge(offset, cart_type.withPlusFunctions, 0x7FF);
	else if (cart_type.base_type == base_type_4K)
		emulate_2k_4k_cartridge(offset, cart_type.withPlusFunctions, 0xFFF);
	else if (cart_type.base_type == base_type_F8)
		emulate_FxSC_cartridge(offset, cart_type.withPlusFunctions, 0x1FF8, 0x1FF9, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F6)
		emulate_FxSC_cartridge(offset, cart_type.withPlusFunctions, 0x1FF6, 0x1FF9, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F4)
		emulate_FxSC_cartridge(offset, cart_type.withPlusFunctions, 0x1FF4, 0x1FFB, cart_type.withSuperChip );
	else if (cart_type.base_type == base_type_FE)
		emulate_FE_cartridge();
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
		emulate_FxSC_cartridge(offset, cart_type.withPlusFunctions, 0x1FE0, 0x1FEF, cart_type.withSuperChip);
	else if (cart_type.base_type == base_type_F0)
		emulate_F0_cartridge();
	else if (cart_type.base_type == base_type_FA)
		emulate_FA_cartridge();
	else if (cart_type.base_type == base_type_E7)
		emulate_E7_cartridge();
	else if (cart_type.base_type == base_type_DPC)
		emulate_DPC_cartridge(cart_size_bytes);
	else if (cart_type.base_type == base_type_AR)
		emulate_supercharger_cartridge(curPath, cart_size_bytes, buffer, user_settings.tv_mode);
	else if (cart_type.base_type == base_type_PP)
		emulate_pp_cartridge( buffer + 8*1024);
	else if (cart_type.base_type == base_type_DF)
		emulate_df_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_DFSC)
		emulate_dfsc_cartridge(curPath, cart_size_bytes, buffer, d);
	else if (cart_type.base_type == base_type_BF)
		emulate_bf_cartridge(curPath, cart_size_bytes, buffer, d);//cart_type.flash_part_address);
	else if (cart_type.base_type == base_type_BFSC)
		emulate_bfsc_cartridge(curPath, cart_size_bytes, buffer, d);//cart_type.flash_part_address);
}

void truncate_curPath(){
    int len = strlen(curPath);
  	while (len && curPath[--len] != '/');
  	curPath[len] = 0;
}

void system_secondary_init(void){
	set_menu_status_byte(StatusByteReboot, 0);
	generate_udid_string();
	MX_USART1_UART_Init();
	esp8266_init();
	// set up status area
}

void append_entry_to_path(MENU_ENTRY *d){

	if(d->type == Cart_File || d->type == Sub_Menu	){
	    char encode_chars[] = " =+&#%";
	    int i = 0, t, len = strlen(d->entryname);
	    char tmp[] = "00";
	    while(i < len){
	        if(strchr(encode_chars, d->entryname[i])) {
		        t = 1;
		        uint8_t seq = (uint8_t)d->entryname[i];
	        	do {
	        		tmp[t] = (seq % 16) + '0';
	        		if (tmp[t] > '9')
	        		    tmp[t] += 7;
	        		t--;
	        		seq /= 16;
	        	} while (seq);
	            strcat(curPath, "%");
	            strcat(curPath, tmp);

	        }else{
	            strncat(curPath, &d->entryname[i], 1);
	        }
	        i++;
	    }
	}else{
		strcat(curPath, d->entryname);
	}
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
	char input_field[STATUS_MESSAGE_LENGTH + 1];

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
  while (1){
    int ret = emulate_firmware_cartridge();
    enum e_status_message menu_status = none, main_status = none;
    if (ret == CART_CMD_ROOT_DIR){
      d->type = Root_Menu;
      d->filesize = 0;

   	  system_secondary_init();

   	  input_field[0] = 0;
      curPath[0] = 0;
      menu_status = buildMenuFromPath( d );
    } else if(ret == CART_CMD_PAGE_DOWN ) {
    	act_page--;
    } else if(ret == CART_CMD_PAGE_UP ) {
    	act_page++;
    } else {
    	ret += act_page * NUM_MENU_ITEMS_PER_PAGE;
      d = &menu_entries[ret];
      if (d->type == Cart_File || d->type == Offline_Cart_File){
    	// selection is a rom file
    	uint32_t max_romsize = (((BUFFER_SIZE + CCM_RAM_SIZE) * 1024) + (12 - user_settings.first_free_flash_sector) * 128 * 1024 );
    	if(d->filesize > max_romsize ){
    		main_status = not_enough_menory;
    	}else{
    		CART_TYPE cart_type = identify_cartridge(d);
            HAL_Delay(200);
            if (cart_type.base_type == base_type_ACE){
            	main_status = romtype_unsupported;
            }else if (cart_type.base_type != base_type_None){
                emulate_cartridge(cart_type, d);
            }else{
            	main_status = romtype_unknown;
            }
    	}

    	truncate_curPath();

      } else {
        // selection is a directory or Menu_Action, or Keyboard_Char
  		if (d->type == Leave_Menu){
  		  // go back clear_curPath();//
  		  truncate_curPath();
  		  input_field[0] = 0; // Reset Keyboard input field
  		} else if(d->type == Delete_Keyboard_Char){
    		  int len = strlen(curPath);
    		  if(len && curPath[--len] != '/' ){
    	  		  curPath[len] = 0;
    		  }
    		  len = strlen((char *) input_field);
    		  if(len){
    			  input_field[--len] = 0;
    		  }
  	    	  main_status = keyboard_input;
  		} else {
  		  // go into Menu TODO find better way for separation of first keyboard char!!
  		  if(( d->type != Keyboard_Char && strlen(curPath) > 0) || strcmp(MENU_TEXT_SETUP"/"MENU_TEXT_PLUS_CONNECT, curPath) == 0 ){
    		    strcat(curPath, "/");
  		  }

  		  append_entry_to_path(d);
  		  if(d->type == Keyboard_Char){
  			  strcat((char *)input_field, d->entryname);
  			  if(strlen((char *)input_field) > STATUS_MESSAGE_LENGTH){
  	  			  for(int i = 0 ; i < STATUS_MESSAGE_LENGTH; i++){
  	  				input_field[i] = input_field[i + 1];
  	  			  }
  			  }
  	    	  main_status = keyboard_input;
  		  }else if(d->type == Menu_Action){
  			input_field[0] = 0;
  		  }
  	    }
  		menu_status = buildMenuFromPath( d );
      }
    }

    // Menu status message and PageType byte
    main_status = (main_status != none)?main_status:menu_status;
    if(main_status == keyboard_input){
    	set_menu_status_msg((char *)input_field);
    	set_menu_status_byte((uint8_t)PageType, (char)Keyboard);
    }else{
    	if(main_status != none){
        	set_menu_status_msg(status_message[main_status]);
    	}
    	if(act_page > (num_menu_entries / NUM_MENU_ITEMS_PER_PAGE) ){
    		act_page = 0;
    	}
    	set_menu_status_byte(PageType, Directory);
    }
    _Bool paging_required = (main_status == paging);
    _Bool is_connected = esp8266_is_connected();

    createMenuForAtari( menu_entries, act_page, num_menu_entries, paging_required, is_connected, plus_store_status );
    HAL_Delay(200);
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
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
