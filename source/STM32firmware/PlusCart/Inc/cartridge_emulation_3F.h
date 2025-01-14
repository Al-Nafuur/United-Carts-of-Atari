#ifndef CARTRIDGE_EMULATION_3F_H
#define CARTRIDGE_EMULATION_3F_H

#include <stdint.h>

/* 3F (Tigervision) Bankswitching */
//void emulate_3F_cartridge();

void emulate_3F_cartridge(const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d);

#endif // CARTRIDGE_EMULATION_3F_H
