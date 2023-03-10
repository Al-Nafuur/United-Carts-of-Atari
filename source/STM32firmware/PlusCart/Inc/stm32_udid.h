/**
 * A simple header for reading the STM32 unique device ID (UDID)
 * Tested with STM32F4 and STM32F0 families
 *
 * Version 1.0
 * Written by Uli Koehler
 * Published on http://techoverflow.net
 * Licensed under CC0 (public domain):
 * https://creativecommons.org/publicdomain/zero/1.0/
 */
#ifndef STM32_UDID_H
#define STM32_UDID_H
#include <stdint.h>

#define FLASH_SIZE_ADDRESS          0x1FFF7A22 /* STM32F4xx flash size address */
#define UNIQUE_DEVICE_ID_ADDRESS    0x1FFF7A10 /* STM32F4xx unique device ID address */

/**
 * The STM32 factory-programmed UDID memory.
 * Three values of 32 bits each starting at this address
 * Use like this: STM32_UDID[0], STM32_UDID[1], STM32_UDID[2]
 */
#define STM32_UDID          ((__IO uint32_t *) UNIQUE_DEVICE_ID_ADDRESS )

#define STM32F4_FLASH_SIZE  (*(__IO uint16_t *) (FLASH_SIZE_ADDRESS))


#endif //STM32_UDID_H
