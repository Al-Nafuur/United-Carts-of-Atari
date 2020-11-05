#ifndef FLASH_H
#define	FLASH_H

#ifdef	__cplusplus
extern "C" {
#endif

#include <stdint.h>
#include "global.h"


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
#define ADDR_FLASH_SECTOR_12    ((uint32_t)0x08100000) /* Base @ of !virtual! Sector 12, 0 Kbytes */

#define FLASH_TIMEOUT_VALUE       50000U /* 50 s */


// eeprom emulation defines
#define EEPROM_SECTOR_ID             FLASH_SECTOR_1
#define EEPROM_START_ADDRESS         ADDR_FLASH_SECTOR_1
#define EEPROM_SIZE                  ((uint32_t)0x4000)

#define EEPROM_EMPTY_PAGE_HEADER     ((uint32_t)0xFFFFFFFF)
#define EEPROM_ACTIVE_PAGE_HEADER    ((uint32_t)0x5555FFFF)
#define EEPROM_INVALID_PAGE_HEADER   ((uint32_t)0x55555555)

#define EEPROM_EMPTY_ENTRY_HEADER    ((uint16_t)0xFFFF)
#define EEPROM_ACTIVE_ENTRY_HEADER   ((uint16_t)0x55FF)
#define EEPROM_INVALID_ENTRY_HEADER  ((uint16_t)0x5555)

#define EEPROM_PAGE_HEADER_SIZE      sizeof(EEPROM_EMPTY_PAGE_HEADER)
#define EEPROM_ENTRY_HEADER_SIZE     sizeof(EEPROM_EMPTY_ENTRY_HEADER)
#define EEPROM_PAGE_SIZE             512U    // 4 byte page header + 508 byte for entries
#define EEPROM_ENTRY_SIZE             39    // 2 byte entry header + 37 byte payload

#define EEPROM_MAX_PAGE_ID           ((uint8_t)(EEPROM_SIZE / EEPROM_PAGE_SIZE ) -1)
#define EEPROM_MAX_ENTRY_ID          ((uint8_t)((EEPROM_PAGE_SIZE - EEPROM_PAGE_HEADER_SIZE) / EEPROM_ENTRY_SIZE) - 1)

// Download Area in Flash
#define DOWNLOAD_AREA_START_ADDRESS  ((uint32_t)ADDR_FLASH_SECTOR_5)
#define TAR_HEADER_SIZE              512
#define TAR_BLOCK_SIZE               512

void flash_firmware_update(uint32_t)__attribute__((section(".data#")));

uint32_t flash_download(char *, uint32_t , uint32_t , bool );


uint32_t flash_file_request( uint8_t *, uint32_t, uint32_t, uint32_t );

bool flash_has_downloaded_roms(void);

void flash_file_list(char *, MENU_ENTRY **dst, int *);
uint32_t flash_check_offline_roms_size(void);

void flash_erase_storage(uint8_t);

USER_SETTINGS flash_get_eeprom_user_settings(void);
void flash_set_eeprom_user_settings(USER_SETTINGS);

#ifdef	__cplusplus
}
#endif

#endif	/* FLASH_H */
