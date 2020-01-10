#ifndef FLASH_H
#define	FLASH_H

#ifdef	__cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "global.h"


#define EEPROM_START_ADDRESS  ((uint32_t)0x08020000)

#define MAX_FLASH_ROM_FILES 130
#define TAR_HEADER_SIZE     512
#define TAR_BLOCK_SIZE      512


uint32_t flash_file_request( uint8_t *, uint32_t );

_Bool flash_has_inbuild_roms(void);

void flash_file_list(MENU_ENTRY **dst, int *);



#ifdef	__cplusplus
}
#endif

#endif	/* FLASH_H */
