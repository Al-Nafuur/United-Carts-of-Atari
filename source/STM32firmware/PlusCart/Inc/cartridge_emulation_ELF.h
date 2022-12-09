#ifndef CARTRIDGE_ELF_H
#define CARTRIDGE_ELF_H

#include "stm32f4xx_hal_tim.h"
#include "cartridge_io.h"
#include "elfLib.h"

// ELF File
int launch_elf_file(const char* filename, uint32_t buffer_size, uint8_t *buffer);

#endif // CARTRIDGE_ELF_H
