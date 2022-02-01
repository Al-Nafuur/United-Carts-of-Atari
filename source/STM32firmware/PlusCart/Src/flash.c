#include <string.h>
#include <stdlib.h>
#include "global.h"
#if USE_WIFI
#include "esp8266.h"
#endif
#include "flash.h"
#include "cartridge_firmware.h"


extern FLASH_ProcessTypeDef pFlash;

// reserve eeprom data storage;
unsigned const char eeprom_data[16384] __attribute__((__section__(".eeprom"), used)) = {[0 ... 16383] = 0xff };


/* Private function prototypes -----------------------------------------------*/
HAL_StatusTypeDef FLASH_WaitInRAMForLastOperationWithMaxDelay(void) __attribute__((section(".data#")));
static uint8_t get_sector(uint32_t Address);
int16_t get_active_eeprom_page(void);
int16_t get_active_eeprom_page_entry(int16_t);
uint32_t get_filesize(uint32_t);


USER_SETTINGS flash_get_eeprom_user_settings(void){
    USER_SETTINGS user_settings = {TV_MODE_DEFAULT, FIRST_FREE_SECTOR, FONT_DEFAULT, SPACING_DEFAULT};
    int16_t act_page_index = get_active_eeprom_page();
    int16_t act_entry_index = -1;
    if( act_page_index != -1 ){
        act_entry_index = get_active_eeprom_page_entry(act_page_index);
    }
    if (act_entry_index != -1){

    	uint32_t dataIndex = (uint32_t) (act_page_index * EEPROM_PAGE_SIZE) + EEPROM_PAGE_HEADER_SIZE;
    	dataIndex += (uint32_t)(act_entry_index * EEPROM_ENTRY_SIZE) + EEPROM_ENTRY_HEADER_SIZE;

    	user_settings = (*(USER_SETTINGS *)(&eeprom_data[dataIndex]));
    }
    return user_settings;
}

void flash_set_eeprom_user_settings(USER_SETTINGS user_settings){
    int16_t act_entry_index = -1;
    int16_t new_entry_index, new_page_index;
    int16_t act_page_index = get_active_eeprom_page();
    if( act_page_index != -1 ){
        act_entry_index = get_active_eeprom_page_entry(act_page_index);
    }
    new_page_index = act_page_index;
    new_entry_index = (int16_t) (act_entry_index + 1);

    HAL_FLASH_Unlock();

    if(act_entry_index != -1){ // && act_page_index != -1 is always true if act_entry_index != -1 is true
        // make last entry invalid!

    	uint32_t dataIndex = (uint32_t) (act_page_index * EEPROM_PAGE_SIZE) + EEPROM_PAGE_HEADER_SIZE;
    	dataIndex += (uint32_t)(act_entry_index * EEPROM_ENTRY_SIZE);

       	HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, EEPROM_START_ADDRESS + dataIndex, ((uint8_t)0x55) );
    }

    // Page full ?
    if( new_entry_index > EEPROM_MAX_ENTRY_ID ){
           new_entry_index = 0;
           // test if flash is full !!
           if(new_page_index > EEPROM_MAX_PAGE_ID ){
               FLASH_Erase_Sector(EEPROM_SECTOR_ID, (uint8_t) FLASH_VOLTAGE_RANGE_3);
               new_page_index = 0;
           }else{ // invalidate act page

			   uint32_t dataIndex = (uint32_t) (act_page_index * EEPROM_PAGE_SIZE);
			   HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, EEPROM_START_ADDRESS + dataIndex, ((uint32_t)EEPROM_INVALID_PAGE_HEADER) );
           }
    }

    // check for start new page !!
    if( new_entry_index == 0 ){ // new_page_index != act_page_index  &&  new_page_index != -1
           new_page_index++;
           // make new activ page header!

       	   uint32_t dataIndex = (uint32_t) (new_page_index * EEPROM_PAGE_SIZE);
           HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, EEPROM_START_ADDRESS + dataIndex, ((uint32_t)EEPROM_ACTIVE_PAGE_HEADER) );
    }

	uint32_t dataIndex = (uint32_t) (new_page_index * EEPROM_PAGE_SIZE) + EEPROM_PAGE_HEADER_SIZE;
	dataIndex += (uint32_t)(new_entry_index * EEPROM_ENTRY_SIZE);

    uint32_t new_entry_flash_address = EEPROM_START_ADDRESS + dataIndex;

    // make new activ entry header!
    new_entry_flash_address++;
    HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, new_entry_flash_address, ((uint8_t)0x55) );
    new_entry_flash_address++;

    for(uint8_t i = 0; i<sizeof(USER_SETTINGS); i++){
        HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, new_entry_flash_address++, ((unsigned char *)&user_settings)[i]);
    }
    HAL_FLASH_Lock();
}

