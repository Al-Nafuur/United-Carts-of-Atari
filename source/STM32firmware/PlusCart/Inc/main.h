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
	base_type_BFSC
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

#define BUFFER_SIZE				96   // kilobytes
#define CCM_RAM_SIZE            64   // kilobytes

#define MENU_TEXT_OFFLINE_ROMS              "Offline ROMs"
#define MENU_TEXT_DELETE_OFFLINE_ROMS       "Erase O ROMs"
#define MENU_TEXT_SETUP 	                "Setup"
#define MENU_TEXT_WIFI_SETUP 	            "WiFi Setup"
#define MENU_TEXT_TV_MODE_SETUP             "Set TV Mode"
#define MENU_TEXT_TV_MODE_PAL               "PAL"
#define MENU_TEXT_TV_MODE_PAL60             "PAL 60Hz"
#define MENU_TEXT_TV_MODE_NTSC              "NTSC"
#define MENU_TEXT_PRIVATE_KEY               "Private Key"
#define MENU_TEXT_FIRMWARE_UPDATE           "** Update **"
#define MENU_TEXT_OFFLINE_ROM_UPDATE        "* Flash ROMs"
#define MENU_TEXT_PLUS_CONNECT              "Plus connect"
#define MENU_TEXT_PLUS_REMOVE               "Plus remove"

#define STATUS_MESSAGE_WIFI_NOT_CONNECTED   "No WiFi     "
#define STATUS_MESSAGE_WIFI_CONNECTED       "WiFi connect"
#define STATUS_MESSAGE_ESP_TIMEOUT          "WiFi timeout"
#define STATUS_MESSAGE_PLUS_CONNECT         "Insert email"
#define STATUS_MESSAGE_PLUS_CONNECTED       "Connected   "
#define STATUS_MESSAGE_PLUS_CREATED         "User created"
#define STATUS_MESSAGE_PLUS_CONNECT_FAILED  "Failed!     "
#define STATUS_MESSAGE_PLUS_REMOVED         "Cart removed"
#define STATUS_MESSAGE_PRIVATE_KEY          "Insert Key  "
#define STATUS_MESSAGE_PRIVATE_KEY_SAVED    "Key saved   "
#define STATUS_MESSAGE_OFFLINE_ROMS_DELETED "ROMs Erased "
#define STATUS_MESSAGE_NOT_ENOUGH_MENORY    "ROM Too Big!"


/* USER CODE END Private defines */


#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
