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
#define SD_CS_Pin GPIO_PIN_5
#define SD_CS_GPIO_Port GPIOB
/* USER CODE BEGIN Private defines */

#define SD_SPI_HANDLE hspi2

#define BUFFER_SIZE				96   // kilobytes
#define CCM_RAM_SIZE            64   // kilobytes
#define CCM_RAM ((uint8_t*)0x10000000)


enum e_status_message {
	STATUS_NONE = -2,
	STATUS_MESSAGE_STRING,
	STATUS_ROOT,
	select_wifi_network,
	wifi_not_connected,
	wifi_connected,
	esp_timeout,
	insert_password,
	plus_connect,
	STATUS_YOUR_MESSAGE,
	offline_roms_deleted,
	not_enough_menory,
	romtype_ACE_unsupported,
	romtype_unknown,
	done,
	failed,
	download_failed,
	offline_roms_detected,
	no_offline_roms_detected,
	romtype_DPCplus_unsupported,
	exit_emulation,
	rom_download_failed,

	STATUS_SETUP,
	STATUS_SETUP_TV_MODE,
	STATUS_SETUP_FONT_STYLE,
	STATUS_SETUP_LINE_SPACING,
	STATUS_SETUP_SYSTEM_INFO,
	STATUS_SEARCH_FOR_ROM,
	STATUS_SEARCH_DETAILS,
	STATUS_CHOOSE_ROM,

	STATUS_APPEARANCE,

};

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
