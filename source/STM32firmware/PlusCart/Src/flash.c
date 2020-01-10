
#include "stm32f4xx_hal.h"
#include "flash.h"


uint32_t get_file_lenght(uint32_t base_adress){
	uint32_t length = 0;
	base_adress += 124;
	c =  (*(__IO uint8_t*)(base_adress));
	while ( c > '/' && c < '9'){ // octal digit 0-8
		length = length * 8 + ( c -'0' );
		c =  (*(__IO uint8_t*)(base_adress++));
	}
	return length;
}

uint32_t flash_file_request(uint8_t *ext_buffer, uint32_t base_adress ){

	uint32_t length = 0, i = 0;

	c =  (*(__IO uint8_t*)(base_adress));

	if(c != 0xff ){
		length = get_file_lenght(base_adress);
	}
	base_adress += TAR_HEADER_SIZE;

	for ( i = 0; i < length; i++) {
		ext_buffer[i] = (*(__IO uint8_t*)(base_adress + i));
	}
 	return length;
}


_Bool flash_has_inbuild_roms(){
	return 0xff != (*(__IO uint8_t*)(EEPROM_START_ADDRESS));
}

void flash_file_list( MENU_ENTRY **dst , int *num_p){
	uint32_t base_adress = (uint32_t)( EEPROM_START_ADDRESS), length = 0, r;
	uint8_t pos = 0;

	c =  (*(__IO uint8_t*)(base_adress));

	while(c != 0xff && *num_p < MAX_FLASH_ROM_FILES){
		while (c != '\0' && pos < 32){ // get the name (first 12 chars)
			(*dst)->entryname[pos] = c;
			++pos;
    		c =  (*(__IO uint8_t*)(base_adress + pos));
		}
		(*dst)->entryname[pos] = '\0';
		(*dst)->type = Offline_cart_File;
		(*dst)->filesize = base_adress;

		length = get_file_lenght(base_adress);

		(*dst)++;
		(*num_p)++;
		base_adress += TAR_HEADER_SIZE + length;
		// padding for next tar block !!
		r = base_adress % TAR_BLOCK_SIZE;
		if(r){
			base_adress += (TAR_BLOCK_SIZE - r);
		}
		pos = 0;
		c =  (*(__IO uint8_t*)(base_adress));
	}
}
