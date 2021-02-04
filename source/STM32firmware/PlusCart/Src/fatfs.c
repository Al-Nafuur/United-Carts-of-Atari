/**
  ******************************************************************************
  * @file   fatfs.c
  * @brief  Code for fatfs applications
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2021 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under Ultimate Liberty license
  * SLA0044, the "License"; You may not use this file except in compliance with
  * the License. You may obtain a copy of the License at:
  *                             www.st.com/SLA0044
  *
  ******************************************************************************
  */

#include "fatfs.h"

uint8_t retUSER;    /* Return value for USER */
char USERPath[4];   /* USER logical drive path */
FATFS USERFatFS;    /* File system object for USER logical drive */
FIL USERFile;       /* File object for USER */

/* USER CODE BEGIN Variables */
#include <string.h>

FILINFO fno;

int entry_compare(const void* p1, const void* p2);

/* USER CODE END Variables */

void MX_FATFS_Init(void)
{
  /*## FatFS: Link the USER driver ###########################*/
  retUSER = FATFS_LinkDriver(&USER_Driver, USERPath);

  /* USER CODE BEGIN Init */
  /* additional user code for init */
  /* USER CODE END Init */
}

/**
  * @brief  Gets Time from RTC
  * @param  None
  * @retval Time in DWORD
  */
DWORD get_fattime(void)
{
  /* USER CODE BEGIN get_fattime */
  return 0;
  /* USER CODE END get_fattime */
}

/* USER CODE BEGIN Application */

int sd_card_file_list( char *path, MENU_ENTRY *dst ){
    int counter = 0;
	FATFS FatFs;

    HAL_Delay(1000); // do we really need this ?
    if ( f_mount(&FatFs, "", 1) == FR_OK) {
            DIR dir;
            if ( f_opendir(&dir, path) == FR_OK) {
                    while ( counter < NUM_MENU_ITEMS) {
                            if (f_readdir(&dir, &fno) != FR_OK || fno.fname[0] == 0)
                                    break;
                            if (fno.fattrib & (AM_HID | AM_SYS))
                                    continue;
                            dst->type = fno.fattrib & AM_DIR ? SD_Sub_Menu : SD_Cart_File;
                            // if (dst->type == SD_Cart_File && !is_valid_file(fno.fname))
                            //      continue;
                            // copy file record
                            dst->filesize = (uint32_t) fno.fsize;
                            strncpy(dst->entryname, fno.fname, 32);
                            dst++;
                            counter++;
                    }
                    f_closedir(&dir);
            }
            f_mount(0, "", 1);
    }
    return counter;
}
/* USER CODE END Application */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
