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
#include <ctype.h>
#include <string.h>

#include "stm32_udid.h"
#include "esp8266.h"
#include "cartridge_io.h"
#include "cartridge_firmware.h"
#include "cartridge_detection.h"
#include "cartridge_emulation.h"

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

EXT_TO_CART_TYPE_MAP ext_to_cart_type_map[]__attribute__((section(".ccmram"))) = {
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
	{0,{0,0,0}}
};

#define HTTP_REQUEST_CHUNK_PARAM_POS  15

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart1;

/* USER CODE BEGIN PV */
uint8_t buffer[BUFFER_SIZE * 1024];
char stm32_udid[] = UDID_TEMPLATE;         // 3*32 bit + \0

char curPath[256]__attribute__((section(".ccmram")));

unsigned int cart_size_bytes;
int tv_mode;
uint8_t c;

extern FLASH_ProcessTypeDef pFlash;

#define  API_ATCMD_1  "AT+CIPSTART=\"TCP\",\"pluscart.firmaplus.de\",80\r\n"
#define  API_ATCMD_2  "AT+CIPSEND\r\n"
#define  API_ATCMD_3  "GET /api.php?c=0&p="
#define  API_ATCMD_4  " HTTP/1.0\r\nHost: pluscart.firmaplus.de\r\nPlusStore-ID: v" VERSION " "
#define  API_ATCMD_5  "\r\nConnection: keep-alive\r\n\r\n"
uint8_t  ATCMD6[] = "+++";
uint8_t http_request_header[512]__attribute__((section(".ccmram")));


/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void);
/* USER CODE BEGIN PFP */

HAL_StatusTypeDef FLASH_WaitInRAMForLastOperationWithMaxDelay() __attribute__((section(".data#")));
void do_firmware_update(uint32_t filesize, uint8_t *http_request_header)__attribute__((section(".data#")));
_Bool prepare_PlusStore_API_request(char *);
void skip_http_header();


/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

void skip_http_header(){
	int count = 0;
	while(HAL_UART_Receive(&huart1, &c, 1, 5000 ) == HAL_OK){
       	if( c == '\n' ){
       		if (count == 1)
       			break;
       		count = 0;
       	}else{
       		count++;
       	}
	}
}

_Bool prepare_PlusStore_API_request(char *path){


    if(HAL_UART_Transmit(&huart1, (uint8_t *) API_ATCMD_1, sizeof(API_ATCMD_1)-1, 10) != HAL_OK)
		return FALSE;

    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK);


/*
    if(_esp8266_wait_response(100) != ESP8266_CONNECT || ESP8266_Allready_CONNECTed){
		return FALSE;
	}
    if(_esp8266_wait_response(100) != ESP8266_OK  and ESP826_> ){
		return FALSE;
	}
*/

    if(HAL_UART_Transmit(&huart1, (uint8_t *) API_ATCMD_2, sizeof(API_ATCMD_2)-1, 10) != HAL_OK)
		return FALSE;

    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK);


    // make path http request ready
    for (char* p = path; (p = strchr(p, ' ')); ++p) {
        *p = '+';
    }

    http_request_header[0] = '\0';

    strcat((char *)http_request_header, API_ATCMD_3);
    strcat((char *)http_request_header, path);
    strcat((char *)http_request_header, API_ATCMD_4);
    strcat((char *)http_request_header, stm32_udid);
    strcat((char *)http_request_header, API_ATCMD_5);

    return TRUE;
}

HAL_StatusTypeDef FLASH_WaitInRAMForLastOperationWithMaxDelay()
{
  /* Wait for the FLASH operation to complete by polling on BUSY flag to be reset.
     Even if the FLASH operation fails, the BUSY flag will be reset and an error
     flag will be set */
  while(__HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY) != RESET)
  {
  }

  /* Check FLASH End of Operation flag  */
  if (__HAL_FLASH_GET_FLAG(FLASH_FLAG_EOP) != RESET)
  {
    /* Clear FLASH End of Operation pending bit */
    __HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_EOP);
  }
