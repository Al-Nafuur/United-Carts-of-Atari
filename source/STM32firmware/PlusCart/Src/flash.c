#include <string.h>
#include <stdlib.h>

#include "stm32f4xx_hal.h"
#include "flash.h"
#include "global.h"
#include "cartridge_firmware.h"


extern FLASH_ProcessTypeDef pFlash;
const uint8_t * eeprom_pointer;
// reserve eeprom data storage;
unsigned const char eeprom_data[16384] __attribute__((__section__(".eeprom"), used)) = {[0 ... 16383] = 0xff };

/* Private function prototypes -----------------------------------------------*/
HAL_StatusTypeDef FLASH_WaitInRAMForLastOperationWithMaxDelay(void) __attribute__((section(".data#")));
static uint32_t get_sector(uint32_t Address);
int16_t get_active_eeprom_page(void);
int16_t get_active_eeprom_page_entry(uint16_t);
uint32_t get_filesize(uint32_t);

USER_SETTINGS flash_get_eeprom_user_settings(void){
    USER_SETTINGS user_settings = {TV_MODE_NTSC, FLASH_SECTOR_5, ""};
    int16_t act_page_index = get_active_eeprom_page();
    int16_t act_entry_index = -1;
    if( act_page_index != -1 ){
        act_entry_index = get_active_eeprom_page_entry(act_page_index);
    }

    if( act_entry_index != -1 ){
        uint32_t settings_pos = (act_page_index * EEPROM_PAGE_SIZE) + EEPROM_PAGE_HEADER_SIZE + (act_entry_index * EEPROM_ENTRY_SIZE) + EEPROM_ENTRY_HEADER_SIZE;
        user_settings.tv_mode = eeprom_data[settings_pos++];
        user_settings.first_free_flash_sector = eeprom_data[settings_pos++];
        strncpy(user_settings.secret_key, (char *) &eeprom_data[settings_pos], 10);
    }else if( *(__IO uint32_t*)FLASH_CONFIG_ADDRESS <= TV_MODE_PAL60 ){ // old config
        user_settings.tv_mode = *(__IO uint32_t*)FLASH_CONFIG_ADDRESS;
    }
    return user_settings;
}

void flash_set_eeprom_user_settings(USER_SETTINGS user_settings){
    int16_t act_entry_index = -1;
    uint16_t new_entry_index, new_page_index;
    int16_t act_page_index = get_active_eeprom_page();
    if( act_page_index != -1 ){
        act_entry_index = get_active_eeprom_page_entry(act_page_index);
    }
    new_page_index = act_page_index;
    new_entry_index = act_entry_index + 1;

    HAL_FLASH_Unlock();

    if(act_entry_index != -1){ // && act_page_index != -1 is always true if act_entry_index != -1 is true
        // make last entry invalid!
        HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE,
                          EEPROM_START_ADDRESS + ( act_page_index * EEPROM_PAGE_SIZE ) + EEPROM_PAGE_HEADER_SIZE + ( act_entry_index * EEPROM_ENTRY_SIZE ),
                          ((uint8_t)0x55) );
    }

    // Page full ?
    if( new_entry_index > EEPROM_MAX_ENTRY_ID ){
           new_entry_index = 0;
           // test if flash is full !!
           if(new_page_index > EEPROM_MAX_PAGE_ID ){
               FLASH_Erase_Sector(EEPROM_SECTOR_ID, (uint8_t) FLASH_VOLTAGE_RANGE_3);
               new_page_index = 0;
           }else{ // invalidate act page
            HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, EEPROM_START_ADDRESS + (act_page_index * EEPROM_PAGE_SIZE ), ((uint32_t)EEPROM_INVALID_PAGE_HEADER) );
           }
    }

    // check for start new page !!
    if( new_entry_index == 0 ){ // new_page_index != act_page_index  &&  new_page_index != -1
           new_page_index++;
           // make new activ page header!
        HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, EEPROM_START_ADDRESS + (new_page_index * EEPROM_PAGE_SIZE ), ((uint32_t)EEPROM_ACTIVE_PAGE_HEADER) );
    }

    uint32_t new_entry_flash_address = EEPROM_START_ADDRESS + ( new_page_index * EEPROM_PAGE_SIZE ) + EEPROM_PAGE_HEADER_SIZE + ( new_entry_index * EEPROM_ENTRY_SIZE );

    // make new activ entry header!
    new_entry_flash_address++;
    HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, new_entry_flash_address, ((uint8_t)0x55) );
//    new_entry_flash_address += sizeof(EEPROM_ACTIVE_ENTRY_HEADER);
    new_entry_flash_address++;

    // save new entry data!
    HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, new_entry_flash_address, user_settings.tv_mode);
    new_entry_flash_address++;
    HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, new_entry_flash_address, user_settings.first_free_flash_sector);
    new_entry_flash_address++;
    for(uint8_t i = 0; i<10; i++){
        HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, new_entry_flash_address++, user_settings.secret_key[i]);
    }
    HAL_FLASH_Lock();
}