void flash_erase_eeprom(){

    HAL_FLASH_Unlock();
    FLASH_WaitForLastOperation((uint32_t)FLASH_TIMEOUT_VALUE);
    FLASH_Erase_Sector(EEPROM_SECTOR_ID, (uint8_t) FLASH_VOLTAGE_RANGE_3);
    FLASH_WaitForLastOperation((uint32_t)FLASH_TIMEOUT_VALUE);
    CLEAR_BIT(FLASH->CR, (FLASH_CR_SER | FLASH_CR_SNB));
    HAL_FLASH_Lock();
}


#if USE_WIFI
/* write to flash with multiple HTTP range requests */
uint32_t flash_download(char *filename, uint32_t filesize, uint32_t http_range_start, bool append){

	uint8_t start_sector;

	if(append)
		start_sector = user_settings.first_free_flash_sector;
	else
		start_sector = (uint8_t)FLASH_SECTOR_5;

	if( start_sector < (uint8_t)FLASH_SECTOR_5 || esp8266_PlusStore_API_connect() == false){
    	return 0;
	}

    flash_erase_storage(start_sector);

    __disable_irq();
	HAL_FLASH_Unlock();

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

    uint8_t c;
    uint32_t count, http_range_end = http_range_start + (filesize < MAX_RANGE_SIZE ? filesize : MAX_RANGE_SIZE) - 1;
	uint32_t Address = DOWNLOAD_AREA_START_ADDRESS + 128U * 1024U * (uint8_t)( start_sector - 5);

	esp8266_PlusStore_API_prepare_request_header((char *)filename, true );
	strcat(http_request_header, (char *)"     0- 32767\r\n\r\n");
    size_t http_range_param_pos_counter, http_range_param_pos = strlen((char *)http_request_header) - 5;

    uint8_t parts = (uint8_t)(( filesize + MAX_RANGE_SIZE - 1 )  / MAX_RANGE_SIZE);
    uint16_t last_part_size = (filesize % MAX_RANGE_SIZE)?(filesize % MAX_RANGE_SIZE):MAX_RANGE_SIZE;

    while(parts != 0 ){
        http_range_param_pos_counter = http_range_param_pos;
        count = http_range_end;
        while(count != 0) {
            http_request_header[http_range_param_pos_counter--] = (char)(( count % 10 ) + '0');
            count = count/10;
        }
        http_range_param_pos_counter = http_range_param_pos - 7;
        count = http_range_start;
        while(count != 0) {
            http_request_header[http_range_param_pos_counter--] = (char)(( count % 10 ) + '0');
            count = count/10;
        }

    	esp8266_print(http_request_header);

        // Skip HTTP Header
        esp8266_skip_http_response_header();

        // Now for the HTTP Body
        count = 0;
        while(count < MAX_RANGE_SIZE && (parts != 1 || count < last_part_size )){
            if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
                c = (uint8_t)huart1.Instance->DR; // & (uint8_t)0xFF);

//HAL_FLASH_Program();
                /* Program the user Flash area byte by byte
                (area defined by FLASH_USER_START_ADDR and FLASH_USER_END_ADDR) ***********/
                /* Wait for last operation to be completed */
                //if(FLASH_WaitInRAMForLastOperationWithMaxDelay() == HAL_OK){
                FLASH_WaitInRAMForLastOperationWithMaxDelay() ;
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
               // }else{
                //    return;
               // }
                count++;
            }
        }

        http_range_start += MAX_RANGE_SIZE;
        http_range_end += (--parts==1)?last_part_size:MAX_RANGE_SIZE;

        count = 0;
        while(count++ < 25000000){
        }
    }
    __HAL_UNLOCK(&pFlash);

    __enable_irq();

    // End Transparent Transmission
    esp8266_PlusStore_API_end_transmission();

    // flash new usersettings .. (if not appended)
	if(! append){
		user_settings.first_free_flash_sector = (uint8_t)(get_sector(Address) + 1);
    	flash_set_eeprom_user_settings(user_settings);
	}
	return (uint32_t)( DOWNLOAD_AREA_START_ADDRESS + 128U * 1024U * (uint32_t)( start_sector - 5) );
}
#endif

