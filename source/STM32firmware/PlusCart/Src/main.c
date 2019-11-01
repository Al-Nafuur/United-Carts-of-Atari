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

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

EXT_TO_CART_TYPE_MAP ext_to_cart_type_map[]__attribute__((section(".ccmram"))) = {
	{"ROM", CART_TYPE_NONE},
	{"BIN", CART_TYPE_NONE},
	{"A26", CART_TYPE_NONE},
	{"2K", CART_TYPE_2K},
	{"4K", CART_TYPE_4K},
	{"F8", CART_TYPE_F8},
	{"F6", CART_TYPE_F6},
	{"F4", CART_TYPE_F4},
	{"F8S", CART_TYPE_F8SC},
	{"F6S", CART_TYPE_F6SC},
	{"F4S", CART_TYPE_F4SC},
	{"FE", CART_TYPE_FE},
	{"3F", CART_TYPE_3F},
	{"3E", CART_TYPE_3E},
	{"E0", CART_TYPE_E0},
	{"084", CART_TYPE_0840},
	{"CV", CART_TYPE_CV},
	{"EF", CART_TYPE_EF},
	{"EFS", CART_TYPE_EFSC},
	{"F0", CART_TYPE_F0},
	{"FA", CART_TYPE_FA},
	{"E7", CART_TYPE_E7},
	{"DPC", CART_TYPE_DPC},
	{"AR", CART_TYPE_AR},
	{"PLS", CART_TYPE_PLUS},
	{"P32", CART_TYPE_PLUS32},
	{0,0}
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
#define  API_ATCMD_4  " HTTP/1.0\r\nHost: pluscart.firmaplus.de\r\nUser-Agent: PlusCart/v" VERSION " "
#define  API_ATCMD_5  "\r\nConnection: keep-alive\r\n\r\n"
uint8_t  ATCMD6[] = "+++";
uint8_t http_request_header[512]__attribute__((section(".ccmram")));


/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART1_UART_Init(void);
/* USER CODE BEGIN PFP */

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

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */


/*************************************************************************
 * Menu Handling
 *************************************************************************/

#define NUM_MENU_ITEMS	80


MENU_ENTRY menu_entries[NUM_MENU_ITEMS]__attribute__((section(".ccmram")));

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


HAL_StatusTypeDef FLASH_WaitInCCMRAMForLastOperationWithMaxDelay() __attribute__((section(".data#")));
HAL_StatusTypeDef FLASH_WaitInCCMRAMForLastOperationWithMaxDelay()
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


void do_firmware_update(uint32_t filesize, uint8_t *http_request_header)__attribute__((section(".data#")));
void do_firmware_update(uint32_t filesize, uint8_t *http_request_header){

	uint32_t Address = ADDR_FLASH_SECTOR_0;
	uint32_t count=0;
	HAL_StatusTypeDef status;


	//HAL_FLASHEx_Erase();
	// Process Locked
	// __HAL_LOCK(&pFlash);
	pFlash.Lock = HAL_LOCKED;

	// Wait for last operation to be completed
	if(FLASH_WaitInCCMRAMForLastOperationWithMaxDelay() == HAL_OK)
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
	        status = FLASH_WaitInCCMRAMForLastOperationWithMaxDelay();

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
		FLASH_WaitInCCMRAMForLastOperationWithMaxDelay();

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
                    if(FLASH_WaitInCCMRAMForLastOperationWithMaxDelay() == HAL_OK)
                    {
                        /*Program byte (8-bit) at a specified address.*/
                        // FLASH_Program_Byte(Address, (uint8_t) c);
                        CLEAR_BIT(FLASH->CR, FLASH_CR_PSIZE);
                        FLASH->CR |= FLASH_PSIZE_BYTE;
                        FLASH->CR |= FLASH_CR_PG;

                        *(__IO uint8_t*)Address = c;
                        // end FLASH_Program_Byte(Address, (uint8_t) c);

                      /* Wait for last operation to be completed */
                      FLASH_WaitInCCMRAMForLastOperationWithMaxDelay();

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

void buildMenuFromPath( MENU_ENTRY *d )  {
	int count = 0;
	_Bool loadStore = FALSE;
	_Bool is_entry_row;
	uint8_t pos = 0;
	num_menu_entries = 0;

	MENU_ENTRY *dst = (MENU_ENTRY *)&menu_entries[0];

	if(strlen(curPath) == 0){
	}else if(strncmp(MENU_TEXT_WIFI_SETUP, curPath, sizeof(MENU_TEXT_WIFI_SETUP) - 1) == 0 ){
		if(strlen(curPath) > sizeof(MENU_TEXT_WIFI_SETUP) ){
			if(d->type == Menu_Action){ // if actual Entry is of type Menu_Action -> Connect to WiFi
				// curPath is: MENU_TEXT_WIFI_SETUP + "/" SSID[33] + Password + "/Enter" + '\0'
				curPath[strlen(curPath) - 6 ] = '\0'; // delete "/Enter" at end of Path

				// TODO before we send them to esp8266 escape , " and \ in SSID and Password..
				int i = sizeof(MENU_TEXT_WIFI_SETUP);
		        while( curPath[i] != 30 && i < sizeof(MENU_TEXT_WIFI_SETUP) + 31 ){
		            i++;
		        }
		        curPath[i] = 0;

		        // TODO esp8266_connect((unsigned char*) &curPath[sizeof(MENU_TEXT_WIFI_SETUP) ], (unsigned char*) &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + 32]);

		    	http_request_header[0] = 0;
		        strcat((char *)http_request_header, "AT+CWJAP=\"");
		        strcat((char *)http_request_header, &curPath[sizeof(MENU_TEXT_WIFI_SETUP) ]);     // skip MENU_TEXT_WIFI_SETUP + "/"
		        strcat((char *)http_request_header, "\",\"");
		        strcat((char *)http_request_header, &curPath[sizeof(MENU_TEXT_WIFI_SETUP) + 32]); // skip MENU_TEXT_WIFI_SETUP + "/" SSID[33]
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
	}else if(strncmp(MENU_TEXT_USER_SETUP, curPath, sizeof(MENU_TEXT_USER_SETUP) - 1) == 0 ){
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
			if(strcmp(MENU_TEXT_USER_SETUP, curPath) == 0){
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
	}else if(strncmp(MENU_TEXT_TV_MODE_SETUP, curPath, sizeof(MENU_TEXT_TV_MODE_SETUP) - 1) == 0 ){
		if(d->type == Menu_Action){
			HAL_FLASH_Unlock();
			if(strcmp(&curPath[sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_PAL) == 0){
				set_tv_mode(TV_MODE_PAL);
				if(tv_mode != TV_MODE_PAL){
					FLASH_Erase_Sector(FLASH_SECTOR_11, (uint8_t) FLASH_VOLTAGE_RANGE_3); // TODO use User-Option Bytes for TV Mode (0x1FFF C000) bits 0-1 are unused, but don't change RDP, BOR WDG and RST!
					HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_CONFIG_ADDRESS, ((uint32_t)TV_MODE_PAL) );
				}
				tv_mode = TV_MODE_PAL;
			}else if(strcmp(&curPath[sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_PAL60) == 0){
				set_tv_mode(TV_MODE_PAL60);
				if(tv_mode != TV_MODE_PAL60){
					FLASH_Erase_Sector(FLASH_SECTOR_11, (uint8_t) FLASH_VOLTAGE_RANGE_3);
					HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_CONFIG_ADDRESS, ((uint32_t)TV_MODE_PAL60) );
				}
				tv_mode = TV_MODE_PAL60;
			}else{ // if(strcmp(&curPath[sizeof(MENU_TEXT_TV_MODE_SETUP)], MENU_TEXT_TV_MODE_NTSC) == 0)
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

	if(strlen(curPath) == 0){
		MAKE_MENU_ENTRY(MENU_TEXT_WIFI_SETUP, Sub_Menu);
		MAKE_MENU_ENTRY(MENU_TEXT_TV_MODE_SETUP, Sub_Menu);
		loadStore = TRUE;
	}



	// Test we should load store and if connected to AP
    if(	loadStore ){
    	if(esp8266_is_connected() == TRUE){
			if( prepare_PlusStore_API_request(curPath) == FALSE){
            	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
				return;
			}

            HAL_UART_Transmit(&huart1, http_request_header, strlen((char *)http_request_header), 50);
        	count = 0;
        	while(HAL_UART_Receive(&huart1, &c,1, 400 ) == HAL_OK){
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
                	}else if( count > 8 && count < 37 && c != '\n'){ // filename/dirname should begin at index 9
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

}

int identify_cartridge( MENU_ENTRY *d )
{


	unsigned int image_size = 0, count;
	int cart_type = CART_TYPE_NONE;

	strcat(curPath, "/");
    strcat(curPath, d->entryname);

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

	// Test if connected to AP
    if(esp8266_is_connected() == FALSE){
    	return CART_TYPE_NONE;
    }

	if( prepare_PlusStore_API_request(curPath) == FALSE){
    	set_menu_status_msg(STATUS_MESSAGE_ESP_TIMEOUT);
		return CART_TYPE_NONE;
	}

    uint8_t chunks = ( d->filesize + 4095 )  / 4096;         //  use Real HTTP Range requests??
    while(chunks != 0 ){
    	if(HAL_UART_Transmit(&huart1, http_request_header, strlen((char *)http_request_header), 50)!= HAL_OK){
    	}

    	count = 0;
    	// Skip HTTP Header
    	while(HAL_UART_Receive(&huart1, &c, 1, 400 ) == HAL_OK){
           	if( c == '\n' ){
           		if (count == 1)
           			break;
           		count = 0;
           	}else{
           		count++;
           	}
    	}
    	// Now for the HTTP Body
    	while(HAL_UART_Receive(&huart1, &c, 1, 400 ) == HAL_OK){
            	buffer[image_size++] = c;
    	}
    	chunks--;
    	http_request_header[HTTP_REQUEST_CHUNK_PARAM_POS]++;
    	HAL_Delay(1200);
    }

    // End Transparent Transmission
    if( HAL_UART_Transmit(&huart1, ATCMD6, sizeof(ATCMD6) - 1, 10) != HAL_OK){
		cart_type = CART_TYPE_NONE; // lets see what we've got
	}
	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){
	}

    // disconnect here or if cart_type != CART_TYPE_NONE
	if (cart_type != CART_TYPE_NONE) goto close;

	// If we don't already know the type (from the file extension), then we
	// auto-detect the cart type - largely follows code in Stella's CartDetector.cpp

	if (image_size == 2*1024)
	{
		if (isProbablyCV(image_size, buffer))
			cart_type = CART_TYPE_CV;
		else
			cart_type = CART_TYPE_2K;
	}
	else if (isProbablyPLS(image_size, buffer))
	{
		if (image_size == 4*1024)
			cart_type = CART_TYPE_PLUS;
		else
			cart_type = CART_TYPE_PLUS32;
	}
	else if (image_size == 4*1024)
	{
		cart_type = CART_TYPE_4K;
	}
	else if (image_size == 8*1024)
	{
		// First check for *potential* F8
		int f8 = isPotentialF8(image_size, buffer);

		if (isProbablySC(image_size, buffer))
			cart_type = CART_TYPE_F8SC;
		else if (memcmp(buffer, buffer + 4096, 4096) == 0)
			cart_type = CART_TYPE_4K;
		else if (isProbablyE0(image_size, buffer))
			cart_type = CART_TYPE_E0;
		else if (isProbably3E(image_size, buffer))
			cart_type = CART_TYPE_3E;
		else if (isProbably3F(image_size, buffer))
			cart_type = CART_TYPE_3F;
		else if (isProbablyFE(image_size, buffer) && !f8)
			cart_type = CART_TYPE_FE;
		else if (isProbably0840(image_size, buffer))
			cart_type = CART_TYPE_0840;
		else
			cart_type = CART_TYPE_F8;
	}
	else if(image_size >= 10240 && image_size <= 10496)
	{  // ~10K - Pitfall II
		cart_type = CART_TYPE_DPC;
	}
	else if (image_size == 12*1024)
	{
		cart_type = CART_TYPE_FA;
	}
	else if (image_size == 16*1024)
	{
		if (isProbablySC(image_size, buffer))
			cart_type = CART_TYPE_F6SC;
		else if (isProbablyE7(image_size, buffer))
			cart_type = CART_TYPE_E7;
		else if (isProbably3E(image_size, buffer))
			cart_type = CART_TYPE_3E;
		else
			cart_type = CART_TYPE_F6;
	}
	else if (image_size == 32*1024)
	{
		if (isProbablySC(image_size, buffer))
			cart_type = CART_TYPE_F4SC;
		else if (isProbably3E(image_size, buffer))
			cart_type = CART_TYPE_3E;
		else if (isProbably3F(image_size, buffer))
			cart_type = CART_TYPE_3F;
		else
			cart_type = CART_TYPE_F4;
	}
	else if (image_size == 64*1024)
	{
		if (isProbably3E(image_size, buffer))
			cart_type = CART_TYPE_3E;
		else if (isProbably3F(image_size, buffer))
			cart_type = CART_TYPE_3F;
		else if (isProbablyEF(image_size, buffer))
		{
			if (isProbablySC(image_size, buffer))
				cart_type = CART_TYPE_EFSC;
			else
				cart_type = CART_TYPE_EF;
		}
		else
			cart_type = CART_TYPE_F0;
	}

	close:

	if (cart_type)
		cart_size_bytes = image_size;

  int len = strlen(curPath);
	while (len && curPath[--len] != '/');
	curPath[len] = 0;


	return cart_type;
}



/*************************************************************************
 * Cartridge Emulation
 *************************************************************************/

void emulate_PLUS_cartridge(int header_length, int isPlus32) {
	setup_cartridge_image_with_ram();

  __disable_irq();  // Disable interrupts
  uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];

  uint8_t receive_buffer_write_pointer = 0, receive_buffer_read_pointer = 0, content_counter = 0;
  uint8_t out_buffer_write_pointer = 0, out_buffer_send_pointer = 0;
  uint8_t receive_buffer[256], out_buffer[256];
  uint8_t last_c, last_last_c, i;
  uint16_t content_len;
  int content_length_pos = header_length - 5;

  enum Transmission_State huart_state = No_Transmission;

  while (1)
  {
    while ((addr = ADDR_IN) != addr_prev)
      addr_prev = addr;
    // got a stable address
    if (addr & 0x1000)
    { // A12 high
			if (isPlus32 && addr > 0x1FF3 && addr < 0x1FFC){	// bank-switch 1FF4 to 1FFB
				  bankPtr = &cart_rom[(addr-0x1FF4)*4*1024];
      }else if (isPlus32 && (addr & 0x1F00) == 0x1000){	// SC RAM access
				if (addr & 0x0080)
				{	// a read from cartridge ram
					DATA_OUT = ((uint16_t)cart_ram[addr&0x7F]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
				else
				{	// a write to cartridge ram
					// read last data on the bus before the address lines change
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					cart_ram[addr&0x7F] = data_prev;//>>8;
				}
      }else if(addr == 0x1ff2 ){// read from receive buffer
        DATA_OUT = ((uint16_t)receive_buffer[receive_buffer_read_pointer]);//<<8;
        SET_DATA_MODE_OUT
        // if there is more data on the receive_buffer
        if(receive_buffer_read_pointer < receive_buffer_write_pointer )
          receive_buffer_read_pointer++;
        // wait for address bus to change
        while (ADDR_IN == addr){}
        SET_DATA_MODE_IN
      }else if(addr == 0x1ff1){ // write to send Buffer and start Request !!
        while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
        if(huart_state == No_Transmission)
          huart_state = Send_Start;
        out_buffer[out_buffer_write_pointer] = data_prev;//>>8;
      }else if(addr == 0x1ff3){ // read receive Buffer length
        DATA_OUT = ((uint16_t)(receive_buffer_write_pointer - receive_buffer_read_pointer));//<<8;
        SET_DATA_MODE_OUT
        // wait for address bus to change
        while (ADDR_IN == addr){}
        SET_DATA_MODE_IN
      }else if(addr == 0x1ff0){ // write to send Buffer
        while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
        out_buffer[out_buffer_write_pointer++] = data_prev;//>>8;
      }else{
        DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
        SET_DATA_MODE_OUT
        // wait for address bus to change
        while (ADDR_IN == addr){ }
        SET_DATA_MODE_IN
      }
    }else{
      while (ADDR_IN == addr) {
        switch(huart_state){
          case Send_Start: {
            content_len = out_buffer_write_pointer + 1;
            i = content_length_pos;
            huart_state++; // = Send_Prepare_Header;
            break;
          }
          case Send_Prepare_Header: {
            if (content_len != 0) {
                  c = content_len % 10;
                  http_request_header[i--] =  c + '0';
                  content_len = content_len/10;
            }else{
              i = 0; // use as Header send counter in next step
              huart_state++;// = Send_Header;
            }
            break;
          }

          case Send_Header: {
                if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                  huart1.Instance->DR = http_request_header[i]; // & (uint8_t)0xFF);
                  if( ++i == header_length ){
                    huart_state++;// = Send_Content;
              }
                }
            break;
          }
          case Send_Content: {
                if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                  huart1.Instance->DR = out_buffer[out_buffer_send_pointer]; // & (uint8_t)0xFF);
                  if( out_buffer_send_pointer == out_buffer_write_pointer ){
                    huart_state++;// = Send_Finished;
              }else{
                out_buffer_send_pointer++;
              }
                }
            break;
          }
          case Send_Finished: {
            if(( huart1.Instance->SR & UART_FLAG_TC) == UART_FLAG_TC){//(! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TC)) ){
              out_buffer_write_pointer = 0;
              out_buffer_send_pointer = 0;
              huart_state++;// = Receive_Header;
            }
            break;
          }
          case Receive_Header: {
                if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                  c = (uint8_t)huart1.Instance->DR; // & (uint8_t)0xFF);
                  if(c == last_last_c && c == '\n'){
                    huart_state++;// = Receive_Length;
                  }else{
                    last_last_c = last_c;
                    last_c = c;
                  }
                }
            break;
          }
          case Receive_Length: {
                if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                  c = (uint8_t)huart1.Instance->DR;// & (uint8_t)0xFF);
                  huart_state++;// = Receive_Content;
                }
            break;
          }
          case Receive_Content: {
                if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                  receive_buffer[receive_buffer_write_pointer++] = (uint8_t)huart1.Instance->DR;// & (uint8_t)0xFF);
                  if(++content_counter == c ){
                        huart_state++;// = Receive_Finished;
                    }
                }
            break;
          }
          case Receive_Finished:{
            http_request_header[content_length_pos - 1] = ' ';
            http_request_header[content_length_pos - 2] = ' ';
            content_counter = 0;
            huart_state = No_Transmission;
            break;
          }
        }
      }
    }
  }
  __enable_irq();
}


void emulate_2k_cartridge() {
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			DATA_OUT = ((uint16_t)cart_rom[addr&0x7FF]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();
}

void emulate_4k_cartridge() {
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			DATA_OUT = ((uint16_t)cart_rom[addr&0xFFF]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();
}

/* 'Standard' Bankswitching
 * ------------------------
 * Used by F8(8k), F6(16k), F4(32k), EF(64k)
 * and F8SC(8k), F6SC(16k), F4SC(32k), EFSC(64k)
 *
 * SC variants have 128 bytes of RAM:
 * RAM read port is $1080 - $10FF, write port is $1000 - $107F.
 */
void emulate_FxSC_cartridge(uint16_t lowBS, uint16_t highBS, int isSC)
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr >= lowBS && addr <= highBS)	// bank-switch
				bankPtr = &cart_rom[(addr-lowBS)*4*1024];

			if (isSC && (addr & 0x1F00) == 0x1000)
			{	// SC RAM access
				if (addr & 0x0080)
				{	// a read from cartridge ram
					DATA_OUT = ((uint16_t)cart_ram[addr&0x7F]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
				else
				{	// a write to cartridge ram
					// read last data on the bus before the address lines change
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					cart_ram[addr&0x7F] = data_prev;//>>8;
				}
			}
			else
			{	// normal rom access
				DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
		}
	}
	__enable_irq();
}

/* FA (CBS RAM plus) Bankswitching
 * -------------------------------
 * Similar to the above, but with 3 ROM banks for a total of 12K
 * plus 256 bytes of RAM:
 * RAM read port is $1100 - $11FF, write port is $1000 - $10FF.
 */
void emulate_FA_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr >= 0x1FF8 && addr <= 0x1FFA)	// bank-switch
				bankPtr = &cart_rom[(addr-0x1FF8)*4*1024];

			if ((addr & 0x1F00) == 0x1100)
			{	// a read from cartridge ram
				DATA_OUT = ((uint16_t)cart_ram[addr&0xFF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
			else if ((addr & 0x1F00) == 0x1000)
			{	// a write to cartridge ram
				// read last data on the bus before the address lines change
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				cart_ram[addr&0xFF] = data_prev;//>>8;
			}
			else
			{	// normal rom access
				DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
		}
	}
	__enable_irq();
}

/* FE Bankswitching
 * ----------------
 * The text below is quoted verbatim from the source code of the Atari
 * 2600 emulator Stella (https://github.com/stella-emu) which was the
 * best reference that I could find for FE bank-switching.
 * The implementation below is based on this description, and the relevant
 * source files in Stella.
 */

/*
  Bankswitching method used by Activision's Robot Tank and Decathlon.

  This scheme was originally designed to have up to 8 4K banks, and is
  triggered by monitoring the address bus for address $01FE.  All released
  carts had only two banks, and this implementation assumes that (ie, ROM
  is always 8K, and there are two 4K banks).

  The following is paraphrased from the original patent by David Crane,
  European Patent Application # 84300730.3, dated 06.02.84:
  ---------------------------------------------------------------------------
  The twelve line address bus is connected to a plurality of 4K by eight bit
  memories.

  The eight line data bus is connected to each of the banks of memory, also.
  An address comparator is connected to the bus for detecting the presence of
  the 01FE address.  Actually, the comparator will detect only the lowest 12
  bits of 1FE, because of the twelve bit limitation of the address bus.  Upon
  detection of the 01FE address, a one cycle delay is activated which then
  actuates latch connected to the data bus.  The three most significant bits
  on the data bus are latched and provide the address bits A13, A14, and A15
  which are then applied to a 3 to 8 de-multiplexer.  The 3 bits A13-A15
  define a code for selecting one of the eight banks of memory which is used
  to enable one of the banks of memory by applying a control signal to the
  enable, EN, terminal thereof.  Accordingly, memory bank selection is
  accomplished from address codes on the data bus following a particular
  program instruction, such as a jump to subroutine.
  ---------------------------------------------------------------------------

  Note that in the general scheme, we use D7, D6 and D5 for the bank number
  (3 bits, so 8 possible banks).  However, the scheme as used historically
  by Activision only uses two banks.  Furthermore, the two banks it uses
  are actually indicated by binary 110 and 111, and translated as follows:

	binary 110 -> decimal 6 -> Upper 4K ROM (bank 1) @ $D000 - $DFFF
	binary 111 -> decimal 7 -> Lower 4K ROM (bank 0) @ $F000 - $FFFF

  Since the actual bank numbers (0 and 1) do not map directly to their
  respective bitstrings (7 and 6), we simply test for D5 being 0 or 1.
  This is the significance of the test '(value & 0x20) ? 0 : 1' in the code.

  NOTE: Consult the patent application for more specific information, in
		particular *why* the address $01FE will be placed on the address
		bus after both the JSR and RTS opcodes.

  @author  Stephen Anthony; with ideas/research from Christian Speckner and
		   alex_79 and TomSon (of AtariAge)
*/
void emulate_FE_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	int lastAccessWasFE = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (!(addr & 0x1000))
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			data = data_prev;//>>8;
		}
		else
		{ // A12 high
			data = bankPtr[addr&0xFFF];
			DATA_OUT = data;//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
		// end of cycle
		if (lastAccessWasFE)
		{	// bank-switch - check the 5th bit of the data bus
			if (data & 0x20)
				bankPtr = &cart_rom[0];
			else
				bankPtr = &cart_rom[4 * 1024];
		}
		lastAccessWasFE = (addr == 0x01FE);
	}
	__enable_irq();
}

/* 3F (Tigervision) Bankswitching
 * ------------------------------
 * Generally 8K ROMs, containing 4 x 2K banks. The last bank is always mapped into
 * the upper part of the 4K cartridge ROM space. The bank mapped into the lower part
 * of the 4K cartridge ROM space is selected by the lowest two bits written to $003F
 * (or any lower address).
 * In theory this scheme supports up to 512k ROMs if we use all the bits written to
 * $003F - the code below should support up to MAX_CART_ROM_SIZE.
 *
 * Note - Stella restricts bank switching to only *WRITES* to $0000-$003f. But we
 * can't do this here and Miner 2049'er crashes (unless we restrict to $003f only).
 *
 * From an post by Eckhard Stolberg, it seems the switch would happen on a real cart
 * only when the access is followed by an access to an address between $1000 and $1FFF.
 *
 * 29/3/18 - The emulation below switches on access to $003f only, since the my prior
 * attempt at the banking scheme described by Eckhard Stolberg didn't work on a 7800.
 *
 * Refs:
 * http://atariage.com/forums/topic/266245-tigervision-banking-and-low-memory-reads/
 * http://atariage.com/forums/topic/68544-3f-bankswitching/
 */
void emulate_3F_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	int cartPages = cart_size_bytes/2048;

	uint16_t addr, addr_prev = 0, addr_prev2 = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	unsigned char *fixedPtr = &cart_rom[(cartPages-1)*2048];

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{	// new more robust test for stable address (seems to be needed for 7800)
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}
		// got a stable address
		if (!(addr & 0x1000))
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			if (addr == 0x003F)
			{	// switch bank
				int newPage = (data_prev) % cartPages; //data_prev>>8
				bankPtr = &cart_rom[newPage*2048];
			}
		}
		else
		{ // A12 high
			if (addr & 0x800)
				DATA_OUT = ((uint16_t)fixedPtr[addr&0x7FF]);//<<8;
			else
				DATA_OUT = ((uint16_t)bankPtr[addr&0x7FF]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();
}

/* Scheme as described by Eckhard Stolberg. Didn't work on my test 7800, so replaced
 * by the simpler 3F only scheme above.
	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (!(addr & 0x1000))
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			data = data_prev;//>>8;
			if (addr <= 0x003F) newPage = data % cartPages; else newPage = -1;
		}
		else
		{ // A12 high
			if (newPage >=0) {
				bankPtr = &cart_rom[newPage*2048];	// switch bank
				newPage = -1;
			}
			if (addr & 0x800)
				data = fixedPtr[addr&0x7FF];
			else
				data = bankPtr[addr&0x7FF];
			DATA_OUT = data;//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
 */

/* 3E (3F + RAM) Bankswitching
 * ------------------------------
 * This scheme supports up to 512k ROM and 256K RAM.
 * However here we only support up to MAX_CART_ROM_SIZE and MAX_CART_RAM_SIZE
 *
 * The text below is the best description of the mapping scheme I could find,
 * quoted from http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 */

/*
This works similar to 3F (Tigervision) above, except RAM has been added.  The range of
addresses has been restricted, too.  Only 3E and 3F can be written to now.

1000-17FF - this bank is selectable
1800-1FFF - this bank is the last 2K of the ROM

To select a particular 2K ROM bank, its number is poked into address 3F.  Because there's
8 bits, there's enough for 256 2K banks, or a maximum of 512K of ROM.

Writing to 3E, however, is what's new.  Writing here selects a 1K RAM bank into
1000-17FF.  The example (Boulderdash) uses 16K of RAM, however there's theoretically
enough space for 256K of RAM.  When RAM is selected, 1000-13FF is the read port while
1400-17FF is the write port.
*/
void emulate_3E_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	int cartROMPages = cart_size_bytes/2048;
	int cartRAMPages = 32;

	uint16_t addr, addr_prev = 0, addr_prev2 = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	unsigned char *fixedPtr = &cart_rom[(cartROMPages-1)*2048];
	int bankIsRAM = 0;

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{	// new more robust test for stable address (seems to be needed for 7800)
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (bankIsRAM && (addr & 0xC00) == 0x400)
			{	// we are accessing the RAM write addresses ($1400-$17FF)
				// read last data on the bus before the address lines change
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				bankPtr[addr&0x3FF] = data_prev;//>>8;
			}
			else
			{	// reads to either ROM or RAM
				if (addr & 0x800)
				{	// upper 2k ($1800-$1FFF)
					data = fixedPtr[addr&0x7FF];	// upper 2k -> read fixed ROM bank
				}
				else
				{	// lower 2k ($1000-$17FF)
					if (!bankIsRAM)
						data = bankPtr[addr&0x7FF];	// read switching ROM bank
					else
						data = bankPtr[addr&0x3FF];	// must be RAM read
				}
				DATA_OUT = data;//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
		}
		else
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			data = data_prev;//>>8;
			if (addr == 0x003F) {
				bankIsRAM = 0;
				bankPtr = &cart_rom[(data%cartROMPages)*2048];	// switch in ROM bank
			}
			else if (addr == 0x003E) {
				bankIsRAM = 1;
				bankPtr = &cart_ram[(data%cartRAMPages)*1024];	// switch in RAM bank
			}
		}
	}
	__enable_irq();
}

/* E0 Bankswitching
 * ------------------------------
 * The text below is the best description of the mapping scheme I could find,
 * quoted from http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 */

/*
Parker Brothers used this, and it was used on one other game (Tooth Protectors).  It
uses 8K of ROM and can map 1K sections of it.

This mapper has 4 1K banks of ROM in the address space.  The address space is broken up
into the following locations:

1000-13FF : To select a 1K ROM bank here, access 1FE0-1FE7 (1FE0 = select first 1K, etc)
1400-17FF : To select a 1K ROM bank, access 1FE8-1FEF
1800-1BFF : To select a 1K ROM bank, access 1FF0-1FF7
1C00-1FFF : This is fixed to the last 1K ROM bank of the 8K

Like F8, F6, etc. accessing one of the locations indicated will perform the switch.
*/
void emulate_E0_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	unsigned char curBanks[4] = {0,0,0,7};

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high

			if (addr >= 0x1FE0 && addr <= 0x1FF7)
			{	// bank-switching addresses
				if (addr <= 0x1FE7)	// switch 1st bank
					curBanks[0] = addr-0x1FE0;
				else if (addr >= 0x1FE8 && addr <= 0x1FEF)	// switch 2nd bank
					curBanks[1] = addr-0x1FE8;
				else if (addr >= 0x1FF0)	// switch 3rd bank
					curBanks[2] = addr-0x1FF0;
			}
			// fetch data from the correct bank
			int target = (addr & 0xC00) >> 10;
			DATA_OUT = ((uint16_t)cart_rom[curBanks[target]*1024 + (addr&0x3FF)]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();

}

/* 0840 Bankswitching
 * ------------------------------
 * 8k cartridge with two 4k banks.
 * The following description was derived from:
 * http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 *
 * Bankswitch triggered by access to an address matching the pattern below:
 *
 * A12		   A0
 * ----------------
 * 0 1xxx xBxx xxxx (x = don't care, B is the bank we select)
 *
 * If address AND $1840 == $0800, then we select bank 0
 * If address AND $1840 == $0840, then we select bank 1
 */
void emulate_0840_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, addr_prev2 = 0;
	unsigned char *bankPtr = &cart_rom[0];

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{	// new more robust test for stable address (seems to be needed for 7800)
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
		else
		{
			if ((addr & 0x0840) == 0x0800) bankPtr = &cart_rom[0];
			else if ((addr & 0x0840) == 0x0840) bankPtr = &cart_rom[4*1024];
			// wait for address bus to change
			while (ADDR_IN == addr) ;
		}
	}
	__enable_irq();
}

/* CommaVid Cartridge
 * ------------------------------
 * 2K ROM + 1K RAM
 *  $F000-$F3FF 1K RAM read
 *  $F400-$F7FF 1K RAM write
 *  $F800-$FFFF 2K ROM
 */
void emulate_CV_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr & 0x0800)
			{	// ROM read
				DATA_OUT = ((uint16_t)cart_rom[addr&0x7FF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
			else
			{	// RAM access
				if (addr & 0x0400)
				{	// a write to cartridge ram
					// read last data on the bus before the address lines change
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					cart_ram[addr&0x3FF] = data_prev;//>>8;
				}
				else
				{	// a read from cartridge ram
					DATA_OUT = ((uint16_t)cart_ram[addr&0x3FF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
			}
		}
	}
	__enable_irq();
}

/* F0 Bankswitching
 * ------------------------------
 * 64K cartridge with 16 x 4K banks. An access to $1FF0 switches to the next
 * bank in sequence.
 */
void emulate_F0_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	int currentBank = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr == 0x1FF0)
				currentBank = (currentBank + 1) % 16;
			// ROM access
			DATA_OUT = ((uint16_t)cart_rom[(currentBank * 4096)+(addr&0xFFF)]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();
}

/* E7 Bankswitching
 * ------------------------------
 * 16K cartridge with additional RAM.
 * The text below is the best description of the mapping scheme I could find,
 * quoted from http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 */

/*
M-network wanted something of their own too, so they came up with what they called
"Big Game" (this was printed on the prototype ASICs on the prototype carts).  It
can handle up to 16K of ROM and 2K of RAM.

1000-17FF is selectable
1800-19FF is RAM
1A00-1FFF is fixed to the last 1.5K of ROM

Accessing 1FE0 through 1FE6 selects bank 0 through bank 6 of the ROM into 1000-17FF.
Accessing 1FE7 enables 1K of the 2K RAM, instead.

When the RAM is enabled, this 1K appears at 1000-17FF.  1000-13FF is the write port, 1400-17FF
is the read port.

1800-19FF also holds RAM. 1800-18FF is the write port, 1900-19FF is the read port.
Only 256 bytes of RAM is accessable at time, but there are four different 256 byte
banks making a total of 1K accessable here.

Accessing 1FE8 through 1FEB select which 256 byte bank shows up.
 */
void emulate_E7_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	unsigned char *fixedPtr = &cart_rom[(8-1)*2048];
	unsigned char *ram1Ptr = &cart_ram[0];
	unsigned char *ram2Ptr = &cart_ram[1024];
	int ram_mode = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr & 0x0800)
			{	// higher 2k cartridge ROM area
				if ((addr & 0x0E00) == 0x0800)
				{	// 256 byte RAM access
					if (addr & 0x0100)
					{	// 1900-19FF is the read port
						DATA_OUT = ((uint16_t)ram1Ptr[addr&0xFF]);//<<8;
						SET_DATA_MODE_OUT
						// wait for address bus to change
						while (ADDR_IN == addr) ;
						SET_DATA_MODE_IN
					}
					else
					{	// 1800-18FF is the write port
						while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
						ram1Ptr[addr&0xFF] = data_prev;//>>8;
					}
				}
				else
				{	// fixed ROM bank access
					// check bankswitching addresses
					if (addr >= 0x1FE0 && addr <= 0x1FE7)
					{
						if (addr == 0x1FE7) ram_mode = 1;
						else
						{
							bankPtr = &cart_rom[(addr - 0x1FE0)*2048];
							ram_mode = 0;
						}
					}
					else if (addr >= 0x1FE8 && addr <= 0x1FEB)
						ram1Ptr = &cart_ram[(addr - 0x1FE8)*256];

					DATA_OUT = ((uint16_t)fixedPtr[addr&0x7FF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
			}
			else
			{	// lower 2k cartridge ROM area
				if (ram_mode)
				{	// 1K RAM access
					if (addr & 0x400)
					{	// 1400-17FF is the read port
						DATA_OUT = ((uint16_t)ram2Ptr[addr&0x3FF]);//<<8;
						SET_DATA_MODE_OUT
						// wait for address bus to change
						while (ADDR_IN == addr) ;
						SET_DATA_MODE_IN
					}
					else
					{	// 1000-13FF is the write port
						while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
						ram2Ptr[addr&0x3FF] = data_prev;//>>8;
					}
				}
				else
				{	// selected ROM bank access
					DATA_OUT = ((uint16_t)bankPtr[addr&0x7FF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
			}
		}
	}
	__enable_irq();
}

/* DPC (Pitfall II) Bankswitching
 * ------------------------------
 * Bankswitching like F8(8k)
 * DPC implementation based on:
 * - Stella (https://github.com/stella-emu) - CartDPC.cxx
 * - Kevin Horton's 2600 Mappers (http://blog.kevtris.org/blogfiles/Atari 2600 Mappers.txt)
 *
 * Note this is not a full implementation of DPC, but is enough to run Pitfall II and the music sounds ok.
 */

void emulate_DPC_cartridge()
{
	setup_cartridge_image();

	SysTick_Config(SystemCoreClock / 21000);	// 21KHz
	__disable_irq();	// Disable interrupts

	unsigned char prevRom = 0, prevRom2 = 0;
	int soundAmplitudeIndex = 0;
	unsigned char soundAmplitudes[8] = {0x00, 0x04, 0x05, 0x09, 0x06, 0x0a, 0x0b, 0x0f};

	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0], *DpcDisplayPtr = &cart_rom[8*1024];

	unsigned char DpcTops[8], DpcBottoms[8], DpcFlags[8];
	uint16_t DpcCounters[8];
	int DpcMusicModes[3], DpcMusicFlags[3];

	// Initialise the DPC's random number generator register (must be non-zero)
	int DpcRandom = 1;

	// Initialise the DPC registers
	for(int i = 0; i < 8; ++i)
		DpcTops[i] = DpcBottoms[i] = DpcCounters[i] = DpcFlags[i] = 0;

	DpcMusicModes[0] = DpcMusicModes[1] = DpcMusicModes[2] = 0;
	DpcMusicFlags[0] = DpcMusicFlags[1] = DpcMusicFlags[2] = 0;


	uint32_t lastSysTick = SysTick->VAL;
	uint32_t DpcClocks = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;

		// got a stable address
		if (addr & 0x1000)
		{ // A12 high

			if (addr < 0x1040)
			{	// DPC read
				int index = addr & 0x07;
				int function = (addr >> 3) & 0x07;

				// Update flag register for selected data fetcher
				if((DpcCounters[index] & 0x00ff) == DpcTops[index])
					DpcFlags[index] = 0xff;
				else if((DpcCounters[index] & 0x00ff) == DpcBottoms[index])
					DpcFlags[index] = 0x00;

				unsigned char result = 0;
				switch (function)
				{
					case 0x00:
					{
						if(index < 4)
						{	// random number read
							DpcRandom ^= DpcRandom << 3;
							DpcRandom ^= DpcRandom >> 5;
							result = (unsigned char)DpcRandom;
						}
						else
						{	// sound
							soundAmplitudeIndex = (DpcMusicModes[0] & DpcMusicFlags[0]);
							soundAmplitudeIndex |=  (DpcMusicModes[1] & DpcMusicFlags[1]);
							soundAmplitudeIndex |=  (DpcMusicModes[2] & DpcMusicFlags[2]);
							result = soundAmplitudes[soundAmplitudeIndex];;
						}
						break;
					}

					case 0x01:
					{	// DFx display data read
						result = DpcDisplayPtr[2047 - DpcCounters[index]];
						break;
					}

					case 0x02:
					{	// DFx display data read AND'd w/flag
						result = DpcDisplayPtr[2047 - DpcCounters[index]] & DpcFlags[index];
						break;
					}

					case 0x07:
					{	// DFx flag
						result = DpcFlags[index];
						break;
					}
				}

				DATA_OUT = ((uint16_t)result);
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN

				// Clock the selected data fetcher's counter if needed
				if ((index < 5) || ((index >= 5) && (!DpcMusicModes[index - 5])))
					DpcCounters[index] = (DpcCounters[index] - 1) & 0x07ff;
			}
			else if (addr < 0x1080)
			{	// DPC write
				int index = addr & 0x07;
				int function = (addr >> 3) & 0x07;

				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				unsigned char value = data_prev;
				switch (function)
				{
					case 0x00:
					{	// DFx top count
						DpcTops[index] = value;
						DpcFlags[index] = 0x00;
						break;
					}

					case 0x01:
					{	// DFx bottom count
						DpcBottoms[index] = value;
						break;
					}

					case 0x02:
					{	// DFx counter low
						DpcCounters[index] = (DpcCounters[index] & 0x0700) | value;
						break;
					}

					case 0x03:
					{	// DFx counter high
						DpcCounters[index] = ((uint16_t)(value & 0x07))  | (DpcCounters[index] & 0xff);
						if(index >= 5)
							DpcMusicModes[index - 5] = (value & 0x10) ? 0x7 : 0;
						break;
					}

					case 0x06:
					{	// Random Number Generator Reset
						DpcRandom = 1;
						break;
					}
				}
			}
			else
			{	// check bank-switch
				if (addr == 0x1FF8)
					bankPtr = &cart_rom[0];
				else if (addr == 0x1FF9)
					bankPtr = &cart_rom[4*1024];

				// normal rom access
				DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);
				SET_DATA_MODE_OUT
				prevRom2 = prevRom;
				prevRom = bankPtr[addr&0xFFF];
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
		}
		else if((prevRom2 & 0xec) == 0x84) // Only do this when ZP write since there will be a full cycle available there
		{	// non cartridge access - e.g. sta wsync
			while (ADDR_IN == addr) {
				// should the DPC clock be incremented?
				uint32_t sysTick = SysTick->VAL;
				if (sysTick > lastSysTick)
				{	// the 21KHz clock has wrapped, so we increase the DPC clock
					DpcClocks++;
					// update the music flags here, since there isn't enough time when the music register
					// is being read.
					DpcMusicFlags[0] = (DpcClocks % (DpcTops[5] + 1))
							> DpcBottoms[5] ? 1 : 0;
					DpcMusicFlags[1] = (DpcClocks % (DpcTops[6] + 1))
							> DpcBottoms[6] ? 2 : 0;
					DpcMusicFlags[2] = (DpcClocks % (DpcTops[7] + 1))
							> DpcBottoms[7] ? 4 : 0;
				}
				lastSysTick = sysTick;
			}
		}
	}
	__enable_irq();
}

/*************************************************************************
 * Main loop/helper functions
 *************************************************************************/

void emulate_cartridge(int cart_type)
{
	if (cart_type == CART_TYPE_2K)
		emulate_2k_cartridge();
	else if (cart_type == CART_TYPE_4K)
		emulate_4k_cartridge();
	else if (cart_type == CART_TYPE_F8)
		emulate_FxSC_cartridge(0x1FF8, 0x1FF9, 0);
	else if (cart_type == CART_TYPE_F6)
		emulate_FxSC_cartridge(0x1FF6, 0x1FF9, 0);
	else if (cart_type == CART_TYPE_F4)
		emulate_FxSC_cartridge(0x1FF4, 0x1FFB, 0);
	else if (cart_type == CART_TYPE_F8SC)
		emulate_FxSC_cartridge(0x1FF8, 0x1FF9, 1);
	else if (cart_type == CART_TYPE_F6SC)
		emulate_FxSC_cartridge(0x1FF6, 0x1FF9, 1);
	else if (cart_type == CART_TYPE_F4SC)
		emulate_FxSC_cartridge(0x1FF4, 0x1FFB, 1);
	else if (cart_type == CART_TYPE_FE)
		emulate_FE_cartridge();
	else if (cart_type == CART_TYPE_3F)
		emulate_3F_cartridge();
	else if (cart_type == CART_TYPE_3E)
		emulate_3E_cartridge();
	else if (cart_type == CART_TYPE_E0)
		emulate_E0_cartridge();
	else if (cart_type == CART_TYPE_0840)
		emulate_0840_cartridge();
	else if (cart_type == CART_TYPE_CV)
		emulate_CV_cartridge();
	else if (cart_type == CART_TYPE_EF)
		emulate_FxSC_cartridge(0x1FE0, 0x1FEF, 0);
	else if (cart_type == CART_TYPE_EFSC)
		emulate_FxSC_cartridge(0x1FE0, 0x1FEF, 1);
	else if (cart_type == CART_TYPE_F0)
		emulate_F0_cartridge();
	else if (cart_type == CART_TYPE_FA)
		emulate_FA_cartridge();
	else if (cart_type == CART_TYPE_E7)
		emulate_E7_cartridge();
	else if (cart_type == CART_TYPE_DPC)
		emulate_DPC_cartridge();
	else if (cart_type == CART_TYPE_PLUS || cart_type == CART_TYPE_PLUS32 ){
 		// Read Path and Hostname in ROM File from 0xf00  till '\0' and
		// copy to http_request_header offset for Content-Length pos isn't
		// a defined constant anymore .. (CONTENT_LENGTH_POSITION_IN_REQUEST_HEADER)
		int offset = strlen((char *)buffer) + 1;

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
        strcat((char *)http_request_header, (char *)"\r\nConnection: keep-alive\r\nContent-Type: application/octet-stream\r\nContent-Length:    \r\n\r\n");
        offset = strlen((char *)http_request_header);

        HAL_UART_Transmit(&huart1, (uint8_t*) API_ATCMD_2, sizeof(API_ATCMD_2)-1, 10);
	    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){ }

		emulate_PLUS_cartridge(offset, (cart_type == CART_TYPE_PLUS32) );
	}else if (cart_type == CART_TYPE_AR) {
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
	memset(menu_ram, 0, 1024);
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
	int cart_type = CART_TYPE_NONE;
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
    if (ret == CART_CMD_ROOT_DIR){

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
    } else {
      int sel = ret - CART_CMD_SEL_ITEM_n;
      MENU_ENTRY *d = &menu_entries[sel];
      if (d->type == Cart_File){
    	  // selection is a rom file
        cart_type = identify_cartridge(d);
        HAL_Delay(200);
        if (cart_type != CART_TYPE_NONE){
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
  		  // go into Menu
  		  if(( d->type != Keyboard_Char && strlen(curPath) > 0) || strcmp(MENU_TEXT_USER_SETUP, curPath) == 0 ){
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