/* write to flash with multiple HTTP range requests */
void flash_download(uint32_t filesize, uint8_t *http_request_header, uint32_t Address, uint32_t http_range_start){

    if(Address < ADDR_FLASH_SECTOR_5) // we don't flash firmware area here!
    	return;

    uint8_t c;
    uint16_t http_range_param_pos_counter, http_range_param_pos = strlen((char *)http_request_header) - 5;
    uint32_t count, flash_max = 4, http_range_end = http_range_start + 4095;
    HAL_StatusTypeDef status;


    //HAL_FLASHEx_Erase();
    // Process Locked
    // __HAL_LOCK(&pFlash);
    pFlash.Lock = HAL_LOCKED;

    // Wait for last operation to be completed
    if(FLASH_WaitInRAMForLastOperationWithMaxDelay() == HAL_OK){
        uint32_t sectors[7];
        uint8_t start_sector = get_sector( Address);
        flash_max = 12 - start_sector;
        for(count = 0 ; count < flash_max; count++){
            sectors[count] = count + start_sector;
        }


        for( count = 0 ; count < flash_max; count++){
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

    uint8_t chunks = ( filesize + 4095 )  / 4096;
    uint16_t lastChunkSize = (filesize % 4096)?(filesize % 4096):4096;
    while(chunks != 0 ){
        http_range_param_pos_counter = http_range_param_pos;
        count = http_range_end;
        while(count != 0) {
            c = count % 10;
            http_request_header[http_range_param_pos_counter--] =  c + '0';
            count = count/10;
        }
        http_range_param_pos_counter = http_range_param_pos - 7;
        count = http_range_start;
        while(count != 0) {
            c = count % 10;
            http_request_header[http_range_param_pos_counter--] =  c + '0';
            count = count/10;
        }

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
                if( (uint8_t)huart1.Instance->DR == '\n' ){
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

        http_range_start += 4096;
        http_range_end += (--chunks==1)?lastChunkSize:4096;

        count = 0;
        while(count++ < 25000000){
        }
    }
    __HAL_UNLOCK(&pFlash);

    // End Transparent Transmission
    count = 0;
    while(1){ // todo set and break on timeout ?
        if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ // ! (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_TXE) ) ){
            huart1.Instance->DR = '+';
            if(count++ == 2)
                break;
        }
    }

    __enable_irq();
    // flash new usersettings .. (if not BFSC or BF !!)
    user_settings.first_free_flash_sector = get_sector(Address) + 1;
    flash_set_eeprom_user_settings(user_settings);
}


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


        // Now for the HTTP Body
        count = 0;
        while(count < filesize ){

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

                    *(__IO uint8_t*)Address = buffer[count];
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

_Bool flash_has_downloaded_roms(){
    return user_settings.first_free_flash_sector > 5;
}

void flash_file_list( char *path, MENU_ENTRY **dst , int *num_p){
    uint32_t base_adress = (uint32_t)( DOWNLOAD_AREA_START_ADDRESS), length, r;
    uint8_t pos, c, path_len = strlen(path);
    char act_tar_file_path_name[100];
    _Bool is_dir, is_file;
    char *tmp_path = (char*) calloc((path_len +2) , sizeof(char));
    if(path_len > 0 ){
        strcpy(tmp_path, &path[1]);
        strcat(tmp_path, "/");
    }

    c =  (*(__IO uint8_t*)(base_adress));

    while(c != 0xff && *num_p < MAX_FLASH_ROM_FILES){ // NUM_MENU_ITEMS and c < 127 ? Ascii ?
        pos = 0;
        length = get_filesize(base_adress);
        is_dir = ((*(__IO uint8_t*)(base_adress + 156)) == '5');
        is_file = is_dir ?  FALSE : ((*(__IO uint8_t*)(base_adress + 156)) == '0');


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
            		strncpy((*dst)->entryname, act_tar_filename, 33);
                    (*dst)->type = is_dir?Offline_Sub_Menu:Offline_Cart_File;
                    (*dst)->flash_base_address = base_adress;

                    (*dst)->filesize = length;

                    (*dst)++;
                    (*num_p)++;
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
        size = size * 8 + ( c -'0' );
        c =  (*(__IO uint8_t*)(base_adress++));
    }
    return size;
}

static uint32_t get_sector(uint32_t Address)
{
  uint32_t sector = 0;

  if((Address >= ADDR_FLASH_SECTOR_0) && (Address < ADDR_FLASH_SECTOR_4)){
    sector = (Address - ADDR_FLASH_SECTOR_0) / 0x4000;
  }else if((Address >= ADDR_FLASH_SECTOR_5) && (Address < ADDR_FLASH_SECTOR_12)){
    sector = ((Address - ADDR_FLASH_SECTOR_5) / 0x20000 ) + 5;
  }else{
    sector = FLASH_SECTOR_4;
  }
  return sector;
}

int16_t get_active_eeprom_page(){
    int16_t index = 0;
    eeprom_pointer = &eeprom_data[0];
    for ( ; index <  (EEPROM_MAX_PAGE_ID - 2); index++ ){
        if((*( uint32_t*)(eeprom_pointer)) != EEPROM_INVALID_PAGE_HEADER ){
            break;
        }
        eeprom_pointer += EEPROM_PAGE_SIZE;
    }
    if((*( uint32_t*)(eeprom_pointer)) != EEPROM_ACTIVE_PAGE_HEADER )
        index = -1;
    return index;
}

int16_t get_active_eeprom_page_entry(uint16_t page_index){
    int16_t index = 0;
    eeprom_pointer =  &eeprom_data[(page_index * EEPROM_PAGE_SIZE) + EEPROM_PAGE_HEADER_SIZE];
    for ( ; index <  (EEPROM_MAX_ENTRY_ID - 2) ; index++ ){
        if((*( uint16_t*)(eeprom_pointer)) != EEPROM_INVALID_ENTRY_HEADER ){
            break;
        }
        eeprom_pointer += EEPROM_ENTRY_SIZE;
    }
    if((*( uint16_t*)(eeprom_pointer)) != EEPROM_ACTIVE_ENTRY_HEADER )
        index = -1;
    return index;
}