#if defined(FLASH_SR_RDERR)
  if(__HAL_FLASH_GET_FLAG((FLASH_FLAG_OPERR | FLASH_FLAG_WRPERR | FLASH_FLAG_PGAERR | \
                           FLASH_FLAG_PGPERR | FLASH_FLAG_PGSERR | FLASH_FLAG_RDERR)) != RESET)
#else
  if(__HAL_FLASH_GET_FLAG((FLASH_FLAG_OPERR | FLASH_FLAG_WRPERR | FLASH_FLAG_PGAERR | \
                           FLASH_FLAG_PGPERR | FLASH_FLAG_PGSERR)) != RESET)
#endif /* FLASH_SR_RDERR */
  {
    /*Save the error code*/
    return HAL_ERROR;
  }

  /* If there is no error flag set */
  return HAL_OK;

}


void do_firmware_update(uint32_t filesize, uint8_t *http_request_header){

	uint32_t Address = ADDR_FLASH_SECTOR_0;
	uint32_t count=0;
	HAL_StatusTypeDef status;


	//HAL_FLASHEx_Erase();
	// Process Locked
	// __HAL_LOCK(&pFlash);
	pFlash.Lock = HAL_LOCKED;

	// Wait for last operation to be completed
	if(FLASH_WaitInRAMForLastOperationWithMaxDelay() == HAL_OK)
	{
	      for( count = FLASH_SECTOR_0; count < FLASH_SECTOR_6; count++)
	      {
//	        FLASH_Erase_Sector(count, (uint8_t) FLASH_VOLTAGE_RANGE_3);
	    	  CLEAR_BIT(FLASH->CR, FLASH_CR_PSIZE);
	    	  FLASH->CR |= FLASH_PSIZE_WORD;
	    	  CLEAR_BIT(FLASH->CR, FLASH_CR_SNB);
	    	  FLASH->CR |= FLASH_CR_SER | (count << FLASH_CR_SNB_Pos);
	    	  FLASH->CR |= FLASH_CR_STRT;

	        /* Wait for last operation to be completed */
	        status = FLASH_WaitInRAMForLastOperationWithMaxDelay();

	        /* If the erase operation is completed, disable the SER and SNB Bits */
	        CLEAR_BIT(FLASH->CR, (FLASH_CR_SER | FLASH_CR_SNB));

	        if(status != HAL_OK)
	        {
	          /* In case of error, stop erase procedure and return the faulty sector*/
	          break;
	        }
	      }


	}else{
		return; // or try flashing anyway ??
	}

	  /* Process Unlocked */
	  __HAL_UNLOCK(&pFlash);

//end HAL_FLASHEx_Erase();

	    /* Flush the caches to be sure of the data consistency */
	  __HAL_FLASH_DATA_CACHE_DISABLE();
	  __HAL_FLASH_INSTRUCTION_CACHE_DISABLE();

	  __HAL_FLASH_DATA_CACHE_RESET();
	  __HAL_FLASH_INSTRUCTION_CACHE_RESET();

	  __HAL_FLASH_INSTRUCTION_CACHE_ENABLE();
	  __HAL_FLASH_DATA_CACHE_ENABLE();


	  //__HAL_LOCK(&pFlash);

	  pFlash.Lock = HAL_LOCKED;
		FLASH_WaitInRAMForLastOperationWithMaxDelay();

	  uint8_t chunks = ( filesize + 4095 )  / 4096;         //  use Real HTTP Range requests??
	    uint16_t lastChunkSize = filesize % 4096;
	    while(chunks != 0 ){
	    	count = 0;
			while(1){ // todo set and break on timeout ?
				if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
					huart1.Instance->DR = http_request_header[count++]; // & (uint8_t)0xFF);
					if(http_request_header[count] == '\0')
						break;
				}
			}
	    	count = 0;

	    	// Skip HTTP Header
	    	while(1){ // todo set and break on timeout ?
                if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                    c = (uint8_t)huart1.Instance->DR; // & (uint8_t)0xFF);
					if( c == '\n' ){
						if (count == 1)
							break;
						count = 0;
					}else{
						count++;
					}
                }
	    	}

	    	// Now for the HTTP Body
			count = 0;
	    	while(count < 4096 && (chunks != 1 || count < lastChunkSize )){
                if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                    c = (uint8_t)huart1.Instance->DR; // & (uint8_t)0xFF);

//HAL_FLASH_Program();
                    /* Program the user Flash area byte by byte
					(area defined by FLASH_USER_START_ADDR and FLASH_USER_END_ADDR) ***********/

                    /* Wait for last operation to be completed */
                    if(FLASH_WaitInRAMForLastOperationWithMaxDelay() == HAL_OK)
                    {
                        /*Program byte (8-bit) at a specified address.*/
                        // FLASH_Program_Byte(Address, (uint8_t) c);
                        CLEAR_BIT(FLASH->CR, FLASH_CR_PSIZE);
                        FLASH->CR |= FLASH_PSIZE_BYTE;
                        FLASH->CR |= FLASH_CR_PG;

                        *(__IO uint8_t*)Address = c;
                        // end FLASH_Program_Byte(Address, (uint8_t) c);

                      /* Wait for last operation to be completed */
                      FLASH_WaitInRAMForLastOperationWithMaxDelay();

                      /* If the program operation is completed, disable the PG Bit */
                      FLASH->CR &= (~FLASH_CR_PG);
					  Address++;
					  // end HAL_FLASH_Program
                    }else{
                    	return;
                    }
					count++;
                }
	    	}

	    	chunks--;
	    	http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS]++;
	    	if(http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS] == 58)
	    		http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS] = 65;
	    	else if(http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS] == 91)
	    		http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS] = 97;

	    	count = 0;
	    	while(count++ < 20000000){

	    	} // won't work at __disable_irq(); !!

	    	count = 0;
	    }
        __HAL_UNLOCK(&pFlash);

        // End Transparent Transmission
    	count = 0;
		while(1){ // todo set and break on timeout ?
			if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
				huart1.Instance->DR = ATCMD6[count++]; // & (uint8_t)0xFF);
				if(ATCMD6[count] == '\0')
					break;
			}
		}