/* write (firmware) to flash from buffer */
void flash_firmware_update(uint32_t filesize){

    uint32_t count;
    uint32_t Address = ADDR_FLASH_SECTOR_0;
    HAL_StatusTypeDef status;


    //HAL_FLASHEx_Erase();
    // Process Locked
    // __HAL_LOCK(&pFlash);
    pFlash.Lock = HAL_LOCKED;

    // Wait for last operation to be completed
    if(FLASH_WaitInRAMForLastOperationWithMaxDelay() == HAL_OK){
        uint32_t sectors[4] = { FLASH_SECTOR_0, FLASH_SECTOR_2, FLASH_SECTOR_3, FLASH_SECTOR_4 };

        for( count = 0 ; count < 4; count++){
//          FLASH_Erase_Sector(count, (uint8_t) FLASH_VOLTAGE_RANGE_3);
            CLEAR_BIT(FLASH->CR, FLASH_CR_PSIZE);
            FLASH->CR |= FLASH_PSIZE_WORD;
            CLEAR_BIT(FLASH->CR, FLASH_CR_SNB);
            FLASH->CR |= FLASH_CR_SER | (sectors[count] << FLASH_CR_SNB_Pos);
            FLASH->CR |= FLASH_CR_STRT;

            /* Wait for last operation to be completed */
            status = FLASH_WaitInRAMForLastOperationWithMaxDelay();

            /* If the erase operation is completed, disable the SER and SNB Bits */
            CLEAR_BIT(FLASH->CR, (FLASH_CR_SER | FLASH_CR_SNB));

            if(status != HAL_OK){
                /* In case of error, stop erase procedure and return the faulty sector*/
                // break; Todo wat nu
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


    uint8_t* data_pointer = buffer;
    count = 0;
    while(count < filesize ){
        //HAL_FLASH_Program();
        /* Program the user Flash area byte by byte
         (area defined by FLASH_USER_START_ADDR and FLASH_USER_END_ADDR) ***********/
        /* Wait for last operation to be completed */
        FLASH_WaitInRAMForLastOperationWithMaxDelay() ;
        /*Program byte (8-bit) at a specified address.*/
        // FLASH_Program_Byte(Address, (uint8_t) c);
        CLEAR_BIT(FLASH->CR, FLASH_CR_PSIZE);
        FLASH->CR |= FLASH_PSIZE_BYTE;
        FLASH->CR |= FLASH_CR_PG;

        *(__IO uint8_t*)Address = data_pointer[count];
        // end FLASH_Program_Byte(Address, (uint8_t) c);

        /* Wait for last operation to be completed */
        FLASH_WaitInRAMForLastOperationWithMaxDelay();

        /* If the program operation is completed, disable the PG Bit */
        FLASH->CR &= (~FLASH_CR_PG);
        Address++;
        count++;
        if( Address == ADDR_FLASH_SECTOR_1){
        	Address = ADDR_FLASH_SECTOR_2; // Skip user settings area
        } else if(Address == ( ADDR_FLASH_SECTOR_4 + 48 * 1024 ) ){
        	data_pointer = ((uint8_t*)0x10000000) - 96 * 1024 ;
        }
    }
    __HAL_UNLOCK(&pFlash);

    __enable_irq();
    NVIC_SystemReset();
}

uint32_t flash_file_request(uint8_t *ext_buffer, uint32_t base_address, uint32_t start, uint32_t length ){

    uint32_t i = 0;

    base_address += TAR_HEADER_SIZE + start;

    for ( i = 0; i < length; i++) {
        ext_buffer[i] = (*(__IO uint8_t*)(base_address + i));
    }
    return length;
}

bool flash_has_downloaded_roms(){
    return user_settings.first_free_flash_sector > 5;
}

void flash_file_list( char *path, MENU_ENTRY **dst, int *num_menu_entries ){
    uint32_t base_adress = (uint32_t)( DOWNLOAD_AREA_START_ADDRESS), length, r;
    uint8_t pos, c;
	size_t path_len = strlen(path);
    char act_tar_file_path_name[100];
    bool is_dir, is_file;
    char *tmp_path = (char*) calloc((path_len +2) , sizeof(char));
    if(path_len > 0 ){
        strcpy(tmp_path, &path[1]);
        strcat(tmp_path, "/");
    }

    c =  (*(__IO uint8_t*)(base_adress));

    while(c != 0xff && (*num_menu_entries) < NUM_MENU_ITEMS){ // NUM_MENU_ITEMS and c < 127 ? Ascii ?
        pos = 0;
        length = get_filesize(base_adress);
        is_dir = ((*(__IO uint8_t*)(base_adress + 156)) == '5');
        is_file = is_dir ?  false : ((*(__IO uint8_t*)(base_adress + 156)) == '0');


        if(is_dir || is_file){ // ignore hard/symbolic link, (block) device files and named pipes
            while (c != '\0' && pos < 100){ // get path and name (first 100 chars)
            	act_tar_file_path_name[pos++] = c;
                c =  (*(__IO uint8_t*)(base_adress + pos));
            }
            act_tar_file_path_name[pos] = '\0';
            if(act_tar_file_path_name[--pos] == '/')// last char in filename is '/'
            	act_tar_file_path_name[pos] = '\0';

            if(strncmp(tmp_path, act_tar_file_path_name, path_len ) == 0 ){
            	char *act_tar_filename = &act_tar_file_path_name[ path_len ];
            	if( !( strchr( act_tar_filename, '/') ) ){
            		(*dst)->entryname[0] = '\0';
            		strncat((*dst)->entryname, act_tar_filename, 32);
            		(*dst)->type = is_dir?Offline_Sub_Menu:Offline_Cart_File;
            		(*dst)->flash_base_address = base_adress;

            		(*dst)->filesize = length;

            		(*dst)++;
                    (*num_menu_entries)++;
            	}
            }
        }

        // move to next (possible) tar entry (base_adress)
        base_adress += TAR_HEADER_SIZE + length;
        // padding for next tar block !!
        r = base_adress % TAR_BLOCK_SIZE;
        if(r){
            base_adress += (TAR_BLOCK_SIZE - r);
        }
        c =  (*(__IO uint8_t*)(base_adress));
    }

    free(tmp_path);
}

uint32_t flash_check_offline_roms_size( ){
    uint32_t base_adress = (uint32_t)( DOWNLOAD_AREA_START_ADDRESS), length, r;
    uint8_t c;

    c =  (*(__IO uint8_t*)(base_adress));

    while(c != 0xff && c != 0x00 ){
        length = get_filesize(base_adress);

        // move to next (possible) tar entry (base_adress)
        base_adress += TAR_HEADER_SIZE + length;
        // padding for next tar block !!
        r = base_adress % TAR_BLOCK_SIZE;
        if(r){
            base_adress += (TAR_BLOCK_SIZE - r);
        }
        c =  (*(__IO uint8_t*)(base_adress));
    }

    return base_adress;
}

void flash_erase_storage(uint8_t start_sector){
	if(start_sector < (uint8_t)FLASH_SECTOR_5 )
		return;

	HAL_FLASH_Unlock();
	FLASH_WaitForLastOperation((uint32_t)FLASH_TIMEOUT_VALUE);
	for( uint32_t del_sec = (uint32_t)start_sector; del_sec <= FLASH_SECTOR_11; del_sec++){
	    FLASH_Erase_Sector(del_sec, (uint8_t) FLASH_VOLTAGE_RANGE_3);
		FLASH_WaitForLastOperation((uint32_t)FLASH_TIMEOUT_VALUE);
	    CLEAR_BIT(FLASH->CR, (FLASH_CR_SER | FLASH_CR_SNB));
	}
	HAL_FLASH_Lock();
}


/* Private function -----------------------------------------------------------*/

HAL_StatusTypeDef FLASH_WaitInRAMForLastOperationWithMaxDelay(){
  /* Wait for the FLASH operation to complete by polling on BUSY flag to be reset.
     Even if the FLASH operation fails, the BUSY flag will be reset and an error
     flag will be set */
  while(__HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY) != RESET){}

  /* Check FLASH End of Operation flag  */
  if (__HAL_FLASH_GET_FLAG(FLASH_FLAG_EOP) != RESET){
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

uint32_t get_filesize(uint32_t base_adress){
    uint32_t size = 0;
    uint8_t c;
    base_adress += 124;
    c =  (*(__IO uint8_t*)(base_adress));
    while ( c > '/' && c < '9'){ // octal digit 0-8
        size = size * 8 + (uint8_t)( c -'0' );
        c =  (*(__IO uint8_t*)(base_adress++));
    }
    return size;
}

static uint8_t get_sector(uint32_t Address)
{
  uint8_t sector = 0;

  if((Address >= ADDR_FLASH_SECTOR_0) && (Address < ADDR_FLASH_SECTOR_4)){
    sector = (uint8_t)((Address - ADDR_FLASH_SECTOR_0) / 0x4000);
  }else if((Address >= ADDR_FLASH_SECTOR_5) && (Address < ADDR_FLASH_SECTOR_12)){
    sector = (uint8_t)(((Address - ADDR_FLASH_SECTOR_5) / 0x20000 ) + 5);
  }else{
    sector = FLASH_SECTOR_4;
  }
  return sector;
}

int16_t get_active_eeprom_page(){
    int16_t index = 0;
    uint32_t eeprom_pointer = (uint32_t) eeprom_data;
    while ( index <  EEPROM_MAX_PAGE_ID &&  *(__IO uint32_t *) eeprom_pointer == EEPROM_INVALID_PAGE_HEADER ){
        index++;
        eeprom_pointer += EEPROM_PAGE_SIZE;
    }
    //
    if( *(__IO uint32_t *) eeprom_pointer != EEPROM_ACTIVE_PAGE_HEADER )
        index = -1;
    return index;
}

int16_t get_active_eeprom_page_entry(int16_t page_index){
    int16_t index = 0;

	uint32_t dataIndex = (uint32_t) (page_index * EEPROM_PAGE_SIZE) + EEPROM_PAGE_HEADER_SIZE;

	uint32_t eeprom_pointer =  (uint32_t) &eeprom_data[dataIndex];
    while( index <  EEPROM_MAX_ENTRY_ID &&  *(__IO uint16_t *) eeprom_pointer == EEPROM_INVALID_ENTRY_HEADER ){
        index++;
        eeprom_pointer += EEPROM_ENTRY_SIZE;
    }
    if( *(__IO uint16_t *) eeprom_pointer != EEPROM_ACTIVE_ENTRY_HEADER )
        index = -1;
    return index;
}
