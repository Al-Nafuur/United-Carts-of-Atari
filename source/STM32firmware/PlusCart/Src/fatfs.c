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
#include <stdbool.h>

FILINFO fno;

bool is_text_file(char *);
bool is_valid_file(char *);

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

bool is_text_file(char * filename){
	return false;
}

bool is_valid_file(char * filename){
	return true;
}

int sd_card_file_size(char * path){
	FATFS FatFs;
	int file_size = -1;

    if ( f_mount(&FatFs, "", 1) == FR_OK) {
    	if( f_stat(path, &fno) == FR_OK)
    		file_size = (int)fno.fsize;
    	f_mount(0, "", 1);
    }
	return file_size;
}

void sd_card_file_list( char *path, MENU_ENTRY **dst, int *num_menu_entries ){
	FATFS FatFs;

    if ( f_mount(&FatFs, "", 1) == FR_OK) {
            DIR dir;
            if ( f_opendir(&dir, path) == FR_OK) {
                    while ( (*num_menu_entries) < NUM_MENU_ITEMS) {
                            if (f_readdir(&dir, &fno) != FR_OK || fno.fname[0] == 0)
                                    break;
                            if (fno.fattrib & (AM_HID | AM_SYS))
                                    continue;
                            (*dst)->type = fno.fattrib & AM_DIR ? SD_Sub_Menu : SD_Cart_File;
                            if ((*dst)->type == SD_Cart_File ){
                            	if(is_text_file(fno.fname)){
                            		(*dst)->type = SD_Sub_Menu; // text files are "fake" directories
                            	}else if(!is_valid_file(fno.fname)){
                            		continue;
                            	}
                            }
                            // copy file record
                            (*dst)->filesize = (uint32_t) fno.fsize;
                            strncpy((*dst)->entryname, fno.fname, 32);
                            (*dst)++;
                            (*num_menu_entries)++;
                    }
                    f_closedir(&dir);
/*            }else if(is_text_file(path) ){
            	FIL fil;
            	if(f_open(&fil, path, FA_READ) == FR_OK){

        			f_close(&fil);
            	}
 */
            }
            f_mount(0, "", 1);
    }
}

uint32_t sd_card_file_request(uint8_t *ext_buffer, char *path, uint32_t start_pos, uint32_t length ){
	UINT bytes_read = 0;
	FATFS FatFs;
	FIL fil;
	FRESULT read_result;
	if (f_mount(&FatFs, "", 1) == FR_OK){
		if (f_open(&fil, &path[sizeof(MENU_TEXT_SD_CARD_CONTENT)], FA_READ) == FR_OK){
			if (start_pos == 0 || f_lseek(&fil, start_pos) == FR_OK) {
				read_result = f_read(&fil, ext_buffer, length, &bytes_read);
				if (read_result != FR_OK) {
					bytes_read = 0;
				}
			}
			f_close(&fil);
		}
		f_mount(0, "", 1);
	}
	return (uint32_t) bytes_read;
}

/* USER CODE END Application */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
