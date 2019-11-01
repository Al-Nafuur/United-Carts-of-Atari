/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * File            : main.h
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

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */
enum MENU_ENTRY_Type {
	Root_Menu = -1,
	Leave_Menu,
	Sub_Menu,
	Cart_File,
	Input_Field,
	Keyboard_Char,
	Menu_Action
};

enum Transmission_State{
	No_Transmission,
	Send_Start,
	Send_Prepare_Header,
	Send_Header,
	Send_Content,
	Send_Finished,
	Receive_Header,
	Receive_Length,
	Receive_Content,
	Receive_Finished
};

typedef struct {
	const char *ext;
	int cart_type;
} EXT_TO_CART_TYPE_MAP;


typedef struct {
	enum MENU_ENTRY_Type type;
	char entryname[33];
	uint32_t filesize;
} MENU_ENTRY;

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
/* USER CODE BEGIN Private defines */
#define TRUE 1
#define FALSE 0

#define VERSION 	  "0.5.1"
#define UDID_TEMPLATE "000000000000000000000000"

#define MENU_TEXT_WIFI_SETUP 	  "WiFi Setup"
#define MENU_TEXT_TV_MODE_SETUP   "Set TV Mode"
#define MENU_TEXT_TV_MODE_PAL     "PAL"
#define MENU_TEXT_TV_MODE_PAL60   "PAL 60Hz"
#define MENU_TEXT_TV_MODE_NTSC    "NTSC"
#define MENU_TEXT_FIRMWARE_UPDATE "** Update **"
#define MENU_TEXT_USER_SETUP      "Plus connect"

#define STATUS_MESSAGE_WIFI_NOT_CONNECTED   "No WiFi     "
#define STATUS_MESSAGE_WIFI_CONNECTED       "WiFi connect"
#define STATUS_MESSAGE_ESP_TIMEOUT          "WiFi timeout"
#define STATUS_MESSAGE_USER_CONNECT         "Insert email"
#define STATUS_MESSAGE_USER_CONNECTED       "User created"
#define STATUS_MESSAGE_USER_CONNECT_FAILED  "Failed      "

#define MAKE_MENU_ENTRY(NAME, TYPE)   dst->type = TYPE; \
                                strcpy(dst->entryname, NAME); \
                                dst->filesize = 0U; \
                                num_menu_entries++; \
                                dst++; \

#define setup_cartridge_image() \
	if (cart_size_bytes > 0x010000) return; \
	uint8_t* cart_rom = buffer; \
	if (!reboot_into_cartridge()) return;

#define setup_cartridge_image_with_ram() \
	if (cart_size_bytes > 0x010000) return; \
	uint8_t* cart_rom = buffer; \
	uint8_t* cart_ram = buffer + cart_size_bytes + (((~cart_size_bytes & 0x03) + 1) & 0x03); \
	if (!reboot_into_cartridge()) return;


/*************************************************************************
 * Cartridge Definitions
 *************************************************************************/
#define BUFFER_SIZE			96   // kilobytes

#define CART_TYPE_NONE		0
#define CART_TYPE_2K		1
#define CART_TYPE_4K		2
#define CART_TYPE_F8		3	// 8k
#define CART_TYPE_F6		4	// 16k
#define CART_TYPE_F4		5	// 32k
#define CART_TYPE_F8SC		6	// 8k+ram
#define CART_TYPE_F6SC		7	// 16k+ram
#define CART_TYPE_F4SC		8	// 32k+ram
#define CART_TYPE_FE		9	// 8k
#define CART_TYPE_3F		10	// varies (examples 8k)
#define CART_TYPE_3E		11	// varies (only example 32k)
#define CART_TYPE_E0		12	// 8k
#define CART_TYPE_0840		13	// 8k
#define CART_TYPE_CV		14	// 2k+ram
#define CART_TYPE_EF		15	// 64k
#define CART_TYPE_EFSC		16	// 64k+ram
#define CART_TYPE_F0		17	// 64k
#define CART_TYPE_FA		18	// 12k
#define CART_TYPE_E7		19	// 16k+ram
#define CART_TYPE_DPC		20	// 8k+DPC(2k)
#define CART_TYPE_AR		21  // Arcadia Supercharger (variable size)
#define CART_TYPE_PLUS		22  // plusCart 4K
#define CART_TYPE_PLUS32	23  // plusCart 32k + 128b RAM


#define FLASH_CONFIG_ADDRESS     ((uint32_t)0x080FFFFC) /* Base @ of last word in last sector */

/* Base address of the Flash sectors */
#define ADDR_FLASH_SECTOR_0     ((uint32_t)0x08000000) /* Base @ of Sector 0, 16 Kbytes */
#define ADDR_FLASH_SECTOR_1     ((uint32_t)0x08004000) /* Base @ of Sector 1, 16 Kbytes */
#define ADDR_FLASH_SECTOR_2     ((uint32_t)0x08008000) /* Base @ of Sector 2, 16 Kbytes */
#define ADDR_FLASH_SECTOR_3     ((uint32_t)0x0800C000) /* Base @ of Sector 3, 16 Kbytes */
#define ADDR_FLASH_SECTOR_4     ((uint32_t)0x08010000) /* Base @ of Sector 4, 64 Kbytes */
#define ADDR_FLASH_SECTOR_5     ((uint32_t)0x08020000) /* Base @ of Sector 5, 128 Kbytes */
#define ADDR_FLASH_SECTOR_6     ((uint32_t)0x08040000) /* Base @ of Sector 6, 128 Kbytes */
#define ADDR_FLASH_SECTOR_7     ((uint32_t)0x08060000) /* Base @ of Sector 7, 128 Kbytes */
#define ADDR_FLASH_SECTOR_8     ((uint32_t)0x08080000) /* Base @ of Sector 8, 128 Kbytes */
#define ADDR_FLASH_SECTOR_9     ((uint32_t)0x080A0000) /* Base @ of Sector 9, 128 Kbytes */
#define ADDR_FLASH_SECTOR_10    ((uint32_t)0x080C0000) /* Base @ of Sector 10, 128 Kbytes */
#define ADDR_FLASH_SECTOR_11    ((uint32_t)0x080E0000) /* Base @ of Sector 11, 128 Kbytes */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
