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
	base_type_AR
};

typedef struct {
	enum cart_base_type base_type;
	_Bool withSuperChip;
	_Bool withPlusFunctions;
} CART_TYPE;

typedef struct {
	const char *ext;
	CART_TYPE cart_type;
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

#define VERSION 	  "0.7.1"
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
                                dst++;

#define BUFFER_SIZE				96   // kilobytes

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
