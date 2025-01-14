/*
 * cartridge_setup.c
 *
 *  Created on: 05.07.2020
 *      Author: stubig
 */

#include "global.h"
#if USE_WIFI
#include "esp8266.h"
#endif
#if USE_SD_CARD
#include "fatfs.h"
#endif
#include "flash.h"
#include "main.h"

#include "cartridge_setup.h"

#define FLASH_SIZE_KB 352

#define RAM_IMAGE_SIZE (BUFFER_SIZE * 1024U)        // 98304

#define CCM_IMAGE_OFFSET RAM_IMAGE_SIZE             // 98304
#define CCM_IMAGE_SIZE   (CCM_RAM_SIZE * 1024U)      // 65536

#define FLASH_IMAGE_OFFSET (RAM_IMAGE_SIZE + CCM_IMAGE_SIZE)
#define FLASH_IMAGE_SIZE   (FLASH_SIZE_KB * 1024U)



bool setup_cartridge_image(const char* filename, uint32_t image_size, uint8_t* buffer, cartridge_layout* layout, MENU_ENTRY *d, enum cart_base_type banking_type) {
    uint32_t bank_size = 4096;

    switch(banking_type){
        case(base_type_SB):
            if (image_size > 256*1024) return false;
        break;
        case(base_type_DF):
        case(base_type_DFSC):
            if (image_size != 128*1024) return false;
        break;
        case(base_type_BF):
        case(base_type_BFSC):
            if (image_size != 256*1024) return false;
        break;
        case base_type_3F:
            if (image_size > 512*1024) return false;
            bank_size = 2048;
        break;
        // these base types will never appear here, it is just to stop
        // the compiler from nagging!
        case base_type_None:
        case base_type_2K:
        case base_type_4K:
        case base_type_4KSC:
        case base_type_F8:
        case base_type_F6:
        case base_type_F4:
        case base_type_UA:
        case base_type_FE:
        case base_type_3E:
        case base_type_E0:
        case base_type_0840:
        case base_type_CV:
        case base_type_EF:
        case base_type_F0:
        case base_type_FA:
        case base_type_FA2:
        case base_type_E7:
        case base_type_DPC:
        case base_type_AR:
        case base_type_PP:
        case base_type_3EPlus:
        case base_type_DPCplus:
        case base_type_ACE:
        case base_type_ELF:
        case base_type_Load_Failed:
        default:
        	return false;
    }


	uint32_t ram_size = image_size > (RAM_IMAGE_SIZE) ? RAM_IMAGE_SIZE : image_size;
	uint8_t ram_banks = (uint8_t)(ram_size / bank_size);

    for (uint8_t i = 0; i < ram_banks; i++) layout->banks[i] = buffer + i * bank_size;

    // Save d->type from CCMRAM before it is overwritten
    enum MENU_ENTRY_Type d_type = d->type;

    if(image_size > (RAM_IMAGE_SIZE + CCM_IMAGE_SIZE) ){
        uint32_t flash_part_address;
        uint32_t flash_size = image_size - (RAM_IMAGE_SIZE + CCM_IMAGE_SIZE);
    	uint8_t flash_banks = (uint8_t)(flash_size / bank_size); // should always be less than 352K 88 banks
    	if(d_type == Cart_File ){
#if USE_WIFI
    		flash_part_address = flash_download((char*)filename, flash_size, FLASH_IMAGE_OFFSET, true);
#else
    		flash_part_address = 0; // d->type == Cart_File and no WiFi ???
#endif
    	}else if(d_type == SD_Cart_File ){
#if USE_SD_CARD
    		flash_part_address = DOWNLOAD_AREA_START_ADDRESS + 128U * 1024U * (uint8_t)( user_settings.first_free_flash_sector - 5);
    		uint32_t bytes_read = 0, next_read = 0;
    		uint32_t next_chunk = flash_size > CCM_IMAGE_SIZE ? CCM_IMAGE_SIZE : flash_size;
    	    flash_erase_storage(user_settings.first_free_flash_sector);

    		while ( bytes_read < flash_size){
    			next_read = sd_card_file_request( CCM_RAM, (char*) filename, FLASH_IMAGE_OFFSET + bytes_read, next_chunk );
    			flash_buffer_at(CCM_RAM, next_chunk, (uint8_t*)flash_part_address + bytes_read);
    			bytes_read += next_read;
    			next_chunk = flash_size > bytes_read + CCM_IMAGE_SIZE ? CCM_IMAGE_SIZE : flash_size - bytes_read;
    		}
#else
    		flash_part_address = 0; // d->type == SD_Cart_File and no SD-Card ???
#endif
    	}else{
    		flash_part_address = d->flash_base_address + FLASH_IMAGE_OFFSET;
    	}

    	if(flash_part_address == 0)
    		return false;

        for (uint8_t i = 0; i < flash_banks; i++) layout->banks[((RAM_IMAGE_SIZE + CCM_IMAGE_SIZE) / bank_size) + i] = (uint8_t *)(flash_part_address + i * bank_size);
    }

    if(image_size > RAM_IMAGE_SIZE){
    	uint32_t bytes_read;
    	uint32_t ccm_size = image_size > (RAM_IMAGE_SIZE + CCM_IMAGE_SIZE) ? CCM_IMAGE_SIZE : (image_size - RAM_IMAGE_SIZE);
    	uint8_t ccm_banks = (uint8_t)(ccm_size / bank_size);
    	if(d_type == Cart_File ){
#if USE_WIFI
    		bytes_read = esp8266_PlusStore_API_file_request( CCM_RAM, (char*) filename, CCM_IMAGE_OFFSET, ccm_size );
#else
    		bytes_read = 0; // d->type == Cart_File and no WiFi ???
#endif
    	}
    	else if(d_type == SD_Cart_File ){
#if USE_SD_CARD
    		bytes_read = sd_card_file_request( CCM_RAM, (char*) filename, CCM_IMAGE_OFFSET, ccm_size );
#else
    		bytes_read = 0; // d->type == SD_Cart_File and no SD-Card ???
#endif

    	}
     	else
     		bytes_read = flash_file_request( CCM_RAM, d->flash_base_address, CCM_IMAGE_OFFSET, ccm_size );

        if (bytes_read != ccm_size)	return false;

        for (uint8_t i = 0; i < ccm_banks; i++) layout->banks[(RAM_IMAGE_SIZE / bank_size) + i] = CCM_RAM + i * bank_size;
    }

	return true;
}

