#ifndef CARTRIDGE_SETUP_H
#define CARTRIDGE_SETUP_H

#include <stdint.h>
#include <stdbool.h>

#include "global.h"

typedef struct {
    uint8_t* banks[64];
} cartridge_layout;

bool setup_cartridge_image(const char*, uint32_t, uint8_t*, cartridge_layout* , MENU_ENTRY *, enum cart_base_type  );

#endif // CARTRIDGE_SETUP_H