//		while(HAL_UART_Receive(&huart1, &c,1, 100 ) == HAL_OK){	}
		__enable_irq();
		NVIC_SystemReset();

}


/*************************************************************************
 * Menu Handling
 *************************************************************************/

MENU_ENTRY menu_entries[NUM_MENU_ITEMS ]__attribute__((section(".ccmram")));

int num_menu_entries = 0; // how many entries in the current menu

char *get_filename_ext(char *filename) {
	char *dot = strrchr(filename, '.');
	if(!dot || dot == filename) return "";
	return dot + 1;
}

int is_valid_file(char *filename) {
	char *ext = get_filename_ext(filename);
	EXT_TO_CART_TYPE_MAP *p = ext_to_cart_type_map;
	while (p->ext) {
		if (strcasecmp(ext, p->ext) == 0)
			return 1;
		p++;
	}
	return 0;
}

void make_menu_entry( MENU_ENTRY *dst, char *name, int type){
	dst->type = type;
	strcpy(dst->entryname, name);
	dst->filesize = 0U;
	num_menu_entries++;
	dst++;
}

void buildMenuFromPath( MENU_ENTRY *d )  {
	int count = 0;
	_Bool loadStore = FALSE;
	_Bool is_entry_row;
	uint8_t pos = 0;
	num_menu_entries = 0;

	MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];

	if(strncmp(MENU_TEXT_SETUP, curPath, sizeof(MENU_TEXT_SETUP) - 1) == 0 ){
		if(strlen(curPath) == sizeof(MENU_TEXT_SETUP) - 1 ){
			MAKE_MENU_ENTRY("(GO Back)", Leave_Menu);
			MAKE_MENU_ENTRY(MENU_TEXT_WIFI_SETUP, Sub_Menu);
			MAKE_MENU_ENTRY(MENU_TEXT_TV_MODE_SETUP, Sub_Menu);
			MAKE_MENU_ENTRY(MENU_TEXT_PRIVATE_KEY, Sub_Menu);
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

			        // TODO esp8266_connect((unsigned char*) &curPath[sizeof(MENU_TEXT_WIFI_SETUP) ], (unsigned char*) &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + 32]);

			    	http_request_header[0] = 0;
			        strcat((char *)http_request_header, "AT+CWJAP=\"");
			        strcat((char *)http_request_header, &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + sizeof(MENU_TEXT_SETUP) ]);     // skip MENU_TEXT_WIFI_SETUP + "/"
			        strcat((char *)http_request_header, "\",\"");
			        strcat((char *)http_request_header, &curPath[sizeof(MENU_TEXT_WIFI_SETUP)  + sizeof(MENU_TEXT_SETUP) + 32]); // skip MENU_TEXT_WIFI_SETUP + "/" SSID[33]
			        strcat((char *)http_request_header, "\"\r\n");
			    	HAL_UART_Transmit(&huart1, http_request_header, strlen((char *)http_request_header), 50);
			    	if(_esp8266_wait_response(10000) == ESP8266_OK){
			        	set_menu_status_msg(STATUS_MESSAGE_WIFI_CONNECTED);
			    	}else{
			        	set_menu_status_msg(STATUS_MESSAGE_WIFI_NOT_CONNECTED);
			    	}

					curPath[0] = '\0';
				}else{
					MAKE_MENU_ENTRY("(GO BACK)", Leave_Menu); // TODO Delete last Char not all
					char Key[2] = "0";
					for (char i=32; i < 96; i++){
						Key[0] = i;
						MAKE_MENU_ENTRY(Key, Keyboard_Char);
					}

					MAKE_MENU_ENTRY("Enter", Menu_Action);
				}

			}else{
				MAKE_MENU_ENTRY("(GO BACK)", Leave_Menu);
				uint8_t  ATCMD1[]  = "AT+CWLAP\r\n";
		        if( HAL_UART_Transmit(&huart1, ATCMD1, sizeof(ATCMD1)-1, 10) != HAL_OK){
		        	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
		    		return;
		    	}
		        //enum ssid_name_stauts{in_name, char_escaped };
		    	if(HAL_UART_Receive(&huart1, &c, 1, 4000 ) == HAL_OK){
			    	do{
			            if(count == 0){ // first char defines if its an entry row with SSID or Header Row
			            	is_entry_row = (c == '+' ) ? 1 : 0;
			                dst->type = Sub_Menu;
			                dst->filesize = 0U;
			                pos=0;
			                while(pos < 32){
			                	dst->entryname[pos++] = 30; // ASCII record separator 32x illegal SSID Char..
			                }
	                        dst->entryname[32] = '\0';
			                pos = 0;
			            }else if( is_entry_row ){
			            	if( count > 10 && count < 43 ){ // Wifi
			            		if (c == '"'){ // TODO howto find not escaped " , and \ in ESP8266 CWLAP response !!
			                        dst++;
			                        num_menu_entries++;
			                        count = 43; // ugly
			            		}else{
			            			dst->entryname[pos++] = c;
			            		}
			            	}
			            }
			            if (c == '\n'){
			                count = 0;
			            }else{
			                count++;
			            }
			    	}while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK);
		    	}
			}
		}else if( strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_TV_MODE_SETUP, sizeof(MENU_TEXT_TV_MODE_SETUP) - 1) == 0 ){
			if(d->type == Menu_Action){
				HAL_FLASH_Unlock();
				if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_PAL) == 0){
					set_tv_mode(TV_MODE_PAL);
					if(tv_mode != TV_MODE_PAL){
						FLASH_Erase_Sector(FLASH_SECTOR_11, (uint8_t) FLASH_VOLTAGE_RANGE_3); // TODO use User-Option Bytes for TV Mode (0x1FFF C000) bits 0-1 are unused, but don't change RDP, BOR WDG and RST!
						HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_CONFIG_ADDRESS, ((uint32_t)TV_MODE_PAL) );
					}
					tv_mode = TV_MODE_PAL;
				}else if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_PAL60) == 0){
					set_tv_mode(TV_MODE_PAL60);
					if(tv_mode != TV_MODE_PAL60){
						FLASH_Erase_Sector(FLASH_SECTOR_11, (uint8_t) FLASH_VOLTAGE_RANGE_3);
						HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_CONFIG_ADDRESS, ((uint32_t)TV_MODE_PAL60) );
					}
					tv_mode = TV_MODE_PAL60;
				}else{ // if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP) + sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_NTSC) == 0)
					set_tv_mode(TV_MODE_NTSC);
					if(tv_mode != TV_MODE_NTSC){
						FLASH_Erase_Sector(FLASH_SECTOR_11, (uint8_t) FLASH_VOLTAGE_RANGE_3);
						HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_CONFIG_ADDRESS, ((uint32_t)TV_MODE_NTSC) );
					}
					tv_mode = TV_MODE_NTSC;
				}
				HAL_FLASH_Lock();
	        	curPath[0] = '\0';
			}else{
				MAKE_MENU_ENTRY("(GO Back)", Leave_Menu);
				MAKE_MENU_ENTRY(MENU_TEXT_TV_MODE_PAL, Menu_Action);
				MAKE_MENU_ENTRY(MENU_TEXT_TV_MODE_PAL60, Menu_Action);
				MAKE_MENU_ENTRY(MENU_TEXT_TV_MODE_NTSC, Menu_Action);
			}

		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_USER_SETUP, sizeof(MENU_TEXT_USER_SETUP) - 1) == 0 ){
			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect user
				if( prepare_PlusStore_API_request(curPath) == FALSE){
	            	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
					return;
				}
	        	HAL_UART_Transmit(&huart1, http_request_header, strlen((char *)http_request_header), 50);

	        	while(HAL_UART_Receive(&huart1, &c,1, 400 ) == HAL_OK){}
	        	if(c == '0')
	        		set_menu_status_msg(STATUS_MESSAGE_USER_CONNECT_FAILED);
	        	else
	        		set_menu_status_msg(STATUS_MESSAGE_USER_CONNECTED);

	        	if( HAL_UART_Transmit(&huart1, ATCMD6, sizeof(ATCMD6)-1, 10) != HAL_OK){
	            	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
	        		return;
	        	}
	        	while(HAL_UART_Receive(&huart1, &c,1, 100 ) == HAL_OK){
	        	}

	        	curPath[0] = '\0';
			}else{
				if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_USER_SETUP) == 0){
					set_menu_status_msg(STATUS_MESSAGE_USER_CONNECT);
				}

				MAKE_MENU_ENTRY("(GO BACK)", Leave_Menu); // TODO Delete last Char or All?
				char Key[2] = "0";
				for (char i=32; i < 96; i++){
					Key[0] = i;
					MAKE_MENU_ENTRY(Key, Keyboard_Char);
				}
				MAKE_MENU_ENTRY("Enter", Menu_Action);
			}
		}else if(strncmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PRIVATE_KEY, sizeof(MENU_TEXT_PRIVATE_KEY) - 1) == 0 ){
			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Save Private key
				set_menu_status_msg(STATUS_MESSAGE_PRIVATE_KEY_SAVED);

	        	curPath[0] = '\0';
			}else{
				if(strcmp(&curPath[sizeof(MENU_TEXT_SETUP)], MENU_TEXT_PRIVATE_KEY ) == 0){
					set_menu_status_msg(STATUS_MESSAGE_PRIVATE_KEY);
				}

				MAKE_MENU_ENTRY("(GO BACK)", Leave_Menu); // TODO Delete last Char or All?
				char Key[2] = "0";
				for (char i=32; i < 96; i++){
					Key[0] = i;
					MAKE_MENU_ENTRY(Key, Keyboard_Char);
				}
				MAKE_MENU_ENTRY("Enter", Menu_Action);
			}
		}
	}else if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action..
		if(strncmp(MENU_TEXT_FIRMWARE_UPDATE, curPath, sizeof(MENU_TEXT_FIRMWARE_UPDATE) - 1) == 0 ){

			if( prepare_PlusStore_API_request("&u=1") == FALSE){
		    	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
			}
			__disable_irq();  // Disable interrupts
			HAL_FLASH_Unlock();
			// do Flashing in ram !!
			do_firmware_update(d->filesize, http_request_header);
		}
    	curPath[0] = '\0';
	}else{
		loadStore = TRUE;
	}

	// Test we should load store and if connected to AP
    if(	loadStore || strlen(curPath) == 0 ){
    	if(esp8266_is_connected() == TRUE){
			if( prepare_PlusStore_API_request(curPath) == FALSE){
            	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
				return;
			}

            HAL_UART_Transmit(&huart1, http_request_header, strlen((char *)http_request_header), 50);
        	count = 0;
        	skip_http_header();
        	while(HAL_UART_Receive(&huart1, &c, 1, 400 ) == HAL_OK){
        		if(num_menu_entries < NUM_MENU_ITEMS){
                    if(count == 0){ // first char defines if its an entry row (or Header Row) and dir or file
                    	is_entry_row = (c > '/' && c < ':' ) ? TRUE : FALSE; // First Char is '0' to '9'
                        if(is_entry_row){
                        	dst->type = c - 48;
                        }
                    }else if( is_entry_row ){
                    	if(count == 1){
                            dst->filesize = 0U;
                            pos = 0;
                    	}else if( count < 8 ){ // get the filesize !
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
        	}

        	if( HAL_UART_Transmit(&huart1, ATCMD6, sizeof(ATCMD6)-1, 10) != HAL_OK){
            	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
        		return;
        	}
        	while(HAL_UART_Receive(&huart1, &c,1, 100 ) == HAL_OK){
        	}

        }else {
        	set_menu_status_msg(STATUS_MESSAGE_WIFI_NOT_CONNECTED);
    	}

    }

    if(strlen(curPath) == 0){
		MAKE_MENU_ENTRY(MENU_TEXT_SETUP, Sub_Menu);
	}
}

CART_TYPE identify_cartridge( MENU_ENTRY *d )
{


	unsigned int image_size = 0;
	CART_TYPE cart_type = { base_type_None, FALSE, FALSE };

	strcat(curPath, "/");
    strcat(curPath, d->entryname);

	// Test if connected to AP
    if(esp8266_is_connected() == FALSE){
    	return cart_type;
    }

	if( prepare_PlusStore_API_request(curPath) == FALSE){
    	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
		return cart_type;
	}

    uint8_t chunks = ( d->filesize + 4095 )  / 4096;         //  use Real HTTP Range requests??
    while(chunks != 0 ){
    	if(HAL_UART_Transmit(&huart1, http_request_header, strlen((char *)http_request_header), 50)!= HAL_OK){
    	}

    	skip_http_header();

    	// Now for the HTTP Body
    	while(HAL_UART_Receive(&huart1, &c, 1, 400 ) == HAL_OK){
            	buffer[image_size++] = c;
    	}
    	chunks--;
    	http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS]++;
    	HAL_Delay(200);
    }

    // End Transparent Transmission
    if( HAL_UART_Transmit(&huart1, ATCMD6, sizeof(ATCMD6) - 1, 10) != HAL_OK){
	}
	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){
	}

	// select type by file extension?
	char *ext = get_filename_ext(curPath);
	EXT_TO_CART_TYPE_MAP *p = ext_to_cart_type_map;
	while (p->ext) {
		if (strcasecmp(ext, p->ext) == 0) {
			cart_type = p->cart_type;
			break;
		}
		p++;
	}


    // disconnect here or if cart_type != CART_TYPE_NONE
	if (cart_type.base_type != base_type_None) goto close;

	// If we don't already know the type (from the file extension), then we
	// auto-detect the cart type - largely follows code in Stella's CartDetector.cpp

	cart_type.withPlusFunctions = isProbablyPLS(image_size, buffer);
	cart_type.withSuperChip =  isProbablySC(image_size, buffer);


	if (image_size == 2*1024)
	{
		if (isProbablyCV(image_size, buffer))
			cart_type.base_type = base_type_CV;
		else
			cart_type.base_type = base_type_2K;
	}
	else if (image_size == 4*1024)
	{
		cart_type.base_type = base_type_4K;
	}
	else if (image_size == 8*1024)
	{
		// First check for *potential* F8
		int f8 = isPotentialF8(image_size, buffer);

		if (memcmp(buffer, buffer + 4096, 4096) == 0)
			cart_type.base_type = base_type_4K;
		else if (isProbablyE0(image_size, buffer))
			cart_type.base_type = base_type_E0;
		else if (isProbably3E(image_size, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(image_size, buffer))
			cart_type.base_type = base_type_3F;
		else if (isProbablyFE(image_size, buffer) && !f8)
			cart_type.base_type = base_type_FE;
		else if (isProbably0840(image_size, buffer))
			cart_type.base_type = base_type_0840;
		else
			cart_type.base_type = base_type_F8;
	}
	else if(image_size >= 10240 && image_size <= 10496)
	{  // ~10K - Pitfall II
		cart_type.base_type = base_type_DPC;
	}
	else if (image_size == 12*1024)
	{
		cart_type.base_type = base_type_FA;
	}
	else if (image_size == 16*1024)
	{
		if (isProbablyE7(image_size, buffer))
			cart_type.base_type = base_type_E7;
		else if (isProbably3E(image_size, buffer))
			cart_type.base_type = base_type_3E;
		else
			cart_type.base_type = base_type_F6;
	}
	else if (image_size == 32*1024)
	{
		if (isProbably3E(image_size, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(image_size, buffer))
			cart_type.base_type = base_type_3F;
		else
			cart_type.base_type = base_type_F4;
	}
	else if (image_size == 64*1024)
	{
		if (isProbably3E(image_size, buffer))
			cart_type.base_type = base_type_3E;
		else if (isProbably3F(image_size, buffer))
			cart_type.base_type = base_type_3F;
		else if (isProbablyEF(image_size, buffer))
			cart_type.base_type = base_type_EF;
		else
			cart_type.base_type = base_type_F0;
	}

	close:

	if (cart_type.base_type != base_type_None)
		cart_size_bytes = image_size;

  int len = strlen(curPath);
	while (len && curPath[--len] != '/');
	curPath[len] = 0;


	return cart_type;
}




/*************************************************************************
 * Main loop/helper functions
 *************************************************************************/

void emulate_cartridge(CART_TYPE cart_type)
{
	int offset = 0;
	if (cart_type.withPlusFunctions == TRUE ){
 		// Read Path and Hostname in ROM File from 0xf00  till '\0' and
		// copy to http_request_header offset for Content-Length pos isn't
		// a defined constant anymore .. (CONTENT_LENGTH_POSITION_IN_REQUEST_HEADER)
		offset = strlen((char *)buffer) + 1;

		http_request_header[0] = '\0';
		strcat((char *)http_request_header, (char *)"AT+CIPSTART=\"TCP\",\"");
        strcat((char *)http_request_header, (char *)&buffer[offset]);
        strcat((char *)http_request_header, (char *)"\",80\r\n");

        HAL_UART_Transmit(&huart1, (uint8_t*) http_request_header, strlen((char *)http_request_header), 50);
	    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){ }

		http_request_header[0] = '\0';
		strcat((char *)http_request_header, (char *)"POST /");
        strcat((char *)http_request_header, (char *)buffer);
        strcat((char *)http_request_header, (char *)" HTTP/1.0\r\nHost: ");
        strcat((char *)http_request_header, (char *)&buffer[offset]);
        strcat((char *)http_request_header, (char *)"\r\nConnection: keep-alive\r\nContent-Type: application/octet-stream\r\nPlusStore-ID: v" VERSION " ");
        strcat((char *)http_request_header, (char *)stm32_udid);
        strcat((char *)http_request_header, (char *)"\r\nContent-Length:    \r\n\r\n");
        offset = strlen((char *)http_request_header);

        HAL_UART_Transmit(&huart1, (uint8_t*) API_ATCMD_2, sizeof(API_ATCMD_2)-1, 10);
	    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){ }
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
		emulate_DPC_cartridge();
	else if (cart_type.base_type == base_type_AR) {
		// emulate_supercharger_cartridge(cartridge_image_path, cart_size_bytes, buffer, tv_mode);
	}
}

void convertMenuNameForCart(unsigned char *dst, char *src)
{
	memset(dst, ' ', 12);
	for (int i=0; i<12; i++) {
		if (!src[i]) break;
		dst[i] = toupper(src[i]);
	}
}

void createMenuForAtari( MENU_ENTRY *d )
{
	buildMenuFromPath( d);
	uint8_t *menu_ram = get_menu_ram();
	// create a table of entries for the atari to read
	memset(menu_ram, 0, NUM_MENU_ITEMS_MEM);
	for (int i=0; i<num_menu_entries; i++)
	{
		unsigned char *dst = menu_ram + i*12;
		convertMenuNameForCart(dst, menu_entries[i].entryname);
		// set the high-bit of the first character if Submenu or Upmenu
		if (menu_entries[i].type == Sub_Menu || menu_entries[i].type == Leave_Menu) *dst += 0x80;
	}
}

void generate_udid_string(){
	int i;
	for (int j = 2; j > -1; j--){
		uint32_t content_len = STM32_UDID[j];
		i = (j * 8) + 7;
		while (content_len != 0 && i > -1) {
			c = content_len % 16;
			stm32_udid[i--] = (c > 9)? (c-10) + 'a' : c + '0';
			content_len = content_len/16;
		}
	}
	//stm32_udid[24] = '\0'; // this seems to necessary ?
}


/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

	curPath[0] = '\0';
	CART_TYPE cart_type = { base_type_None, FALSE, FALSE };
	_Bool usart_not_init = TRUE;

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
  //  MX_USART1_UART_Init(); /* USART1_Init is done later at before  wifi init
  /* USER CODE BEGIN 2 */

  tv_mode = *(__IO uint32_t*)FLASH_CONFIG_ADDRESS > TV_MODE_PAL60 ? TV_MODE_NTSC : *(__IO uint32_t*)FLASH_CONFIG_ADDRESS;
  set_tv_mode(tv_mode);

  // set up status area
  set_menu_status_msg("BY W.STUBIG ");
  set_menu_status_byte(0);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1){
    int ret = emulate_firmware_cartridge();
    if (ret == CART_CMD_ROOT_DIR || ret >= num_menu_entries){

    	MENU_ENTRY d;
    	d.type = Root_Menu;
    	d.filesize = 0;

      if(usart_not_init){
    	  MX_USART1_UART_Init();
    	  Initialize_ESP8266();
    	  generate_udid_string();
		  usart_not_init = FALSE;
      }
      buffer[0] = 0;
      curPath[0] = 0;
      createMenuForAtari(&d);
      if(ret != CART_CMD_ROOT_DIR && ret >= num_menu_entries){
          set_menu_status_msg("erorr r>n   ");
      }

    } else {
      MENU_ENTRY *d = &menu_entries[ret];
      if (d->type == Cart_File){
    	  // selection is a rom file
        cart_type = identify_cartridge(d);
        HAL_Delay(200);
        if (cart_type.base_type != base_type_None){
            emulate_cartridge(cart_type);
        }
      } else {
        // selection is a directory or Menu_Action, or Keyboard_Char
  		if (d->type == Leave_Menu){
  		  // go back
  		  int len = strlen(curPath);
  		  while (len && curPath[--len] != '/');
  		  curPath[len] = 0;
  		} else {
  		  // go into Menu TODO find better way for separation of first keyboard char!!
  		  if(( d->type != Keyboard_Char && strlen(curPath) > 0) || strcmp(MENU_TEXT_SETUP"/"MENU_TEXT_USER_SETUP, curPath) == 0 ){
    		    strcat(curPath, "/");
  		  }

  		  strcat(curPath, d->entryname);
  		  if(d->type == Keyboard_Char){
  			  strcat((char *)buffer, d->entryname);
  			  if(strlen((char *)buffer) > 12){
  	  			  for(int i = 0 ; i < 13; i++){
  	  				  buffer[i] = buffer[i + 1];
  	  			  }
  			  }
  	    	set_menu_status_msg((char *)buffer);
  		  }else if(d->type == Menu_Action){
  		      buffer[0] = 0;
  		  }
  	    }

          createMenuForAtari( d);
          HAL_Delay(200);
      }
    }
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
  __HAL_RCC_GPIOC_CLK_ENABLE();
//  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
// __HAL_RCC_GPIOA_CLK_ENABLE();

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
